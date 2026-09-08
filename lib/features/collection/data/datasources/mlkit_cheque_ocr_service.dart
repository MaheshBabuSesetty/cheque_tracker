import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/cheque_scan.dart';
import '../../domain/repositories/cheque_ocr_service.dart';

/// Reads a captured cheque copy on-device via ML Kit's text recognizer and
/// pulls out currency, cheque number, amount and drawee bank.
///
/// Unlike [MlKitEmiratesIdOcrService] — one fixed card layout — cheque stock
/// varies by bank, so this is inherently best-effort: fields that can't be
/// confidently located come back null/empty for the agent to fill in by hand
/// rather than guessed. Only AED and USD are accepted, matching the design;
/// any other currency, or one ML Kit can't confidently read at all, comes
/// back rejected so the agent recaptures instead of recording a bad read.
///
/// Field location is driven by each recognized line's `boundingBox`, not by
/// its position in the flattened `recognized.text` string. Block ordering in
/// [RecognizedText] is detection order, which approximates top-to-bottom on a
/// clean scan and is unreliable on a skewed one — so "the last line of the
/// text" is not a dependable way to find the bottom MICR band. Geometry also
/// survives the rotation-correction pass below, where the notion of "last
/// line" would otherwise silently refer to a different edge of the leaf.
class MlKitChequeOcrService implements ChequeOcrService {
  MlKitChequeOcrService(this._recognizer);

  final TextRecognizer _recognizer;

  static const _banks = [
    'Emirates NBD',
    'First Abu Dhabi Bank',
    'Mashreq Bank',
    'Abu Dhabi Commercial Bank',
    'Abu Dhabi Islamic Bank',
    'Dubai Islamic Bank',
    'RAKBANK',
    'Commercial Bank of Dubai',
    'Ajman Bank',
    'Sharjah Islamic Bank',
    'HSBC',
    'Standard Chartered',
    'Citibank',
    'National Bank of Fujairah',
    'Emirates Islamic',
    'Al Hilal Bank',
  ];

  /// Comma-grouped ("12,500.00") or plain-decimal ("12500.00") amounts —
  /// deliberately excludes plain integer runs, which on a cheque are far
  /// more likely to be the cheque/account/MICR number than the amount.
  static final _amountPattern =
      RegExp(r'\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+\.\d{2}');

  /// Cheque numbers aren't a fixed length across banks/leaves (5-8 digits in
  /// practice). The labelled form is rare on real stock but unambiguous when
  /// present, so it wins outright within the corner region.
  static final _labelledChequeNumberPattern =
      RegExp(r'no\.?\s*[:#]?\s*(\d{4,8})\b', caseSensitive: false);

  /// Bare digit run, excluding runs adjacent to a digit, hyphen or slash so
  /// it can't grab a fragment of a longer hyphenated reference (a BPN, say)
  /// or of the printed "DD/MM/YYYY" date. Only used for corner-region and
  /// last-resort searches — the MICR band is parsed by
  /// [_parseMicrBand] instead, because the lookarounds here match *nothing*
  /// on a band whose E-13B symbols ML Kit dropped (see that method).
  static final _bareChequeNumberPattern = RegExp(r'(?<![\d\-/])\d{4,8}(?![\d\-/])');

  static final _currencyAnchorPattern = RegExp(
    r'\bAED\b|\bDIRHAMS?\b|\bUSD\b|\bUS\s*DOLLARS?\b|\$',
    caseSensitive: false,
  );

  /// ML Kit's on-device model is downloaded on first use via Google Play
  /// Services; on a slow/filtered network that download can stall with the
  /// call never resolving. Bounding it means a stall reads to the agent as
  /// an unreadable scan (recapture) instead of a frozen scanning overlay.
  /// Applied per OCR pass — the rotation-correction pass below gets its own
  /// budget rather than sharing the first pass's.
  static const _timeout = Duration(seconds: 20);

  /// Longest edge a rotated working copy is resized to before re-running OCR.
  /// A full-resolution phone photo decodes to ~50MB of RGBA; rotating that on
  /// the main isolate is a visible freeze on low-end Android. 2000px still
  /// leaves the MICR band and corner number comfortably above the ~30px glyph
  /// height OCR needs.
  static const _rotatedCopyMaxEdge = 2000;

  // Region boundaries as a fraction of the recognized-text envelope. The
  // envelope (union of every line's box) is used rather than the raw image
  // dimensions because the cheque rarely fills the frame — anchoring to the
  // photo edges would put the "top right corner" somewhere in the background.
  static const _cornerMinX = 0.55;
  static const _cornerMaxY = 0.28;
  static const _micrMinY = 0.82;

  @override
  Future<ChequeScan> scan(String imagePath, {String? expectedPayeeName}) async {
    final firstPass = await _recognize(imagePath);
    if (firstPass == null) {
      return ChequeScan(
        detectedCurrency: '',
        accepted: false,
        nameMatched: expectedPayeeName == null ? null : false,
      );
    }

    // The MICR band is a horizontal strip across the *bottom* of the leaf,
    // printed in E-13B — it is not a vertical strip along the edge. When it
    // comes back looking vertical, the photo is rotated, not the printing, so
    // the fix is to correct the image orientation once and re-read rather
    // than to brute-force both rotations on every scan.
    var reading = _ChequeReading.from(firstPass);
    if (_looksRotated(firstPass) || !reading.hasChequeNumber) {
      final corrected = await _readWithOrientationCorrection(imagePath);
      if (corrected != null && corrected.fieldsFound > reading.fieldsFound) {
        reading = corrected;
      }
    }

    final nameMatched = expectedPayeeName == null
        ? null
        : _payeeNameFound(reading.flatText, expectedPayeeName);

    final bank = _detectBank(reading.flatText);
    final currency = _detectCurrency(reading.flatText.toUpperCase(), bank);

    if (currency != 'AED' && currency != 'USD') {
      return ChequeScan(detectedCurrency: currency, accepted: false, bank: bank, nameMatched: nameMatched);
    }

    final chequeNumber = _resolveChequeNumber(reading);
    final amount = _detectAmount(reading, currency);

    _logRead(reading, chequeNumber, amount);

    var fieldsFound = 0;
    if (bank != null) fieldsFound++;
    if (chequeNumber.value != null) fieldsFound++;
    if (amount != null) fieldsFound++;

    return ChequeScan(
      detectedCurrency: currency,
      accepted: true,
      // Deliberately not a percentage. The old '${55 + fieldsFound * 15}%'
      // rendered as "100%" whenever all three fields happened to be located,
      // which reads to the agent as the machine being certain about an amount
      // it is about to record. This states what was actually established, and
      // flags the corner/MICR mismatch case that a percentage hid entirely.
      confidence: _describeConfidence(fieldsFound, chequeNumber),
      chequeNumber: chequeNumber.value ?? '',
      amount: amount ?? 0,
      nameMatched: nameMatched,
    );
  }

  /// Best-effort check that most of [expectedName]'s words appear somewhere
  /// in the recognized text. Cheque stock doesn't give the payee line a
  /// fixed geometric region the way the corner/MICR bands have (unlike
  /// [_resolveChequeNumber]), so there's no positional read to anchor on —
  /// this instead requires [_matchThreshold] of the name's significant
  /// (3+ letter) words to show up anywhere on the leaf, in any order.
  ///
  /// Deliberately *not* a contiguous substring match: the payee line sits
  /// over the cheque's watermark/security pattern, so ML Kit routinely
  /// mis-detects a character or splits the line into two OCR lines even
  /// when every other field (cheque number, amount) reads cleanly — a whole
  /// name only has to be *slightly* off for a substring match to fail, which
  /// is exactly what made this reject a photo where the name was plainly
  /// legible. Requiring most words, unordered, tolerates both without
  /// accepting an unrelated cheque (a completely different payee shares
  /// none of these words).
  static const _matchThreshold = 0.6;

  bool _payeeNameFound(String flatText, String expectedName) {
    final words = _normalizeForNameMatch(expectedName)
        .split(' ')
        .where((w) => w.length >= 3)
        .toList();
    if (words.isEmpty) return true;

    final haystack = _normalizeForNameMatch(flatText);
    final found = words.where(haystack.contains).length;
    _debugLog(
      'Payee name check: $found/${words.length} word(s) of "$expectedName" found on leaf.',
    );
    return found / words.length >= _matchThreshold;
  }

  static String _normalizeForNameMatch(String s) =>
      s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), ' ').trim();

  // ---------------------------------------------------------------------------
  // Recognition passes
  // ---------------------------------------------------------------------------

  Future<RecognizedText?> _recognize(String imagePath) async {
    try {
      return await _recognizer
          .processImage(InputImage.fromFilePath(imagePath))
          .timeout(_timeout);
    } catch (e) {
      // Not gated behind `assert`/`kDebugMode` — see the equivalent note on
      // `MlKitEmiratesIdOcrService.scan`. This logs the failure only, never
      // cheque content.
      debugPrint('Cheque OCR scan failed: $e');
      return null;
    }
  }

  /// Bakes EXIF orientation, downscales, and tries 90°/270° on a working copy,
  /// keeping whichever pass locates the most fields. Runs only when the first
  /// pass looked rotated or found no cheque number, so most scans never reach
  /// this path.
  Future<_ChequeReading?> _readWithOrientationCorrection(String imagePath) async {
    final Uint8List original;
    try {
      original = await File(imagePath).readAsBytes();
    } catch (e) {
      debugPrint('Cheque OCR orientation pass: could not read photo: $e');
      return null;
    }

    _ChequeReading? best;
    for (final angle in const [90, 270]) {
      final bytes = await compute(
        _bakeRotateAndResize,
        _RotateRequest(bytes: original, angle: angle, maxEdge: _rotatedCopyMaxEdge),
      );
      if (bytes == null) continue;

      final path = await _writeTempCopy(bytes, angle);
      try {
        final recognized = await _recognize(path);
        if (recognized == null) continue;
        final reading = _ChequeReading.from(recognized);
        if (best == null || reading.fieldsFound > best.fieldsFound) {
          best = reading;
        }
        // A pass that already found the cheque number is good enough; skip
        // the second rotation rather than paying for another OCR call.
        if (reading.hasChequeNumber) break;
      } finally {
        File(path).delete().ignore();
      }
    }
    return best;
  }

  Future<String> _writeTempCopy(Uint8List bytes, int angle) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/cheque-rotated-$angle-${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  /// Horizontal text produces lines that are much wider than they are tall.
  /// When most substantial lines come back taller than wide, the photo is on
  /// its side. Short lines are ignored — a two-character line is near-square
  /// either way and only adds noise.
  bool _looksRotated(RecognizedText recognized) {
    var vertical = 0;
    var total = 0;
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        if (line.text.trim().length < 4) continue;
        total++;
        if (line.boundingBox.height > line.boundingBox.width) vertical++;
      }
    }
    if (total < 3) return false;
    return vertical / total > 0.6;
  }

  // ---------------------------------------------------------------------------
  // Cheque number
  // ---------------------------------------------------------------------------

  /// Prefers the top-right corner number over the MICR band. Both encode the
  /// same value, but the corner is printed in a normal typeface while the band
  /// is E-13B — which ML Kit's Latin recognizer was never trained on, so it
  /// confuses 6/8, 1/7 and 0/8 there. When both are found they're compared:
  /// agreement is corroboration from two independent reads of two different
  /// fonts, disagreement means one of them definitely misread and is surfaced
  /// rather than silently resolved.
  _ChequeNumberResult _resolveChequeNumber(_ChequeReading reading) {
    final corner = _fromCornerRegion(reading);
    final micr = _parseMicrBand(reading.micrBandText);

    if (corner != null && micr != null) {
      return _ChequeNumberResult(
        value: corner,
        source: _ChequeNumberSource.corner,
        // Compare on the trailing digits: the MICR field is zero-padded to
        // six while the corner may be printed unpadded, so "047231" and
        // "47231" are the same number, not a mismatch.
        crossChecked: _sameNumber(corner, micr),
      );
    }
    if (corner != null) {
      return _ChequeNumberResult(value: corner, source: _ChequeNumberSource.corner);
    }
    if (micr != null) {
      return _ChequeNumberResult(value: micr, source: _ChequeNumberSource.micr);
    }

    final fallback = _fromFlatText(reading.flatText);
    if (fallback != null) {
      return _ChequeNumberResult(value: fallback, source: _ChequeNumberSource.flatText);
    }
    return const _ChequeNumberResult(value: null, source: _ChequeNumberSource.none);
  }

  static bool _sameNumber(String a, String b) {
    final trimmedA = a.replaceFirst(RegExp(r'^0+'), '');
    final trimmedB = b.replaceFirst(RegExp(r'^0+'), '');
    return trimmedA == trimmedB;
  }

  String? _fromCornerRegion(_ChequeReading reading) {
    final text = reading.cornerText;
    if (text.isEmpty) return null;

    final labelled = _labelledChequeNumberPattern
        .allMatches(text)
        .map((m) => m.group(1)!)
        .firstWhere(_isPlausibleChequeNumber, orElse: () => '');
    if (labelled.isNotEmpty) return labelled;

    final bare = _bareChequeNumberPattern
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where(_isPlausibleChequeNumber)
        .toList();
    // Corner region is small enough that a second candidate means something
    // else got caught (a date fragment, a form code). Take nothing rather
    // than pick arbitrarily.
    return bare.length == 1 ? bare.first : null;
  }

  /// Parses the bottom MICR band by splitting on non-digits rather than by
  /// regex lookaround.
  ///
  /// UAE CTS-2010 stock encodes the band as cheque number (6) | MICR/routing
  /// code (9) | account number | transaction code (2), separated by the E-13B
  /// transit and on-us symbols. ML Kit frequently drops those symbols
  /// entirely, collapsing the whole band into one continuous digit run like
  /// "123456123456789123456" — in which case every 4-8 digit window inside it
  /// is adjacent to another digit, [_bareChequeNumberPattern] matches nothing
  /// at all, and the band silently contributes no candidate. Splitting on
  /// non-digits handles both the separated and collapsed cases, and the
  /// cheque number is the *first* group either way.
  String? _parseMicrBand(String bandText) {
    if (bandText.isEmpty) return null;

    final groups = bandText
        .split(RegExp(r'\D+'))
        .where((group) => group.isNotEmpty)
        .toList();
    if (groups.isEmpty) return null;

    final first = groups.first;
    if (_isPlausibleChequeNumber(first)) return first;
    // Symbols were dropped and the fields ran together — the leading six
    // digits are the cheque number.
    if (first.length > 8) {
      final candidate = first.substring(0, 6);
      if (_isPlausibleChequeNumber(candidate)) return candidate;
    }
    return null;
  }

  /// Last resort for a scan that produced usable text but no identifiable
  /// corner or band — takes the last plausible run anywhere, matching the
  /// original whole-text behaviour so those scans don't regress.
  String? _fromFlatText(String text) {
    final candidates = _bareChequeNumberPattern
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where(_isPlausibleChequeNumber)
        .toList();
    return candidates.isEmpty ? null : candidates.last;
  }

  /// All-zeros ("000000") is the placeholder a specimen/sample cheque prints
  /// where a real leaf would have its actual number — never a real cheque
  /// number, so it's treated the same as no match at all.
  ///
  /// Note there is deliberately no leading-zero penalty here. The MICR field
  /// is zero-padded to six digits by specification, so "047231" is the normal
  /// form of a five-digit cheque number, not a suspicious read. The old
  /// `_hasLeadingZero` deprioritisation inverted the correct preference and
  /// could hand back a stray fragment from elsewhere on the leaf instead.
  static bool _isPlausibleChequeNumber(String digits) {
    if (digits.length < 4 || digits.length > 8) return false;
    if (RegExp(r'^0+$').hasMatch(digits)) return false;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Currency, bank, amount
  // ---------------------------------------------------------------------------

  /// Some cheque stock marks the currency with a symbol/watermark next to the
  /// amount box instead of (or as well as) the literal "AED"/"USD" text — a
  /// text recognizer can't read a graphical icon at all, so that case would
  /// otherwise come back `UNKNOWN` and get rejected even though it's a
  /// perfectly normal cheque. A recognized [bank] with no explicit currency
  /// text is AED by convention (every bank in [_banks] is UAE-only and none
  /// issue USD cheques as their default), so that's a safe default — but only
  /// when nothing else was explicitly read; an explicit "USD"/other currency
  /// on the leaf always wins.
  String _detectCurrency(String upperText, String? bank) {
    if (RegExp(r'\bAED\b|\bDIRHAMS?\b').hasMatch(upperText)) return 'AED';
    if (RegExp(r'\bUSD\b|\bUS\s*DOLLARS?\b|\$').hasMatch(upperText)) return 'USD';
    const others = ['EUR', 'GBP', 'SAR', 'QAR', 'KWD', 'INR'];
    for (final code in others) {
      if (RegExp('\\b$code\\b').hasMatch(upperText)) return code;
    }
    return bank != null ? 'AED' : 'UNKNOWN';
  }

  String? _detectBank(String text) {
    final upper = text.toUpperCase();
    for (final bank in _banks) {
      if (upper.contains(bank.toUpperCase())) return bank;
    }
    return null;
  }

  /// Picks the amount nearest the currency label, falling back to the amount
  /// box's usual position (right side, vertically central).
  ///
  /// The previous implementation took `reduce((a, b) => a > b ? a : b)` — the
  /// maximum of every match on the leaf. That biases every OCR error in one
  /// direction: a spurious digit turning 1,000.00 into 10,000.00 always wins,
  /// and the larger figure is the one written to the record. For a financial
  /// field the bias has to run the other way, so competing candidates that
  /// disagree return null and the agent types the amount instead.
  double? _detectAmount(_ChequeReading reading, String currency) {
    final candidates = <_AmountCandidate>[];
    for (final line in reading.lines) {
      for (final match in _amountPattern.allMatches(line.text)) {
        final value = double.tryParse(match.group(0)!.replaceAll(',', ''));
        if (value == null) continue;
        if (value < 100 || value > 10000000) continue;
        candidates.add(_AmountCandidate(value: value, box: line.box));
      }
    }
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first.value;

    final anchor = reading.currencyAnchor;
    final env = reading.envelope;

    // Distance to the currency label when we have one; otherwise to the
    // middle of the right-hand side, where the figures box sits on every
    // layout in [_banks].
    final targetX = anchor?.center.dx ?? (env.left + env.width * 0.80);
    final targetY = anchor?.center.dy ?? (env.top + env.height * 0.45);

    candidates.sort((a, b) {
      final da = _distanceSquared(a.box, targetX, targetY);
      final db = _distanceSquared(b.box, targetX, targetY);
      return da.compareTo(db);
    });

    final best = candidates.first;
    final runnerUp = candidates[1];

    // If the two nearest candidates are both close to the target but hold
    // different values, we can't tell which is the figures box — bail out.
    final bestDistance = _distanceSquared(best.box, targetX, targetY);
    final runnerUpDistance = _distanceSquared(runnerUp.box, targetX, targetY);
    final ambiguous = (best.value - runnerUp.value).abs() > 0.01 &&
        runnerUpDistance < bestDistance * 2.25;
    if (ambiguous) {
      _debugLog(
        'Amount ambiguous: ${best.value} vs ${runnerUp.value} at comparable '
        'distance — leaving blank for manual entry.',
      );
      return null;
    }

    return best.value;
  }

  static double _distanceSquared(Rect box, double x, double y) {
    final dx = box.center.dx - x;
    final dy = box.center.dy - y;
    return dx * dx + dy * dy;
  }

  // ---------------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------------

  String _describeConfidence(int fieldsFound, _ChequeNumberResult chequeNumber) {
    final parts = <String>['$fieldsFound of 3 fields read'];
    if (chequeNumber.source == _ChequeNumberSource.corner &&
        chequeNumber.crossChecked == true) {
      parts.add('cheque no. confirmed against MICR');
    } else if (chequeNumber.crossChecked == false) {
      parts.add('cheque no. differs from MICR — verify');
    } else if (chequeNumber.source == _ChequeNumberSource.micr) {
      parts.add('cheque no. from MICR only — verify');
    } else if (chequeNumber.source == _ChequeNumberSource.flatText) {
      parts.add('cheque no. position uncertain — verify');
    }
    return parts.join(' · ');
  }

  /// Cheque content — account number, MICR band, drawer name — is customer
  /// financial data. `debugPrint` is not stripped from release builds; it
  /// routes to the platform log, where any app with log access or any crash
  /// reporter that scrapes logcat can read it. So the raw-text dump stays
  /// behind [kDebugMode], and release builds log nothing but failures.
  void _logRead(_ChequeReading reading, _ChequeNumberResult number, double? amount) {
    if (!kDebugMode) return;
    debugPrint('Cheque OCR raw text:\n${reading.flatText}');
    debugPrint('Cheque OCR corner region: "${reading.cornerText}"');
    debugPrint('Cheque OCR MICR band: "${reading.micrBandText}"');
    debugPrint(
      'Cheque OCR resolved: number=${number.value} '
      'source=${number.source.name} crossChecked=${number.crossChecked} '
      'amount=$amount',
    );
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('Cheque OCR: $message');
  }
}

// -----------------------------------------------------------------------------
// Supporting types
// -----------------------------------------------------------------------------

/// One recognized line plus the box it occupies, so region membership can be
/// decided geometrically instead of by string order.
class _PositionedLine {
  const _PositionedLine({required this.text, required this.box});

  final String text;
  final Rect box;
}

/// A single OCR pass reduced to the regions this service cares about.
class _ChequeReading {
  _ChequeReading._({
    required this.lines,
    required this.envelope,
    required this.flatText,
    required this.cornerText,
    required this.micrBandText,
    required this.currencyAnchor,
  });

  factory _ChequeReading.from(RecognizedText recognized) {
    final lines = <_PositionedLine>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        lines.add(_PositionedLine(text: text, box: line.boundingBox));
      }
    }

    if (lines.isEmpty) {
      return _ChequeReading._(
        lines: const [],
        envelope: Rect.zero,
        flatText: recognized.text,
        cornerText: '',
        micrBandText: '',
        currencyAnchor: null,
      );
    }

    final envelope = lines
        .map((line) => line.box)
        .reduce((a, b) => a.expandToInclude(b));

    // Guard against a degenerate envelope (every line on one axis) so the
    // fractional thresholds below can't divide by zero.
    final width = math.max(envelope.width, 1);
    final height = math.max(envelope.height, 1);

    final corner = lines.where((line) {
      final relX = (line.box.center.dx - envelope.left) / width;
      final relY = (line.box.center.dy - envelope.top) / height;
      return relX >= MlKitChequeOcrService._cornerMinX &&
          relY <= MlKitChequeOcrService._cornerMaxY;
    }).toList()
      ..sort((a, b) => a.box.center.dx.compareTo(b.box.center.dx));

    final band = lines.where((line) {
      final relY = (line.box.center.dy - envelope.top) / height;
      return relY >= MlKitChequeOcrService._micrMinY;
    }).toList()
      ..sort((a, b) => a.box.center.dx.compareTo(b.box.center.dx));

    _PositionedLine? anchor;
    for (final line in lines) {
      if (MlKitChequeOcrService._currencyAnchorPattern.hasMatch(line.text)) {
        anchor = line;
        break;
      }
    }

    return _ChequeReading._(
      lines: lines,
      envelope: envelope,
      flatText: recognized.text,
      cornerText: corner.map((line) => line.text).join(' '),
      // Joined left-to-right by box position, so a band ML Kit split at the
      // E-13B symbol boundaries reassembles in printed order.
      micrBandText: band.map((line) => line.text).join(' '),
      currencyAnchor: anchor?.box,
    );
  }

  final List<_PositionedLine> lines;
  final Rect envelope;
  final String flatText;
  final String cornerText;
  final String micrBandText;
  final Rect? currencyAnchor;

  bool get hasChequeNumber =>
      cornerText.isNotEmpty || micrBandText.isNotEmpty;

  /// Rough score used only to compare rotation passes against each other.
  int get fieldsFound {
    var score = 0;
    if (cornerText.isNotEmpty) score++;
    if (micrBandText.isNotEmpty) score++;
    if (currencyAnchor != null) score++;
    return score;
  }
}

enum _ChequeNumberSource { corner, micr, flatText, none }

class _ChequeNumberResult {
  const _ChequeNumberResult({
    required this.value,
    required this.source,
    this.crossChecked,
  });

  final String? value;
  final _ChequeNumberSource source;

  /// True when corner and MICR agreed, false when they disagreed, null when
  /// only one of the two was available.
  final bool? crossChecked;
}

class _AmountCandidate {
  const _AmountCandidate({required this.value, required this.box});

  final double value;
  final Rect box;
}

class _RotateRequest {
  const _RotateRequest({
    required this.bytes,
    required this.angle,
    required this.maxEdge,
  });

  final Uint8List bytes;
  final int angle;
  final int maxEdge;
}

/// Runs on a background isolate via [compute] — decode, EXIF bake, downscale
/// and rotate are all CPU-bound and would otherwise jank the scanning overlay.
/// Must stay top-level for [compute] to accept it.
Uint8List? _bakeRotateAndResize(_RotateRequest request) {
  try {
    final decoded = img.decodeImage(request.bytes);
    if (decoded == null) return null;

    // Apply EXIF orientation first — many Android cameras store the photo
    // unrotated with an orientation tag, and ML Kit's handling of that tag
    // via fromFilePath is inconsistent across platforms.
    var working = img.bakeOrientation(decoded);

    final longestEdge = math.max(working.width, working.height);
    if (longestEdge > request.maxEdge) {
      final scale = request.maxEdge / longestEdge;
      working = img.copyResize(
        working,
        width: (working.width * scale).round(),
        height: (working.height * scale).round(),
        interpolation: img.Interpolation.average,
      );
    }

    working = img.copyRotate(working, angle: request.angle);
    return Uint8List.fromList(img.encodeJpg(working, quality: 92));
  } catch (_) {
    // Swallowed deliberately: a failed working copy just means this rotation
    // contributes no candidate, which the caller already handles.
    return null;
  }
}
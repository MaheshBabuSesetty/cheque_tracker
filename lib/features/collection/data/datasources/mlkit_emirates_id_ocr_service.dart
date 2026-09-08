import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/entities/emirates_id_scan.dart';
import '../../domain/repositories/emirates_id_ocr_service.dart';

/// Reads the front of an Emirates ID on-device via ML Kit's Latin-script
/// text recognizer, then pulls the four fields the design expects out of
/// the recognized lines with label/pattern heuristics — ML Kit has no
/// "Emirates ID" model, just raw text, so this leans on the card's fixed
/// English layout (ID Number / Name / Nationality / Expiry Date).
class MlKitEmiratesIdOcrService implements EmiratesIdOcrService {
  MlKitEmiratesIdOcrService(this._recognizer);

  final TextRecognizer _recognizer;

  /// Emirates ID number: 784-XXXX-XXXXXXX-X, with or without hyphens in the
  /// raw OCR output.
  static final _idPattern = RegExp(r'784[-\s]?(\d{4})[-\s]?(\d{7})[-\s]?(\d)', caseSensitive: false);

  /// Fallback for when OCR reads the number as one continuous digit run.
  static final _idContinuousPattern = RegExp(r'784(\d{12})', caseSensitive: false);

  static final _nameLabelPatterns = [
    RegExp(r'\bName\s*:', caseSensitive: false),
    RegExp(r'\bFull\s*Name\b', caseSensitive: false),
    RegExp(r'\bHolder\s*Name\b', caseSensitive: false),
    RegExp(r'^Name:?$', caseSensitive: false),
  ];

  static final _nameNoisePattern = RegExp(r'[@#\$%\^&\*\(\)_\+=\[\]\{\};"|<>\/\\]');

  /// Card labels, field names, and common nationality values that must
  /// never be mistaken for a name.
  static const _excludedTerms = [
    'emirates', 'identity', 'card', 'authority', 'federal', 'united arab', 'government',
    'nationality', 'resident', 'expiry', 'expiration', 'date of birth', 'date of expiry',
    'date of issue', 'place of birth', 'occupation', 'employer', 'issuing', 'issued', 'valid',
    'number', 'license', 'profession', 'sex', 'gender',
    'aljinsia', 'tarikh', 'mihna',
    'india', 'pakistan', 'bangladesh', 'philippines', 'nepal', 'srilanka', 'sri lanka',
    'indonesia', 'egypt', 'jordan', 'lebanon', 'syria', 'iran', 'iraq', 'afghanistan', 'china',
    'vietnam', 'thailand', 'malaysia', 'kenya', 'uganda', 'ethiopia', 'sudan', 'yemen', 'oman',
    'saudi', 'kuwait', 'qatar', 'bahrain',
  ];

  static const _labelStartWords = [
    'nationality', 'date', 'place', 'expiry', 'expiration', 'occupation', 'employer',
    'profession', 'sex', 'gender', 'valid', 'issued', 'issuing', 'united', 'federal',
    'resident', 'identity', 'card', 'number', 'id',
  ];

  /// ML Kit's on-device model is downloaded on first use via Google Play
  /// Services; on a slow/filtered network that download can stall with the
  /// call never resolving. Bounding it means a stall reads to the agent as
  /// an unreadable scan (fill in by hand) instead of a frozen scanning
  /// overlay.
  static const _timeout = Duration(seconds: 20);

  @override
  Future<EmiratesIdScan> scan(String imagePath) async {
    final RecognizedText recognized;
    try {
      recognized = await _recognizer.processImage(InputImage.fromFilePath(imagePath)).timeout(_timeout);
    } catch (e) {
      // Deliberately not gated behind `assert`/`kDebugMode`: this is the
      // only trace of *why* a scan came back empty once R8 minification is
      // in play (release builds), where a stripped/renamed ML Kit class
      // throws here instead of recognizing anything — see the `-keep`
      // rules in `proguard-rules.pro`.
      debugPrint('EID OCR scan failed: $e');
      return const EmiratesIdScan(idNumber: '', name: '', confidence: '0%');
    }
    final lines = recognized.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    assert(() {
      debugPrint('═══ EID OCR LINES ═══');
      for (var i = 0; i < lines.length; i++) {
        debugPrint('  [$i] ${lines[i]}');
      }
      debugPrint('═════════════════════');
      return true;
    }());

    final idNumber = _extractIdNumber(recognized.text);
    final name = _extractName(lines);
    final nationality = _extractNationality(lines);
    final fieldsFound = [idNumber, name].where((f) => f.isNotEmpty).length;

    assert(() {
      debugPrint('═══ EID PARSED ══════');
      debugPrint('  ID:          $idNumber');
      debugPrint('  Name:        $name');
      debugPrint('  Nationality: $nationality');
      debugPrint('═════════════════════');
      return true;
    }());

    return EmiratesIdScan(
      idNumber: idNumber,
      name: name,
      nationality: nationality,
      // ML Kit's on-device text recognizer doesn't expose a per-field
      // confidence score, so this stands in as "how much of the card we
      // could actually read" rather than a real OCR confidence. Nationality
      // is a bonus field, not counted here — it isn't always present on a
      // readable card, so it would otherwise drag confidence down for scans
      // that are otherwise perfectly usable.
      confidence: '${(fieldsFound / 2 * 100).round()}%',
    );
  }

  String _extractIdNumber(String text) {
    // OCR commonly confuses these two letters for a digit inside the run.
    final cleanText = text.replaceAll(RegExp(r'[Oo]'), '0').replaceAll('l', '1');

    final match = _idPattern.firstMatch(cleanText);
    if (match != null) return '784-${match[1]}-${match[2]}-${match[3]}';

    final continuous = _idContinuousPattern.firstMatch(cleanText);
    if (continuous != null) {
      final digits = continuous[1]!;
      return '784-${digits.substring(0, 4)}-${digits.substring(4, 11)}-${digits.substring(11)}';
    }

    return '';
  }

  String _extractName(List<String> lines) {
    final byLabel = _extractNameByLabel(lines);
    if (byLabel != null) return byLabel;

    for (final line in lines) {
      if (!_isLikelyName(line) || !_isValidName(line)) continue;
      final cleaned = _cleanName(line);
      if (!_containsExcludedTerm(cleaned)) return cleaned;
    }
    return '';
  }

  String? _extractNameByLabel(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final pattern in _nameLabelPatterns) {
        if (!pattern.hasMatch(line)) continue;

        final colonIndex = line.indexOf(':');
        if (colonIndex != -1 && colonIndex < line.length - 1) {
          final namePart = line.substring(colonIndex + 1).trim();
          if (_isValidName(namePart) && !_containsExcludedTerm(namePart)) return _cleanName(namePart);
        }

        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          if (_isValidName(nextLine) && !_containsExcludedTerm(nextLine)) return _cleanName(nextLine);
        }
      }
    }
    return null;
  }

  /// Nationality is a bonus field (not required to complete step 3), so
  /// unlike [_extractName] this has no fallback heuristic — a label match
  /// or nothing.
  String? _extractNationality(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (!lower.startsWith('nationality') && !lower.contains('nationality:') && !lower.contains('الجنسية')) {
        continue;
      }

      final colonIndex = line.indexOf(':');
      if (colonIndex != -1 && colonIndex < line.length - 1) {
        final value = line.substring(colonIndex + 1).trim();
        if (value.isNotEmpty) return _capitalizeWord(value);
      }

      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();
        if (nextLine.isNotEmpty && !nextLine.contains(':')) return _capitalizeWord(nextLine);
      }
    }
    return null;
  }

  bool _containsExcludedTerm(String text) {
    final lower = text.toLowerCase();
    return _excludedTerms.any(lower.contains);
  }

  bool _isValidName(String text) {
    final cleaned = _cleanName(text);
    if (cleaned.isEmpty || cleaned.length < 3 || cleaned.length > 60) return false;
    if (_nameNoisePattern.hasMatch(cleaned)) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(cleaned)) return false;
    return true;
  }

  bool _isLikelyName(String text) {
    final cleaned = text.trim();
    if (cleaned.length < 10 || cleaned.length > 50) return false;
    if (cleaned.contains(':')) return false;
    if (RegExp(r'\d').hasMatch(cleaned)) return false;

    var letterCount = 0;
    var spaceCount = 0;
    for (final char in cleaned.runes) {
      if (_isLetter(char)) letterCount++;
      if (char == 32) spaceCount++;
    }
    if (letterCount / cleaned.length < 0.85) return false;
    if (spaceCount == 0) return false;

    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    if (words.length < 2 || words.length > 6) return false;
    if (_labelStartWords.contains(words.first.toLowerCase())) return false;

    return !_containsExcludedTerm(cleaned);
  }

  bool _isLetter(int rune) => (rune >= 65 && rune <= 90) || (rune >= 97 && rune <= 122);

  String _cleanName(String name) => name
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(_capitalizeWord)
      .join(' ');

  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

}

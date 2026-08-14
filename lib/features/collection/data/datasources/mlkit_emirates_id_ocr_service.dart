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

  static final _idNumberPattern = RegExp(r'(\d{3})[\s-]?(\d{4})[\s-]?(\d{7})[\s-]?(\d)');
  static final _datePattern = RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b');
  static final _nameLabel = RegExp(r'name\s*[:\-]\s*(.+)', caseSensitive: false);
  static final _nationalityLabel = RegExp(r'nationality\s*[:\-]\s*(.+)', caseSensitive: false);

  /// English boilerplate printed on every card, so it's never mistaken for
  /// the all-caps name line when the "Name:" label itself fails to read.
  static const _boilerplate = [
    'UNITED ARAB EMIRATES',
    'IDENTITY CARD',
    'RESIDENT IDENTITY',
    'FEDERAL AUTHORITY',
    'IDENTITY',
    'ID NUMBER',
    'EXPIRY DATE',
    'NATIONALITY',
  ];

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Future<EmiratesIdScan> scan(String imagePath) async {
    final recognized = await _recognizer.processImage(InputImage.fromFilePath(imagePath));
    final lines = recognized.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final idNumber = _extractIdNumber(recognized.text);
    final name = _extractName(lines);
    final nationality = _extractNationality(lines);
    final expiry = _extractExpiry(lines);

    final fieldsFound = [idNumber, name, nationality, expiry].where((f) => f.isNotEmpty).length;

    return EmiratesIdScan(
      idNumber: idNumber,
      name: name,
      nationality: nationality,
      expiry: expiry,
      // ML Kit's on-device text recognizer doesn't expose a per-field
      // confidence score, so this stands in as "how much of the card we
      // could actually read" rather than a real OCR confidence.
      confidence: '${(fieldsFound / 4 * 100).round()}%',
    );
  }

  String _extractIdNumber(String text) {
    final match = _idNumberPattern.firstMatch(text);
    if (match == null) return '';
    return '${match[1]}-${match[2]}-${match[3]}-${match[4]}';
  }

  String _extractName(List<String> lines) {
    for (final line in lines) {
      final match = _nameLabel.firstMatch(line);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    for (final line in lines) {
      final upper = line.toUpperCase();
      final looksLikeName = line == upper &&
          line.length >= 6 &&
          line.length <= 40 &&
          !RegExp(r'\d').hasMatch(line) &&
          !_boilerplate.any((b) => upper.contains(b));
      if (looksLikeName) return line;
    }
    return '';
  }

  String _extractNationality(List<String> lines) {
    for (final line in lines) {
      final match = _nationalityLabel.firstMatch(line);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  String _extractExpiry(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].toLowerCase().contains('expiry')) continue;
      final onSameLine = _datePattern.firstMatch(lines[i]);
      if (onSameLine != null) return _formatDate(onSameLine);
      if (i + 1 < lines.length) {
        final onNextLine = _datePattern.firstMatch(lines[i + 1]);
        if (onNextLine != null) return _formatDate(onNextLine);
      }
    }
    // The front face only carries one printed date, so if the "Expiry"
    // label itself didn't recognize, any date found is still it.
    final fallback = _datePattern.firstMatch(lines.join(' '));
    return fallback != null ? _formatDate(fallback) : '';
  }

  String _formatDate(RegExpMatch match) {
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = match[3]!;
    if (month < 1 || month > 12) return '${match[1]}/${match[2]}/$year';
    return '${day.toString().padLeft(2, '0')} ${_months[month - 1]} $year';
  }
}

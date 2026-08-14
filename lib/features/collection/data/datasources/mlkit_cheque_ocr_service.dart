import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/entities/cheque_scan.dart';
import '../../domain/repositories/cheque_ocr_service.dart';

/// Reads a captured cheque copy on-device via ML Kit's text recognizer and
/// pulls out currency, cheque number, amount and drawee bank with
/// keyword/pattern heuristics. Unlike [MlKitEmiratesIdOcrService] — one
/// fixed card layout — cheque stock varies by bank, so this is inherently
/// best-effort: fields that can't be confidently located come back
/// null/empty for the agent to fill in by hand rather than guessed. Only
/// AED and USD are accepted, matching the design; any other currency, or
/// one ML Kit can't confidently read at all, comes back rejected so the
/// agent recaptures instead of recording a bad read.
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
  static final _amountPattern = RegExp(r'\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+\.\d{2}');
  static final _chequeNumberPattern = RegExp(r'\b\d{6}\b');

  @override
  Future<ChequeScan> scan(String imagePath) async {
    final recognized = await _recognizer.processImage(InputImage.fromFilePath(imagePath));
    final text = recognized.text;

    final currency = _detectCurrency(text.toUpperCase());
    final bank = _detectBank(text);

    if (currency != 'AED' && currency != 'USD') {
      return ChequeScan(detectedCurrency: currency, accepted: false, bank: bank);
    }

    final chequeNumber = _detectChequeNumber(text);
    final amount = _detectAmount(text);
    var fieldsFound = 0;
    if (bank != null) fieldsFound++;
    if (chequeNumber != null) fieldsFound++;
    if (amount != null) fieldsFound++;

    return ChequeScan(
      detectedCurrency: currency,
      accepted: true,
      bank: bank,
      // Same caveat as the Emirates ID service: not a real OCR
      // confidence score, just how many of the three fields we located.
      confidence: '${55 + fieldsFound * 15}%',
      chequeNumber: chequeNumber ?? '',
      amount: amount ?? 0,
    );
  }

  String _detectCurrency(String upperText) {
    if (RegExp(r'\bAED\b|\bDIRHAMS?\b').hasMatch(upperText)) return 'AED';
    if (RegExp(r'\bUSD\b|\bUS\s*DOLLARS?\b|\$').hasMatch(upperText)) return 'USD';
    const others = ['EUR', 'GBP', 'SAR', 'QAR', 'KWD', 'INR'];
    for (final code in others) {
      if (RegExp('\\b$code\\b').hasMatch(upperText)) return code;
    }
    return 'UNKNOWN';
  }

  String? _detectBank(String text) {
    final upper = text.toUpperCase();
    for (final bank in _banks) {
      if (upper.contains(bank.toUpperCase())) return bank;
    }
    return null;
  }

  String? _detectChequeNumber(String text) => _chequeNumberPattern.firstMatch(text)?.group(0);

  double? _detectAmount(String text) {
    final values = _amountPattern
        .allMatches(text)
        .map((m) => double.parse(m.group(0)!.replaceAll(',', '')))
        .where((v) => v >= 100 && v <= 10000000)
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }
}

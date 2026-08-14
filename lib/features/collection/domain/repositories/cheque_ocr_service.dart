import '../entities/cheque_scan.dart';

/// Reads a cheque copy photo and extracts the drawee bank, currency,
/// cheque number and amount — separate from [EmiratesIdOcrService] since
/// nothing about scanning a cheque overlaps with scanning an ID (Interface
/// Segregation). Swappable for a real OCR provider the same way.
abstract class ChequeOcrService {
  Future<ChequeScan> scan(String imagePath);
}

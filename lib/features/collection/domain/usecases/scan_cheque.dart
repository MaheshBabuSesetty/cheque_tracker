import '../entities/cheque_scan.dart';
import '../repositories/cheque_ocr_service.dart';

class ScanCheque {
  const ScanCheque(this._service);

  final ChequeOcrService _service;

  Future<ChequeScan> call(String imagePath) => _service.scan(imagePath);
}

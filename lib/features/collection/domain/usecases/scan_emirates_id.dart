import '../entities/emirates_id_scan.dart';
import '../repositories/emirates_id_ocr_service.dart';

class ScanEmiratesId {
  const ScanEmiratesId(this._service);

  final EmiratesIdOcrService _service;

  Future<EmiratesIdScan> call(String imagePath) => _service.scan(imagePath);
}

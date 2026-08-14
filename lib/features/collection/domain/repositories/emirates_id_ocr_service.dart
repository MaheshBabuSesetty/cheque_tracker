import '../entities/emirates_id_scan.dart';

/// Reads an Emirates ID front-face photo and extracts identity fields.
/// Modeled as its own contract (not a repository — nothing is being
/// listed/stored) so the OCR provider — currently
/// `MlKitEmiratesIdOcrService` — can be swapped without touching the
/// usecase, notifier, or screen that call it (Open/Closed, Dependency
/// Inversion).
abstract class EmiratesIdOcrService {
  Future<EmiratesIdScan> scan(String imagePath);
}

import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Captures a photo and/or persists raw bytes (e.g. a signature PNG) into
/// the app's own documents directory, returning a stable file path that
/// survives app restarts — `image_picker`'s own returned path lives in a
/// cache directory the OS can reclaim.
abstract class ImageCaptureService {
  /// Opens the camera and returns the saved file path, or `null` if the
  /// agent cancelled. [prefix] becomes part of the filename (e.g.
  /// "id-front") purely for on-disk debuggability.
  Future<String?> captureFromCamera({required String prefix});

  Future<String> saveBytes(Uint8List bytes, {required String prefix, String extension = 'png'});
}

class DeviceImageCaptureService implements ImageCaptureService {
  DeviceImageCaptureService(this._picker);

  final ImagePicker _picker;

  @override
  Future<String?> captureFromCamera({required String prefix}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
    return saveBytes(bytes, prefix: prefix, extension: ext);
  }

  @override
  Future<String> saveBytes(Uint8List bytes, {required String prefix, String extension = 'png'}) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${docsDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    final fileName = '$prefix-${DateTime.now().microsecondsSinceEpoch}.$extension';
    final file = File('${attachmentsDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

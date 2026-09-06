import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../core/widgets/camera/in_app_camera_screen.dart';

/// Captures a photo and/or persists raw bytes (e.g. a signature PNG) into
/// the app's own documents directory, returning a stable file path that
/// survives app restarts — the camera plugin's own returned path lives in
/// a cache directory the OS can reclaim.
abstract class ImageCaptureService {
  /// Opens the in-app camera and returns the saved file path, or `null` if
  /// the agent backed out. [prefix] both becomes part of the filename (e.g.
  /// "id-front") for on-disk debuggability, and selects the viewfinder's
  /// framing (aspect ratio/shape) and guidance text for that document type
  /// — see [_CameraConfig.forPrefix].
  Future<String?> captureFromCamera({required String prefix});

  Future<String> saveBytes(Uint8List bytes, {required String prefix, String extension = 'png'});
}

class DeviceImageCaptureService implements ImageCaptureService {
  DeviceImageCaptureService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;

  @override
  Future<String?> captureFromCamera({required String prefix}) async {
    final config = _CameraConfig.forPrefix(prefix);
    final file = await InAppCameraScreen.show(
      _navigatorKey,
      title: config.title,
      guidance: config.guidance,
      aspectRatio: config.aspectRatio,
      shape: config.shape,
      initialLens: config.initialLens,
      fillHeight: config.fillHeight,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final ext = file.path.contains('.') ? file.path.split('.').last : 'jpg';
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

/// Per-document-type viewfinder framing — keyed by the same `prefix`
/// strings the collection notifier already passes to [captureFromCamera]
/// (e.g. "id-front", "cheque-copy"), so no new enum/constant needed at the
/// call sites.
class _CameraConfig {
  const _CameraConfig({
    required this.title,
    required this.guidance,
    this.aspectRatio = 4 / 3,
    this.shape = CameraFrameShape.rect,
    this.initialLens = CameraLensDirection.back,
    this.fillHeight = false,
  });

  final String title;
  final String guidance;
  final double aspectRatio;
  final CameraFrameShape shape;
  final CameraLensDirection initialLens;

  /// See [InAppCameraScreen.fillHeight].
  final bool fillHeight;

  factory _CameraConfig.forPrefix(String prefix) {
    switch (prefix) {
      case 'rep-photo':
        return const _CameraConfig(
          title: 'Representative photo',
          guidance: 'Position the representative within the frame',
          shape: CameraFrameShape.circle,
          initialLens: CameraLensDirection.front,
        );
      case 'id-front':
        return const _CameraConfig(
          title: 'Emirates ID — front',
          guidance: 'Position the front of the Emirates ID within the frame',
          aspectRatio: 1.58,
          fillHeight: true,
        );
      case 'id-back':
        return const _CameraConfig(
          title: 'Emirates ID — back',
          guidance: 'Position the back of the Emirates ID within the frame',
          aspectRatio: 1.58,
          fillHeight: true,
        );
      case 'cheque-copy':
        return const _CameraConfig(
          title: 'Cheque copy',
          guidance: 'Position the cheque within the frame',
          aspectRatio: 2.1,
          fillHeight: true,
        );
      case 'cheque-scan-select':
        return const _CameraConfig(
          title: 'Scan cheque',
          guidance: 'Position the cheque within the frame',
          aspectRatio: 2.1,
          fillHeight: true,
        );
      case 'voucher':
        return const _CameraConfig(
          title: 'Voucher',
          guidance: 'Position the voucher within the frame',
          aspectRatio: 1.5,
          fillHeight: true,
        );
      case 'supporting-doc':
        return const _CameraConfig(
          title: 'Supporting document',
          guidance: 'Position the document within the frame',
          aspectRatio: 1,
          fillHeight: true,
        );
      default:
        return const _CameraConfig(title: 'Capture photo', guidance: 'Position the document within the frame');
    }
  }
}

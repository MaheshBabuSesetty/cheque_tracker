import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Shrinks a photo for upload: long side capped at [maxLongSide] px, JPEG
/// quality [quality] — roughly 300–600 KB per photo, well under the server's
/// 5 MB per-file limit that full-size phone photos often exceed.
///
/// Applied to the uploaded copy only: the file on disk stays full size,
/// because on-device OCR (the cheque's MICR band especially) reads better
/// from the original.
class ImageCompressor {
  const ImageCompressor._();

  static const int maxLongSide = 1600;
  static const int quality = 80;

  /// Never throws: a file that can't be decoded is uploaded as it is.
  static Future<Uint8List> compressForUpload(String path) async {
    final original = await File(path).readAsBytes();
    try {
      return await compute(_compress, original);
    } catch (_) {
      return original;
    }
  }

  static Uint8List _compress(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final longSide = decoded.width > decoded.height ? decoded.width : decoded.height;
    final resized = longSide > maxLongSide
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxLongSide : null,
            height: decoded.height > decoded.width ? maxLongSide : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;
    final encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    // Never upload something bigger than what we were given.
    return encoded.length < bytes.length ? encoded : bytes;
  }
}

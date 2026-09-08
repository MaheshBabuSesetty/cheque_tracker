import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/dependency_injection.dart';

part 'authenticated_network_image.g.dart';

/// Every stored collection attachment (`GET /cheques/{id}/collection/
/// files/{field}` and `.../supporting-documents/{id}`) is behind the same
/// Bearer auth as the rest of the API, with no public/signed-URL scheme —
/// a plain `Image.network` can't attach that header, so this fetches
/// through the same authenticated Dio client every other call uses.
/// [url] is the relative path returned by the API (e.g. a record's
/// `chequePhotoUrl`); Dio resolves it against the configured base URL.
@riverpod
Future<Uint8List> authenticatedImageBytes(Ref ref, String url) async {
  final dio = ref.watch(dioClientProvider);
  final response = await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
  return Uint8List.fromList(response.data!);
}

class AuthenticatedNetworkImage extends ConsumerWidget {
  const AuthenticatedNetworkImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytesAsync = ref.watch(authenticatedImageBytesProvider(url));
    return bytesAsync.when(
      data: (bytes) => Image.memory(bytes, fit: fit),
      loading: () => const Center(
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
    );
  }
}

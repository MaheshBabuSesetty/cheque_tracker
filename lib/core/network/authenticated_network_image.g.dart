// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authenticated_network_image.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every stored collection attachment (`GET /cheques/{id}/collection/
/// files/{field}` and `.../supporting-documents/{id}`) is behind the same
/// Bearer auth as the rest of the API, with no public/signed-URL scheme —
/// a plain `Image.network` can't attach that header, so this fetches
/// through the same authenticated Dio client every other call uses.
/// [url] is the relative path returned by the API (e.g. a record's
/// `chequePhotoUrl`); Dio resolves it against the configured base URL.

@ProviderFor(authenticatedImageBytes)
final authenticatedImageBytesProvider = AuthenticatedImageBytesFamily._();

/// Every stored collection attachment (`GET /cheques/{id}/collection/
/// files/{field}` and `.../supporting-documents/{id}`) is behind the same
/// Bearer auth as the rest of the API, with no public/signed-URL scheme —
/// a plain `Image.network` can't attach that header, so this fetches
/// through the same authenticated Dio client every other call uses.
/// [url] is the relative path returned by the API (e.g. a record's
/// `chequePhotoUrl`); Dio resolves it against the configured base URL.

final class AuthenticatedImageBytesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>
        >
    with $FutureModifier<Uint8List>, $FutureProvider<Uint8List> {
  /// Every stored collection attachment (`GET /cheques/{id}/collection/
  /// files/{field}` and `.../supporting-documents/{id}`) is behind the same
  /// Bearer auth as the rest of the API, with no public/signed-URL scheme —
  /// a plain `Image.network` can't attach that header, so this fetches
  /// through the same authenticated Dio client every other call uses.
  /// [url] is the relative path returned by the API (e.g. a record's
  /// `chequePhotoUrl`); Dio resolves it against the configured base URL.
  AuthenticatedImageBytesProvider._({
    required AuthenticatedImageBytesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'authenticatedImageBytesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authenticatedImageBytesHash();

  @override
  String toString() {
    return r'authenticatedImageBytesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List> create(Ref ref) {
    final argument = this.argument as String;
    return authenticatedImageBytes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AuthenticatedImageBytesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authenticatedImageBytesHash() =>
    r'204b54ff5d0081b339af0cbcf54eae750af70fea';

/// Every stored collection attachment (`GET /cheques/{id}/collection/
/// files/{field}` and `.../supporting-documents/{id}`) is behind the same
/// Bearer auth as the rest of the API, with no public/signed-URL scheme —
/// a plain `Image.network` can't attach that header, so this fetches
/// through the same authenticated Dio client every other call uses.
/// [url] is the relative path returned by the API (e.g. a record's
/// `chequePhotoUrl`); Dio resolves it against the configured base URL.

final class AuthenticatedImageBytesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uint8List>, String> {
  AuthenticatedImageBytesFamily._()
    : super(
        retry: null,
        name: r'authenticatedImageBytesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every stored collection attachment (`GET /cheques/{id}/collection/
  /// files/{field}` and `.../supporting-documents/{id}`) is behind the same
  /// Bearer auth as the rest of the API, with no public/signed-URL scheme —
  /// a plain `Image.network` can't attach that header, so this fetches
  /// through the same authenticated Dio client every other call uses.
  /// [url] is the relative path returned by the API (e.g. a record's
  /// `chequePhotoUrl`); Dio resolves it against the configured base URL.

  AuthenticatedImageBytesProvider call(String url) =>
      AuthenticatedImageBytesProvider._(argument: url, from: this);

  @override
  String toString() => r'authenticatedImageBytesProvider';
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cheque_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The SIGNED cheques available to collect for one vendor — backs the
/// "select a cheque" picker in the collect flow. Keyed by [vendor] so
/// switching vendors in the picker re-fetches automatically.

@ProviderFor(signedChequesForVendor)
final signedChequesForVendorProvider = SignedChequesForVendorFamily._();

/// The SIGNED cheques available to collect for one vendor — backs the
/// "select a cheque" picker in the collect flow. Keyed by [vendor] so
/// switching vendors in the picker re-fetches automatically.

final class SignedChequesForVendorProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Cheque>>,
          List<Cheque>,
          FutureOr<List<Cheque>>
        >
    with $FutureModifier<List<Cheque>>, $FutureProvider<List<Cheque>> {
  /// The SIGNED cheques available to collect for one vendor — backs the
  /// "select a cheque" picker in the collect flow. Keyed by [vendor] so
  /// switching vendors in the picker re-fetches automatically.
  SignedChequesForVendorProvider._({
    required SignedChequesForVendorFamily super.from,
    required Vendor super.argument,
  }) : super(
         retry: null,
         name: r'signedChequesForVendorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signedChequesForVendorHash();

  @override
  String toString() {
    return r'signedChequesForVendorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Cheque>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Cheque>> create(Ref ref) {
    final argument = this.argument as Vendor;
    return signedChequesForVendor(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SignedChequesForVendorProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signedChequesForVendorHash() =>
    r'33963ce891728df2352316d03f03abc26ac53655';

/// The SIGNED cheques available to collect for one vendor — backs the
/// "select a cheque" picker in the collect flow. Keyed by [vendor] so
/// switching vendors in the picker re-fetches automatically.

final class SignedChequesForVendorFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Cheque>>, Vendor> {
  SignedChequesForVendorFamily._()
    : super(
        retry: null,
        name: r'signedChequesForVendorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The SIGNED cheques available to collect for one vendor — backs the
  /// "select a cheque" picker in the collect flow. Keyed by [vendor] so
  /// switching vendors in the picker re-fetches automatically.

  SignedChequesForVendorProvider call(Vendor vendor) =>
      SignedChequesForVendorProvider._(argument: vendor, from: this);

  @override
  String toString() => r'signedChequesForVendorProvider';
}

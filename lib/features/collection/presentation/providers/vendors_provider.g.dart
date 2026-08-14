// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendors_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The vendor master list — synced read-only, so a plain `Future` provider
/// (rather than a `Notifier`) is enough.

@ProviderFor(vendors)
final vendorsProvider = VendorsProvider._();

/// The vendor master list — synced read-only, so a plain `Future` provider
/// (rather than a `Notifier`) is enough.

final class VendorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Vendor>>,
          List<Vendor>,
          FutureOr<List<Vendor>>
        >
    with $FutureModifier<List<Vendor>>, $FutureProvider<List<Vendor>> {
  /// The vendor master list — synced read-only, so a plain `Future` provider
  /// (rather than a `Notifier`) is enough.
  VendorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vendorsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vendorsHash();

  @$internal
  @override
  $FutureProviderElement<List<Vendor>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Vendor>> create(Ref ref) {
    return vendors(ref);
  }
}

String _$vendorsHash() => r'2aa4c827a92ed7e64c3ac64c908ce5ce8e1d2d92';

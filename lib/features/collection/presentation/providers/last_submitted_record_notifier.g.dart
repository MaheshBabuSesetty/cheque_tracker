// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_submitted_record_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Non-null while the Collect tab should show the "Collection recorded"
/// success view instead of the form; set by the collect screen right
/// after a successful submit (one record per cheque collected), cleared by
/// "Record another"/leaving the tab.

@ProviderFor(LastSubmittedRecordNotifier)
final lastSubmittedRecordProvider = LastSubmittedRecordNotifierProvider._();

/// Non-null while the Collect tab should show the "Collection recorded"
/// success view instead of the form; set by the collect screen right
/// after a successful submit (one record per cheque collected), cleared by
/// "Record another"/leaving the tab.
final class LastSubmittedRecordNotifierProvider
    extends
        $NotifierProvider<
          LastSubmittedRecordNotifier,
          List<CollectionRecord>?
        > {
  /// Non-null while the Collect tab should show the "Collection recorded"
  /// success view instead of the form; set by the collect screen right
  /// after a successful submit (one record per cheque collected), cleared by
  /// "Record another"/leaving the tab.
  LastSubmittedRecordNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastSubmittedRecordProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastSubmittedRecordNotifierHash();

  @$internal
  @override
  LastSubmittedRecordNotifier create() => LastSubmittedRecordNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CollectionRecord>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CollectionRecord>?>(value),
    );
  }
}

String _$lastSubmittedRecordNotifierHash() =>
    r'6bab7c0d5f72f18d02242d230ad2023ed1ef8cf2';

/// Non-null while the Collect tab should show the "Collection recorded"
/// success view instead of the form; set by the collect screen right
/// after a successful submit (one record per cheque collected), cleared by
/// "Record another"/leaving the tab.

abstract class _$LastSubmittedRecordNotifier
    extends $Notifier<List<CollectionRecord>?> {
  List<CollectionRecord>? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<CollectionRecord>?, List<CollectionRecord>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<CollectionRecord>?, List<CollectionRecord>?>,
              List<CollectionRecord>?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

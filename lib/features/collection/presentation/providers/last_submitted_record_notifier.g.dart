// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_submitted_record_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Non-null while the Collect tab should show the "Collection recorded"
/// success view instead of the form; set by the collect screen right
/// after a successful submit, cleared by "Record another"/leaving the tab.

@ProviderFor(LastSubmittedRecordNotifier)
final lastSubmittedRecordProvider = LastSubmittedRecordNotifierProvider._();

/// Non-null while the Collect tab should show the "Collection recorded"
/// success view instead of the form; set by the collect screen right
/// after a successful submit, cleared by "Record another"/leaving the tab.
final class LastSubmittedRecordNotifierProvider
    extends $NotifierProvider<LastSubmittedRecordNotifier, CollectionRecord?> {
  /// Non-null while the Collect tab should show the "Collection recorded"
  /// success view instead of the form; set by the collect screen right
  /// after a successful submit, cleared by "Record another"/leaving the tab.
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
  Override overrideWithValue(CollectionRecord? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollectionRecord?>(value),
    );
  }
}

String _$lastSubmittedRecordNotifierHash() =>
    r'7f45e0a022acb2abcbd0b1886044631c45ad3eca';

/// Non-null while the Collect tab should show the "Collection recorded"
/// success view instead of the form; set by the collect screen right
/// after a successful submit, cleared by "Record another"/leaving the tab.

abstract class _$LastSubmittedRecordNotifier
    extends $Notifier<CollectionRecord?> {
  CollectionRecord? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CollectionRecord?, CollectionRecord?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CollectionRecord?, CollectionRecord?>,
              CollectionRecord?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

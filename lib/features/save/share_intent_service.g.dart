// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_intent_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the most recently shared and persisted [SavedItem], if any.

@ProviderFor(LatestSharedItem)
final latestSharedItemProvider = LatestSharedItemProvider._();

/// Holds the most recently shared and persisted [SavedItem], if any.
final class LatestSharedItemProvider
    extends $NotifierProvider<LatestSharedItem, SavedItem?> {
  /// Holds the most recently shared and persisted [SavedItem], if any.
  LatestSharedItemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestSharedItemProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestSharedItemHash();

  @$internal
  @override
  LatestSharedItem create() => LatestSharedItem();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedItem? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedItem?>(value),
    );
  }
}

String _$latestSharedItemHash() => r'95bcaa58c89486c7f69d3c9db15da8a6c711e91f';

/// Holds the most recently shared and persisted [SavedItem], if any.

abstract class _$LatestSharedItem extends $Notifier<SavedItem?> {
  SavedItem? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SavedItem?, SavedItem?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SavedItem?, SavedItem?>,
              SavedItem?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Provides the active [ShareIntentService] instance.

@ProviderFor(shareIntentService)
final shareIntentServiceProvider = ShareIntentServiceProvider._();

/// Provides the active [ShareIntentService] instance.

final class ShareIntentServiceProvider
    extends
        $FunctionalProvider<
          ShareIntentService,
          ShareIntentService,
          ShareIntentService
        >
    with $Provider<ShareIntentService> {
  /// Provides the active [ShareIntentService] instance.
  ShareIntentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareIntentServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareIntentServiceHash();

  @$internal
  @override
  $ProviderElement<ShareIntentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShareIntentService create(Ref ref) {
    return shareIntentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareIntentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareIntentService>(value),
    );
  }
}

String _$shareIntentServiceHash() =>
    r'def01c0cbae2b598e45de0199c6c619973fe4f63';

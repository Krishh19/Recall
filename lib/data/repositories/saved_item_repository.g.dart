// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_item_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the active [SavedItemRepository] instance.

@ProviderFor(savedItemRepository)
final savedItemRepositoryProvider = SavedItemRepositoryProvider._();

/// Provides the active [SavedItemRepository] instance.

final class SavedItemRepositoryProvider
    extends
        $FunctionalProvider<
          SavedItemRepository,
          SavedItemRepository,
          SavedItemRepository
        >
    with $Provider<SavedItemRepository> {
  /// Provides the active [SavedItemRepository] instance.
  SavedItemRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedItemRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedItemRepositoryHash();

  @$internal
  @override
  $ProviderElement<SavedItemRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedItemRepository create(Ref ref) {
    return savedItemRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedItemRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedItemRepository>(value),
    );
  }
}

String _$savedItemRepositoryHash() =>
    r'05c1c78025eeaa515c9cb84aed0daa6de43598d0';

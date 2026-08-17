// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the currently selected category filter on the Home feed.

@ProviderFor(SelectedCategory)
final selectedCategoryProvider = SelectedCategoryProvider._();

/// Holds the currently selected category filter on the Home feed.
final class SelectedCategoryProvider
    extends $NotifierProvider<SelectedCategory, String> {
  /// Holds the currently selected category filter on the Home feed.
  SelectedCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCategoryHash();

  @$internal
  @override
  SelectedCategory create() => SelectedCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedCategoryHash() => r'a6d76efd73f48731cc08e800de2fd13185991149';

/// Holds the currently selected category filter on the Home feed.

abstract class _$SelectedCategory extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Holds whether the Home feed should only show unread items.

@ProviderFor(UnreadOnlyFilter)
final unreadOnlyFilterProvider = UnreadOnlyFilterProvider._();

/// Holds whether the Home feed should only show unread items.
final class UnreadOnlyFilterProvider
    extends $NotifierProvider<UnreadOnlyFilter, bool> {
  /// Holds whether the Home feed should only show unread items.
  UnreadOnlyFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadOnlyFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadOnlyFilterHash();

  @$internal
  @override
  UnreadOnlyFilter create() => UnreadOnlyFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$unreadOnlyFilterHash() => r'0ac2d7a2b98a56d13f7e05d8127ec9a07ef65cd1';

/// Holds whether the Home feed should only show unread items.

abstract class _$UnreadOnlyFilter extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Streams saved items for the current selected category and unread filter.

@ProviderFor(savedItemsFeed)
final savedItemsFeedProvider = SavedItemsFeedProvider._();

/// Streams saved items for the current selected category and unread filter.

final class SavedItemsFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedItem>>,
          List<SavedItem>,
          Stream<List<SavedItem>>
        >
    with $FutureModifier<List<SavedItem>>, $StreamProvider<List<SavedItem>> {
  /// Streams saved items for the current selected category and unread filter.
  SavedItemsFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedItemsFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedItemsFeedHash();

  @$internal
  @override
  $StreamProviderElement<List<SavedItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SavedItem>> create(Ref ref) {
    return savedItemsFeed(ref);
  }
}

String _$savedItemsFeedHash() => r'4e85782b73460676bc8e6f578fc7f4a3d918702b';

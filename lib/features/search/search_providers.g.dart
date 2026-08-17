// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the current active search query string.

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

/// Holds the current active search query string.
final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  /// Holds the current active search query string.
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'a2de29f344488b8b351fbfcf9c230f993798b9ea';

/// Holds the current active search query string.

abstract class _$SearchQuery extends $Notifier<String> {
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

/// Provides filtered [SavedItem]s matching the active search query.
/// Matches against title (ilike), summary (ilike), and tags.

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsProvider._();

/// Provides filtered [SavedItem]s matching the active search query.
/// Matches against title (ilike), summary (ilike), and tags.

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedItem>>,
          List<SavedItem>,
          Stream<List<SavedItem>>
        >
    with $FutureModifier<List<SavedItem>>, $StreamProvider<List<SavedItem>> {
  /// Provides filtered [SavedItem]s matching the active search query.
  /// Matches against title (ilike), summary (ilike), and tags.
  SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $StreamProviderElement<List<SavedItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SavedItem>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'3400faca0555e45c20b5efdbdffec4ee1e1456d9';

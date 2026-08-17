import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';

part 'search_providers.g.dart';

/// Holds the current active search query string.
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  /// Updates the search query.
  void setQuery(String query) {
    state = query;
  }

  /// Clears the query.
  void clear() {
    state = '';
  }
}

/// Provides filtered [SavedItem]s matching the active search query.
/// Matches against title (ilike), summary (ilike), and tags.
@riverpod
Stream<List<SavedItem>> searchResults(Ref ref) {
  final repository = ref.watch(savedItemRepositoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return repository.watchItems().map((items) {
    if (query.isEmpty) {
      return items;
    }

    return items.where((item) {
      final titleMatch = item.title?.toLowerCase().contains(query) ?? false;
      final summaryMatch = item.summary?.toLowerCase().contains(query) ?? false;
      final rawContentMatch =
          item.rawContent?.toLowerCase().contains(query) ?? false;
      final tagMatch =
          item.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false;
      final urlMatch = item.url.toLowerCase().contains(query);

      return titleMatch ||
          summaryMatch ||
          rawContentMatch ||
          tagMatch ||
          urlMatch;
    }).toList();
  });
}

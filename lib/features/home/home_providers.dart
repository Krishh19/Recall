import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';

part 'home_providers.g.dart';

/// Available categories and filter tabs in Recall.
const List<String> recallCategories = [
  'All',
  'Unread',
  'Favorites',
  'Blocked',
  'Technology',
  'Business',
  'Health',
  'Education',
  'Entertainment',
  'News',
  'Food',
  'Finance',
  'Other',
];

/// Holds the currently selected category filter on the Home feed.
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String build() => 'All';

  /// Updates the currently selected category.
  void selectCategory(String category) {
    state = category;
  }
}

/// Holds whether the Home feed should only show unread items.
@Riverpod(keepAlive: true)
class UnreadOnlyFilter extends _$UnreadOnlyFilter {
  @override
  bool build() => false;

  /// Sets unread-only filtering.
  void setUnreadOnly(bool value) {
    state = value;
  }

  /// Toggles the unread-only filtering state.
  void toggle() {
    state = !state;
  }
}

/// Streams saved items for the current selected category and unread filter.
@riverpod
Stream<List<SavedItem>> savedItemsFeed(Ref ref) {
  final category = ref.watch(selectedCategoryProvider);
  final unreadOnly = ref.watch(unreadOnlyFilterProvider);
  final repository = ref.watch(savedItemRepositoryProvider);

  return repository.watchItems(
    category: category,
    unreadOnly: unreadOnly || category == 'Unread',
    favoritesOnly: category == 'Favorites',
    status: category == 'Blocked' ? 'failed' : null,
  );
}

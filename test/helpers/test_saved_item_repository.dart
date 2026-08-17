import 'package:recall/core/database/app_database.dart';
import 'package:recall/core/services/content_processing_service.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';

/// Test double implementing [SavedItemRepository] for widget and unit tests.
class TestSavedItemRepository implements SavedItemRepository {
  TestSavedItemRepository({List<SavedItem>? items})
      : items = items ?? <SavedItem>[];

  final List<SavedItem> items;
  final List<String> toggledFavoriteIds = [];
  final List<String> toggledReadIds = [];
  final List<String> deletedIds = [];
  final List<String> retriedIds = [];

  @override
  AppDatabase get database => throw UnimplementedError();

  @override
  ContentProcessingService get processingService => throw UnimplementedError();

  @override
  Stream<List<SavedItem>> watchItems({
    String? category,
    bool unreadOnly = false,
    bool favoritesOnly = false,
    String? status,
  }) {
    var result = List<SavedItem>.from(items);
    if (category != null &&
        category != 'All' &&
        category != 'Unread' &&
        category != 'Favorites' &&
        category != 'Blocked') {
      result = result.where((i) => i.category == category).toList();
    }
    if (unreadOnly || category == 'Unread') {
      result = result.where((i) => !i.isRead).toList();
    }
    if (favoritesOnly || category == 'Favorites') {
      result = result.where((i) => i.isFavorite).toList();
    }
    if (status != null || category == 'Blocked') {
      result = result.where((i) => i.status == (status ?? 'failed')).toList();
    }
    return Stream.value(result);
  }

  @override
  Stream<SavedItem?> watchItem(String id) {
    final match = items.where((i) => i.id == id);
    return Stream.value(match.isEmpty ? null : match.first);
  }

  @override
  Future<SavedItem?> getItem(String id) async {
    final match = items.where((i) => i.id == id);
    return match.isEmpty ? null : match.first;
  }

  @override
  Future<SavedItem?> getItemByUrl(String url) async {
    final match = items.where((i) => i.url == url);
    return match.isEmpty ? null : match.first;
  }

  @override
  Future<List<SavedItem>> getAllItems() async {
    return List<SavedItem>.from(items);
  }

  @override
  Future<SavedItem> createInitialItem({
    required String url,
    required String platform,
  }) async {
    final item = SavedItem(
      id: 'test-item-${DateTime.now().millisecondsSinceEpoch}',
      url: url,
      platform: platform,
      createdAt: DateTime.now(),
    );
    items.add(item);
    return item;
  }

  @override
  Future<void> triggerProcessing({
    required String id,
    required String url,
  }) async {}

  @override
  Future<void> retryItem(SavedItem item) async {
    retriedIds.add(item.id);
  }

  @override
  Future<void> updateAndResummarize({
    required String id,
    required String textContent,
    String? title,
  }) async {
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      items[index] = items[index].copyWith(
        rawContent: textContent,
        title: title ?? items[index].title,
        status: 'done',
      );
    }
  }

  @override
  Future<void> toggleFavorite({
    required String id,
    required bool isFavorite,
  }) async {
    toggledFavoriteIds.add(id);
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      items[index] = items[index].copyWith(isFavorite: isFavorite);
    }
  }

  @override
  Future<void> toggleRead({required String id, required bool isRead}) async {
    toggledReadIds.add(id);
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      items[index] = items[index].copyWith(isRead: isRead);
    }
  }

  @override
  Future<void> bulkToggleFavorite({
    required List<String> ids,
    required bool isFavorite,
  }) async {
    toggledFavoriteIds.addAll(ids);
  }

  @override
  Future<void> bulkToggleRead({
    required List<String> ids,
    required bool isRead,
  }) async {
    toggledReadIds.addAll(ids);
  }

  @override
  Future<void> deleteItem(String id) async {
    deletedIds.add(id);
    items.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> bulkDelete({required List<String> ids}) async {
    deletedIds.addAll(ids);
    items.removeWhere((i) => ids.contains(i.id));
  }

  @override
  Future<int> getUnreadCountPast7Days() async => 0;
}

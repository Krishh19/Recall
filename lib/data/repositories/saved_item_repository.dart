import 'dart:async';
import 'package:drift/drift.dart';
import 'package:recall/core/database/app_database.dart';
import 'package:recall/core/services/content_processing_service.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_item_repository.g.dart';

/// Repository handling local SQLite persistence for [SavedItem]s via Drift.
class SavedItemRepository {
  /// Creates a [SavedItemRepository] instance.
  SavedItemRepository({
    required this.database,
    required this.processingService,
  });

  /// The local database instance.
  final AppDatabase database;

  /// The content extraction and AI processing service.
  final ContentProcessingService processingService;

  /// Generates a simple unique ID for local storage.
  String _generateId() =>
      'item_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000)}';

  /// Inserts a new initial [SavedItem] with status 'processing'
  /// and kicks off in-app content extraction and AI summarization asynchronously.
  Future<SavedItem> createInitialItem({
    required String url,
    required String platform,
  }) async {
    final id = _generateId();
    final now = DateTime.now();

    final companion = SavedItemsTableCompanion(
      id: Value(id),
      url: Value(url),
      platform: Value(platform),
      status: const Value('processing'),
      isRead: const Value(false),
      isFavorite: const Value(false),
      createdAt: Value(now),
    );

    await database.into(database.savedItemsTable).insert(companion);

    final item = SavedItem(
      id: id,
      url: url,
      platform: platform,
      status: 'processing',
      isRead: false,
      isFavorite: false,
      createdAt: now,
    );

    // Run extraction & Gemini AI processing in the background
    unawaited(triggerProcessing(id: id, url: url));
    return item;
  }

  /// Triggers background extraction and AI summarization.
  Future<void> triggerProcessing({
    required String id,
    required String url,
  }) async {
    await processingService.processItem(id: id, url: url);
  }

  /// Re-summarizes an item using manually supplied text from the user.
  Future<void> updateAndResummarize({
    required String id,
    required String textContent,
    String? title,
  }) async {
    final existing = await getItem(id);
    final resolvedTitle = title ?? existing?.title ?? 'Saved Link';
    await processingService.summarizeManualText(
      id: id,
      title: resolvedTitle,
      textContent: textContent,
    );
  }

  /// Retries processing for a previously failed [SavedItem].
  Future<void> retryItem(SavedItem item) async {
    await (database.update(database.savedItemsTable)
          ..where((t) => t.id.equals(item.id)))
        .write(
          const SavedItemsTableCompanion(
            status: Value('processing'),
            summary: Value(null),
          ),
        );
    unawaited(triggerProcessing(id: item.id, url: item.url));
  }

  /// Streams all saved items ordered chronologically descending, with optional category, unread, favorites, and status filtering.
  Stream<List<SavedItem>> watchItems({
    String? category,
    bool unreadOnly = false,
    bool favoritesOnly = false,
    String? status,
  }) {
    return database
        .watchAllItems(
          category: category,
          unreadOnly: unreadOnly,
          favoritesOnly: favoritesOnly,
          status: status,
        )
        .map((rows) => rows.map(SavedItem.fromDrift).toList());
  }

  /// Streams a single saved item by [id].
  Stream<SavedItem?> watchItem(String id) {
    return database.watchItemById(id).map(
          (row) => row != null ? SavedItem.fromDrift(row) : null,
        );
  }

  /// Fetches a single saved item by [id].
  Future<SavedItem?> getItem(String id) async {
    final row = await database.getItemById(id);
    return row != null ? SavedItem.fromDrift(row) : null;
  }

  /// Checks if an item with the given [url] is already saved in the library.
  Future<SavedItem?> getItemByUrl(String url) async {
    final row = await database.getItemByUrl(url);
    return row != null ? SavedItem.fromDrift(row) : null;
  }

  /// Fetches all items in the database (e.g. for export).
  Future<List<SavedItem>> getAllItems() async {
    final rows = await database.getAllItems();
    return rows.map(SavedItem.fromDrift).toList();
  }

  /// Toggles the `is_read` (archived) status of a saved item.
  Future<void> toggleRead({required String id, required bool isRead}) async {
    await (database.update(database.savedItemsTable)
          ..where((t) => t.id.equals(id)))
        .write(SavedItemsTableCompanion(isRead: Value(isRead)));
  }

  /// Toggles the `is_favorite` status of a saved item.
  Future<void> toggleFavorite({
    required String id,
    required bool isFavorite,
  }) async {
    await (database.update(database.savedItemsTable)
          ..where((t) => t.id.equals(id)))
        .write(SavedItemsTableCompanion(isFavorite: Value(isFavorite)));
  }

  /// Bulk updates the `is_read` (archived) status for multiple items.
  Future<void> bulkToggleRead({
    required List<String> ids,
    required bool isRead,
  }) async {
    await (database.update(database.savedItemsTable)
          ..where((t) => t.id.isIn(ids)))
        .write(SavedItemsTableCompanion(isRead: Value(isRead)));
  }

  /// Bulk updates the `is_favorite` status for multiple items.
  Future<void> bulkToggleFavorite({
    required List<String> ids,
    required bool isFavorite,
  }) async {
    await (database.update(database.savedItemsTable)
          ..where((t) => t.id.isIn(ids)))
        .write(SavedItemsTableCompanion(isFavorite: Value(isFavorite)));
  }

  /// Deletes a saved item permanently.
  Future<void> deleteItem(String id) async {
    await (database.delete(database.savedItemsTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Bulk deletes multiple saved items.
  Future<void> bulkDelete({required List<String> ids}) async {
    await (database.delete(database.savedItemsTable)
          ..where((t) => t.id.isIn(ids)))
        .go();
  }

  /// Returns count of unread items saved in the past 7 days for the weekly notification digest.
  Future<int> getUnreadCountPast7Days() async {
    return database.getUnreadCountPast7Days();
  }
}

/// Provides the active [SavedItemRepository] instance.
@Riverpod(keepAlive: true)
SavedItemRepository savedItemRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final processingService = ref.watch(contentProcessingServiceProvider);
  return SavedItemRepository(
    database: db,
    processingService: processingService,
  );
}

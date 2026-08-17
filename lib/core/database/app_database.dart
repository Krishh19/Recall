import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

/// Table definition for locally persisted [SavedItems].
class SavedItemsTable extends Table {
  /// Unique identifier (UUID).
  TextColumn get id => text()();

  /// Original target URL.
  TextColumn get url => text()();

  /// Detected platform: 'twitter' | 'instagram' | 'youtube' | 'article'.
  TextColumn get platform => text()();

  /// Page/video/post title.
  TextColumn get title => text().nullable()();

  /// Media thumbnail image URL.
  TextColumn get thumbnailUrl => text().nullable()();

  /// Extracted raw content/transcript/article markdown.
  TextColumn get rawContent => text().nullable()();

  /// Plain-language AI summary.
  TextColumn get summary => text().nullable()();

  /// JSON-encoded array of key bullet points.
  TextColumn get keyPoints => text().nullable()();

  /// Detected or assigned category.
  TextColumn get category => text().nullable()();

  /// JSON-encoded array of lowercase tag strings.
  TextColumn get tags => text().nullable()();

  /// Current processing lifecycle status: 'processing' | 'done' | 'failed'.
  TextColumn get status => text().withDefault(const Constant('processing'))();

  /// Read / archived status.
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  /// Bookmarked / favorited status.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// The local Drift SQLite database for Recall.
@DriftDatabase(tables: [SavedItemsTable])
class AppDatabase extends _$AppDatabase {
  /// Default constructor using local Drift storage.
  AppDatabase() : super(_openConnection());

  /// Testing constructor for in-memory databases.
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'recall_database');
  }

  /// Streams saved items ordered chronologically descending, with optional category, unread, favorites, and status filtering.
  Stream<List<SavedItemsTableData>> watchAllItems({
    String? category,
    bool unreadOnly = false,
    bool favoritesOnly = false,
    String? status,
  }) {
    final query = select(savedItemsTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (category != null &&
        category != 'All' &&
        category != 'Unread' &&
        category != 'Favorites' &&
        category != 'Blocked') {
      query.where((t) => t.category.equals(category));
    }
    if (unreadOnly || category == 'Unread') {
      query.where((t) => t.isRead.equals(false));
    }
    if (favoritesOnly || category == 'Favorites') {
      query.where((t) => t.isFavorite.equals(true));
    }
    if (status != null || category == 'Blocked') {
      query.where((t) => t.status.equals(status ?? 'failed'));
    }

    return query.watch();
  }

  /// Streams a single saved item by its [id].
  Stream<SavedItemsTableData?> watchItemById(String id) {
    return (select(savedItemsTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Fetches a single saved item by its [id].
  Future<SavedItemsTableData?> getItemById(String id) {
    return (select(savedItemsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Fetches a saved item by its [url] for duplicate detection.
  Future<SavedItemsTableData?> getItemByUrl(String url) {
    return (select(savedItemsTable)..where((t) => t.url.equals(url)))
        .getSingleOrNull();
  }

  /// Fetches all saved items in the database.
  Future<List<SavedItemsTableData>> getAllItems() {
    return (select(savedItemsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Computes count of unread items saved in the past 7 days.
  Future<int> getUnreadCountPast7Days() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final count = countAll(
      filter: savedItemsTable.isRead.equals(false) &
          savedItemsTable.createdAt.isBiggerOrEqualValue(cutoff),
    );
    final query = selectOnly(savedItemsTable)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}

/// Provides the active [AppDatabase] instance.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:recall/core/database/app_database.dart';
import 'package:recall/core/extraction/content_extractor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_processing_service.g.dart';

/// Orchestrates in-app link extraction and Gemini AI summarization,
/// persisting the completed metadata directly into the local Drift SQLite database.
class ContentProcessingService {
  /// Creates a [ContentProcessingService].
  ContentProcessingService({
    required this.database,
    required this.extractor,
    required this.gemini,
  });

  /// The local Drift SQLite database instance.
  final AppDatabase database;

  /// The content extraction service.
  final ContentExtractor extractor;

  /// The Gemini AI summarization service.
  final GeminiService gemini;

  /// Processes a saved item by extracting its content and running Gemini AI summarization.
  Future<void> processItem({
    required String id,
    required String url,
  }) async {
    try {
      debugPrint('Processing item $id: Extracting content from $url...');
      final extracted = await extractor.extract(url);

      // Anti-hallucination validation gate:
      // If content could not be read or is blocked by auth/bot wall,
      // do not call Gemini to produce a generic hallucinated summary.
      if (!extracted.isSubstantive) {
        debugPrint(
          'Extraction for item $id produced non-substantive content. Marking as failed.',
        );
        await (database.update(database.savedItemsTable)
              ..where((t) => t.id.equals(id)))
            .write(
              SavedItemsTableCompanion(
                title: Value(extracted.title),
                thumbnailUrl: Value(extracted.thumbnailUrl),
                rawContent: Value(extracted.rawContent),
                summary: Value(
                  extracted.errorMessage ??
                      'Unable to read post content automatically (requires login or scraper was blocked).',
                ),
                category: const Value('Other'),
                status: const Value('failed'),
              ),
            );
        return;
      }

      debugPrint('Summarizing item $id with Gemini...');
      final aiResult = await gemini.summarize(
        title: extracted.title,
        content: extracted.rawContent,
      );

      if (aiResult.isCannotSummarize) {
        await (database.update(database.savedItemsTable)
              ..where((t) => t.id.equals(id)))
            .write(
              SavedItemsTableCompanion(
                title: Value(extracted.title),
                thumbnailUrl: Value(extracted.thumbnailUrl),
                rawContent: Value(extracted.rawContent),
                summary: const Value(
                  'Content does not contain enough readable text to summarize.',
                ),
                category: const Value('Other'),
                status: const Value('failed'),
              ),
            );
        return;
      }

      await (database.update(database.savedItemsTable)
            ..where((t) => t.id.equals(id)))
          .write(
            SavedItemsTableCompanion(
              title: Value(extracted.title),
              thumbnailUrl: Value(extracted.thumbnailUrl),
              rawContent: Value(extracted.rawContent),
              summary: Value(aiResult.summary),
              keyPoints: Value(jsonEncode(aiResult.keyPoints)),
              category: Value(aiResult.category),
              tags: Value(jsonEncode(aiResult.tags)),
              status: const Value('done'),
            ),
          );

      debugPrint('Item $id successfully processed and summarized.');
    } catch (e) {
      debugPrint('Failed to process item $id: $e');
      await (database.update(database.savedItemsTable)
            ..where((t) => t.id.equals(id)))
          .write(
            SavedItemsTableCompanion(
              status: const Value('failed'),
              summary: Value('Processing error: ${e.toString()}'),
            ),
          );
    }
  }

  /// Re-summarizes an item with user-provided text content (manual paste).
  Future<void> summarizeManualText({
    required String id,
    required String title,
    required String textContent,
  }) async {
    try {
      debugPrint('Summarizing manual content for item $id with Gemini...');
      await (database.update(database.savedItemsTable)
            ..where((t) => t.id.equals(id)))
          .write(
            SavedItemsTableCompanion(
              rawContent: Value(textContent),
              status: const Value('processing'),
            ),
          );

      final aiResult = await gemini.summarize(
        title: title,
        content: textContent,
      );

      await (database.update(database.savedItemsTable)
            ..where((t) => t.id.equals(id)))
          .write(
            SavedItemsTableCompanion(
              title: Value(title),
              rawContent: Value(textContent),
              summary: Value(aiResult.summary),
              keyPoints: Value(jsonEncode(aiResult.keyPoints)),
              category: Value(aiResult.category),
              tags: Value(jsonEncode(aiResult.tags)),
              status: const Value('done'),
            ),
          );
      debugPrint('Manual text for item $id successfully summarized.');
    } catch (e) {
      debugPrint('Failed to summarize manual text for item $id: $e');
      await (database.update(database.savedItemsTable)
            ..where((t) => t.id.equals(id)))
          .write(
            SavedItemsTableCompanion(
              status: const Value('failed'),
              summary: Value('Summarization error: ${e.toString()}'),
            ),
          );
    }
  }
}

/// Provides the active [ContentProcessingService] instance.
@Riverpod(keepAlive: true)
ContentProcessingService contentProcessingService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final gemini = ref.watch(geminiServiceProvider);
  return ContentProcessingService(
    database: db,
    extractor: ContentExtractor(),
    gemini: gemini,
  );
}

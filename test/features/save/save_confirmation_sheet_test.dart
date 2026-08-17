import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/save/widgets/save_confirmation_sheet.dart';
import '../../helpers/test_saved_item_repository.dart';

class MockSavedItemRepository extends TestSavedItemRepository {
  MockSavedItemRepository({required super.items});

  List<SavedItem> get retriedItems =>
      items.where((i) => retriedIds.contains(i.id)).toList();
}

void main() {
  final processingItem = SavedItem(
    id: 'item-proc',
    url: 'https://techcrunch.com/article',
    platform: 'article',
    title: 'AI Breakthroughs in 2026',
    status: 'processing',
    createdAt: DateTime(2026, 8, 16),
  );

  final doneItem = SavedItem(
    id: 'item-done',
    url: 'https://youtube.com/watch?v=999',
    platform: 'youtube',
    title: 'Flutter Expressive UI Tutorial',
    summary: 'Mastering Material 3 Expressive motion and components.',
    category: 'Technology',
    tags: const ['flutter', 'ui'],
    status: 'done',
    createdAt: DateTime(2026, 8, 16),
  );

  final failedItem = SavedItem(
    id: 'item-fail',
    url: 'https://example.com/bad-url',
    platform: 'article',
    status: 'failed',
    summary: 'Network timeout',
    createdAt: DateTime(2026, 8, 16),
  );

  Widget createWidget({
    required List<SavedItem> items,
    required String itemId,
    MockSavedItemRepository? customRepo,
  }) {
    final mockRepo = customRepo ?? MockSavedItemRepository(items: items);

    return ProviderScope(
      overrides: [savedItemRepositoryProvider.overrideWithValue(mockRepo)],
      child: MaterialApp(
        theme: AppTheme.light.toThemeData(),
        builder: (context, child) => M3ETheme(
          data: AppTheme.light,
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(body: SaveConfirmationSheet(itemId: itemId)),
      ),
    );
  }

  testWidgets('renders "Saved to Recall" and "Summarizing…" when processing', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidget(items: [processingItem], itemId: processingItem.id),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Saved to Recall'), findsOneWidget);
    expect(find.text('AI Breakthroughs in 2026'), findsOneWidget);
    expect(find.text('Summarizing…'), findsOneWidget);
    expect(find.byType(M3EProgressIndicator), findsOneWidget);
  });

  testWidgets('renders category chip and "View Details" button when done', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidget(items: [doneItem], itemId: doneItem.id),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Saved to Recall'), findsOneWidget);
    expect(find.text('Flutter Expressive UI Tutorial'), findsOneWidget);
    expect(find.text('Technology'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
  });

  testWidgets('renders retry button when status is failed', (tester) async {
    final mockRepo = MockSavedItemRepository(items: [failedItem]);

    await tester.pumpWidget(
      createWidget(
        items: [failedItem],
        itemId: failedItem.id,
        customRepo: mockRepo,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("Couldn't process — tap to retry"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(mockRepo.retriedItems, contains(failedItem));
  });
}

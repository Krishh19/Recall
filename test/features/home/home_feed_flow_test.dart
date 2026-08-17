import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/home/home_screen.dart';
import 'package:recall/features/home/widgets/category_filter_row.dart';
import '../../helpers/test_saved_item_repository.dart';

class MockSavedItemRepository extends TestSavedItemRepository {
  MockSavedItemRepository(List<SavedItem> items) : super(items: items);

  List<String> get archivedIds => toggledReadIds;
  List<SavedItem> get retried =>
      items.where((i) => retriedIds.contains(i.id)).toList();
}

void main() {
  final sampleItems = [
    SavedItem(
      id: 'item-tech-1',
      url: 'https://flutter.dev',
      platform: 'article',
      title: 'Flutter 3.44 Release Notes',
      summary: 'Detailed summary of Flutter 3.44 features.',
      category: 'Technology',
      tags: const ['flutter', 'dart'],
      status: 'done',
      isRead: false,
      createdAt: DateTime(2026, 8, 16),
    ),
    SavedItem(
      id: 'item-biz-1',
      url: 'https://bloomberg.com/news',
      platform: 'article',
      title: 'Global Tech Economy Surge',
      summary: 'Markets rally on AI computing infrastructure.',
      category: 'Business',
      status: 'done',
      isRead: true,
      createdAt: DateTime(2026, 8, 15),
    ),
    SavedItem(
      id: 'item-proc-1',
      url: 'https://youtube.com/watch?v=sample',
      platform: 'youtube',
      status: 'processing',
      isRead: false,
      createdAt: DateTime(2026, 8, 14),
    ),
    SavedItem(
      id: 'item-fail-1',
      url: 'https://twitter.com/x/status/123',
      platform: 'twitter',
      status: 'failed',
      isRead: false,
      createdAt: DateTime(2026, 8, 13),
    ),
  ];

  Widget buildTestScreen(MockSavedItemRepository mockRepo) {
    return ProviderScope(
      overrides: [savedItemRepositoryProvider.overrideWithValue(mockRepo)],
      child: MaterialApp(
        theme: AppTheme.light.toThemeData(),
        builder: (context, child) =>
            M3ETheme(data: AppTheme.light, child: child!),
        home: const HomeScreen(),
      ),
    );
  }

  testWidgets('renders feed items with processing, done, and failed states', (
    tester,
  ) async {
    final mockRepo = MockSavedItemRepository(sampleItems);
    await tester.pumpWidget(buildTestScreen(mockRepo));
    await tester.pump();

    // Done items
    expect(find.text('Flutter 3.44 Release Notes'), findsOneWidget);
    expect(
      find.text('Detailed summary of Flutter 3.44 features.'),
      findsOneWidget,
    );
    expect(find.text('Technology'), findsWidgets);

    // Processing item
    expect(find.text('Summarizing with AI…'), findsOneWidget);

    // Failed item
    expect(find.text("Couldn't process — tap to retry"), findsOneWidget);
  });

  testWidgets('filters feed when Category chip is selected', (tester) async {
    final mockRepo = MockSavedItemRepository(sampleItems);
    await tester.pumpWidget(buildTestScreen(mockRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Initial state: shows both tech and business
    expect(find.text('Flutter 3.44 Release Notes'), findsOneWidget);
    expect(find.text('Global Tech Economy Surge'), findsOneWidget);

    // Tap 'Technology' filter chip in CategoryFilterRow
    await tester.tap(
      find.descendant(
        of: find.byType(CategoryFilterRow),
        matching: find.text('Technology'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Only Tech item displayed
    expect(find.text('Flutter 3.44 Release Notes'), findsOneWidget);
    expect(find.text('Global Tech Economy Surge'), findsNothing);

    // Tap 'All' to restore
    await tester.tap(
      find.descendant(
        of: find.byType(CategoryFilterRow),
        matching: find.text('All'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Flutter 3.44 Release Notes'), findsOneWidget);
    expect(find.text('Global Tech Economy Surge'), findsOneWidget);
  });

  testWidgets('filters feed when Unread chip is selected', (tester) async {
    final mockRepo = MockSavedItemRepository(sampleItems);
    await tester.pumpWidget(buildTestScreen(mockRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap 'Unread' filter chip in CategoryFilterRow
    await tester.tap(
      find.descendant(
        of: find.byType(CategoryFilterRow),
        matching: find.text('Unread'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Unread items are visible, Read item (Global Tech Economy Surge) is filtered out
    expect(find.text('Flutter 3.44 Release Notes'), findsOneWidget);
    expect(find.text('Global Tech Economy Surge'), findsNothing);
  });

  testWidgets('swiping item triggers archive (toggleRead) on repository', (
    tester,
  ) async {
    final mockRepo = MockSavedItemRepository(sampleItems);
    await tester.pumpWidget(buildTestScreen(mockRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final techItemFinder = find.byKey(
      const ValueKey('dismissible_item-tech-1'),
    );
    expect(techItemFinder, findsOneWidget);

    // Drag from right to left to trigger archive swipe
    await tester.drag(techItemFinder, const Offset(-500, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(mockRepo.archivedIds, contains('item-tech-1'));
  });

  testWidgets('tapping failed item triggers retry on repository', (
    tester,
  ) async {
    final mockRepo = MockSavedItemRepository(sampleItems);
    await tester.pumpWidget(buildTestScreen(mockRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Blocked').last);
    await tester.pump();

    expect(mockRepo.retried.length, 1);
    expect(mockRepo.retried.first.id, 'item-fail-1');
  });
}

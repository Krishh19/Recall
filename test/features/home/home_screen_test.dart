import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/home/home_screen.dart';
import 'package:recall/features/home/widgets/category_filter_row.dart';
import 'package:recall/features/home/widgets/feed_empty_state.dart';
import 'package:recall/features/home/widgets/feed_item_tile.dart';
import '../../helpers/test_saved_item_repository.dart';

void main() {
  setUp(() {
    ReceiveSharingIntent.setMockValues(
      initialMedia: [],
      mediaStream: const Stream.empty(),
    );
  });

  final sampleItems = [
    SavedItem(
      id: '1',
      url: 'https://youtube.com/watch?v=123',
      platform: 'youtube',
      title: 'Flutter Architecture 101',
      summary: 'A deep dive into clean architecture in Flutter apps.',
      category: 'Technology',
      tags: const ['flutter', 'dart'],
      status: 'done',
      createdAt: DateTime.now(),
    ),
    SavedItem(
      id: '2',
      url: 'https://twitter.com/user/status/456',
      platform: 'twitter',
      title: 'Healthy Morning Routines',
      summary: '10 habits that can transform your daily energy levels.',
      category: 'Health',
      tags: const ['health', 'habits'],
      status: 'done',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    SavedItem(
      id: '3',
      url: 'https://article.com/market-trends',
      platform: 'article',
      title: 'Market Trends 2026',
      status: 'processing',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SavedItem(
      id: '4',
      url: 'https://instagram.com/p/fail',
      platform: 'instagram',
      title: 'Broken Link Example',
      status: 'failed',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  Widget createWidgetUnderTest(TestSavedItemRepository repository) {
    return ProviderScope(
      overrides: [
        savedItemRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light.toThemeData(),
        home: M3ETheme(
          data: AppTheme.light,
          child: const HomeScreen(),
        ),
      ),
    );
  }

  group('HomeScreen Feed Widget Tests', () {
    testWidgets('renders category filter row and all feed items', (
      tester,
    ) async {
      final repository = TestSavedItemRepository(items: sampleItems);

      await tester.pumpWidget(createWidgetUnderTest(repository));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CategoryFilterRow), findsOneWidget);
      expect(find.byType(FeedItemTile), findsNWidgets(4));
    });

    testWidgets('renders empty state when no items exist', (tester) async {
      final repository = TestSavedItemRepository(items: []);

      await tester.pumpWidget(createWidgetUnderTest(repository));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FeedEmptyState), findsOneWidget);
      expect(find.text('Your Recall library is empty'), findsOneWidget);
    });

    testWidgets('filtering by category displays only matching items', (
      tester,
    ) async {
      final repository = TestSavedItemRepository(items: sampleItems);

      await tester.pumpWidget(createWidgetUnderTest(repository));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FeedItemTile), findsNWidgets(4));

      // Tap on 'Technology' filter chip in CategoryFilterRow
      final techChip = find.descendant(
        of: find.byType(CategoryFilterRow),
        matching: find.text('Technology'),
      );
      expect(techChip, findsOneWidget);
      await tester.tap(techChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Now only 1 item should be visible (Flutter Architecture 101)
      expect(find.byType(FeedItemTile), findsOneWidget);
      expect(find.text('Flutter Architecture 101'), findsOneWidget);
    });
  });
}

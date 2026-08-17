import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/search/search_providers.dart';
import 'package:recall/features/search/search_screen.dart';
import '../../helpers/test_saved_item_repository.dart';

class MockSavedItemRepository extends TestSavedItemRepository {
  MockSavedItemRepository({required super.items});
}

void main() {
  final item1 = SavedItem(
    id: 'item-1',
    url: 'https://flutter.dev',
    platform: 'article',
    title: 'Flutter Architectural Overview',
    summary: 'Deep dive into widget trees and render objects.',
    tags: const ['flutter', 'architecture'],
    status: 'done',
    createdAt: DateTime(2026, 8, 16),
  );

  final item2 = SavedItem(
    id: 'item-2',
    url: 'https://youtube.com/watch?v=123',
    platform: 'youtube',
    title: 'Modern TypeScript Edge Functions',
    summary: 'Writing serverless endpoints on Deno.',
    tags: const ['typescript', 'deno', 'backend'],
    status: 'done',
    createdAt: DateTime(2026, 8, 16),
  );

  Widget createWidget({required List<SavedItem> items, String? initialQuery}) {
    final mockRepo = MockSavedItemRepository(items: items);

    return ProviderScope(
      overrides: [
        savedItemRepositoryProvider.overrideWithValue(mockRepo),
        if (initialQuery != null)
          searchQueryProvider.overrideWith(() => _PreloadedQuery(initialQuery)),
      ],
      child: MaterialApp(
        theme: AppTheme.light.toThemeData(),
        builder: (context, child) => M3ETheme(
          data: AppTheme.light,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SearchScreen(),
      ),
    );
  }

  testWidgets('renders empty search placeholder initially', (tester) async {
    await tester.pumpWidget(createWidget(items: [item1, item2]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Search your saved links'), findsOneWidget);
    expect(
      find.text('Search through AI summaries, titles, and topics'),
      findsOneWidget,
    );
  });

  testWidgets('filters items matching title query', (tester) async {
    await tester.pumpWidget(
      createWidget(items: [item1, item2], initialQuery: 'Flutter'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Flutter Architectural Overview'), findsOneWidget);
    expect(find.text('Modern TypeScript Edge Functions'), findsNothing);
  });

  testWidgets('filters items matching tag query', (tester) async {
    await tester.pumpWidget(
      createWidget(items: [item1, item2], initialQuery: 'backend'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Modern TypeScript Edge Functions'), findsOneWidget);
    expect(find.text('Flutter Architectural Overview'), findsNothing);
  });

  testWidgets('renders no results found state when query matches nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidget(items: [item1, item2], initialQuery: 'nonexistent-term-xyz'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No results found'), findsOneWidget);
    expect(
      find.text('Try searching for a different keyword or tag'),
      findsOneWidget,
    );
  });
}

class _PreloadedQuery extends SearchQuery {
  _PreloadedQuery(this._query);
  final String _query;

  @override
  String build() => _query;
}

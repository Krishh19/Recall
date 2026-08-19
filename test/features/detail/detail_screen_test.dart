import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/providers/theme_controller.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/detail/detail_screen.dart';
import '../../helpers/test_saved_item_repository.dart';

void main() {
  final sampleItem = SavedItem(
    id: 'item-123',
    url: 'https://youtube.com/watch?v=123',
    platform: 'youtube',
    title: 'Understanding Flutter Riverpod',
    summary: 'A comprehensive guide on modern Flutter state management.',
    keyPoints: const [
      'Declarative code generation with @riverpod',
      'Scoped dependency injection',
      'Reactive stream handling',
    ],
    category: 'Technology',
    tags: const ['flutter', 'riverpod', 'dart'],
    status: 'done',
    isRead: false,
    isFavorite: false,
    createdAt: DateTime.now(),
  );

  Widget createWidgetUnderTest({
    required String id,
    required TestSavedItemRepository repository,
  }) {
    return ProviderScope(
      overrides: [
        savedItemRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light.toThemeData(),
        home: M3ETheme(
          data: AppTheme.light,
          child: DetailScreen(id: id),
        ),
      ),
    );
  }

  group('DetailScreen Widget Tests', () {
    testWidgets('renders item title, summary, chips, and key points', (
      tester,
    ) async {
      final repository = TestSavedItemRepository(items: [sampleItem]);

      await tester.pumpWidget(
        createWidgetUnderTest(id: sampleItem.id, repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Understanding Flutter Riverpod'), findsOneWidget);
      expect(
        find.text(
          'A comprehensive guide on modern Flutter state management.',
        ),
        findsOneWidget,
      );
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('#flutter'), findsOneWidget);
      expect(find.text('#riverpod'), findsOneWidget);
      expect(find.text('#dart'), findsOneWidget);
      expect(
        find.text('Declarative code generation with @riverpod'),
        findsOneWidget,
      );
      expect(find.text('Scoped dependency injection'), findsOneWidget);
      expect(find.text('Reactive stream handling'), findsOneWidget);
    });

    testWidgets('toggles favorite when favorite icon is tapped in toolbar', (
      tester,
    ) async {
      final repository = TestSavedItemRepository(items: [sampleItem]);

      await tester.pumpWidget(
        createWidgetUnderTest(id: sampleItem.id, repository: repository),
      );
      await tester.pumpAndSettle();

      final favoriteFinder = find.byIcon(Icons.star_border);
      expect(favoriteFinder, findsOneWidget);

      await tester.tap(favoriteFinder);
      await tester.pump();

      expect(repository.toggledFavoriteIds, contains(sampleItem.id));
    });

    testWidgets('toggles read archive status when archive button is tapped', (
      tester,
    ) async {
      final repository = TestSavedItemRepository(items: [sampleItem]);

      await tester.pumpWidget(
        createWidgetUnderTest(id: sampleItem.id, repository: repository),
      );
      await tester.pumpAndSettle();

      final archiveFinder = find.byIcon(Icons.archive_outlined);
      expect(archiveFinder, findsOneWidget);

      await tester.tap(archiveFinder);
      await tester.pump();

      expect(repository.toggledReadIds, contains(sampleItem.id));
    });

    testWidgets('renders long tag list without layout overflow', (
      tester,
    ) async {
      final itemWithManyTags = sampleItem.copyWith(
        tags: [
          'flutter',
          'dart',
          'riverpod',
          'sqlite',
          'drift',
          'material3',
          'expressive',
          'gemini',
          'ai',
          'mobile',
        ],
      );
      final repository =
          TestSavedItemRepository(items: [itemWithManyTags]);

      await tester.pumpWidget(
        createWidgetUnderTest(
          id: itemWithManyTags.id,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#flutter'), findsOneWidget);
      expect(find.text('#mobile'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode and alternate Emerald theme preset', (
      tester,
    ) async {
      final darkEmeraldScheme = AppTheme.createScheme(
        preset: ThemePreset.emerald,
        brightness: Brightness.dark,
      );
      final repository = TestSavedItemRepository(items: [sampleItem]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedItemRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.buildThemeData(darkEmeraldScheme),
            home: M3ETheme(
              data: AppTheme.darkWithSeed(ThemePreset.emerald.color!),
              child: DetailScreen(id: sampleItem.id),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Understanding Flutter Riverpod'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/save/retry_tracker.dart';
import '../../helpers/test_saved_item_repository.dart';

class MockSavedItemRepository extends TestSavedItemRepository {
  List<String> get retried => retriedIds;
}

void main() {
  final failedItem = SavedItem(
    id: 'item-fail-1',
    url: 'https://example.com/broken',
    platform: 'article',
    status: 'failed',
    summary: 'Extraction failed: 404 Not Found',
    createdAt: DateTime(2026, 8, 16),
  );

  test('RetryTracker increments and resets counts', () {
    // Initial state
    final element = ProviderContainer();
    expect(element.read(retryTrackerProvider)['item-1'], isNull);

    // Increment
    final c1 = element.read(retryTrackerProvider.notifier).increment('item-1');
    expect(c1, 1);
    expect(element.read(retryTrackerProvider)['item-1'], 1);

    final c2 = element.read(retryTrackerProvider.notifier).increment('item-1');
    expect(c2, 2);
    expect(element.read(retryTrackerProvider)['item-1'], 2);

    // Reset
    element.read(retryTrackerProvider.notifier).reset('item-1');
    expect(element.read(retryTrackerProvider)['item-1'], isNull);
  });

  testWidgets('shows warning SnackBar on second consecutive retry', (
    tester,
  ) async {
    final mockRepo = MockSavedItemRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [savedItemRepositoryProvider.overrideWithValue(mockRepo)],
        child: MaterialApp(
          theme: AppTheme.light.toThemeData(),
          builder: (context, child) => M3ETheme(
            data: AppTheme.light,
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () {
                    ref
                        .read(retryTrackerProvider.notifier)
                        .retryItem(context, failedItem);
                  },
                  child: const Text('Trigger Retry'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // First retry
    await tester.tap(find.text('Trigger Retry'));
    await tester.pump();
    expect(mockRepo.retried.length, 1);
    expect(find.byType(SnackBar), findsNothing);

    // Second retry triggers warning SnackBar
    await tester.tap(find.text('Trigger Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(mockRepo.retried.length, 2);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Open Link'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/features/home/widgets/feed_empty_state.dart';

void main() {
  Widget buildEmptyState({
    required String selectedCategory,
    VoidCallback? onResetFilter,
  }) {
    return MaterialApp(
      theme: AppTheme.light.toThemeData(),
      builder: (context, child) =>
          M3ETheme(data: AppTheme.light, child: child!),
      home: Scaffold(
        body: FeedEmptyState(
          selectedCategory: selectedCategory,
          onResetFilter: onResetFilter,
        ),
      ),
    );
  }

  testWidgets('renders Unread empty state with All Caught Up title', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildEmptyState(selectedCategory: 'Unread', onResetFilter: () {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('All Caught Up!'), findsOneWidget);
    expect(find.text('Show All Items'), findsOneWidget);
  });

  testWidgets('renders Favorites empty state with No Favorites Yet title', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildEmptyState(selectedCategory: 'Favorites', onResetFilter: () {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Favorites Yet'), findsOneWidget);
    expect(find.text('Show All Items'), findsOneWidget);
  });

  testWidgets('renders Blocked empty state with No Blocked Links title', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildEmptyState(selectedCategory: 'Blocked', onResetFilter: () {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Blocked Links'), findsOneWidget);
    expect(find.text('Show All Items'), findsOneWidget);
  });

  testWidgets('renders All empty state with library empty title and add link button', (
    tester,
  ) async {
    await tester.pumpWidget(buildEmptyState(selectedCategory: 'All'));
    await tester.pumpAndSettle();

    expect(find.text('Your Recall library is empty'), findsOneWidget);
    expect(find.text('Add Your First Link'), findsOneWidget);
  });
}

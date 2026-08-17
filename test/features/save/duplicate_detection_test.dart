import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/save/widgets/manual_add_url_dialog.dart';
import '../../helpers/test_saved_item_repository.dart';

void main() {
  testWidgets('ManualAddUrlDialog warns on duplicate link', (tester) async {
    final existingItem = SavedItem(
      id: 'existing-123',
      url: 'https://flutter.dev',
      platform: 'article',
      title: 'Flutter Official Site',
      createdAt: DateTime(2026, 8, 17),
    );

    final repository = TestSavedItemRepository(items: [existingItem]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedItemRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light.toThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ManualAddUrlDialog.show(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Enter existing URL
    await tester.enterText(find.byType(TextField), 'https://flutter.dev');
    await tester.tap(find.text('Save & Summarize'));
    await tester.pumpAndSettle();

    // Duplicate detection alert dialog appears
    expect(find.text('Link Already Saved'), findsOneWidget);
    expect(find.text('View Existing'), findsOneWidget);
    expect(find.text('Save New Copy'), findsOneWidget);
  });
}

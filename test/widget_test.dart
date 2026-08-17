import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:recall/app.dart';
import 'package:recall/core/providers/theme_controller.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/home/home_screen.dart';
import 'helpers/test_saved_item_repository.dart';

class _FakeRepository extends TestSavedItemRepository {}

void main() {
  late _FakeRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeRepository();
    ReceiveSharingIntent.setMockValues(
      initialMedia: [],
      mediaStream: const Stream.empty(),
    );
  });

  testWidgets('renders home screen directly on app launch', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [savedItemRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const RecallApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('applies a theme mode override', (tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: [savedItemRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const RecallApp()),
    );
    await tester.pumpAndSettle();

    container
        .read(themeControllerProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(HomeScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}

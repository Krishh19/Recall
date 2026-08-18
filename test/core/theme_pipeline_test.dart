import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:recall/app.dart';
import 'package:recall/core/providers/theme_controller.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/home/home_screen.dart';
import '../helpers/test_saved_item_repository.dart';

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

  group('Theme Pipeline Synchronized Resolution Tests', () {
    test('AppTheme builds coherent light and dark ThemeData from scheme', () {
      final lightScheme = AppTheme.createScheme(
        preset: ThemePreset.oceanBlue,
        brightness: Brightness.light,
      );
      final darkScheme = AppTheme.createScheme(
        preset: ThemePreset.oceanBlue,
        brightness: Brightness.dark,
      );

      final lightTheme = AppTheme.buildThemeData(lightScheme);
      final darkTheme = AppTheme.buildThemeData(darkScheme);

      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, lightScheme.surface);
      expect(lightTheme.cardTheme.color, lightScheme.surfaceContainer);

      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, darkScheme.surface);
      expect(darkTheme.cardTheme.color, darkScheme.surfaceContainer);
    });

    testWidgets(
      'Synchronizes Material ThemeData and M3ETheme brightness on mode switch',
      (tester) async {
        final container = ProviderContainer(
          overrides: [savedItemRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RecallApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Light Mode
        container
            .read(themeControllerProvider.notifier)
            .setThemeMode(ThemeMode.light);
        await tester.pumpAndSettle();

        BuildContext context = tester.element(find.byType(HomeScreen));
        ThemeData currentMaterial = Theme.of(context);
        M3EThemeData currentM3E = M3ETheme.of(context);

        expect(currentMaterial.brightness, Brightness.light);
        expect(currentM3E.colorScheme.brightness, Brightness.light);
        expect(
          currentMaterial.colorScheme.primary,
          currentM3E.colorScheme.primary,
        );
        expect(
          currentMaterial.scaffoldBackgroundColor,
          currentMaterial.colorScheme.surface,
        );

        // 2. Dark Mode
        container
            .read(themeControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        await tester.pumpAndSettle();

        context = tester.element(find.byType(HomeScreen));
        currentMaterial = Theme.of(context);
        currentM3E = M3ETheme.of(context);

        expect(currentMaterial.brightness, Brightness.dark);
        expect(currentM3E.colorScheme.brightness, Brightness.dark);
        expect(
          currentMaterial.colorScheme.primary,
          currentM3E.colorScheme.primary,
        );
        expect(
          currentMaterial.scaffoldBackgroundColor,
          currentMaterial.colorScheme.surface,
        );

        // 3. Preset Switch (e.g. Emerald)
        container
            .read(themePresetControllerProvider.notifier)
            .setPreset(ThemePreset.emerald);
        await tester.pumpAndSettle();

        context = tester.element(find.byType(HomeScreen));
        currentMaterial = Theme.of(context);
        currentM3E = M3ETheme.of(context);

        expect(currentMaterial.brightness, Brightness.dark);
        expect(
          currentMaterial.colorScheme.primary,
          currentM3E.colorScheme.primary,
        );
      },
    );
  });
}

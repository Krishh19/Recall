import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:recall/core/providers/theme_controller.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/profile/profile_screen.dart';
import '../../helpers/test_saved_item_repository.dart';

void main() {
  Widget createProfileTestApp({
    bool isGeminiConfigured = false,
  }) {
    return ProviderScope(
      overrides: [
        savedItemRepositoryProvider
            .overrideWithValue(TestSavedItemRepository(items: [])),
        isGeminiConfiguredProvider
            .overrideWith((ref) => Future.value(isGeminiConfigured)),
      ],
      child: MaterialApp(
        theme: AppTheme.light.toThemeData(),
        home: M3ETheme(
          data: AppTheme.light,
          child: const ProfileScreen(),
        ),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders identity header, AI intelligence, and appearance sections', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createProfileTestApp(isGeminiConfigured: false));
      await tester.pumpAndSettle();

      // Identity Header
      expect(find.text('Recall'), findsOneWidget);
      expect(find.text('Your personal link memory'), findsOneWidget);

      // AI Intelligence
      expect(find.text('AI Intelligence'), findsOneWidget);
      expect(find.text('Google Gemini'), findsOneWidget);
      expect(find.text('Not configured'), findsOneWidget);
      expect(find.text('Configure'), findsOneWidget);

      // Appearance
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Theme Accent options
      expect(find.text('Dynamic'), findsOneWidget);
      expect(find.text('Ocean'), findsOneWidget);
      expect(find.text('Emerald'), findsOneWidget);

      // Storage & Privacy
      expect(find.text('100% Local & Private'), findsOneWidget);

      // About
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.3'), findsOneWidget);
      expect(find.text('Open Source Licenses'), findsOneWidget);
    });

    testWidgets('renders Connected state when Gemini is configured', (
      tester,
    ) async {
      await tester.pumpWidget(createProfileTestApp(isGeminiConfigured: true));
      await tester.pumpAndSettle();

      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Stored securely on this device'), findsOneWidget);
    });

    testWidgets('allows switching theme mode in Profile', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedItemRepositoryProvider
                .overrideWithValue(TestSavedItemRepository(items: [])),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              final mode = ref.watch(themeControllerProvider);
              return MaterialApp(
                themeMode: mode,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                home: const ProfileScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Dark' in theme mode
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Verified without error
    });
  });
}

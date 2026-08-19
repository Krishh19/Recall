import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/onboarding/screens/onboarding_flow_screen.dart';
import 'package:recall/features/onboarding/widgets/ai_gate_prompt.dart';
import '../../helpers/test_saved_item_repository.dart';

class MockSuccessGeminiService extends GeminiService {
  @override
  Future<void> validateApiKey(String candidateKey) async {
    if (candidateKey == 'invalid_key') {
      throw const GeminiValidationException(
        'We couldn\'t verify this API key. Check that you copied the complete key and try again.',
        category: GeminiValidationCategory.invalidKey,
      );
    }
    if (candidateKey == 'network_err') {
      throw const GeminiValidationException(
        'Couldn\'t reach Gemini. Check your internet connection and try again.',
        category: GeminiValidationCategory.networkError,
      );
    }
    if (candidateKey == 'quota_err') {
      throw const GeminiValidationException(
        'Your key is valid, but Gemini isn\'t currently allowing this request.',
        category: GeminiValidationCategory.quotaOrPermission,
      );
    }
    // Valid key
  }

  @override
  Future<void> setApiKey(String key) async {}
}

void main() {
  Widget createOnboardingTestApp({
    GeminiService? geminiService,
    OnboardingStep? initialStep,
  }) {
    return ProviderScope(
      overrides: [
        savedItemRepositoryProvider
            .overrideWithValue(TestSavedItemRepository(items: [])),
        if (geminiService != null)
          geminiServiceProvider.overrideWithValue(geminiService),
      ],
      child: MaterialApp(
        theme: AppTheme.light.toThemeData(),
        home: OnboardingFlowScreen(
          isInlineModal: true,
          initialStep: initialStep,
        ),
      ),
    );
  }

  group('OnboardingFlowScreen State Machine Tests', () {
    testWidgets('Welcome screen renders and navigates to Gemini Intro on Get Started', (
      tester,
    ) async {
      await tester.pumpWidget(createOnboardingTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Recall'), findsOneWidget);
      expect(find.text('Save anything. Remember everything.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Skip setup'), findsAtLeast(1));

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Now on Gemini Intro
      expect(find.text('Make Recall intelligent'), findsOneWidget);
      expect(find.text('✨'), findsOneWidget);
      expect(find.text('Connect Gemini'), findsOneWidget);
      expect(find.text("I'll do this later"), findsAtLeast(1));
    });

    testWidgets('Gemini Intro navigates to Key Entry on Connect Gemini', (
      tester,
    ) async {
      await tester.pumpWidget(createOnboardingTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect Gemini'));
      await tester.pumpAndSettle();

      // On Key Entry screen
      expect(find.text('Connect Gemini'), findsOneWidget);
      expect(find.text('Step 1 — Get your key'), findsOneWidget);
      expect(find.text('Step 2 — Paste your key'), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
    });

    testWidgets('Invalid key produces categorized error message and allows retry', (
      tester,
    ) async {
      final mockService = MockSuccessGeminiService();
      await tester.pumpWidget(
        createOnboardingTestApp(
          geminiService: mockService,
          initialStep: OnboardingStep.geminiKeyEntry,
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid key
      await tester.enterText(find.byType(TextField), 'invalid_key');
      await tester.pumpAndSettle();

      // Tap Verify & Continue
      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      // Verify error banner
      expect(find.text("Couldn't connect to Gemini"), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Get a new key'), findsOneWidget);
      // Input is preserved
      expect(find.text('invalid_key'), findsOneWidget);
    });

    testWidgets('Valid key verifies and displays success screen', (
      tester,
    ) async {
      final mockService = MockSuccessGeminiService();
      await tester.pumpWidget(
        createOnboardingTestApp(
          geminiService: mockService,
          initialStep: OnboardingStep.geminiKeyEntry,
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid key
      await tester.enterText(find.byType(TextField), 'AIzaSyValidCandidate12345');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      // On Success screen
      expect(find.text('✨ Gemini connected'), findsOneWidget);
      expect(find.text('Start using Recall'), findsOneWidget);
    });
  });

  group('AIGatePrompt Widget Tests', () {
    testWidgets('renders inline prompt and opens key entry modal', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light.toThemeData(),
          home: const Scaffold(
            body: AIGatePrompt(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Connect Gemini to unlock AI summaries'),
        findsOneWidget,
      );
      expect(find.text('Connect Gemini'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/settings/settings_screen.dart';
import 'package:recall/features/settings/widgets/gemini_config_sheet.dart';
import '../../helpers/test_saved_item_repository.dart';

class TestGeminiService extends GeminiService {
  TestGeminiService({this.savedKey = ''});

  String savedKey;

  @override
  Future<String> getApiKey() async => savedKey;

  @override
  Future<bool> hasApiKey() async => savedKey.isNotEmpty;

  @override
  Future<void> setApiKey(String key) async {
    savedKey = key;
  }

  @override
  Future<void> validateApiKey(String candidateKey) async {
    final trimmed = candidateKey.trim();
    if (trimmed.isEmpty) {
      throw const GeminiValidationException('Please enter a valid API key.');
    }
    if (trimmed == 'invalid-key') {
      throw const GeminiValidationException(
        'This API key was rejected by Gemini. Check that the key is correct and has Gemini API access enabled.',
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestSavedItemRepository repo;
  late TestGeminiService geminiService;

  setUp(() {
    repo = TestSavedItemRepository();
    geminiService = TestGeminiService();
  });

  group('GeminiService BYOK validation logic', () {
    test('validateApiKey throws on empty string', () async {
      expect(
        () => geminiService.validateApiKey(''),
        throwsA(isA<GeminiValidationException>()),
      );
    });

    test('validateApiKey throws on invalid key', () async {
      expect(
        () => geminiService.validateApiKey('invalid-key'),
        throwsA(isA<GeminiValidationException>()),
      );
    });
  });

  group('SettingsScreen BYOK UI Tests', () {
    testWidgets('renders unconfigured state when no API key is saved', (tester) async {
      geminiService = TestGeminiService(savedKey: '');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedItemRepositoryProvider.overrideWithValue(repo),
            geminiServiceProvider.overrideWithValue(geminiService),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Google Gemini'), findsOneWidget);
      expect(find.text('Not configured'), findsOneWidget);
      expect(find.text('Configure'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Save Key'), findsNothing);
    });

    testWidgets('renders connected state when API key is present', (tester) async {
      geminiService = TestGeminiService(savedKey: 'valid-secret-key-1234');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedItemRepositoryProvider.overrideWithValue(repo),
            geminiServiceProvider.overrideWithValue(geminiService),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Google Gemini'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Stored securely on this device'), findsOneWidget);
      // Ensure the plaintext or masked key is NEVER present on the main Settings screen
      expect(find.text('valid-secret-key-1234'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('GeminiConfigSheet Tests', () {
    testWidgets('renders connected sheet with replace and remove actions', (tester) async {
      geminiService = TestGeminiService(savedKey: 'valid-secret-key-1234');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedItemRepositoryProvider.overrideWithValue(repo),
            geminiServiceProvider.overrideWithValue(geminiService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GeminiConfigSheet(isInitiallyConfigured: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Stored securely'), findsOneWidget);
      expect(find.text('The key is never displayed after saving.'), findsOneWidget);
      expect(find.text('Replace API key'), findsOneWidget);
      expect(find.text('Remove key'), findsOneWidget);

      // Tap replace key to enter input mode
      await tester.tap(find.text('Replace API key'));
      await tester.pumpAndSettle();

      expect(find.text('Replace API key'), findsWidgets);
      expect(find.text('Enter a new Gemini API key. Your existing key will remain active until the new key is successfully validated and saved.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Save key'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders unconfigured input sheet initially when not configured', (tester) async {
      geminiService = TestGeminiService(savedKey: '');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedItemRepositoryProvider.overrideWithValue(repo),
            geminiServiceProvider.overrideWithValue(geminiService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GeminiConfigSheet(isInitiallyConfigured: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Connect Gemini'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Save & connect'), findsOneWidget);
      expect(find.text('Get a free API key'), findsOneWidget);
    });

    testWidgets('tapping remove key displays confirmation dialog', (tester) async {
      geminiService = TestGeminiService(savedKey: 'valid-secret-key-1234');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedItemRepositoryProvider.overrideWithValue(repo),
            geminiServiceProvider.overrideWithValue(geminiService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GeminiConfigSheet(isInitiallyConfigured: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove key'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Gemini key?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove key'), findsWidgets);
    });

    testWidgets('validation failure preserves existing key and shows error banner', (tester) async {
      geminiService = TestGeminiService(savedKey: 'existing-valid-key');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedItemRepositoryProvider.overrideWithValue(repo),
            geminiServiceProvider.overrideWithValue(geminiService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GeminiConfigSheet(isInitiallyConfigured: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to replace mode
      await tester.tap(find.text('Replace API key'));
      await tester.pumpAndSettle();

      // Enter invalid key
      await tester.enterText(find.byType(TextField), 'invalid-key');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save key'));
      await tester.pumpAndSettle();

      // Error banner should be shown
      expect(find.text("Couldn't connect"), findsOneWidget);
      expect(find.text('Existing key remains active.'), findsOneWidget);

      // Existing key must still be intact
      expect(await geminiService.getApiKey(), 'existing-valid-key');
    });
  });
}

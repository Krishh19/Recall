import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/settings/digest_settings_provider.dart';

part 'onboarding_controller.g.dart';

/// The current canonical onboarding version.
const int kCurrentOnboardingVersion = 1;

/// Secure storage key for persisting the completed onboarding version.
const String kOnboardingVersionKey = 'recall_onboarding_version';

/// Controls whether the first-launch onboarding sequence should be displayed.
@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  late final FlutterSecureStorage _storage;

  @override
  Future<bool> build() async {
    _storage = ref.watch(secureStorageProvider);
    return _checkShouldShowOnboarding();
  }

  Future<bool> _checkShouldShowOnboarding() async {
    try {
      final versionStr = await _storage.read(key: kOnboardingVersionKey);
      if (versionStr != null) {
        final version = int.tryParse(versionStr) ?? 0;
        if (version >= kCurrentOnboardingVersion) {
          return false;
        }
      }

      // Check if this is an existing user:
      // If user already has a configured Gemini key or existing items in database,
      // never force them through the onboarding flow.
      final hasGeminiKey = await ref.read(geminiServiceProvider).hasApiKey();
      if (hasGeminiKey) {
        await _saveVersion(kCurrentOnboardingVersion);
        return false;
      }

      final existingItems =
          await ref.read(savedItemRepositoryProvider).getAllItems();
      if (existingItems.isNotEmpty) {
        await _saveVersion(kCurrentOnboardingVersion);
        return false;
      }

      // Fresh install with no data: show onboarding
      return true;
    } catch (_) {
      // In case of error reading storage, default to false to avoid trapping user
      return false;
    }
  }

  Future<void> _saveVersion(int version) async {
    try {
      await _storage.write(
        key: kOnboardingVersionKey,
        value: version.toString(),
      );
    } catch (_) {}
  }

  /// Marks the onboarding flow as completed.
  Future<void> completeOnboarding() async {
    await _saveVersion(kCurrentOnboardingVersion);
    state = const AsyncValue.data(false);
  }

  /// Skips the onboarding flow and marks the current version as acknowledged.
  Future<void> skipOnboarding() async {
    await completeOnboarding();
  }
}

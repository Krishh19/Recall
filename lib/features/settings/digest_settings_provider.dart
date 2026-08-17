import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:recall/features/settings/digest_settings.dart';

part 'digest_settings_provider.g.dart';

const String _kDigestSettingsKey = 'recall_digest_settings_v1';

/// Provider for FlutterSecureStorage instance.
@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

/// Manages and persists user configurable digest notification preferences.
@Riverpod(keepAlive: true)
class DigestSettingsController extends _$DigestSettingsController {
  late final FlutterSecureStorage _storage;

  @override
  DigestSettings build() {
    _storage = ref.watch(secureStorageProvider);
    _loadSettings();
    return const DigestSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final raw = await _storage.read(key: _kDigestSettingsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        state = DigestSettings.fromJson(decoded);
      }
    } catch (_) {
      // Fall back to default settings
    }
  }

  Future<void> _saveSettings(DigestSettings settings) async {
    state = settings;
    try {
      await _storage.write(
        key: _kDigestSettingsKey,
        value: jsonEncode(settings.toJson()),
      );
    } catch (_) {
      // Storage error handled silently
    }
  }

  /// Toggles whether digest notifications are enabled.
  Future<void> setEnabled(bool enabled) async {
    await _saveSettings(state.copyWith(enabled: enabled));
  }

  /// Sets the day of week (1 = Monday, 7 = Sunday) for weekly digest delivery.
  Future<void> setDayOfWeek(int dayOfWeek) async {
    await _saveSettings(state.copyWith(dayOfWeek: dayOfWeek));
  }

  /// Sets the hour (0-23) and minute (0-59) for delivery time.
  Future<void> setTime({required int hour, required int minute}) async {
    await _saveSettings(state.copyWith(hour: hour, minute: minute));
  }
}

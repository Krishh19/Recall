import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_controller.g.dart';

/// Available Material 3 user-generated theme presets.
enum ThemePreset {
  /// System dynamic wallpaper color (Material You) on supported devices.
  dynamicColor('Dynamic', null),

  /// Modern ocean blue seed (default).
  oceanBlue('Ocean', Color(0xFF2563EB)),

  /// Natural emerald green seed.
  emerald('Emerald', Color(0xFF059669)),

  /// Rich indigo dusk seed.
  indigo('Indigo', Color(0xFF4F46E5)),

  /// Minimalist neutral slate seed.
  slate('Slate', Color(0xFF475569)),

  /// Warm amber gold seed.
  amber('Amber', Color(0xFFD97706)),

  /// Royal amethyst purple seed.
  amethyst('Amethyst', Color(0xFF7C3AED));

  const ThemePreset(this.label, this.color);

  /// Human-readable name.
  final String label;

  /// Underlying seed color (null if using system dynamic color).
  final Color? color;
}

/// Controls whether Recall follows the system, light, or dark theme.
@riverpod
class ThemeController extends _$ThemeController {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Changes the application's active theme mode.
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// Controls the active user-selected Material 3 color preset.
@riverpod
class ThemePresetController extends _$ThemePresetController {
  @override
  ThemePreset build() => ThemePreset.oceanBlue;

  /// Changes the active theme color preset.
  void setPreset(ThemePreset preset) {
    state = preset;
  }
}

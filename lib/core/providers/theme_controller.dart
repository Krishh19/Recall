import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_controller.g.dart';

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

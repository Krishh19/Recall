import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Recall's shared Material 3 Expressive theme tokens.
abstract final class AppTheme {
  /// The calm library-teal seed used across light and dark themes.
  static const Color seedColor = Color(0xFF356A67);

  /// Recall's light Material 3 Expressive theme.
  static final M3EThemeData light = M3EThemeData.light(seedColor: seedColor);

  /// Recall's dark Material 3 Expressive theme.
  static final M3EThemeData dark = M3EThemeData.dark(seedColor: seedColor);
}

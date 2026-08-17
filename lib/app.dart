import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/providers/theme_controller.dart';
import 'package:recall/core/router.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/features/save/share_intent_service.dart';

/// The root Material 3 Expressive application widget with dynamic color support.
class RecallApp extends ConsumerWidget {
  /// Creates the Recall application.
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate the share intent listener on startup
    ref.watch(shareIntentServiceProvider);

    final ThemeMode themeMode = ref.watch(themeControllerProvider);
    final goRouter = ref.watch(routerProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Harmonize dynamic color schemes derived from user's wallpaper/system
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // Standard Material 3 balanced fallback
          lightScheme = AppTheme.lightScheme;
          darkScheme = AppTheme.darkScheme;
        }

        final lightTheme = AppTheme.buildThemeData(lightScheme);
        final darkTheme = AppTheme.buildThemeData(darkScheme);

        return MaterialApp.router(
          title: 'Recall',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          routerConfig: goRouter,
          builder: (context, child) {
            final isDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark);
            final activeScheme = isDark ? darkScheme : lightScheme;

            return M3ETheme(
              data: isDark
                  ? AppTheme.darkWithSeed(activeScheme.primary)
                  : AppTheme.lightWithSeed(activeScheme.primary),
              autoTheming: themeMode == ThemeMode.system,
              dynamicColoring: true,
              initialTheme: switch (themeMode) {
                ThemeMode.system => null,
                ThemeMode.light => Brightness.light,
                ThemeMode.dark => Brightness.dark,
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

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
    final ThemePreset preset = ref.watch(themePresetControllerProvider);
    final goRouter = ref.watch(routerProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme = AppTheme.createScheme(
          preset: preset,
          brightness: Brightness.light,
          dynamicScheme: lightDynamic?.harmonized(),
        );
        final darkScheme = AppTheme.createScheme(
          preset: preset,
          brightness: Brightness.dark,
          dynamicScheme: darkDynamic?.harmonized(),
        );

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
            // M3ETheme projects its token colors back onto Theme.of(context).
            // Giving it its own adaptive/dynamic configuration would therefore
            // create a second, independently-resolved color scheme on top of
            // MaterialApp's scheme. Keep one source of truth: the fully
            // resolved ColorScheme above, including its separate dark palette.
            final isDark =
                themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) ==
                        Brightness.dark);
            final activeTheme = isDark ? darkTheme : lightTheme;

            return M3ETheme(
              data: M3EThemeData.fromMaterial(activeTheme),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

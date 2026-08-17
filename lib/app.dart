import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/providers/theme_controller.dart';
import 'package:recall/core/router.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/features/save/share_intent_service.dart';

/// The root Material 3 Expressive application widget.
class RecallApp extends ConsumerWidget {
  /// Creates the Recall application.
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate the share intent listener on startup
    ref.watch(shareIntentServiceProvider);

    final ThemeMode themeMode = ref.watch(themeControllerProvider);
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Recall',
      theme: AppTheme.light.toThemeData(),
      darkTheme: AppTheme.dark.toThemeData(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
      builder: (context, child) {
        return M3ETheme(
          data: AppTheme.light,
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
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recall/core/theme.dart';
import 'package:recall/features/home/home_screen.dart';
import 'package:recall/features/navigation/main_shell.dart';
import 'package:recall/features/profile/profile_screen.dart';
import '../../helpers/test_saved_item_repository.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';

void main() {
  Widget createShellTestApp(GoRouter router, TestSavedItemRepository repo) {
    return ProviderScope(
      overrides: [
        savedItemRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light.toThemeData(),
        routerConfig: router,
      ),
    );
  }

  testWidgets('MainShell displays Home and Profile tabs and switches correctly', (
    tester,
  ) async {
    final repo = TestSavedItemRepository(items: []);

    final testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(createShellTestApp(testRouter, repo));
    await tester.pumpAndSettle();

    // Verify NavigationBar exists with Home and Profile
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Initial destination is Home
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget); // Add Link FAB

    // Tap Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Now ProfileScreen is visible and FAB is not on Profile
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Your personal link memory'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Tap Home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // Home is active again
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}

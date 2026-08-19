import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:recall/features/detail/detail_screen.dart';
import 'package:recall/features/home/home_screen.dart';
import 'package:recall/features/navigation/main_shell.dart';
import 'package:recall/features/onboarding/onboarding_controller.dart';
import 'package:recall/features/onboarding/screens/onboarding_flow_screen.dart';
import 'package:recall/features/profile/profile_screen.dart';
import 'package:recall/features/search/search_screen.dart';

part 'router.g.dart';

/// Provides the application's configured [GoRouter].
@riverpod
GoRouter router(Ref ref) {
  final onboardingAsync = ref.watch(onboardingControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final shouldShowOnboarding = onboardingAsync.value ?? false;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (shouldShowOnboarding && !isOnboarding) {
        return '/onboarding';
      }
      if (!shouldShowOnboarding && isOnboarding) {
        return '/';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/detail/:id',
        name: 'detail',
        builder: (context, state) =>
            DetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        redirect: (context, state) => '/profile',
      ),
    ],
  );
}

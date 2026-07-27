import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/components/app_components.dart';
import '../features/detail/feed_detail_screen.dart';
import '../features/assistant/assistant_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/interests/interests_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({String initialLocation = '/splash'}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: '/onboarding/:step',
      builder: (_, state) => OnboardingScreen(
        step: int.tryParse(state.pathParameters['step'] ?? '0') ?? 0,
      ),
    ),
    GoRoute(path: '/interests', builder: (_, _) => const InterestsScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppScaffold(
        currentIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        child: shell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const FeedScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/assistant',
              builder: (_, _) => const AssistantScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // `id` ekrana geçirilir: içerik hâlâ fixture, ama okuma geçmişi hangi
    // kaydın açıldığını bilmelidir.
    GoRoute(
      path: '/repository/:id',
      builder: (_, state) =>
          RepositoryDetailScreen(id: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/ai-model/:id',
      builder: (_, state) =>
          AiModelDetailScreen(id: state.pathParameters['id'] ?? ''),
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: ErrorStateView(
      title: 'Sayfa bulunamadı',
      message: state.error.toString(),
    ),
  ),
);

final appRouter = createRouter();

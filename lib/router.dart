import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'screens/board_screen.dart';
import 'screens/claim_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/item_form_screen.dart';
import 'screens/login_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/my_activity_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/app_shell.dart';
import 'widgets/item_loader.dart';
import 'widgets/not_found_screen.dart';

// В приложении создаётся один router. Фабрика позволяет изолировать тесты.
final router = createRouter();

GoRouter createRouter({
  String initialLocation = '/login',
  bool Function()? isAuthenticated,
}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (_, state) {
    if (isAuthenticated == null) return null;
    final authRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    if (!isAuthenticated() && !authRoute) return '/login';
    if (isAuthenticated() && authRoute) return '/items';
    return null;
  },
  errorBuilder: (_, _) => const NotFoundScreen(),
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (_, _) => const LoginScreen(register: true),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/items',
              builder: (_, _) => const BoardScreen(),
              routes: [
                GoRoute(path: 'new', builder: (_, _) => const ItemFormScreen()),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => ItemLoader(
                    key: ValueKey(state.pathParameters['id']),
                    id: state.pathParameters['id']!,
                    child: ItemDetailScreen(id: state.pathParameters['id']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, state) =>
                          ItemFormScreen(itemId: state.pathParameters['id']),
                    ),
                    GoRoute(
                      path: 'claim',
                      builder: (_, state) =>
                          ClaimScreen(itemId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activity',
              builder: (_, _) => const MyActivityScreen(),
              routes: [
                GoRoute(
                  path: 'claims/:claimId/messages',
                  builder: (_, state) =>
                      MessagesScreen(claimId: state.pathParameters['claimId']),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ],
        ),
      ],
    ),
  ],
);

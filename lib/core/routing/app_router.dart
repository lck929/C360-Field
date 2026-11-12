import 'package:c360/core/routing/app_shell.dart';
import 'package:c360/core/routing/routes.dart';
import 'package:c360/features/attendance/presentation/screens/check_screen.dart';
import 'package:c360/features/attendance/presentation/screens/history_screen.dart';
import 'package:c360/features/attendance/presentation/screens/home_screen.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:c360/features/auth/presentation/providers/auth_state.dart';
import 'package:c360/features/auth/presentation/screens/login_screen.dart';
import 'package:c360/features/auth/presentation/screens/profile_screen.dart';
import 'package:c360/features/auth/presentation/screens/splash_screen.dart';
import 'package:c360/features/sync/presentation/screens/sync_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen<AuthState>(authProvider, (_, next) => auth.value = next);
  ref.onDispose(auth.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final at = state.matchedLocation;
      return switch (auth.value) {
        AuthLoading() => at == Routes.splash ? null : Routes.splash,
        SignedOut() => at == Routes.login ? null : Routes.login,
        SignedIn() => at == Routes.login || at == Routes.splash ? Routes.home : null,
      };
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: Routes.checkPattern,
        builder: (_, state) => CheckScreen(type: Routes.typeOf(state.pathParameters['type'])),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.history, builder: (_, _) => const HistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.sync, builder: (_, _) => const SyncScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen())]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

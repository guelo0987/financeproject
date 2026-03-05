
import 'package:go_router/go_router.dart';
import 'main_shell.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/assets/presentation/assets_screen.dart';
import '../features/quick_log/presentation/quick_log_screen.dart';
import '../features/invest/presentation/invest_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/assets/presentation/asset_detail_screen.dart';
import '../features/history/presentation/transaction_history_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouter = Provider<GoRouter>((ref) {
  final isAuth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isGoingToAuth = state.matchedLocation == '/login' || 
                            state.matchedLocation == '/register';

      // If not logged in and not going to auth pages, redirect to login
      if (!isAuth && !isGoingToAuth) {
        return '/login';
      }

      // If logged in and going to auth pages, redirect to home
      if (isAuth && isGoingToAuth) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/assets',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AssetsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'detail/:id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return AssetDetailScreen(assetId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TransactionHistoryScreen(),
          ),
        ),
        GoRoute(
          path: '/invest',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InvestScreen(),
          ),
        ),
        GoRoute(
          path: '/insights',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InsightsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/quick-log',
      builder: (context, state) => const QuickLogScreen(),
    ),
  ],
);
});

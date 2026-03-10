import 'package:go_router/go_router.dart';
import 'main_shell.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/budgets/presentation/budgets_screen.dart';
import '../features/wallet/presentation/wallet_screen.dart';
import '../features/quick_log/presentation/quick_log_screen.dart';
import '../features/invest/presentation/invest_screen.dart';
import '../features/history/presentation/transaction_history_screen.dart';
import '../features/ia/presentation/ai_advisor_screen.dart';
import '../features/spaces/presentation/spaces_manager_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/auth_state.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/tools/presentation/tools_screen.dart';
import '../features/recurring/presentation/recurring_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouter = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isAuth = authState.isAuthenticated;

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isGoingToAuthOrOnboarding =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';

      // If not logged in and not going to auth/onboarding pages, redirect to login
      if (!isAuth && !isGoingToAuthOrOnboarding) {
        return '/splash';
      }

      // If logged in and going to auth pages, redirect to home
      if (isAuth && isGoingToAuthOrOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CalendarScreen()),
          ),
          GoRoute(
            path: '/budgets',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BudgetsScreen()),
          ),
          GoRoute(
            path: '/wallet',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WalletScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/invest',
        builder: (context, state) => const InvestScreen(),
      ),
      GoRoute(
        path: '/quick-log',
        builder: (context, state) => const QuickLogScreen(),
      ),
      GoRoute(
        path: '/ai-advisor',
        builder: (context, state) => const AiAdvisorScreen(),
      ),
      GoRoute(
        path: '/spaces-manager',
        builder: (context, state) => const SpacesManagerScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(path: '/tools', builder: (context, state) => const ToolsScreen()),
      GoRoute(
        path: '/recurring',
        builder: (context, state) => const RecurringScreen(),
      ),
    ],
  );
});

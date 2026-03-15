import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_shell.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/budgets/presentation/budgets_screen.dart';
import '../features/wallet/presentation/wallet_screen.dart';
import '../features/history/presentation/transaction_history_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/auth_state.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/profile_screen.dart';
import '../features/settings/presentation/contact_screen.dart';
import '../features/alerts/presentation/alerts_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/categories/presentation/spending_categories_screen.dart';
import '../features/tools/presentation/tools_screen.dart';
import '../features/recurring/presentation/recurring_screen.dart';
import '../features/subscription/presentation/paywall_screen.dart';
import '../features/subscription/subscription_provider.dart';

final appRouter = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final subState = ref.watch(subscriptionProvider);
  final isAuth = authState.isAuthenticated;

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isGoingToAuthOrOnboarding =
          loc == '/login' ||
          loc == '/register' ||
          loc == '/splash' ||
          loc == '/onboarding';

      // Not logged in → splash/auth
      if (!isAuth && !isGoingToAuthOrOnboarding) return '/splash';

      // Logged in, auth loaded, subscription check done:
      // if no active subscription → force paywall
      if (isAuth && !subState.isLoading && !subState.isActive && loc != '/paywall') {
        return '/paywall?fromReg=true';
      }

      // Logged in going to auth pages → home
      if (isAuth && isGoingToAuthOrOnboarding) return '/';

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
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/categories-spending',
        builder: (context, state) => const SpendingCategoriesScreen(),
      ),
      GoRoute(path: '/tools', builder: (context, state) => const ToolsScreen()),
      GoRoute(
        path: '/recurring',
        builder: (context, state) => const RecurringScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) {
          final fromReg = state.uri.queryParameters['fromReg'] == 'true';
          return PaywallScreen(fromRegistration: fromReg);
        },
      ),
    ],
  );
});

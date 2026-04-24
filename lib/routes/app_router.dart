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
import '../features/auth/presentation/email_confirmation_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/auth_state.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/profile_screen.dart';
import '../features/settings/presentation/contact_screen.dart';
import '../features/alerts/presentation/alerts_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/categories/presentation/spending_categories_screen.dart';
import '../features/tools/presentation/tools_screen.dart';
import '../features/recurring/presentation/recurring_screen.dart';
import '../features/shortcuts/presentation/ios_shortcuts_setup_screen.dart';
import '../features/subscription/presentation/paywall_screen.dart';
import '../features/subscription/presentation/subscription_detail_screen.dart';
import '../features/subscription/subscription_provider.dart';

final appRouter = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final subState = ref.watch(subscriptionProvider);
  final isAuth = authState.isAuthenticated;
  final hasVerifiedAccess = subState.isActive || subState.hasVerificationIssue;
  final requiresPasswordReset = authState.requiresPasswordReset;

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final staleFromReg =
          loc == '/paywall' &&
          state.uri.queryParameters['fromReg'] == 'true' &&
          !authState.needsPaywall;
      final isGoingToAuthOrOnboarding =
          loc == '/login' ||
          loc == '/register' ||
          loc == '/splash' ||
          loc == '/onboarding' ||
          loc == '/auth/confirm' ||
          loc == '/auth/reset-password' ||
          loc == '/callback' ||
          loc == '/reset-password';
      final isAllowedWhileInactive =
          loc == '/paywall' ||
          loc == '/subscription' ||
          loc == '/settings' ||
          loc == '/profile' ||
          loc == '/contact' ||
          loc == '/auth/confirm' ||
          loc == '/callback';
      final paywallLocation = authState.needsPaywall
          ? '/paywall?fromReg=true'
          : '/paywall';

      if (authState.isBootstrapping) {
        return loc == '/splash' ||
                loc == '/auth/confirm' ||
                loc == '/auth/reset-password'
            ? null
            : '/splash';
      }

      if (requiresPasswordReset) {
        return loc == '/auth/reset-password' ? null : '/auth/reset-password';
      }

      if (staleFromReg) return '/paywall';

      if (!isAuth) {
        if (loc == '/splash') return '/onboarding';
        if (!isGoingToAuthOrOnboarding) return '/onboarding';
        return null;
      }

      if (isAuth && subState.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      if (loc == '/splash') {
        return hasVerifiedAccess ? '/' : paywallLocation;
      }

      if (!hasVerifiedAccess && !isAllowedWhileInactive) {
        return paywallLocation;
      }

      if (isAuth &&
          isGoingToAuthOrOnboarding &&
          loc != '/auth/confirm' &&
          loc != '/callback') {
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
      GoRoute(
        path: '/auth/confirm',
        builder: (context, state) => EmailConfirmationScreen(uri: state.uri),
      ),
      GoRoute(
        path: '/callback',
        builder: (context, state) => EmailConfirmationScreen(uri: state.uri),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
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
        path: '/shortcuts',
        builder: (context, state) => const IosShortcutsSetupScreen(),
      ),
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
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionDetailScreen(),
      ),
    ],
  );
});

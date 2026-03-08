# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Menudo** — A personal finance app for the Dominican market (currency: DOP / RD$). Flutter app targeting iOS and Android.

## Commands

```bash
# Run the app
flutter run

# Run on a specific device
flutter run -d <device-id>

# Build
flutter build apk       # Android
flutter build ios       # iOS

# Analyze / lint
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/file_test.dart

# Get dependencies
flutter pub get
```

## Architecture

Feature-first folder structure under `lib/`:

```
lib/
  main.dart                  # App entry point; wraps with ProviderScope
  routes/
    app_router.dart          # GoRouter config; auth-guarded redirect logic
    main_shell.dart          # ShellRoute scaffold with bottom nav + FAB for quick log
  core/
    data/
      models.dart            # All data models (WalletAccount, MenudoTransaction, MenudoBudget, etc.) + mock data
      mock_data.dart         # Additional mock data
    theme/
      app_colors.dart        # Color system (AppColors + MenudoColors alias)
      app_text_styles.dart   # Typography (MenudoTextStyles + AppTextStyles shim)
      app_theme.dart         # ThemeData
      app_spacing.dart       # Spacing constants
      app_shadows.dart       # Shadow constants
    constants/
      app_constants.dart
  features/
    auth/                    # AuthState (Riverpod StateNotifier), login/register/splash/onboarding screens
    dashboard/               # Main home screen
    calendar/                # Calendar view of transactions
    budgets/                 # Budget management (list, detail sheet, create wizard)
    wallet/                  # Wallet accounts screen
    quick_log/               # Quick transaction logging (bottom sheet: RegisterTransactionSheet)
    history/                 # Full transaction history
    invest/                  # Investment instruments screen
    ia/                      # AI advisor screen
    assets/                  # Asset tracking
    insights/                # Spending insights
    spaces/                  # Shared budget spaces (multi-member)
    settings/
  shared/
    widgets/                 # Reusable Menudo design system widgets
```

## State Management

Riverpod (`flutter_riverpod`). Key providers:
- `authProvider` — `StateNotifierProvider<AuthNotifier, AuthState>` in `lib/features/auth/auth_state.dart`
- `appRouter` — `Provider<GoRouter>` in `lib/routes/app_router.dart`, watches `authProvider` for redirect logic

## Routing

GoRouter with:
- `/splash`, `/onboarding`, `/login`, `/register` — unauthenticated routes
- `ShellRoute` wrapping `/`, `/calendar`, `/budgets`, `/wallet` — these share the `MainShell` bottom nav
- Full-screen routes outside the shell: `/history`, `/invest`, `/quick-log`, `/ai-advisor`, `/spaces-manager`

The FAB in `MainShell` opens `RegisterTransactionSheet` as a modal bottom sheet (not a route).

## Design System

All UI uses the Menudo design system. Use these, not raw Flutter widgets:
- `AppColors` / `MenudoColors` — color constants (short aliases: `e8`, `o5`, `g2`, etc.)
- `MenudoTextStyles` — typography (`h1`–`h3`, `bodyLarge/Medium/Small`, `amountMedium`, etc.)
- `AppTextStyles` — legacy shims mapping to `MenudoTextStyles`; prefer `MenudoTextStyles` for new code
- Shared widgets in `lib/shared/widgets/`: `MenudoButton`, `MenudoCard`, `MenudoChip`, `MenudoBottomNav`, `MenudoTextField`, `MenudoGauge`, `GlassCard`, `MiniSparkline`, `VariationBadge`, `AnimatedCounter`
- Font: Plus Jakarta Sans (via `google_fonts`)
- Icons: `lucide_icons` (preferred for new screens), `iconsax_flutter`

## Data Models

Core models in `lib/core/data/models.dart`:
- `WalletAccount` — bank/cash accounts (`tipo`: `"ahorro"`, `"gasto"`, `"deuda"`)
- `MenudoTransaction` — transactions (`tipo`: `"gasto"`, `"ingreso"`, `"transferencia"`)
- `MenudoBudget` / `BudgetCategory` / `BudgetMember` — budget with category spending limits
- Legacy models (`Asset`, `Transaction`, `InvestmentInstrument`) — kept as compilation shims during refactor

All data is currently mock (no backend). Mock instances are defined at the bottom of `models.dart` (`mockWallets`, `mockBudgets`, `mockTxns`).

## Refactor Status

The codebase is mid-refactor from a legacy model set to the Menudo 2.0 models. `AppColors`, `AppTextStyles`, and legacy model classes have shim aliases to prevent compilation errors. Prefer the canonical Menudo 2.0 APIs (`MenudoTextStyles`, `AppColors` short aliases, `lucide_icons`) for any new code.

# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the app code. Keep app-wide pieces in `lib/core/` (`constants/`, `network/`, `theme/`, `utils/`) and reusable UI in `lib/shared/widgets/`. Feature work belongs in `lib/features/<feature>/`, usually split into `data/`, `presentation/`, and `providers/`. Navigation lives in `lib/routes/`. Static assets go in `assets/images/`. Treat `android/`, `ios/`, `macos/`, `linux/`, `windows/`, and `web/` as platform shells; avoid editing generated Flutter files unless platform behavior changes.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies from `pubspec.yaml`.
- `flutter run` starts the app on the selected simulator, emulator, or device.
- `flutter analyze` runs the configured `flutter_lints` rules.
- `flutter test` runs widget and unit tests from `test/`.
- `dart format lib test` formats the primary Dart sources before commit.
- `flutter build apk` or `flutter build macos` creates release builds for the target platform.

## Coding Style & Naming Conventions
Use 2-space indentation and keep Dart files in `lower_snake_case.dart`. Name UI entry points with suffixes such as `Screen`, `Sheet`, and `Wizard`; keep repositories ending in `Repository` and Riverpod providers ending in `Provider`. Follow the feature-first layout already used in `lib/features/`, and move shared colors, spacing, and text styles into `lib/core/theme/` instead of duplicating inline values.

## Testing Guidelines
Use `flutter_test` for widget coverage and mirror feature paths under `test/` when adding new cases. Prefer behavior-focused names such as `wallet_screen_shows_empty_state_test.dart`. When testing auth bootstrap, account for the delayed navigation in `lib/features/auth/presentation/splash_screen.dart`; otherwise pending timers can fail the test run. Run `flutter test` locally before opening a PR.

## Commit & Pull Request Guidelines
Recent history follows Conventional Commit prefixes like `feat:`, `refactor:`, and `chore:` with short imperative subjects. Keep each commit scoped to one change. PRs should include a concise summary, linked task or issue, screenshots or recordings for UI changes, and the current results of `flutter analyze` and `flutter test`.

## Security & Configuration Tips
Do not commit secrets. `.mcp.json` is ignored for local tokens, and backend settings under `lib/core/constants/` or Supabase initialization should be reviewed carefully before changes are merged.

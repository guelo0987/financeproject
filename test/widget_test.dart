import 'package:financeproject/features/auth/presentation/login_screen.dart';
import 'package:financeproject/features/auth/presentation/register_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financeproject/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MenudoApp()));
    await tester.pumpAndSettle();

    // Verify the app launches
    expect(find.text('Menudo'), findsWidgets);
  });

  testWidgets(
    'Register back button falls back to login when there is no route to pop',
    (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Entrar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

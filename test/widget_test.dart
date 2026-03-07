
import 'package:flutter_test/flutter_test.dart';

import 'package:financeproject/main.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MenudoApp()));
    await tester.pumpAndSettle();

    // Verify the app launches
    expect(find.text('Menudo'), findsWidgets);
  });
}

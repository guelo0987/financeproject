
import 'package:flutter_test/flutter_test.dart';

import 'package:financeproject/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PatrimoniumApp());
    await tester.pumpAndSettle();

    // Verify the app launches and shows the dashboard
    expect(find.text('Patrimonium'), findsOneWidget);
  });
}

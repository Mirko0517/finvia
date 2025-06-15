// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:finvia_flutter/features/auth/auth_gate.dart';

void main() {
  testWidgets('Initial app test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AuthGate());

    // Aquí puedes agregar las verificaciones específicas para AuthGate
    // Por ahora solo verificamos que el widget se construya sin errores
    expect(find.byType(AuthGate), findsOneWidget);
  });
}

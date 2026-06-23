// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:babsensi/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('BAbsensi'), findsOneWidget);
    expect(find.text('Username / NIS / No. Orang Tua'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk Aplikasi'), findsOneWidget);
  });
}

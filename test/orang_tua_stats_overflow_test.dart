import 'package:babsensi/screens/orang_tua/dashboard_orang_tua.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('monthly stats grid does not overflow on small phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ParentMonthlyStatsGrid(
                statistikBulan: const {
                  'hadir': 12,
                  'terlambat': 3,
                  'izin': 1,
                  'sakit': 2,
                  'alpa': 0,
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hadir'), findsOneWidget);
    expect(find.text('Terlambat'), findsOneWidget);
    expect(find.text('Izin'), findsOneWidget);
    expect(find.text('Sakit'), findsOneWidget);
    expect(find.text('Alpa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

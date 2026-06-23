import 'package:babsensi/screens/siswa/dashboard_siswa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> schedule({
    required String mapel,
    required String mulai,
    required String selesai,
    required bool sudah,
  }) {
    return {
      'id': 1,
      'nama_mapel': mapel,
      'jam_mulai': mulai,
      'jam_selesai': selesai,
      'jp_label': 'JP 5-6',
      'guru_utama': 'Teguh Firmansyah',
      'status_guru_utama': 'sakit',
      'guru_aktif': 'ROBBY',
      'role_guru_aktif': 'pengganti_pertama',
      'role_guru_aktif_label': 'Guru Pengganti',
      'butuh_pengganti': false,
      'sudah_absen': sudah,
    };
  }

  Future<void> pumpSchedule(
    WidgetTester tester, {
    required Map<String, dynamic> item,
    DateTime? currentTime,
    bool includeFooter = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardScheduleTile(
                    item: item,
                    currentTime: currentTime ?? DateTime(2026, 6, 23, 9, 30),
                  ),
                  if (includeFooter)
                    DashboardScheduleLastUpdated(
                      updatedAt: DateTime(2026, 6, 23, 9, 35),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('badge Sudah uses green and subject is visible', (tester) async {
    await pumpSchedule(
      tester,
      item: schedule(
        mapel: 'Bahasa Indonesia',
        mulai: '07:00',
        selesai: '08:10',
        sudah: true,
      ),
    );

    final badgeText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('schedule-badge-Sudah')),
        matching: find.text('Sudah'),
      ),
    );

    expect(find.text('Bahasa Indonesia'), findsOneWidget);
    expect(badgeText.style?.color, Colors.green);
  });

  testWidgets('badge Belum uses orange', (tester) async {
    await pumpSchedule(
      tester,
      item: schedule(
        mapel: 'Bahasa Inggris',
        mulai: '08:10',
        selesai: '09:20',
        sudah: false,
      ),
    );

    final badgeText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('schedule-badge-Belum')),
        matching: find.text('Belum'),
      ),
    );

    expect(badgeText.style?.color, Colors.orange);
  });

  testWidgets('active schedule shows Sedang Berlangsung label', (tester) async {
    await pumpSchedule(
      tester,
      item: schedule(
        mapel: 'Bahasa Indonesia',
        mulai: '09:20',
        selesai: '10:30',
        sudah: false,
      ),
      currentTime: DateTime(2026, 6, 23, 9, 45),
    );

    expect(find.text('Sedang Berlangsung'), findsOneWidget);
    expect(find.byKey(const Key('schedule-active-label')), findsOneWidget);
  });

  testWidgets('last updated text appears after successful refresh',
      (tester) async {
    await pumpSchedule(
      tester,
      item: schedule(
        mapel: 'Bahasa Indonesia',
        mulai: '09:20',
        selesai: '10:30',
        sudah: false,
      ),
      includeFooter: true,
    );

    expect(find.text('Terakhir diperbarui pukul 09:35'), findsOneWidget);
    expect(find.byKey(const Key('schedule-last-updated')), findsOneWidget);
  });

  testWidgets('schedule card stays responsive on a small phone width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpSchedule(
      tester,
      item: schedule(
        mapel: 'Bahasa Indonesia Lanjutan dan Literasi',
        mulai: '09:20',
        selesai: '10:30',
        sudah: false,
      ),
      currentTime: DateTime(2026, 6, 23, 9, 45),
      includeFooter: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('schedule-card')), findsOneWidget);
  });
}

import 'package:babsensi/models/jadwal_mapel_item.dart';
import 'package:babsensi/models/orang_tua_dashboard_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> payload({List<Map<String, dynamic>>? notifications}) {
    return {
      'ringkasan_kehadiran_hari_ini': {
        'status': 'hadir',
        'label': 'Hadir',
        'jam_masuk': '06:48',
        'deskripsi': 'Hadir pukul 06:48',
      },
      'statistik_bulan_berjalan': {
        'hadir': 7,
        'terlambat': 1,
        'izin': 2,
        'sakit': 1,
        'alpa': 0,
      },
      'jadwal_hari_ini': [
        {
          'nama_mapel': 'Bahasa Indonesia',
          'jam_mulai': '09:20',
          'jam_selesai': '10:30',
          'guru_utama': 'Teguh Firmansyah',
          'status_guru_utama': 'sakit',
          'guru_aktif': 'ROBBY',
          'role_guru_aktif': 'pengganti_pertama',
          'butuh_pengganti': false,
          'sudah_absen': false,
        }
      ],
      'aktivitas_terbaru': [
        {
          'tipe': 'masuk',
          'label': 'Masuk sekolah pukul 06:48',
          'tanggal': '2026-06-23',
          'jam': '06:48',
        },
        {
          'tipe': 'mapel',
          'label': 'Absensi Bahasa Inggris pukul 08:15',
          'tanggal': '2026-06-23',
          'jam': '08:15',
        },
      ],
      'notifikasi_penting': notifications ??
          [
            {
              'level': 'warning',
              'pesan':
                  'Bahasa Indonesia sedang berlangsung, tetapi absensi mapel belum tercatat.',
            }
          ],
    };
  }

  test('status hadir and monthly stats are parsed', () {
    final data = OrangTuaDashboardData(payload());

    expect(data.attendanceStatus, 'hadir');
    expect(data.attendanceSummary['deskripsi'], 'Hadir pukul 06:48');
    expect(data.monthlyStats['hadir'], 7);
    expect(data.monthlyStats['terlambat'], 1);
    expect(data.monthlyStats['izin'], 2);
    expect(data.monthlyStats['sakit'], 1);
    expect(data.monthlyStats['alpa'], 0);
  });

  test('status belum absen is used when summary is missing', () {
    final data = OrangTuaDashboardData({});

    expect(data.attendanceStatus, 'belum_absen');
  });

  test('active teacher replacement remains the displayed teacher', () {
    final data = OrangTuaDashboardData(payload());
    final schedule = JadwalMapelItem.fromJson(data.schedules.first);

    expect(schedule.guruLine, 'Guru bertugas: ROBBY');
    expect(schedule.guruLine, isNot(contains('Teguh Firmansyah')));
  });

  test('recent activities are sorted newest first', () {
    final data = OrangTuaDashboardData(payload());

    expect(data.recentActivities.first['label'],
        'Absensi Bahasa Inggris pukul 08:15');
    expect(data.recentActivities.last['label'], 'Masuk sekolah pukul 06:48');
  });

  test('important and safe notifications are available', () {
    final warning = OrangTuaDashboardData(payload());
    final safe = OrangTuaDashboardData(payload(notifications: []));

    expect(warning.importantNotifications.first['level'], 'warning');
    expect(warning.importantNotifications.first['pesan'],
        contains('sedang berlangsung'));
    expect(safe.importantNotifications.first['level'], 'safe');
    expect(safe.importantNotifications.first['pesan'],
        'Tidak ada pemberitahuan penting hari ini.');
  });
}

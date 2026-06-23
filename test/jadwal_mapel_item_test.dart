import 'package:babsensi/models/jadwal_mapel_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses primary teacher as active even when replacement exists', () {
    final item = JadwalMapelItem.fromJson({
      'id': '1',
      'nama_mapel': 'Bahasa Indonesia',
      'jam_mulai': '08:10',
      'jam_selesai': '09:20',
      'jp_label': 'JP 3-4',
      'guru_utama': 'Nanda Wijaya',
      'status_guru_utama': 'normal',
      'status_guru_utama_label': 'Hadir',
      'guru_aktif': 'Nanda Wijaya',
      'role_guru_aktif': 'guru_utama',
      'pengganti_terbaru': 'Oki Prasetyo',
      'sudah_absen': false,
    });

    expect(item.guruLine, 'Guru bertugas: Nanda Wijaya');
    expect(item.attendanceBadge, 'Belum');
    expect(item.jpTimeLabel, 'JP 3-4 | 08:10 - 09:20');
  });

  test('parses active replacement separately from attendance badge', () {
    final item = JadwalMapelItem.fromJson({
      'nama_mapel': 'Bahasa Indonesia',
      'jam_mulai': '07:00',
      'jam_selesai': '08:10',
      'guru_utama': 'JOHNCENA',
      'status_guru_utama_label': 'Sakit',
      'guru_aktif': 'Teguh Firmansyah',
      'role_guru_aktif': 'pengganti_pertama',
      'role_guru_aktif_label': 'Guru Pengganti',
      'urutan_pengganti': 1,
      'sudah_absen': 1,
    });

    expect(item.isPenggantiAktif, isTrue);
    expect(item.guruLine, 'Guru bertugas: Teguh Firmansyah');
    expect(item.attendanceBadge, 'Sudah');
  });

  test('shows waiting only when replacement is needed', () {
    final item = JadwalMapelItem.fromJson({
      'nama_mapel': 'MTK',
      'jam_mulai': '09:50',
      'jam_selesai': '11:00',
      'guru_utama': 'Joko Susilo',
      'guru_aktif': null,
      'butuh_pengganti': true,
      'sudah_absen': false,
    });

    expect(item.guruLine, 'Guru bertugas belum ditentukan');
    expect(item.attendanceBadge, 'Belum');
  });

  test('does not fall back to primary teacher when primary is sick', () {
    final item = JadwalMapelItem.fromJson({
      'nama_mapel': 'Bahasa Indonesia',
      'jam_mulai': '07:00',
      'jam_selesai': '08:10',
      'guru_utama': 'JOHNCENA',
      'status_guru_utama': 'sakit',
      'butuh_pengganti': false,
      'sudah_absen': false,
    });

    expect(item.guruLine, isNot(contains('JOHNCENA')));
    expect(item.guruLine, 'Guru bertugas belum ditentukan');
  });

  test('falls back safely for old backend payload', () {
    final item = JadwalMapelItem.fromJson({
      'nama_mapel': 'MTK',
      'jam_mulai': '09:50',
      'jam_selesai': '11:00',
      'guru_utama': 'Joko Susilo',
      'status_guru': 'normal',
      'guru_aktif': 'Joko Susilo',
      'peran_guru_aktif': 'guru_utama',
      'sudah_absen': 'false',
    });

    expect(item.statusGuruUtama, 'normal');
    expect(item.guruLine, 'Guru bertugas: Joko Susilo');
    expect(item.sudahAbsen, isFalse);
  });

  test('uses active replacement over stale description payload', () {
    final item = JadwalMapelItem.fromJson({
      'nama_mapel': 'Bahasa Indonesia',
      'jam_mulai': '09:20',
      'jam_selesai': '10:30',
      'jp_label': 'JP 5-6',
      'guru_utama': 'Teguh Firmansyah',
      'status_guru_utama': 'sakit',
      'guru_aktif': 'ROBBY',
      'role_guru_aktif': 'pengganti_pertama',
      'pengganti_terbaru': 'ROBBY',
      'status_penugasan': 'aktif',
      'butuh_pengganti': false,
      'guru_tersedia': true,
      'keterangan_guru': 'Guru bertugas belum ditentukan',
      'sudah_absen': false,
    });

    expect(item.guruUtama, 'Teguh Firmansyah');
    expect(item.guruAktif, 'ROBBY');
    expect(item.penggantiTerbaru, 'ROBBY');
    expect(item.statusPenugasan, 'aktif');
    expect(item.butuhPengganti, isFalse);
    expect(item.guruTersedia, isTrue);
    expect(item.guruLine, 'Guru bertugas: ROBBY');
  });
}

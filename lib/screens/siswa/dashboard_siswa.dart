import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api.dart';
import '../../models/jadwal_mapel_item.dart';
import '../../services/storage_service.dart';
import '../bantuan_screen.dart';
import '../../widgets/live_datetime_card.dart';
import 'kalender_siswa_screen.dart';
import 'pengajuan_izin_screen.dart';
import 'riwayat_screen.dart';

const Color _scheduleActiveBlue = Color(0xff2563eb);
const Color _scheduleDoneGreen = Colors.green;
const Color _schedulePendingOrange = Colors.orange;

DateTime? dashboardServerTime(Map<String, dynamic>? data) {
  final raw = data?['server_time'] ?? data?['serverTime'];
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString())?.toLocal();
}

String dashboardHourMinute(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class DashboardScheduleLastUpdated extends StatelessWidget {
  final DateTime updatedAt;

  const DashboardScheduleLastUpdated({
    super.key,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Terakhir diperbarui pukul ${dashboardHourMinute(updatedAt)}',
      key: const Key('schedule-last-updated'),
      style: const TextStyle(
        color: Colors.black45,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class DashboardScheduleTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final DateTime currentTime;
  final VoidCallback? onTap;

  const DashboardScheduleTile({
    super.key,
    required this.item,
    required this.currentTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final jadwal = JadwalMapelItem.fromJson(item);
    final active = isScheduleActive(jadwal, currentTime);
    final badgeColor =
        jadwal.sudahAbsen ? _scheduleDoneGreen : _schedulePendingOrange;
    final teacherColor = jadwal.butuhPengganti
        ? Colors.redAccent
        : (jadwal.isPenggantiAktif ? Colors.deepOrange : Colors.black54);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        key: const Key('schedule-card'),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? _scheduleActiveBlue.withValues(alpha: 0.32)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 5 : 0,
                color: _scheduleActiveBlue,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          jadwal.sudahAbsen
                              ? Icons.check_circle
                              : Icons.qr_code_scanner,
                          color: badgeColor,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    jadwal.namaMapel,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff1f2937),
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                scheduleAttendanceBadge(jadwal.attendanceBadge),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  jadwal.jpTimeLabel,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (active) scheduleActiveLabel(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 15,
                                  color: teacherColor,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    jadwal.guruLine,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: teacherColor,
                                      fontSize: 12.2,
                                      height: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (jadwal.isPenggantiAktif &&
                                jadwal.statusGuruUtamaLabel != '-') ...[
                              const SizedBox(height: 3),
                              Text(
                                'Guru utama ${jadwal.statusGuruUtamaLabel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontSize: 11.5,
                                  height: 1.15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool isScheduleActive(JadwalMapelItem jadwal, DateTime currentTime) {
    final start = _timeOnDate(jadwal.jamMulai, currentTime);
    final end = _timeOnDate(jadwal.jamSelesai, currentTime);
    if (start == null || end == null) return false;
    return !currentTime.isBefore(start) && currentTime.isBefore(end);
  }

  static DateTime? _timeOnDate(String value, DateTime date) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

Widget scheduleAttendanceBadge(String status) {
  final normalized = status.toLowerCase();
  final color =
      normalized == 'sudah' ? _scheduleDoneGreen : _schedulePendingOrange;
  return Container(
    key: Key('schedule-badge-$status'),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

Widget scheduleActiveLabel() {
  return Container(
    key: const Key('schedule-active-label'),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _scheduleActiveBlue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Text(
      'Sedang Berlangsung',
      style: TextStyle(
        color: _scheduleActiveBlue,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class DashboardSiswa extends StatefulWidget {
  final String nama;
  final int userId;

  const DashboardSiswa({
    super.key,
    required this.nama,
    required this.userId,
  });

  @override
  State<DashboardSiswa> createState() => _DashboardSiswaState();
}

class _DashboardSiswaState extends State<DashboardSiswa> {
  Map<String, dynamic>? dashboard;
  bool loading = true;
  String? errorMessage;
  DateTime? dashboardLastUpdatedAt;
  Set<String> readNotificationKeys = {};

  @override
  void initState() {
    super.initState();
    loadReadNotifications();
    loadDashboard();
  }

  String get notificationStorageKey =>
      'siswa_read_notifications_${widget.userId}';

  Future<void> loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      readNotificationKeys =
          (prefs.getStringList(notificationStorageKey) ?? []).toSet();
    });
  }

  Future<void> saveReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      notificationStorageKey,
      readNotificationKeys.toList(),
    );
  }

  Future<void> loadDashboard() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });
      final token = await StorageService.getToken();
      if (token == null || token.trim().isEmpty) {
        setState(() {
          errorMessage = 'Sesi login tidak ditemukan. Silakan login kembali.';
          loading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/siswa/dashboard/${widget.userId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token.trim()}',
        },
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode >= 400 || data['status'] == 'error') {
        setState(() {
          errorMessage = data['message'] ?? 'Dashboard siswa gagal dimuat.';
          loading = false;
        });
        return;
      }

      setState(() {
        dashboard = data;
        dashboardLastUpdatedAt = dashboardServerTime(data) ?? DateTime.now();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Koneksi bermasalah: $e';
        loading = false;
      });
    }
  }

  Map<String, dynamic> get siswa =>
      Map<String, dynamic>.from(dashboard?['siswa'] ?? {});

  Map<String, dynamic> get absensi =>
      Map<String, dynamic>.from(dashboard?['absensi_hari_ini'] ?? {});

  Map<String, dynamic> get statusMapel =>
      Map<String, dynamic>.from(dashboard?['status_mapel_hari_ini'] ?? {});

  List<dynamic> get jadwalHariIni => dashboard?['jadwal_hari_ini'] ?? [];

  List<dynamic> get pengajuan => dashboard?['pengajuan'] ?? [];

  List<dynamic> get notifikasi => dashboard?['notifikasi'] ?? [];

  List<dynamic> get kalenderHariIni => dashboard?['kalender_hari_ini'] ?? [];

  DateTime get scheduleReferenceTime =>
      dashboardServerTime(dashboard) ?? DateTime.now();

  List<Map<String, dynamic>> getNotifications() {
    if (notifikasi.isNotEmpty) {
      return notifikasi.map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return {
          'icon': notificationIcon(item['kategori']),
          'color': notificationColor(item['warna'] ?? item['kategori']),
          'key': notificationKey(
            item['kategori'],
            item['judul'],
            item['pesan'],
          ),
          'title': item['judul'] ?? 'Notifikasi',
          'text': item['pesan'] ?? '-',
        };
      }).toList();
    }

    final items = <Map<String, dynamic>>[];
    final sudahMasuk = absensi['sudah_masuk'] == true;
    final sudahPulang = absensi['sudah_pulang'] == true;
    final statusMasuk = (absensi['status_masuk'] ?? '').toString();
    final belumMapel = int.tryParse('${statusMapel['belum_absen'] ?? 0}') ?? 0;

    if (!sudahMasuk) {
      items.add({
        'icon': Icons.login,
        'color': Colors.red,
        'key': notificationKey('absensi_harian', 'Belum absen masuk',
            'Silakan scan QR masuk dari guru piket.'),
        'title': 'Belum absen masuk',
        'text': 'Silakan scan QR masuk dari guru piket.',
      });
    } else if (statusMasuk.toLowerCase() == 'telat') {
      items.add({
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'key': notificationKey(
            'absensi_harian', 'Tercatat telat', '${absensi['jam_masuk']}'),
        'title': 'Tercatat telat',
        'text': 'Masuk jam ${emptyDash(absensi['jam_masuk'])}.',
      });
    }

    if (sudahMasuk && !sudahPulang) {
      items.add({
        'icon': Icons.logout,
        'color': Colors.blue,
        'key': notificationKey('absensi_harian', 'Belum absen pulang',
            'Jangan lupa scan QR pulang sebelum meninggalkan sekolah.'),
        'title': 'Belum absen pulang',
        'text': 'Jangan lupa scan QR pulang sebelum meninggalkan sekolah.',
      });
    }

    if (belumMapel > 0) {
      items.add({
        'icon': Icons.school,
        'color': Colors.purple,
        'key': notificationKey(
            'absensi_mapel', 'Belum absen mapel', '$belumMapel'),
        'title': 'Belum absen mapel',
        'text': '$belumMapel sesi mapel hari ini belum discan.',
      });
    }

    return items;
  }

  String notificationKey(dynamic kategori, dynamic title, dynamic message) {
    final date = emptyDash(dashboard?['tanggal']);
    return '$date|${emptyDash(kategori)}|${emptyDash(title)}|${emptyDash(message)}';
  }

  int unreadNotificationCount() {
    return getNotifications()
        .where((item) => !readNotificationKeys.contains(item['key']))
        .length;
  }

  Future<void> markNotificationsAsRead(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    setState(() {
      readNotificationKeys.addAll(items.map((item) => item['key'].toString()));
    });
    await saveReadNotifications();
  }

  IconData notificationIcon(dynamic value) {
    final text = (value ?? '').toString();
    if (text.contains('mapel')) return Icons.school;
    if (text.contains('pengajuan')) return Icons.description;
    if (text.contains('kalender')) return Icons.event;
    return Icons.notifications_active;
  }

  Color notificationColor(dynamic value) {
    final text = (value ?? '').toString().toLowerCase();
    if (text.contains('green')) return Colors.green;
    if (text.contains('red') || text.contains('libur')) return Colors.red;
    if (text.contains('purple') || text.contains('mapel')) return Colors.purple;
    if (text.contains('blue') || text.contains('kegiatan')) return Colors.blue;
    return Colors.orange;
  }

  String emptyDash(dynamic value) {
    final text = (value ?? '').toString();
    return text.trim().isEmpty ? '-' : text;
  }

  String titleCase(dynamic value) {
    final text = emptyDash(value).replaceAll('_', ' ');
    if (text == '-') return text;
    return text
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Color statusColor(dynamic value) {
    final status = (value ?? '').toString().toLowerCase();
    if (status.contains('hadir') || status.contains('aktif')) {
      return Colors.green;
    }
    if (status.contains('telat') ||
        status.contains('menunggu') ||
        status.contains('belum')) {
      return Colors.orange;
    }
    if (status.contains('izin') || status.contains('sakit')) {
      return Colors.blue;
    }
    if (status.contains('tolak') ||
        status.contains('alfa') ||
        status.contains('nonaktif')) {
      return Colors.red;
    }
    return const Color(0xff273c75);
  }

  Future<void> openScan(String routeName) async {
    final refresh = await Navigator.pushNamed(context, routeName);
    if (refresh == true) {
      await loadDashboard();
      if (mounted) {
        showSoftDialog(
          title: 'Data Diperbarui',
          message: 'Dashboard siswa sudah mengambil data absensi terbaru.',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      }
    }
  }

  Future<void> logout() async {
    await StorageService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void showSoftDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff273c75),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showProfileDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => detailSheet(
        title: 'Profil Siswa',
        icon: Icons.person,
        color: const Color(0xff273c75),
        children: [
          detailRow('Nama', siswa['nama']),
          detailRow('NIS', siswa['nis']),
          detailRow('Username', siswa['username']),
          detailRow('Kelas', siswa['kelas']),
          detailRow('Jurusan', siswa['jurusan']),
          detailRow('Wali kelas', siswa['wali_kelas']),
          detailRow('Nama orang tua', siswa['nama_ortu']),
          detailRow('No orang tua', siswa['no_ortu']),
          detailRow('Status akun', siswa['status_akun']),
        ],
      ),
    );
  }

  Future<void> showNotifications() async {
    final notifications = getNotifications();
    await markNotificationsAsRead(notifications);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => detailSheet(
        title: 'Notifikasi Siswa',
        icon: Icons.notifications_active,
        color: Colors.orange,
        children: notifications.isEmpty
            ? [
                emptyState(
                  icon: Icons.check_circle,
                  title: 'Tidak ada notifikasi',
                  message: 'Semua status penting hari ini terlihat aman.',
                )
              ]
            : notifications
                .map(
                  (item) => notificationTile(
                    item['title'],
                    item['text'],
                    item['icon'],
                    item['color'],
                  ),
                )
                .toList(),
      ),
    );
  }

  void showJadwalDetail(Map<String, dynamic> item) {
    final jadwal = JadwalMapelItem.fromJson(item);
    final sudah = jadwal.sudahAbsen;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => detailSheet(
        title: jadwal.namaMapel,
        icon: Icons.school,
        color: sudah ? Colors.green : Colors.orange,
        children: [
          detailRow('Jam', jadwal.jpTimeLabel),
          detailRow('Guru utama', jadwal.guruUtama),
          detailRow('Status guru utama', jadwal.statusGuruUtamaLabel),
          detailRow('Guru yang bertugas', jadwal.guruAktif),
          detailRow(
            'Peran guru',
            jadwal.roleGuruAktifLabel ??
                (jadwal.guruAktif != null ? 'Guru utama' : 'Belum ditentukan'),
          ),
          if (jadwal.butuhPengganti)
            detailRow('Penugasan', 'Menunggu guru pengganti'),
          detailRow('Keterangan guru', jadwal.guruLine),
          detailRow('Status absen', sudah ? 'Sudah absen' : 'Belum absen'),
          detailRow('Jam scan', jadwal.jamScan),
          detailRow('Catatan', jadwal.catatanGuru),
        ],
      ),
    );
  }

  void showPengajuanDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => detailSheet(
        title: 'Detail Pengajuan',
        icon: Icons.description,
        color: statusColor(item['status']),
        children: [
          detailRow('Jenis', titleCase(item['jenis'])),
          detailRow(
            'Tanggal',
            '${emptyDash(item['tanggal_mulai'])} s/d ${emptyDash(item['tanggal_selesai'])}',
          ),
          detailRow('Status', titleCase(item['status'])),
          detailRow('Alasan', item['alasan']),
          detailRow('Reviewer', item['reviewer']),
          detailRow('Catatan review', item['catatan_review']),
          detailRow('Direview pada', item['reviewed_at']),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = unreadNotificationCount();

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff273c75),
        elevation: 0,
        title: const Text(
          'Dashboard Siswa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Bantuan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BantuanScreen()),
            ),
            icon: const Icon(Icons.help_outline, color: Colors.white),
          ),
          IconButton(
            onPressed: showNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, color: Colors.white),
                if (unreadCount > 0)
                  Positioned(
                    right: -7,
                    top: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                  content: const Text('Yakin ingin keluar dari aplikasi?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? errorView()
                  : ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        animatedItem(0, heroCard()),
                        const SizedBox(height: 16),
                        animatedItem(
                          1,
                          LiveDateTimeCard(
                            label: 'Waktu Server Sekolah',
                            serverTime: dashboard?['server_time'] ?? '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        animatedItem(2, profileCard()),
                        const SizedBox(height: 16),
                        animatedItem(2, attendanceStatusCard()),
                        const SizedBox(height: 16),
                        animatedItem(3, scheduleSection()),
                        const SizedBox(height: 16),
                        if (kalenderHariIni.isNotEmpty) ...[
                          animatedItem(4, todayCalendarSection()),
                          const SizedBox(height: 16),
                        ],
                        animatedItem(5, permitSection()),
                        const SizedBox(height: 16),
                        animatedItem(6, mainMenu()),
                        const SizedBox(height: 20),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget animatedItem(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget errorView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        emptyState(
          icon: Icons.wifi_off,
          title: 'Dashboard gagal dimuat',
          message: errorMessage ?? 'Terjadi kesalahan.',
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: loadDashboard,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff273c75),
            padding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget heroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff273c75), Color(0xff40739e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff273c75).withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${emptyDash(dashboard?['hari'])}, ${emptyDash(dashboard?['tanggal'])}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            emptyDash(siswa['nama'] ?? widget.nama),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: glassMetric(
                  'Status',
                  titleCase(absensi['status_siswa']),
                  Icons.verified,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: glassMetric(
                  'Mapel',
                  emptyDash(statusMapel['label']),
                  Icons.school,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget glassMetric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget profileCard() {
    return whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader('Profil Lengkap', Icons.person,
              onTap: showProfileDetail),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xff273c75).withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: Color(0xff273c75)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emptyDash(siswa['nama']),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${emptyDash(siswa['kelas'])} - ${emptyDash(siswa['jurusan'])}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              statusChip(siswa['status_akun']),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              miniInfo(Icons.badge, 'NIS', siswa['nis']),
              miniInfo(Icons.supervisor_account, 'Wali', siswa['wali_kelas']),
              miniInfo(Icons.family_restroom, 'Ortu', siswa['nama_ortu']),
              miniInfo(Icons.phone, 'No Ortu', siswa['no_ortu']),
            ],
          ),
        ],
      ),
    );
  }

  Widget attendanceStatusCard() {
    return whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader('Status Absensi Hari Ini', Icons.fact_check),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: statusBox(
                  title: 'Masuk',
                  done: absensi['sudah_masuk'] == true,
                  time: absensi['jam_masuk'],
                  status: absensi['status_masuk'],
                  icon: Icons.login,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: statusBox(
                  title: 'Pulang',
                  done: absensi['sudah_pulang'] == true,
                  time: absensi['jam_pulang'],
                  status: absensi['status_pulang'],
                  icon: Icons.logout,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor(statusMapel['label']).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.school, color: statusColor(statusMapel['label'])),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    emptyDash(statusMapel['label']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget scheduleSection() {
    return whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader('Jadwal Pelajaran Hari Ini', Icons.calendar_month),
          const SizedBox(height: 12),
          if (jadwalHariIni.isEmpty)
            emptyState(
              icon: Icons.event_available,
              title: 'Tidak ada jadwal',
              message: 'Hari ini tidak ada jadwal mapel untuk kelas Anda.',
            )
          else
            ...jadwalHariIni.map((raw) {
              final item = Map<String, dynamic>.from(raw);
              return scheduleTile(item);
            }),
          if (dashboardLastUpdatedAt != null) ...[
            const SizedBox(height: 2),
            DashboardScheduleLastUpdated(
              updatedAt: dashboardLastUpdatedAt!,
            ),
          ],
        ],
      ),
    );
  }

  Widget permitSection() {
    return whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader(
            'Riwayat Izin / Sakit',
            Icons.description,
            onTap: () async {
              final refresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PengajuanIzinScreen(),
                ),
              );
              if (refresh == true) loadDashboard();
            },
          ),
          const SizedBox(height: 12),
          if (pengajuan.isEmpty)
            emptyState(
              icon: Icons.inbox,
              title: 'Belum ada pengajuan',
              message:
                  'Pengajuan izin atau sakit yang dikirim akan muncul di sini.',
            )
          else
            ...pengajuan.take(4).map((raw) {
              final item = Map<String, dynamic>.from(raw);
              return permitTile(item);
            }),
        ],
      ),
    );
  }

  Widget todayCalendarSection() {
    return whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader(
            'Agenda Hari Ini',
            Icons.event,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    KalenderSiswaScreen(siswaId: widget.userId),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...kalenderHariIni.map((raw) {
            final item = Map<String, dynamic>.from(raw);
            final color = notificationColor(item['jenis']);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emptyDash(item['judul']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (emptyDash(item['keterangan']) != '-') ...[
                          const SizedBox(height: 4),
                          Text(
                            emptyDash(item['keterangan']),
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                  statusChip(item['jenis']),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget mainMenu() {
    final menus = [
      {
        'title': 'Absen Masuk',
        'icon': Icons.login,
        'color': Colors.green,
        'tap': () => openScan('/scan-harian'),
      },
      {
        'title': 'Absen Pulang',
        'icon': Icons.logout,
        'color': Colors.orange,
        'tap': () => openScan('/scan-harian'),
      },
      {
        'title': 'Absensi Mapel',
        'icon': Icons.school,
        'color': Colors.blue,
        'tap': () => openScan('/scan-mapel'),
      },
      {
        'title': 'Riwayat',
        'icon': Icons.history,
        'color': Colors.purple,
        'tap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RiwayatScreen(siswaId: widget.userId),
              ),
            ),
      },
      {
        'title': 'Izin / Sakit',
        'icon': Icons.description,
        'color': Colors.redAccent,
        'tap': () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PengajuanIzinScreen()),
          );
          if (refresh == true) loadDashboard();
        },
      },
      {
        'title': 'Kalender',
        'icon': Icons.calendar_month,
        'color': Colors.teal,
        'tap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    KalenderSiswaScreen(siswaId: widget.userId),
              ),
            ),
      },
      {
        'title': 'Bantuan',
        'icon': Icons.help_outline,
        'color': const Color(0xff273c75),
        'tap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BantuanScreen()),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Utama',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff273c75),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: menus.map((menu) {
            return menuCard(
              title: menu['title'] as String,
              icon: menu['icon'] as IconData,
              color: menu['color'] as Color,
              onTap: menu['tap'] as VoidCallback,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget scheduleTile(Map<String, dynamic> item) {
    return DashboardScheduleTile(
      item: item,
      currentTime: scheduleReferenceTime,
      onTap: () => showJadwalDetail(item),
    );
  }

  Widget permitTile(Map<String, dynamic> item) {
    final color = statusColor(item['status']);
    return InkWell(
      onTap: () => showPengajuanDetail(item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(Icons.description, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${titleCase(item['jenis'])} | ${titleCase(item['status'])}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${emptyDash(item['tanggal_mulai'])} s/d ${emptyDash(item['tanggal_selesai'])}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget menuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusBox({
    required String title,
    required bool done,
    required dynamic time,
    required dynamic status,
    required IconData icon,
  }) {
    final color = done ? statusColor(status) : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            done ? emptyDash(time) : 'Belum',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            done ? titleCase(status) : 'Belum absen',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget sectionHeader(String title, IconData icon, {VoidCallback? onTap}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff273c75)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xff273c75),
            ),
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text('Lihat'),
          ),
      ],
    );
  }

  Widget miniInfo(IconData icon, String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff5f6fa),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xff273c75)),
          const SizedBox(width: 6),
          Text(
            '$label: ${emptyDash(value)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget statusChip(dynamic status) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        titleCase(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget notificationTile(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfff5f6fa),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xff273c75), size: 34),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget detailSheet({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget detailRow(String label, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff5f6fa),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              emptyDash(value),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api.dart';
import '../../services/fcm_service.dart';
import '../../services/storage_service.dart';
import '../siswa/kalender_siswa_screen.dart';
import '../siswa/riwayat_screen.dart';

class DashboardOrangTua extends StatefulWidget {
  final String nama;
  final int siswaId;
  final String siswaNama;

  const DashboardOrangTua({
    super.key,
    required this.nama,
    required this.siswaId,
    required this.siswaNama,
  });

  @override
  State<DashboardOrangTua> createState() => _DashboardOrangTuaState();
}

class _DashboardOrangTuaState extends State<DashboardOrangTua> {
  Map<String, dynamic>? dashboard;
  bool loading = true;
  String? errorMessage;
  Set<String> readNotificationIds = {};
  StreamSubscription<Map<String, dynamic>>? notificationTapSubscription;

  @override
  void initState() {
    super.initState();
    notificationTapSubscription =
        FcmService.notificationTapStream.listen(handleNotificationTap);
    loadReadNotifications();
    loadDashboard();
  }

  @override
  void dispose() {
    notificationTapSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadDashboard() async {
    if (widget.siswaId <= 0) {
      setState(() {
        loading = false;
        errorMessage = 'Data siswa anak belum ditemukan.';
      });
      return;
    }

    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });
      final response = await http.get(
        Uri.parse('$baseUrl/siswa/dashboard/${widget.siswaId}'),
        headers: {'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode >= 400 || data['status'] == 'error') {
        setState(() {
          errorMessage = data['message'] ?? 'Data monitoring gagal dimuat.';
          loading = false;
        });
        return;
      }

      setState(() {
        dashboard = data;
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

  List<dynamic> get kalenderHariIni => dashboard?['kalender_hari_ini'] ?? [];

  List<dynamic> get notifikasi => dashboard?['notifikasi'] ?? [];

  List<dynamic> get notifikasiOrangTua =>
      dashboard?['notifikasi_orang_tua'] ?? notifikasi;

  String get readNotificationStorageKey =>
      'orang_tua_read_notifications_${widget.siswaId}';

  Future<void> loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      readNotificationIds =
          (prefs.getStringList(readNotificationStorageKey) ?? []).toSet();
    });
  }

  Future<void> saveReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      readNotificationStorageKey,
      readNotificationIds.toList(),
    );
  }

  String value(dynamic data) {
    final text = (data ?? '').toString();
    return text.trim().isEmpty ? '-' : text;
  }

  String titleCase(dynamic data) {
    final text = value(data).replaceAll('_', ' ');
    if (text == '-') return text;
    return text
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Color statusColor(dynamic data) {
    final text = value(data).toLowerCase();
    if (text.contains('hadir') || text.contains('aktif')) return Colors.green;
    if (text.contains('telat') ||
        text.contains('menunggu') ||
        text.contains('belum')) {
      return Colors.orange;
    }
    if (text.contains('izin') || text.contains('sakit')) return Colors.blue;
    if (text.contains('alfa') || text.contains('tolak')) return Colors.red;
    return const Color(0xff273c75);
  }

  IconData notificationIcon(dynamic data) {
    final text = value(data).toLowerCase();
    if (text.contains('alfa')) return Icons.warning_amber_rounded;
    if (text.contains('izin')) return Icons.assignment_turned_in;
    if (text.contains('sakit')) return Icons.local_hospital;
    if (text.contains('mapel')) return Icons.school;
    if (text.contains('pulang')) return Icons.logout;
    if (text.contains('masuk')) return Icons.login;
    if (text.contains('kalender')) return Icons.event;
    return Icons.notifications_active;
  }

  String attendanceDescription(Map<String, dynamic> data) {
    final tipe = value(data['tipe']).toLowerCase();
    final status = value(data['status'] ?? absensi['status_masuk']);
    final jam = value(data['jam']);
    final batasAbsen =
        value(data['batas_absen'] ?? dashboard?['batas_absen_masuk']);

    if (tipe == 'alfa' || status.toLowerCase().contains('alfa')) {
      return '${value(siswa['nama'] ?? widget.siswaNama)} belum absen masuk sampai batas waktu $batasAbsen, sehingga sementara dinyatakan Alfa.';
    }

    if (tipe == 'izin' || tipe == 'sakit') {
      return '${value(siswa['nama'] ?? widget.siswaNama)} hari ini tercatat ${titleCase(tipe)}.';
    }

    if (tipe == 'masuk') {
      if (jam == '-') {
        return '${value(siswa['nama'] ?? widget.siswaNama)} belum absen masuk. Batas absen masuk pukul $batasAbsen.';
      }
      final label = status.toLowerCase().contains('telat')
          ? 'tercatat telat'
          : 'tepat waktu';
      return '${value(siswa['nama'] ?? widget.siswaNama)} absen masuk jam $jam dan $label.';
    }

    if (tipe == 'pulang') {
      return '${value(siswa['nama'] ?? widget.siswaNama)} absen pulang jam $jam.';
    }

    if (tipe == 'mapel') {
      return '${value(siswa['nama'] ?? widget.siswaNama)} sudah absen mapel ${value(data['mapel'])} jam $jam.';
    }

    return value(data['pesan'] ?? 'Notifikasi absensi terbaru diterima.');
  }

  Map<String, dynamic> notificationPayload(Map<String, dynamic> item) {
    final payload = item['payload'];
    final data = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};

    return {
      ...data,
      'pesan': item['pesan'],
      'judul': item['judul'],
      'siswa_id': widget.siswaId.toString(),
    };
  }

  String notificationKey(Map<String, dynamic> item) {
    final id = value(item['id']);
    if (id != '-') return id;

    return '${value(item['judul'])}|${value(item['pesan'])}|${value(item['created_at'])}';
  }

  int unreadNotificationCount() {
    return notifikasiOrangTua
        .map((raw) => Map<String, dynamic>.from(raw))
        .where((item) => !readNotificationIds.contains(notificationKey(item)))
        .length;
  }

  Future<void> markParentNotificationsAsRead() async {
    final keys = notifikasiOrangTua
        .map((raw) => notificationKey(Map<String, dynamic>.from(raw)))
        .where((key) => key != '-')
        .toList();

    if (keys.isEmpty) return;

    setState(() {
      readNotificationIds.addAll(keys);
    });
    await saveReadNotifications();
  }

  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    final siswaId = int.tryParse(value(data['siswa_id']));
    if (siswaId != null && siswaId != widget.siswaId) return;

    await loadDashboard();
    if (!mounted) return;
    showAttendancePopup(data);
  }

  void showAttendancePopup(Map<String, dynamic> data) {
    final tipe = value(data['tipe']);
    final status = value(data['status'] ?? absensi['status_masuk']);
    final color = statusColor(status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(notificationIcon(tipe), color: color),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Rincian Absensi')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attendanceDescription(data),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            detailLine('Siswa', siswa['nama'] ?? widget.siswaNama),
            detailLine('Kelas', siswa['kelas']),
            detailLine('Jenis', titleCase(tipe)),
            detailLine('Jam', data['jam']),
            detailLine('Status', status),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff273c75),
            ),
            child: const Text('Lihat Notifikasi',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> showNotifications() async {
    await markParentNotificationsAsRead();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                sectionTitle('Notifikasi Terbaru', Icons.notifications_active),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff273c75).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Catatan: notifikasi akan terhapus otomatis setelah 30 hari.',
                    style: TextStyle(
                      color: Color(0xff273c75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (notifikasiOrangTua.isEmpty)
                  emptyState(Icons.check_circle, 'Tidak ada notifikasi',
                      'Semua status penting anak terlihat aman.')
                else
                  ...notifikasiOrangTua.take(10).map((raw) {
                    final item = Map<String, dynamic>.from(raw);
                    final payload = notificationPayload(item);
                    final color =
                        statusColor(payload['status'] ?? item['warna']);
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        showAttendancePopup(payload);
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: infoTile(
                        icon: notificationIcon(payload['tipe']),
                        color: color,
                        title: value(item['judul']),
                        subtitle:
                            '${value(item['pesan'])}\n${value(item['created_at'])}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget detailLine(String label, dynamic data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value(data),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    await StorageService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
          'Dashboard Orang Tua',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
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
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? errorView()
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      animated(0, heroCard()),
                      const SizedBox(height: 16),
                      animated(1, dailyStatusCard()),
                      const SizedBox(height: 16),
                      animated(2, notificationCard()),
                      const SizedBox(height: 16),
                      animated(3, scheduleCard()),
                      const SizedBox(height: 16),
                      animated(4, permitCard()),
                      const SizedBox(height: 16),
                      animated(5, actionMenu()),
                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }

  Widget animated(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - progress)),
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
        emptyState(Icons.wifi_off, 'Monitoring gagal dimuat',
            errorMessage ?? 'Terjadi kesalahan.'),
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff273c75).withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monitoring Anak',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value(siswa['nama'] ?? widget.siswaNama),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${value(siswa['kelas'])} - ${value(siswa['jurusan'])}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: glassMetric(
                  'Status Hari Ini',
                  titleCase(absensi['status_siswa']),
                  Icons.verified,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: glassMetric(
                  'Mapel',
                  value(statusMapel['label']),
                  Icons.school,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget dailyStatusCard() {
    return whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Absensi Hari Ini', Icons.fact_check),
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
        ],
      ),
    );
  }

  Widget notificationCard() {
    return whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Notifikasi Monitoring', Icons.notifications_active),
          const SizedBox(height: 12),
          if (notifikasi.isEmpty)
            emptyState(Icons.check_circle, 'Tidak ada notifikasi',
                'Semua status penting anak terlihat aman.')
          else
            ...notifikasi.take(4).map((raw) {
              final item = Map<String, dynamic>.from(raw);
              final color = statusColor(item['warna'] ?? item['kategori']);
              return infoTile(
                icon: Icons.notifications_active,
                color: color,
                title: value(item['judul']),
                subtitle: value(item['pesan']),
              );
            }),
        ],
      ),
    );
  }

  Widget scheduleCard() {
    return whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Jadwal dan Absen Mapel', Icons.calendar_month),
          const SizedBox(height: 12),
          if (jadwalHariIni.isEmpty)
            emptyState(Icons.event_available, 'Tidak ada jadwal',
                'Hari ini tidak ada jadwal mapel untuk anak.')
          else
            ...jadwalHariIni.map((raw) {
              final item = Map<String, dynamic>.from(raw);
              final done = item['sudah_absen'] == true;
              return infoTile(
                icon: done ? Icons.check_circle : Icons.pending_actions,
                color: done ? Colors.green : Colors.orange,
                title: value(item['nama_mapel']),
                subtitle:
                    '${value(item['jam_mulai'])} - ${value(item['jam_selesai'])} | ${done ? 'Sudah absen' : 'Belum absen'}',
                trailing: statusChip(done ? 'Sudah' : 'Belum'),
              );
            }),
        ],
      ),
    );
  }

  Widget permitCard() {
    return whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Pengajuan Izin / Sakit', Icons.description),
          const SizedBox(height: 12),
          if (pengajuan.isEmpty)
            emptyState(Icons.inbox, 'Belum ada pengajuan',
                'Riwayat izin atau sakit anak akan muncul di sini.')
          else
            ...pengajuan.take(3).map((raw) {
              final item = Map<String, dynamic>.from(raw);
              return infoTile(
                icon: Icons.description,
                color: statusColor(item['status']),
                title:
                    '${titleCase(item['jenis'])} | ${titleCase(item['status'])}',
                subtitle:
                    '${value(item['tanggal_mulai'])} s/d ${value(item['tanggal_selesai'])}',
              );
            }),
        ],
      ),
    );
  }

  Widget actionMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Orang Tua',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff273c75),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: menuButton(
                title: 'Riwayat Absensi',
                icon: Icons.history,
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RiwayatScreen(siswaId: widget.siswaId),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: menuButton(
                title: 'Kalender Sekolah',
                icon: Icons.calendar_month,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        KalenderSiswaScreen(siswaId: widget.siswaId),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget glassMetric(String title, String data, IconData icon) {
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
            data,
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
            done ? value(time) : 'Belum',
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

  Widget menuButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(height: 12),
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

  Widget infoTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          if (trailing != null) trailing,
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

  Widget sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff273c75)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xff273c75),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }

  Widget statusChip(dynamic data) {
    final color = statusColor(data);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        titleCase(data),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget emptyState(IconData icon, String title, String message) {
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
}

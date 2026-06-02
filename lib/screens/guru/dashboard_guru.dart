import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../config/api.dart';
import '../../services/storage_service.dart';
import '../piket/dashboard_piket.dart';
import '../wali/dashboard_wali.dart';

class DashboardGuru extends StatefulWidget {
  const DashboardGuru({super.key});

  @override
  State<DashboardGuru> createState() => _DashboardGuruState();
}

class _DashboardGuruState extends State<DashboardGuru> {
  bool loading = true;
  String nama = 'Guru';
  Map<String, dynamic> contextRole = {};
  List<Map<String, dynamic>> features = [];

  static const Color navy = Color(0xff243f7f);
  static const Color ink = Color(0xff172033);
  static const Color muted = Color(0xff64748b);
  static const Color bg = Color(0xffeef3f9);
  static const Color line = Color(0xffdfe7f2);
  static const Color gold = Color(0xfff4b84d);
  static const Color green = Color(0xff16845f);

  @override
  void initState() {
    super.initState();
    loadContext();
  }

  Future<void> loadContext() async {
    final storedName = await StorageService.getNama();
    final userId = await StorageService.getUserId();

    if (!mounted) return;
    setState(() {
      nama = storedName ?? 'Guru';
      loading = true;
    });

    if (userId == null) {
      if (!mounted) return;
      setState(() => loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mobile/role-context/$userId'),
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(response.body);
      final rawFeatures = data['features'] as List? ?? [];

      if (!mounted) return;
      setState(() {
        contextRole = Map<String, dynamic>.from(data['context'] ?? {});
        features = rawFeatures
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  bool get isGuruMapel => contextRole['is_guru_mapel'] == true;
  bool get isGuruMapelHariIni => contextRole['is_guru_mapel_hari_ini'] == true;
  bool get isGuruPiket => contextRole['is_guru_piket'] == true;
  bool get isGuruPiketHariIni => contextRole['is_guru_piket_hari_ini'] == true;
  bool get isWaliKelas => contextRole['is_wali'] == true;

  Future<void> openWeb(String path) async {
    if (path == '/dashboard/piket') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPiket()),
      );
      return;
    }

    if (path == '/dashboard/wali') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardWali()),
      );
      return;
    }

    final uri = Uri.parse('$webBaseUrl$path');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka dashboard web')),
      );
    }
  }

  Future<void> logout() async {
    await StorageService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: loadContext,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 178,
              backgroundColor: navy,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: loadContext,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xff243f7f), Color(0xff315b9e)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.school, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Guru Mapel, Guru Piket, dan Wali Kelas dalam satu akses.',
                        style: TextStyle(
                          color: Color(0xffdbe8ff),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          accessSummary(),
                          const SizedBox(height: 16),
                          const Text(
                            'Akses Guru',
                            style: TextStyle(
                              color: ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          roleCard(
                            title: 'Guru Mapel',
                            subtitle: isGuruMapelHariIni
                                ? 'Ada jadwal mengajar hari ini. Buka QR mapel, verifikasi, dan rekap.'
                                : 'Lihat jadwal, QR mapel, verifikasi absensi, dan rekap mapel.',
                            icon: Icons.menu_book,
                            color: navy,
                            active: isGuruMapel,
                            path: '/dashboard/guru',
                          ),
                          roleCard(
                            title: 'Guru Piket',
                            subtitle: isGuruPiketHariIni
                                ? 'Anda bertugas piket hari ini. Buka QR harian tim dan absensi siswa.'
                                : 'Akses jadwal piket, QR harian, pengajuan izin, dan rekap piket.',
                            icon: Icons.qr_code_scanner,
                            color: gold,
                            active: isGuruPiket,
                            path: '/dashboard/piket',
                          ),
                          roleCard(
                            title: 'Wali Kelas',
                            subtitle:
                                'Pantau siswa kelas, absensi, siswa rawan, dan laporan wali kelas.',
                            icon: Icons.groups,
                            color: green,
                            active: isWaliKelas,
                            path: '/dashboard/wali',
                          ),
                          const SizedBox(height: 8),
                          quickActions(),
                          if (features.isEmpty) emptyAccess(),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget accessSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          summaryChip('Mapel', isGuruMapel, Icons.menu_book),
          const SizedBox(width: 8),
          summaryChip('Piket', isGuruPiket, Icons.shield),
          const SizedBox(width: 8),
          summaryChip('Wali', isWaliKelas, Icons.groups),
        ],
      ),
    );
  }

  Widget summaryChip(String label, bool active, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xffe8f1ff) : const Color(0xfff8fafc),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? const Color(0xffb8cdf3) : line),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? navy : muted, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? navy : muted,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              active ? 'Aktif' : 'Tidak',
              style: TextStyle(
                color: active ? green : muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool active,
    required String path,
  }) {
    return InkWell(
      onTap: active ? () => openWeb(path) : null,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedOpacity(
        opacity: active ? 1 : .55,
        duration: const Duration(milliseconds: 180),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        statusPill(active),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                active ? Icons.open_in_new : Icons.lock_outline,
                color: active ? color : muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget statusPill(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xffdcf7e8) : const Color(0xffeef1f6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          color: active ? green : muted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget quickActions() {
    final activeFeatures = features.where((item) => item['path'] != null);
    if (activeFeatures.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shortcut Aktif',
          style: TextStyle(
            color: ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...activeFeatures.map((item) {
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: line),
            ),
            leading: Icon(featureIcon(item['icon']), color: featureColor(item)),
            title: Text(
              item['title'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(item['subtitle'] ?? '-'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openWeb(item['path']),
          );
        }),
      ],
    );
  }

  Widget emptyAccess() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: muted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Belum ada akses guru aktif. Pastikan guru punya jadwal mapel, jadwal piket, atau menjadi wali kelas.',
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  IconData featureIcon(dynamic icon) {
    if (icon == 'piket') return Icons.qr_code_scanner;
    if (icon == 'wali') return Icons.groups;
    if (icon == 'admin') return Icons.admin_panel_settings;
    return Icons.menu_book;
  }

  Color featureColor(Map<String, dynamic> item) {
    if (item['icon'] == 'piket') return gold;
    if (item['icon'] == 'wali') return green;
    if (item['icon'] == 'admin') return Colors.redAccent;
    return navy;
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .045),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

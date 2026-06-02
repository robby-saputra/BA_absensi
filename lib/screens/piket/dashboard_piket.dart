import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/api.dart';
import '../../services/storage_service.dart';
import 'piket_menu_screen.dart';

class DashboardPiket extends StatefulWidget {
  const DashboardPiket({super.key});

  @override
  State<DashboardPiket> createState() => _DashboardPiketState();
}

class _DashboardPiketState extends State<DashboardPiket> {
  static const Color navy = Color(0xff243f7f);
  static const Color ink = Color(0xff172033);
  static const Color muted = Color(0xff64748b);
  static const Color bg = Color(0xffeef3f9);
  static const Color line = Color(0xffdfe7f2);
  static const Color gold = Color(0xfff4b84d);
  static const Color green = Color(0xff16845f);
  static const Color red = Color(0xffbf3030);

  bool loading = true;
  bool generatingMasuk = false;
  bool generatingPulang = false;
  String nama = 'Guru Piket';
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final storedName = await StorageService.getNama();
    final userId = await StorageService.getUserId();

    if (!mounted) return;
    setState(() {
      nama = storedName ?? 'Guru Piket';
      loading = true;
    });

    if (userId == null) {
      if (!mounted) return;
      setState(() => loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mobile/piket-dashboard/$userId'),
        headers: {'Accept': 'application/json'},
      );
      final decoded = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        data = Map<String, dynamic>.from(decoded);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('Gagal memuat dashboard piket.');
    }
  }

  Future<void> generateQr(String tipe) async {
    final token = await StorageService.getToken();
    if (token == null) {
      showMessage('Sesi login habis. Silakan login ulang.');
      return;
    }

    setState(() {
      if (tipe == 'masuk') {
        generatingMasuk = true;
      } else {
        generatingPulang = true;
      }
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/qr/generate'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {'tipe': tipe},
      );

      final decoded = jsonDecode(response.body);
      showMessage(decoded['message'] ?? 'QR berhasil diproses.');
      await loadDashboard();
    } catch (_) {
      showMessage('Gagal generate QR $tipe.');
    } finally {
      if (mounted) {
        setState(() {
          generatingMasuk = false;
          generatingPulang = false;
        });
      }
    }
  }

  Future<void> logout() async {
    await StorageService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Map<String, dynamic>? get team {
    final value = data['team'];
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic> get summary {
    final value = data['summary'];
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  Map<String, dynamic>? qrByType(String tipe) {
    final qr = data['qr'];
    if (qr is! Map) return null;
    final value = qr[tipe];
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  bool get isHoliday => data['is_holiday'] == true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 176,
              backgroundColor: navy,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: loadDashboard,
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
                      const Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 42),
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
                      Text(
                        '${data['hari'] ?? '-'} | ${data['tanggal'] ?? '-'}',
                        style: const TextStyle(
                          color: Color(0xffdbe8ff),
                          fontWeight: FontWeight.w700,
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
                          if (isHoliday) holidayBanner(),
                          teamCard(),
                          const SizedBox(height: 14),
                          statsGrid(),
                          const SizedBox(height: 18),
                          sectionTitle('QR Absensi Harian'),
                          qrCard('masuk'),
                          qrCard('pulang'),
                          const SizedBox(height: 8),
                          sectionTitle('Menu Piket'),
                          shortcutGrid(),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget holidayBanner() {
    final holiday = data['holiday'];
    final title = holiday is Map ? holiday['judul'] : 'Hari libur';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfffff1e6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffffcfaa)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy, color: red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hari ini libur: $title. QR absensi harian tidak dapat dibuat.',
              style: const TextStyle(
                color: red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget teamCard() {
    final currentTeam = team;
    if (currentTeam == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: muted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tim guru piket hari ini belum ditemukan.',
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    final members = (currentTeam['anggota'] as List? ?? []);
    final replacements = (currentTeam['pengganti'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tim Piket ${currentTeam['hari'] ?? ''}',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              statusPill(
                  '${currentTeam['jam_mulai']} - ${currentTeam['jam_selesai']}'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: members.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return personChip(item['nama'] ?? '-');
            }).toList(),
          ),
          if (replacements.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfffff7e7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xfff3d291)),
              ),
              child: Text(
                'Guru pengganti: ${replacements.join(', ')}',
                style: const TextStyle(
                  color: Color(0xff8a510b),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget statsGrid() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.42,
      children: [
        statCard('Masuk', summary['masuk'] ?? 0, Icons.login, green),
        statCard('Pulang', summary['pulang'] ?? 0, Icons.logout, navy),
        statCard('Izin/Sakit', summary['izin_sakit'] ?? 0,
            Icons.medical_information, gold),
        statCard('Pengajuan', summary['pengajuan_menunggu'] ?? 0,
            Icons.mark_email_unread, red),
      ],
    );
  }

  Widget qrCard(String tipe) {
    final qr = qrByType(tipe);
    final isMasuk = tipe == 'masuk';
    final isGenerating = isMasuk ? generatingMasuk : generatingPulang;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isMasuk ? Icons.login : Icons.logout, color: navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'QR ${isMasuk ? 'Masuk' : 'Pulang'}',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              statusPill(qr == null ? 'Belum ada' : 'Aktif'),
            ],
          ),
          const SizedBox(height: 14),
          if (qr == null)
            Text(
              isHoliday
                  ? 'Hari libur, QR tidak dapat dibuat.'
                  : 'Belum ada QR ${isMasuk ? 'masuk' : 'pulang'} untuk tim hari ini.',
              style: const TextStyle(color: muted, fontWeight: FontWeight.w600),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: line),
                  ),
                  child: QrImageView(
                    data: qr['token'] ?? '',
                    version: QrVersions.auto,
                    size: 112,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Token',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        qr['token'] ?? '-',
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Berlaku sampai ${qr['expires_at'] ?? '-'}',
                        style: const TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  isHoliday || isGenerating ? null : () => generateQr(tipe),
              icon: isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.qr_code),
              label: Text(qr == null ? 'Generate QR' : 'Refresh QR Tim'),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: muted.withValues(alpha: .35),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget shortcutGrid() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.02,
      children: [
        shortcutCard('Absensi Harian', 'Kelola data siswa', Icons.fact_check,
            PiketMenuType.absensi),
        shortcutCard('Pengajuan Izin', 'Review izin/sakit',
            Icons.assignment_turned_in, PiketMenuType.pengajuan),
        shortcutCard('Rekap Jadwal', 'Jadwal tim piket', Icons.groups,
            PiketMenuType.jadwal),
        shortcutCard(
            'Riwayat', 'Riwayat absensi', Icons.history, PiketMenuType.riwayat),
      ],
    );
  }

  Widget shortcutCard(
    String title,
    String subtitle,
    IconData icon,
    PiketMenuType type,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PiketMenuScreen(type: type),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: navy, size: 30),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget statCard(String title, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget statusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffe8f1ff),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: navy,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget personChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xfff8fbff),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: ink,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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

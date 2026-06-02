import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';
import '../../services/storage_service.dart';

class DashboardWali extends StatefulWidget {
  const DashboardWali({super.key});

  @override
  State<DashboardWali> createState() => _DashboardWaliState();
}

class _DashboardWaliState extends State<DashboardWali> {
  static const navy = Color(0xff243f7f);
  static const ink = Color(0xff172033);
  static const muted = Color(0xff64748b);
  static const bg = Color(0xffeef3f9);
  static const line = Color(0xffdfe7f2);
  static const green = Color(0xff16845f);
  static const red = Color(0xffbf3030);

  bool loading = true;
  bool failed = false;
  String nama = 'Wali Kelas';
  String tanggal = '';
  String activeTab = 'siswa';
  String search = '';
  String statusFilter = 'semua';

  Map<String, dynamic> wali = {};
  Map<String, dynamic> ringkasan = {};
  List<Map<String, dynamic>> siswa = [];
  List<Map<String, dynamic>> absensi = [];
  List<Map<String, dynamic>> rawan = [];

  final tabs = const [
    {'label': 'Siswa', 'value': 'siswa', 'icon': Icons.groups_rounded},
    {'label': 'Absensi', 'value': 'absensi', 'icon': Icons.fact_check_rounded},
    {'label': 'Rawan', 'value': 'rawan', 'icon': Icons.warning_rounded},
  ];

  final statusOptions = const [
    {'label': 'Semua', 'value': 'semua'},
    {'label': 'Hadir', 'value': 'hadir'},
    {'label': 'Telat', 'value': 'telat'},
    {'label': 'Izin', 'value': 'izin'},
    {'label': 'Sakit', 'value': 'sakit'},
    {'label': 'Alfa', 'value': 'alfa'},
    {'label': 'Belum', 'value': 'belum'},
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final storedName = await StorageService.getNama();
    final userId = await StorageService.getUserId();

    if (!mounted) return;
    setState(() {
      nama = storedName ?? 'Wali Kelas';
      loading = true;
      failed = false;
    });

    if (userId == null) {
      setState(() {
        loading = false;
        failed = true;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mobile/wali-dashboard/$userId'),
        headers: {'Accept': 'application/json'},
      );
      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        tanggal = decoded['tanggal']?.toString() ?? '';
        wali = Map<String, dynamic>.from(decoded['wali'] ?? {});
        ringkasan = Map<String, dynamic>.from(decoded['ringkasan'] ?? {});
        siswa = toMapList(decoded['siswa']);
        absensi = toMapList(decoded['absensi']);
        rawan = toMapList(decoded['rawan']);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        failed = true;
      });
    }
  }

  List<Map<String, dynamic>> toMapList(dynamic input) {
    final list = input as List? ?? [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  List<Map<String, dynamic>> get filteredSiswa {
    return siswa.where((item) {
      if (!matchesStatus(item)) return false;
      if (search.trim().isEmpty) return true;
      final q = search.toLowerCase();
      return '${item['nama']} ${item['nis']} ${item['username']} ${item['nama_ortu']} ${item['no_ortu']}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredAbsensi {
    return absensi.where((item) {
      if (!matchesStatus(item)) return false;
      if (search.trim().isEmpty) return true;
      final q = search.toLowerCase();
      return '${item['nama']} ${item['nis']} ${item['tanggal']} ${item['status_masuk']} ${item['status_pulang']}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredRawan {
    return rawan.where((item) {
      if (search.trim().isEmpty) return true;
      final q = search.toLowerCase();
      return '${item['nama']} ${item['nis']}'.toLowerCase().contains(q);
    }).toList();
  }

  bool matchesStatus(Map<String, dynamic> item) {
    if (statusFilter == 'semua') return true;

    final statusMasuk = value(item['status_masuk']).toLowerCase();
    final statusPulang = value(item['status_pulang']).toLowerCase();
    final combined = '$statusMasuk $statusPulang';
    final jamMasuk = value(item['jam_masuk']);

    if (statusFilter == 'belum') {
      return jamMasuk == '-' &&
          !combined.contains('izin') &&
          !combined.contains('sakit') &&
          !combined.contains('alfa') &&
          !combined.contains('alpa');
    }
    if (statusFilter == 'alfa') {
      return combined.contains('alfa') || combined.contains('alpa');
    }
    if (statusFilter == 'hadir') {
      return statusMasuk.contains('hadir') && !statusMasuk.contains('telat');
    }
    return combined.contains(statusFilter);
  }

  String value(dynamic input) {
    final text = (input ?? '').toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Color statusColor(dynamic input) {
    final status = value(input).toLowerCase();
    if (status.contains('hadir')) return green;
    if (status.contains('telat')) return const Color(0xffb76b11);
    if (status.contains('izin')) return navy;
    if (status.contains('sakit')) return const Color(0xff7d55c7);
    if (status.contains('alfa') || status.contains('alpa')) return red;
    return muted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Wali Kelas',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: navy))
          : failed
              ? errorState()
              : RefreshIndicator(
                  color: navy,
                  onRefresh: loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      headerCard(),
                      const SizedBox(height: 14),
                      tabSelector(),
                      const SizedBox(height: 14),
                      filterPanel(),
                      const SizedBox(height: 14),
                      ...contentSection(),
                    ],
                  ),
                ),
    );
  }

  Widget headerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.supervisor_account_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${value(wali['nama_kelas'])} | ${value(wali['nama_jurusan'])}',
                      style: const TextStyle(
                        color: Color(0xffdce7ff),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: statBox('Siswa', ringkasan['total_siswa'])),
              const SizedBox(width: 8),
              Expanded(child: statBox('Hadir', ringkasan['hadir_hari_ini'])),
              const SizedBox(width: 8),
              Expanded(child: statBox('Belum', ringkasan['belum_absen'])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: statBox('Telat', ringkasan['telat_hari_ini'])),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      statBox('Izin/Sakit', ringkasan['izin_sakit_hari_ini'])),
              const SizedBox(width: 8),
              Expanded(child: statBox('Alfa', ringkasan['alfa_hari_ini'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget statBox(String title, dynamic count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xffdce7ff),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${count ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget tabSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: cardDecoration(radius: 18),
      child: Row(
        children: tabs.map((tab) {
          final active = activeTab == tab['value'];
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  activeTab = tab['value'] as String;
                  search = '';
                  statusFilter = 'semua';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      color: active ? Colors.white : muted,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: active ? Colors.white : muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget filterPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => search = value),
            decoration: inputDecoration(
              activeTab == 'rawan'
                  ? 'Cari siswa rawan...'
                  : 'Cari nama, NIS, kelas, status...',
            ),
          ),
          if (activeTab != 'rawan') ...[
            const SizedBox(height: 12),
            const Text(
              'Filter Status',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statusOptions.map((option) {
                  final active = statusFilter == option['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: active,
                      label: Text(option['label']!),
                      selectedColor: navy,
                      backgroundColor: const Color(0xfff8fbff),
                      labelStyle: TextStyle(
                        color: active ? Colors.white : navy,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(color: active ? navy : line),
                      ),
                      onSelected: (_) {
                        setState(() => statusFilter = option['value']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> contentSection() {
    if (activeTab == 'absensi') {
      final rows = filteredAbsensi;
      return rows.isEmpty
          ? [emptyCard('Belum ada riwayat absensi.')]
          : rows.map(absensiCard).toList();
    }
    if (activeTab == 'rawan') {
      final rows = filteredRawan;
      return rows.isEmpty
          ? [emptyCard('Belum ada siswa rawan 30 hari terakhir.')]
          : rows.map(rawanCard).toList();
    }

    final rows = filteredSiswa;
    return rows.isEmpty
        ? [emptyCard('Belum ada siswa yang cocok.')]
        : rows.map(siswaCard).toList();
  }

  Widget siswaCard(Map<String, dynamic> item) {
    final status = value(item['status_masuk']) == '-'
        ? 'belum'
        : value(item['status_masuk']);
    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          personHeader(item['nama'],
              '${value(item['nis'])} | ${value(item['username'])}', color),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: infoBox(
                    'Masuk',
                    joinTimeStatus(item['jam_masuk'], item['status_masuk']),
                    Icons.login_rounded,
                    color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: infoBox(
                    'Pulang',
                    joinTimeStatus(item['jam_pulang'], item['status_pulang']),
                    Icons.logout_rounded,
                    navy),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              pill('Ortu: ${value(item['nama_ortu'])}', navy),
              pill('Telp: ${value(item['no_ortu'])}', muted),
            ],
          ),
        ],
      ),
    );
  }

  Widget absensiCard(Map<String, dynamic> item) {
    final color = statusColor(item['status_masuk']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          personHeader(item['nama'],
              '${value(item['tanggal'])} | NIS ${value(item['nis'])}', color),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: infoBox(
                    'Masuk',
                    joinTimeStatus(item['jam_masuk'], item['status_masuk']),
                    Icons.login_rounded,
                    color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: infoBox(
                    'Pulang',
                    joinTimeStatus(item['jam_pulang'], item['status_pulang']),
                    Icons.logout_rounded,
                    statusColor(item['status_pulang'])),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget rawanCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          personHeader(item['nama'], 'NIS ${value(item['nis'])}',
              const Color(0xffb76b11)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: infoBox('Temuan', '${item['total_temuan'] ?? 0}',
                      Icons.analytics_rounded, const Color(0xffb76b11))),
              const SizedBox(width: 10),
              Expanded(
                  child: infoBox('Telat', '${item['telat'] ?? 0}',
                      Icons.schedule_rounded, navy)),
              const SizedBox(width: 10),
              Expanded(
                  child: infoBox('Alfa', '${item['alfa'] ?? 0}',
                      Icons.warning_rounded, red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget personHeader(dynamic title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar(value(title), color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value(title),
                style: const TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style:
                    const TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget avatar(String name, Color color) {
    final initials = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'S' : initials,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget infoBox(String label, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: navy, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Data wali kelas belum terbaca',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: ink, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Periksa koneksi atau pastikan akun guru sudah menjadi wali kelas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Muat Ulang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded, color: navy),
      filled: true,
      fillColor: const Color(0xfff8fbff),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: navy, width: 1.5),
      ),
    );
  }

  String joinTimeStatus(dynamic time, dynamic status) {
    final t = value(time);
    final s = value(status);
    if (t == '-' && s == '-') return '-';
    if (t == '-') return s;
    if (s == '-') return shortTime(t);
    return '${shortTime(t)} - $s';
  }

  String shortTime(String input) {
    if (input.length >= 5) return input.substring(0, 5);
    return input;
  }

  BoxDecoration cardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';
import '../../services/storage_service.dart';

enum PiketMenuType { absensi, pengajuan, jadwal, riwayat }

class PiketMenuScreen extends StatefulWidget {
  final PiketMenuType type;

  const PiketMenuScreen({super.key, required this.type});

  @override
  State<PiketMenuScreen> createState() => _PiketMenuScreenState();
}

class _PiketMenuScreenState extends State<PiketMenuScreen> {
  static const Color navy = Color(0xff243f7f);
  static const Color ink = Color(0xff172033);
  static const Color muted = Color(0xff64748b);
  static const Color bg = Color(0xffeef3f9);
  static const Color line = Color(0xffdfe7f2);
  static const Color green = Color(0xff16845f);
  static const Color red = Color(0xffbf3030);

  bool loading = true;
  List<Map<String, dynamic>> rows = [];
  String tanggal = '';
  String search = '';
  String attendanceFilter = 'semua';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String get title {
    switch (widget.type) {
      case PiketMenuType.absensi:
        return 'Absensi Harian';
      case PiketMenuType.pengajuan:
        return 'Pengajuan Izin';
      case PiketMenuType.jadwal:
        return 'Rekap Jadwal';
      case PiketMenuType.riwayat:
        return 'Riwayat Absensi';
    }
  }

  IconData get icon {
    switch (widget.type) {
      case PiketMenuType.absensi:
        return Icons.fact_check;
      case PiketMenuType.pengajuan:
        return Icons.assignment_turned_in;
      case PiketMenuType.jadwal:
        return Icons.groups;
      case PiketMenuType.riwayat:
        return Icons.history;
    }
  }

  String endpoint(int userId) {
    switch (widget.type) {
      case PiketMenuType.absensi:
        return '$baseUrl/mobile/piket-absensi/$userId';
      case PiketMenuType.pengajuan:
        return '$baseUrl/mobile/piket-pengajuan/$userId';
      case PiketMenuType.jadwal:
        return '$baseUrl/mobile/piket-jadwal/$userId';
      case PiketMenuType.riwayat:
        return '$baseUrl/mobile/piket-riwayat/$userId';
    }
  }

  Future<void> loadData() async {
    final userId = await StorageService.getUserId();
    if (userId == null) {
      setState(() => loading = false);
      return;
    }

    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse(endpoint(userId)),
        headers: {'Accept': 'application/json'},
      );
      final decoded = jsonDecode(response.body);
      final data = decoded['data'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        rows = data.map((item) => Map<String, dynamic>.from(item)).toList();
        tanggal = decoded['tanggal']?.toString() ?? '';
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('Gagal memuat $title.');
    }
  }

  Future<void> reviewPengajuan(int id, String status) async {
    final userId = await StorageService.getUserId();
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mobile/piket-pengajuan/$id/review'),
        headers: {'Accept': 'application/json'},
        body: {
          'user_id': '$userId',
          'status': status,
          'catatan_review': '',
        },
      );
      final decoded = jsonDecode(response.body);
      showMessage(decoded['message'] ?? 'Pengajuan diproses.');
      await loadData();
    } catch (_) {
      showMessage('Gagal memproses pengajuan.');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Text(title),
        actions: [
          IconButton(onPressed: loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            headerCard(),
            const SizedBox(height: 14),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rows.isEmpty)
              emptyCard()
            else if (widget.type == PiketMenuType.absensi)
              ...absensiSection()
            else if (widget.type == PiketMenuType.jadwal)
              ...jadwalSections()
            else
              ...rows.map(itemCard),
          ],
        ),
      ),
    );
  }

  Widget headerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xffe8f1ff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: navy, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  tanggal.isEmpty
                      ? '${rows.length} data'
                      : '$tanggal | ${rows.length} data',
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
    );
  }

  Widget itemCard(Map<String, dynamic> item) {
    switch (widget.type) {
      case PiketMenuType.absensi:
        return absensiCard(item);
      case PiketMenuType.pengajuan:
        return pengajuanCard(item);
      case PiketMenuType.jadwal:
        return jadwalCard(item);
      case PiketMenuType.riwayat:
        return riwayatCard(item);
    }
  }

  Widget absensiCard(Map<String, dynamic> item) {
    final statusMasuk = (item['status_masuk'] ?? '').toString();
    final statusPulang = (item['status_pulang'] ?? '').toString();
    final color =
        attendanceColor(statusMasuk.isNotEmpty ? statusMasuk : statusPulang);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar(item['nama'] ?? '-'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama'] ?? '-',
                      style: const TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['nama_kelas'] ?? '-'} | NIS ${item['nis'] ?? '-'}',
                      style: const TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              chip(statusMasuk.isEmpty ? 'Belum' : statusMasuk, color),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: timeBox(
                  label: 'Masuk',
                  value:
                      joinTimeStatus(item['jam_masuk'], item['status_masuk']),
                  icon: Icons.login,
                  color: green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: timeBox(
                  label: 'Pulang',
                  value:
                      joinTimeStatus(item['jam_pulang'], item['status_pulang']),
                  icon: Icons.logout,
                  color: navy,
                ),
              ),
            ],
          ),
          if ((item['catatan_piket'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff8fbff),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: Text(
                item['catatan_piket'].toString(),
                style:
                    const TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> absensiSection() {
    final filtered = rows.where((item) {
      if (!matchesAttendanceFilter(item)) return false;
      if (search.trim().isEmpty) return true;
      final q = search.toLowerCase();
      return '${item['nama']} ${item['nis']} ${item['nama_kelas']}'
          .toLowerCase()
          .contains(q);
    }).toList();

    final masuk = rows
        .where((item) => (item['jam_masuk'] ?? '').toString().isNotEmpty)
        .length;
    final pulang = rows
        .where((item) => (item['jam_pulang'] ?? '').toString().isNotEmpty)
        .length;
    final khusus = rows.where((item) {
      final sm = (item['status_masuk'] ?? '').toString();
      final sp = (item['status_pulang'] ?? '').toString();
      return ['izin', 'sakit', 'alfa', 'alpa'].contains(sm) ||
          ['izin', 'sakit', 'alfa', 'alpa'].contains(sp);
    }).length;

    return [
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: miniStat('Masuk', masuk, green)),
                const SizedBox(width: 8),
                Expanded(child: miniStat('Pulang', pulang, navy)),
                const SizedBox(width: 8),
                Expanded(
                    child: miniStat('Khusus', khusus, const Color(0xffb76b11))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => search = value),
              decoration: InputDecoration(
                hintText: 'Cari nama, NIS, atau kelas...',
                prefixIcon: const Icon(Icons.search, color: navy),
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
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: attendanceFilterOptions.map((option) {
                  final active = attendanceFilter == option['value'];
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
                        setState(() => attendanceFilter = option['value']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      if (filtered.isEmpty) emptyCard() else ...filtered.map(absensiCard),
    ];
  }

  Widget riwayatCard(Map<String, dynamic> item) {
    return baseCard(
      title: item['nama'] ?? '-',
      subtitle:
          '${item['tanggal'] ?? '-'} | ${item['nama_kelas'] ?? '-'} | NIS ${item['nis'] ?? '-'}',
      chips: [
        chip(
            'Masuk: ${joinTimeStatus(item['jam_masuk'], item['status_masuk'])}',
            green),
        chip(
            'Pulang: ${joinTimeStatus(item['jam_pulang'], item['status_pulang'])}',
            navy),
      ],
    );
  }

  Widget jadwalCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'Akan Bertugas').toString();
    final statusColor = scheduleStatusColor(status);
    final pengganti = [
      item['guru_pengganti'],
      item['guru_pengganti2'],
    ].where((value) => value != null && value.toString().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xffe8f1ff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.schedule, color: navy, size: 20),
                const SizedBox(height: 6),
                Text(
                  shortTime(item['jam_mulai']),
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  shortTime(item['jam_selesai']),
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['guru_utama'] ?? '-',
                        style: const TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    chip(status, statusColor),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Guru utama piket',
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pengganti.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xfffff7e7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xfff3d291)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guru Pengganti',
                          style: TextStyle(
                            color: Color(0xff8a510b),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pengganti.join(', '),
                          style: const TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> jadwalSections() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final hari = (row['hari'] ?? 'Tanpa Hari').toString();
      grouped.putIfAbsent(hari, () => []).add(row);
    }

    return grouped.entries.map((entry) {
      final totalAktif = entry.value.where((item) => item['aktif'] == 1).length;
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xfff8fbff),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_month,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ucfirst(entry.key),
                          style: const TextStyle(
                            color: ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${entry.value.length} jadwal | $totalAktif aktif',
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              child: Column(children: entry.value.map(jadwalCard).toList()),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget pengajuanCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? '-').toString();
    final isWaiting = status == 'menunggu';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['nama_siswa'] ?? '-',
            style: const TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${item['nama_kelas'] ?? '-'} | ${item['tanggal_mulai']} s/d ${item['tanggal_selesai']}',
            style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip('Jenis: ${item['jenis'] ?? '-'}', navy),
              chip('Status: $status',
                  isWaiting ? const Color(0xffb76b11) : green),
            ],
          ),
          if ((item['alasan'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item['alasan'].toString(),
              style: const TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ],
          if (isWaiting) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: actionButton(
                    'Tolak',
                    red,
                    () => reviewPengajuan(item['id'], 'ditolak'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: actionButton(
                    'Setujui',
                    green,
                    () => reviewPengajuan(item['id'], 'disetujui'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget baseCard({
    required String title,
    required String subtitle,
    required List<Widget> chips,
    dynamic note,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
          if (note != null && note.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              note.toString(),
              style: const TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget avatar(String name) {
    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          parts.isEmpty ? 'S' : parts,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget timeBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .18)),
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
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget miniStat(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget emptyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: muted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Belum ada data untuk menu ini.',
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String joinTimeStatus(dynamic time, dynamic status) {
    final t = time?.toString();
    final s = status?.toString();
    if ((t == null || t.isEmpty) && (s == null || s.isEmpty)) return '-';
    if (t == null || t.isEmpty) return s ?? '-';
    if (s == null || s.isEmpty) return shortTime(t);
    return '${shortTime(t)} - $s';
  }

  String shortTime(dynamic value) {
    final text = value?.toString() ?? '-';
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  List<Map<String, String>> get attendanceFilterOptions => const [
        {'label': 'Semua', 'value': 'semua'},
        {'label': 'Hadir', 'value': 'hadir'},
        {'label': 'Telat', 'value': 'telat'},
        {'label': 'Izin', 'value': 'izin'},
        {'label': 'Sakit', 'value': 'sakit'},
        {'label': 'Alfa', 'value': 'alfa'},
        {'label': 'Belum Masuk', 'value': 'belum'},
      ];

  bool matchesAttendanceFilter(Map<String, dynamic> item) {
    if (attendanceFilter == 'semua') return true;

    final jamMasuk = (item['jam_masuk'] ?? '').toString();
    final statusMasuk = (item['status_masuk'] ?? '').toString().toLowerCase();
    final statusPulang = (item['status_pulang'] ?? '').toString().toLowerCase();
    final combined = '$statusMasuk $statusPulang';

    if (attendanceFilter == 'belum') {
      return jamMasuk.isEmpty &&
          !combined.contains('izin') &&
          !combined.contains('sakit') &&
          !combined.contains('alfa') &&
          !combined.contains('alpa');
    }

    if (attendanceFilter == 'alfa') {
      return combined.contains('alfa') || combined.contains('alpa');
    }

    if (attendanceFilter == 'hadir') {
      return statusMasuk.contains('hadir') && !statusMasuk.contains('telat');
    }

    return combined.contains(attendanceFilter);
  }

  Color attendanceColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('hadir')) return green;
    if (normalized.contains('telat')) return const Color(0xffb76b11);
    if (normalized.contains('izin')) return navy;
    if (normalized.contains('sakit')) return red;
    if (normalized.contains('alfa') || normalized.contains('alpa')) return red;
    return muted;
  }

  String ucfirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Color scheduleStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('sedang')) return green;
    if (normalized.contains('selesai')) return navy;
    if (normalized.contains('izin') ||
        normalized.contains('sakit') ||
        normalized.contains('ganti')) {
      return const Color(0xffb76b11);
    }
    return muted;
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

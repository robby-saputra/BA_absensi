import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';
import '../../services/storage_service.dart';

class RiwayatScreen extends StatefulWidget {
  final int siswaId;

  const RiwayatScreen({
    super.key,
    required this.siswaId,
  });

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  static const navy = Color(0xff233b78);
  static const ink = Color(0xff172033);
  static const muted = Color(0xff66758f);
  static const line = Color(0xffdfe7f3);
  static const bg = Color(0xfff3f7fc);

  List<Map<String, dynamic>> data = [];
  bool loading = true;
  bool failed = false;

  String search = '';
  String typeFilter = 'semua';
  String statusFilter = 'semua';
  String periodFilter = 'semua';
  DateTimeRange? customRange;

  final typeOptions = const [
    {'label': 'Semua', 'value': 'semua'},
    {'label': 'Masuk', 'value': 'masuk'},
    {'label': 'Pulang', 'value': 'pulang'},
    {'label': 'Mapel', 'value': 'mapel'},
  ];

  final statusOptions = const [
    {'label': 'Semua', 'value': 'semua'},
    {'label': 'Hadir', 'value': 'hadir'},
    {'label': 'Telat', 'value': 'telat'},
    {'label': 'Izin', 'value': 'izin'},
    {'label': 'Sakit', 'value': 'sakit'},
    {'label': 'Alfa', 'value': 'alfa'},
    {'label': 'Pulang Cepat', 'value': 'pulang_cepat'},
  ];

  final periodOptions = const [
    {'label': 'Semua', 'value': 'semua'},
    {'label': 'Hari ini', 'value': 'today'},
    {'label': '7 hari', 'value': 'week'},
    {'label': '30 hari', 'value': 'month'},
    {'label': 'Pilih tanggal', 'value': 'custom'},
  ];

  Future<void> getRiwayat() async {
    setState(() {
      loading = true;
      failed = false;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.trim().isEmpty) {
        if (mounted) {
          setState(() {
            loading = false;
            failed = true;
          });
        }
        return;
      }
      final url = Uri.parse('$baseUrl/riwayat/${widget.siswaId}');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.trim()}',
      });
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 400 || decoded is! List) {
        throw Exception(
            decoded is Map ? decoded['message'] : 'Riwayat gagal dimuat');
      }
      final result = decoded;

      if (!mounted) return;

      setState(() {
        data = result.map((item) => Map<String, dynamic>.from(item)).toList();
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

  @override
  void initState() {
    super.initState();
    getRiwayat();
  }

  List<Map<String, dynamic>> get filteredData {
    return data.where((item) {
      final jenis = value(item['jenis']).toLowerCase();
      final status = normalizeStatus(item['status']);
      final tanggal = parseDate(item['tanggal']);
      final q = search.trim().toLowerCase();

      if (typeFilter != 'semua' && !jenis.contains(typeFilter)) return false;
      if (statusFilter != 'semua' && status != statusFilter) return false;
      if (!matchesPeriod(tanggal)) return false;

      if (q.isEmpty) return true;
      return '${item['jenis']} ${item['status']} ${item['tanggal']} ${item['jam_scan']}'
          .toLowerCase()
          .contains(q);
    }).toList()
      ..sort((a, b) {
        final dateA = '${a['tanggal'] ?? ''} ${a['jam_scan'] ?? ''}';
        final dateB = '${b['tanggal'] ?? ''} ${b['jam_scan'] ?? ''}';
        return dateB.compareTo(dateA);
      });
  }

  bool matchesPeriod(DateTime? date) {
    if (periodFilter == 'semua') return true;
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);

    if (periodFilter == 'today') return current == today;
    if (periodFilter == 'week') {
      return !current.isBefore(today.subtract(const Duration(days: 6))) &&
          !current.isAfter(today);
    }
    if (periodFilter == 'month') {
      return !current.isBefore(today.subtract(const Duration(days: 29))) &&
          !current.isAfter(today);
    }
    if (periodFilter == 'custom' && customRange != null) {
      final start = DateTime(
        customRange!.start.year,
        customRange!.start.month,
        customRange!.start.day,
      );
      final end = DateTime(
        customRange!.end.year,
        customRange!.end.month,
        customRange!.end.day,
      );
      return !current.isBefore(start) && !current.isAfter(end);
    }

    return true;
  }

  String value(dynamic input) {
    final text = (input ?? '').toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String normalizeStatus(dynamic input) {
    final status = value(input).toLowerCase().replaceAll(' ', '_');
    if (status == 'alpa') return 'alfa';
    return status;
  }

  DateTime? parseDate(dynamic input) {
    final text = value(input);
    if (text == '-') return null;
    return DateTime.tryParse(text);
  }

  Color statusColor(dynamic input) {
    switch (normalizeStatus(input)) {
      case 'hadir':
        return const Color(0xff168753);
      case 'telat':
        return const Color(0xffb76b11);
      case 'izin':
        return const Color(0xff2868b7);
      case 'sakit':
        return const Color(0xff7d55c7);
      case 'pulang_cepat':
        return const Color(0xffc45a24);
      default:
        return const Color(0xffc33636);
    }
  }

  IconData jenisIcon(dynamic input) {
    final jenis = value(input).toLowerCase();
    if (jenis.contains('masuk')) return Icons.login_rounded;
    if (jenis.contains('pulang')) return Icons.logout_rounded;
    return Icons.menu_book_rounded;
  }

  int countStatus(String status) {
    return data
        .where((item) => normalizeStatus(item['status']) == status)
        .length;
  }

  int countType(String type) {
    return data
        .where((item) => value(item['jenis']).toLowerCase().contains(type))
        .length;
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: navy,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (range == null) return;
    setState(() {
      customRange = range;
      periodFilter = 'custom';
    });
  }

  void resetFilters() {
    setState(() {
      search = '';
      typeFilter = 'semua';
      statusFilter = 'semua';
      periodFilter = 'semua';
      customRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = filteredData;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Riwayat Absensi',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: getRiwayat,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: navy))
          : failed
              ? stateMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'Riwayat belum terbaca',
                  message: 'Periksa koneksi lalu muat ulang halaman ini.',
                  action: ElevatedButton.icon(
                    onPressed: getRiwayat,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Muat Ulang'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: getRiwayat,
                  color: navy,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      headerCard(rows.length),
                      const SizedBox(height: 14),
                      filterPanel(),
                      const SizedBox(height: 14),
                      if (rows.isEmpty)
                        stateMessage(
                          icon: Icons.manage_search_rounded,
                          title: 'Data tidak ditemukan',
                          message:
                              'Coba ubah filter, tanggal, status, atau kata kunci pencarian.',
                          action: OutlinedButton.icon(
                            onPressed: resetFilters,
                            icon: const Icon(Icons.filter_alt_off_rounded),
                            label: const Text('Reset Filter'),
                          ),
                        )
                      else
                        ...rows.map(historyCard),
                    ],
                  ),
                ),
    );
  }

  Widget headerCard(int filteredTotal) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.18),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Absensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$filteredTotal ditampilkan dari ${data.length} riwayat',
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
              Expanded(child: statBox('Masuk', countType('masuk').toString())),
              const SizedBox(width: 8),
              Expanded(
                  child: statBox('Pulang', countType('pulang').toString())),
              const SizedBox(width: 8),
              Expanded(child: statBox('Mapel', countType('mapel').toString())),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: statBox('Hadir', countStatus('hadir').toString())),
              const SizedBox(width: 8),
              Expanded(
                  child: statBox('Telat', countStatus('telat').toString())),
              const SizedBox(width: 8),
              Expanded(child: statBox('Alfa', countStatus('alfa').toString())),
            ],
          ),
        ],
      ),
    );
  }

  Widget statBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
            value,
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
              hint: 'Cari jenis, status, tanggal, atau jam...',
              icon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 12),
          sectionLabel('Jenis Absensi'),
          chipRow(typeOptions, typeFilter, (value) {
            setState(() => typeFilter = value);
          }),
          const SizedBox(height: 10),
          sectionLabel('Status'),
          chipRow(statusOptions, statusFilter, (value) {
            setState(() => statusFilter = value);
          }),
          const SizedBox(height: 10),
          sectionLabel('Periode'),
          chipRow(periodOptions, periodFilter, (value) async {
            if (value == 'custom') {
              await pickDateRange();
              return;
            }
            setState(() {
              periodFilter = value;
              customRange = null;
            });
          }),
          if (customRange != null) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: pickDateRange,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fbff),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded, color: navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${formatDate(customRange!.start)} sampai ${formatDate(customRange!.end)}',
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: resetFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Reset Semua Filter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                side: const BorderSide(color: line),
                padding: const EdgeInsets.symmetric(vertical: 13),
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

  Widget sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: muted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget chipRow(
    List<Map<String, String>> options,
    String activeValue,
    ValueChanged<String> onSelected,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final active = activeValue == option['value'];
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
              onSelected: (_) => onSelected(option['value']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget historyCard(Map<String, dynamic> item) {
    final color = statusColor(item['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(jenisIcon(item['jenis']), color: color),
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
                        value(item['jenis']),
                        style: const TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    statusPill(item['status']),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    infoPill(Icons.calendar_today_rounded,
                        formatDate(parseDate(item['tanggal']))),
                    infoPill(Icons.schedule_rounded, value(item['jam_scan'])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget statusPill(dynamic status) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value(status).replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xfff8fbff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget stateMessage({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: navy, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action,
          ],
        ],
      ),
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: navy),
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

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: line),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff172033).withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String formatDate(dynamic input) {
    final date = input is DateTime ? input : parseDate(input);
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

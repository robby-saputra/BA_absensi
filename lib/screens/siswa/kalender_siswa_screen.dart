import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';

class KalenderSiswaScreen extends StatefulWidget {
  final int siswaId;

  const KalenderSiswaScreen({super.key, required this.siswaId});

  @override
  State<KalenderSiswaScreen> createState() => _KalenderSiswaScreenState();
}

class _KalenderSiswaScreenState extends State<KalenderSiswaScreen> {
  late int bulan;
  late int tahun;
  bool loading = true;
  List<dynamic> events = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    bulan = now.month;
    tahun = now.year;
    loadKalender();
  }

  Future<void> loadKalender() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/siswa/kalender/${widget.siswaId}?bulan=$bulan&tahun=$tahun',
        ),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        events = data['events'] ?? [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        events = [];
        loading = false;
      });
    }
  }

  void changeMonth(int diff) {
    final date = DateTime(tahun, bulan + diff, 1);
    setState(() {
      bulan = date.month;
      tahun = date.year;
    });
    loadKalender();
  }

  Color eventColor(dynamic jenis) {
    final value = (jenis ?? '').toString().toLowerCase();
    if (value == 'libur') return Colors.red;
    if (value == 'ujian') return Colors.orange;
    return Colors.blue;
  }

  String namaBulan(int value) {
    const bulanList = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return bulanList[value - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff273c75),
        elevation: 0,
        title: const Text(
          'Kalender Sekolah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadKalender,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff273c75), Color(0xff40739e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => changeMonth(-1),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.calendar_month,
                            color: Colors.white, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          '${namaBulan(bulan)} $tahun',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => changeMonth(1),
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                legend('Libur', Colors.red),
                const SizedBox(width: 10),
                legend('Ujian', Colors.orange),
                const SizedBox(width: 10),
                legend('Kegiatan', Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (events.isEmpty)
              emptyState()
            else
              ...events.map((raw) {
                final item = Map<String, dynamic>.from(raw);
                final color = eventColor(item['jenis']);
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.event, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['judul'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['tanggal_mulai']} s/d ${item['tanggal_selesai']}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              if ((item['keterangan'] ?? '')
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(item['keterangan']),
                              ],
                            ],
                          ),
                        ),
                        chip(item['jenis'], color),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget legend(String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget chip(dynamic label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        (label ?? '-').toString().toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available, color: Color(0xff273c75), size: 42),
          SizedBox(height: 10),
          Text(
            'Tidak ada agenda',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Belum ada libur, ujian, atau kegiatan pada bulan ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

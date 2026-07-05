import 'dart:async';

import 'package:flutter/material.dart';

class LiveDateTimeCard extends StatefulWidget {
  final String label;
  final String serverTime;

  const LiveDateTimeCard({
    super.key,
    this.label = 'Waktu Server',
    required this.serverTime,
  });

  @override
  State<LiveDateTimeCard> createState() => _LiveDateTimeCardState();
}

class _LiveDateTimeCardState extends State<LiveDateTimeCard> {
  DateTime? now;
  Timer? timer;

  static const days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];
  static const months = [
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
    'Desember'
  ];

  @override
  void initState() {
    super.initState();
    now = parseServerTime(widget.serverTime);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && now != null) {
        setState(() => now = now!.add(const Duration(seconds: 1)));
      }
    });
  }

  @override
  void didUpdateWidget(covariant LiveDateTimeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverTime != widget.serverTime) {
      now = parseServerTime(widget.serverTime);
    }
  }

  DateTime? parseServerTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return parsed.toUtc().add(const Duration(hours: 7));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final current = now;
    final time = current == null
        ? '--:--:--'
        : '${two(current.hour)}:${two(current.minute)}:${two(current.second)}';
    final date = current == null
        ? 'Menunggu sinkronisasi Laravel'
        : '${days[current.weekday - 1]}, ${current.day} ${months[current.month - 1]} ${current.year}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff273c75), Color(0xff3f67ad)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff273c75).withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.schedule_rounded,
                color: Colors.white, size: 29),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(time,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(date,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('WIB',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

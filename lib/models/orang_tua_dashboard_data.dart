class OrangTuaDashboardData {
  final Map<String, dynamic> raw;

  OrangTuaDashboardData(this.raw);

  Map<String, dynamic> get attendanceSummary =>
      Map<String, dynamic>.from(raw['ringkasan_kehadiran_hari_ini'] ?? {});

  Map<String, int> get monthlyStats {
    final stats = Map<String, dynamic>.from(
      raw['statistik_bulan_berjalan'] ?? {},
    );
    return {
      'hadir': intValue(stats['hadir']),
      'terlambat': intValue(stats['terlambat']),
      'izin': intValue(stats['izin']),
      'sakit': intValue(stats['sakit']),
      'alpa': intValue(stats['alpa']),
    };
  }

  List<Map<String, dynamic>> get schedules {
    return listOfMaps(raw['jadwal_hari_ini']);
  }

  List<Map<String, dynamic>> get recentActivities {
    final items = listOfMaps(raw['aktivitas_terbaru']);
    items.sort((a, b) => activityKey(b).compareTo(activityKey(a)));
    return items.take(5).toList();
  }

  List<Map<String, dynamic>> get importantNotifications {
    final items = listOfMaps(raw['notifikasi_penting']);
    if (items.isEmpty) {
      return [
        {
          'level': 'safe',
          'pesan': 'Tidak ada pemberitahuan penting hari ini.',
        }
      ];
    }
    return items;
  }

  String get attendanceStatus {
    final status = (attendanceSummary['status'] ?? '').toString().trim();
    return status.isEmpty ? 'belum_absen' : status;
  }

  static List<Map<String, dynamic>> listOfMaps(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static int intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String activityKey(Map<String, dynamic> item) {
    return '${item['tanggal'] ?? ''} ${item['jam'] ?? ''}';
  }
}

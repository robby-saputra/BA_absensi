class JadwalMapelItem {
  final Map<String, dynamic> raw;
  final int id;
  final String namaMapel;
  final String jamMulai;
  final String jamSelesai;
  final int? jamKeMulai;
  final int? jumlahJp;
  final String? jpLabel;
  final int? guruUtamaId;
  final String guruUtama;
  final String statusGuruUtama;
  final String statusGuruUtamaLabel;
  final int? guruAktifId;
  final String? guruAktif;
  final String? roleGuruAktif;
  final String? roleGuruAktifLabel;
  final int? penggantiTerbaruId;
  final String? penggantiTerbaru;
  final int? urutanPengganti;
  final String? statusPenugasan;
  final bool butuhPengganti;
  final bool guruTersedia;
  final String keteranganGuru;
  final bool sudahAbsen;
  final String? jamScan;
  final String statusAbsen;
  final String? catatanGuru;

  JadwalMapelItem._({
    required this.raw,
    required this.id,
    required this.namaMapel,
    required this.jamMulai,
    required this.jamSelesai,
    required this.jamKeMulai,
    required this.jumlahJp,
    required this.jpLabel,
    required this.guruUtamaId,
    required this.guruUtama,
    required this.statusGuruUtama,
    required this.statusGuruUtamaLabel,
    required this.guruAktifId,
    required this.guruAktif,
    required this.roleGuruAktif,
    required this.roleGuruAktifLabel,
    required this.penggantiTerbaruId,
    required this.penggantiTerbaru,
    required this.urutanPengganti,
    required this.statusPenugasan,
    required this.butuhPengganti,
    required this.guruTersedia,
    required this.keteranganGuru,
    required this.sudahAbsen,
    required this.jamScan,
    required this.statusAbsen,
    required this.catatanGuru,
  });

  factory JadwalMapelItem.fromJson(Map<String, dynamic> json) {
    final role = stringOrNull(json['role_guru_aktif']) ??
        stringOrNull(json['peran_guru_aktif']);
    final statusPenugasan = stringOrNull(
        json['status_penugasan'] ?? json['status_penugasan_pengganti']);
    final guruAktif = stringOrNull(json['guru_aktif']) ??
        (statusPenugasan == 'aktif'
            ? stringOrNull(json['pengganti_terbaru'])
            : null);
    final guruUtama = text(json['guru_utama']);
    final statusGuruUtama =
        text(json['status_guru_utama'] ?? json['status_guru']);
    final butuhPengganti = boolValue(
      json['butuh_pengganti'] ?? json['membutuhkan_pengganti'],
    );
    final keterangan = guruAktif != null
        ? teacherDescription(
            guruAktif,
            role,
            guruUtama,
            butuhPengganti,
            statusGuruUtama,
          )
        : (stringOrNull(json['keterangan_guru']) ??
            teacherDescription(
              guruAktif,
              role,
              guruUtama,
              butuhPengganti,
              statusGuruUtama,
            ));

    return JadwalMapelItem._(
      raw: json,
      id: intValue(json['id']) ?? 0,
      namaMapel: text(json['nama_mapel']),
      jamMulai: text(json['jam_mulai']),
      jamSelesai: text(json['jam_selesai']),
      jamKeMulai: intValue(json['jam_ke_mulai']),
      jumlahJp: intValue(json['jumlah_jp']),
      jpLabel: stringOrNull(json['jp_label']),
      guruUtamaId: intValue(json['guru_utama_id']),
      guruUtama: guruUtama,
      statusGuruUtama: statusGuruUtama,
      statusGuruUtamaLabel:
          text(json['status_guru_utama_label'] ?? json['status_guru_utama']),
      guruAktifId: intValue(json['guru_aktif_id']),
      guruAktif: guruAktif,
      roleGuruAktif: role,
      roleGuruAktifLabel: stringOrNull(json['role_guru_aktif_label']),
      penggantiTerbaruId: intValue(json['pengganti_terbaru_id']),
      penggantiTerbaru: stringOrNull(json['pengganti_terbaru']),
      urutanPengganti: intValue(json['urutan_pengganti']),
      statusPenugasan: statusPenugasan,
      butuhPengganti: butuhPengganti,
      guruTersedia: boolValue(json['guru_tersedia'] ?? (guruAktif != null)),
      keteranganGuru: keterangan,
      sudahAbsen: boolValue(json['sudah_absen']),
      jamScan: stringOrNull(json['jam_scan']),
      statusAbsen: text(json['status_absen']),
      catatanGuru: stringOrNull(json['catatan_guru']),
    );
  }

  String get timeLabel => '$jamMulai - $jamSelesai';

  String get jpTimeLabel {
    if (jpLabel == null || jpLabel!.trim().isEmpty) return timeLabel;
    return '$jpLabel | $timeLabel';
  }

  String get attendanceBadge => sudahAbsen ? 'Sudah' : 'Belum';

  bool get isPenggantiAktif => (roleGuruAktif ?? '').contains('pengganti');

  String get guruLine {
    if (keteranganGuru.trim().isNotEmpty && keteranganGuru != '-') {
      return keteranganGuru;
    }
    return teacherDescription(
      guruAktif,
      roleGuruAktif,
      guruUtama,
      butuhPengganti,
      statusGuruUtama,
    );
  }

  static String text(dynamic value) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? '-' : result;
  }

  static String? stringOrNull(dynamic value) {
    final result = (value ?? '').toString().trim();
    if (result.isEmpty || result == '-') return null;
    return result;
  }

  static int? intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }

  static bool boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = (value ?? '').toString().toLowerCase().trim();
    return ['1', 'true', 'yes', 'ya', 'sudah'].contains(text);
  }

  static String teacherDescription(
    String? guruAktif,
    String? role,
    String guruUtama,
    bool butuhPengganti,
    String statusGuruUtama,
  ) {
    if (guruAktif != null) return 'Guru bertugas: $guruAktif';
    if (butuhPengganti) return 'Guru bertugas belum ditentukan';
    if (['sakit', 'izin', 'inval', 'digantikan', 'tidak_hadir']
        .contains(statusGuruUtama.toLowerCase())) {
      return 'Guru bertugas belum ditentukan';
    }
    return guruUtama == '-'
        ? 'Guru bertugas belum ditentukan'
        : 'Guru bertugas: $guruUtama';
  }
}

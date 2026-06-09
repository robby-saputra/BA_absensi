import 'package:flutter/material.dart';

class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff273c75),
        elevation: 0,
        title: const Text(
          'Bantuan Penggunaan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          heroCard(),
          const SizedBox(height: 16),
          helpCard(
            icon: Icons.login,
            color: Colors.green,
            title: 'Login Aplikasi',
            items: const [
              'Aplikasi Android hanya untuk siswa dan orang tua.',
              'Siswa login memakai username/NIS dan password dari sekolah.',
              'Orang tua login memakai akun atau nomor orang tua yang didaftarkan sekolah.',
              'Akun admin, guru, guru piket, dan wali kelas digunakan melalui website.',
            ],
          ),
          helpCard(
            icon: Icons.qr_code_scanner,
            color: Colors.blue,
            title: 'Scan QR Absensi',
            items: const [
              'Pilih Absen Masuk atau Absen Pulang untuk QR harian dari guru piket.',
              'Pilih Absensi Mapel untuk QR sesi mata pelajaran dari guru.',
              'Pastikan kamera jelas dan QR masih aktif.',
              'Dashboard akan diperbarui otomatis setelah scan berhasil.',
            ],
          ),
          helpCard(
            icon: Icons.location_on,
            color: Colors.orange,
            title: 'Lokasi dan GPS',
            items: const [
              'Aktifkan GPS/lokasi sebelum scan QR.',
              'Izinkan aplikasi mengakses lokasi perangkat.',
              'Absensi hanya diproses jika lokasi berada dalam radius sekolah.',
              'Jika lokasi gagal, tunggu beberapa saat lalu coba scan lagi.',
            ],
          ),
          helpCard(
            icon: Icons.description,
            color: Colors.redAccent,
            title: 'Izin atau Sakit',
            items: const [
              'Siswa dapat mengirim pengajuan izin atau sakit dari menu Izin / Sakit.',
              'Isi tanggal, jenis pengajuan, alasan, dan bukti jika diminta.',
              'Status pengajuan dapat dipantau dari dashboard atau riwayat.',
              'Jika data belum berubah, tunggu verifikasi pihak sekolah.',
            ],
          ),
          helpCard(
            icon: Icons.family_restroom,
            color: Colors.purple,
            title: 'Untuk Orang Tua',
            items: const [
              'Dashboard orang tua menampilkan monitoring kehadiran anak.',
              'Orang tua dapat melihat riwayat absensi dan kalender sekolah.',
              'Notifikasi kehadiran akan diterima jika fitur notifikasi aktif.',
              'Jika data anak tidak muncul, hubungi admin sekolah.',
            ],
          ),
          helpCard(
            icon: Icons.wifi_off,
            color: Colors.teal,
            title: 'Kendala Umum',
            items: const [
              'Jika login gagal, periksa username dan password.',
              'Jika koneksi bermasalah, pastikan internet aktif dan server sekolah berjalan.',
              'Jika QR tidak valid, minta guru membuat QR baru.',
              'Jika data absensi salah setelah jam kunci, hubungi admin sekolah.',
            ],
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff273c75).withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.help_outline, color: Colors.white, size: 36),
          SizedBox(height: 12),
          Text(
            'Panduan BAbsensi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gunakan panduan ini saat login, scan QR, mengirim izin/sakit, atau memantau absensi anak.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget helpCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe5eaf3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff273c75),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xff344054),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class KartuPelajarScreen extends StatelessWidget {
  final Map<String, dynamic> siswa;
  final Map<String, dynamic> kartu;

  const KartuPelajarScreen({
    super.key,
    required this.siswa,
    required this.kartu,
  });

  String value(dynamic data) {
    final text = (data ?? '').toString();
    return text.trim().isEmpty ? '-' : text;
  }

  @override
  Widget build(BuildContext context) {
    final kode = value(kartu['kode']);
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff273c75),
        elevation: 0,
        title: const Text(
          'Kartu Pelajar Digital',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, progress, child) => Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 26 * (1 - progress)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff273c75), Color(0xff40739e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff273c75).withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      logo(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value(kartu['nama_sekolah']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Kartu Pelajar Digital',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: QrImageView(
                      data: kode,
                      version: QrVersions.auto,
                      size: 190,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    value(siswa['nama']),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${value(siswa['kelas'])} - ${value(siswa['jurusan'])}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  row('NIS', siswa['nis']),
                  row('Username', siswa['username']),
                  row('Wali Kelas', siswa['wali_kelas']),
                  row('Status Akun', siswa['status_akun']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xff273c75)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kode kartu: $kode. Gunakan kartu ini sebagai identitas digital siswa.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget logo() {
    final logoUrl = value(kartu['logo_url']);
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: logoUrl == '-'
          ? const Icon(Icons.school, color: Color(0xff273c75))
          : Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.school, color: Color(0xff273c75)),
            ),
    );
  }

  Widget row(String label, dynamic data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              value(data),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

# Panduan BAbsensi Android

## Login

- Siswa masuk menggunakan akun/NIS yang diberikan sekolah.
- Orang tua masuk menggunakan nomor orang tua dan pasangan kredensial yang ditentukan sistem.
- Jika muncul “Token tidak ditemukan”, keluar lalu login kembali dan pastikan URL API benar.

## Dashboard Siswa

Dashboard menampilkan status masuk/pulang, jumlah mapel yang sudah dan belum diabsen, jadwal hari ini, JP, agenda sekolah, serta notifikasi. Data dapat diperbarui dengan tarik layar ke bawah.

## Scan Absensi Harian

1. Aktifkan GPS dan izinkan kamera serta lokasi.
2. Pilih **Scan Absensi Harian**.
3. Arahkan kamera ke QR masuk atau pulang dari guru piket aktif.
4. Tunggu pesan berhasil sebelum menutup halaman.

QR ditolak jika kedaluwarsa, dinonaktifkan karena pergantian petugas, berada di luar radius, dipindai pada hari libur, atau sudah pernah digunakan untuk jenis absensi yang sama.

## Scan Absensi Mapel

1. Pastikan sesi mapel/JP sedang aktif.
2. Pilih **Scan Absensi Mapel**.
3. Scan QR dari guru utama atau guru pengganti yang sedang bertugas.
4. Status hadir/terlambat ditentukan backend berdasarkan jadwal JP dan toleransi sekolah.

## Kalender Sekolah

Gunakan tombol kiri/kanan untuk berpindah bulan. Daftar hanya menampilkan **Libur**, **Ujian**, dan **Kegiatan** yang berlangsung pada bulan terpilih. Event bulan lain tidak dicampurkan.

## Pengajuan Izin atau Sakit

Isi jenis pengajuan, tanggal mulai/selesai, alasan, dan bukti jika diperlukan. Status menunggu, disetujui, atau ditolak dapat dilihat kembali dari aplikasi.

## Dashboard Orang Tua

Orang tua dapat melihat status kehadiran anak, riwayat, agenda sekolah, dan pengajuan izin. Notifikasi dikirim ketika anak melakukan absensi serta saat ada pengingat mapel atau absen pulang.

## Notifikasi

- Saat mapel berlangsung: informasi mapel, JP, dan waktu sesi.
- Pukul 14.00: **Waktunya Absen Pulang**.
- Hasil absensi masuk, mapel, dan pulang.

Pastikan izin notifikasi aktif dan penghemat baterai tidak membatasi aplikasi.

## Penyelesaian Masalah

- **Tidak terhubung:** pastikan server Laravel hidup, IP API benar, dan perangkat satu jaringan.
- **Lokasi ditolak:** aktifkan GPS presisi dan berada dalam radius sekolah.
- **QR tidak valid:** minta guru membuat QR terbaru.
- **Data belum berubah:** tarik dashboard untuk refresh.
- **Tampilan meluap:** gunakan versi terbaru lalu restart penuh, bukan hanya hot reload.

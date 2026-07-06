# BAbsensi Mobile

Aplikasi Android Flutter untuk siswa dan orang tua yang terhubung ke backend **Absensi QR Bhakti Anindya**. Aplikasi menyediakan scan QR absensi harian dan mata pelajaran, monitoring kehadiran, kalender sekolah, pengajuan izin, serta notifikasi Firebase.

## Pengguna

- **Siswa:** scan masuk, pulang, dan mapel; melihat dashboard, jadwal JP, riwayat, nilai, kalender, serta pengajuan izin/sakit.
- **Orang tua:** memantau absensi anak, riwayat, kalender sekolah, status izin, dan menerima notifikasi kehadiran.
- Akun admin, guru, guru piket, dan wali kelas menggunakan website.

## Fitur Utama

- Login API menggunakan token akses sesuai konteks siswa/orang tua.
- Scan QR masuk dan pulang dengan validasi GPS, radius sekolah, tanggal, masa aktif QR, dan status QR.
- Scan QR mapel berdasarkan kelas, jadwal, dan sesi **Jam Pelajaran (JP)**.
- Dashboard siswa dan orang tua dengan status absensi terbaru.
- Jadwal hari ini beserta mapel, guru, waktu, dan JP.
- Riwayat absensi harian dan mapel.
- Kalender yang hanya menampilkan libur, ujian, dan kegiatan pada bulan terpilih.
- Pengajuan izin/sakit beserta unggahan bukti.
- FCM untuk siswa dan orang tua, termasuk pengingat mapel aktif dan “Waktunya Absen Pulang” pukul 14.00.
- Notifikasi foreground melalui kanal `absensi_sekolah`.

## Persyaratan

- Flutter SDK dengan Dart `>=3.3.0 <4.0.0`
- Android SDK
- Perangkat/emulator Android
- Backend Laravel Absensi QR yang dapat diakses perangkat
- Firebase project dan `google-services.json`

## Konfigurasi API

Sesuaikan base URL pada:

- `lib/config/api.dart`
- `lib/models/config/api.dart`

Contoh perangkat fisik:

```dart
const baseUrl = 'http://192.168.1.14:8000/api';
```

HP dan komputer harus berada pada jaringan yang sama. Emulator Android dapat memakai `http://10.0.2.2:8000/api`.

## Menjalankan Aplikasi

```bash
flutter pub get
flutter run
```

Pemeriksaan source:

```bash
dart format lib
flutter analyze
flutter test
```

Build APK:

```bash
flutter build apk --release
```

## Izin Android

Aplikasi membutuhkan kamera, lokasi, internet, dan notifikasi. GPS wajib aktif ketika scan. Backend tetap menjadi sumber validasi utama sehingga manipulasi waktu, user ID, lokasi, atau QR dari aplikasi akan ditolak.

## Alur Singkat

1. Login sebagai siswa atau orang tua.
2. Aplikasi menyimpan token login secara lokal dan mendaftarkan token FCM perangkat.
3. Siswa memilih scan harian atau scan mapel.
4. Aplikasi mengirim token QR, identitas dari token login, dan koordinat GPS.
5. Backend memvalidasi QR, jadwal, JP, kelas, radius, hari libur, dan duplikasi.
6. Dashboard serta riwayat diperbarui dari data backend.

Panduan penggunaan lengkap tersedia di [PANDUAN_APLIKASI.md](PANDUAN_APLIKASI.md).

## Repository Backend

Website dan API Laravel: [robby-saputra/absensi-qr](https://github.com/robby-saputra/absensi-qr)

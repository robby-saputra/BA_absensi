# AbsensiBA Mobile

AbsensiBA Mobile adalah aplikasi Android berbasis Flutter untuk siswa dan orang tua. Aplikasi ini terhubung dengan backend Laravel Absensi QR dan digunakan untuk scan QR absensi, melihat jadwal pelajaran, memantau riwayat kehadiran, mengirim pengajuan izin/sakit, serta menerima notifikasi sekolah.

Repository ini berisi source code aplikasi mobile. Backend website dan API berada pada repository Laravel terpisah.

## Repository

- Aplikasi mobile Flutter: `https://github.com/robby-saputra/BA_absensi`
- Website dan API Laravel: `https://github.com/robby-saputra/absensi-qr`
- Branch utama pengembangan/rilis: `final`
- Package Android production: `id.my.baabsensi`
- Version saat ini: `1.0.0+3`

## Teknologi

- Flutter
- Dart `>=3.3.0 <4.0.0`
- Android SDK
- Firebase Core
- Firebase Cloud Messaging
- Local notification
- Mobile scanner untuk QR
- Geolocator untuk validasi lokasi
- Shared preferences untuk penyimpanan token lokal

## Pengguna Aplikasi

Aplikasi ini dipakai oleh:

- Siswa
- Orang tua

Role admin, guru, guru piket, dan wali kelas menggunakan website Laravel.

## Tujuan Aplikasi

Aplikasi mobile dibuat agar siswa dapat melakukan absensi langsung dari HP melalui QR Code, sedangkan orang tua dapat memantau status kehadiran anak dari dashboard. Semua validasi penting tetap dilakukan oleh backend Laravel agar data absensi tidak hanya bergantung pada aplikasi.

## Fitur Siswa

- Login siswa menggunakan akun dari backend.
- Dashboard siswa dengan ringkasan absensi.
- Jadwal Pelajaran Hari Ini.
- Informasi guru aktif atau guru pengganti sesuai data backend.
- Status jadwal yang sedang berlangsung.
- Scan QR absensi masuk dan pulang.
- Scan QR absensi mata pelajaran.
- Validasi izin kamera dan lokasi sebelum scan.
- Riwayat absensi harian dan mapel.
- Kalender sekolah.
- Pengajuan izin/sakit dengan bukti pendukung.
- Notifikasi Firebase untuk informasi absensi dan mapel.

## Fitur Orang Tua

- Login orang tua menggunakan akun dari backend.
- Dashboard orang tua untuk memantau anak.
- Statistik bulan berjalan: Hadir, Terlambat, Izin, Sakit, dan Alpa.
- Riwayat kehadiran anak.
- Kalender sekolah.
- Status absensi terbaru.
- Notifikasi kehadiran anak melalui Firebase Cloud Messaging.

## Integrasi Dengan Backend

Aplikasi mengambil data dari API Laravel. Untuk production, base URL berada pada:

```text
https://baabsensi.my.id/api
```

File konfigurasi API:

```text
lib/config/api.dart
lib/models/config/api.dart
```

Backend tetap menjadi sumber validasi utama untuk:

- Token login
- Token QR
- Tanggal dan jam scan
- Jadwal pelajaran
- Jam Pelajaran (JP)
- Kelas siswa
- Guru aktif dan guru pengganti
- Lokasi GPS
- Radius sekolah
- Duplikasi absensi
- Hari libur atau kegiatan sekolah

## Alur Login

1. User membuka aplikasi.
2. User login sebagai siswa atau orang tua.
3. Aplikasi menerima token dari API.
4. Token disimpan secara lokal.
5. Aplikasi mendaftarkan token Firebase jika tersedia.
6. User diarahkan ke dashboard sesuai role.

## Alur Scan Absensi Harian

1. Guru piket membuat QR masuk atau pulang dari website.
2. Siswa membuka menu scan harian.
3. Aplikasi meminta akses kamera dan lokasi.
4. Siswa scan QR.
5. Aplikasi mengirim token QR dan koordinat GPS ke API.
6. Backend memvalidasi QR, waktu aktif, lokasi, radius, dan data siswa.
7. Jika valid, absensi tersimpan dan dashboard diperbarui.

## Alur Scan Absensi Mapel

1. Guru mapel atau guru pengganti aktif memulai sesi mapel dari website.
2. Guru menampilkan QR mapel.
3. Siswa membuka menu scan mapel.
4. Aplikasi mengirim token QR dan lokasi ke API.
5. Backend memvalidasi jadwal, JP, kelas, guru aktif, sesi mapel, QR, dan lokasi.
6. Jika valid, absensi mapel tersimpan.

## Guru Aktif dan Guru Pengganti

Aplikasi menampilkan guru bertugas berdasarkan payload dari backend. Urutan utama tampilan guru adalah:

1. `guru_aktif`
2. fallback payload lama jika tersedia
3. teks belum ditentukan hanya ketika backend menyatakan guru aktif belum tersedia dan jadwal membutuhkan pengganti

Aplikasi tidak mengganti guru aktif dengan guru utama ketika guru utama sedang sakit/izin. Jika backend menyatakan guru pengganti aktif, nama pengganti tersebut yang ditampilkan.

## Firebase dan Package Android

Package Android production:

```text
id.my.baabsensi
```

File Firebase:

```text
android/app/google-services.json
```

File tersebut harus memiliki client Android untuk package `id.my.baabsensi`.

## Keamanan Release

File berikut tidak boleh di-commit:

- `android/key.properties`
- file `.jks`
- file `.keystore`
- folder `build`
- folder `release`
- APK hasil build
- password atau credential apa pun

APK release ditandatangani menggunakan release keystore lokal. APK distribusi sebaiknya diunggah sebagai GitHub Release Asset atau ke hosting, bukan sebagai file commit.

## Instalasi Lokal

```bash
git clone https://github.com/robby-saputra/BA_absensi.git
cd BA_absensi
flutter pub get
flutter run
```

## Perintah Pengembangan

Format source:

```bash
dart format lib test
```

Analisis source:

```bash
flutter analyze
```

Jalankan test:

```bash
flutter test
```

Build APK release:

```bash
flutter build apk --release
```

Output default build release:

```text
build/app/outputs/flutter-apk/app-release.apk
```

File distribusi lokal yang biasa digunakan:

```text
release/absensi-ba.apk
```

## Test Yang Dicakup

Test widget dan model mencakup beberapa bagian penting:

- Tampilan login.
- Kartu Jadwal Pelajaran Hari Ini.
- Badge absensi `Sudah` dan `Belum`.
- Label jadwal `Sedang Berlangsung`.
- Teks terakhir diperbarui setelah fetch dashboard.
- Layout dashboard orang tua agar tidak overflow pada layar kecil.
- Parsing guru aktif, guru utama, dan guru pengganti.
- Kondisi guru utama sakit dengan pengganti aktif.

## Izin Android

Aplikasi membutuhkan izin:

- Internet
- Kamera
- Lokasi
- Notifikasi

GPS wajib aktif ketika melakukan scan QR karena backend memvalidasi lokasi siswa terhadap radius sekolah.

## Rilis APK

Rilis resmi pertama memakai:

```text
versionName: 1.0.0
versionCode: 3
package: id.my.baabsensi
```

Tag GitHub Release yang digunakan:

```text
v1.0.0-build3
```

Asset APK:

```text
absensi-ba.apk
```

## Troubleshooting

Aplikasi tidak bisa login:

- Pastikan koneksi internet aktif.
- Pastikan API production dapat diakses.
- Pastikan akun siswa/orang tua benar.
- Pastikan backend Laravel berjalan normal.

Scan QR gagal:

- Pastikan kamera diberi izin.
- Pastikan lokasi/GPS aktif.
- Pastikan siswa berada dalam radius sekolah.
- Pastikan QR belum kedaluwarsa.
- Pastikan jadwal atau sesi mapel sedang aktif.

Notifikasi tidak muncul:

- Pastikan izin notifikasi aktif.
- Pastikan Firebase client sesuai package `id.my.baabsensi`.
- Pastikan token FCM berhasil dikirim ke backend.

## Panduan Tambahan

Panduan penggunaan aplikasi tersedia di:

```text
PANDUAN_APLIKASI.md
```

## Lisensi dan Kegunaan

Project ini dibuat untuk kebutuhan sistem absensi sekolah dan penyusunan skripsi. Aplikasi dapat dikembangkan lebih lanjut mengikuti kebutuhan sekolah.

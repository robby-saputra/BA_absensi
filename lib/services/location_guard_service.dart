import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationGuardResult {
  const LocationGuardResult({
    required this.allowed,
    required this.message,
    this.distanceInMeters,
    this.latitude,
    this.longitude,
    this.accuracyInMeters,
  });

  final bool allowed;
  final String message;
  final double? distanceInMeters;
  final double? latitude;
  final double? longitude;
  final double? accuracyInMeters;
}

class LocationGuardService {
  static const double schoolLatitude = -6.172564;
  static const double schoolLongitude = 106.627565;
  static const double allowedRadiusMeters = 300;

  static Future<LocationGuardResult> ensureInsideSchoolArea() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationGuardResult(
        allowed: false,
        message: 'GPS belum aktif. Aktifkan lokasi/GPS sebelum scan absensi.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationGuardResult(
        allowed: false,
        message:
            'Izin lokasi ditolak. Izinkan akses lokasi agar bisa scan absensi.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationGuardResult(
        allowed: false,
        message:
            'Izin lokasi diblokir permanen. Buka pengaturan aplikasi lalu izinkan lokasi.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      final distance = Geolocator.distanceBetween(
        schoolLatitude,
        schoolLongitude,
        position.latitude,
        position.longitude,
      );

      if (distance <= allowedRadiusMeters) {
        return LocationGuardResult(
          allowed: true,
          distanceInMeters: distance,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyInMeters: position.accuracy,
          message:
              'Lokasi valid. Jarak dari sekolah sekitar ${distance.round()} meter.',
        );
      }

      return LocationGuardResult(
        allowed: false,
        distanceInMeters: distance,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyInMeters: position.accuracy,
        message:
            'Anda berada sekitar ${distance.round()} meter dari sekolah. Scan hanya bisa dilakukan dalam radius ${allowedRadiusMeters.round()} meter dari SMK Bhakti Anindya.',
      );
    } on TimeoutException {
      return const LocationGuardResult(
        allowed: false,
        message:
            'Lokasi belum terbaca. Coba lagi di area terbuka atau pastikan GPS aktif.',
      );
    } catch (e) {
      return LocationGuardResult(
        allowed: false,
        message: 'Gagal membaca lokasi: $e',
      );
    }
  }
}

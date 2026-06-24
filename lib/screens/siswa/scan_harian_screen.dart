import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../config/api.dart';
import '../../services/location_guard_service.dart';
import '../../services/storage_service.dart';

class ScanHarianScreen extends StatefulWidget {
  const ScanHarianScreen({super.key});

  @override
  State<ScanHarianScreen> createState() => _ScanHarianScreenState();
}

class _ScanHarianScreenState extends State<ScanHarianScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController scannerController = MobileScannerController();
  late final AnimationController lineController;
  late final Animation<double> lineAnimation;

  bool scanned = false;
  bool success = false;

  @override
  void initState() {
    super.initState();
    lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    lineAnimation = Tween<double>(begin: -105, end: 105).animate(
      CurvedAnimation(parent: lineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    lineController.dispose();
    super.dispose();
  }

  Future<void> scanQr(String token) async {
    await scannerController.stop();
    final userId = await StorageService.getUserId();
    final accessToken = await StorageService.getToken();

    if (userId == null || accessToken == null || accessToken.trim().isEmpty) {
      await showResultDialog(
        title: 'Sesi Login Habis',
        message: 'Silakan login ulang sebelum melakukan absensi.',
        color: Colors.red,
        icon: Icons.lock,
      );
      resetScanner();
      return;
    }

    final locationResult =
        await LocationGuardService.getCurrentLocationForScan();
    if (!mounted) return;
    if (!locationResult.allowed) {
      await showResultDialog(
        title: 'Lokasi Belum Siap',
        message: locationResult.message,
        color: Colors.orange,
        icon: Icons.location_off,
      );
      resetScanner();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scan-absensi'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
        body: {
          'user_id': userId.toString(),
          'token': token,
          'latitude': locationResult.latitude.toString(),
          'longitude': locationResult.longitude.toString(),
          'location_accuracy': locationResult.accuracyInMeters.toString(),
        },
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data['status'] == 'success') {
        setState(() => success = true);
        showSuccessDialog(data['message'] ?? 'Absensi berhasil');
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context, true);
        return;
      }

      await showResultDialog(
        title: 'Absensi Gagal',
        message: data['message'] ?? 'QR tidak bisa diproses.',
        color: Colors.red,
        icon: Icons.error,
      );
      resetScanner();
    } catch (e) {
      if (!mounted) return;
      await showResultDialog(
        title: 'Koneksi Bermasalah',
        message: e.toString(),
        color: Colors.red,
        icon: Icons.wifi_off,
      );
      resetScanner();
    }
  }

  void resetScanner() {
    if (!mounted) return;
    setState(() => scanned = false);
    scannerController.start();
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Absensi Berhasil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff273c75).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xff273c75)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Dashboard akan diperbarui otomatis.'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showResultDialog({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff273c75),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> handleDetect(BarcodeCapture capture) async {
    if (scanned) return;
    final token =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    setState(() => scanned = true);

    if (token == null || token.trim().isEmpty) {
      await scannerController.stop();
      await showResultDialog(
        title: 'QR Tidak Terbaca',
        message: 'Arahkan kamera lebih dekat ke QR absensi.',
        color: Colors.red,
        icon: Icons.qr_code_2,
      );
      resetScanner();
      return;
    }

    await scanQr(token.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff273c75),
        elevation: 0,
        title: const Text(
          'Scan Absensi Harian',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: handleDetect,
          ),
          Container(color: Colors.black.withValues(alpha: 0.3)),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: success ? Colors.green : Colors.white,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                AnimatedBuilder(
                  animation: lineAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, lineAnimation.value),
                      child: Container(
                        width: 220,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.8),
                              blurRadius: 12,
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 35),
                  SizedBox(height: 10),
                  Text(
                    'Arahkan kamera ke QR Code absensi masuk atau pulang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

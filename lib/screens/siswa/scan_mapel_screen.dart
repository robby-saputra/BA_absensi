import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../config/api.dart';
import '../../services/location_guard_service.dart';
import '../../services/storage_service.dart';

class ScanMapelScreen extends StatefulWidget {
  const ScanMapelScreen({super.key});

  @override
  State<ScanMapelScreen> createState() => _ScanMapelScreenState();
}

class _ScanMapelScreenState extends State<ScanMapelScreen>
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

    if (userId == null) {
      await showResultDialog(
        title: 'Sesi Login Habis',
        message: 'Silakan login ulang sebelum melakukan absensi mapel.',
        color: Colors.red,
        icon: Icons.lock,
      );
      resetScanner();
      return;
    }

    final locationResult = await LocationGuardService.getCurrentLocationForScan();
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
        Uri.parse('$baseUrl/scan-mapel'),
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
        await showResultDialog(
          title: 'Absen Mapel Berhasil',
          message: data['message'] ?? 'Absensi mapel berhasil.',
          color: Colors.green,
          icon: Icons.check_circle,
          autoClose: true,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      await showResultDialog(
        title: 'Absen Mapel Gagal',
        message: data['message'] ?? 'Absensi mapel gagal.',
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

  Future<void> showResultDialog({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    bool autoClose = false,
  }) async {
    if (!mounted) return;
    if (autoClose) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _resultDialog(title, message, color, icon),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => _resultDialog(title, message, color, icon),
    );
  }

  Widget _resultDialog(
    String title,
    String message,
    Color color,
    IconData icon,
  ) {
    return AlertDialog(
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
        message: 'Arahkan kamera lebih dekat ke QR mapel.',
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
          'Scan Absensi Mapel',
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
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.lightBlueAccent.withValues(alpha: 0.8),
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
                  Icon(Icons.school, color: Colors.white, size: 35),
                  SizedBox(height: 10),
                  Text(
                    'Scan QR sesi mata pelajaran dari guru mapel',
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

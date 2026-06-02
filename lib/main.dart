import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/auth/login_screen.dart';

import 'screens/guru/dashboard_guru.dart';
import 'screens/piket/dashboard_piket.dart';
import 'screens/wali/dashboard_wali.dart';
import 'screens/admin/dashboard_admin.dart';
import 'screens/orang_tua/dashboard_orang_tua.dart';

import 'screens/siswa/scan_harian_screen.dart';
import 'screens/siswa/scan_mapel_screen.dart';

import 'services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runFirebase();
}

Future<void> runFirebase() async {
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await FcmService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        /*
        |--------------------------------------------------------------------------
        | LOGIN
        |--------------------------------------------------------------------------
        */
        '/': (context) => const LoginScreen(),

        /*
        |--------------------------------------------------------------------------
        | DASHBOARD GURU
        |--------------------------------------------------------------------------
        */
        '/guru': (context) => const DashboardGuru(),

        /*
        |--------------------------------------------------------------------------
        | DASHBOARD PIKET
        |--------------------------------------------------------------------------
        */
        '/piket': (context) => const DashboardPiket(),

        /*
        |--------------------------------------------------------------------------
        | DASHBOARD WALI KELAS
        |--------------------------------------------------------------------------
        */
        '/wali': (context) => const DashboardWali(),

        /*
        |--------------------------------------------------------------------------
        | DASHBOARD ADMIN
        |--------------------------------------------------------------------------
        */
        '/admin': (context) => const DashboardAdmin(),
        '/orang-tua': (context) => const DashboardOrangTua(
              nama: 'Orang Tua',
              siswaId: 0,
              siswaNama: 'Siswa',
            ),

        /*
        |--------------------------------------------------------------------------
        | ABSENSI HARIAN
        |--------------------------------------------------------------------------
        */
        '/scan-harian': (context) => const ScanHarianScreen(),

        /*
        |--------------------------------------------------------------------------
        | ABSENSI MAPEL
        |--------------------------------------------------------------------------
        */
        '/scan-mapel': (context) => const ScanMapelScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../services/storage_service.dart';

import '../siswa/dashboard_siswa.dart';
import '../orang_tua/dashboard_orang_tua.dart';
import '../bantuan_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  static const webOnlyMessage =
      'Akun ini hanya dapat digunakan melalui website. Silakan login melalui dashboard web sekolah.';

  String normalizeRole(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  bool isParentRole(String role) {
    return ['orang_tua', 'orangtua', 'parent', 'wali_murid'].contains(role);
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      loading = true;
    });

    final response = await AuthService.login(
      username: username.text,
      password: password.text,
    );

    setState(() {
      loading = false;
    });

    if (response['status'] == 'success') {
      final user = Map<String, dynamic>.from(response['user'] ?? {});
      final role = normalizeRole(user['role']);

      if (role != 'siswa' && !isParentRole(role)) {
        await StorageService.logout();
        if (!mounted) return;
        await showAuthDialog(
          title: 'Akses Ditolak',
          message: webOnlyMessage,
          icon: Icons.lock_outline,
          color: Colors.orange,
        );
        return;
      }

      await StorageService.saveLogin(
        token: response['token'],
        role: role,
        nama: user['nama'],
        userId: user['id'],
        siswaId: user['siswa_id'],
      );

      /*
      |--------------------------------------------------------------------------
      | LOGIN SISWA
      |--------------------------------------------------------------------------
      */
      if (role == 'siswa') {
        await FcmService.registerDeviceToken(
          siswaId: user['id'],
          audience: 'siswa',
          deviceName: 'Android Siswa',
        );
        if (!mounted) return;
        await showAuthDialog(
          title: 'Login Berhasil',
          message:
              'Selamat datang, ${user['nama']}. Anda akan masuk ke dashboard siswa.',
          icon: Icons.check_circle,
          color: Colors.green,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardSiswa(
              nama: user['nama'],
              userId: user['id'],
            ),
          ),
        );
        return;
      }

      if (isParentRole(role)) {
        await FcmService.registerDeviceToken(
          siswaId: user['siswa_id'],
          audience: 'orang_tua',
          deviceName: 'Android Orang Tua',
        );
        if (!mounted) return;
        await showAuthDialog(
          title: 'Login Berhasil',
          message:
              'Selamat datang, ${user['nama']}. Anda akan masuk ke dashboard orang tua.',
          icon: Icons.check_circle,
          color: Colors.green,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardOrangTua(
              nama: user['nama'],
              siswaId: user['siswa_id'],
              siswaNama: user['siswa_nama'],
            ),
          ),
        );
        return;
      }
    } else {
      if (!mounted) return;
      await showAuthDialog(
        title: 'Login Gagal',
        message: (response['message'] ?? 'Username atau password tidak sesuai.')
            .toString(),
        icon: Icons.error_outline,
        color: Colors.red,
      );
    }
  }

  Future<void> showAuthDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) async {
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width.clamp(0, 420) - 44,
              margin: const EdgeInsets.symmetric(horizontal: 22),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff273c75),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xff273c75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Mengerti',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: const Color(0xff273c75).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: const Color(0xffe51d23).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 26,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 118,
                              height: 118,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xfff8fafc),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xffdbe4f0),
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/logo-ba.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'AbsensiBA',
                              style: TextStyle(
                                color: Color(0xff273c75),
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sistem Absensi QR Bhakti Anindya',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 26),
                            TextField(
                              controller: username,
                              textInputAction: TextInputAction.next,
                              decoration: inputDecoration(
                                label: 'Username / NIS / No. Orang Tua',
                                icon: Icons.person,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: password,
                              obscureText: hidePassword,
                              onSubmitted: (_) {
                                if (!loading) login();
                              },
                              decoration: inputDecoration(
                                label: 'Password',
                                icon: Icons.lock,
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      hidePassword = !hidePassword;
                                    });
                                  },
                                  icon: Icon(
                                    hidePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: const Color(0xff667085),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: loading ? null : login,
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xff273c75),
                                  disabledBackgroundColor:
                                      const Color(0xff273c75)
                                          .withValues(alpha: 0.55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login,
                                              color: Colors.white),
                                          SizedBox(width: 10),
                                          Text(
                                            'Masuk Aplikasi',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xffe5eaf3)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_user,
                                    color: Color(0xff273c75)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Akses aplikasi Android hanya untuk siswa dan orang tua.',
                                    style: TextStyle(
                                      color: Color(0xff344054),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BantuanScreen(),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xff273c75),
                                  side: const BorderSide(
                                    color: Color(0xffdbe4f0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                                icon: const Icon(Icons.help_outline),
                                label: const Text(
                                  'Bantuan Penggunaan Aplikasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xff273c75)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xfff8fafc),
      labelStyle: const TextStyle(
        color: Color(0xff667085),
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffdbe4f0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff273c75), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future saveLogin({
    required String token,
    required String role,
    required String nama,
    required int userId,
    int? siswaId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setString('nama', nama);

    await prefs.setInt('user_id', userId);
    if (siswaId != null) {
      await prefs.setInt('siswa_id', siswaId);
    } else {
      await prefs.remove('siswa_id');
    }
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt('user_id');
  }

  static Future<String?> getNama() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nama');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<int?> getSiswaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('siswa_id');
  }

  static Future logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}

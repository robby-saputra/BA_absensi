import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Login gagal'};
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }
}

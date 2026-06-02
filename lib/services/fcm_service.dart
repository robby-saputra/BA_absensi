import 'dart:convert';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final StreamController<Map<String, dynamic>>
      _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notificationTapStream =>
      _notificationTapController.stream;

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload);
          if (data is Map<String, dynamic>) {
            _notificationTapController.add(data);
          }
        } catch (_) {}
      },
    );

    const channel = AndroidNotificationChannel(
      'orang_tua_absensi',
      'Notifikasi Absensi Orang Tua',
      description: 'Notifikasi absen masuk, mapel, dan pulang siswa.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'orang_tua_absensi',
            'Notifikasi Absensi Orang Tua',
            channelDescription: 'Notifikasi absen siswa untuk orang tua.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _notificationTapController.add(Map<String, dynamic>.from(message.data));
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 450), () {
        _notificationTapController
            .add(Map<String, dynamic>.from(initialMessage.data));
      });
    }
  }

  static Future<void> registerParentToken({
    required int siswaId,
    String deviceName = 'Android',
  }) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await http.post(
      Uri.parse('$baseUrl/fcm/register-parent'),
      headers: {'Accept': 'application/json'},
      body: {
        'siswa_id': siswaId.toString(),
        'token': token,
        'device_name': deviceName,
      },
    );

    _messaging.onTokenRefresh.listen((newToken) {
      http.post(
        Uri.parse('$baseUrl/fcm/register-parent'),
        headers: {'Accept': 'application/json'},
        body: {
          'siswa_id': siswaId.toString(),
          'token': newToken,
          'device_name': deviceName,
        },
      );
    });
  }
}

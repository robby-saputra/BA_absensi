import 'package:babsensi/services/fcm_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parent audience uses register-parent endpoint', () {
    expect(FcmService.registrationUri('orang_tua').path,
        endsWith('/fcm/register-parent'));
  });

  test('student audience uses register-device endpoint', () {
    expect(FcmService.registrationUri('siswa').path,
        endsWith('/fcm/register-device'));
  });

  test('registerProvidedToken sends parent token with auth header', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response('{"status":"success"}', 200);
    });

    final result = await FcmService.registerProvidedToken(
      siswaId: 10,
      audience: 'orang_tua',
      deviceName: 'Android Orang Tua',
      fcmToken: 'firebase-token-abcdef',
      apiToken: 'api-token',
      client: client,
    );

    expect(result, isTrue);
    expect(capturedRequest.url.path, endsWith('/fcm/register-parent'));
    expect(capturedRequest.headers['Authorization'], 'Bearer api-token');
    expect(capturedRequest.bodyFields['siswa_id'], '10');
    expect(capturedRequest.bodyFields['audience'], 'orang_tua');
    expect(capturedRequest.bodyFields['token'], 'firebase-token-abcdef');
  });

  test('null token does not crash and skips registration', () async {
    final result = await FcmService.registerProvidedToken(
      siswaId: 10,
      audience: 'orang_tua',
      deviceName: 'Android Orang Tua',
      fcmToken: null,
      apiToken: 'api-token',
      client: MockClient((request) async => http.Response('{}', 500)),
    );

    expect(result, isFalse);
  });

  test('failed registration returns false', () async {
    final result = await FcmService.registerProvidedToken(
      siswaId: 10,
      audience: 'orang_tua',
      deviceName: 'Android Orang Tua',
      fcmToken: 'firebase-token-abcdef',
      apiToken: 'api-token',
      client: MockClient((request) async => http.Response('error', 403)),
    );

    expect(result, isFalse);
  });
}

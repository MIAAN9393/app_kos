import 'package:google_sign_in/google_sign_in.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/fcm_notification_service.dart';

class AuthService {
  ApiService api;
  AuthService(this.api);

  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  // =========================
  // AUTH
  // =========================

  Future<void> _simpanTokenLogin(dynamic data) async {
    final accessToken = data?['access_token'];
    final refreshToken = data?['refresh_token'];

    if (accessToken == null || '$accessToken'.isEmpty) {
      throw Exception('Token login tidak diterima dari server');
    }

    if (refreshToken == null || '$refreshToken'.isEmpty) {
      throw Exception('Refresh token tidak diterima dari server');
    }

    await api.saveToken('access_token', accessToken.toString());
    await api.saveToken('refresh_token', refreshToken.toString());
    await FcmNotificationService(api).registerDeviceToken();
  }

  String _pesanDenganOtpDev(dynamic responseData, String fallback) {
    final pesan = '${responseData?['pesan'] ?? fallback}';
    final data = responseData?['data'];
    if (data is Map && data['dev_otp'] != null) {
      return '$pesan. Kode dev: ${data['dev_otp']}';
    }
    return pesan;
  }

  Future<dynamic> register(
    String nama,
    String kontak,
    String password, {
    String channel = 'email',
  }) async {
    final res = await api.post('auth/register', {
      "nama": nama,
      if (channel == 'phone') "no_telpon": kontak else "email": kontak,
      "password": password,
      "channel": channel,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'register gagal');
    }
    return {
      ...Map<String, dynamic>.from(res['data']),
      'pesan': _pesanDenganOtpDev(res['data'], 'Registrasi berhasil'),
    };
  }

  Future<String> resendEmailVerification(String email) async {
    final res = await api.post('auth/resend-email-verification', {
      "email": email,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'Gagal mengirim kode');
    }
    return _pesanDenganOtpDev(res['data'], 'Kode verifikasi dikirim');
  }

  Future<String> resendPhoneVerification(String phone) async {
    final res = await api.post('auth/resend-phone-verification', {
      "no_telpon": phone,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'Gagal mengirim kode');
    }
    return _pesanDenganOtpDev(res['data'], 'Kode verifikasi dikirim');
  }

  Future<String> verifyEmail(String email, String code) async {
    final res = await api.post('auth/verify-email', {
      "email": email,
      "code": code,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'Verifikasi email gagal');
    }
    return res['data']['pesan'] ?? 'Email berhasil diverifikasi';
  }

  Future<String> verifyPhone(String phone, String code) async {
    final res = await api.post('auth/verify-phone', {
      "no_telpon": phone,
      "code": code,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'Verifikasi nomor HP gagal');
    }
    return res['data']['pesan'] ?? 'Nomor HP berhasil diverifikasi';
  }

  Future<String> forgotPassword(
    String kontak, {
    String channel = 'email',
  }) async {
    final res = await api.post('auth/forgot-password', {
      if (channel == 'phone') "no_telpon": kontak else "email": kontak,
      "channel": channel,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'Gagal mengirim kode reset');
    }
    return _pesanDenganOtpDev(res['data'], 'Kode reset password dikirim');
  }

  Future<String> resetPassword({
    required String kontak,
    required String code,
    required String passwordBaru,
    String channel = 'email',
  }) async {
    final res = await api.post('auth/reset-password', {
      if (channel == 'phone') "no_telpon": kontak else "email": kontak,
      "code": code,
      "password_baru": passwordBaru,
      "channel": channel,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'Reset password gagal');
    }
    return res['data']['pesan'] ?? 'Password berhasil diubah';
  }

  Future<dynamic> login(
    String identifier,
    String password, {
    String channel = 'email',
  }) async {
    final res = await api.post('auth/login', {
      "identifier": identifier,
      "password": password,
      "channel": channel,
    });

    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'Login gagal');
    }
    await _simpanTokenLogin(res['data']['data']);

    return res['data']['pesan'];
  }

  Future<dynamic> loginGoogle() async {
    if (_googleWebClientId.isEmpty) {
      throw Exception(
        'GOOGLE_CLIENT_ID Flutter belum diisi. Gunakan Web Client ID Google.',
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: _googleWebClientId,
    );

    final akun = await googleSignIn.signIn();
    if (akun == null) {
      throw Exception('Login Google dibatalkan');
    }

    final auth = await akun.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Token Google tidak diterima');
    }

    final res = await api.post('auth/google', {"idToken": idToken});

    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'Login Google gagal');
    }

    await _simpanTokenLogin(res['data']['data']);

    return res['data']['pesan'];
  }

  Future<dynamic> logout() async {
    final refreshToken = await api.getToken('refresh_token');

    try {
      await FcmNotificationService(api).unregisterDeviceToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final res = await api.post('auth/logout', {
          "refresh_token": refreshToken,
        });
        if (res['statusCode'] != 200) {
          throw Exception(res['data']['pesan'] ?? 'Logout gagal');
        }
        return res['data']['pesan'];
      }
      return 'logout berhasil';
    } finally {
      await api.clearToken('access_token');
      await api.clearToken('refresh_token');
    }
  }
}

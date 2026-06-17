import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kos_management/service/api_service.dart';

class FcmNotificationService {
  FcmNotificationService(this.api);

  final ApiService api;

  static bool _initialized = false;
  static bool _initializing = false;
  static bool _tokenRefreshListenerAttached = false;

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    if (_initializing) return false;

    _initializing = true;
    try {
      if (Firebase.apps.isEmpty) return false;
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    } finally {
      _initializing = false;
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'ios';
      default:
        return 'android';
    }
  }

  Future<void> registerDeviceToken() async {
    final ok = await _ensureInitialized();
    if (!ok) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await api.post('fcm/register-token', {
        'token': token,
        'platform': _platform,
      });

      if (!_tokenRefreshListenerAttached) {
        _tokenRefreshListenerAttached = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          if (newToken.isEmpty) return;
          try {
            await api.post('fcm/register-token', {
              'token': newToken,
              'platform': _platform,
            });
          } catch (_) {}
        });
      }
    } catch (_) {}
  }

  Future<void> unregisterDeviceToken() async {
    final ok = await _ensureInitialized();
    if (!ok) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await api.put('fcm/unregister-token', {'token': token});
    } catch (_) {}
  }
}

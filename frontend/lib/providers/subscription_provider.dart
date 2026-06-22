import 'package:flutter/foundation.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/subscription_service.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService api = SubscriptionService(ApiService());

  bool loading = false;
  bool upgrading = false;
  String? _pesanError;
  Map<String, dynamic>? data;

  String? get pesanError {
    final msg = rapikanPesan(_pesanError);
    return msg.isEmpty ? null : msg;
  }

  String? ambilPesanError() {
    final msg = rapikanPesan(_pesanError);
    _pesanError = null;
    return msg.isEmpty ? null : msg;
  }

  String get paketAktif => '${data?['paket'] ?? 'free'}'.toLowerCase();

  Map<String, dynamic> get limits {
    final raw = data?['limits'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Map<String, dynamic> get usage {
    final raw = data?['usage'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Map<String, dynamic> get features {
    final raw = data?['features'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  bool fiturAktif(String key) => features[key] == true;

  int get paketRank => switch (paketAktif) {
    'starter' => 1,
    'pro' => 2,
    _ => 0,
  };

  Future<void> ambilSubscription({bool force = false}) async {
    if (!force && data != null) return;

    try {
      _pesanError = null;
      loading = true;
      notifyListeners();
      data = await api.ambilSubscriptionSaya();
    } catch (e) {
      _pesanError = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<({String? redirectUrl, String? error})> upgrade(String paket) async {
    const paketBerbayar = {'starter', 'pro'};

    if (!paketBerbayar.contains(paket)) {
      _pesanError = 'Paket tidak valid';
      notifyListeners();
      return (redirectUrl: null, error: _pesanError);
    }

    try {
      _pesanError = null;
      upgrading = true;
      notifyListeners();
      final transaksi = await api.buatTransaksiSubscription(
        paket: paket,
      );
      return (redirectUrl: '${transaksi['redirect_url'] ?? ''}', error: null);
    } catch (e) {
      _pesanError = e.toString();
      return (redirectUrl: null, error: rapikanPesan(_pesanError));
    } finally {
      upgrading = false;
      notifyListeners();
    }
  }
}

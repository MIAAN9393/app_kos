import 'package:kos_management/service/api_service.dart';

class SubscriptionService {
  final ApiService api;

  SubscriptionService(this.api);

  Future<Map<String, dynamic>> ambilSubscriptionSaya() async {
    final res = await api.get('subscription/me');
    final data = res['data']?['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> buatTransaksiSubscription({
    required String paket,
  }) async {
    final res = await api.post('midtrans/subscription/create', {
      'paket': paket,
    });
    final data = res['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}

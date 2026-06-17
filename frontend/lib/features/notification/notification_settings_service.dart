import 'package:kos_management/service/api_service.dart';

class NotificationSettings {
  final bool notifTagihanJatuhTempo;
  final bool notifTagihanTelat;
  final bool notifTagihanOtomatis;
  final bool notifKontrakAkanBerakhir;
  final bool notifKontrakSelesai;
  final bool notifPerpanjanganOtomatis;

  const NotificationSettings({
    required this.notifTagihanJatuhTempo,
    required this.notifTagihanTelat,
    required this.notifTagihanOtomatis,
    required this.notifKontrakAkanBerakhir,
    required this.notifKontrakSelesai,
    required this.notifPerpanjanganOtomatis,
  });

  static const defaults = NotificationSettings(
    notifTagihanJatuhTempo: true,
    notifTagihanTelat: true,
    notifTagihanOtomatis: true,
    notifKontrakAkanBerakhir: true,
    notifKontrakSelesai: true,
    notifPerpanjanganOtomatis: true,
  );

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    bool flag(String key) => json[key] != false;

    return NotificationSettings(
      notifTagihanJatuhTempo: flag('notif_tagihan_jatuh_tempo'),
      notifTagihanTelat: flag('notif_tagihan_telat'),
      notifTagihanOtomatis: flag('notif_tagihan_otomatis'),
      notifKontrakAkanBerakhir: flag('notif_kontrak_akan_berakhir'),
      notifKontrakSelesai: flag('notif_kontrak_selesai'),
      notifPerpanjanganOtomatis: flag('notif_perpanjangan_otomatis'),
    );
  }

  Map<String, dynamic> toJson() => {
    'notif_tagihan_jatuh_tempo': notifTagihanJatuhTempo,
    'notif_tagihan_telat': notifTagihanTelat,
    'notif_tagihan_otomatis': notifTagihanOtomatis,
    'notif_kontrak_akan_berakhir': notifKontrakAkanBerakhir,
    'notif_kontrak_selesai': notifKontrakSelesai,
    'notif_perpanjangan_otomatis': notifPerpanjanganOtomatis,
  };

  NotificationSettings copyWith({
    bool? notifTagihanJatuhTempo,
    bool? notifTagihanTelat,
    bool? notifTagihanOtomatis,
    bool? notifKontrakAkanBerakhir,
    bool? notifKontrakSelesai,
    bool? notifPerpanjanganOtomatis,
  }) {
    return NotificationSettings(
      notifTagihanJatuhTempo:
          notifTagihanJatuhTempo ?? this.notifTagihanJatuhTempo,
      notifTagihanTelat: notifTagihanTelat ?? this.notifTagihanTelat,
      notifTagihanOtomatis: notifTagihanOtomatis ?? this.notifTagihanOtomatis,
      notifKontrakAkanBerakhir:
          notifKontrakAkanBerakhir ?? this.notifKontrakAkanBerakhir,
      notifKontrakSelesai: notifKontrakSelesai ?? this.notifKontrakSelesai,
      notifPerpanjanganOtomatis:
          notifPerpanjanganOtomatis ?? this.notifPerpanjanganOtomatis,
    );
  }
}

class NotificationSettingsService {
  final ApiService api;

  NotificationSettingsService(this.api);

  static Map<String, dynamic> _mapFrom(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<NotificationSettings> getSettings() async {
    final res = await api.get('fcm/settings');
    return NotificationSettings.fromJson(
      _mapFrom(_mapFrom(res['data'])['data']),
    );
  }

  Future<NotificationSettings> saveSettings(
    NotificationSettings settings,
  ) async {
    final res = await api.put('fcm/settings', settings.toJson());
    return NotificationSettings.fromJson(
      _mapFrom(_mapFrom(res['data'])['data']),
    );
  }
}

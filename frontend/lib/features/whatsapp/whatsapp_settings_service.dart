import 'package:kos_management/features/whatsapp/whatsapp_settings_storage.dart';
import 'package:kos_management/service/api_service.dart';

class WhatsAppMessageLog {
  final int id;
  final String tipe;
  final String noTujuan;
  final String status;
  final String? errorMessage;
  final DateTime? createdAt;

  const WhatsAppMessageLog({
    required this.id,
    required this.tipe,
    required this.noTujuan,
    required this.status,
    required this.errorMessage,
    required this.createdAt,
  });

  factory WhatsAppMessageLog.fromMap(Map<String, dynamic> map) {
    return WhatsAppMessageLog(
      id: int.tryParse('${map['id'] ?? 0}') ?? 0,
      tipe: '${map['tipe'] ?? '-'}',
      noTujuan: '${map['no_tujuan'] ?? '-'}',
      status: '${map['status'] ?? '-'}',
      errorMessage: map['error_message']?.toString(),
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
    );
  }
}

class WhatsAppSettingsService {
  final ApiService api;

  WhatsAppSettingsService(this.api);

  static Map<String, dynamic> _mapFrom(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static bool _boolFrom(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return false;
  }

  static String _pesanFrom(dynamic data, String fallback) {
    final m = _mapFrom(data);
    return '${m['pesan'] ?? m['message'] ?? fallback}';
  }

  static WhatsAppSettings _settingsFrom(dynamic raw) {
    final data = _mapFrom(raw);
    final integration = _mapFrom(data['integration']);
    final autoSend = _mapFrom(data['auto_send']);

    return WhatsAppSettings(
      phoneNumberId: '${integration['phone_number_id'] ?? ''}',
      accessToken: '',
      hasAccessToken: _boolFrom(integration['has_access_token']),
      status: '${integration['status'] ?? 'disconnected'}',
      autoSendTagihanOnCreate: _boolFrom(
        autoSend['auto_send_tagihan_on_create'],
      ),
      autoSendTagihanFromCron: _boolFrom(
        autoSend['auto_send_tagihan_from_cron'],
      ),
      autoSendTagihanReminderBeforeDue: _boolFrom(
        autoSend['auto_send_tagihan_reminder_before_due'],
      ),
      autoSendTagihanReminderOverdue: _boolFrom(
        autoSend['auto_send_tagihan_reminder_overdue'],
      ),
      autoSendPenyewaContractOnCreate: _boolFrom(
        autoSend['auto_send_penyewa_contract_on_create'],
      ),
      autoSendPenyewaContractFromCron: _boolFrom(
        autoSend['auto_send_penyewa_contract_from_cron'],
      ),
      autoSendPenyewaReminderBeforeContractEnd: _boolFrom(
        autoSend['auto_send_penyewa_reminder_before_contract_end'],
      ),
    );
  }

  Map<String, dynamic> _payloadFrom(WhatsAppSettings settings) {
    final accessToken = settings.accessToken.trim();
    return {
      'integration': {
        'phone_number_id': settings.phoneNumberId.trim(),
        if (accessToken.isNotEmpty) 'access_token': accessToken,
      },
      'auto_send': {
        'auto_send_tagihan_on_create': settings.autoSendTagihanOnCreate,
        'auto_send_tagihan_from_cron': settings.autoSendTagihanFromCron,
        'auto_send_tagihan_reminder_before_due':
            settings.autoSendTagihanReminderBeforeDue,
        'auto_send_tagihan_reminder_overdue':
            settings.autoSendTagihanReminderOverdue,
        'auto_send_penyewa_contract_on_create':
            settings.autoSendPenyewaContractOnCreate,
        'auto_send_penyewa_contract_from_cron':
            settings.autoSendPenyewaContractFromCron,
        'auto_send_penyewa_reminder_before_contract_end':
            settings.autoSendPenyewaReminderBeforeContractEnd,
      },
    };
  }

  Future<WhatsAppSettings> getSettings() async {
    final res = await api.get('whatsapp/settings');
    return _settingsFrom(_mapFrom(res['data'])['data']);
  }

  Future<WhatsAppSettings> saveSettings(WhatsAppSettings settings) async {
    final res = await api.put('whatsapp/settings', _payloadFrom(settings));
    return _settingsFrom(_mapFrom(res['data'])['data']);
  }

  Future<String> testConnection() async {
    final res = await api.post('whatsapp/test-connection', {});
    final data = _mapFrom(res['data']);
    final payload = _mapFrom(data['data']);
    return '${payload['pesan'] ?? _pesanFrom(data, 'Tes koneksi berhasil.')}';
  }

  Future<String> sendTestMessage({
    required String to,
    required String message,
  }) async {
    final res = await api.post('whatsapp/send-test-message', {
      'to': to,
      'message': message,
    });
    final data = _mapFrom(res['data']);
    final payload = _mapFrom(data['data']);
    return '${payload['pesan'] ?? _pesanFrom(data, 'Pesan test berhasil dikirim.')}';
  }

  Future<List<WhatsAppMessageLog>> getMessageLogs() async {
    final res = await api.get('whatsapp/message-logs');
    final data = _mapFrom(res['data'])['data'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map(
          (row) => WhatsAppMessageLog.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<String> sendInvoiceToWhatsApp(int tagihanId) async {
    final res = await api.post('whatsapp/tagihan/$tagihanId/send-invoice', {});
    final data = _mapFrom(res['data']);
    final payload = _mapFrom(data['data']);
    return '${payload['pesan'] ?? _pesanFrom(data, 'Invoice berhasil dikirim ke WhatsApp.')}';
  }

  Future<String> sendKontrakToWhatsApp(int kontrakId) async {
    final res = await api.post('whatsapp/kontrak/$kontrakId/send-kontrak', {});
    final data = _mapFrom(res['data']);
    final payload = _mapFrom(data['data']);
    return '${payload['pesan'] ?? _pesanFrom(data, 'Kontrak berhasil dikirim ke WhatsApp.')}';
  }
}

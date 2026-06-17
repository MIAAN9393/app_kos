class WhatsAppSettings {
  final String phoneNumberId;
  final String accessToken;
  final bool hasAccessToken;
  final String status;
  final bool autoSendTagihanOnCreate;
  final bool autoSendTagihanFromCron;
  final bool autoSendTagihanReminderBeforeDue;
  final bool autoSendTagihanReminderOverdue;
  final bool autoSendPenyewaContractOnCreate;
  final bool autoSendPenyewaContractFromCron;
  final bool autoSendPenyewaReminderBeforeContractEnd;

  const WhatsAppSettings({
    required this.phoneNumberId,
    required this.accessToken,
    required this.hasAccessToken,
    required this.status,
    required this.autoSendTagihanOnCreate,
    required this.autoSendTagihanFromCron,
    required this.autoSendTagihanReminderBeforeDue,
    required this.autoSendTagihanReminderOverdue,
    required this.autoSendPenyewaContractOnCreate,
    required this.autoSendPenyewaContractFromCron,
    required this.autoSendPenyewaReminderBeforeContractEnd,
  });

  bool get isConfigured => status == 'connected';

  bool get hasSavedIntegration =>
      phoneNumberId.trim().isNotEmpty && hasAccessToken;

  WhatsAppSettings copyWith({
    String? phoneNumberId,
    String? accessToken,
    bool? hasAccessToken,
    String? status,
    bool? autoSendTagihanOnCreate,
    bool? autoSendTagihanFromCron,
    bool? autoSendTagihanReminderBeforeDue,
    bool? autoSendTagihanReminderOverdue,
    bool? autoSendPenyewaContractOnCreate,
    bool? autoSendPenyewaContractFromCron,
    bool? autoSendPenyewaReminderBeforeContractEnd,
  }) {
    return WhatsAppSettings(
      phoneNumberId: phoneNumberId ?? this.phoneNumberId,
      accessToken: accessToken ?? this.accessToken,
      hasAccessToken: hasAccessToken ?? this.hasAccessToken,
      status: status ?? this.status,
      autoSendTagihanOnCreate:
          autoSendTagihanOnCreate ?? this.autoSendTagihanOnCreate,
      autoSendTagihanFromCron:
          autoSendTagihanFromCron ?? this.autoSendTagihanFromCron,
      autoSendTagihanReminderBeforeDue:
          autoSendTagihanReminderBeforeDue ??
          this.autoSendTagihanReminderBeforeDue,
      autoSendTagihanReminderOverdue:
          autoSendTagihanReminderOverdue ?? this.autoSendTagihanReminderOverdue,
      autoSendPenyewaContractOnCreate:
          autoSendPenyewaContractOnCreate ??
          this.autoSendPenyewaContractOnCreate,
      autoSendPenyewaContractFromCron:
          autoSendPenyewaContractFromCron ??
          this.autoSendPenyewaContractFromCron,
      autoSendPenyewaReminderBeforeContractEnd:
          autoSendPenyewaReminderBeforeContractEnd ??
          this.autoSendPenyewaReminderBeforeContractEnd,
    );
  }

  static const empty = WhatsAppSettings(
    phoneNumberId: '',
    accessToken: '',
    hasAccessToken: false,
    status: 'disconnected',
    autoSendTagihanOnCreate: false,
    autoSendTagihanFromCron: false,
    autoSendTagihanReminderBeforeDue: false,
    autoSendTagihanReminderOverdue: false,
    autoSendPenyewaContractOnCreate: false,
    autoSendPenyewaContractFromCron: false,
    autoSendPenyewaReminderBeforeContractEnd: false,
  );
}

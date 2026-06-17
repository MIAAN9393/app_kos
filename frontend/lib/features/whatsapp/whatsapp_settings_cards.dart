import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_document_action_button.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/core/widgets/app_text_field.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/whatsapp/whatsapp_deep_link_service.dart';
import 'package:kos_management/features/whatsapp/whatsapp_settings_service.dart';
import 'package:kos_management/features/whatsapp/whatsapp_settings_storage.dart';
import 'package:kos_management/service/api_service.dart';

class WhatsAppSettingsCards extends StatefulWidget {
  const WhatsAppSettingsCards({super.key});

  @override
  State<WhatsAppSettingsCards> createState() => _WhatsAppSettingsCardsState();
}

class _WhatsAppSettingsCardsState extends State<WhatsAppSettingsCards> {
  final _phoneNumberId = TextEditingController();
  final _accessToken = TextEditingController();
  final _testTo = TextEditingController();
  final _testMessage = TextEditingController(
    text: 'Halo, ini pesan test dari aplikasi Manajemen Kos.',
  );
  final _service = WhatsAppSettingsService(ApiService());
  WhatsAppSettings _settings = WhatsAppSettings.empty;
  List<WhatsAppMessageLog> _logs = const [];
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _sendingTest = false;
  bool _loadingLogs = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneNumberId.dispose();
    _accessToken.dispose();
    _testTo.dispose();
    _testMessage.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings = await _service.getSettings();
      final logs = await _service.getMessageLogs();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _logs = logs;
        _phoneNumberId.text = settings.phoneNumberId;
        _accessToken.clear();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackbar.error(context, '$error');
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final settings = _settings.copyWith(
      phoneNumberId: _phoneNumberId.text,
      accessToken: _accessToken.text,
    );
    try {
      final saved = await _service.saveSettings(settings);
      if (!mounted) return;
      setState(() {
        _settings = saved;
        _phoneNumberId.text = saved.phoneNumberId;
        _accessToken.clear();
        _saving = false;
      });
      AppSnackbar.success(context, 'Pengaturan WhatsApp disimpan.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, '$error');
    }
  }

  Future<void> _testConnection() async {
    if (_testing) return;
    setState(() => _testing = true);
    try {
      final message = await _service.testConnection();
      if (!mounted) return;
      final settings = await _service.getSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _phoneNumberId.text = settings.phoneNumberId;
        _testing = false;
      });
      AppSnackbar.success(context, message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _testing = false);
      AppSnackbar.error(context, '$error');
    }
  }

  Future<void> _sendTestMessage() async {
    if (_sendingTest) return;
    setState(() => _sendingTest = true);
    try {
      final message = await _service.sendTestMessage(
        to: _testTo.text,
        message: _testMessage.text,
      );
      final logs = await _service.getMessageLogs();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _sendingTest = false;
      });
      AppSnackbar.success(context, message);
    } catch (error) {
      final logs = await _tryLoadLogs();
      if (!mounted) return;
      setState(() {
        _logs = logs ?? _logs;
        _sendingTest = false;
      });
      AppSnackbar.error(context, '$error');
    }
  }

  Future<List<WhatsAppMessageLog>?> _tryLoadLogs() async {
    try {
      return await _service.getMessageLogs();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshLogs() async {
    if (_loadingLogs) return;
    setState(() => _loadingLogs = true);
    try {
      final logs = await _service.getMessageLogs();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loadingLogs = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingLogs = false);
      AppSnackbar.error(context, '$error');
    }
  }

  Future<void> _toggle(WhatsAppSettings settings) async {
    setState(() => _settings = settings);
    try {
      final saved = await _service.saveSettings(
        settings.copyWith(
          phoneNumberId: _phoneNumberId.text,
          accessToken: _accessToken.text,
        ),
      );
      if (!mounted) return;
      setState(() => _settings = saved);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, '$error');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(AppDesign.spaceMd),
        decoration: AppDesign.cardDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final configured = _settings.isConfigured;
    final hasSavedIntegration = _settings.hasSavedIntegration;

    return Container(
      decoration: AppDesign.cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppDesign.spaceMd,
            vertical: AppDesign.spaceXs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppDesign.spaceMd,
            0,
            AppDesign.spaceMd,
            AppDesign.spaceMd,
          ),
          leading: Icon(
            Icons.chat_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Pengaturan WhatsApp',
                  style: AppDesign.titleBold(context),
                ),
              ),
              AppStatusBadge(
                status: configured ? 'aktif' : 'pending',
                label: configured ? 'Terhubung' : 'Belum Terhubung',
              ),
            ],
          ),
          subtitle: Text(
            'Integrasi dan pengiriman otomatis',
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
          ),
          children: [
            _IntegrationSection(
              phoneNumberId: _phoneNumberId,
              accessToken: _accessToken,
              testTo: _testTo,
              testMessage: _testMessage,
              hasAccessToken: _settings.hasAccessToken,
              hasSavedIntegration: hasSavedIntegration,
              saving: _saving,
              testing: _testing,
              sendingTest: _sendingTest,
              onSave: _save,
              onTest: _testConnection,
              onSendTest: _sendTestMessage,
            ),
            const SizedBox(height: AppDesign.spaceMd),
            _AutoSendSection(settings: _settings, onChanged: _toggle),
            const SizedBox(height: AppDesign.spaceMd),
            _MessageLogsSection(
              logs: _logs,
              loading: _loadingLogs,
              onRefresh: _refreshLogs,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageLogsSection extends StatelessWidget {
  final List<WhatsAppMessageLog> logs;
  final bool loading;
  final VoidCallback onRefresh;

  const _MessageLogsSection({
    required this.logs,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final visibleLogs = logs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SubsectionTitle(
                icon: Icons.history_outlined,
                title: 'Riwayat Pengiriman WhatsApp',
                subtitle: 'Menampilkan log pengiriman terbaru.',
              ),
            ),
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: loading ? null : onRefresh,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_outlined),
            ),
          ],
        ),
        const SizedBox(height: AppDesign.spaceSm),
        if (visibleLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppDesign.spaceMd),
            decoration: BoxDecoration(
              color: AppDesign.surface,
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
              border: Border.all(color: AppDesign.border),
            ),
            child: Text(
              'Belum ada riwayat pengiriman.',
              style: AppDesign.bodyMuted(context),
            ),
          )
        else
          ...visibleLogs.map((log) => _MessageLogTile(log: log)),
      ],
    );
  }
}

class _MessageLogTile extends StatelessWidget {
  final WhatsAppMessageLog log;

  const _MessageLogTile({required this.log});

  String get _timeLabel {
    final date = log.createdAt;
    if (date == null) return '-';
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  String get _statusLabel {
    switch (log.status) {
      case 'sent':
        return 'Terkirim';
      case 'failed':
        return 'Gagal';
      case 'pending':
        return 'Pending';
      default:
        return log.status;
    }
  }

  String get _typeLabel {
    switch (log.tipe) {
      case 'test':
        return 'Test';
      case 'invoice':
        return 'Invoice';
      case 'kontrak':
        return 'Kontrak';
      case 'reminder':
        return 'Reminder';
      default:
        return log.tipe;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = log.status == 'sent'
        ? 'aktif'
        : log.status == 'failed'
        ? 'dibatalkan'
        : 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spaceSm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppDesign.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_typeLabel - ${log.noTujuan}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppStatusBadge(status: status, label: _statusLabel),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _timeLabel,
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
          ),
          if ((log.errorMessage ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              log.errorMessage!,
              style: const TextStyle(
                color: AppDesign.danger,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IntegrationSection extends StatelessWidget {
  final TextEditingController phoneNumberId;
  final TextEditingController accessToken;
  final TextEditingController testTo;
  final TextEditingController testMessage;
  final bool hasAccessToken;
  final bool hasSavedIntegration;
  final bool saving;
  final bool testing;
  final bool sendingTest;
  final VoidCallback onSave;
  final VoidCallback onTest;
  final VoidCallback onSendTest;

  const _IntegrationSection({
    required this.phoneNumberId,
    required this.accessToken,
    required this.testTo,
    required this.testMessage,
    required this.hasAccessToken,
    required this.hasSavedIntegration,
    required this.saving,
    required this.testing,
    required this.sendingTest,
    required this.onSave,
    required this.onTest,
    required this.onSendTest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SubsectionTitle(
          icon: Icons.settings_outlined,
          title: 'Integrasi',
          subtitle: 'Data disimpan di backend aplikasi.',
        ),
        const SizedBox(height: AppDesign.spaceSm),
        AppTextField(
          label: 'Phone Number ID',
          controller: phoneNumberId,
          icon: Icons.confirmation_number_outlined,
          helperText: 'Dipakai backend untuk identitas nomor WhatsApp.',
        ),
        AppTextField(
          label: 'Access Token',
          controller: accessToken,
          icon: Icons.key_outlined,
          obscure: true,
          helperText: hasAccessToken
              ? 'Access token sudah tersimpan. Isi hanya jika ingin mengganti.'
              : 'Token tidak akan ditampilkan kembali setelah disimpan.',
        ),
        Row(
          children: [
            Expanded(
              child: AppPrimaryButton(
                label: 'Simpan Integrasi',
                icon: Icons.save_outlined,
                loading: saving,
                onPressed: onSave,
              ),
            ),
            const SizedBox(width: AppDesign.spaceSm),
            Expanded(
              child: AppPrimaryButton(
                label: 'Tes Koneksi',
                icon: Icons.wifi_tethering_outlined,
                loading: testing,
                outlined: true,
                onPressed: onTest,
              ),
            ),
          ],
        ),
        if (hasSavedIntegration) ...[
          const SizedBox(height: AppDesign.spaceMd),
          const _SubsectionTitle(
            icon: Icons.send_outlined,
            title: 'Pesan Test',
            subtitle: 'Kirim pesan teks manual untuk memastikan integrasi.',
          ),
          const SizedBox(height: AppDesign.spaceSm),
          AppTextField(
            label: 'Nomor Tujuan Test',
            controller: testTo,
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            helperText: 'Gunakan format 08xxx atau 62xxx.',
          ),
          AppTextField(
            label: 'Pesan Test',
            controller: testMessage,
            icon: Icons.message_outlined,
            maxLines: 3,
          ),
          AppPrimaryButton(
            label: 'Kirim Pesan Test',
            icon: Icons.send_outlined,
            loading: sendingTest,
            outlined: true,
            onPressed: onSendTest,
          ),
        ],
      ],
    );
  }
}

class _AutoSendSection extends StatelessWidget {
  final WhatsAppSettings settings;
  final ValueChanged<WhatsAppSettings> onChanged;

  const _AutoSendSection({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SubsectionTitle(
          icon: Icons.schedule_send_outlined,
          title: 'Pengiriman Otomatis',
          subtitle: 'Fitur akan aktif setelah integrasi WhatsApp selesai.',
        ),
        const SizedBox(height: AppDesign.spaceSm),
        _SwitchGroup(
          title: 'Tagihan',
          children: [
            _switchTile(
              title: 'Kirim invoice otomatis saat tagihan dibuat',
              value: settings.autoSendTagihanOnCreate,
              onChanged: (v) =>
                  onChanged(settings.copyWith(autoSendTagihanOnCreate: v)),
            ),
            _switchTile(
              title: 'Kirim invoice otomatis dari cron',
              value: settings.autoSendTagihanFromCron,
              onChanged: (v) =>
                  onChanged(settings.copyWith(autoSendTagihanFromCron: v)),
            ),
            _switchTile(
              title: 'Kirim reminder sebelum jatuh tempo',
              value: settings.autoSendTagihanReminderBeforeDue,
              onChanged: (v) => onChanged(
                settings.copyWith(autoSendTagihanReminderBeforeDue: v),
              ),
            ),
            _switchTile(
              title: 'Kirim reminder saat telat bayar',
              value: settings.autoSendTagihanReminderOverdue,
              onChanged: (v) => onChanged(
                settings.copyWith(autoSendTagihanReminderOverdue: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesign.spaceSm),
        _SwitchGroup(
          title: 'Penyewa & Kontrak',
          children: [
            _switchTile(
              title: 'Kirim kontrak otomatis saat kontrak dibuat',
              value: settings.autoSendPenyewaContractOnCreate,
              onChanged: (v) => onChanged(
                settings.copyWith(autoSendPenyewaContractOnCreate: v),
              ),
            ),
            _switchTile(
              title: 'Kirim kontrak otomatis dari cron',
              value: settings.autoSendPenyewaContractFromCron,
              onChanged: (v) => onChanged(
                settings.copyWith(autoSendPenyewaContractFromCron: v),
              ),
            ),
            _switchTile(
              title: 'Kirim reminder sebelum kontrak selesai',
              value: settings.autoSendPenyewaReminderBeforeContractEnd,
              onChanged: (v) => onChanged(
                settings.copyWith(autoSendPenyewaReminderBeforeContractEnd: v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SubsectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SubsectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppDesign.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppDesign.titleBold(context)),
              Text(
                subtitle,
                style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SwitchGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppDesign.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppDesign.bodyMuted(context).copyWith(
              color: AppDesign.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          ...children,
        ],
      ),
    );
  }
}

class WhatsAppUnavailableActions extends StatelessWidget {
  final bool showInvoice;
  final bool showContract;

  const WhatsAppUnavailableActions({
    super.key,
    this.showInvoice = true,
    this.showContract = true,
  });

  void _show(BuildContext context) {
    AppSnackbar.info(
      context,
      'Fitur akan tersedia setelah integrasi WhatsApp selesai.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (showInvoice) {
      children.add(
        _disabledButton(
          context,
          label: 'Kirim Invoice ke WhatsApp',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }
    if (showContract) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(
        _disabledButton(
          context,
          label: 'Kirim Kontrak ke WhatsApp',
          icon: Icons.description_outlined,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _disabledButton(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return AppDocumentActionButton(
      label: label,
      icon: icon,
      onPressed: () => _show(context),
    );
  }
}

class WhatsAppNumberInfo extends StatelessWidget {
  final String? phoneNumber;
  final String? status;

  const WhatsAppNumberInfo({super.key, required this.phoneNumber, this.status});

  Future<void> _open(BuildContext context) async {
    final opened = await WhatsAppDeepLinkService.openChat(
      phoneNumber: phoneNumber,
      message: 'Halo, saya menghubungi dari aplikasi Manajemen Kos.',
    );
    if (!context.mounted) return;
    if (!opened) {
      AppSnackbar.error(
        context,
        'Nomor WhatsApp belum valid atau WhatsApp tidak bisa dibuka.',
      );
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'valid':
        return 'Valid';
      case 'tidak_valid':
        return 'Tidak Valid';
      case 'belum_tersedia':
        return 'Belum tersedia';
      default:
        return 'Belum divalidasi';
    }
  }

  String get _badgeStatus {
    switch (status) {
      case 'valid':
        return 'aktif';
      case 'tidak_valid':
        return 'dibatalkan';
      case 'belum_tersedia':
        return 'selesai';
      default:
        return 'pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = (phoneNumber ?? '').trim();
    final hasNumber = number.isNotEmpty && number != 'null';
    final label = hasNumber ? _statusLabel : 'Belum tersedia';
    final badgeStatus = hasNumber ? _badgeStatus : 'selesai';

    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppDesign.spaceSm),
              Expanded(
                child: Text('WhatsApp', style: AppDesign.titleBold(context)),
              ),
              AppStatusBadge(status: badgeStatus, label: label),
            ],
          ),
          const SizedBox(height: AppDesign.spaceSm),
          Text(
            hasNumber ? number : 'Nomor WhatsApp belum tersedia.',
            style: hasNumber
                ? const TextStyle(fontWeight: FontWeight.w700)
                : AppDesign.bodyMuted(context),
          ),
          const SizedBox(height: AppDesign.spaceSm),
          const SizedBox(height: AppDesign.spaceSm),
          AppDocumentActionButton(
            label: 'Chat WhatsApp',
            icon: Icons.chat_rounded,
            onPressed: hasNumber ? () => _open(context) : null,
          ),
        ],
      ),
    );
  }
}

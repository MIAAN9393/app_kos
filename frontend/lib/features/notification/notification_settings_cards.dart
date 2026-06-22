import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/notification/notification_settings_service.dart';
import 'package:kos_management/service/api_service.dart';

class NotificationSettingsCards extends StatefulWidget {
  const NotificationSettingsCards({super.key});

  @override
  State<NotificationSettingsCards> createState() =>
      _NotificationSettingsCardsState();
}

class _NotificationSettingsCardsState extends State<NotificationSettingsCards> {
  final _service = NotificationSettingsService(ApiService());
  NotificationSettings _settings = NotificationSettings.defaults;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _service.getSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackbar.error(context, '$error');
    }
  }

  Future<void> _toggle(NotificationSettings settings) async {
    if (_saving) return;
    final previous = _settings;
    setState(() {
      _settings = settings;
      _saving = true;
    });

    try {
      final saved = await _service.saveSettings(settings);
      if (!mounted) return;
      setState(() {
        _settings = saved;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _settings = previous;
        _saving = false;
      });
      AppSnackbar.error(context, '$error');
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

    return Container(
      decoration: AppDesign.cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
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
            Icons.notifications_active_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            'Pengaturan Notifikasi',
            style: AppDesign.titleBold(context),
          ),
          subtitle: Text(
            'Kontrol alarm tagihan dan kontrak dari cron',
            style: AppDesign.bodyMuted(context),
          ),
          children: [
            const Divider(height: 1, color: AppDesign.border),
            _SwitchRow(
              title: 'Tagihan jatuh tempo hari ini',
              subtitle: 'Ringkasan tagihan yang perlu ditagih hari ini',
              value: _settings.notifTagihanJatuhTempo,
              enabled: !_saving,
              onChanged: (value) =>
                  _toggle(_settings.copyWith(notifTagihanJatuhTempo: value)),
            ),
            _SwitchRow(
              title: 'Tagihan terlambat',
              subtitle: 'Ringkasan tagihan yang melewati jatuh tempo',
              value: _settings.notifTagihanTelat,
              enabled: !_saving,
              onChanged: (value) =>
                  _toggle(_settings.copyWith(notifTagihanTelat: value)),
            ),
            _SwitchRow(
              title: 'Tagihan otomatis',
              subtitle: 'Ringkasan berhasil atau gagal generate otomatis',
              value: _settings.notifTagihanOtomatis,
              enabled: !_saving,
              onChanged: (value) =>
                  _toggle(_settings.copyWith(notifTagihanOtomatis: value)),
            ),
            _SwitchRow(
              title: 'Kontrak akan berakhir',
              subtitle: 'Pengingat kontrak yang akan habis dalam 7 hari',
              value: _settings.notifKontrakAkanBerakhir,
              enabled: !_saving,
              onChanged: (value) =>
                  _toggle(_settings.copyWith(notifKontrakAkanBerakhir: value)),
            ),
            _SwitchRow(
              title: 'Kontrak selesai',
              subtitle: 'Kontrak yang baru ditandai selesai oleh sinkronisasi',
              value: _settings.notifKontrakSelesai,
              enabled: !_saving,
              onChanged: (value) =>
                  _toggle(_settings.copyWith(notifKontrakSelesai: value)),
            ),
            _SwitchRow(
              title: 'Perpanjangan otomatis',
              subtitle: 'Ringkasan berhasil atau gagal perpanjang kontrak',
              value: _settings.notifPerpanjanganOtomatis,
              enabled: !_saving,
              onChanged: (value) =>
                  _toggle(_settings.copyWith(notifPerpanjanganOtomatis: value)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: AppDesign.titleBold(context).copyWith(fontSize: 14),
      ),
      subtitle: Text(subtitle, style: AppDesign.bodyMuted(context)),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

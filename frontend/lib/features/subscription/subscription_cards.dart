import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/providers/subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionCards extends StatefulWidget {
  const SubscriptionCards({super.key});

  @override
  State<SubscriptionCards> createState() => _SubscriptionCardsState();
}

class _SubscriptionCardsState extends State<SubscriptionCards>
    with WidgetsBindingObserver {
  bool _menungguPembayaran = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().ambilSubscription();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _menungguPembayaran) {
      _refreshSubscriptionSetelahPembayaran();
    }
  }

  Future<void> _refreshSubscriptionSetelahPembayaran() async {
    _menungguPembayaran = false;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await context.read<SubscriptionProvider>().ambilSubscription(force: true);
  }

  Future<void> _upgrade(BuildContext context, String paket) async {
    final provider = context.read<SubscriptionProvider>();
    final result = await provider.upgrade(paket);
    if (!context.mounted) return;

    if (result.error != null && result.error!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }

    final url = result.redirectUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redirect pembayaran tidak tersedia')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka halaman pembayaran')),
      );
      return;
    }

    _menungguPembayaran = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        if (provider.loading && provider.data == null) {
          return Container(
            padding: const EdgeInsets.all(AppDesign.spaceMd),
            decoration: AppDesign.cardDecoration(),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final loadError = provider.data == null ? provider.pesanError : null;
        if (loadError != null) {
          return Container(
            padding: const EdgeInsets.all(AppDesign.spaceMd),
            decoration: AppDesign.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppDesign.warning),
                    const SizedBox(width: AppDesign.spaceSm),
                    Expanded(
                      child: Text(
                        'Gagal memuat paket',
                        style: AppDesign.titleBold(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spaceSm),
                Text(loadError, style: AppDesign.bodyMuted(context)),
                const SizedBox(height: AppDesign.spaceMd),
                OutlinedButton.icon(
                  onPressed: () => provider.ambilSubscription(force: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: AppDesign.cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            initiallyExpanded: false,
            leading: Icon(
              Icons.workspace_premium_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Paket ${_labelPaket(provider.paketAktif)}',
              style: AppDesign.titleBold(context),
            ),
            subtitle: Text(
              'Limit terpakai & upgrade paket',
              style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
            ),
            trailing: provider.loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            childrenPadding: const EdgeInsets.fromLTRB(
              AppDesign.spaceMd,
              0,
              AppDesign.spaceMd,
              AppDesign.spaceMd,
            ),
            children: [
              const Divider(height: 1, color: AppDesign.border),
              const SizedBox(height: AppDesign.spaceMd),
              if (provider.warningPesan != null) ...[
                _subscriptionWarning(context, provider.warningPesan!),
                const SizedBox(height: AppDesign.spaceMd),
              ],
              _limitRow(
                context,
                label: 'Kos',
                used: _intValue(provider.usage['kos']),
                limit: _intOrNull(provider.limits['kos']),
              ),
              _limitRow(
                context,
                label: 'Kamar',
                used: _intValue(provider.usage['kamar']),
                limit: _intOrNull(provider.limits['kamar']),
              ),
              _limitRow(
                context,
                label: 'Penyewa aktif',
                used: _intValue(provider.usage['penyewa_aktif']),
                limit: _intOrNull(provider.limits['penyewa_aktif']),
              ),
              const SizedBox(height: AppDesign.spaceSm),
              _lockedFeature(
                context,
                title: 'Tagihan otomatis',
                active: provider.fiturAktif('tagihan_otomatis'),
              ),
              _lockedFeature(
                context,
                title: 'Perpanjangan otomatis',
                active: provider.fiturAktif('perpanjangan_otomatis'),
              ),
              const SizedBox(height: AppDesign.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _upgradeButton(
                      context,
                      provider: provider,
                      paket: 'starter',
                      label: 'Starter',
                      price: 'Rp 29.000',
                    ),
                  ),
                  const SizedBox(width: AppDesign.spaceSm),
                  Expanded(
                    child: _upgradeButton(
                      context,
                      provider: provider,
                      paket: 'pro',
                      label: 'Pro',
                      price: 'Rp 49.000',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _subscriptionWarning(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesign.spaceSm),
      decoration: BoxDecoration(
        color: AppDesign.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppDesign.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            color: AppDesign.warning,
            size: 18,
          ),
          const SizedBox(width: AppDesign.spaceSm),
          Expanded(child: Text(message, style: AppDesign.bodyMuted(context))),
        ],
      ),
    );
  }

  Widget _limitRow(
    BuildContext context, {
    required String label,
    required int used,
    required int? limit,
  }) {
    final unlimited = limit == null;
    final progress = unlimited || limit <= 0
        ? 0.0
        : (used / limit).clamp(0.0, 1.0);
    final value = unlimited ? '$used / unlimited' : '$used / $limit';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppDesign.bodyMuted(context))),
              Text(value, style: AppDesign.titleBold(context)),
            ],
          ),
          const SizedBox(height: AppDesign.spaceXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: unlimited ? 1 : progress,
              backgroundColor: AppDesign.border,
              color: unlimited
                  ? AppDesign.success
                  : progress >= 0.9
                  ? AppDesign.warning
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedFeature(
    BuildContext context, {
    required String title,
    required bool active,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: AppDesign.spaceSm),
      padding: const EdgeInsets.all(AppDesign.spaceSm),
      decoration: BoxDecoration(
        color: active
            ? AppDesign.success.withValues(alpha: 0.08)
            : AppDesign.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(
          color: active
              ? AppDesign.success.withValues(alpha: 0.25)
              : AppDesign.warning.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_outline : Icons.lock_outline,
            size: 18,
            color: active ? AppDesign.success : AppDesign.warning,
          ),
          const SizedBox(width: AppDesign.spaceSm),
          Expanded(
            child: Text(
              active ? title : '$title - Upgrade untuk membuka fitur ini',
              style: AppDesign.bodyMuted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _upgradeButton(
    BuildContext context, {
    required SubscriptionProvider provider,
    required String paket,
    required String label,
    required String price,
  }) {
    final targetRank = switch (paket) {
      'starter' => 1,
      'pro' => 2,
      _ => 0,
    };
    final active = provider.paketAktif == paket;
    final canUpgrade = provider.dalamMasaTenggang
        ? targetRank >= provider.paketRank
        : targetRank > provider.paketRank;
    return FilledButton(
      onPressed: provider.upgrading || !canUpgrade
          ? null
          : () => _upgrade(context, paket),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDesign.spaceSm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              active && provider.dalamMasaTenggang
                  ? 'Perpanjang $label'
                  : active
                  ? '$label aktif'
                  : 'Upgrade $label',
            ),
            if (!active && canUpgrade)
              Text(
                price,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _intValue(dynamic value) => int.tryParse('$value') ?? 0;

  int? _intOrNull(dynamic value) {
    if (value == null) return null;
    return int.tryParse('$value');
  }

  String _labelPaket(String value) {
    if (value.isEmpty) return 'Free';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

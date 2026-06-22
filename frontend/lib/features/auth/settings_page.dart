import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/notification/notification_settings_cards.dart';
import 'package:kos_management/features/subscription/subscription_cards.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(AppDesign.spaceMd),
        children: [
          const SubscriptionCards(),
          const SizedBox(height: AppDesign.spaceSm),
          const NotificationSettingsCards(),
          const SizedBox(height: AppDesign.spaceSm),
          _tile(context, Icons.language_outlined, 'Bahasa', 'Indonesia'),
          _tile(context, Icons.info_outline_rounded, 'Versi', '1.0.0'),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spaceSm),
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      decoration: AppDesign.cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppDesign.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppDesign.titleBold(context)),
                Text(sub, style: AppDesign.bodyMuted(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

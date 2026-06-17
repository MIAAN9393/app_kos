import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_menu_tile.dart';
import 'package:kos_management/core/widgets/app_page_scaffold.dart';

class ProfileHubPage extends StatelessWidget {
  const ProfileHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Profile',
      subtitle: 'Akun pemilik kos',
      body: ListView(
        padding: const EdgeInsets.all(AppDesign.spaceMd),
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spaceLg),
            decoration: AppDesign.cardDecoration(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppDesign.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pemilik Kos', style: AppDesign.sectionTitle(context)),
                      Text(
                        'Kelola properti & penyewa',
                        style: AppDesign.bodyMuted(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesign.spaceMd),
          AppMenuTile(
            title: 'Profile User',
            subtitle: 'Data akun & logout',
            icon: Icons.badge_outlined,
            onTap: () => AppNavigation.toProfile(context),
          ),
          AppMenuTile(
            title: 'Pengaturan',
            subtitle: 'Preferensi aplikasi',
            icon: Icons.settings_outlined,
            onTap: () => AppNavigation.toSettings(context),
          ),
        ],
      ),
    );
  }
}

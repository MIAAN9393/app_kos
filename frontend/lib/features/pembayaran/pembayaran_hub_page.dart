import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_shell.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_menu_tile.dart';
import 'package:kos_management/core/widgets/app_page_scaffold.dart';
import 'package:kos_management/core/widgets/app_section_header.dart';

class PembayaranHubPage extends StatelessWidget {
  const PembayaranHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Pembayaran',
      subtitle: 'Tagihan, transaksi, dan riwayat bayar',
      body: ListView(
        padding: const EdgeInsets.all(AppDesign.spaceMd),
        children: [
          const AppSectionHeader(
            title: 'Akses cepat',
            subtitle: 'Kelola dari rantai Property atau dari sini',
          ),
          AppMenuTile(
            title: 'Property — List Kos',
            subtitle: 'Kos → Kamar → Penyewa → Tagihan → Bayar',
            icon: Icons.home_work_rounded,
            iconColor: AppDesign.info,
            onTap: () => context.switchShellTab(AppShellTabs.property),
          ),
          AppMenuTile(
            title: 'Cara mencatat pembayaran',
            subtitle: 'Buka detail tagihan → Tambah pembayaran / Refund',
            icon: Icons.receipt_long_rounded,
            iconColor: AppDesign.success,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Buka Property → Kos → Kamar → Penyewa → pilih tagihan',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDesign.spaceLg),
          const AppSectionHeader(
            title: 'API tersedia',
            subtitle: 'Provider sudah terhubung backend',
          ),
          _infoCard(
            context,
            'POST buat_pembayaran',
            'Catat pembayaran per tagihan',
            Icons.add_card_rounded,
          ),
          _infoCard(
            context,
            'PUT buat_refund_pembayaran',
            'Refund sebagian / penuh per transaksi',
            Icons.undo_rounded,
          ),
          _infoCard(
            context,
            'GET ambil_pembayaran',
            'Riwayat di detail tagihan',
            Icons.history_rounded,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spaceSm),
      child: Container(
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
      ),
    );
  }
}

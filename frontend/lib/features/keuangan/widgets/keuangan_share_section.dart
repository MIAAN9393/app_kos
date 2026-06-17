import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_menu_tile.dart';

class KeuanganShareSection extends StatelessWidget {
  final VoidCallback? onExportPdf;

  const KeuanganShareSection({super.key, this.onExportPdf});

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDesign.cardDecoration(),
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.ios_share_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppDesign.spaceSm),
              Text('Bagikan & export', style: AppDesign.titleBold(context)),
            ],
          ),
          const SizedBox(height: AppDesign.spaceMd),
          AppMenuTile(
            title: 'Bagikan Laporan PDF',
            subtitle: 'Unduh ringkasan periode ini',
            icon: Icons.picture_as_pdf_outlined,
            iconColor: AppDesign.danger,
            onTap:
                onExportPdf ??
                () => _snack(context, 'Bagikan PDF belum tersedia'),
          ),
          const SizedBox(height: AppDesign.spaceSm),
          AppMenuTile(
            title: 'Bagikan ke WhatsApp',
            subtitle: 'Kirim rekap ke grup atau penyewa',
            icon: Icons.share_rounded,
            iconColor: AppDesign.success,
            onTap: () => _snack(context, 'Share WA — coming soon (dummy)'),
          ),
          const SizedBox(height: AppDesign.spaceSm),
          AppMenuTile(
            title: 'Salin ringkasan',
            subtitle: 'Teks singkat uang masuk & sisa tagihan',
            icon: Icons.content_copy_rounded,
            iconColor: AppDesign.info,
            onTap: () => _snack(context, 'Ringkasan disalin (dummy)'),
          ),
        ],
      ),
    );
  }
}

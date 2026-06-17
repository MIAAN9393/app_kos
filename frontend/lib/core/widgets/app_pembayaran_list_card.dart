import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_entity_list_card.dart';

class AppPembayaranListCard extends StatelessWidget {
  final Map<String, dynamic> pembayaran;
  final Map<String, dynamic>? tagihan;
  final VoidCallback onTap;
  final String? konteksPenyewa;

  const AppPembayaranListCard({
    super.key,
    required this.pembayaran,
    this.tagihan,
    required this.onTap,
    this.konteksPenyewa,
  });

  @override
  Widget build(BuildContext context) {
    final jumlah = int.tryParse('${pembayaran['jumlah_bayar']}') ?? 0;
    final status = '${pembayaran['status'] ?? 'valid'}';
    final kode = tagihan?['kode_tagihan'];
    final tanggal = '${pembayaran['dibuat_pada'] ?? ''}'.split('T').first;
    final title = kode != null && '$kode'.isNotEmpty
        ? '$kode'
        : 'Tagihan #${pembayaran['tagihan_id']}';

    return AppEntityListCard(
      entityLabel: 'BAYAR',
      title: title,
      titleMaxLines: 1,
      accentColor: AppColors.icon_uang,
      placeholderIcon: Icons.payments_rounded,
      status: status == 'refund' ? 'refund' : 'valid',
      highlightText: AppDesign.formatRupiah(jumlah),
      lines: [
        if (konteksPenyewa != null && konteksPenyewa!.trim().isNotEmpty)
          AppEntityListLine(
            icon: Icons.person_outline,
            text: konteksPenyewa!.trim(),
          ),
        AppEntityListLine(
          icon: Icons.event_outlined,
          text: 'Tanggal $tanggal',
        ),
      ],
      onTap: onTap,
      canEdit: false,
      canDelete: false,
    );
  }
}

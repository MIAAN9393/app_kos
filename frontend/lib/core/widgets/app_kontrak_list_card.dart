import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_entity_list_card.dart';
import 'package:kos_management/utils/kontrak_aksi_rules.dart';
import 'package:kos_management/utils/kontrak_status.dart';
import 'package:kos_management/utils/sisa_hari.dart';

class AppKontrakListCard extends StatelessWidget {
  final Map<String, dynamic> kontrak;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AppKontrakListCard({
    super.key,
    required this.kontrak,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  static String _tanggal(dynamic v) => '${v ?? ''}'.split('T').first;

  @override
  Widget build(BuildContext context) {
    final penyewa = kontrak['penyewa'];
    final kamar = kontrak['kamar'];
    final namaPenyewa = penyewa is Map
        ? '${penyewa['nama'] ?? 'Penyewa'}'
        : 'Penyewa';
    final nomorKamar = kamar is Map ? 'Kamar ${kamar['nomor']}' : 'Kamar';
    final harga = int.tryParse('${kontrak['harga_sewa']}') ?? 0;
    final durasi = SisaHari.labelKontrak(
      kontrak['tanggal_mulai'],
      kontrak['tanggal_selesai'],
      status: kontrak['status'],
    );
    final canEdit = onEdit != null && KontrakAksiRules.bolehEdit(kontrak);
    final canDelete = onDelete != null && KontrakAksiRules.bolehHapus(kontrak);

    return AppEntityListCard(
      entityLabel: 'KONTRAK',
      title: '$namaPenyewa · $nomorKamar',
      accentColor: AppColors.icon_penyewa,
      placeholderIcon: Icons.description_rounded,
      status: KontrakStatus.normalize(kontrak['status']),
      highlightText: AppDesign.formatRupiah(harga),
      lines: [
        AppEntityListLine(
          icon: Icons.calendar_today_outlined,
          text:
              '${_tanggal(kontrak['tanggal_mulai'])} — ${_tanggal(kontrak['tanggal_selesai'])}',
        ),
        AppEntityListLine(
          icon: Icons.schedule_rounded,
          text:
              'Siklus ${kontrak['siklus'] ?? '-'}${durasi == null ? '' : ' · $durasi'}',
        ),
      ],
      onTap: onTap,
      onEdit: onEdit ?? () {},
      onDelete: onDelete ?? () {},
      canEdit: canEdit,
      canDelete: canDelete,
      editBlockedMessage: KontrakAksiRules.alasanEdit(kontrak),
      deleteBlockedMessage: KontrakAksiRules.alasanHapus(kontrak),
      titleMaxLines: 1,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/widgets/app_entity_list_card.dart';
import 'package:kos_management/utils/entity_action_rules.dart';

class AppKosCard extends StatelessWidget {
  final String nama;
  final String alamat;
  final String status;
  final int jumlahKamar;
  final int jumlahPenyewa;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool canDelete;
  final String? editBlockedMessage;
  final String? deleteBlockedMessage;

  const AppKosCard({
    super.key,
    required this.nama,
    required this.alamat,
    required this.status,
    required this.jumlahKamar,
    required this.jumlahPenyewa,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.canEdit = true,
    this.canDelete = true,
    this.editBlockedMessage,
    this.deleteBlockedMessage,
  });

  factory AppKosCard.fromData({
    required Map<String, dynamic> kos,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    int? jumlahKamar,
    int? jumlahPenyewa,
  }) {
    final k = jumlahKamar ?? int.tryParse('${kos['jumlah_kamar']}') ?? 0;
    final p = jumlahPenyewa ?? int.tryParse('${kos['jumlah_penyewa']}') ?? 0;
    return AppKosCard(
      nama: '${kos['nama_kos'] ?? ''}',
      alamat: '${kos['alamat'] ?? ''}',
      status: '${kos['status'] ?? 'aktif'}',
      jumlahKamar: k,
      jumlahPenyewa: p,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      canEdit: EntityActionRules.bolehEditKos(kos),
      canDelete: EntityActionRules.bolehHapusKos(kos),
      editBlockedMessage: EntityActionRules.pesanEditKos(kos),
      deleteBlockedMessage: EntityActionRules.pesanHapusKos(kos),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppEntityListCard(
      entityLabel: 'KOS',
      title: nama,
      accentColor: AppColors.icon_kos,
      placeholderIcon: Icons.home_work_rounded,
      status: status,
      lines: [
        AppEntityListLine(icon: Icons.location_on_outlined, text: alamat),
        AppEntityListLine(
          text: '$jumlahKamar kamar · $jumlahPenyewa penyewa',
        ),
      ],
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      canEdit: canEdit,
      canDelete: canDelete,
      editBlockedMessage: editBlockedMessage,
      deleteBlockedMessage: deleteBlockedMessage,
    );
  }
}

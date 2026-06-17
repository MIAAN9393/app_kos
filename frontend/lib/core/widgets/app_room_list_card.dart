import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_entity_list_card.dart';
import 'package:kos_management/utils/entity_action_rules.dart';

class AppRoomListCard extends StatelessWidget {
  final String nomor;
  final String harga;
  final String kapasitas;
  final String status;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool canDelete;
  final String? editBlockedMessage;
  final String? deleteBlockedMessage;

  const AppRoomListCard({
    super.key,
    required this.nomor,
    required this.harga,
    required this.kapasitas,
    required this.status,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.canEdit = true,
    this.canDelete = true,
    this.editBlockedMessage,
    this.deleteBlockedMessage,
  });

  factory AppRoomListCard.fromData({
    required Map<String, dynamic> kamar,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return AppRoomListCard(
      nomor: '${kamar['nomor']}',
      harga: '${kamar['harga']}',
      kapasitas: '${kamar['kapasitas']}',
      status: '${kamar['status_kondisi'] ?? ''}',
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      canEdit: EntityActionRules.bolehEditKamar(kamar),
      canDelete: EntityActionRules.bolehHapusKamar(kamar),
      editBlockedMessage: EntityActionRules.pesanEditKamar(kamar),
      deleteBlockedMessage: EntityActionRules.pesanHapusKamar(kamar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppEntityListCard(
      entityLabel: 'KAMAR',
      title: 'Kamar $nomor',
      accentColor: AppColors.icon_kamar,
      placeholderIcon: Icons.meeting_room_rounded,
      status: status,
      lines: [
        AppEntityListLine(
          icon: Icons.payments_outlined,
          text: AppDesign.formatRupiah(harga),
        ),
        AppEntityListLine(
          icon: Icons.people_alt_outlined,
          text: 'Kapasitas $kapasitas orang',
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

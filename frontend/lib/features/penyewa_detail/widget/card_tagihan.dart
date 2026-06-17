import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_entity_list_card.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/sisa_hari.dart';
import 'package:kos_management/utils/tagihan_rules.dart';

class CardTagihan extends StatelessWidget {
  final Map<String, dynamic> data_tagihan;
  final Function(int) tekan;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Konteks penyewa/kamar (mis. dari tab Controll): "Budi · Kamar 3".
  final String? konteksPenyewa;

  const CardTagihan({
    super.key,
    required this.data_tagihan,
    required this.tekan,
    this.onEdit,
    this.onDelete,
    this.konteksPenyewa,
  });

  static int _angka(dynamic v) => int.tryParse('$v') ?? 0;

  static String _status(Map<String, dynamic> t) => TagihanRules.badgeStatus(t);

  @override
  Widget build(BuildContext context) {
    final total = _angka(
      data_tagihan['total_tagihan'] ?? data_tagihan['harga_sewa'],
    );
    final dibayar = _angka(data_tagihan['total_dibayar']);
    final sisa = total - dibayar;
    final status = _status(data_tagihan);
    final awal = '${data_tagihan['periode_awal']}'.split('T').first;
    final akhir = '${data_tagihan['periode_akhir']}'.split('T').first;
    final kode = data_tagihan['kode_tagihan'];
    final periode = '$awal — $akhir';
    final pesanEdit = EntityActionRules.pesanEditTagihan(data_tagihan);
    final pesanHapus = EntityActionRules.pesanHapusTagihan(data_tagihan);

    final tempo = data_tagihan['jatuh_tempo'] != null
        ? ' · Tempo ${'${data_tagihan['jatuh_tempo']}'.split('T').first}'
        : '';
    final sisaTempo = SisaHari.labelJatuhTempo(
      data_tagihan['jatuh_tempo'],
      lifecycle: data_tagihan['lifecycle'],
      statusPembayaran: data_tagihan['status_pembayaran'],
    );
    final punyaKode = kode != null && '$kode'.isNotEmpty;
    final bayarSisa =
        'Dibayar ${AppDesign.formatRupiah(dibayar)} · Sisa ${AppDesign.formatRupiah(sisa)}$tempo${sisaTempo == null ? '' : ' · $sisaTempo'}';
    final lines = <AppEntityListLine>[
      if (konteksPenyewa != null && konteksPenyewa!.trim().isNotEmpty)
        AppEntityListLine(
          icon: Icons.person_outline,
          text: konteksPenyewa!.trim(),
        ),
      AppEntityListLine(
        icon: Icons.payments_outlined,
        text: punyaKode ? '$periode · $bayarSisa' : bayarSisa,
      ),
    ];

    return AppEntityListCard(
      entityLabel: 'TAGIHAN',
      titleMaxLines: 1,
      title: punyaKode ? '$kode' : periode,
      accentColor: AppColors.icon_uang,
      placeholderIcon: Icons.receipt_long_rounded,
      status: status,
      highlightText: AppDesign.formatRupiah(total),
      lines: lines,
      onTap: () {
        final id = entityId(data_tagihan['id']);
        if (id != null) tekan(id);
      },
      onEdit: onEdit,
      onDelete: onDelete,
      canEdit: EntityActionRules.bolehEditTagihan(data_tagihan),
      canDelete: EntityActionRules.bolehHapusTagihan(data_tagihan),
      editBlockedMessage: pesanEdit,
      deleteBlockedMessage: pesanHapus,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/widgets/app_entity_list_card.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/sisa_hari.dart';

/// Kartu penyewa di list — memakai layout list standar aplikasi.
class CardPenyewa extends StatelessWidget {
  final int id;
  final String nama;
  final String noTelpon;
  final String? email;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final String? statusHubungan;
  final String? tanggalSelesaiKontrak;
  final String? statusKontrak;
  final String statusSewa;
  final String? tanggalMasuk;
  final String? lokasi;
  final bool showActions;
  final VoidCallback onTap;
  final void Function(int)? onEdit;
  final void Function(int)? onDelete;
  final void Function(String)? onWa;
  final bool canEdit;
  final bool canDelete;
  final String? editBlockedMessage;
  final String? deleteBlockedMessage;

  const CardPenyewa({
    super.key,
    required this.id,
    required this.nama,
    required this.noTelpon,
    this.email,
    this.tanggalLahir,
    this.jenisKelamin,
    this.statusHubungan,
    this.tanggalSelesaiKontrak,
    this.statusKontrak,
    required this.statusSewa,
    this.tanggalMasuk,
    this.lokasi,
    this.showActions = true,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onWa,
    this.canEdit = true,
    this.canDelete = true,
    this.editBlockedMessage,
    this.deleteBlockedMessage,
  });

  factory CardPenyewa.fromData({
    required Map<String, dynamic> item,
    required Function(int) klik_card,
    required Function(int) klik_edit,
    required Function(int) klik_hapus,
    required Function(String) klik_wa,
  }) {
    final id = entityId(item['id']) ?? 0;
    final masuk =
        item['tanggal_mulai']?.toString() ??
        item['dibuat_pada']?.toString() ??
        '-';
    return CardPenyewa(
      id: id,
      nama: '${item['nama']}',
      noTelpon: '${item['no_telpon']}',
      email: item['email']?.toString(),
      tanggalLahir: item['tanggal_lahir']?.toString(),
      jenisKelamin: item['jenis_kelamin']?.toString(),
      statusHubungan: item['status_hubungan']?.toString(),
      tanggalSelesaiKontrak: item['tanggal_selesai']?.toString(),
      statusKontrak: item['status_kontrak']?.toString(),
      statusSewa: '${item['status'] ?? 'aktif'}',
      tanggalMasuk: masuk.split('T').first,
      onTap: () => klik_card(id),
      onEdit: klik_edit,
      onDelete: klik_hapus,
      onWa: klik_wa,
      canEdit: EntityActionRules.bolehEditPenyewa(item),
      canDelete: EntityActionRules.bolehHapusPenyewa(item),
      editBlockedMessage: EntityActionRules.pesanEditPenyewa(item),
      deleteBlockedMessage: EntityActionRules.pesanHapusPenyewa(item),
    );
  }

  /// Kartu baca saja di detail tagihan / konteks lain (tanpa edit/hapus/WA).
  factory CardPenyewa.konteks({
    required Map<String, dynamic> item,
    required String lokasi,
    required VoidCallback onTap,
  }) {
    final id = entityId(item['id']) ?? 0;
    return CardPenyewa(
      id: id,
      nama: '${item['nama'] ?? 'Penyewa'}',
      noTelpon: '${item['no_telpon'] ?? '-'}',
      email: item['email']?.toString(),
      tanggalLahir: item['tanggal_lahir']?.toString(),
      jenisKelamin: item['jenis_kelamin']?.toString(),
      statusHubungan: item['status_hubungan']?.toString(),
      tanggalSelesaiKontrak: item['tanggal_selesai']?.toString(),
      statusKontrak: item['status_kontrak']?.toString(),
      statusSewa: '${item['status'] ?? 'aktif'}',
      lokasi: lokasi,
      showActions: false,
      onTap: onTap,
      canEdit: false,
      canDelete: false,
    );
  }

  List<AppEntityListLine> get _lines {
    final out = <AppEntityListLine>[];
    if (lokasi != null && lokasi!.trim().isNotEmpty) {
      out.add(
        AppEntityListLine(icon: Icons.home_work_outlined, text: lokasi!.trim()),
      );
    }
    out.add(AppEntityListLine(icon: Icons.phone_outlined, text: noTelpon));
    if (showActions && tanggalMasuk != null && tanggalMasuk!.isNotEmpty) {
      final sisaKontrak = SisaHari.labelKontrak(
        tanggalMasuk,
        tanggalSelesaiKontrak,
        status: statusKontrak,
      );
      out.add(
        AppEntityListLine(
          icon: Icons.calendar_today_rounded,
          text:
              'Masuk: ${tanggalMasuk!.split('T').first}${sisaKontrak == null ? '' : ' · $sisaKontrak'}',
        ),
      );
    }
    final profil = _profilSingkat;
    if (profil.isNotEmpty) {
      out.add(AppEntityListLine(icon: Icons.badge_outlined, text: profil));
    } else if (email != null && email!.trim().isNotEmpty) {
      out.add(AppEntityListLine(icon: Icons.mail_outline, text: email!.trim()));
    }
    return out.take(AppEntityListCardMetrics.maxMetaLines).toList();
  }

  String get _profilSingkat {
    final parts = <String>[];
    final jk = _label(jenisKelamin);
    final hubungan = _label(statusHubungan);
    final lahir = tanggalLahir?.trim().split('T').first ?? '';
    if (jk.isNotEmpty) parts.add(jk);
    if (hubungan.isNotEmpty) parts.add(hubungan);
    if (lahir.isNotEmpty) parts.add('Lahir $lahir');
    return parts.join(' · ');
  }

  String _label(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return AppEntityListCard(
      entityLabel: 'PENGHUNI',
      title: nama,
      titleMaxLines: 1,
      accentColor: AppColors.icon_penyewa,
      placeholderIcon: Icons.person_rounded,
      status: statusSewa,
      lines: _lines,
      onTap: onTap,
      onMessage: showActions && onWa != null ? () => onWa!(noTelpon) : null,
      onEdit: showActions && onEdit != null ? () => onEdit!(id) : null,
      onDelete: showActions && onDelete != null ? () => onDelete!(id) : null,
      canEdit: canEdit,
      canDelete: canDelete,
      editBlockedMessage: editBlockedMessage,
      deleteBlockedMessage: deleteBlockedMessage,
    );
  }
}

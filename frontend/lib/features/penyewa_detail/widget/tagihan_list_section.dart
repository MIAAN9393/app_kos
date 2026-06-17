import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/penyewa_detail/widget/card_tagihan.dart';
import 'package:kos_management/features/penyewa_detail/widget/pengaturan_otomatis_panel.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/kontrak_status.dart';
import 'package:provider/provider.dart';

/// Daftar semua tagihan penyewa (tab Daftar di detail penyewa).
class TagihanListSection extends StatelessWidget {
  final int idPenyewa;
  final int idKamar;
  final int idKos;
  final bool embedded;

  const TagihanListSection({
    super.key,
    required this.idPenyewa,
    required this.idKamar,
    required this.idKos,
    this.embedded = false,
  });

  String _labelTagihan(Map<String, dynamic> data) {
    final kode = data['kode_tagihan'];
    if (kode != null && '$kode'.isNotEmpty) return '$kode';
    final awal = '${data['periode_awal']}'.split('T').first;
    final akhir = '${data['periode_akhir']}'.split('T').first;
    return '$awal — $akhir';
  }

  Map<String, dynamic>? _kontrakAktif(KontrakProvider provider) {
    final list = provider.kontrakListByPenyewa[idPenyewa] ?? const [];
    for (final kontrak in list) {
      if (KontrakStatus.isAktif(kontrak)) return kontrak;
    }

    final kontrak = provider.kontrakByPenyewa[idPenyewa];
    if (kontrak != null && KontrakStatus.isAktif(kontrak)) return kontrak;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final list = context.watch<TagihanProvider>().data_tagihan[idPenyewa] ?? [];
    final kontrakProvider = context.watch<KontrakProvider>();
    final kontrakAktif = _kontrakAktif(kontrakProvider);
    final padding = AppListTabUi.listPadding(
      embedded: embedded,
    ).copyWith(top: embedded ? 8 : 16);

    if (list.isEmpty) {
      return ListView(
        padding: padding,
        children: [
          _TagihanHeader(kontrakAktif: kontrakAktif),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 8),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada tagihan',
                  style: AppDesign.titleBold(context).copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gunakan tombol tambah untuk membuat tagihan baru.',
                  textAlign: TextAlign.center,
                  style: AppDesign.bodyMuted(context),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: padding,
      itemCount: list.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _TagihanHeader(kontrakAktif: kontrakAktif);
        }

        final data = list[index - 1];
        final tagihanId = entityId(data['id']);
        if (tagihanId == null) return const SizedBox.shrink();

        return CardTagihan(
          data_tagihan: data,
          tekan: (id) {
            AppNavigation.toTagihanDetail(
              context,
              tagihanId: id,
              penyewaId: idPenyewa,
              idKamar: idKamar,
              idKos: idKos,
            );
          },
          onEdit: () async {
            final ok = await AppNavigation.toEditTagihan(
              context,
              tagihanId: tagihanId,
              idPenyewa: idPenyewa,
            );
            if (ok == true && context.mounted) {
              await context.read<TagihanProvider>().ambil_data_tagihan_provider(
                idPenyewa,
              );
            }
          },
          onDelete: () {
            showConfirmDeleteDialog(
              context: context,
              nama: _labelTagihan(data),
              entityLabel: 'tagihan',
              onConfirm: () => context
                  .read<TagihanProvider>()
                  .hapus_tagihan_provider(tagihanId),
            );
          },
        );
      },
    );
  }
}

class _TagihanHeader extends StatelessWidget {
  final Map<String, dynamic>? kontrakAktif;

  const _TagihanHeader({required this.kontrakAktif});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text('Tagihan', style: AppDesign.sectionTitle(context)),
          ),
          PengaturanOtomatisButton(
            icon: Icons.receipt_long_rounded,
            label: 'Otomatisasi',
            onPressed: kontrakAktif == null
                ? null
                : () =>
                      showPengaturanTagihanOtomatisSheet(context, kontrakAktif),
          ),
        ],
      ),
    );
  }
}

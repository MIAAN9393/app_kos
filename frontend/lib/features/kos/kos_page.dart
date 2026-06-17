import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/navigation/app_routes.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_add_fab.dart';
import 'package:kos_management/core/widgets/app_empty_state.dart';
import 'package:kos_management/core/widgets/app_hero_header.dart';
import 'package:kos_management/core/widgets/app_kos_card.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/widgets/app_loading_overlay.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/provider_feedback.dart';
import 'package:provider/provider.dart';

class KosPage extends StatefulWidget {
  const KosPage({super.key});

  @override
  State<KosPage> createState() => _KosPageState();
}

class _KosPageState extends State<KosPage> with ProviderFeedback {
  late KosProvider _read;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _read = context.read<KosProvider>();
    _search.addListener(() => setState(() {}));
    _read.addListener(_onProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KosProvider>().ambil_or_update_data();
    });
  }

  void _onProvider() {
    listenProviderErrors(
      readError: _read.ambil_pesan_error,
      readSuccess: _read.ambil_pesan_sukses,
    );
  }

  @override
  void dispose() {
    _read.removeListener(_onProvider);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KosProvider>();
    final list = provider.tampilkan_data(_search.text);
    final map = provider.dataKosMap;
    final allKos = provider.data_kos;
    var totalKamar = 0;
    var totalPenyewa = 0;
    for (final kos in allKos) {
      totalKamar += intFromJson(kos['jumlah_kamar']) ?? 0;
      totalPenyewa += intFromJson(kos['jumlah_penyewa']) ?? 0;
    }

    return Scaffold(
      backgroundColor: AppDesign.surface,
      floatingActionButton: AppAddFab(
        tooltip: 'Tambah Kos',
        onPressed: () async {
          final ok = await AppNavigation.toTambahKos(context);
          if (ok == true && context.mounted) {
            await context.read<KosProvider>().ambil_data_kos_provider();
          }
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeroHeader(
            title: 'Property',
            subtitle: 'Kelola kos Anda',
            stats: [
              AppHeroStat(label: 'Kos', value: '${allKos.length}'),
              AppHeroStat(label: 'Kamar', value: '$totalKamar'),
              AppHeroStat(
                label: 'Penyewa',
                value: '$totalPenyewa',
                valueColor: AppDesign.success,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDesign.spaceMd,
              AppDesign.spaceMd,
              AppDesign.spaceMd,
              0,
            ),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Cari nama atau alamat kos...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: AppLoadingOverlay(
              loading: provider.loading,
              child: list.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.home_work_outlined,
                      title: 'Belum ada kos',
                      message: 'Tambahkan properti pertama Anda',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppListTabUi.horizontal,
                        AppDesign.spaceMd,
                        AppListTabUi.horizontal,
                        AppDesign.spaceMd,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final id = entityId(item['id']);
                        if (id == null) return const SizedBox.shrink();
                        final kos = map[id];
                        if (kos == null) return const SizedBox.shrink();
                        final jumlahKamar =
                            intFromJson(kos['jumlah_kamar']) ?? 0;
                        final jumlahPenyewa =
                            intFromJson(kos['jumlah_penyewa']) ?? 0;
                        return AppKosCard.fromData(
                          kos: kos,
                          jumlahKamar: jumlahKamar,
                          jumlahPenyewa: jumlahPenyewa,
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.kosDetail,
                              arguments: {'idKos': id},
                            );
                            if (!context.mounted) return;
                            await provider.ambil_data_kos_provider();
                          },
                          onEdit: () async {
                            final ok = await AppNavigation.toEditKos(
                              context,
                              idKos: id,
                              nama: '${kos['nama_kos']}',
                              alamat: '${kos['alamat']}',
                              deskripsi: '${kos['deskripsi'] ?? ''}',
                            );
                            if (ok == true && context.mounted) {
                              await provider.ambil_data_kos_provider();
                            }
                          },
                          onDelete: () => showConfirmDeleteDialog(
                            context: context,
                            nama: '${kos['nama_kos']}',
                            entityLabel: 'kos',
                            onConfirm: () => provider.hapus_kos_provider(id),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

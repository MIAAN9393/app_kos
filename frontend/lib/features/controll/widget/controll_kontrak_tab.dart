import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/widgets/app_kontrak_list_card.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/controll/controll_helpers.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/list_multi_filter.dart';
import 'package:provider/provider.dart';

class ControllKontrakTab extends StatefulWidget {
  const ControllKontrakTab({super.key});

  @override
  State<ControllKontrakTab> createState() => _ControllKontrakTabState();
}

class _ControllKontrakTabState extends State<ControllKontrakTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  final Set<int> _selectedFilters = ControllHelpers.defaultFilterSelection(
    _filterLabels.length,
  );
  static const _filterLabels = ['Aktif', 'Pending', 'Selesai', 'Dibatalkan'];
  bool _loaded = false;
  bool _refreshTerjadwal = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat());
  }

  Future<void> _muat() async {
    await ControllHelpers.loadAllKontrak(context);
    if (mounted) setState(() => _loaded = true);
  }

  void _muatJikaPerlu(bool perlu) {
    if (!perlu || _refreshTerjadwal) return;
    _refreshTerjadwal = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _loaded = false);
      try {
        await _muat();
      } finally {
        _refreshTerjadwal = false;
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _bukaDetail(Map<String, dynamic> kontrak) {
    final penyewaId = entityId(kontrak['penyewa_id']);
    if (penyewaId == null) return;
    final kamarId = entityId(kontrak['kamar_id']);
    final kosId = ControllHelpers.kosIdForKamar(
      context.read<KamarProvider>(),
      kamarId,
    );
    AppNavigation.toPenyewaDetail(
      context,
      idPenyewa: penyewaId,
      idKamar: kamarId,
      idKos: kosId,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<KontrakProvider>();
    _muatJikaPerlu(provider.semuaPerluMuatUlang && !provider.loading);
    final penyewaProv = context.read<PenyewaProvider>();
    final kamarProv = context.read<KamarProvider>();
    final all = ControllHelpers.flattenKontrak(provider).map((k) {
      final row = Map<String, dynamic>.from(k);
      final pid = entityId(row['penyewa_id']);
      final kid = entityId(row['kamar_id']);
      if (row['penyewa'] == null && pid != null) {
        final p = penyewaProv.penyewa_by_id[pid];
        if (p != null) row['penyewa'] = {'nama': p['nama']};
      }
      if (row['kamar'] == null && kid != null) {
        final km = kamarProv.kamar_by_id[kid];
        if (km != null) row['kamar'] = {'nomor': km['nomor']};
      }
      return row;
    }).toList();
    final outcome = ControllHelpers.filterKontrakMulti(
      all,
      _search.text,
      _selectedFilters,
    );
    final data = outcome.data;
    final hasFilter =
        _search.text.trim().isNotEmpty ||
        ListMultiFilter.isNarrowedSelection(
          _selectedFilters,
          _filterLabels.length,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListTabUi.searchField(
          controller: _search,
          hint: 'Cari penyewa atau kamar…',
          embedded: true,
        ),
        AppListTabUi.summaryRowWithFilter(
          context: context,
          leftItems: AppListTabUi.summaryFromFilterCounts(
            selected: _selectedFilters,
            counts: outcome.counts,
            labels: _filterLabels,
          ),
          right: AppListSummaryItem(
            label: 'Total',
            value: '${data.length}',
            color: Theme.of(context).colorScheme.primary,
          ),
          filterLabels: _filterLabels,
          selectedFilters: _selectedFilters,
          onFiltersChanged: (s) => setState(() {
            _selectedFilters
              ..clear()
              ..addAll(s);
          }),
        ),
        Expanded(
          child: !_loaded || provider.loading
              ? const Center(child: CircularProgressIndicator())
              : data.isEmpty
              ? AppListTabUi.emptyListMessage(
                  context: context,
                  hasQuery: _search.text.trim().isNotEmpty,
                  hasFilter: hasFilter,
                  emptyMessage: 'Belum ada kontrak.',
                  noMatchMessage: 'Tidak ada kontrak yang cocok.',
                )
              : ListView.builder(
                  padding: AppListTabUi.listPadding(embedded: true),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final kontrak = data[index];
                    final kontrakId = entityId(kontrak['id']);
                    final penyewaId = entityId(kontrak['penyewa_id']);
                    final kamarId = entityId(kontrak['kamar_id']);
                    return AppKontrakListCard(
                      kontrak: kontrak,
                      onTap: () => _bukaDetail(kontrak),
                      onEdit:
                          kontrakId != null &&
                              penyewaId != null &&
                              kamarId != null
                          ? () async {
                              await AppNavigation.toEditKontrak(
                                context,
                                kontrakId: kontrakId,
                                idPenyewa: penyewaId,
                                idKamar: kamarId,
                                harga: '${kontrak['harga_sewa']}',
                                mulai: '${kontrak['tanggal_mulai']}'
                                    .split('T')
                                    .first,
                                selesai: '${kontrak['tanggal_selesai']}'
                                    .split('T')
                                    .first,
                                siklus: '${kontrak['siklus'] ?? 'bulanan'}',
                              );
                              if (context.mounted) {
                                await context
                                    .read<KontrakProvider>()
                                    .ambil_kontrak_provider(
                                      penyewaId,
                                      force: true,
                                    );
                              }
                            }
                          : null,
                      onDelete: kontrakId != null && penyewaId != null
                          ? () => showConfirmDeleteDialog(
                              context: context,
                              nama:
                                  '${kontrak['kode_kontrak'] ?? '#$kontrakId'}',
                              entityLabel: 'kontrak',
                              onConfirm: () async {
                                final provider = context
                                    .read<KontrakProvider>();
                                await provider.batalkan_kontrak_provider(
                                  kontrakId: kontrakId,
                                  penyewaId: penyewaId,
                                );
                                if (!context.mounted) return;
                                await provider.ambil_semua_kontrak(force: true);
                                await provider.ambil_kontrak_provider(
                                  penyewaId,
                                  force: true,
                                );
                              },
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

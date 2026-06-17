import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/controll/controll_helpers.dart';
import 'package:kos_management/features/penyewa_detail/widget/card_tagihan.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/list_multi_filter.dart';
import 'package:provider/provider.dart';

class ControllTagihanTab extends StatefulWidget {
  const ControllTagihanTab({super.key});

  @override
  State<ControllTagihanTab> createState() => _ControllTagihanTabState();
}

class _ControllTagihanTabState extends State<ControllTagihanTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  final Set<int> _selectedFilters = ControllHelpers.defaultFilterSelection(
    _filterLabels.length,
  );
  static const _filterLabels = ['Belum', 'Sebagian', 'Lunas', 'Dibatalkan'];
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
    await ControllHelpers.loadAllTagihan(context);
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

  String _labelTagihan(Map<String, dynamic> data) {
    final kode = data['kode_tagihan'];
    if (kode != null && '$kode'.isNotEmpty) return '$kode';
    final awal = '${data['periode_awal']}'.split('T').first;
    final akhir = '${data['periode_akhir']}'.split('T').first;
    return '$awal — $akhir';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<TagihanProvider>();
    _muatJikaPerlu(provider.semuaPerluMuatUlang && !provider.loading);
    final penyewaProv = context.watch<PenyewaProvider>();
    final kamarProv = context.watch<KamarProvider>();
    final kosProv = context.watch<KosProvider>();
    final all = ControllHelpers.flattenTagihan(provider);
    final outcome = ControllHelpers.filterTagihanMulti(
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
          hint: 'Cari kode tagihan…',
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
                  emptyMessage: 'Belum ada tagihan.',
                  noMatchMessage: 'Tidak ada tagihan yang cocok.',
                )
              : ListView.builder(
                  padding: AppListTabUi.listPadding(embedded: true),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final dataTagihan = data[index];
                    final tagihanId = entityId(dataTagihan['id']);
                    final penyewaId = entityId(dataTagihan['penyewa_id']);
                    if (tagihanId == null || penyewaId == null) {
                      return const SizedBox.shrink();
                    }
                    // kamar_id dibawa langsung oleh response tagihan;
                    // fallback ke index penyewa aktif bila perlu.
                    final kamarId =
                        entityId(dataTagihan['kamar_id']) ??
                        ControllHelpers.kamarIdForPenyewa(
                          penyewaProv,
                          penyewaId,
                        );
                    final kosId = ControllHelpers.kosIdForKamar(
                      kamarProv,
                      kamarId,
                    );
                    return CardTagihan(
                      data_tagihan: dataTagihan,
                      konteksPenyewa: ControllHelpers.labelKonteksPenyewa(
                        penyewa: penyewaProv,
                        kamar: kamarProv,
                        kos: kosProv,
                        penyewaId: penyewaId,
                      ),
                      tekan: (id) {
                        if (kamarId == null || kosId == null) return;
                        AppNavigation.toTagihanDetail(
                          context,
                          tagihanId: id,
                          penyewaId: penyewaId,
                          idKamar: kamarId,
                          idKos: kosId,
                        );
                      },
                      onEdit: () async {
                        final ok = await AppNavigation.toEditTagihan(
                          context,
                          tagihanId: tagihanId,
                          idPenyewa: penyewaId,
                        );
                        if (ok == true && context.mounted) {
                          await provider.ambil_data_tagihan_provider(penyewaId);
                        }
                      },
                      onDelete: () => showConfirmDeleteDialog(
                        context: context,
                        nama: _labelTagihan(dataTagihan),
                        entityLabel: 'tagihan',
                        onConfirm: () =>
                            provider.hapus_tagihan_provider(tagihanId),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

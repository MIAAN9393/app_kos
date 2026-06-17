import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/widgets/app_pembayaran_list_card.dart';
import 'package:kos_management/features/controll/controll_helpers.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/pembayaran_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/list_multi_filter.dart';
import 'package:provider/provider.dart';

class ControllPembayaranTab extends StatefulWidget {
  const ControllPembayaranTab({super.key});

  @override
  State<ControllPembayaranTab> createState() => _ControllPembayaranTabState();
}

class _ControllPembayaranTabState extends State<ControllPembayaranTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  final Set<int> _selectedFilters = ControllHelpers.defaultFilterSelection(
    _filterLabels.length,
  );
  static const _filterLabels = ['Valid', 'Refund'];
  bool _loaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat());
  }

  Future<void> _muat() async {
    await ControllHelpers.loadAllPembayaran(context);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _bukaDetail(Map<String, dynamic> row) {
    final penyewaId = entityId(row['penyewa_id']);
    // kamar_id diambil dari tagihan terkait dulu, fallback index penyewa aktif.
    final tagihan = row['_tagihan'];
    final kamarId =
        (tagihan is Map ? entityId(tagihan['kamar_id']) : null) ??
        (penyewaId == null
            ? null
            : ControllHelpers.kamarIdForPenyewa(
                context.read<PenyewaProvider>(),
                penyewaId,
              ));
    final kosId = ControllHelpers.kosIdForKamar(
      context.read<KamarProvider>(),
      kamarId,
    );
    AppNavigation.toPembayaranDetail(
      context,
      pembayaran: row,
      tagihan: tagihan is Map ? Map<String, dynamic>.from(tagihan) : null,
      penyewaId: penyewaId,
      idKamar: kamarId,
      idKos: kosId,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final payProv = context.watch<PembayaranProvider>();
    final tagihanProv = context.watch<TagihanProvider>();
    final penyewaProv = context.watch<PenyewaProvider>();
    final kamarProv = context.watch<KamarProvider>();
    final kosProv = context.watch<KosProvider>();
    final all = ControllHelpers.flattenPembayaran(payProv, tagihanProv);
    final outcome = ControllHelpers.filterPembayaranMulti(
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
          child: !_loaded || payProv.loading
              ? const Center(child: CircularProgressIndicator())
              : data.isEmpty
              ? AppListTabUi.emptyListMessage(
                  context: context,
                  hasQuery: _search.text.trim().isNotEmpty,
                  hasFilter: hasFilter,
                  emptyMessage: 'Belum ada pembayaran tercatat.',
                  noMatchMessage: 'Tidak ada pembayaran yang cocok.',
                )
              : ListView.builder(
                  padding: AppListTabUi.listPadding(embedded: true),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final row = data[index];
                    final tagihan = row['_tagihan'] is Map
                        ? Map<String, dynamic>.from(row['_tagihan'] as Map)
                        : tagihanProv.tagihan_by_id[entityId(
                                row['tagihan_id'],
                              ) ??
                              -1];
                    final penyewaId = entityId(row['penyewa_id']);
                    return AppPembayaranListCard(
                      pembayaran: row,
                      tagihan: tagihan,
                      konteksPenyewa: penyewaId != null
                          ? ControllHelpers.labelKonteksPenyewa(
                              penyewa: penyewaProv,
                              kamar: kamarProv,
                              kos: kosProv,
                              penyewaId: penyewaId,
                            )
                          : null,
                      onTap: () => _bukaDetail(row),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

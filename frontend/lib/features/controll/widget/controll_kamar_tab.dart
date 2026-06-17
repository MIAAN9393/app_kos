import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/widgets/app_room_list_card.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/controll/controll_helpers.dart';
import 'package:kos_management/features/kamar/widget/kamar_filter_sheet.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';
import 'package:kos_management/utils/list_multi_filter.dart';
import 'package:provider/provider.dart';

class ControllKamarTab extends StatefulWidget {
  const ControllKamarTab({super.key});

  @override
  State<ControllKamarTab> createState() => _ControllKamarTabState();
}

class _ControllKamarTabState extends State<ControllKamarTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  final Set<int> _selectedFilters = ControllHelpers.defaultFilterSelection(
    _filterLabels.length,
  );
  static final _filterLabels = KamarFilterSheet.labels;
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
    await ControllHelpers.loadAllKamar(context);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AppListSummaryItem> _filterSummary(Map<int, int> counts) {
    final allSelected = _selectedFilters.length == _filterLabels.length;
    if (_selectedFilters.length == 1) {
      final i = _selectedFilters.first;
      return [
        AppListSummaryItem(
          label: _filterLabels[i],
          value: '${counts[i] ?? 0}',
          color: AppDesign.info,
        ),
      ];
    }
    return [
      AppListSummaryItem(
        label: 'Filter',
        value: allSelected ? 'Semua' : '${_selectedFilters.length}',
        suffix: allSelected ? '' : ' opsi',
        color: AppDesign.info,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<KamarProvider>();
    final all = ControllHelpers.flattenKamar(provider);
    final outcome = ControllHelpers.filterKamarMulti(
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
          hint: 'Cari nomor kamar…',
          embedded: true,
        ),
        AppListTabUi.summaryRowWithFilter(
          context: context,
          leftItems: _filterSummary(outcome.counts),
          right: AppListSummaryItem(
            label: 'Total',
            value: '${data.length}',
            color: Theme.of(context).colorScheme.primary,
          ),
          filterLabels: _filterLabels,
          selectedFilters: _selectedFilters,
          onFilterTap: () => KamarFilterSheet.show(
            context: context,
            selected: _selectedFilters,
            onChanged: (s) => setState(() {
              _selectedFilters
                ..clear()
                ..addAll(s);
            }),
          ),
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
                  emptyMessage: 'Belum ada kamar.',
                  noMatchMessage: 'Tidak ada kamar yang cocok.',
                )
              : ListView.builder(
                  padding: AppListTabUi.listPadding(embedded: true),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final id = entityId(item['id']);
                    final kosId = entityId(item['kos_id']);
                    if (id == null || kosId == null) {
                      return const SizedBox.shrink();
                    }
                    final kamarData = provider.kamar_by_id[id] ?? item;
                    return AppRoomListCard.fromData(
                      kamar: kamarData,
                      onTap: () => AppNavigation.toKamarDetail(
                        context,
                        idKamar: id,
                        idKos: kosId,
                      ),
                      onEdit: () async {
                        final ok = await AppNavigation.toEditKamar(
                          context,
                          idKamar: id,
                          idKos: kosId,
                          nomor: '${kamarData['nomor']}',
                          harga: '${kamarData['harga']}',
                          kapasitas: '${kamarData['kapasitas']}',
                          fasilitas: KamarFasilitas.parse(
                            kamarData['fasilitas'],
                          ),
                        );
                        if (!context.mounted) return;
                        if (ok == true) {
                          final kosProvider = context.read<KosProvider>();
                          final kamarProvider = context.read<KamarProvider>();
                          await kosProvider.ambil_data_kos_provider();
                          await kamarProvider.ambil_data_kamar_provider(kosId);
                        }
                      },
                      onDelete: () => showConfirmDeleteDialog(
                        context: context,
                        nama: '${kamarData['nomor']}',
                        entityLabel: 'kamar',
                        onConfirm: () async {
                          final kamarProvider = context.read<KamarProvider>();
                          final kosProvider = context.read<KosProvider>();
                          await kamarProvider.hapus_kamar_provider(id);
                          if (context.mounted) {
                            await kosProvider.ambil_data_kos_provider();
                            await kamarProvider.ambil_data_kamar_provider(
                              kosId,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

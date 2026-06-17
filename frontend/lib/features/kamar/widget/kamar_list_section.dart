import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_add_fab.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/widgets/app_room_list_card.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/kamar/widget/kamar_filter_sheet.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/list_multi_filter.dart';
import 'package:provider/provider.dart';

class KamarListSection extends StatefulWidget {
  final int idKos;
  final String? namaKos;
  final bool showHeader;
  final bool embedded;

  const KamarListSection({
    super.key,
    required this.idKos,
    this.namaKos,
    this.showHeader = true,
    this.embedded = false,
  });

  @override
  State<KamarListSection> createState() => _KamarListSectionState();
}

class _KamarListSectionState extends State<KamarListSection> {
  final Set<int> _selectedFilters = ListMultiFilter.allIndices(
    _filterLabels.length,
  );
  static final _filterLabels = KamarFilterSheet.labels;
  late TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController()..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KamarProvider>().ambil_data_kamar_provider(widget.idKos);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ListMultiFilterResult<Map<String, dynamic>> _outcome(KamarProvider provider) {
    final searched = provider.tampilkan_data(_search.text, widget.idKos);
    return ListMultiFilter.apply(
      searched: searched,
      selected: _selectedFilters,
      matchers: [
        (e) => e['status_kondisi'] == 'kosong',
        (e) => e['status_kondisi'] == 'sebagian',
        (e) => e['status_kondisi'] == 'penuh',
        (e) => KamarFasilitas.contains(e['fasilitas'], KamarFasilitas.ac),
        (e) => KamarFasilitas.contains(e['fasilitas'], KamarFasilitas.wifi),
        (e) => KamarFasilitas.contains(e['fasilitas'], KamarFasilitas.lemari),
        (e) =>
            KamarFasilitas.contains(e['fasilitas'], KamarFasilitas.kamarMandi),
      ],
    );
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
    final provider = context.watch<KamarProvider>();
    final outcome = _outcome(provider);
    final data = outcome.data;
    final byId = provider.kamar_by_id;
    final hasQuery = _search.text.trim().isNotEmpty;
    final hasFilter =
        hasQuery ||
        ListMultiFilter.isNarrowedSelection(
          _selectedFilters,
          _filterLabels.length,
        );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'List Kamar',
                  style: AppDesign.titleBold(context).copyWith(fontSize: 20),
                ),
                if (widget.namaKos != null)
                  Text(
                    widget.namaKos!,
                    style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        AppListTabUi.searchField(
          controller: _search,
          hint: 'Cari kamar…',
          embedded: widget.embedded,
        ),
        AppListTabUi.summaryRowWithFilter(
          context: context,
          leftItems: _filterSummary(outcome.counts),
          right: AppListSummaryItem(
            label: 'Total',
            value: '${data.length}',
            color: Theme.of(context).colorScheme.primary,
          ),
          filterTitle: 'Filter',
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
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : data.isEmpty
              ? AppListTabUi.emptyListMessage(
                  context: context,
                  hasQuery: hasQuery,
                  hasFilter: hasFilter,
                  emptyMessage: 'Belum ada kamar di kos ini.',
                  noMatchMessage:
                      'Tidak ada kamar yang cocok dengan filter atau pencarian.',
                )
              : ListView.builder(
                  padding: AppListTabUi.listPadding(embedded: widget.embedded),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final id = entityId(item['id']);
                    if (id == null) return const SizedBox.shrink();
                    final kamarData = byId[id] ?? item;
                    return AppRoomListCard.fromData(
                      kamar: kamarData,
                      onTap: () => AppNavigation.toKamarDetail(
                        context,
                        idKamar: id,
                        idKos: widget.idKos,
                      ),
                      onEdit: () async {
                        final k = byId[id];
                        if (k == null) return;
                        final ok = await AppNavigation.toEditKamar(
                          context,
                          idKamar: id,
                          idKos: widget.idKos,
                          nomor: '${k['nomor']}',
                          harga: '${k['harga']}',
                          kapasitas: '${k['kapasitas']}',
                          fasilitas: KamarFasilitas.parse(k['fasilitas']),
                        );
                        if (!context.mounted) return;
                        if (ok == true) {
                          await context
                              .read<KosProvider>()
                              .ambil_data_kos_provider();
                          if (!context.mounted) return;
                          await context
                              .read<KamarProvider>()
                              .ambil_data_kamar_provider(widget.idKos);
                        }
                      },
                      onDelete: () => showConfirmDeleteDialog(
                        context: context,
                        nama: '${byId[id]?['nomor']}',
                        entityLabel: 'kamar',
                        onConfirm: () async {
                          await context
                              .read<KamarProvider>()
                              .hapus_kamar_provider(id);
                          if (!context.mounted) return;
                          await context
                              .read<KosProvider>()
                              .ambil_data_kos_provider();
                          if (!context.mounted) return;
                          await context
                              .read<KamarProvider>()
                              .ambil_data_kamar_provider(widget.idKos);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (!widget.embedded) {
      return Scaffold(
        backgroundColor: AppDesign.surface,
        floatingActionButton: AppAddFab(
          tooltip: 'Tambah Kamar',
          onPressed: () async {
            final ok = await AppNavigation.toTambahKamar(
              context,
              idKos: widget.idKos,
            );
            if (ok == true && context.mounted) {
              await context.read<KosProvider>().ambil_data_kos_provider();
            }
          },
        ),
        body: content,
      );
    }

    return content;
  }
}

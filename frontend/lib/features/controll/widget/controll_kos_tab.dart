import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/navigation/app_routes.dart';
import 'package:kos_management/core/widgets/app_kos_card.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/controll/controll_helpers.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/list_multi_filter.dart';
import 'package:kos_management/utils/provider_feedback.dart';
import 'package:provider/provider.dart';

class ControllKosTab extends StatefulWidget {
  const ControllKosTab({super.key});

  @override
  State<ControllKosTab> createState() => _ControllKosTabState();
}

class _ControllKosTabState extends State<ControllKosTab>
    with AutomaticKeepAliveClientMixin, ProviderFeedback {
  final _search = TextEditingController();
  final Set<int> _selectedFilters =
      ControllHelpers.defaultFilterSelection(_filterLabels.length);
  static const _filterLabels = ['Aktif', 'Nonaktif'];
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
    await ControllHelpers.ensureKos(context);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<KosProvider>();
    final all = provider.data_kos;
    final outcome =
        ControllHelpers.filterKosMulti(all, _search.text, _selectedFilters);
    final data = outcome.data;
    final hasFilter = _search.text.trim().isNotEmpty ||
        ListMultiFilter.isNarrowedSelection(
          _selectedFilters,
          _filterLabels.length,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListTabUi.searchField(
          controller: _search,
          hint: 'Cari nama atau alamat kos…',
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
                      emptyMessage: 'Belum ada kos.',
                      noMatchMessage: 'Tidak ada kos yang cocok.',
                    )
                  : ListView.builder(
                      padding: AppListTabUi.listPadding(embedded: true),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final kos = data[index];
                        final id = entityId(kos['id']);
                        if (id == null) return const SizedBox.shrink();
                        final map = provider.dataKosMap[id] ?? kos;
                        return AppKosCard.fromData(
                          kos: map,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.kosDetail,
                            arguments: {'idKos': id},
                          ),
                          onEdit: () async {
                            final ok = await AppNavigation.toEditKos(
                              context,
                              idKos: id,
                              nama: '${map['nama_kos']}',
                              alamat: '${map['alamat']}',
                              deskripsi: '${map['deskripsi'] ?? ''}',
                            );
                            if (ok == true && context.mounted) {
                              await provider.ambil_data_kos_provider();
                            }
                          },
                          onDelete: () => showConfirmDeleteDialog(
                            context: context,
                            nama: '${map['nama_kos']}',
                            entityLabel: 'kos',
                            onConfirm: () => provider.hapus_kos_provider(id),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

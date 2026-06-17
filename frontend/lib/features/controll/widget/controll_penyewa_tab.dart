import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/controll/controll_helpers.dart';
import 'package:kos_management/features/penyewa/widget/custom_card_penyewa.dart';
import 'package:kos_management/features/whatsapp/whatsapp_deep_link_service.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/list_multi_filter.dart';
import 'package:provider/provider.dart';

class ControllPenyewaTab extends StatefulWidget {
  const ControllPenyewaTab({super.key});

  @override
  State<ControllPenyewaTab> createState() => _ControllPenyewaTabState();
}

class _ControllPenyewaTabState extends State<ControllPenyewaTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  final Set<int> _selectedFilters = ControllHelpers.defaultFilterSelection(
    _filterLabels.length,
  );
  static const _filterLabels = ['Aktif', 'Nonaktif'];
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
    await ControllHelpers.loadAllKamar(context);
    if (!mounted) return;
    await ControllHelpers.loadAllPenyewa(context);
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

  Future<void> _chatWhatsApp(String? noTelpon, String? nama) async {
    final opened = await WhatsAppDeepLinkService.openChat(
      phoneNumber: noTelpon,
      message:
          '${WhatsAppDeepLinkService.tenantGreeting(nama)}, saya menghubungi dari aplikasi Manajemen Kos.',
    );
    if (!mounted) return;
    if (!opened) {
      AppSnackbar.error(
        context,
        'Nomor WhatsApp belum valid atau WhatsApp tidak bisa dibuka.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<PenyewaProvider>();
    _muatJikaPerlu(provider.semuaPerluMuatUlang && !provider.loading);
    final kamarProv = context.read<KamarProvider>();
    final all = ControllHelpers.flattenPenyewa(provider);
    final outcome = ControllHelpers.filterPenyewaMulti(
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
          hint: 'Cari nama atau telepon…',
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
                  emptyMessage: 'Belum ada penyewa.',
                  noMatchMessage: 'Tidak ada penyewa yang cocok.',
                )
              : ListView.builder(
                  padding: AppListTabUi.listPadding(embedded: true),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final row = data[index];
                    final id = entityId(row['id']);
                    if (id == null) return const SizedBox.shrink();
                    final kamarId = ControllHelpers.kamarIdForPenyewa(
                      provider,
                      id,
                    );
                    final kosId = ControllHelpers.kosIdForKamar(
                      kamarProv,
                      kamarId,
                    );

                    final item = {
                      ...row,
                      ...?provider.semua_data_penyewa[id],
                      ...?provider.penyewa_by_id[id],
                    };
                    return CardPenyewa.fromData(
                      item: item,
                      klik_card: (pid) => AppNavigation.toPenyewaDetail(
                        context,
                        idPenyewa: pid,
                        idKamar: kamarId,
                        idKos: kosId,
                      ),
                      klik_edit: (pid) {
                        final d = provider.semua_data_penyewa[pid];
                        if (d == null) return;
                        AppNavigation.toEditPenyewa(
                          context,
                          idPenyewa: pid,
                          nama: '${d['nama']}',
                          noTelpon: '${d['no_telpon']}',
                          email: '${d['email'] ?? ''}',
                          tanggalLahir: d['tanggal_lahir']?.toString(),
                          jenisKelamin: d['jenis_kelamin']?.toString(),
                          statusHubungan: d['status_hubungan']?.toString(),
                        );
                      },
                      klik_hapus: (pid) {
                        final d = provider.semua_data_penyewa[pid];
                        if (d == null) return;
                        showConfirmDeleteDialog(
                          context: context,
                          nama: '${d['nama']}',
                          entityLabel: 'penyewa',
                          onConfirm: () => provider.hapus_penyewa_provider(pid),
                        );
                      },
                      klik_wa: (no) =>
                          _chatWhatsApp(no, item['nama']?.toString()),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

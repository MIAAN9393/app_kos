import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_list_tab_ui.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/features/penyewa/widget/custom_card_penyewa.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/whatsapp/whatsapp_deep_link_service.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/list_multi_filter.dart';
import 'package:provider/provider.dart';

class PenyewaListSection extends StatefulWidget {
  final int idKamar;
  final int idKos;
  final String? nomorKamar;
  final bool embedded;

  const PenyewaListSection({
    super.key,
    required this.idKamar,
    required this.idKos,
    this.nomorKamar,
    this.embedded = false,
  });

  @override
  State<PenyewaListSection> createState() => _PenyewaListSectionState();
}

class _PenyewaListSectionState extends State<PenyewaListSection> {
  final Set<int> _selectedFilters = ListMultiFilter.allIndices(
    _filterLabels.length,
  );
  static const _filterLabels = ['Aktif', 'Nonaktif'];
  late TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController()..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenyewaProvider>().ambil_data_penyewa_provider(
        widget.idKamar,
      );
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static bool _isAktif(Map<String, dynamic> e) {
    final s = '${e['status'] ?? 'aktif'}'.toLowerCase();
    return s == 'aktif';
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

  ListMultiFilterResult<Map<String, dynamic>> _outcome(
    PenyewaProvider provider,
  ) {
    final searched = provider.tampilkan_data(_search.text, widget.idKamar);
    return ListMultiFilter.apply(
      searched: searched,
      selected: _selectedFilters,
      matchers: [_isAktif, (e) => !_isAktif(e)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PenyewaProvider>();
    final outcome = _outcome(provider);
    final data = outcome.data;
    final byId = provider.penyewa_by_id;
    final hasQuery = _search.text.trim().isNotEmpty;
    final hasFilter =
        hasQuery ||
        ListMultiFilter.isNarrowedSelection(
          _selectedFilters,
          _filterLabels.length,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListTabUi.searchField(
          controller: _search,
          hint: 'Cari penyewa…',
          embedded: widget.embedded,
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
          filterTitle: 'Filter',
          filterLabels: _filterLabels,
          selectedFilters: _selectedFilters,
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
                  emptyMessage: 'Belum ada penyewa di kamar ini.',
                  noMatchMessage:
                      'Tidak ada penyewa yang cocok dengan filter atau pencarian.',
                )
              : ListView.builder(
                  padding: AppListTabUi.listPadding(embedded: widget.embedded),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final id = entityId(item['id']);
                    if (id == null) return const SizedBox.shrink();
                    final row = byId[id] ?? item;
                    return CardPenyewa.fromData(
                      item: row,
                      klik_card: (pid) => AppNavigation.toPenyewaDetail(
                        context,
                        idPenyewa: pid,
                        idKamar: widget.idKamar,
                        idKos: widget.idKos,
                      ),
                      klik_edit: (pid) {
                        final d = byId[pid];
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
                        final d = byId[pid];
                        if (d == null) return;
                        showConfirmDeleteDialog(
                          context: context,
                          nama: '${d['nama']}',
                          entityLabel: 'penyewa',
                          onConfirm: () => context
                              .read<PenyewaProvider>()
                              .hapus_penyewa_provider(pid),
                        );
                      },
                      klik_wa: (no) =>
                          _chatWhatsApp(no, row['nama']?.toString()),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

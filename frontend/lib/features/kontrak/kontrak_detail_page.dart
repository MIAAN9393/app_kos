import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_back_button.dart';
import 'package:kos_management/core/widgets/app_entity_action_controls.dart';
import 'package:kos_management/core/widgets/app_info_row.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/export_pdf/kontrak_pdf.dart';
import 'package:kos_management/features/export_pdf/pdf_export_service.dart';
import 'package:kos_management/features/export_pdf/pdf_helpers.dart';
import 'package:kos_management/features/whatsapp/whatsapp_deep_link_service.dart';
import 'package:kos_management/features/penyewa_detail/widget/card_tagihan.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/kontrak_aksi_rules.dart';
import 'package:kos_management/utils/kontrak_status.dart';
import 'package:kos_management/utils/sisa_hari.dart';
import 'package:provider/provider.dart';

class KontrakDetailPage extends StatefulWidget {
  final int kontrakId;
  final int idPenyewa;
  final int? idKamar;
  final int? idKos;
  final Map<String, dynamic>? initialKontrak;

  const KontrakDetailPage({
    super.key,
    required this.kontrakId,
    required this.idPenyewa,
    this.idKamar,
    this.idKos,
    this.initialKontrak,
  });

  @override
  State<KontrakDetailPage> createState() => _KontrakDetailPageState();
}

class _KontrakDetailPageState extends State<KontrakDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final KontrakProvider _kontrakRead;
  late final TagihanProvider _tagihanRead;
  bool _sendingKontrakWhatsApp = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _kontrakRead = context.read<KontrakProvider>();
    _tagihanRead = context.read<TagihanProvider>();
    _kontrakRead.addListener(_listenerKontrak);
    _tagihanRead.addListener(_listenerTagihan);
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatAwal());
  }

  Future<void> _muatAwal() async {
    await _kontrakRead.ambil_list_kontrak_penyewa(
      widget.idPenyewa,
      force: true,
    );
    await _tagihanRead.ambil_tagihan_by_kontrak_provider(
      widget.kontrakId,
      penyewa_id: widget.idPenyewa,
      force: true,
    );
  }

  void _listenerKontrak() => _showSnack(
    _kontrakRead.ambil_pesan_error(),
    _kontrakRead.ambil_pesan_sukses(),
  );

  void _listenerTagihan() => _showSnack(
    _tagihanRead.ambil_pesan_error(),
    _tagihanRead.ambil_pesan_sukses(),
  );

  void _showSnack(String? err, String? ok) {
    if (!mounted) return;
    if (err != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSnackbar.error(context, err);
      });
    }
    if (ok != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSnackbar.success(context, ok);
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _kontrakRead.removeListener(_listenerKontrak);
    _tagihanRead.removeListener(_listenerTagihan);
    super.dispose();
  }

  Map<String, dynamic>? _kontrak(KontrakProvider provider) {
    final list = provider.kontrakListByPenyewa[widget.idPenyewa] ?? [];
    for (final item in list) {
      if (idEquals(item['id'], widget.kontrakId)) return item;
    }
    final latest = provider.kontrakByPenyewa[widget.idPenyewa];
    if (latest != null && idEquals(latest['id'], widget.kontrakId)) {
      return latest;
    }
    if (widget.initialKontrak != null &&
        idEquals(widget.initialKontrak!['id'], widget.kontrakId)) {
      return widget.initialKontrak;
    }
    return null;
  }

  String _tanggal(dynamic value) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text == 'null') return '-';
    return text.split('T').first;
  }

  String _labelSiklus(dynamic raw) {
    switch ('${raw ?? ''}'.toLowerCase()) {
      case 'bulanan':
        return 'Bulanan';
      case 'mingguan':
        return 'Mingguan';
      case 'harian':
        return 'Harian';
      case 'tahunan':
        return 'Tahunan';
      default:
        return '${raw ?? '-'}';
    }
  }

  String _labelKontrak(Map<String, dynamic>? kontrak) {
    final kode = '${kontrak?['kode_kontrak'] ?? ''}'.trim();
    if (kode.isNotEmpty) return kode;
    return 'Kontrak #${widget.kontrakId}';
  }

  int _kamarId(Map<String, dynamic>? kontrak) =>
      entityId(kontrak?['kamar_id']) ?? widget.idKamar ?? 0;

  int _kosId(Map<String, dynamic>? kontrak) {
    final kamar = kontrak?['kamar'];
    final fromKontrak = kamar is Map ? entityId(kamar['kos_id']) : null;
    final kamarId = _kamarId(kontrak);
    return fromKontrak ??
        widget.idKos ??
        context.read<KamarProvider>().cari_kos_id(kamarId) ??
        0;
  }

  Future<void> _refreshTagihan() {
    return _tagihanRead.ambil_tagihan_by_kontrak_provider(
      widget.kontrakId,
      penyewa_id: widget.idPenyewa,
      force: true,
    );
  }

  Future<void> _editKontrak(Map<String, dynamic> kontrak) async {
    final ok = await AppNavigation.toEditKontrak(
      context,
      kontrakId: widget.kontrakId,
      idPenyewa: widget.idPenyewa,
      idKamar: _kamarId(kontrak),
      harga: '${kontrak['harga_sewa']}',
      mulai: _tanggal(kontrak['tanggal_mulai']),
      selesai: _tanggal(kontrak['tanggal_selesai']),
      siklus: '${kontrak['siklus'] ?? 'bulanan'}',
    );
    if (!mounted || ok != true) return;
    await _muatAwal();
  }

  Future<void> _selesaikanKontrak(Map<String, dynamic> kontrak) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan kontrak?'),
        content: const Text(
          'Kontrak akan diakhiri hari ini dan status kamar akan disesuaikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _kontrakRead.selesaikan_kontrak_provider(
                kontrakId: widget.kontrakId,
                penyewaId: widget.idPenyewa,
              );
              if (!mounted) return;
              final err = _kontrakRead.ambil_pesan_error();
              if (!ok || err != null) {
                AppSnackbar.error(
                  context,
                  err ?? 'Gagal menyelesaikan kontrak',
                );
                return;
              }
              await _muatAwal();
            },
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }

  Future<void> _batalkanKontrak(Map<String, dynamic> kontrak) async {
    showConfirmDeleteDialog(
      context: context,
      nama: _labelKontrak(kontrak),
      entityLabel: 'kontrak',
      onConfirm: () async {
        final ok = await _kontrakRead.batalkan_kontrak_provider(
          kontrakId: widget.kontrakId,
          penyewaId: widget.idPenyewa,
        );
        if (!mounted) return;
        final err = _kontrakRead.ambil_pesan_error();
        if (!ok || err != null) {
          AppSnackbar.error(context, err ?? 'Gagal membatalkan kontrak');
          return;
        }
        await _muatAwal();
      },
    );
  }

  Future<void> _shareKontrakPdf(Map<String, dynamic> kontrak) async {
    final penyewa = context
        .read<PenyewaProvider>()
        .penyewa_by_id[widget.idPenyewa];
    final kamarId = _kamarId(kontrak);
    final kosId = _kosId(kontrak);
    final kamar = context.read<KamarProvider>().ambil_datasiap_kamar_by_id(
      kamarId,
    );
    final kos = context.read<KosProvider>().ambil_datasiap_kos_by_id(kosId);
    await PdfExportService.sharePdf(
      fileName: PdfHelpers.fileName(
        'detail_kontrak',
        code: '${kontrak['kode_kontrak'] ?? widget.kontrakId}',
      ),
      build: () => KontrakPdf.build(
        kontrak: kontrak,
        penyewa: penyewa,
        namaKos: '${kos?['nama_kos'] ?? ''}',
        nomorKamar:
            '${kamar?['nomor'] ?? kamar?['nama_kamar'] ?? kontrak['kamar_id'] ?? ''}',
      ),
    );
  }

  Future<void> _exportKontrak(Map<String, dynamic> kontrak) async {
    try {
      await _shareKontrakPdf(kontrak);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal export PDF: $e');
    }
  }

  Future<void> _sendKontrakWhatsApp(Map<String, dynamic> kontrak) async {
    if (_sendingKontrakWhatsApp) return;
    setState(() => _sendingKontrakWhatsApp = true);
    try {
      final penyewa = context
          .read<PenyewaProvider>()
          .penyewa_by_id[widget.idPenyewa];
      final kode = '${kontrak['kode_kontrak'] ?? ''}'.trim();
      final token = '${kontrak['public_token'] ?? ''}'.trim();
      if (kode.isEmpty || token.isEmpty) {
        AppSnackbar.error(
          context,
          'Link PDF publik belum tersedia. Muat ulang kontrak.',
        );
        return;
      }

      final kamarId = _kamarId(kontrak);
      final kamar = context.read<KamarProvider>().ambil_datasiap_kamar_by_id(
        kamarId,
      );
      final nomorKamar =
          '${kamar?['nomor'] ?? kamar?['nama_kamar'] ?? kontrak['kamar_id'] ?? '-'}';
      final pdfUrl =
          '${ApiService().publicBaseUrl}/public/kontrak/${Uri.encodeComponent(kode)}/pdf?token=${Uri.encodeQueryComponent(token)}';
      final opened = await WhatsAppDeepLinkService.openChat(
        phoneNumber: penyewa?['no_telpon']?.toString(),
        message: [
          '${WhatsAppDeepLinkService.tenantGreeting(penyewa?['nama']?.toString())}, berikut detail kontrak sewa.',
          '',
          'Nama: ${penyewa?['nama'] ?? '-'}',
          'Kode kontrak: $kode',
          'Kamar: $nomorKamar',
          'Tanggal mulai: ${_tanggal(kontrak['tanggal_mulai'])}',
          'Tanggal selesai: ${_tanggal(kontrak['tanggal_selesai'])}',
          'Harga sewa: ${AppDesign.formatRupiah(kontrak['harga_sewa'])}',
          'Siklus: ${_labelSiklus(kontrak['siklus'])}',
          '',
          'PDF kontrak: $pdfUrl',
        ].join('\n'),
      );
      if (!mounted) return;
      if (opened) {
        AppSnackbar.success(
          context,
          'Chat WhatsApp dibuka dengan link PDF kontrak.',
        );
      } else {
        AppSnackbar.error(
          context,
          'Nomor WhatsApp belum valid atau WhatsApp tidak bisa dibuka.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal menyiapkan kontrak WhatsApp: $error');
    } finally {
      if (mounted) setState(() => _sendingKontrakWhatsApp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kontrakProv = context.watch<KontrakProvider>();
    final tagihanProv = context.watch<TagihanProvider>();
    final kontrak = _kontrak(kontrakProv);
    final tagihanList =
        tagihanProv.data_tagihan_by_kontrak[widget.kontrakId] ?? [];

    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: Center(
          child: AppBackButton(onPressed: () => Navigator.pop(context)),
        ),
        title: Text(
          kontrak == null ? 'Detail Kontrak' : _labelKontrak(kontrak),
        ),
        actions: [
          if (kontrak != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppStatusBadge(
                status: KontrakStatus.normalize(kontrak['status']),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Detail Kontrak'),
            Tab(text: 'Tagihan'),
          ],
        ),
      ),
      body: kontrak == null && kontrakProv.loading
          ? const Center(child: CircularProgressIndicator())
          : kontrak == null
          ? _notFound()
          : TabBarView(
              controller: _tabs,
              children: [
                _buildDetail(kontrak),
                _buildTagihan(kontrak, tagihanList, tagihanProv.loading),
              ],
            ),
    );
  }

  Widget _notFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Kontrak tidak ditemukan',
              textAlign: TextAlign.center,
              style: AppDesign.sectionTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Kembali ke profile penyewa dan coba buka lagi.',
              textAlign: TextAlign.center,
              style: AppDesign.bodyMuted(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(Map<String, dynamic> kontrak) {
    final bolehEdit = KontrakAksiRules.bolehEdit(kontrak);
    final bolehHapus = KontrakAksiRules.bolehHapus(kontrak);
    final bolehSelesai = KontrakAksiRules.bolehSelesaikan(kontrak);
    final kamar = kontrak['kamar'];
    final nomorKamar = kamar is Map
        ? 'Kamar ${kamar['nomor']}'
        : 'Kamar ${kontrak['kamar_id'] ?? '-'}';
    final sisaKontrak = SisaHari.labelKontrak(
      kontrak['tanggal_mulai'],
      kontrak['tanggal_selesai'],
      status: kontrak['status'],
    );

    return RefreshIndicator(
      onRefresh: _muatAwal,
      child: ListView(
        padding: const EdgeInsets.all(AppDesign.spaceMd),
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spaceLg),
            decoration: AppDesign.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Kontrak',
                  style: AppDesign.sectionTitle(context),
                ),
                const SizedBox(height: AppDesign.spaceMd),
                AppInfoRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Kode kontrak',
                  value: _labelKontrak(kontrak),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.meeting_room_outlined,
                  label: 'Kamar',
                  value: nomorKamar,
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tanggal mulai',
                  value: _tanggal(kontrak['tanggal_mulai']),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.event_outlined,
                  label: 'Tanggal selesai',
                  value: _tanggal(kontrak['tanggal_selesai']),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Harga sewa',
                  value: AppDesign.formatRupiah(kontrak['harga_sewa']),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.loop_rounded,
                  label: 'Siklus',
                  value: _labelSiklus(kontrak['siklus']),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.info_outline,
                  label: 'Status',
                  value: KontrakStatus.label(kontrak['status']),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.timer_outlined,
                  label: 'Durasi & sisa',
                  value: sisaKontrak ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesign.spaceMd),
          Row(
            children: [
              Expanded(
                child: AppEntityOutlinedAction(
                  label: 'Edit',
                  icon: Icons.edit_rounded,
                  enabled: bolehEdit,
                  activeColor: AppColors.icon_edit,
                  blockedMessage: KontrakAksiRules.alasanEdit(kontrak),
                  onPressed: () => _editKontrak(kontrak),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppEntityOutlinedAction(
                  label: 'Batalkan',
                  icon: Icons.cancel_outlined,
                  enabled: bolehHapus,
                  activeColor: AppDesign.danger,
                  blockedMessage: KontrakAksiRules.alasanHapus(kontrak),
                  onPressed: () => _batalkanKontrak(kontrak),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppEntityOutlinedAction(
            label: 'Bagikan Kontrak PDF',
            icon: Icons.picture_as_pdf_outlined,
            enabled: true,
            activeColor: AppDesign.info,
            onPressed: () => _exportKontrak(kontrak),
          ),
          const SizedBox(height: 12),
          AppEntityOutlinedAction(
            label: _sendingKontrakWhatsApp
                ? 'Mengirim Kontrak...'
                : 'Kirim Kontrak ke WhatsApp',
            icon: _sendingKontrakWhatsApp
                ? Icons.hourglass_top_rounded
                : Icons.send_outlined,
            enabled: !_sendingKontrakWhatsApp,
            activeColor: AppDesign.info,
            onPressed: () => _sendKontrakWhatsApp(kontrak),
          ),
          const SizedBox(height: 12),
          AppEntityOutlinedAction(
            label: 'Selesaikan kontrak',
            icon: Icons.task_alt_rounded,
            enabled: bolehSelesai,
            activeColor: AppDesign.success,
            blockedMessage: KontrakAksiRules.alasanSelesaikan(kontrak),
            onPressed: () => _selesaikanKontrak(kontrak),
          ),
        ],
      ),
    );
  }

  Widget _buildTagihan(
    Map<String, dynamic> kontrak,
    List<Map<String, dynamic>> tagihanList,
    bool loading,
  ) {
    if (loading && tagihanList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tagihanList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshTagihan,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada tagihan',
              textAlign: TextAlign.center,
              style: AppDesign.sectionTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Tagihan untuk kontrak ini akan tampil di sini.',
              textAlign: TextAlign.center,
              style: AppDesign.bodyMuted(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTagihan,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDesign.spaceMd),
        itemCount: tagihanList.length,
        itemBuilder: (context, index) {
          final tagihan = tagihanList[index];
          final tagihanId = entityId(tagihan['id']);
          if (tagihanId == null) return const SizedBox.shrink();
          return CardTagihan(
            data_tagihan: tagihan,
            tekan: (id) {
              AppNavigation.toTagihanDetail(
                context,
                tagihanId: id,
                penyewaId: widget.idPenyewa,
                idKamar: _kamarId(kontrak),
                idKos: _kosId(kontrak),
                kontrakId: widget.kontrakId,
              );
            },
            onEdit: () async {
              final ok = await AppNavigation.toEditTagihan(
                context,
                tagihanId: tagihanId,
                idPenyewa: widget.idPenyewa,
              );
              if (!mounted || ok != true) return;
              await _refreshTagihan();
            },
            onDelete: () {
              showConfirmDeleteDialog(
                context: context,
                nama: '${tagihan['kode_tagihan'] ?? '#$tagihanId'}',
                entityLabel: 'tagihan',
                onConfirm: () async {
                  await context.read<TagihanProvider>().hapus_tagihan_provider(
                    tagihanId,
                  );
                  if (!mounted) return;
                  await _refreshTagihan();
                },
              );
            },
          );
        },
      ),
    );
  }
}

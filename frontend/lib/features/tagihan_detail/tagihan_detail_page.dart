import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_back_button.dart';
import 'package:kos_management/core/widgets/app_document_action_button.dart';
import 'package:kos_management/core/widgets/app_entity_list_card.dart';
import 'package:kos_management/core/widgets/app_entity_action_controls.dart';
import 'package:kos_management/core/widgets/app_loading_overlay.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/core/widgets/app_form_dialog.dart';
import 'package:kos_management/core/widgets/app_text_field.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/controll/controll_helpers.dart';
import 'package:kos_management/features/export_pdf/pdf_export_service.dart';
import 'package:kos_management/features/export_pdf/pdf_helpers.dart';
import 'package:kos_management/features/export_pdf/tagihan_pdf.dart';
import 'package:kos_management/features/whatsapp/whatsapp_deep_link_service.dart';
import 'package:kos_management/features/penyewa/widget/custom_card_penyewa.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/pembayaran_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/features/tagihan/widget/tagihan_items_list.dart';
import 'package:kos_management/utils/provider_feedback.dart';
import 'package:kos_management/utils/sisa_hari.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';
import 'package:kos_management/utils/tagihan_rules.dart';
import 'package:provider/provider.dart';

class TagihanDetailPage extends StatefulWidget {
  final int tagihanId;
  final int penyewaId;
  final int idKamar;
  final int idKos;
  final int? kontrakId;

  const TagihanDetailPage({
    super.key,
    required this.tagihanId,
    required this.penyewaId,
    required this.idKamar,
    required this.idKos,
    this.kontrakId,
  });

  @override
  State<TagihanDetailPage> createState() => _TagihanDetailPageState();
}

class _TagihanDetailPageState extends State<TagihanDetailPage>
    with ProviderFeedback {
  late PembayaranProvider _payRead;
  late TagihanProvider _tagRead;
  final _jumlahBayar = TextEditingController();
  final _jumlahRefund = TextEditingController();
  bool _sendingInvoiceWhatsApp = false;

  @override
  void initState() {
    super.initState();
    _payRead = context.read<PembayaranProvider>();
    _tagRead = context.read<TagihanProvider>();
    _payRead.addListener(_onPay);
    _tagRead.addListener(_onTag);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final penyewaProv = context.read<PenyewaProvider>();
      final kamarProv = context.read<KamarProvider>();
      final kosProv = context.read<KosProvider>();
      await kosProv.ambil_or_update_data();
      await kamarProv.ambil_data_kamar_provider(widget.idKos);
      await penyewaProv.ambil_data_penyewa_provider(widget.idKamar);
      await _muatTagihan();
      if (!mounted) return;
      await _payRead.ambil_data_pembayaran_provider(widget.tagihanId);
    });
  }

  void _onPay() {
    listenProviderErrors(
      readError: _payRead.ambil_pesan_error,
      readSuccess: _payRead.ambil_pesan_sukses,
    );
  }

  void _onTag() {
    listenProviderErrors(
      readError: _tagRead.ambil_pesan_error,
      readSuccess: _tagRead.ambil_pesan_sukses,
    );
  }

  @override
  void dispose() {
    _payRead.removeListener(_onPay);
    _tagRead.removeListener(_onTag);
    _jumlahBayar.dispose();
    _jumlahRefund.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _tagihan(TagihanProvider p) =>
      p.ambil_datasiap_tagihan_by_id(widget.tagihanId);

  Future<void> _muatTagihan({bool force = false}) {
    final kontrakId = widget.kontrakId;
    if (kontrakId != null) {
      return _tagRead.ambil_tagihan_by_kontrak_provider(
        kontrakId,
        penyewa_id: widget.penyewaId,
        force: force,
      );
    }
    return _tagRead.ambil_data_tagihan_provider(widget.penyewaId);
  }

  Future<void> _tambahPembayaran() async {
    final jumlah = int.tryParse(_jumlahBayar.text.replaceAll('.', ''));
    if (jumlah == null || jumlah <= 0) {
      AppSnackbar.error(context, 'Jumlah bayar tidak valid');
      return;
    }
    await _payRead.buat_pembayaran_provider(
      widget.tagihanId,
      jumlah,
      kos_id: widget.idKos,
    );
    _jumlahBayar.clear();
    _tagRead.ubah_status_flag_true(widget.penyewaId);
    await _muatTagihan(force: true);
  }

  Future<void> _refund(int pembayaranId) async {
    final jumlah = int.tryParse(_jumlahRefund.text.replaceAll('.', ''));
    if (jumlah == null || jumlah <= 0) {
      AppSnackbar.error(context, 'Jumlah refund tidak valid');
      return;
    }
    await _payRead.buat_refund_pembayaran_provider(
      pembayaranId,
      widget.tagihanId,
      jumlah_refund: jumlah,
      kos_id: widget.idKos,
    );
    _jumlahRefund.clear();
    _tagRead.ubah_status_flag_true(widget.penyewaId);
    await _muatTagihan(force: true);
  }

  Future<void> _shareInvoicePdf(
    Map<String, dynamic> tagihan,
    List<Map<String, dynamic>> payments,
  ) async {
    final penyewaProv = context.read<PenyewaProvider>();
    final penyewa = penyewaProv.penyewa_by_id[widget.penyewaId];
    final lokasi = ControllHelpers.labelKonteksPenyewa(
      penyewa: penyewaProv,
      kamar: context.read<KamarProvider>(),
      kos: context.read<KosProvider>(),
      penyewaId: widget.penyewaId,
    );
    await PdfExportService.sharePdf(
      fileName: PdfHelpers.fileName(
        'invoice_tagihan',
        code: '${tagihan['kode_tagihan'] ?? widget.tagihanId}',
      ),
      build: () => TagihanPdf.build(
        tagihan: tagihan,
        penyewa: penyewa,
        pembayaran: payments,
        lokasi: lokasi,
      ),
    );
  }

  Future<void> _exportInvoice(
    Map<String, dynamic> tagihan,
    List<Map<String, dynamic>> payments,
  ) async {
    try {
      await _shareInvoicePdf(tagihan, payments);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal export PDF: $e');
    }
  }

  Future<void> _sendInvoiceWhatsApp(
    Map<String, dynamic> tagihan,
    List<Map<String, dynamic>> payments,
  ) async {
    if (_sendingInvoiceWhatsApp) return;
    setState(() => _sendingInvoiceWhatsApp = true);
    try {
      await _shareInvoicePdf(tagihan, payments);
      if (!mounted) return;

      final penyewa = context
          .read<PenyewaProvider>()
          .penyewa_by_id[widget.penyewaId];
      final kode = '${tagihan['kode_tagihan'] ?? widget.tagihanId}'.trim();
      final opened = await WhatsAppDeepLinkService.openChat(
        phoneNumber: penyewa?['no_telpon']?.toString(),
        message:
            '${WhatsAppDeepLinkService.tenantGreeting(penyewa?['nama']?.toString())}, berikut invoice tagihan $kode.',
      );
      if (!mounted) return;
      if (opened) {
        AppSnackbar.success(
          context,
          'PDF invoice siap dibagikan dan chat WhatsApp dibuka.',
        );
      } else {
        AppSnackbar.error(
          context,
          'Nomor WhatsApp belum valid atau WhatsApp tidak bisa dibuka.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal menyiapkan invoice WhatsApp: $error');
    } finally {
      if (mounted) setState(() => _sendingInvoiceWhatsApp = false);
    }
  }

  void _dialogBayar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radiusMd),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDesign.spaceMd,
          right: AppDesign.spaceMd,
          top: AppDesign.spaceLg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDesign.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah Pembayaran', style: AppDesign.titleBold(ctx)),
            Text(
              'Masukkan nominal yang diterima sekarang (boleh cicilan).',
              style: AppDesign.bodyMuted(ctx),
            ),
            const SizedBox(height: AppDesign.spaceMd),
            AppTextField(
              label: 'Jumlah bayar (Rp)',
              hint: '500000',
              helperText: AppFormHints.rupiah,
              required: true,
              controller: _jumlahBayar,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppDesign.spaceMd),
            AppPrimaryButton(
              label: 'Simpan',
              onPressed: () async {
                Navigator.pop(ctx);
                await _tambahPembayaran();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _dialogRefund(int pembayaranId, int maxRefund) {
    _jumlahRefund.text = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radiusMd),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDesign.spaceMd,
          right: AppDesign.spaceMd,
          top: AppDesign.spaceLg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDesign.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Refund Pembayaran', style: AppDesign.titleBold(ctx)),
            Text(
              'Maksimal yang bisa direfund: ${AppDesign.formatRupiah(maxRefund)}',
              style: AppDesign.bodyMuted(ctx),
            ),
            const SizedBox(height: AppDesign.spaceMd),
            AppTextField(
              label: 'Jumlah refund (Rp)',
              hint: '100000',
              helperText: AppFormHints.rupiah,
              required: true,
              controller: _jumlahRefund,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppDesign.spaceMd),
            AppPrimaryButton(
              label: 'Proses Refund',
              outlined: true,
              onPressed: () async {
                Navigator.pop(ctx);
                await _refund(pembayaranId);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagihanProv = context.watch<TagihanProvider>();
    final payProv = context.watch<PembayaranProvider>();
    final tagihan = _tagihan(tagihanProv);
    final payments = payProv.data_pembayaran[widget.tagihanId] ?? [];
    final sisaTempo = SisaHari.labelJatuhTempo(
      tagihan?['jatuh_tempo'],
      lifecycle: tagihan?['lifecycle'],
      statusPembayaran: tagihan?['status_pembayaran'],
    );

    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Center(
          child: AppBackButton(onPressed: () => Navigator.pop(context)),
        ),
        centerTitle: false,
        leadingWidth: 56,
        title: const Text('Detail Tagihan'),
        actions: [
          if (tagihan != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppEntityIconAction(
                icon: Icons.edit_rounded,
                enabled: EntityActionRules.bolehEditTagihan(tagihan),
                activeColor: AppDesign.info,
                filled: false,
                blockedMessage: EntityActionRules.pesanEditTagihan(tagihan),
                onPressed: () async {
                  final ok = await AppNavigation.toEditTagihan(
                    context,
                    tagihanId: widget.tagihanId,
                    idPenyewa: widget.penyewaId,
                  );
                  if (ok == true && mounted) {
                    await _muatTagihan(force: true);
                  }
                },
              ),
            ),
        ],
      ),
      body: AppLoadingOverlay(
        loading: tagihanProv.loading || payProv.loading,
        child: tagihan == null
            ? Center(
                child: (tagihanProv.loading || payProv.loading)
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(AppDesign.spaceLg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: AppDesign.spaceMd),
                            Text(
                              'Tagihan tidak ditemukan',
                              style: AppDesign.sectionTitle(context),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDesign.spaceSm),
                            Text(
                              'Muat ulang dari daftar tagihan penyewa.',
                              style: AppDesign.bodyMuted(context),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppDesign.spaceMd),
                children: [
                  _buildPenyewaContext(context),
                  const SizedBox(height: AppDesign.spaceMd),
                  Container(
                    padding: const EdgeInsets.all(AppDesign.spaceLg),
                    decoration: AppDesign.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tagihan['kode_tagihan']?.toString() ??
                                    'Tagihan',
                                style: AppDesign.sectionTitle(context),
                              ),
                            ),
                            AppStatusBadge(
                              status: TagihanRules.badgeStatus(tagihan),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDesign.spaceMd),
                        _row(
                          'Total tagihan',
                          AppDesign.formatRupiah(tagihan['total_tagihan']),
                        ),
                        _row(
                          'Sudah dibayar',
                          AppDesign.formatRupiah(tagihan['total_dibayar'] ?? 0),
                        ),
                        _row(
                          'Sisa',
                          AppDesign.formatRupiah(
                            (int.tryParse('${tagihan['total_tagihan']}') ?? 0) -
                                (int.tryParse('${tagihan['total_dibayar']}') ??
                                    0),
                          ),
                        ),
                        _row(
                          'Jatuh tempo',
                          '${tagihan['jatuh_tempo'] ?? '-'}'.split('T').first,
                        ),
                        if (sisaTempo != null)
                          _row('Sisa jatuh tempo', sisaTempo),
                        _row(
                          'Periode',
                          '${'${tagihan['periode_awal'] ?? ''}'.split('T').first} — ${'${tagihan['periode_akhir'] ?? ''}'.split('T').first}',
                        ),
                        if ('${tagihan['catatan'] ?? ''}'.trim().isNotEmpty)
                          _row('Catatan', '${tagihan['catatan']}'),
                        const SizedBox(height: AppDesign.spaceLg),
                        Text(
                          'Rincian item',
                          style: AppDesign.titleBold(context),
                        ),
                        const SizedBox(height: AppDesign.spaceSm),
                        TagihanItemsList(items: tagihan['items'] ?? []),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total: ${AppDesign.formatRupiah(TagihanItemUtils.hitungTotal(TagihanItemUtils.parseItems(tagihan['items'])))}',
                              style: AppDesign.bodyMuted(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceMd),
                        AppDocumentActionButton(
                          label: 'Bagikan Invoice PDF',
                          icon: Icons.picture_as_pdf_outlined,
                          filled: true,
                          onPressed: () => _exportInvoice(tagihan, payments),
                        ),
                        const SizedBox(height: AppDesign.spaceSm),
                        AppDocumentActionButton(
                          label: _sendingInvoiceWhatsApp
                              ? 'Mengirim Invoice...'
                              : 'Kirim Invoice ke WhatsApp',
                          icon: _sendingInvoiceWhatsApp
                              ? Icons.hourglass_top_rounded
                              : Icons.send_outlined,
                          onPressed: _sendingInvoiceWhatsApp
                              ? null
                              : () => _sendInvoiceWhatsApp(tagihan, payments),
                        ),
                        const SizedBox(height: AppDesign.spaceSm),
                        AppPrimaryButton(
                          label: 'Tambah Pembayaran',
                          icon: Icons.add_card_rounded,
                          onPressed: _dialogBayar,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDesign.spaceLg),
                  Text(
                    'Riwayat Pembayaran',
                    style: AppDesign.titleBold(context),
                  ),
                  const SizedBox(height: AppDesign.spaceSm),
                  if (payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppDesign.spaceMd),
                      child: Text(
                        'Belum ada pembayaran',
                        style: AppDesign.bodyMuted(context),
                      ),
                    )
                  else
                    ...payments.map((p) {
                      final id = int.tryParse('${p['id']}') ?? 0;
                      if (id == 0) return const SizedBox.shrink();
                      final status = '${p['status']}';
                      final isValid = status == 'valid';
                      return InkWell(
                        onTap: () => AppNavigation.toPembayaranDetail(
                          context,
                          pembayaran: Map<String, dynamic>.from(p),
                          tagihan: tagihan,
                          penyewaId: widget.penyewaId,
                          idKamar: widget.idKamar,
                          idKos: widget.idKos,
                        ),
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: AppDesign.spaceSm,
                          ),
                          padding: const EdgeInsets.all(AppDesign.spaceMd),
                          decoration: AppDesign.cardDecoration(),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppDesign.formatRupiah(p['jumlah_bayar']),
                                      style: AppDesign.titleBold(context),
                                    ),
                                    Text(
                                      '${p['dibuat_pada'] ?? ''}',
                                      style: AppDesign.bodyMuted(context),
                                    ),
                                  ],
                                ),
                              ),
                              AppStatusBadge(status: status),
                              if (isValid)
                                TextButton(
                                  onPressed: () => _dialogRefund(
                                    id,
                                    (p['jumlah_bayar'] as num?)?.toInt() ?? 0,
                                  ),
                                  child: const Text('Refund'),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _buildPenyewaContext(BuildContext context) {
    final penyewaProv = context.watch<PenyewaProvider>();
    final loading = penyewaProv.loading;
    final penyewa = penyewaProv.penyewa_by_id[widget.penyewaId];

    if (penyewa == null) {
      return AppEntityListCard(
        entityLabel: 'PENGHUNI',
        title: loading ? 'Memuat penyewa…' : 'Data penyewa tidak ditemukan',
        accentColor: AppDesign.info,
        placeholderIcon: Icons.person_rounded,
        status: 'aktif',
        lines: [
          AppEntityListLine(
            icon: Icons.info_outline,
            text: loading
                ? 'Mohon tunggu sebentar'
                : 'Kembali ke daftar dan coba lagi',
          ),
        ],
        onTap: () {},
        canEdit: false,
        canDelete: false,
      );
    }

    final lokasi = ControllHelpers.labelKonteksPenyewa(
      penyewa: penyewaProv,
      kamar: context.read<KamarProvider>(),
      kos: context.read<KosProvider>(),
      penyewaId: widget.penyewaId,
    );

    return CardPenyewa.konteks(
      item: penyewa,
      lokasi: lokasi,
      onTap: () => AppNavigation.toPenyewaDetail(
        context,
        idPenyewa: widget.penyewaId,
        idKamar: widget.idKamar,
        idKos: widget.idKos,
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spaceSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppDesign.bodyMuted(context)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

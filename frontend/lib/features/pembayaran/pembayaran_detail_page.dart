import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_back_button.dart';
import 'package:kos_management/core/widgets/app_entity_action_controls.dart';
import 'package:kos_management/core/widgets/app_entity_list_card.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/core/widgets/app_text_field.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/controll/controll_helpers.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/pembayaran_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:provider/provider.dart';

class PembayaranDetailPage extends StatefulWidget {
  final Map<String, dynamic> pembayaran;
  final Map<String, dynamic>? initialTagihan;
  final int? penyewaId;
  final int? idKamar;
  final int? idKos;

  const PembayaranDetailPage({
    super.key,
    required this.pembayaran,
    this.initialTagihan,
    this.penyewaId,
    this.idKamar,
    this.idKos,
  });

  @override
  State<PembayaranDetailPage> createState() => _PembayaranDetailPageState();
}

class _PembayaranDetailPageState extends State<PembayaranDetailPage> {
  final _jumlahRefund = TextEditingController();

  @override
  void dispose() {
    _jumlahRefund.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _pembayaran =>
      Map<String, dynamic>.from(widget.pembayaran);

  int? get _pembayaranId => entityId(_pembayaran['id']);

  int? get _tagihanId =>
      entityId(_pembayaran['tagihan_id']) ??
      entityId(widget.initialTagihan?['id']);

  int? _resolvePenyewaId(Map<String, dynamic>? tagihan) =>
      widget.penyewaId ?? entityId(tagihan?['penyewa_id']);

  int? _resolveKamarId(BuildContext context, int? penyewaId) {
    if (widget.idKamar != null) return widget.idKamar;
    if (penyewaId == null) return null;
    return ControllHelpers.kamarIdForPenyewa(
      context.read<PenyewaProvider>(),
      penyewaId,
    );
  }

  int? _resolveKosId(BuildContext context, int? kamarId) {
    if (widget.idKos != null) return widget.idKos;
    return ControllHelpers.kosIdForKamar(
      context.read<KamarProvider>(),
      kamarId,
    );
  }

  Map<String, dynamic>? _tagihan(TagihanProvider provider) {
    final id = _tagihanId;
    if (id == null) return widget.initialTagihan;
    return provider.tagihan_by_id[id] ??
        provider.semua_data_tagihan[id] ??
        widget.initialTagihan;
  }

  String _tanggal(dynamic value) {
    final raw = '${value ?? ''}'.trim();
    if (raw.isEmpty || raw == 'null') return '-';
    return raw.replaceFirst('T', ' ').split('.').first;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'refund':
        return 'Pengembalian dana';
      case 'valid':
        return 'Pembayaran valid';
      default:
        return status;
    }
  }

  void _bukaTagihan(Map<String, dynamic>? tagihan) {
    final tagihanId = _tagihanId;
    final penyewaId = _resolvePenyewaId(tagihan);
    final kamarId = _resolveKamarId(context, penyewaId);
    final kosId = _resolveKosId(context, kamarId);
    if (tagihanId == null ||
        penyewaId == null ||
        kamarId == null ||
        kosId == null) {
      return;
    }

    AppNavigation.toTagihanDetail(
      context,
      tagihanId: tagihanId,
      penyewaId: penyewaId,
      idKamar: kamarId,
      idKos: kosId,
      kontrakId: entityId(tagihan?['kontrak_id']),
    );
  }

  List<Map<String, dynamic>> _pembayaranTagihan(PembayaranProvider provider) {
    final id = _tagihanId;
    if (id == null) return const [];
    return provider.data_pembayaran[id] ?? const [];
  }

  Future<void> _refundPembayaran({
    required int pembayaranId,
    required int tagihanId,
    required int jumlahRefund,
  }) async {
    final kosId = _resolveKosId(
      context,
      _resolveKamarId(
        context,
        _resolvePenyewaId(_tagihan(context.read<TagihanProvider>())),
      ),
    );
    final provider = context.read<PembayaranProvider>();
    await provider.buat_refund_pembayaran_provider(
      pembayaranId,
      tagihanId,
      jumlah_refund: jumlahRefund,
      kos_id: kosId,
    );
    if (!mounted) return;
    final err = provider.ambil_pesan_error();
    if (err != null) {
      AppSnackbar.error(context, err);
      return;
    }
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Refund berhasil diproses',
    );
  }

  void _dialogRefund(int pembayaranId, int tagihanId, int maxRefund) {
    _jumlahRefund.clear();
    showModalBottomSheet<void>(
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
              'Maksimal refund: ${AppDesign.formatRupiah(maxRefund)}',
              style: AppDesign.bodyMuted(ctx),
            ),
            const SizedBox(height: AppDesign.spaceMd),
            AppTextField(
              label: 'Jumlah refund (Rp)',
              hint: '$maxRefund',
              required: true,
              controller: _jumlahRefund,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppDesign.spaceMd),
            AppPrimaryButton(
              label: 'Proses Refund',
              icon: Icons.replay_rounded,
              outlined: true,
              onPressed: () async {
                final jumlah = int.tryParse(
                  _jumlahRefund.text.replaceAll('.', ''),
                );
                if (jumlah == null || jumlah <= 0) {
                  AppSnackbar.error(context, 'Jumlah refund tidak valid');
                  return;
                }
                if (jumlah > maxRefund) {
                  AppSnackbar.error(
                    context,
                    'Maksimal refund ${AppDesign.formatRupiah(maxRefund)}',
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _refundPembayaran(
                  pembayaranId: pembayaranId,
                  tagihanId: tagihanId,
                  jumlahRefund: jumlah,
                );
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
    final pembayaranProv = context.watch<PembayaranProvider>();
    final pembayaran = _pembayaran;
    final tagihan = _tagihan(tagihanProv);
    final status = '${pembayaran['status'] ?? 'valid'}';
    final jumlah = int.tryParse('${pembayaran['jumlah_bayar']}') ?? 0;
    final semuaPembayaranTagihan = _pembayaranTagihan(pembayaranProv);
    final sisaRefund = EntityActionRules.sisaRefundPembayaran(
      pembayaran,
      semuaPembayaranTagihan,
    );
    final bolehRefund = EntityActionRules.bolehRefundPembayaran(
      pembayaran,
      tagihan: tagihan,
      semuaPembayaranTagihan: semuaPembayaranTagihan,
    );
    final pesanRefund = EntityActionRules.pesanRefundPembayaran(
      pembayaran,
      tagihan: tagihan,
      semuaPembayaranTagihan: semuaPembayaranTagihan,
    );
    final penyewaId = _resolvePenyewaId(tagihan);
    final konteks = penyewaId == null
        ? null
        : ControllHelpers.labelKonteksPenyewa(
            penyewa: context.watch<PenyewaProvider>(),
            kamar: context.watch<KamarProvider>(),
            kos: context.watch<KosProvider>(),
            penyewaId: penyewaId,
          );
    final kodeTagihan = '${tagihan?['kode_tagihan'] ?? ''}'.trim();
    final title = kodeTagihan.isEmpty
        ? 'Pembayaran #${_pembayaranId ?? '-'}'
        : kodeTagihan;

    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Center(
          child: AppBackButton(onPressed: () => Navigator.pop(context)),
        ),
        leadingWidth: 56,
        title: const Text('Detail Pembayaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDesign.spaceMd),
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spaceLg),
            decoration: AppDesign.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color:
                            (status == 'refund'
                                    ? AppDesign.danger
                                    : AppDesign.success)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                      ),
                      child: Icon(
                        status == 'refund'
                            ? Icons.replay_rounded
                            : Icons.payments_rounded,
                        color: status == 'refund'
                            ? AppDesign.danger
                            : AppDesign.success,
                      ),
                    ),
                    const SizedBox(width: AppDesign.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppDesign.sectionTitle(context)),
                          const SizedBox(height: AppDesign.spaceXs),
                          Text(
                            _statusLabel(status),
                            style: AppDesign.bodyMuted(context),
                          ),
                        ],
                      ),
                    ),
                    AppStatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: AppDesign.spaceLg),
                Text(
                  AppDesign.formatRupiah(jumlah),
                  style: AppDesign.sectionTitle(context).copyWith(fontSize: 28),
                ),
                const SizedBox(height: AppDesign.spaceMd),
                _infoRow('ID pembayaran', '${_pembayaranId ?? '-'}'),
                _infoRow('Tanggal dibuat', _tanggal(pembayaran['dibuat_pada'])),
                _infoRow('ID tagihan', '${_tagihanId ?? '-'}'),
                if (entityId(pembayaran['pembayaran_ref_id']) != null)
                  _infoRow(
                    'Refund dari pembayaran',
                    '#${entityId(pembayaran['pembayaran_ref_id'])}',
                  ),
                if (status == 'valid')
                  _infoRow(
                    'Sisa bisa direfund',
                    AppDesign.formatRupiah(sisaRefund),
                  ),
                if ('${pembayaran['dibatalkan_pada'] ?? ''}'.trim().isNotEmpty)
                  _infoRow(
                    'Dibatalkan pada',
                    _tanggal(pembayaran['dibatalkan_pada']),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDesign.spaceMd),
          AppEntityListCard(
            entityLabel: 'TAGIHAN',
            title: kodeTagihan.isEmpty
                ? 'Tagihan #${_tagihanId ?? '-'}'
                : kodeTagihan,
            accentColor: AppDesign.info,
            placeholderIcon: Icons.receipt_long_rounded,
            status: '${tagihan?['status_pembayaran'] ?? 'valid'}',
            lines: [
              if (konteks != null && konteks.trim().isNotEmpty)
                AppEntityListLine(
                  icon: Icons.person_outline,
                  text: konteks.trim(),
                ),
              AppEntityListLine(
                icon: Icons.event_outlined,
                text:
                    'Jatuh tempo ${_tanggal(tagihan?['jatuh_tempo']).split(' ').first}',
              ),
            ],
            onTap: () => _bukaTagihan(tagihan),
            canEdit: false,
            canDelete: false,
          ),
          const SizedBox(height: AppDesign.spaceMd),
          AppEntityOutlinedAction(
            label: 'Refund Pembayaran',
            icon: Icons.replay_rounded,
            enabled: bolehRefund,
            activeColor: AppDesign.danger,
            blockedMessage: pesanRefund,
            onPressed: _pembayaranId == null || _tagihanId == null
                ? null
                : () => _dialogRefund(_pembayaranId!, _tagihanId!, sisaRefund),
          ),
          const SizedBox(height: AppDesign.spaceSm),
          AppPrimaryButton(
            label: 'Buka Detail Tagihan',
            icon: Icons.receipt_long_rounded,
            onPressed: _tagihanId == null ? null : () => _bukaTagihan(tagihan),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppDesign.bodyMuted(context))),
          const SizedBox(width: AppDesign.spaceMd),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

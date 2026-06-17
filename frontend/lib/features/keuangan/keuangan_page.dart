import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_empty_state.dart';
import 'package:kos_management/core/widgets/app_page_scaffold.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/export_pdf/laporan_keuangan_pdf.dart';
import 'package:kos_management/features/export_pdf/pdf_export_service.dart';
import 'package:kos_management/features/export_pdf/pdf_helpers.dart';
import 'package:kos_management/features/keuangan/models/laporan_data.dart';
import 'package:kos_management/features/keuangan/utils/bulan_periode.dart';
import 'package:kos_management/features/keuangan/widgets/keuangan_filter_panel.dart';
import 'package:kos_management/features/keuangan/widgets/keuangan_laporan_section.dart';
import 'package:kos_management/features/keuangan/widgets/keuangan_ringkasan_banner.dart';
import 'package:kos_management/features/keuangan/widgets/keuangan_share_section.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/laporan_keuangan_provider.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/laporan_service.dart';
import 'package:provider/provider.dart';

class KeuanganPage extends StatefulWidget {
  const KeuanganPage({super.key});

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage> {
  final LaporanService _laporanApi = LaporanService(ApiService());
  LaporanKeuanganProvider? _laporanRefresh;

  late String _bulanMulai;
  late String _bulanAkhir;
  Set<int> _kosTerpilih = {};

  bool _loading = false;
  bool _reloadPending = false;
  int _muatLaporanSeq = 0;
  String? _error;

  LaporanKeuanganData _keuangan = LaporanKeuanganData.kosong;
  LaporanTagihanData _tagihan = LaporanTagihanData.kosong;

  @override
  void initState() {
    super.initState();
    _bulanMulai = BulanPeriode.bulanIni();
    _bulanAkhir = _bulanMulai;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final refresh = context.read<LaporanKeuanganProvider>();
      _laporanRefresh = refresh;
      refresh.addListener(_onPerluMuatUlang);
      _initMuat();
    });
  }

  @override
  void dispose() {
    _laporanRefresh?.removeListener(_onPerluMuatUlang);
    super.dispose();
  }

  void _onPerluMuatUlang() {
    final laporan = _laporanRefresh;
    if (!mounted || laporan == null || !laporan.perlu_muat_ulang) {
      return;
    }
    if (_loading) {
      _reloadPending = true;
      return;
    }
    _muatLaporan();
  }

  Future<void> _initMuat() async {
    final kosProvider = context.read<KosProvider>();
    if (kosProvider.data_kos.isEmpty && !kosProvider.loading) {
      await kosProvider.ambil_data_kos_provider();
    }
    await _muatLaporan();
  }

  List<int>? get _kosIdsQuery =>
      _kosTerpilih.isEmpty ? null : _kosTerpilih.toList();

  String get _periodeLabel {
    if (_keuangan.labelPeriode != null && _keuangan.labelPeriode!.isNotEmpty) {
      return _keuangan.labelPeriode!;
    }
    final mulai = BulanPeriode.labelDari(_bulanMulai);
    final akhir = BulanPeriode.labelDari(_bulanAkhir);
    if (mulai == akhir) return mulai;
    return '$mulai – $akhir';
  }

  bool get _kosong =>
      !_loading &&
      _error == null &&
      _keuangan.totalUangMasuk == 0 &&
      _tagihan.totalTagihan == 0;

  Future<void> _muatLaporan() async {
    _reloadPending = false;
    final seq = ++_muatLaporanSeq;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _laporanApi.ambilLaporanKeuangan(
          bulanMulai: _bulanMulai,
          bulanAkhir: _bulanAkhir,
          kosIds: _kosIdsQuery,
        ),
        _laporanApi.ambilLaporanTagihan(
          bulanMulai: _bulanMulai,
          bulanAkhir: _bulanAkhir,
          kosIds: _kosIdsQuery,
        ),
      ]);

      if (!mounted || seq != _muatLaporanSeq) return;

      setState(() {
        _keuangan = LaporanKeuanganData.fromResponse(results[0]);
        _tagihan = LaporanTagihanData.fromResponse(results[1]);
        _loading = false;
      });
      if (mounted) {
        context.read<LaporanKeuanganProvider>().selesai_muat_ulang();
      }
    } catch (e) {
      if (!mounted || seq != _muatLaporanSeq) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _keuangan = LaporanKeuanganData.kosong;
        _tagihan = LaporanTagihanData.kosong;
      });
      context.read<LaporanKeuanganProvider>().selesai_muat_ulang();
    } finally {
      if (!mounted) return;
      final laporan = _laporanRefresh;
      if (_reloadPending &&
          laporan != null &&
          laporan.perlu_muat_ulang &&
          !_loading) {
        await _muatLaporan();
      }
    }
  }

  void _onFilterBerubah() {
    _muatLaporan();
  }

  String _filterKosLabel(List<Map<String, dynamic>> daftarKos) {
    if (_kosTerpilih.isEmpty) return 'Semua kos';
    final names = daftarKos
        .where((kos) => _kosTerpilih.contains(int.tryParse('${kos['id']}')))
        .map((kos) => '${kos['nama_kos'] ?? kos['nama'] ?? kos['id']}')
        .toList();
    return names.isEmpty
        ? '${_kosTerpilih.length} kos dipilih'
        : names.join(', ');
  }

  Future<void> _exportLaporanKeuangan(
    List<Map<String, dynamic>> daftarKos,
  ) async {
    try {
      await PdfExportService.sharePdf(
        fileName: PdfHelpers.fileName('laporan_keuangan', code: _bulanMulai),
        build: () => LaporanKeuanganPdf.build(
          periode: _periodeLabel,
          keuangan: _keuangan,
          tagihan: _tagihan,
          filterKos: _filterKosLabel(daftarKos),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal export PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kosProvider = context.watch<KosProvider>();
    final k = _keuangan;
    final t = _tagihan;

    return AppPageScaffold(
      title: 'Laporan Keuangan',
      subtitle: _periodeLabel,
      body: RefreshIndicator(
        onRefresh: _muatLaporan,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppDesign.spaceMd,
            AppDesign.spaceSm,
            AppDesign.spaceMd,
            AppDesign.spaceXl,
          ),
          children: [
            if (!_loading && _error == null) ...[
              const SizedBox(height: AppDesign.spaceMd),
              KeuanganRingkasanBanner(
                uangMasuk: AppDesign.formatRupiah(k.totalUangBersih),
                sisaTagihan: AppDesign.formatRupiah(k.totalYangSisa),
                jumlahPembayaranValid: k.valid.jumlah,
                jumlahTagihan: t.totalTagihan,
                bayaranBulanDepan: k.totalBayarTagihanBulanDepan > 0
                    ? AppDesign.formatRupiah(k.totalBayarTagihanBulanDepan)
                    : null,
              ),
            ],
            const SizedBox(height: AppDesign.spaceMd),
            KeuanganFilterPanel(
              bulanMulai: _bulanMulai,
              bulanAkhir: _bulanAkhir,
              onMulai: (v) {
                setState(() => _bulanMulai = v);
                _onFilterBerubah();
              },
              onAkhir: (v) {
                setState(() => _bulanAkhir = v);
                _onFilterBerubah();
              },
              daftarKos: kosProvider.data_kos,
              kosTerpilih: _kosTerpilih,
              onKosChanged: (ids) {
                setState(() => _kosTerpilih = ids);
                _onFilterBerubah();
              },
            ),
            if (_loading) ...[
              const SizedBox(height: AppDesign.spaceLg),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppDesign.spaceMd),
              _ErrorCard(pesan: _error!, onCobaLagi: _muatLaporan),
            ],
            if (!_loading && _error == null) ...[
              if (_kosong) ...[
                const SizedBox(height: AppDesign.spaceLg),
                AppEmptyState(
                  icon: Icons.analytics_outlined,
                  title: 'Belum ada data',
                  message:
                      'Tidak ada tagihan jatuh tempo atau pembayaran pada periode ini.',
                ),
              ] else ...[
                const SizedBox(height: AppDesign.spaceMd),
                KeuanganLaporanSection(
                  title: 'Detail keuangan',
                  icon: Icons.account_balance_wallet_outlined,
                  baris: [
                    KeuanganLaporanBaris(
                      label: 'Uang bersih',
                      nilai: AppDesign.formatRupiah(k.totalUangBersih),
                      tebal: true,
                      warnaNilai: AppDesign.success,
                      icon: Icons.savings_outlined,
                      subtitle: 'Yang benar-benar diterima (valid − refund)',
                    ),
                    KeuanganLaporanBaris(
                      label: 'Pembayaran valid',
                      nilai: AppDesign.formatRupiah(k.totalUangMasuk),
                      warnaNilai: AppDesign.success,
                      icon: Icons.south_west_rounded,
                      subtitle: 'Total uang masuk (sebelum refund)',
                    ),
                    KeuanganLaporanBaris(
                      label: 'Refund pembayaran',
                      nilai: '${AppDesign.formatRupiah(k.refund.nominal)}',
                      warnaNilai: AppDesign.danger,
                      icon: Icons.replay_rounded,
                      subtitle: 'Total pengembalian pembayaran',
                    ),
                    KeuanganLaporanBaris(
                      label: 'Untuk tagihan periode ini',
                      nilai: AppDesign.formatRupiah(
                        k.totalBayarTagihanMasaPeriode,
                      ),
                      warnaNilai: AppDesign.info,
                      icon: Icons.event_available_outlined,
                      subtitle: 'Jatuh tempo di periode ini',
                    ),
                    KeuanganLaporanBaris(
                      label: 'Bayar di muka',
                      nilai: AppDesign.formatRupiah(
                        k.totalBayarTagihanBulanDepan,
                      ),
                      warnaNilai: const Color(0xFF7C3AED),
                      icon: Icons.fast_forward_outlined,
                      subtitle: 'Untuk tagihan jatuh tempo bulan depan',
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spaceMd),
                KeuanganLaporanSection(
                  title: 'Tagihan',
                  icon: Icons.receipt_long_outlined,
                  baris: [
                    KeuanganLaporanBaris(
                      label: 'Total tagihan',
                      nilai:
                          '${t.totalTagihan} · ${AppDesign.formatRupiah(t.totalNominalPenuh)}',
                      tebal: true,
                      icon: Icons.summarize_outlined,
                      subtitle: 'Jatuh tempo di periode · nominal penuh',
                    ),
                    KeuanganLaporanBaris(
                      label: 'Sisa tagihan',
                      nilai: AppDesign.formatRupiah(k.totalYangSisa),
                      tebal: true,
                      warnaNilai: AppDesign.warning,
                      icon: Icons.account_balance_outlined,
                      subtitle: 'Belum dibayar (total − uang masuk)',
                    ),
                    KeuanganLaporanBaris(
                      label: 'Lunas',
                      nilai:
                          '${t.lunas.jumlah} · ${AppDesign.formatRupiah(t.lunas.nominal)}',
                      warnaNilai: AppDesign.success,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    KeuanganLaporanBaris(
                      label: 'Sebagian',
                      nilai:
                          '${t.sebagian.jumlah} · ${AppDesign.formatRupiah(t.sebagian.nominal)}',
                      warnaNilai: const Color(0xFFEA580C),
                      icon: Icons.pie_chart_outline_rounded,
                    ),
                    KeuanganLaporanBaris(
                      label: 'Belum bayar',
                      nilai:
                          '${t.belumBayar.jumlah} · ${AppDesign.formatRupiah(t.belumBayar.nominal)}',
                      warnaNilai: AppDesign.warning,
                      icon: Icons.schedule_rounded,
                    ),
                    KeuanganLaporanBaris(
                      label: 'Telat',
                      nilai:
                          '${t.telat.jumlah} · ${AppDesign.formatRupiah(t.telat.nominal)}',
                      warnaNilai: AppDesign.danger,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spaceMd),
                KeuanganLaporanSection(
                  title: 'Transaksi',
                  icon: Icons.swap_horiz_rounded,
                  baris: [
                    KeuanganLaporanBaris(
                      label: 'Total Transaksi',
                      nilai:
                          '${k.totalPembayaran} · ${AppDesign.formatRupiah(k.totalNominalTransansaksi)}',
                      tebal: true,
                      icon: Icons.payments_outlined,
                      subtitle: 'Berdasarkan tanggal bayar',
                    ),
                    KeuanganLaporanBaris(
                      label: 'Valid',
                      nilai:
                          '${k.valid.jumlah} · ${AppDesign.formatRupiah(k.valid.nominal)}',
                      warnaNilai: AppDesign.success,
                      icon: Icons.verified_outlined,
                    ),
                    KeuanganLaporanBaris(
                      label: 'Refund',
                      nilai:
                          '${k.refund.jumlah} · ${AppDesign.formatRupiah(k.refund.nominal)}',
                      warnaNilai: AppDesign.danger,
                      icon: Icons.replay_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spaceMd),
                KeuanganShareSection(
                  onExportPdf: () =>
                      _exportLaporanKeuangan(kosProvider.data_kos),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String pesan;
  final VoidCallback onCobaLagi;

  const _ErrorCard({required this.pesan, required this.onCobaLagi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      decoration: BoxDecoration(
        color: AppDesign.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: AppDesign.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppDesign.danger),
          const SizedBox(width: AppDesign.spaceSm),
          Expanded(
            child: Text(
              pesan,
              style: AppDesign.bodyMuted(
                context,
              ).copyWith(color: AppDesign.danger),
            ),
          ),
          TextButton(onPressed: onCobaLagi, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

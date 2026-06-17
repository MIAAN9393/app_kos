import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/keuangan/utils/bulan_periode.dart';
import 'package:kos_management/features/keuangan/widgets/keuangan_kos_multifilter.dart';
import 'package:kos_management/features/keuangan/widgets/keuangan_rentang_waktu_filter.dart';

/// Panel filter yang bisa dibuka-tutup (minimalis saat tertutup).
class KeuanganFilterPanel extends StatefulWidget {
  final String bulanMulai;
  final String bulanAkhir;
  final ValueChanged<String> onMulai;
  final ValueChanged<String> onAkhir;
  final List<Map<String, dynamic>> daftarKos;
  final Set<int> kosTerpilih;
  final ValueChanged<Set<int>> onKosChanged;
  final bool awalTerbuka;

  const KeuanganFilterPanel({
    super.key,
    required this.bulanMulai,
    required this.bulanAkhir,
    required this.onMulai,
    required this.onAkhir,
    required this.daftarKos,
    required this.kosTerpilih,
    required this.onKosChanged,
    this.awalTerbuka = false,
  });

  @override
  State<KeuanganFilterPanel> createState() => _KeuanganFilterPanelState();
}

class _KeuanganFilterPanelState extends State<KeuanganFilterPanel> {
  late bool _terbuka = widget.awalTerbuka;

  String get _ringkasan {
    final mulai = BulanPeriode.labelDari(widget.bulanMulai);
    final akhir = BulanPeriode.labelDari(widget.bulanAkhir);
    final periode = mulai == akhir ? mulai : '$mulai – $akhir';
    final kos = widget.kosTerpilih.isEmpty
        ? 'Semua kos'
        : '${widget.kosTerpilih.length} kos';
    return '$periode · $kos';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: AppDesign.cardDecoration(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spaceMd,
        vertical: AppDesign.spaceSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _terbuka = !_terbuka),
            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDesign.spaceXs),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: primary),
                  const SizedBox(width: AppDesign.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filter', style: AppDesign.titleBold(context)),
                        if (!_terbuka) ...[
                          const SizedBox(height: 2),
                          Text(
                            _ringkasan,
                            style: AppDesign.bodyMuted(context)
                                .copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _terbuka ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: AppDesign.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _terbuka
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDesign.spaceSm),
                KeuanganRentangWaktuFilter(
                  embedded: true,
                  bulanMulai: widget.bulanMulai,
                  bulanAkhir: widget.bulanAkhir,
                  onMulai: widget.onMulai,
                  onAkhir: widget.onAkhir,
                ),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: AppDesign.spaceMd),
                  child: Divider(height: 1, color: AppDesign.border),
                ),
                KeuanganKosMultifilter(
                  embedded: true,
                  daftarKos: widget.daftarKos,
                  kosTerpilih: widget.kosTerpilih,
                  onChanged: widget.onKosChanged,
                ),
                const SizedBox(height: AppDesign.spaceXs),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

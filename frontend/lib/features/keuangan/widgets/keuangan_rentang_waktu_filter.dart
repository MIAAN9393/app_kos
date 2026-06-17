import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/keuangan/utils/bulan_periode.dart';

class KeuanganRentangWaktuFilter extends StatelessWidget {
  final String bulanMulai;
  final String bulanAkhir;
  final ValueChanged<String> onMulai;
  final ValueChanged<String> onAkhir;
  final bool embedded;

  const KeuanganRentangWaktuFilter({
    super.key,
    required this.bulanMulai,
    required this.bulanAkhir,
    required this.onMulai,
    required this.onAkhir,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final opsi = BulanPeriode.opsiTerakhir();

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!embedded)
            Text('Rentang waktu', style: AppDesign.titleBold(context))
          else
            Text(
              'Rentang waktu',
              style: AppDesign.bodyMuted(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppDesign.textPrimary,
              ),
            ),
          const SizedBox(height: AppDesign.spaceMd),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  context,
                  label: 'Dari',
                  value: bulanMulai,
                  items: opsi,
                  onChanged: (v) {
                    if (v == null) return;
                    onMulai(v);
                    if (v.compareTo(bulanAkhir) > 0) onAkhir(v);
                  },
                ),
              ),
              const SizedBox(width: AppDesign.spaceSm),
              Expanded(
                child: _dropdown(
                  context,
                  label: 'Sampai',
                  value: bulanAkhir,
                  items: opsi,
                  onChanged: (v) {
                    if (v == null) return;
                    onAkhir(v);
                    if (v.compareTo(bulanMulai) < 0) onMulai(v);
                  },
                ),
              ),
            ],
          ),
        ],
      );

    if (embedded) return content;

    return Container(
      decoration: AppDesign.cardDecoration(),
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      child: content,
    );
  }

  Widget _dropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<BulanPeriode> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.any((o) => o.value == value)
        ? value
        : items.first.value;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      isExpanded: true,
      items: items
          .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

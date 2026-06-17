import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_chip.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';

/// Chip/icon fasilitas kamar dari data JSON API.
class KamarFasilitasChips extends StatelessWidget {
  final dynamic fasilitas;
  final String? emptyLabel;

  const KamarFasilitasChips({
    super.key,
    required this.fasilitas,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final list = KamarFasilitas.parse(fasilitas);
    if (list.isEmpty) {
      if (emptyLabel == null) return const SizedBox.shrink();
      return Text(
        emptyLabel!,
        style: const TextStyle(fontSize: 13, color: AppDesign.textSecondary),
      );
    }

    return Wrap(
      children: [
        for (final item in list)
          AppChip(
            icon: KamarFasilitas.iconFor(item),
            label: KamarFasilitas.labelFor(item),
          ),
      ],
    );
  }
}

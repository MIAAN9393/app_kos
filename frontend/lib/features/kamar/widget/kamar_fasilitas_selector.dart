import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';

/// Checkbox pilihan fasilitas kamar (AC, WiFi, Lemari).
class KamarFasilitasSelector extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const KamarFasilitasSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fasilitas',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: AppDesign.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Opsional. Pilih fasilitas yang tersedia di kamar.',
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 8),
          ...KamarFasilitas.options.map((opt) {
            final checked = selected.contains(opt.value);
            return CheckboxListTile(
              value: checked,
              onChanged: (v) {
                final next = Set<String>.from(selected);
                if (v == true) {
                  next.add(opt.value);
                } else {
                  next.remove(opt.value);
                }
                onChanged(next);
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              secondary: Icon(
                opt.icon,
                size: 20,
                color: AppDesign.textSecondary,
              ),
              title: Text(
                opt.label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppDesign.textPrimary,
                ),
              ),
              activeColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
              ),
            );
          }),
        ],
      ),
    );
  }
}

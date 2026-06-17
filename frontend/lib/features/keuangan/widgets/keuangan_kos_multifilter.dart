import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/utils/json_parse.dart';

/// Multi-select kos — kosong = semua kos (tidak kirim kos_ids ke API).
class KeuanganKosMultifilter extends StatelessWidget {
  final List<Map<String, dynamic>> daftarKos;
  final Set<int> kosTerpilih;
  final ValueChanged<Set<int>> onChanged;
  final bool embedded;

  const KeuanganKosMultifilter({
    super.key,
    required this.daftarKos,
    required this.kosTerpilih,
    required this.onChanged,
    this.embedded = false,
  });

  bool get semuaKos => kosTerpilih.isEmpty;

  @override
  Widget build(BuildContext context) {
    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kos',
                  style: embedded
                      ? AppDesign.bodyMuted(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppDesign.textPrimary,
                        )
                      : AppDesign.titleBold(context),
                ),
              ),
              if (!semuaKos)
                TextButton(
                  onPressed: () => onChanged({}),
                  child: const Text('Semua kos'),
                ),
            ],
          ),
          const SizedBox(height: AppDesign.spaceSm),
          Text(
            semuaKos
                ? 'Semua kos aktif'
                : '${kosTerpilih.length} kos dipilih',
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppDesign.spaceMd),
          if (daftarKos.isEmpty)
            Text(
              'Belum ada kos aktif',
              style: AppDesign.bodyMuted(context),
            )
          else
            Wrap(
              spacing: AppDesign.spaceSm,
              runSpacing: AppDesign.spaceSm,
              children: [
                FilterChip(
                  label: const Text('Semua kos'),
                  selected: semuaKos,
                  onSelected: (_) => onChanged({}),
                ),
                for (final kos in daftarKos) ...[
                  Builder(
                    builder: (context) {
                      final id = intFromJson(kos['id']);
                      if (id == null) return const SizedBox.shrink();
                      return FilterChip(
                        label: Text(
                          kos['nama_kos']?.toString() ?? 'Kos $id',
                        ),
                        selected: kosTerpilih.contains(id),
                        onSelected: (_) {
                          final next = Set<int>.from(kosTerpilih);
                          if (next.contains(id)) {
                            next.remove(id);
                          } else {
                            next.add(id);
                          }
                          onChanged(next);
                        },
                      );
                    },
                  ),
                ],
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
}

import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';

class KamarFilterSheet {
  KamarFilterSheet._();

  static const int statusCount = 3;
  static const List<String> statusLabels = ['Kosong', 'Sebagian', 'Penuh'];

  static final List<String> labels = [
    ...statusLabels,
    ...KamarFasilitas.options.map((o) => o.label),
  ];

  static Future<void> show({
    required BuildContext context,
    required Set<int> selected,
    required ValueChanged<Set<int>> onChanged,
  }) {
    var draft = Set<int>.from(selected);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDesign.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radiusLg),
        ),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.82;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void toggle(int index, bool selected) {
              setSheetState(() {
                if (selected) {
                  draft.add(index);
                } else {
                  draft.remove(index);
                }
              });
            }

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Filter Kamar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppDesign.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih status hunian dan fasilitas. Kosongkan semua untuk tampilkan semua data.',
                        style: AppDesign.bodyMuted(ctx).copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      _FilterSection(
                        title: 'Status hunian',
                        children: [
                          for (var i = 0; i < statusLabels.length; i++)
                            _FilterChip(
                              label: statusLabels[i],
                              selected: draft.contains(i),
                              onSelected: (v) => toggle(i, v),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _FilterSection(
                        title: 'Fasilitas',
                        children: [
                          for (var i = 0;
                              i < KamarFasilitas.options.length;
                              i++)
                            _FilterChip(
                              label: KamarFasilitas.options[i].label,
                              icon: KamarFasilitas.options[i].icon,
                              selected: draft.contains(statusCount + i),
                              onSelected: (v) => toggle(statusCount + i, v),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  draft.clear();
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                onChanged(Set<int>.from(draft));
                                Navigator.pop(ctx);
                              },
                              child: const Text('Terapkan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FilterSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppDesign.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 18,
              color: selected ? AppDesign.card : AppDesign.textSecondary,
            ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppDesign.card : AppDesign.textPrimary,
      ),
      selectedColor: AppDesign.info,
      checkmarkColor: AppDesign.card,
      backgroundColor: AppDesign.surface,
      side: BorderSide(
        color: selected ? AppDesign.info : AppDesign.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      ),
    );
  }
}

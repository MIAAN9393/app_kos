import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

/// UI bersama tab list (kamar, penyewa, dll.) di dalam detail + embedded FAB.
class AppListTabUi {
  AppListTabUi._();

  static const double horizontal = 24;
  static const double listBottomEmbedded = 100;
  static const double listBottomStandalone = 24;

  static const List<Color> _filterSummaryColors = [
    AppDesign.success,
    AppDesign.warning,
    AppDesign.info,
    Color(0xFF7C3AED),
  ];

  static EdgeInsets listPadding({required bool embedded}) => EdgeInsets.fromLTRB(
        horizontal,
        8,
        horizontal,
        embedded ? listBottomEmbedded : listBottomStandalone,
      );

  static EdgeInsets searchPadding({bool embedded = true}) => EdgeInsets.fromLTRB(
        horizontal,
        embedded ? 10 : 12,
        horizontal,
        6,
      );

  static Widget searchField({
    required TextEditingController controller,
    required String hint,
    bool embedded = true,
  }) {
    return Padding(
      padding: searchPadding(embedded: embedded),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            borderSide: const BorderSide(color: AppDesign.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            borderSide: const BorderSide(color: AppDesign.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            borderSide: BorderSide(
              color: AppDesign.info.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  /// Kiri: tiap filter terpilih (nama + jumlah). Kanan: total hasil filter. Multi-pilih.
  static Widget summaryRowWithFilter({
    required BuildContext context,
    required List<AppListSummaryItem> leftItems,
    required AppListSummaryItem right,
    required List<String> filterLabels,
    required Set<int> selectedFilters,
    required ValueChanged<Set<int>> onFiltersChanged,
    String filterTitle = 'Filter',
    VoidCallback? onFilterTap,
  }) {
    final filterHint = _filterSelectionHint(filterLabels, selectedFilters);
    return Padding(
      padding: const EdgeInsets.fromLTRB(horizontal, 0, horizontal, 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _compactSummaryBoxMulti(context, leftItems)),
            const SizedBox(width: 8),
            Expanded(child: _compactSummaryBox(context, right)),
            const SizedBox(width: 8),
            _compactFilterTile(
              context: context,
              filterTitle: filterTitle,
              selected: filterHint,
              onTap:
                  onFilterTap ??
                  () => _showMultiFilterSheet(
                    context: context,
                    title: filterTitle,
                    labels: filterLabels,
                    selected: selectedFilters,
                    onChanged: onFiltersChanged,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static List<AppListSummaryItem> summaryFromFilterCounts({
    required Set<int> selected,
    required Map<int, int> counts,
    required List<String> labels,
  }) {
    final sorted = selected.toList()..sort();
    return [
      for (var n = 0; n < sorted.length; n++)
        AppListSummaryItem(
          label: labels[sorted[n]],
          value: '${counts[sorted[n]] ?? 0}',
          color: _filterSummaryColors[n % _filterSummaryColors.length],
        ),
    ];
  }

  static String _filterSelectionHint(List<String> labels, Set<int> selected) {
    if (selected.isEmpty) return 'Pilih';
    if (selected.length == labels.length) return 'Semua';
    if (selected.length == 1) {
      final i = selected.first;
      if (i >= 0 && i < labels.length) return labels[i];
    }
    return '${selected.length} dipilih';
  }

  static Widget _compactSummaryBoxMulti(
    BuildContext context,
    List<AppListSummaryItem> items,
  ) {
    if (items.isEmpty) {
      return _compactSummaryBox(
        context,
        const AppListSummaryItem(
          label: 'Filter',
          value: '—',
          color: AppDesign.textTertiary,
        ),
      );
    }
    if (items.length == 1) {
      return _compactSummaryBox(context, items.first);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _filterStatRow(context, items[i]),
          ],
        ],
      ),
    );
  }

  static Widget _filterStatRow(BuildContext context, AppListSummaryItem item) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.label,
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          item.value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: item.color,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  static Widget _compactSummaryBox(BuildContext context, AppListSummaryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.suffix.isNotEmpty)
                Flexible(
                  child: Text(
                    item.suffix,
                    style: AppDesign.bodyMuted(context).copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _compactFilterTile({
    required BuildContext context,
    required String filterTitle,
    required String selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppDesign.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        side: const BorderSide(color: AppDesign.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tune_rounded, size: 18, color: AppDesign.info),
                const SizedBox(height: 4),
                Text(
                  selected,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppDesign.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  filterTitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppDesign.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showMultiFilterSheet({
    required BuildContext context,
    required String title,
    required List<String> labels,
    required Set<int> selected,
    required ValueChanged<Set<int>> onChanged,
  }) {
    var draft = Set<int>.from(selected);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppDesign.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesign.radiusLg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppDesign.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Bisa pilih lebih dari satu. Kosongkan semua untuk tampilkan semua data.',
                      style: AppDesign.bodyMuted(ctx).copyWith(fontSize: 12),
                    ),
                  ),
                  const Divider(height: 1),
                  for (var i = 0; i < labels.length; i++)
                    CheckboxListTile(
                      value: draft.contains(i),
                      activeColor: AppDesign.info,
                      title: Text(
                        labels[i],
                        style: TextStyle(
                          fontWeight:
                              draft.contains(i) ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onChanged: (checked) {
                        setSheetState(() {
                          if (checked == true) {
                            draft.add(i);
                          } else {
                            draft.remove(i);
                          }
                        });
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
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
            );
          },
        );
      },
    );
  }

  static Widget emptyListMessage({
    required BuildContext context,
    required bool hasQuery,
    required bool hasFilter,
    required String emptyMessage,
    required String noMatchMessage,
  }) {
    final text = (hasQuery || hasFilter) ? noMatchMessage : emptyMessage;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              (hasQuery || hasFilter)
                  ? Icons.search_off_rounded
                  : Icons.inbox_outlined,
              size: 48,
              color: AppDesign.textTertiary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: AppDesign.bodyMuted(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AppListSummaryItem {
  final String label;
  final String value;
  final String suffix;
  final Color color;

  const AppListSummaryItem({
    required this.label,
    required this.value,
    this.suffix = '',
    required this.color,
  });
}

/// Filter kategori multi-pilih (OR): tanpa opsi "Semua".
class ListMultiFilterResult<T> {
  final List<T> data;
  final Map<int, int> counts;

  const ListMultiFilterResult({
    required this.data,
    required this.counts,
  });
}

class ListMultiFilter {
  ListMultiFilter._();

  /// Semua indeks filter terpilih (default awal UI).
  static Set<int> allIndices(int optionCount) =>
      Set<int>.from(List.generate(optionCount, (i) => i));

  /// Filter dianggap "aktif" jika tidak semua terpilih (atau kosong = tampil semua).
  static bool isNarrowedSelection(Set<int> selected, int optionCount) =>
      selected.isNotEmpty && selected.length < optionCount;

  /// [searched] = hasil pencarian saja. [selected] kosong = tampilkan semua.
  static ListMultiFilterResult<T> apply<T>({
    required List<T> searched,
    required Set<int> selected,
    required List<bool Function(T)> matchers,
  }) {
    final counts = <int, int>{};
    for (final i in selected) {
      if (i >= 0 && i < matchers.length) {
        counts[i] = searched.where(matchers[i]).length;
      }
    }
    if (selected.isEmpty) {
      return ListMultiFilterResult(data: searched, counts: counts);
    }
    final data = searched
        .where(
          (e) => selected.any(
            (i) => i >= 0 && i < matchers.length && matchers[i](e),
          ),
        )
        .toList();
    return ListMultiFilterResult(data: data, counts: counts);
  }
}

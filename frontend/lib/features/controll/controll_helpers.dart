import 'package:flutter/material.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/pembayaran_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/providers/repository/kos_repository.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';
import 'package:kos_management/utils/kontrak_status.dart';
import 'package:kos_management/utils/tagihan_rules.dart';
import 'package:kos_management/utils/list_multi_filter.dart';
import 'package:provider/provider.dart';

/// Muat & gabung data lintas kos untuk tab Controll.
class ControllHelpers {
  ControllHelpers._();

  // ── Filter awal ──────────────────────────────────────────────
  static Set<int> defaultFilterSelection(int optionCount) =>
      ListMultiFilter.allIndices(optionCount);

  // ── Loader: muat data per kos ────────────────────────────────
  /// Pastikan daftar kos sudah ada (cache-aware di provider).
  static Future<void> ensureKos(BuildContext context) =>
      context.read<KosProvider>().ambil_or_update_data();

  /// ID semua kos milik pengguna.
  static List<int> kosIds(KosProvider kos) =>
      kos.data_kos.map((k) => entityId(k['id'])).whereType<int>().toList();

  /// Jalankan [action] berurutan untuk tiap kos (sekuensial = aman race state).
  static Future<void> _forEachKos(
    BuildContext context,
    Future<void> Function(int kosId) action,
  ) async {
    final kosProv = context.read<KosProvider>();
    await ensureKos(context);
    for (final id in kosIds(kosProv)) {
      await action(id);
    }
  }

  static Future<void> loadAllKamar(BuildContext context) => _forEachKos(
    context,
    context.read<KamarProvider>().ambil_data_kamar_provider,
  );

  /// Muat semua penyewa (aktif + nonaktif) untuk daftar, lalu muat per kos
  /// supaya penyewa aktif tetap punya konteks kamar/kos (navigasi & label).
  static Future<void> loadAllPenyewa(BuildContext context) async {
    final penyewaProv = context.read<PenyewaProvider>();
    await penyewaProv.ambil_semua_penyewa();
    if (!context.mounted) return;
    await _forEachKos(context, penyewaProv.ambil_data_penyewa_by_kos_provider);
  }

  /// Kontrak: konteks kamar/penyewa disiapkan dulu, lalu ambil semua kontrak.
  static Future<void> loadAllKontrak(BuildContext context) async {
    final kontrakProv = context.read<KontrakProvider>();
    await loadAllKamar(context);
    if (!context.mounted) return;
    await loadAllPenyewa(context);
    await kontrakProv.ambil_semua_kontrak();
  }

  /// Tagihan: konteks kamar/penyewa disiapkan dulu, lalu ambil semua tagihan.
  static Future<void> loadAllTagihan(BuildContext context) async {
    final tagihanProv = context.read<TagihanProvider>();
    await loadAllKamar(context);
    if (!context.mounted) return;
    await loadAllPenyewa(context);
    await tagihanProv.ambil_semua_tagihan();
  }

  /// Pembayaran: tagihan disiapkan dulu (untuk konteks), lalu ambil semua pembayaran.
  static Future<void> loadAllPembayaran(BuildContext context) async {
    final pembayaranProv = context.read<PembayaranProvider>();
    await loadAllTagihan(context);
    await pembayaranProv.ambil_semua_pembayaran();
  }

  // ── Flatten: ubah map-per-kunci jadi satu list datar ─────────
  static List<Map<String, dynamic>> flattenKamar(KamarProvider p) => [
    for (final list in p.data_kamar.values)
      for (final k in list) Map<String, dynamic>.from(k),
  ];

  static List<Map<String, dynamic>> flattenPenyewa(PenyewaProvider p) => p
      .semua_data_penyewa
      .values
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  static List<Map<String, dynamic>> flattenKontrak(KontrakProvider p) => p
      .semua_data_kontrak
      .values
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  static List<Map<String, dynamic>> flattenTagihan(TagihanProvider p) => p
      .semua_data_tagihan
      .values
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  /// Gabung pembayaran + sisipkan konteks tagihan/penyewa, urut terbaru dulu.
  static List<Map<String, dynamic>> flattenPembayaran(
    PembayaranProvider pay,
    TagihanProvider tagihan,
  ) {
    final out = <Map<String, dynamic>>[];
    pay.data_pembayaran.forEach((tagihanId, list) {
      final tag = tagihan.tagihan_by_id[tagihanId];
      for (final bayar in list) {
        final row = Map<String, dynamic>.from(bayar);
        row['tagihan_id'] = tagihanId;
        if (tag != null) {
          row['_tagihan'] = tag;
          row['penyewa_id'] = tag['penyewa_id'];
        }
        out.add(row);
      }
    });
    out.sort(
      (a, b) =>
          '${b['dibuat_pada'] ?? ''}'.compareTo('${a['dibuat_pada'] ?? ''}'),
    );
    return out;
  }

  // ── Pencarian: cocokkan query ke beberapa field ──────────────
  /// True bila salah satu field mengandung [query] (case-insensitive).
  static List<Map<String, dynamic>> _searchBy(
    List<Map<String, dynamic>> items,
    String query,
    Iterable<String> Function(Map<String, dynamic>) fields,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((e) => fields(e).any((f) => f.toLowerCase().contains(q)))
        .toList();
  }

  static String _nested(dynamic map, String key) =>
      map is Map ? '${map[key] ?? ''}' : '';

  // ── Filter multi-pilih per entitas (pencarian → kategori) ────
  static ListMultiFilterResult<Map<String, dynamic>> filterKosMulti(
    List<Map<String, dynamic>> items,
    String query,
    Set<int> selected,
  ) => ListMultiFilter.apply(
    searched: search_data_nama(items, query.trim()),
    selected: selected,
    matchers: [
      (e) => _aktif('${e['status']}'),
      (e) => !_aktif('${e['status']}'),
    ],
  );

  static ListMultiFilterResult<Map<String, dynamic>> filterKamarMulti(
    List<Map<String, dynamic>> items,
    String query,
    Set<int> selected,
  ) => ListMultiFilter.apply(
    searched: _searchBy(items, query, (e) => ['${e['nomor']}']),
    selected: selected,
    matchers: [
      (e) => e['status_kondisi'] == 'kosong',
      (e) => e['status_kondisi'] == 'sebagian',
      (e) => e['status_kondisi'] == 'penuh',
      (e) => KamarFasilitas.contains(e['fasilitas'], KamarFasilitas.ac),
      (e) => KamarFasilitas.contains(e['fasilitas'], KamarFasilitas.wifi),
      (e) => KamarFasilitas.contains(e['fasilitas'], KamarFasilitas.lemari),
      (e) => KamarFasilitas.contains(e['fasilitas'], KamarFasilitas.kamarMandi),
    ],
  );

  static ListMultiFilterResult<Map<String, dynamic>> filterPenyewaMulti(
    List<Map<String, dynamic>> items,
    String query,
    Set<int> selected,
  ) => ListMultiFilter.apply(
    searched: _searchBy(
      items,
      query,
      (e) => [
        '${e['nama']}',
        '${e['no_telpon']}',
        '${e['jenis_kelamin'] ?? ''}',
        '${e['status_hubungan'] ?? ''}',
      ],
    ),
    selected: selected,
    matchers: [
      (e) => _aktif('${e['status'] ?? 'aktif'}'),
      (e) => !_aktif('${e['status'] ?? 'aktif'}'),
    ],
  );

  static ListMultiFilterResult<Map<String, dynamic>> filterKontrakMulti(
    List<Map<String, dynamic>> items,
    String query,
    Set<int> selected,
  ) => ListMultiFilter.apply(
    searched: _searchBy(
      items,
      query,
      (e) => [
        _nested(e['penyewa'], 'nama'),
        _nested(e['kamar'], 'nomor'),
        '${e['id']}',
      ],
    ),
    selected: selected,
    matchers: [
      (e) => KontrakStatus.isAktif(e),
      (e) => KontrakStatus.isPending(e),
      (e) => KontrakStatus.isSelesai(e),
      (e) => KontrakStatus.isDibatalkan(e),
    ],
  );

  static ListMultiFilterResult<Map<String, dynamic>> filterTagihanMulti(
    List<Map<String, dynamic>> items,
    String query,
    Set<int> selected,
  ) => ListMultiFilter.apply(
    searched: _searchBy(
      items,
      query,
      (e) => ['${e['kode_tagihan'] ?? ''}', '${e['id']}'],
    ),
    selected: selected,
    matchers: [
      TagihanRules.matchFilterBelum,
      TagihanRules.matchFilterSebagianTelat,
      TagihanRules.matchFilterLunas,
      TagihanRules.matchFilterDibatalkan,
    ],
  );

  static ListMultiFilterResult<Map<String, dynamic>> filterPembayaranMulti(
    List<Map<String, dynamic>> items,
    String query,
    Set<int> selected,
  ) => ListMultiFilter.apply(
    searched: _searchBy(
      items,
      query,
      (e) => [_nested(e['_tagihan'], 'kode_tagihan'), '${e['id']}'],
    ),
    selected: selected,
    matchers: [
      (e) => '${e['status']}' == 'valid',
      (e) => '${e['status']}' == 'refund',
    ],
  );

  /// "aktif" atau kosong dianggap aktif (default backend).
  static bool _aktif(String s) {
    final v = s.toLowerCase();
    return v == 'aktif' || v.isEmpty;
  }

  // ── Penelusuran relasi penyewa → kamar → kos ─────────────────
  static int? kamarIdForPenyewa(PenyewaProvider p, int penyewaId) =>
      entityId(p.penyewa_by_id[penyewaId]?['kamar_id']) ??
      p.index_penyewa_kamar[penyewaId];

  static int? kosIdForKamar(KamarProvider kamar, int? kamarId) =>
      kamarId == null ? null : kamar.cari_kos_id(kamarId);

  /// Label singkat untuk card/list: "Budi · Kamar 3 · Kos Melati".
  static String labelKonteksPenyewa({
    required PenyewaProvider penyewa,
    required KamarProvider kamar,
    required KosProvider kos,
    required int penyewaId,
  }) {
    final p = penyewa.penyewa_by_id[penyewaId];
    final kamarId = kamarIdForPenyewa(penyewa, penyewaId);
    final km = kamarId != null ? kamar.kamar_by_id[kamarId] : null;
    final kosId = kosIdForKamar(kamar, kamarId);
    final k = kosId != null ? kos.dataKosMap[kosId] : null;
    final parts = <String>['${p?['nama'] ?? 'Penyewa'}'];
    if (km != null) parts.add('Kamar ${km['nomor']}');
    if (k != null) parts.add('${k['nama_kos']}');
    return parts.join(' · ');
  }
}

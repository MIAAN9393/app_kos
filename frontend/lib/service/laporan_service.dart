import 'package:kos_management/service/api_service.dart';

class LaporanService {
  final ApiService api;

  LaporanService(this.api);

  static Map<String, dynamic> _bodyMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static String _pesanFrom(dynamic data, String fallback) {
    final m = _bodyMap(data);
    return '${m['pesan'] ?? m['message'] ?? fallback}';
  }

  static Map<String, dynamic> _dataMap(dynamic data) {
    final m = _bodyMap(data);
    dynamic raw = m['data'];

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      // Beberapa wrapper: { data: { periode, keuangan, ... } } }
      if (map['keuangan'] == null &&
          map['tagihan'] == null &&
          map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }

    if (m['keuangan'] is Map || m['tagihan'] is Map) {
      return m;
    }

    return {};
  }

  String _query({
    required String bulanMulai,
    required String bulanAkhir,
    List<int>? kosIds,
  }) {
    final parts = <String>[
      'bulan_mulai=$bulanMulai',
      'bulan_akhir=$bulanAkhir',
    ];
    if (kosIds != null && kosIds.isNotEmpty) {
      parts.add('kos_ids=${kosIds.join(',')}');
    }
    return parts.join('&');
  }

  Future<Map<String, dynamic>> ambilLaporanKeuangan({
    required String bulanMulai,
    required String bulanAkhir,
    List<int>? kosIds,
  }) async {
    final q = _query(
      bulanMulai: bulanMulai,
      bulanAkhir: bulanAkhir,
      kosIds: kosIds,
    );
    final res = await api.get('laporan_keuangan/ambil_laporan_keuangan?$q');
    final code = res['statusCode'];
    if (code == 404) {
      throw Exception(
        'Endpoint laporan tidak ditemukan. Restart backend (npm run dev).',
      );
    }
    if (code != 200 && code != 201) {
      throw Exception(
        _pesanFrom(res['data'], 'Ambil laporan keuangan gagal'),
      );
    }
    // print("DATA MENTAH ${res["data"]}");
    return _dataMap(res['data']);
  }

  Future<Map<String, dynamic>> ambilLaporanTagihan({
    required String bulanMulai,
    required String bulanAkhir,
    List<int>? kosIds,
  }) async {
    final q = _query(
      bulanMulai: bulanMulai,
      bulanAkhir: bulanAkhir,
      kosIds: kosIds,
    );
    final res = await api.get('laporan_tagihan/ambil_laporan_tagihan?$q');
    final code = res['statusCode'];
    if (code == 404) {
      throw Exception(
        'Endpoint laporan tidak ditemukan. Restart backend (npm run dev).',
      );
    }
    if (code != 200 && code != 201) {
      throw Exception(
        _pesanFrom(res['data'], 'Ambil laporan tagihan gagal'),
      );
    }
    return _dataMap(res['data']);
  }
}

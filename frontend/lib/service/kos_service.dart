import 'package:kos_management/service/api_service.dart';

class KosService extends ApiService {
  final ApiService api;

  KosService(this.api);
  // =========================
  // KOS
  // =========================

  static Map<String, dynamic> _bodyMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static String _pesanFrom(dynamic data, String fallback) {
    final m = _bodyMap(data);
    return '${m['pesan'] ?? m['message'] ?? fallback}';
  }

  static List<Map<String, dynamic>> _listFrom(dynamic data) {
    final m = _bodyMap(data);
    final raw = m['data'];
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
        .toList();
  }

  Future<List<Map<String, dynamic>>> getKosList() async {
    final res = await api.get('kos/ambil_kos');
    final code = res['statusCode'];
    if (code != 200 && code != 201) {
      throw Exception(_pesanFrom(res['data'], 'Ambil data kos gagal'));
    }
    return _listFrom(res['data']);
  }

  Future<String> createKos({
    required String nama_kos,
    required String alamat,
    String deskripsi = '',
  }) async {
    final res = await api.post('kos/buat_kos', {
      'nama_kos': nama_kos,
      'alamat': alamat,
      'deskripsi': deskripsi,
    });
    final code = res['statusCode'];
    if (code != 200 && code != 201) {
      throw Exception(_pesanFrom(res['data'], 'Buat kos gagal'));
    }
    return _pesanFrom(res['data'], 'Kos berhasil dibuat');
  }

  Future<dynamic> hapusKos(int id_kos) async {

      final res = await api.sdelete('kos/shapus_kos/$id_kos');
      if(res['statusCode']!=200){
        throw Exception(_pesanFrom(res['data'], 'Hapus kos gagal'));
      }
    return _pesanFrom(res['data'], 'Kos berhasil dihapus');
  }

    Future<dynamic> editKos({required int kos_id,required String nama_kos,required String alamat, String deskripsi = ""}) async {

      final res = await api.put('kos/edit_kos/$kos_id',{
        "nama_kos":nama_kos,
        "alamat":alamat,
        "deskripsi":deskripsi
      });
      if(res['statusCode']!=200){
        throw Exception(_pesanFrom(res['data'], 'Edit kos gagal'));
      }
    return _pesanFrom(res['data'], 'Kos berhasil diubah');
  }

    Future<dynamic> laporan_kos(int kos_id) async {
    final res = await api.get('kos/laporan_kos?kos_id=$kos_id');

    if(res['statusCode']!=200){
      throw Exception (res['data']['pesan']??'ambil data kos gagal');
    }
    final raw = res['data']['data'] ?? [];

    final data = (raw as List)
    .map((e) => Map<String, dynamic>.from(e))
    .toList();

    return data;
  }

}
List<Map<String, dynamic>> search_data_nama(
  List<Map<String, dynamic>> data_kos,
  String kata_kunci,
) {
  if (kata_kunci.isEmpty) return data_kos;

  final hasil = data_kos.where((item) {
    final nama = item["nama_kos"].toString().toLowerCase();
    return nama.contains(kata_kunci.toLowerCase());
  }).toList();

  return hasil;
}

List<Map<String, dynamic>> search_kamar(
  Map<int, List<Map<String, dynamic>>> data_penyewa,
  String kata_kunci,
  int kamar_id,
) {
  if (kata_kunci.isEmpty) return data_penyewa[kamar_id] ?? [];

  final data = data_penyewa[kamar_id]!;

  final hasil = data.where((item) {
    final nama = item["nomor"].toString().toLowerCase();
    return nama.contains(kata_kunci.toLowerCase());
  }).toList();

  return hasil;
}

List<Map<String, dynamic>> search_penyewa(
  Map<int, List<Map<String, dynamic>>> data_penyewa,
  String kata_kunci,
  int kamar_id,
) {
  if (kata_kunci.isEmpty) return data_penyewa[kamar_id] ?? [];

  final data = data_penyewa[kamar_id]!;

  final hasil = data.where((item) {
    final nama = item["nama"].toString().toLowerCase();
    final telpon = item["no_telpon"].toString().toLowerCase();
    final jenisKelamin = '${item["jenis_kelamin"] ?? ''}'.toLowerCase();
    final statusHubungan = '${item["status_hubungan"] ?? ''}'.toLowerCase();
    final q = kata_kunci.toLowerCase();
    return nama.contains(q) ||
        telpon.contains(q) ||
        jenisKelamin.contains(q) ||
        statusHubungan.contains(q);
  }).toList();

  return hasil;
}

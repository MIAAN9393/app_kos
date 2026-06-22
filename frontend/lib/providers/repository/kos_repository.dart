List<Map<String, dynamic>> search_data_nama(
  List<Map<String, dynamic>> dataKos,
  String kataKunci,
) {
  if (kataKunci.isEmpty) return dataKos;

  final hasil = dataKos.where((item) {
    final nama = item["nama_kos"].toString().toLowerCase();
    return nama.contains(kataKunci.toLowerCase());
  }).toList();

  return hasil;
}

List<Map<String, dynamic>> search_kamar(
  Map<int, List<Map<String, dynamic>>> dataPenyewa,
  String kataKunci,
  int kamarId,
) {
  if (kataKunci.isEmpty) return dataPenyewa[kamarId] ?? [];

  final data = dataPenyewa[kamarId]!;

  final hasil = data.where((item) {
    final nama = item["nomor"].toString().toLowerCase();
    return nama.contains(kataKunci.toLowerCase());
  }).toList();

  return hasil;
}

List<Map<String, dynamic>> search_penyewa(
  Map<int, List<Map<String, dynamic>>> dataPenyewa,
  String kataKunci,
  int kamarId,
) {
  if (kataKunci.isEmpty) return dataPenyewa[kamarId] ?? [];

  final data = dataPenyewa[kamarId]!;

  final hasil = data.where((item) {
    final nama = item["nama"].toString().toLowerCase();
    final telpon = item["no_telpon"].toString().toLowerCase();
    final jenisKelamin = '${item["jenis_kelamin"] ?? ''}'.toLowerCase();
    final statusHubungan = '${item["status_hubungan"] ?? ''}'.toLowerCase();
    final q = kataKunci.toLowerCase();
    return nama.contains(q) ||
        telpon.contains(q) ||
        jenisKelamin.contains(q) ||
        statusHubungan.contains(q);
  }).toList();

  return hasil;
}

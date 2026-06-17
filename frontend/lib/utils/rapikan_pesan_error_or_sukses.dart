import 'dart:convert';

/// Bersihkan pesan mentah (error/sukses) jadi kalimat ramah untuk UI.
/// Dipakai bersama oleh semua provider — satu sumber kebenaran.
String rapikanPesan(String? msg) {
  if (msg == null || msg.isEmpty) return '';

  String hasil = msg.trim();

  // Ambil field "pesan"/"message" bila pesan berbentuk JSON.
  final jsonMatch = RegExp(r'\{.*\}').firstMatch(hasil);
  if (jsonMatch != null) {
    try {
      final Map data = jsonDecode(jsonMatch.group(0)!);
      hasil = '${data['pesan'] ?? data['message'] ?? hasil}';
    } catch (_) {}
  }

  // Stack trace / HTML server bukan untuk dibaca user.
  if (_pesanServerKasar(hasil)) {
    return 'Terjadi kesalahan pada server. Coba lagi atau periksa log backend.';
  }

  // Buang prefix teknis & ratakan jadi satu baris.
  hasil = hasil
      .replaceAll(RegExp(r'Exception:\s*HTTP\s*\d+'), '')
      .replaceAll('Exception:', '')
      .replaceAll('Error:', '')
      .replaceAll('→', '')
      .replaceAll('\n', ' ')
      .trim();

  // Potong pesan yang kepanjangan supaya snackbar tidak meledak.
  if (hasil.length > 280) hasil = '${hasil.substring(0, 280)}…';

  // Kapitalkan huruf pertama.
  if (hasil.isNotEmpty) hasil = hasil[0].toUpperCase() + hasil.substring(1);

  return hasil;
}

/// True jika pesan terlihat seperti dump teknis (HTML/stack trace Node).
bool _pesanServerKasar(String s) {
  final lower = s.toLowerCase();
  return lower.contains('<!doctype') ||
      lower.contains('<html') ||
      s.contains('node_modules') ||
      s.contains('error_middleware') ||
      (s.contains('at ') && s.contains('.js:'));
}

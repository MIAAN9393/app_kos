import 'package:flutter/foundation.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/profile_service.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService api = ProfileService(ApiService());

  bool loading = false;
  bool saving = false;
  String? _pesanError;
  String? _pesanSukses;
  Map<String, dynamic>? profileData;

  String? ambilPesanError() {
    final msg = rapikanPesan(_pesanError);
    _pesanError = null;
    return msg.isEmpty ? null : msg;
  }

  String? ambilPesanSukses() {
    final msg = rapikanPesan(_pesanSukses);
    _pesanSukses = null;
    return msg.isEmpty ? null : msg;
  }

  Map<String, dynamic> get user {
    final raw = profileData?['user'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Map<String, dynamic> get summary {
    final raw = profileData?['summary'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  bool get bisaGantiPassword => user['bisa_ganti_password'] == true;

  Future<void> ambilProfile({bool force = false}) async {
    if (!force && profileData != null) return;

    try {
      _pesanError = null;
      loading = true;
      notifyListeners();
      profileData = await api.ambilProfile();
    } catch (e) {
      _pesanError = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String nama,
    String? fotoPath,
    bool tampilkanPesanSukses = true,
  }) async {
    try {
      _pesanError = null;
      _pesanSukses = null;
      saving = true;
      notifyListeners();
      profileData = await api.updateProfile(nama: nama, fotoPath: fotoPath);
      profileData = await api.ambilProfile();
      if (tampilkanPesanSukses) {
        _pesanSukses = 'Profile berhasil diperbarui';
      }
      return true;
    } catch (e) {
      _pesanError = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> gantiPassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    try {
      _pesanError = null;
      _pesanSukses = null;
      saving = true;
      notifyListeners();
      _pesanSukses = await api.gantiPassword(
        passwordLama: passwordLama,
        passwordBaru: passwordBaru,
      );
      return true;
    } catch (e) {
      _pesanError = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}

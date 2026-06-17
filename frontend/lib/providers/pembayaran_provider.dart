import 'package:flutter/cupertino.dart';
import 'package:kos_management/providers/app_data_invalidator.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/pembayaran_service.dart';
import 'package:kos_management/providers/laporan_keuangan_provider.dart';
import 'package:kos_management/providers/laporan_kos_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class PembayaranProvider extends ChangeNotifier {
  final PembayaranService api_pembayaran = PembayaranService(ApiService());
  Map<int, List<Map<String, dynamic>>> data_pembayaran = {};
  Map<int, bool> perubahan_data = {};
  bool loading = false;
  String? _pesan_error;
  String? _pesan_sukses;

  // index biar tidak loop cari tagihan
  // Map<int,int> index_pembayaran_tagihan = {};

  //FUNGSI FITUR

  // Ambil + reset pesan sukses (sekali pakai oleh UI).
  String? ambil_pesan_sukses() {
    final msg = rapikanPesan(_pesan_sukses);
    _pesan_sukses = null;
    return msg.isEmpty ? null : msg;
  }

  // Ambil + reset pesan error (sekali pakai oleh UI).
  String? ambil_pesan_error() {
    final msg = rapikanPesan(_pesan_error);
    _pesan_error = null;
    return msg.isEmpty ? null : msg;
  }

  //FUNGSI API
  Future<void> ambil_data_pembayaran_provider(int tagihan_id) async {
    if (perubahan_data[tagihan_id] == null) perubahan_data[tagihan_id] = true;

    if (data_pembayaran.containsKey(tagihan_id) &&
        perubahan_data[tagihan_id] == false) {
      return;
    }
    try {
      _pesan_error = null;
      loading = true;
      notifyListeners();
      //aksi
      // print("ambil data pembayaran");
      data_pembayaran[tagihan_id] ??= [];
      final new_data = await api_pembayaran.getPembayaranList(tagihan_id);
      // print("sudah fecth");
      data_pembayaran[tagihan_id] = new_data;
      perubahan_data[tagihan_id] = false;
      print({
        'NEW DATA': new_data,
        'DATA PEMBAYARAN': data_pembayaran[tagihan_id],
      });
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> ambil_semua_pembayaran() async {
    try {
      _pesan_error = null;
      loading = true;
      notifyListeners();

      final list = await api_pembayaran.getSemuaPembayaran();

      // Kelompokkan per tagihan_id supaya kompatibel dengan flatten yang ada.
      data_pembayaran.clear();
      for (final item in list) {
        final tagihanId = intFromJson(item['tagihan_id']);
        if (tagihanId == null) continue;
        data_pembayaran.putIfAbsent(tagihanId, () => []);
        data_pembayaran[tagihanId]!.add(Map<String, dynamic>.from(item));
        perubahan_data[tagihanId] = false;
      }
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> buat_pembayaran_provider(
    int tagihan_id,
    int jumlah_bayar, {
    int? kos_id,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      //aksi
      _pesan_sukses = await api_pembayaran.createPembayaran(
        tagihanId: tagihan_id,
        jumlahBayar: jumlah_bayar,
      );
      final new_data = await api_pembayaran.getPembayaranList(tagihan_id);
      data_pembayaran[tagihan_id] = new_data;
      perubahan_data[tagihan_id] = false;
      AppDataInvalidator.setelahPembayaranBerubah();
      LaporanKeuanganProvider.tandaiMuatUlang();
      if (kos_id != null) {
        LaporanKosProvider.tandaiMuatUlang(kos_id);
      }
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> buat_refund_pembayaran_provider(
    int pembayaran_id,
    int tagihan_id, {
    required int jumlah_refund,
    int? kos_id,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      _pesan_sukses = await api_pembayaran.createRefund(
        pembayaranId: pembayaran_id,
        jumlahRefund: jumlah_refund,
      );
      final new_data = await api_pembayaran.getPembayaranList(tagihan_id);
      data_pembayaran[tagihan_id] = new_data;
      perubahan_data[tagihan_id] = false;
      AppDataInvalidator.setelahPembayaranBerubah();
      LaporanKeuanganProvider.tandaiMuatUlang();
      if (kos_id != null) {
        LaporanKosProvider.tandaiMuatUlang(kos_id);
      }
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> batalkan_pembayaran_provider(
    int pembayaran_id,
    int tagihan_id,
  ) async {
    throw UnimplementedError(
      'Endpoint batalkan pembayaran belum tersedia di backend',
    );
  }
}

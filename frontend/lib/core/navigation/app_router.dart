import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_routes.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/auth/login_page.dart';
import 'package:kos_management/features/auth/forgot_password_page.dart';
import 'package:kos_management/features/auth/register_page.dart';
import 'package:kos_management/features/auth/verify_email_page.dart';
import 'package:kos_management/features/check_in/check_in_cepat_page.dart';
import 'package:kos_management/features/kamar/edit_kamar_page.dart';
import 'package:kos_management/features/kontrak/edit_kontrak_page.dart';
import 'package:kos_management/features/kontrak/kontrak_detail_page.dart';
import 'package:kos_management/features/kamar/kamar_detail_page.dart';
import 'package:kos_management/features/kamar/tambah_kamar_page.dart';
import 'package:kos_management/features/dashboard/dashboard_page.dart';
import 'package:kos_management/features/keuangan/keuangan_page.dart';
import 'package:kos_management/features/auth/profile_page.dart';
import 'package:kos_management/features/auth/settings_page.dart';
import 'package:kos_management/features/kos/edit_kos_page.dart';
import 'package:kos_management/features/kos/kos_detail_page.dart';
import 'package:kos_management/features/kos/kos_statistik_page.dart';
import 'package:kos_management/features/kos/tambah_kos_page.dart';
import 'package:kos_management/features/parent/parent_page.dart';
import 'package:kos_management/features/penyewa/edit_penyewa_page.dart';
import 'package:kos_management/features/penyewa/penyewa_page.dart';
import 'package:kos_management/features/penyewa/profile_penyewa_page.dart';
import 'package:kos_management/features/penyewa/tambah_penyewa_kontrak.dart';
import 'package:kos_management/features/penyewa_detail/penyewa_detail_page.dart';
import 'package:kos_management/features/tagihan/edit_tagihan_page.dart';
import 'package:kos_management/features/tagihan/tambah_tagihan_page.dart';
import 'package:kos_management/features/tagihan_detail/tagihan_detail_page.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    try {
      switch (settings.name) {
        case AppRoutes.login:
          return _fade(const LoginPage(), settings);
        case AppRoutes.register:
          return _fade(const RegisterPage(), settings);
        case AppRoutes.verifyEmail:
          final m = _map(args);
          return _fade(
            VerifyEmailPage(
              kontakAwal:
                  '${m['kontak'] ?? m['email'] ?? m['no_telpon'] ?? ''}',
              channel: '${m['channel'] ?? 'email'}',
            ),
            settings,
          );
        case AppRoutes.forgotPassword:
          return _fade(const ForgotPasswordPage(), settings);
        case AppRoutes.home:
        case AppRoutes.listKos:
          return _fade(const MainNavigation(), settings);
        case AppRoutes.kosDetail:
          final m = _map(args);
          return _slide(
            KosDetailPage(idKos: requireIntArg(m, 'idKos')),
            settings,
          );
        case AppRoutes.kosStatistik:
          final m = _map(args);
          return _slide(
            KosStatistikPage(idKos: requireIntArg(m, 'idKos')),
            settings,
          );
        case AppRoutes.kosTambah:
          return _slide<bool>(const TambahKosPage(), settings);
        case AppRoutes.kosEdit:
          final m = _map(args);
          return _slide<bool>(
            EditKosPage(
              idKos: requireIntArg(m, 'idKos'),
              namaAwal: '${m['nama'] ?? ''}',
              alamatAwal: '${m['alamat'] ?? ''}',
              deskripsiAwal: '${m['deskripsi'] ?? ''}',
            ),
            settings,
          );
        case AppRoutes.kamarDetail:
          final m = _map(args);
          return _slide(
            KamarDetailPage(
              idKamar: requireIntArg(m, 'idKamar'),
              idKos: requireIntArg(m, 'idKos'),
            ),
            settings,
          );
        case AppRoutes.listPenyewa:
          final m = _map(args);
          return _slide(
            PenyewaPage(
              id_kamar: requireIntArg(m, 'id_kamar'),
              id_kos: requireIntArg(m, 'id_kos'),
            ),
            settings,
          );
        case AppRoutes.detailPenyewa:
          final m = _map(args);
          return _slide(
            PenyewaDetailPage(
              id_penyewa: requireIntArg(m, 'id_penyewa'),
              id_kamar: intArg(m, 'id_kamar'),
              id_kos: intArg(m, 'id_kos'),
            ),
            settings,
          );
        case AppRoutes.profilePenyewa:
          final m = _map(args);
          return _slide(
            ProfilePenyewaPage(
              idPenyewa: requireIntArg(m, 'id_penyewa'),
              idKamar: intArg(m, 'id_kamar'),
              idKos: intArg(m, 'id_kos'),
            ),
            settings,
          );
        case AppRoutes.kamarTambah:
          final m = _map(args);
          return _slide<bool>(
            TambahKamarPage(idKos: requireIntArg(m, 'idKos')),
            settings,
          );
        case AppRoutes.kamarEdit:
          final m = _map(args);
          return _slide<bool>(
            EditKamarPage(
              idKamar: requireIntArg(m, 'idKamar'),
              idKos: requireIntArg(m, 'idKos'),
              nomorAwal: '${m['nomor'] ?? ''}',
              hargaAwal: '${m['harga'] ?? ''}',
              kapasitasAwal: '${m['kapasitas'] ?? ''}',
              fasilitasAwal: KamarFasilitas.parse(m['fasilitas']),
            ),
            settings,
          );
        case AppRoutes.tambahPenyewaKontrak:
          final m = args is Map ? _map(args) : <String, dynamic>{};
          return _slide(
            TambahPenyewaKontrak(
              idKamar: intArg(m, 'idKamar'),
              idKos: intArg(m, 'idKos'),
            ),
            settings,
          );
        case AppRoutes.editPenyewa:
          final m = _map(args);
          return _slide<bool>(
            EditPenyewaPage(
              idPenyewa: requireIntArg(m, 'idPenyewa'),
              namaAwal: '${m['nama'] ?? ''}',
              telponAwal: '${m['no_telpon'] ?? ''}',
              emailAwal: '${m['email'] ?? ''}',
              tanggalLahirAwal: '${m['tanggal_lahir'] ?? ''}',
              jenisKelaminAwal: '${m['jenis_kelamin'] ?? ''}',
              statusHubunganAwal: '${m['status_hubungan'] ?? ''}',
            ),
            settings,
          );
        case AppRoutes.kontrakEdit:
          final m = _map(args);
          return _slide<bool>(
            EditKontrakPage(
              kontrakId: requireIntArg(m, 'kontrakId'),
              idPenyewa: requireIntArg(m, 'idPenyewa'),
              idKamar: requireIntArg(m, 'idKamar'),
              hargaAwal: '${m['harga'] ?? ''}',
              mulaiAwal: '${m['mulai'] ?? ''}',
              selesaiAwal: '${m['selesai'] ?? ''}',
              siklusAwal: '${m['siklus'] ?? 'bulanan'}',
            ),
            settings,
          );
        case AppRoutes.kontrakDetail:
          final m = _map(args);
          final rawKontrak = m['kontrak'];
          return _slide(
            KontrakDetailPage(
              kontrakId: requireIntArg(m, 'kontrakId'),
              idPenyewa: requireIntArg(m, 'idPenyewa'),
              idKamar: intArg(m, 'idKamar'),
              idKos: intArg(m, 'idKos'),
              initialKontrak: rawKontrak is Map
                  ? Map<String, dynamic>.from(rawKontrak)
                  : null,
            ),
            settings,
          );
        case AppRoutes.tagihanTambah:
          final m = _map(args);
          return _slide<bool>(
            TambahTagihanPage(
              idPenyewa: requireIntArg(m, 'idPenyewa'),
              idKamar: requireIntArg(m, 'id_kamar'),
              idKos: requireIntArg(m, 'id_kos'),
            ),
            settings,
          );
        case AppRoutes.tagihanEdit:
          final m = _map(args);
          return _slide<bool>(
            EditTagihanPage(
              tagihanId: requireIntArg(m, 'tagihanId'),
              idPenyewa: requireIntArg(m, 'idPenyewa'),
            ),
            settings,
          );
        case AppRoutes.detailTagihan:
          final m = _map(args);
          return _slide(
            TagihanDetailPage(
              tagihanId: requireIntArg(m, 'tagihanId'),
              penyewaId: requireIntArg(m, 'penyewaId'),
              idKamar: requireIntArg(m, 'id_kamar'),
              idKos: requireIntArg(m, 'id_kos'),
              kontrakId: intArg(m, 'kontrakId'),
            ),
            settings,
          );
        case AppRoutes.checkInCepat:
          return _slide(const CheckInCepatPage(), settings);
        case AppRoutes.dashboard:
          return _slide(const DashboardPage(), settings);
        case AppRoutes.keuangan:
          return _slide(const KeuanganPage(), settings);
        case AppRoutes.profile:
          return _slide(const ProfilePage(), settings);
        case AppRoutes.settings:
          return _slide(const SettingsPage(), settings);
        default:
          return null;
      }
    } on FormatException catch (e) {
      return _badArgs<bool>(settings, e.message);
    }
  }

  static Map<String, dynamic> _map(Object? args) {
    if (args is Map<String, dynamic>) return args;
    if (args is Map) return Map<String, dynamic>.from(args);
    return {};
  }

  static PageRoute<T> _badArgs<T>(RouteSettings settings, String message) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigasi gagal')),
        body: Padding(
          padding: const EdgeInsets.all(AppDesign.spaceLg),
          child: Text(message),
        ),
      ),
    );
  }

  static PageRoute<T> _fade<T>(Widget child, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }

  static PageRoute<T> _slide<T>(Widget child, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, anim, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}

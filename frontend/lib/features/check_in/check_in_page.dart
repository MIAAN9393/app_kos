import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/widgets/app_menu_tile.dart';
import 'package:kos_management/core/widgets/app_section_header.dart';
import 'package:kos_management/features/check_in/check_in_cepat_page.dart';
import 'package:kos_management/features/penyewa/tambah_penyewa_kontrak.dart';

class CheckInPage extends StatelessWidget {
  const CheckInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In'), centerTitle: true),
      body: ListView(
        children: [
          const AppSectionHeader(
            title: 'Operasional Harian',
            subtitle: 'Penyewa, kontrak, dan tagihan',
          ),
          AppMenuTile(
            title: 'Penyewa Aktif',
            subtitle: 'Lihat dari My Property → Kos → Kamar',
            icon: Icons.people_rounded,
            iconColor: AppColors.icon_penyewa,
            onTap: () => _info(
              context,
              'Buka My Property → List Kos → Detail Kos → List Kamar',
            ),
          ),
          AppMenuTile(
            title: 'Penyewa Non Aktif',
            subtitle: 'Penyewa dengan status nonaktif',
            icon: Icons.person_off_outlined,
            onTap: () => _info(
              context,
              'Fitur filter penyewa nonaktif dari detail kamar',
            ),
          ),
          AppMenuTile(
            title: 'Tagihan Belum Lunas',
            subtitle: 'Tagihan belum_bayar / sebagian / telat',
            icon: Icons.receipt_long_rounded,
            iconColor: Colors.redAccent,
            onTap: () => _info(
              context,
              'Buka detail penyewa untuk melihat list tagihan',
            ),
          ),
          AppMenuTile(
            title: 'Buat Penyewa Baru',
            subtitle: 'POST /api/penyewa/buat_penyewa',
            icon: Icons.person_add_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TambahPenyewaKontrak()),
            ),
          ),
          AppMenuTile(
            title: 'Buat Kontrak Baru',
            subtitle: 'POST /api/kontrak/buat_kontrak',
            icon: Icons.description_outlined,
            iconColor: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TambahPenyewaKontrak()),
            ),
          ),
          const AppSectionHeader(title: 'Check In Cepat'),
          AppMenuTile(
            title: 'Check In Cepat',
            subtitle: 'Pilih Kos → Kamar → Penyewa → Kontrak',
            icon: Icons.flash_on_rounded,
            iconColor: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckInCepatPage()),
            ),
          ),
        ],
      ),
    );
  }

  void _info(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_form_page.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:provider/provider.dart';

class TambahKosPage extends StatefulWidget {
  const TambahKosPage({super.key});

  @override
  State<TambahKosPage> createState() => _TambahKosPageState();
}

class _TambahKosPageState extends State<TambahKosPage> {
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _deskripsi = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_nama.text.trim().isEmpty || _alamat.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Nama dan alamat kos wajib diisi');
      return;
    }
    setState(() => _loading = true);
    final provider = context.read<KosProvider>();
    final ok = await provider.buat_kos_provider(
      nama_kos: _nama.text.trim(),
      alamat: _alamat.text.trim(),
      deskripsi: _deskripsi.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal menambah kos');
      return;
    }
    AppSnackbar.success(context, provider.ambil_pesan_sukses() ?? 'Kos berhasil ditambah');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormPage(
      title: 'Tambah Kos',
      introText:
          'Nama tampil di daftar properti. Alamat wajib diisi; deskripsi boleh kosong.',
      isLoading: _loading,
      saveLabel: 'Buat kos',
      onSave: _simpan,
      children: [
        CustomInput(
          controller: _nama,
          label: 'Nama kos',
          hint: 'Kos Melati',
          icon: Icons.home_work_outlined,
          required: true,
        ),
        CustomInput(
          controller: _alamat,
          label: 'Alamat lengkap',
          hint: 'Jl. Contoh No. 10',
          icon: Icons.location_on_outlined,
          required: true,
        ),
        CustomInput(
          controller: _deskripsi,
          label: 'Deskripsi',
          hint: 'Fasilitas, aturan kos, dll.',
          icon: Icons.description_outlined,
          required: false,
        ),
      ],
    );
  }
}

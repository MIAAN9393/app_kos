import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_form_page.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:provider/provider.dart';

class EditKosPage extends StatefulWidget {
  final int idKos;
  final String namaAwal;
  final String alamatAwal;
  final String deskripsiAwal;

  const EditKosPage({
    super.key,
    required this.idKos,
    required this.namaAwal,
    required this.alamatAwal,
    required this.deskripsiAwal,
  });

  @override
  State<EditKosPage> createState() => _EditKosPageState();
}

class _EditKosPageState extends State<EditKosPage> {
  late final TextEditingController _nama;
  late final TextEditingController _alamat;
  late final TextEditingController _deskripsi;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.namaAwal);
    _alamat = TextEditingController(text: widget.alamatAwal);
    _deskripsi = TextEditingController(text: widget.deskripsiAwal);
  }

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
    final ok = await provider.edit_kos_provider(
      kos_id: widget.idKos,
      nama_kos: _nama.text.trim(),
      alamat: _alamat.text.trim(),
      deskripsi: _deskripsi.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal mengubah kos');
      return;
    }
    AppSnackbar.success(context, provider.ambil_pesan_sukses() ?? 'Kos berhasil diubah');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormPage(
      title: 'Edit Kos',
      introText: 'Perbarui informasi kos. Field bertanda * wajib diisi.',
      isLoading: _loading,
      saveLabel: 'Simpan perubahan',
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
          hint: 'Fasilitas, aturan kos',
          icon: Icons.description_outlined,
          required: false,
        ),
      ],
    );
  }
}

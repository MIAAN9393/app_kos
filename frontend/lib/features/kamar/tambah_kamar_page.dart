import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_form_dialog.dart';
import 'package:kos_management/core/widgets/app_form_page.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/features/kamar/widget/kamar_fasilitas_selector.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';
import 'package:provider/provider.dart';

class TambahKamarPage extends StatefulWidget {
  final int idKos;

  const TambahKamarPage({super.key, required this.idKos});

  @override
  State<TambahKamarPage> createState() => _TambahKamarPageState();
}

class _TambahKamarPageState extends State<TambahKamarPage> {
  final _nomor = TextEditingController();
  final _harga = TextEditingController();
  final _kapasitas = TextEditingController();
  Set<String> _fasilitas = {};
  bool _loading = false;

  @override
  void dispose() {
    _nomor.dispose();
    _harga.dispose();
    _kapasitas.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_nomor.text.trim().isEmpty ||
        _harga.text.trim().isEmpty ||
        _kapasitas.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Lengkapi semua field kamar');
      return;
    }
    final harga = int.tryParse(_harga.text.trim().replaceAll('.', ''));
    final kapasitas = int.tryParse(_kapasitas.text.trim());
    if (harga == null || kapasitas == null) {
      AppSnackbar.error(context, 'Harga dan kapasitas harus angka valid');
      return;
    }
    setState(() => _loading = true);
    final provider = context.read<KamarProvider>();
    final ok = await provider.buat_kamar_provider(
      kos_id: widget.idKos,
      nama_kamar: _nomor.text.trim(),
      harga_kamar: harga,
      kapasitas_kamar: kapasitas,
      fasilitas: KamarFasilitas.toPayload(_fasilitas),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal menambah kamar');
      return;
    }
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Kamar berhasil ditambah',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormPage(
      title: 'Tambah Kamar',
      introText:
          'Nomor kamar, harga sewa per bulan, dan kapasitas maksimal penghuni.',
      isLoading: _loading,
      saveLabel: 'Buat kamar',
      onSave: _simpan,
      children: [
        CustomInput(
          controller: _nomor,
          label: 'Nomor kamar',
          hint: 'A-01',
          icon: Icons.door_front_door_outlined,
          helperText: AppFormHints.nomorKamar,
          required: true,
        ),
        CustomInput(
          controller: _harga,
          label: 'Harga sewa per bulan (Rp)',
          hint: '1500000',
          icon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: angkaSajaFormatter(),
          helperText: AppFormHints.rupiah,
          required: true,
        ),
        CustomInput(
          controller: _kapasitas,
          label: 'Kapasitas (orang)',
          hint: '2',
          icon: Icons.people_outline,
          keyboardType: TextInputType.number,
          inputFormatters: angkaSajaFormatter(),
          helperText: AppFormHints.kapasitas,
          required: true,
        ),
        KamarFasilitasSelector(
          selected: _fasilitas,
          onChanged: (v) => setState(() => _fasilitas = v),
        ),
      ],
    );
  }
}

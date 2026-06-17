import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_form_dialog.dart';
import 'package:kos_management/core/widgets/app_form_page.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/features/kamar/widget/kamar_fasilitas_selector.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';
import 'package:provider/provider.dart';

class EditKamarPage extends StatefulWidget {
  final int idKamar;
  final int idKos;
  final String nomorAwal;
  final String hargaAwal;
  final String kapasitasAwal;
  final List<String> fasilitasAwal;

  const EditKamarPage({
    super.key,
    required this.idKamar,
    required this.idKos,
    required this.nomorAwal,
    required this.hargaAwal,
    required this.kapasitasAwal,
    this.fasilitasAwal = const [],
  });

  @override
  State<EditKamarPage> createState() => _EditKamarPageState();
}

class _EditKamarPageState extends State<EditKamarPage> {
  late final TextEditingController _nomor;
  late final TextEditingController _harga;
  late final TextEditingController _kapasitas;
  late Set<String> _fasilitas;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nomor = TextEditingController(text: widget.nomorAwal);
    _harga = TextEditingController(text: widget.hargaAwal);
    _kapasitas = TextEditingController(text: widget.kapasitasAwal);
    _fasilitas = KamarFasilitas.parse(widget.fasilitasAwal).toSet();
  }

  @override
  void dispose() {
    _nomor.dispose();
    _harga.dispose();
    _kapasitas.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final harga = int.tryParse(_harga.text.trim().replaceAll('.', ''));
    final kapasitas = int.tryParse(_kapasitas.text.trim());
    if (_nomor.text.trim().isEmpty || harga == null || kapasitas == null) {
      AppSnackbar.error(context, 'Data kamar tidak valid');
      return;
    }
    setState(() => _loading = true);
    final provider = context.read<KamarProvider>();
    final ok = await provider.edit_kamar_provider(
      kamar_id: widget.idKamar,
      nama_kamar: _nomor.text.trim(),
      harga_kamar: harga,
      kapasitas_kamar: kapasitas,
      fasilitas: KamarFasilitas.toPayload(_fasilitas),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal mengubah kamar');
      return;
    }
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Kamar berhasil diubah',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormPage(
      title: 'Edit Kamar',
      introText: 'Perbarui nomor, harga, kapasitas, dan fasilitas kamar.',
      isLoading: _loading,
      saveLabel: 'Simpan perubahan',
      onSave: _simpan,
      children: [
        CustomInput(
          controller: _nomor,
          label: 'Nomor kamar',
          hint: 'A-01',
          icon: Icons.door_front_door_outlined,
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

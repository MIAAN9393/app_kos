import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_date_field.dart';
import 'package:kos_management/core/widgets/app_form_dialog.dart';
import 'package:kos_management/core/widgets/app_form_page.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';
import 'package:provider/provider.dart';

class EditKontrakPage extends StatefulWidget {
  final int kontrakId;
  final int idPenyewa;
  final int idKamar;
  final String hargaAwal;
  final String mulaiAwal;
  final String selesaiAwal;
  final String siklusAwal;

  const EditKontrakPage({
    super.key,
    required this.kontrakId,
    required this.idPenyewa,
    required this.idKamar,
    required this.hargaAwal,
    required this.mulaiAwal,
    required this.selesaiAwal,
    this.siklusAwal = 'bulanan',
  });

  @override
  State<EditKontrakPage> createState() => _EditKontrakPageState();
}

class _EditKontrakPageState extends State<EditKontrakPage> {
  late final TextEditingController _harga;
  DateTime? _mulai;
  DateTime? _selesai;
  late String _siklus;
  bool _loading = false;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? _parseDate(String raw) {
    final text = raw.split('T').first.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  @override
  void initState() {
    super.initState();
    _harga = TextEditingController(text: widget.hargaAwal);
    _mulai = _parseDate(widget.mulaiAwal);
    _selesai = _parseDate(widget.selesaiAwal);
    _siklus = widget.siklusAwal;
  }

  @override
  void dispose() {
    _harga.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final harga = int.tryParse(_harga.text.trim().replaceAll('.', ''));
    if (harga == null || harga <= 0) {
      AppSnackbar.error(context, 'Harga sewa tidak valid');
      return;
    }
    if (_mulai == null || _selesai == null) {
      AppSnackbar.error(context, 'Pilih tanggal mulai dan selesai sewa');
      return;
    }
    if (!_selesai!.isAfter(_mulai!)) {
      AppSnackbar.error(context, 'Tanggal selesai harus setelah tanggal mulai');
      return;
    }
    if (!_selesai!.isAfter(_today)) {
      AppSnackbar.error(context, 'Tanggal selesai harus setelah hari ini');
      return;
    }

    setState(() => _loading = true);
    final provider = context.read<KontrakProvider>();
    final ok = await provider.edit_kontrak_provider(
      kontrakId: widget.kontrakId,
      penyewaId: widget.idPenyewa,
      kamarId: widget.idKamar,
      tanggalMulai: TagihanItemUtils.formatTanggalApi(_mulai!),
      tanggalSelesai: TagihanItemUtils.formatTanggalApi(_selesai!),
      hargaSewa: harga,
      siklus: _siklus,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal mengubah kontrak');
      return;
    }
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Kontrak berhasil diubah',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormPage(
      title: 'Edit Kontrak',
      introText:
          'Perubahan hanya diperbolehkan sebelum kontrak mulai berjalan (sesuai aturan sistem).',
      isLoading: _loading,
      saveLabel: 'Simpan kontrak',
      onSave: _simpan,
      children: [
        CustomInput(
          controller: _harga,
          label: 'Harga sewa per siklus (Rp)',
          hint: '1500000',
          icon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: angkaSajaFormatter(),
          helperText: AppFormHints.rupiah,
          required: true,
        ),
        AppDateField(
          label: 'Tanggal mulai sewa',
          value: _mulai,
          icon: Icons.calendar_today_outlined,
          helperText: 'Ketuk untuk pilih tanggal.',
          required: true,
          firstDate: DateTime(_today.year - 1),
          lastDate: _selesai ?? DateTime(_today.year + 5),
          onChanged: (d) => setState(() {
            _mulai = d;
            if (_selesai != null && !_selesai!.isAfter(d)) _selesai = null;
          }),
        ),
        AppDateField(
          label: 'Tanggal selesai sewa',
          value: _selesai,
          icon: Icons.event_outlined,
          helperText: 'Ketuk untuk pilih tanggal. Harus setelah hari ini.',
          required: true,
          firstDate:
              _mulai?.add(const Duration(days: 1)) ??
              _today.add(const Duration(days: 1)),
          lastDate: DateTime(_today.year + 5),
          onChanged: (d) => setState(() => _selesai = d),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Siklus pembayaran *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _siklus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'bulanan', child: Text('Bulanan')),
                  DropdownMenuItem(value: 'mingguan', child: Text('Mingguan')),
                  DropdownMenuItem(value: 'harian', child: Text('Harian')),
                ],
                onChanged: (v) => setState(() => _siklus = v ?? 'bulanan'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

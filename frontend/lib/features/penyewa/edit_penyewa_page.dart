import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_form_dialog.dart';
import 'package:kos_management/core/widgets/app_form_page.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:provider/provider.dart';

class EditPenyewaPage extends StatefulWidget {
  final int idPenyewa;
  final String namaAwal;
  final String telponAwal;
  final String emailAwal;
  final String tanggalLahirAwal;
  final String jenisKelaminAwal;
  final String statusHubunganAwal;

  const EditPenyewaPage({
    super.key,
    required this.idPenyewa,
    required this.namaAwal,
    required this.telponAwal,
    required this.emailAwal,
    this.tanggalLahirAwal = '',
    this.jenisKelaminAwal = '',
    this.statusHubunganAwal = '',
  });

  @override
  State<EditPenyewaPage> createState() => _EditPenyewaPageState();
}

class _EditPenyewaPageState extends State<EditPenyewaPage> {
  late final TextEditingController _nama;
  late final TextEditingController _telpon;
  late final TextEditingController _email;
  late final TextEditingController _tanggalLahir;
  String? _jenisKelamin;
  String? _statusHubungan;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.namaAwal);
    _telpon = TextEditingController(text: widget.telponAwal);
    _email = TextEditingController(text: widget.emailAwal);
    _tanggalLahir = TextEditingController(
      text: _tanggalOnly(widget.tanggalLahirAwal),
    );
    _jenisKelamin = _emptyToNull(widget.jenisKelaminAwal);
    _statusHubungan = _emptyToNull(widget.statusHubunganAwal);
  }

  @override
  void dispose() {
    _nama.dispose();
    _telpon.dispose();
    _email.dispose();
    _tanggalLahir.dispose();
    super.dispose();
  }

  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _tanggalOnly(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    return text.split('T').first;
  }

  bool _tanggalValid(String value) {
    if (value.trim().isEmpty) return true;
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim());
  }

  Future<void> _simpan() async {
    if (_nama.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Nama penyewa wajib diisi');
      return;
    }
    final telpon = _telpon.text.trim().replaceAll(RegExp(r'\D'), '');
    if (telpon.isEmpty) {
      AppSnackbar.error(context, 'Nomor telepon tidak valid');
      return;
    }
    final email = _email.text.trim();
    if (email.isEmpty) {
      AppSnackbar.error(context, 'Email wajib diisi');
      return;
    }
    if (!_tanggalValid(_tanggalLahir.text)) {
      AppSnackbar.error(context, 'Tanggal lahir harus format YYYY-MM-DD');
      return;
    }
    setState(() => _loading = true);
    final provider = context.read<PenyewaProvider>();
    final ok = await provider.edit_penyewa_provider(
      penyewa_id: widget.idPenyewa,
      nama: _nama.text.trim(),
      no_telpon: telpon,
      email: email,
      tanggal_lahir: _emptyToNull(_tanggalLahir.text),
      jenis_kelamin: _jenisKelamin,
      status_hubungan: _statusHubungan,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal mengubah penyewa');
      return;
    }
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Penyewa berhasil diubah',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormPage(
      title: 'Edit Penyewa',
      introText: 'Perbarui nama, nomor telepon, dan email penyewa.',
      isLoading: _loading,
      saveLabel: 'Simpan perubahan',
      onSave: _simpan,
      children: [
        CustomInput(
          controller: _nama,
          label: 'Nama lengkap',
          hint: 'Budi Santoso',
          icon: Icons.person_outline,
          required: true,
        ),
        CustomInput(
          controller: _telpon,
          label: 'Nomor WhatsApp / HP',
          hint: '081234567890',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          helperText: AppFormHints.telepon,
          required: true,
        ),
        CustomInput(
          controller: _email,
          label: 'Email',
          hint: 'budi@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          helperText: AppFormHints.email,
          required: true,
        ),
        CustomInput(
          controller: _tanggalLahir,
          label: 'Tanggal lahir',
          hint: '1998-08-17',
          icon: Icons.cake_outlined,
          keyboardType: TextInputType.datetime,
          helperText: 'Opsional, format YYYY-MM-DD.',
        ),
        _dropdownField(
          label: 'Jenis kelamin',
          value: _jenisKelamin,
          icon: Icons.wc_outlined,
          items: const {'pria': 'Pria', 'wanita': 'Wanita'},
          onChanged: (v) => setState(() => _jenisKelamin = v),
        ),
        _dropdownField(
          label: 'Status hubungan',
          value: _statusHubungan,
          icon: Icons.favorite_border,
          items: const {
            'jomblo': 'Jomblo',
            'pacaran': 'Pacaran',
            'menikah': 'Menikah',
            'duda': 'Duda',
            'janda': 'Janda',
          },
          onChanged: (v) => setState(() => _statusHubungan = v),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required IconData icon,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        initialValue: value != null && items.containsKey(value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 22),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Tidak diisi'),
          ),
          ...items.entries.map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

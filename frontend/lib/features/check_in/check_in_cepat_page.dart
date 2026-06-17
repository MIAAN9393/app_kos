import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_field_decoration.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:provider/provider.dart';

class CheckInCepatPage extends StatefulWidget {
  const CheckInCepatPage({super.key});

  @override
  State<CheckInCepatPage> createState() => _CheckInCepatPageState();
}

class _CheckInCepatPageState extends State<CheckInCepatPage> {
  int _step = 0;
  int? _kosId;
  int? _kamarId;
  int? _penyewaId;

  final _nama = TextEditingController();
  final _telpon = TextEditingController();
  final _email = TextEditingController();
  final _tanggalLahir = TextEditingController();
  final _harga = TextEditingController();
  final _mulai = TextEditingController();
  final _selesai = TextEditingController();
  String? _jenisKelamin;
  String? _statusHubungan;
  String _siklus = 'bulanan';
  bool _pakaiPenyewaNonaktif = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<KosProvider>().ambil_or_update_data();
      context.read<PenyewaProvider>().ambil_semua_penyewa();
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _telpon.dispose();
    _email.dispose();
    _tanggalLahir.dispose();
    _harga.dispose();
    _mulai.dispose();
    _selesai.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0 && _kosId == null) {
      AppSnackbar.error(context, 'Pilih kos terlebih dahulu');
      return;
    }
    if (_step == 1 && _kamarId == null) {
      AppSnackbar.error(context, 'Pilih kamar terlebih dahulu');
      return;
    }
    if (_step == 2) {
      final ok = await _buatPenyewa();
      if (!ok) return;
    }
    if (_step == 3) {
      final ok = await _buatKontrak();
      if (!ok) return;
    }
    if (_step < 4) setState(() => _step++);
  }

  Future<bool> _buatPenyewa() async {
    if (_pakaiPenyewaNonaktif) {
      if (_penyewaId == null) {
        AppSnackbar.error(context, 'Pilih penyewa nonaktif terlebih dahulu');
        return false;
      }
      final provider = context.read<PenyewaProvider>();
      final selected = provider.semua_data_penyewa[_penyewaId];
      if (selected == null ||
          '${selected['status'] ?? ''}'.toLowerCase() != 'nonaktif') {
        AppSnackbar.error(
          context,
          'Penyewa nonaktif tidak valid atau sudah berubah status',
        );
        return false;
      }
      return true;
    }

    if (_nama.text.isEmpty || _telpon.text.isEmpty || _email.text.isEmpty) {
      AppSnackbar.error(context, 'Lengkapi data penyewa');
      return false;
    }
    final telpon = _telpon.text.trim().replaceAll(RegExp(r'\D'), '');
    if (telpon.isEmpty) {
      AppSnackbar.error(context, 'Nomor telepon tidak valid');
      return false;
    }
    if (!_tanggalValid(_tanggalLahir.text)) {
      AppSnackbar.error(context, 'Tanggal lahir harus format YYYY-MM-DD');
      return false;
    }
    final provider = context.read<PenyewaProvider>();
    _penyewaId = await provider.buat_penyewa_provider(
      kamar_id: _kamarId!,
      nama: _nama.text.trim(),
      no_telpon: telpon,
      email: _email.text.trim(),
      tanggal_lahir: _emptyToNull(_tanggalLahir.text),
      jenis_kelamin: _jenisKelamin,
      status_hubungan: _statusHubungan,
    );
    if (!mounted) return false;
    final err = provider.ambil_pesan_error();
    if (err != null) {
      AppSnackbar.error(context, err);
      return false;
    }
    return _penyewaId != null;
  }

  Future<bool> _buatKontrak() async {
    if (_penyewaId == null || _kamarId == null) return false;
    if (_harga.text.isEmpty || _mulai.text.isEmpty || _selesai.text.isEmpty) {
      AppSnackbar.error(context, 'Lengkapi data kontrak');
      return false;
    }
    final harga = int.tryParse(_harga.text.trim().replaceAll('.', ''));
    if (harga == null) {
      AppSnackbar.error(context, 'Harga sewa tidak valid');
      return false;
    }
    final provider = context.read<KontrakProvider>();
    final penyewaProvider = context.read<PenyewaProvider>();
    final kamarProvider = context.read<KamarProvider>();
    final ok = await provider.buat_kontrak_provider(
      penyewaId: _penyewaId!,
      kamarId: _kamarId!,
      tanggalMulai: _mulai.text,
      tanggalSelesai: _selesai.text,
      hargaSewa: harga,
      siklus: _siklus,
    );
    if (!mounted) return false;
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal buat kontrak');
      return false;
    }
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Kontrak berhasil',
    );

    if (_kosId != null) {
      await penyewaProvider.refreshKamar(_kamarId!, kos_id: _kosId);
      await penyewaProvider.ambil_semua_penyewa();
      if (mounted) {
        await kamarProvider.ambil_data_kamar_provider(_kosId!);
      }
    }
    return true;
  }

  List<Map<String, dynamic>> _penyewaNonaktif(PenyewaProvider provider) {
    final list = provider.semua_data_penyewa.values
        .where((e) => '${e['status'] ?? ''}'.toLowerCase() == 'nonaktif')
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    list.sort((a, b) => '${a['nama'] ?? ''}'.compareTo('${b['nama'] ?? ''}'));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In Cepat')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _step < 4 ? _next : null,
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_step < 4)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_step == 3 ? 'Buat Kontrak' : 'Lanjut'),
                  ),
                const SizedBox(width: 12),
                if (_step > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Kembali'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Pilih Kos'),
            isActive: _step >= 0,
            content: _buildPilihKos(),
          ),
          Step(
            title: const Text('Pilih Kamar'),
            isActive: _step >= 1,
            content: _buildPilihKamar(),
          ),
          Step(
            title: const Text('Buat/Pilih Penyewa'),
            isActive: _step >= 2,
            content: _buildPenyewaForm(),
          ),
          Step(
            title: const Text('Buat Kontrak'),
            isActive: _step >= 3,
            content: _buildKontrakForm(),
          ),
          Step(
            title: const Text('Selesai'),
            isActive: _step >= 4,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                Text('Penyewa ID: $_penyewaId'),
                Text('Kamar ID: $_kamarId'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: AppPrimaryButton(
                    label: 'Selesai',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPilihKos() {
    final kos = context.watch<KosProvider>().data_kos;
    return RadioGroup<int>(
      groupValue: _kosId,
      onChanged: (v) => setState(() {
        _kosId = v;
        _kamarId = null;
        _penyewaId = null;
      }),
      child: Column(
        children: kos.map((item) {
          final id = intFromJson(item['id']);
          if (id == null) return const SizedBox.shrink();
          return RadioListTile<int>(
            value: id,
            title: Text('${item['nama_kos']}'),
            subtitle: Text('${item['alamat']}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPilihKamar() {
    if (_kosId == null) return const Text('Pilih kos dulu');
    final kamars = context.watch<KamarProvider>().data_kamar[_kosId] ?? [];
    if (kamars.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<KamarProvider>().ambil_data_kamar_provider(_kosId!);
        }
      });
    }
    return RadioGroup<int>(
      groupValue: _kamarId,
      onChanged: (v) => setState(() {
        _kamarId = v;
        _penyewaId = null;
      }),
      child: Column(
        children: kamars.map((item) {
          final id = intFromJson(item['id']);
          if (id == null) return const SizedBox.shrink();
          return RadioListTile<int>(
            value: id,
            title: Text('Kamar ${item['nomor']}'),
            subtitle: Text('Rp ${item['harga']} • ${item['status_kondisi']}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPenyewaForm() {
    final penyewaProvider = context.watch<PenyewaProvider>();
    final penyewaNonaktif = _penyewaNonaktif(penyewaProvider);
    final selectedValue =
        penyewaNonaktif.any((e) => entityId(e['id']) == _penyewaId)
        ? _penyewaId
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.person_add_alt_1_outlined),
                label: Text('Buat baru'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.person_search_outlined),
                label: Text('Pilih nonaktif'),
              ),
            ],
            selected: {_pakaiPenyewaNonaktif},
            onSelectionChanged: (value) {
              setState(() {
                _pakaiPenyewaNonaktif = value.first;
                _penyewaId = null;
              });
            },
          ),
        ),
        if (_pakaiPenyewaNonaktif) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<int>(
              initialValue: selectedValue,
              isExpanded: true,
              decoration: AppFieldDecoration.input(
                context,
                labelText: 'Pilih penyewa nonaktif',
                helperText: penyewaProvider.loading
                    ? 'Memuat daftar penyewa...'
                    : 'Penyewa terpilih akan dibuatkan kontrak di kamar ini.',
                prefixIcon: Icons.person_search_outlined,
              ),
              items: [
                for (final item in penyewaNonaktif)
                  if (entityId(item['id']) != null)
                    DropdownMenuItem<int>(
                      value: entityId(item['id'])!,
                      child: Text(
                        '${item['nama'] ?? 'Tanpa nama'}'
                        ' · ${item['no_telpon'] ?? '-'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              ],
              onChanged: penyewaNonaktif.isEmpty
                  ? null
                  : (v) => setState(() => _penyewaId = v),
            ),
          ),
        ] else ...[
          CustomInput(
            controller: _nama,
            label: 'Nama Penyewa',
            hint: 'Nama lengkap',
            icon: Icons.person,
          ),
          CustomInput(
            controller: _telpon,
            label: 'No Telepon',
            hint: '08xxxxxxxxxx',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          CustomInput(
            controller: _email,
            label: 'Email',
            hint: 'email@example.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          CustomInput(
            controller: _tanggalLahir,
            label: 'Tanggal Lahir',
            hint: '1998-08-17',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.datetime,
          ),
          _dropdownField(
            label: 'Jenis Kelamin',
            value: _jenisKelamin,
            icon: Icons.wc_outlined,
            items: const {'pria': 'Pria', 'wanita': 'Wanita'},
            onChanged: (v) => setState(() => _jenisKelamin = v),
          ),
          _dropdownField(
            label: 'Status Hubungan',
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
      ],
    );
  }

  Widget _buildKontrakForm() {
    return Column(
      children: [
        CustomInput(
          controller: _harga,
          label: 'Harga Sewa',
          hint: '1000000',
          icon: Icons.payments,
          keyboardType: TextInputType.number,
        ),
        CustomInput(
          controller: _mulai,
          label: 'Tanggal Mulai (YYYY-MM-DD)',
          hint: '2026-06-01',
          icon: Icons.calendar_today,
        ),
        CustomInput(
          controller: _selesai,
          label: 'Tanggal Selesai (YYYY-MM-DD)',
          hint: '2027-06-01',
          icon: Icons.event,
        ),
        DropdownButtonFormField<String>(
          initialValue: _siklus,
          decoration: AppFieldDecoration.input(
            context,
            labelText: 'Siklus',
            prefixIcon: Icons.loop_rounded,
          ),
          items: const [
            DropdownMenuItem(value: 'bulanan', child: Text('Bulanan')),
            DropdownMenuItem(value: 'mingguan', child: Text('Mingguan')),
            DropdownMenuItem(value: 'harian', child: Text('Harian')),
          ],
          onChanged: (v) => setState(() => _siklus = v ?? 'bulanan'),
        ),
      ],
    );
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  bool _tanggalValid(String value) {
    if (value.trim().isEmpty) return true;
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim());
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required IconData icon,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value != null && items.containsKey(value) ? value : null,
        decoration: AppFieldDecoration.input(
          context,
          labelText: label,
          prefixIcon: icon,
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

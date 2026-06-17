import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_date_field.dart';
import 'package:kos_management/core/widgets/app_form_dialog.dart';
import 'package:kos_management/core/widgets/app_form_page.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';
import 'package:provider/provider.dart';

class TambahPenyewaKontrak extends StatefulWidget {
  final int? idKamar;
  final int? idKos;

  const TambahPenyewaKontrak({super.key, this.idKamar, this.idKos});

  @override
  State<TambahPenyewaKontrak> createState() => _TambahPenyewaKontrakState();
}

class _TambahPenyewaKontrakState extends State<TambahPenyewaKontrak> {
  final _nama = TextEditingController();
  final _telpon = TextEditingController();
  final _email = TextEditingController();
  final _harga = TextEditingController();
  DateTime? _tanggalLahir;
  DateTime? _mulai;
  DateTime? _selesai;
  String? _jenisKelamin;
  String? _statusHubungan;
  int? _idKosDipilih;
  int? _idKamarDipilih;
  int? _penyewaDipilihId;
  String _siklus = 'bulanan';
  bool _pakaiPenyewaNonaktif = false;
  bool _loading = false;
  bool _loadingPilihanKamar = false;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _idKosDipilih = widget.idKos;
    _idKamarDipilih = widget.idKamar;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _muatDataAwal();
    });
  }

  Future<void> _muatDataAwal() async {
    final penyewaProvider = context.read<PenyewaProvider>();
    final kosProvider = context.read<KosProvider>();
    final kamarProvider = context.read<KamarProvider>();
    final kontrakProvider = context.read<KontrakProvider>();

    await Future.wait([
      penyewaProvider.ambil_semua_penyewa(),
      kosProvider.ambil_or_update_data(),
      kontrakProvider.ambil_semua_kontrak(),
    ]);

    if (!mounted) return;
    final kosId = _idKosDipilih;
    if (kosId != null) {
      await kamarProvider.ambil_data_kamar_provider(kosId);
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _telpon.dispose();
    _email.dispose();
    _harga.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final idKamar = _idKamarDipilih;
    final idKos = _idKosDipilih;
    if (idKamar == null) {
      AppSnackbar.error(context, 'Kamar belum dipilih');
      return;
    }
    if (_pakaiPenyewaNonaktif) {
      if (_penyewaDipilihId == null) {
        AppSnackbar.error(context, 'Pilih penyewa nonaktif terlebih dahulu');
        return;
      }
    } else {
      if (_nama.text.trim().isEmpty ||
          _telpon.text.trim().isEmpty ||
          _email.text.trim().isEmpty) {
        AppSnackbar.error(context, 'Lengkapi semua field penyewa (bertanda *)');
        return;
      }
    }
    if (_harga.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Lengkapi semua field kontrak (bertanda *)');
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

    final harga = int.tryParse(_harga.text.trim().replaceAll('.', ''));
    if (harga == null) {
      AppSnackbar.error(context, 'Harga sewa tidak valid');
      return;
    }

    final kamarProvider = context.read<KamarProvider>();
    final kontrakProvider = context.read<KontrakProvider>();
    final tersedia = _kamarTersedia(
      kamarProvider,
      idKos,
      kontrakProvider,
    ).any((kamar) => entityId(kamar['id']) == idKamar);
    if (!tersedia) {
      AppSnackbar.error(
        context,
        'Kamar tidak tersedia untuk periode tanggal yang dipilih',
      );
      return;
    }

    setState(() => _loading = true);

    final penyewaProvider = context.read<PenyewaProvider>();
    final kosProvider = context.read<KosProvider>();
    int penyewaId;
    String pesanSukses = 'Penyewa dan kontrak berhasil dibuat';

    if (_pakaiPenyewaNonaktif) {
      final selected = penyewaProvider.semua_data_penyewa[_penyewaDipilihId];
      if (selected == null ||
          '${selected['status'] ?? ''}'.toLowerCase() != 'nonaktif') {
        if (mounted) {
          setState(() => _loading = false);
          AppSnackbar.error(
            context,
            'Penyewa nonaktif tidak valid atau sudah berubah status',
          );
        }
        return;
      }
      penyewaId = _penyewaDipilihId!;
      pesanSukses = 'Kontrak berhasil dibuat untuk penyewa terpilih';
    } else {
      final telponText = _telpon.text.trim().replaceAll(RegExp(r'\D'), '');
      if (telponText.isEmpty) {
        if (mounted) {
          setState(() => _loading = false);
          AppSnackbar.error(context, 'Nomor telepon tidak valid');
        }
        return;
      }

      final createdId = await penyewaProvider.buat_penyewa_provider(
        kamar_id: idKamar,
        nama: _nama.text.trim(),
        no_telpon: telponText,
        email: _email.text.trim(),
        tanggal_lahir: _tanggalLahir == null
            ? null
            : TagihanItemUtils.formatTanggalApi(_tanggalLahir!),
        jenis_kelamin: _jenisKelamin,
        status_hubungan: _statusHubungan,
      );

      final err = penyewaProvider.ambil_pesan_error();
      if (createdId == null || err != null) {
        if (!mounted) return;
        setState(() => _loading = false);
        AppSnackbar.error(context, err ?? 'Penyewa gagal dibuat');
        return;
      }
      penyewaId = createdId;
    }

    final ok = await kontrakProvider.buat_kontrak_provider(
      penyewaId: penyewaId,
      kamarId: idKamar,
      tanggalMulai: TagihanItemUtils.formatTanggalApi(_mulai!),
      tanggalSelesai: TagihanItemUtils.formatTanggalApi(_selesai!),
      hargaSewa: harga,
      siklus: _siklus,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    final err = kontrakProvider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal buat kontrak');
      return;
    }

    await penyewaProvider.refreshKamar(idKamar, kos_id: idKos);
    await penyewaProvider.ambil_semua_penyewa();
    if (!mounted) return;
    if (idKos != null) {
      await kamarProvider.ambil_data_kamar_provider(idKos);
      await kosProvider.ambil_data_kos_provider();
    }

    if (!mounted) return;
    AppSnackbar.success(context, pesanSukses);
    Navigator.pop(context);
  }

  List<Map<String, dynamic>> _penyewaNonaktif(PenyewaProvider provider) {
    final list = provider.semua_data_penyewa.values
        .where((e) => '${e['status'] ?? ''}'.toLowerCase() == 'nonaktif')
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    list.sort((a, b) => '${a['nama'] ?? ''}'.compareTo('${b['nama'] ?? ''}'));
    return list;
  }

  List<Map<String, dynamic>> _kamarTersedia(
    KamarProvider provider,
    int? kosId,
    KontrakProvider kontrakProvider,
  ) {
    if (kosId == null) return const [];
    final list = provider.data_kamar[kosId] ?? const [];
    return list.where((kamar) {
      final status = '${kamar['status'] ?? 'aktif'}'.toLowerCase();
      if (status != 'aktif') return false;

      final kapasitas = int.tryParse('${kamar['kapasitas']}') ?? 0;
      final kamarId = entityId(kamar['id']);
      if (kamarId == null || kapasitas <= 0) return false;

      if (_mulai == null || _selesai == null) {
        final statusKondisi = '${kamar['status_kondisi'] ?? ''}'.toLowerCase();
        return statusKondisi != 'penuh';
      }

      final jumlahTerbooking = kontrakProvider.semua_data_kontrak.values
          .where((kontrak) => _kontrakMengisiKamarPadaPeriode(kontrak, kamarId))
          .length;

      return jumlahTerbooking < kapasitas;
    }).toList();
  }

  DateTime? _parseTanggal(dynamic raw) {
    final text = '${raw ?? ''}'.split('T').first.trim();
    if (text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }

  bool _periodeOverlap(DateTime a0, DateTime a1, DateTime b0, DateTime b1) {
    final awalA = DateTime(a0.year, a0.month, a0.day);
    final akhirA = DateTime(a1.year, a1.month, a1.day);
    final awalB = DateTime(b0.year, b0.month, b0.day);
    final akhirB = DateTime(b1.year, b1.month, b1.day);
    return !awalA.isAfter(akhirB) && !awalB.isAfter(akhirA);
  }

  bool _kontrakMengisiKamarPadaPeriode(
    Map<String, dynamic> kontrak,
    int kamarId,
  ) {
    final status = '${kontrak['status'] ?? ''}'.toLowerCase();
    if (status != 'aktif' && status != 'pending') return false;

    final kontrakKamarId = entityId(kontrak['kamar_id']);
    if (kontrakKamarId != kamarId) return false;

    final mulai = _parseTanggal(kontrak['tanggal_mulai']);
    final selesai = _parseTanggal(kontrak['tanggal_selesai']);
    if (mulai == null ||
        selesai == null ||
        _mulai == null ||
        _selesai == null) {
      return false;
    }

    return _periodeOverlap(_mulai!, _selesai!, mulai, selesai);
  }

  Future<void> _pilihKos(int? kosId) async {
    setState(() {
      _idKosDipilih = kosId;
      _idKamarDipilih = null;
      _loadingPilihanKamar = kosId != null;
    });

    if (kosId == null) {
      setState(() => _loadingPilihanKamar = false);
      return;
    }

    await context.read<KamarProvider>().ambil_data_kamar_provider(kosId);
    if (!mounted) return;
    setState(() => _loadingPilihanKamar = false);
  }

  Widget _pilihKamarSection(
    KosProvider kosProvider,
    KamarProvider kamarProvider,
    KontrakProvider kontrakProvider,
  ) {
    if (widget.idKamar != null) return const SizedBox.shrink();

    final kosList = kosProvider.data_kos;
    final selectedKos =
        kosList.any((kos) => entityId(kos['id']) == _idKosDipilih)
        ? _idKosDipilih
        : null;
    final kamarList = _kamarTersedia(
      kamarProvider,
      selectedKos,
      kontrakProvider,
    );
    final selectedKamar =
        kamarList.any((kamar) => entityId(kamar['id']) == _idKamarDipilih)
        ? _idKamarDipilih
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppFormSectionLabel('PILIH KAMAR'),
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: DropdownButtonFormField<int>(
            initialValue: selectedKos,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Kos *',
              helperText: kosProvider.loading
                  ? 'Memuat daftar kos...'
                  : 'Pilih kos untuk melihat kamar tersedia.',
              prefixIcon: const Icon(Icons.home_work_outlined, size: 22),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              for (final kos in kosList)
                if (entityId(kos['id']) != null)
                  DropdownMenuItem<int>(
                    value: entityId(kos['id'])!,
                    child: Text(
                      '${kos['nama_kos'] ?? 'Kos tanpa nama'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
            onChanged: kosList.isEmpty ? null : _pilihKos,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: DropdownButtonFormField<int>(
            initialValue: selectedKamar,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Kamar aktif belum penuh *',
              helperText: _loadingPilihanKamar || kamarProvider.loading
                  ? 'Memuat daftar kamar...'
                  : selectedKos == null
                  ? 'Pilih kos terlebih dahulu.'
                  : _mulai == null || _selesai == null
                  ? 'Pilih tanggal sewa agar booking pending ikut dihitung.'
                  : 'Kamar aktif yang belum penuh pada periode terpilih.',
              prefixIcon: const Icon(Icons.meeting_room_outlined, size: 22),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              for (final kamar in kamarList)
                if (entityId(kamar['id']) != null)
                  DropdownMenuItem<int>(
                    value: entityId(kamar['id'])!,
                    child: Text(
                      'Kamar ${kamar['nomor'] ?? '-'}'
                      ' · ${kamar['status_kondisi'] ?? '-'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
            onChanged: kamarList.isEmpty
                ? null
                : (v) => setState(() => _idKamarDipilih = v),
          ),
        ),
      ],
    );
  }

  Widget _modePenyewaField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
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
            if (!_pakaiPenyewaNonaktif) {
              _penyewaDipilihId = null;
            }
          });
        },
      ),
    );
  }

  Widget _pilihPenyewaNonaktifField(
    List<Map<String, dynamic>> penyewaNonaktif,
    bool loading,
  ) {
    final selectedValue =
        penyewaNonaktif.any((e) => entityId(e['id']) == _penyewaDipilihId)
        ? _penyewaDipilihId
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<int>(
        initialValue: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Pilih penyewa nonaktif *',
          helperText: loading
              ? 'Memuat daftar penyewa...'
              : 'Penyewa terpilih akan dibuatkan kontrak di kamar ini.',
          prefixIcon: const Icon(Icons.person_search_outlined, size: 22),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            : (v) => setState(() => _penyewaDipilihId = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final penyewaProvider = context.watch<PenyewaProvider>();
    final kosProvider = context.watch<KosProvider>();
    final kamarProvider = context.watch<KamarProvider>();
    final kontrakProvider = context.watch<KontrakProvider>();
    final penyewaNonaktif = _penyewaNonaktif(penyewaProvider);

    return AppFormPage(
      title: 'Tambah Penyewa + Kontrak',
      introText:
          'Isi dua bagian berikut. Field bertanda * wajib diisi. '
          'Setelah penyewa dibuat, kontrak akan menghubungkan penyewa ke kamar.',
      isLoading: _loading,
      saveLabel: 'Simpan penyewa & kontrak',
      onSave: _simpan,
      children: [
        _pilihKamarSection(kosProvider, kamarProvider, kontrakProvider),
        const AppFormSectionLabel('DATA PENYEWA'),
        _modePenyewaField(),
        if (_pakaiPenyewaNonaktif) ...[
          _pilihPenyewaNonaktifField(penyewaNonaktif, penyewaProvider.loading),
        ] else ...[
          CustomInput(
            controller: _nama,
            label: 'Nama lengkap',
            hint: 'Contoh: Budi Santoso',
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
          AppDateField(
            label: 'Tanggal lahir',
            value: _tanggalLahir,
            icon: Icons.cake_outlined,
            helperText: 'Opsional. Ketuk untuk pilih tanggal.',
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _tanggalLahir = d),
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
        const SizedBox(height: 8),
        const AppFormSectionLabel('DATA KONTRAK SEWA'),
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
              const SizedBox(height: 4),
              Text(
                'Seberapa sering tagihan dibuat untuk kontrak ini.',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_date_field.dart';
import 'package:kos_management/core/widgets/app_form_page.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/features/tagihan/widget/tagihan_items_editor.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';
import 'package:kos_management/utils/tagihan_rules.dart';
import 'package:provider/provider.dart';

class TambahTagihanPage extends StatefulWidget {
  final int idPenyewa;
  final int idKamar;
  final int idKos;

  const TambahTagihanPage({
    super.key,
    required this.idPenyewa,
    required this.idKamar,
    required this.idKos,
  });

  @override
  State<TambahTagihanPage> createState() => _TambahTagihanPageState();
}

class _TambahTagihanPageState extends State<TambahTagihanPage> {
  final _editorKey = GlobalKey<TagihanItemsEditorState>();
  final _catatan = TextEditingController();
  DateTime? _awal;
  DateTime? _akhir;
  DateTime? _jatuh;
  bool _loading = false;
  List<Map<String, dynamic>> _items = [TagihanItemUtils.itemBaru()];
  String? _blokirKontrak;
  int? _hargaKamar;
  int? _hargaKontrak;
  int? _kontrakId;
  Map<String, dynamic>? _kontrak;
  DateTime? _kontrakMulai;
  DateTime? _kontrakSelesai;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cekKontrak());
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _cekKontrak() async {
    final kontrakProv = context.read<KontrakProvider>();
    final tagihanProv = context.read<TagihanProvider>();
    final kamarProv = context.read<KamarProvider>();
    await kontrakProv.ambil_kontrak_provider(widget.idPenyewa, force: true);
    await tagihanProv.ambil_data_tagihan_provider(widget.idPenyewa);
    await kamarProv.ambil_data_kamar_provider(widget.idKos);
    if (!mounted) return;
    final kontrak = kontrakProv.kontrakByPenyewa[widget.idPenyewa];
    final kontrakId = int.tryParse('${kontrak?['id']}');
    if (kontrakId != null) {
      await tagihanProv.ambil_tagihan_by_kontrak_provider(
        kontrakId,
        penyewa_id: widget.idPenyewa,
        force: true,
      );
    }
    final kamar =
        kamarProv.kamar_by_id[widget.idKamar] ??
        kamarProv.ambil_datasiap_kamar_by_id(widget.idKamar);
    setState(() {
      _blokirKontrak = TagihanRules.pesanKontrakUntukBuatTagihan(kontrak);
      _hargaKontrak = int.tryParse('${kontrak?['harga_sewa']}');
      _hargaKamar = int.tryParse('${kamar?['harga']}');
      _kontrakId = kontrakId;
      _kontrak = kontrak == null ? null : Map<String, dynamic>.from(kontrak);
      _kontrakMulai = TagihanRules.parseTanggal(kontrak?['tanggal_mulai']);
      _kontrakSelesai = TagihanRules.parseTanggal(kontrak?['tanggal_selesai']);
    });
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_loading) return;
    if (_blokirKontrak != null) {
      AppSnackbar.error(context, _blokirKontrak!);
      return;
    }
    _items = _editorKey.currentState?.exportItems() ?? _items;
    final err = TagihanItemUtils.validasiItems(_items);
    if (err != null) {
      AppSnackbar.error(context, err);
      return;
    }
    if (_awal == null || _akhir == null || _jatuh == null) {
      AppSnackbar.error(context, 'Lengkapi semua tanggal tagihan');
      return;
    }

    final errPeriode = TagihanItemUtils.validasiPeriode(
      periodeAwal: _awal!,
      periodeAkhir: _akhir!,
      jatuhTempo: _jatuh!,
    );
    if (errPeriode != null) {
      AppSnackbar.error(context, errPeriode);
      return;
    }
    final errPeriodeKontrak = TagihanRules.pesanPeriodeDalamKontrak(
      kontrak: _kontrak,
      periodeAwal: _awal!,
      periodeAkhir: _akhir!,
    );
    if (errPeriodeKontrak != null) {
      AppSnackbar.error(context, errPeriodeKontrak);
      return;
    }

    final tagihanProv = context.read<TagihanProvider>();
    final tagihanList = _kontrakId == null
        ? tagihanProv.data_tagihan[widget.idPenyewa] ?? []
        : tagihanProv.data_tagihan_by_kontrak[_kontrakId] ?? [];
    final duplikat = TagihanRules.pesanDuplikatSewaPeriode(
      tagihanList: tagihanList,
      periodeAwal: _awal!,
      periodeAkhir: _akhir!,
      listItemBaru: _items,
    );
    if (duplikat != null) {
      AppSnackbar.error(context, duplikat);
      return;
    }

    setState(() => _loading = true);
    final provider = tagihanProv;
    final ok = await provider.buat_tagihan_provider(
      penyewa_id: widget.idPenyewa,
      periode_awal: _awal!,
      periode_akhir: _akhir!,
      jatuh_tempo: _jatuh!,
      list_item: _items,
      catatan: _catatan.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      final apiErr = provider.ambil_pesan_error();
      if (apiErr != null) AppSnackbar.error(context, apiErr);
      return;
    }
    final msg = provider.ambil_pesan_sukses();
    if (msg != null) AppSnackbar.success(context, msg);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _blokirKontrak != null;
    final batasMulai = _kontrakMulai ?? DateTime(_today.year - 1);
    final batasSelesai = DateTime(_today.year + 2);
    final batasAwalAkhir = _kontrakSelesai == null
        ? (_akhir ?? DateTime(_today.year + 2))
        : (_akhir != null && _akhir!.isBefore(_kontrakSelesai!)
              ? _akhir!
              : _kontrakSelesai!);

    return AppFormPage(
      title: 'Tambah Tagihan',
      introText:
          _blokirKontrak ??
          'Buat tagihan untuk kontrak aktif. Periode awal harus berada di masa kontrak. Periode akhir harus setelah hari ini. '
              'Hanya satu item SEWA per periode yang tumpang tindih. Total dihitung otomatis.',
      isLoading: _loading,
      saveLabel: 'Buat tagihan',
      onSave: _simpan,
      children: [
        TagihanItemsEditor(
          key: _editorKey,
          items: _items,
          onChanged: (v) => _items = v,
          hargaKamar: _hargaKamar,
          hargaKontrak: _hargaKontrak,
        ),
        const SizedBox(height: 16),
        AppDateField(
          label: 'Periode awal',
          value: _awal,
          icon: Icons.date_range_outlined,
          helperText:
              'Ketuk untuk pilih tanggal. Tidak boleh sebelum mulai kontrak.',
          required: true,
          enabled: !blocked,
          firstDate: batasMulai,
          lastDate: batasAwalAkhir,
          onChanged: (d) => setState(() {
            _awal = d;
            if (_akhir != null && _akhir!.isBefore(d)) _akhir = null;
            if (_jatuh != null &&
                (_jatuh!.isBefore(d) ||
                    (_akhir != null && _jatuh!.isAfter(_akhir!)))) {
              _jatuh = null;
            }
          }),
        ),
        AppDateField(
          label: 'Periode akhir',
          value: _akhir,
          icon: Icons.date_range_outlined,
          helperText: 'Ketuk untuk pilih tanggal. Harus setelah hari ini.',
          required: true,
          enabled: !blocked,
          firstDate: _awal ?? batasMulai,
          lastDate: batasSelesai,
          onChanged: (d) => setState(() {
            _akhir = d;
            if (_jatuh != null &&
                (_awal != null && _jatuh!.isBefore(_awal!) ||
                    _jatuh!.isAfter(d))) {
              _jatuh = null;
            }
          }),
        ),
        AppDateField(
          label: 'Jatuh tempo',
          value: _jatuh,
          icon: Icons.event_outlined,
          helperText:
              'Ketuk untuk pilih tanggal (antara periode awal & akhir).',
          required: true,
          enabled: !blocked && _awal != null && _akhir != null,
          firstDate: _awal,
          lastDate: _akhir,
          onChanged: (d) => setState(() => _jatuh = d),
        ),
        CustomInput(
          controller: _catatan,
          label: 'Catatan',
          hint: 'Misal: termasuk listrik',
          icon: Icons.note_outlined,
          required: false,
        ),
      ],
    );
  }
}

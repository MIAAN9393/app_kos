import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_date_field.dart';
import 'package:kos_management/core/widgets/app_form_page.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/features/tagihan/widget/tagihan_items_editor.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';
import 'package:kos_management/utils/tagihan_rules.dart';
import 'package:provider/provider.dart';

class EditTagihanPage extends StatefulWidget {
  final int tagihanId;
  final int idPenyewa;

  const EditTagihanPage({
    super.key,
    required this.tagihanId,
    required this.idPenyewa,
  });

  @override
  State<EditTagihanPage> createState() => _EditTagihanPageState();
}

class _EditTagihanPageState extends State<EditTagihanPage> {
  final _editorKey = GlobalKey<TagihanItemsEditorState>();
  final _catatan = TextEditingController();
  DateTime? _awal;
  DateTime? _akhir;
  DateTime? _jatuh;
  bool _loading = false;
  bool _loadingData = true;
  List<Map<String, dynamic>> _items = [];
  String? _blokirEdit;
  int? _hargaKamar;
  int? _hargaKontrak;
  int? _kontrakIdTagihan;
  Map<String, dynamic>? _kontrakTagihan;
  DateTime? _kontrakMulai;
  DateTime? _kontrakSelesai;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatData());
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? _parseStoredDate(dynamic raw) {
    final text = '${raw ?? ''}'.split('T').first.trim();
    if (text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }

  Future<void> _muatHargaReferensi() async {
    final kontrakProv = context.read<KontrakProvider>();
    final kamarProv = context.read<KamarProvider>();
    await kontrakProv.ambil_kontrak_provider(widget.idPenyewa, force: true);
    if (!mounted) return;

    final kontrak = kontrakProv.kontrakByPenyewa[widget.idPenyewa];
    final kamarId =
        entityId(kontrak?['kamar_id']) ??
        (kontrak?['kamar'] is Map
            ? entityId((kontrak!['kamar'] as Map)['id'])
            : null);

    Map<String, dynamic>? kamar;
    if (kamarId != null) {
      final kosId = kamarProv.cari_kos_id(kamarId);
      if (kosId != null) {
        await kamarProv.ambil_data_kamar_provider(kosId);
      }
      kamar =
          kamarProv.kamar_by_id[kamarId] ??
          kamarProv.ambil_datasiap_kamar_by_id(kamarId);
    }

    if (!mounted) return;
    setState(() {
      _hargaKontrak = int.tryParse('${kontrak?['harga_sewa']}');
      _hargaKamar = int.tryParse('${kamar?['harga']}');
    });
  }

  Future<void> _muatData() async {
    final provider = context.read<TagihanProvider>();
    provider.ubah_status_flag_true(widget.idPenyewa);
    await provider.ambil_data_tagihan_provider(widget.idPenyewa);
    await _muatHargaReferensi();
    if (!mounted) return;

    final tagihan = provider.ambil_datasiap_tagihan_by_id(widget.tagihanId);
    if (tagihan == null) {
      setState(() => _loadingData = false);
      AppSnackbar.error(context, 'Data tagihan tidak ditemukan');
      return;
    }
    final kontrakIdTagihan = entityId(tagihan['kontrak_id']);
    Map<String, dynamic>? kontrakTagihan;
    if (kontrakIdTagihan != null) {
      final kontrakProv = context.read<KontrakProvider>();
      final listKontrak = await kontrakProv.ambil_list_kontrak_penyewa(
        widget.idPenyewa,
        force: true,
      );
      for (final kontrak in listKontrak) {
        if (idEquals(kontrak['id'], kontrakIdTagihan)) {
          kontrakTagihan = kontrak;
          break;
        }
      }
      if (!mounted) return;
    }
    if (kontrakIdTagihan != null) {
      await provider.ambil_tagihan_by_kontrak_provider(
        kontrakIdTagihan,
        penyewa_id: widget.idPenyewa,
        force: true,
      );
      if (!mounted) return;
    }

    final blokir = TagihanRules.isCancelled(tagihan)
        ? 'Tagihan sudah dibatalkan'
        : EntityActionRules.pesanUbahTagihan(tagihan);

    _awal = _parseStoredDate(tagihan['periode_awal']);
    _akhir = _parseStoredDate(tagihan['periode_akhir']);
    _jatuh = _parseStoredDate(tagihan['jatuh_tempo']);
    _catatan.text = '${tagihan['catatan'] ?? ''}';

    final items = TagihanItemUtils.parseItems(tagihan['items']);
    setState(() {
      _items = items.isNotEmpty
          ? items.map((e) {
              final m = Map<String, dynamic>.from(e);
              m.remove('id');
              return m;
            }).toList()
          : [TagihanItemUtils.itemBaru()];
      _blokirEdit = blokir;
      _kontrakIdTagihan = kontrakIdTagihan;
      _kontrakTagihan = kontrakTagihan;
      _kontrakMulai = TagihanRules.parseTanggal(
        kontrakTagihan?['tanggal_mulai'],
      );
      _kontrakSelesai = TagihanRules.parseTanggal(
        kontrakTagihan?['tanggal_selesai'],
      );
      _hargaKontrak =
          int.tryParse('${kontrakTagihan?['harga_sewa']}') ?? _hargaKontrak;
      _loadingData = false;
    });
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_loading) return;
    if (_blokirEdit != null) {
      AppSnackbar.error(context, _blokirEdit!);
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
      kontrak: _kontrakTagihan,
      periodeAwal: _awal!,
      periodeAkhir: _akhir!,
    );
    if (errPeriodeKontrak != null) {
      AppSnackbar.error(context, errPeriodeKontrak);
      return;
    }

    final tagihanProv = context.read<TagihanProvider>();
    final tagihanList = _kontrakIdTagihan == null
        ? tagihanProv.data_tagihan[widget.idPenyewa] ?? []
        : tagihanProv.data_tagihan_by_kontrak[_kontrakIdTagihan] ?? [];
    final duplikat = TagihanRules.pesanDuplikatSewaPeriode(
      tagihanList: tagihanList,
      periodeAwal: _awal!,
      periodeAkhir: _akhir!,
      listItemBaru: _items,
      excludeTagihanId: widget.tagihanId,
    );
    if (duplikat != null) {
      AppSnackbar.error(context, duplikat);
      return;
    }

    setState(() => _loading = true);
    final provider = tagihanProv;
    final ok = await provider.edit_tagihan_provider(
      tagihan_id: widget.tagihanId,
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
    if (_loadingData) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(title: const Text('Edit Tagihan')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final blocked = _blokirEdit != null;
    final batasMulai = _kontrakMulai ?? DateTime(_today.year - 1);
    final batasSelesai = DateTime(_today.year + 2);
    final batasAwalAkhir = _kontrakSelesai == null
        ? (_akhir ?? DateTime(_today.year + 2))
        : (_akhir != null && _akhir!.isBefore(_kontrakSelesai!)
              ? _akhir!
              : _kontrakSelesai!);

    return AppFormPage(
      title: 'Edit Tagihan',
      introText:
          _blokirEdit ??
          'Perbarui periode, jatuh tempo, dan rincian item. Periode awal harus berada di masa kontrak. Periode akhir harus setelah hari ini. '
              'Hanya satu item SEWA per periode tumpang tindih (tagihan lain). '
              'Hanya bisa disimpan jika belum ada pembayaran.',
      isLoading: _loading,
      saveLabel: 'Simpan perubahan',
      onSave: _blokirEdit == null ? _simpan : null,
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
          helperText: 'Ketuk untuk pilih tanggal.',
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
          hint: 'Opsional',
          icon: Icons.note_outlined,
          required: false,
        ),
      ],
    );
  }
}

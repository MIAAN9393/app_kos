import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_field_decoration.dart';
import 'package:kos_management/core/widgets/app_form_dialog.dart';
import 'package:kos_management/core/widgets/app_outlined_action.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/providers/pengaturan_otomatis_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:provider/provider.dart';

String _tanggal(dynamic value) {
  final text = '${value ?? ''}'.trim();
  if (text.isEmpty || text == 'null') return '-';
  return text.split('T').first;
}

String _labelSiklus(String raw) {
  switch (raw.toLowerCase()) {
    case 'tahunan':
      return 'Tahunan';
    case 'bulanan':
      return 'Bulanan';
    case 'mingguan':
      return 'Mingguan';
    case 'harian':
      return 'Harian';
    default:
      return raw.isEmpty ? '-' : raw;
  }
}

Future<void> showPengaturanPerpanjanganOtomatisSheet(
  BuildContext context,
  Map<String, dynamic> kontrak,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PengaturanOtomatisSheet(
      child: PengaturanPerpanjanganOtomatisPanel(kontrak: kontrak),
    ),
  );
}

Future<void> showPengaturanTagihanOtomatisSheet(
  BuildContext context,
  Map<String, dynamic>? kontrak,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PengaturanOtomatisSheet(
      child: PengaturanTagihanOtomatisPanel(kontrak: kontrak),
    ),
  );
}

class PengaturanOtomatisButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const PengaturanOtomatisButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppOutlinedAction(
      icon: icon,
      label: label,
      onTap: onPressed,
      compact: true,
      accentColor: AppDesign.info,
    );
  }
}

class _PengaturanOtomatisSheet extends StatelessWidget {
  final Widget child;

  const _PengaturanOtomatisSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.66,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Material(
          color: AppDesign.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppDesign.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}

class PengaturanPerpanjanganOtomatisPanel extends StatefulWidget {
  final Map<String, dynamic> kontrak;

  const PengaturanPerpanjanganOtomatisPanel({super.key, required this.kontrak});

  @override
  State<PengaturanPerpanjanganOtomatisPanel> createState() =>
      _PengaturanPerpanjanganOtomatisPanelState();
}

class _PengaturanPerpanjanganOtomatisPanelState
    extends State<PengaturanPerpanjanganOtomatisPanel> {
  final _jumlah = TextEditingController(text: '1');
  final _hari = TextEditingController(text: '30');
  final _harga = TextEditingController();
  String _jenis = 'bulanan';
  bool _aktif = true;
  bool _editMode = false;
  String? _loadError;

  int? get _kontrakId => entityId(widget.kontrak['id']);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _muat();
    });
  }

  @override
  void didUpdateWidget(PengaturanPerpanjanganOtomatisPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (entityId(oldWidget.kontrak['id']) != _kontrakId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _muat(force: true);
      });
    }
  }

  @override
  void dispose() {
    _jumlah.dispose();
    _hari.dispose();
    _harga.dispose();
    super.dispose();
  }

  Future<void> _muat({bool force = false}) async {
    final id = _kontrakId;
    if (id == null) return;
    final provider = context.read<PengaturanOtomatisProvider>();
    await provider.ambilPerpanjangan(id, force: force);
    if (!mounted) return;
    final err = provider.ambil_pesan_error();
    _loadError = err;
    _isiForm(provider.perpanjanganByKontrak[id]);
  }

  void _isiForm(Map<String, dynamic>? data) {
    if (data == null) {
      _jenis = '${widget.kontrak['siklus'] ?? 'bulanan'}';
      _jumlah.text = '1';
      _hari.text = '30';
      _harga.clear();
      _aktif = true;
      _editMode = false;
      setState(() {});
      return;
    }
    _jenis = '${data['jenis_perpanjangan'] ?? 'bulanan'}';
    _jumlah.text = '${data['jumlah_periode_perpanjangan'] ?? 1}';
    _hari.text = '${data['hari_sebelum_berakhir'] ?? 30}';
    final harga = data['harga_perpanjangan'];
    _harga.text = harga == null ? '' : '$harga';
    _aktif = '${data['status'] ?? 'aktif'}' == 'aktif';
    _editMode = false;
    setState(() {});
  }

  Future<void> _simpan() async {
    final id = _kontrakId;
    if (id == null) return;
    final jumlah = int.tryParse(_jumlah.text.trim());
    final hari = int.tryParse(_hari.text.trim());
    final hargaText = _harga.text.trim();
    final harga = hargaText.isEmpty ? null : int.tryParse(hargaText);

    if (jumlah == null || jumlah <= 0) {
      AppSnackbar.error(context, 'Jumlah periode tidak valid');
      return;
    }
    if (hari == null || hari < 0) {
      AppSnackbar.error(context, 'Hari sebelum berakhir tidak valid');
      return;
    }
    if (hargaText.isNotEmpty && (harga == null || harga <= 0)) {
      AppSnackbar.error(context, 'Harga perpanjangan tidak valid');
      return;
    }

    final provider = context.read<PengaturanOtomatisProvider>();
    final ok = await provider.simpanPerpanjangan(
      kontrakId: id,
      jenisPerpanjangan: _jenis,
      jumlahPeriodePerpanjangan: jumlah,
      hariSebelumBerakhir: hari,
      hargaPerpanjangan: harga,
      status: _aktif ? 'aktif' : 'nonaktif',
    );
    if (!mounted) return;
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal menyimpan pengaturan');
      return;
    }
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Pengaturan berhasil disimpan',
    );
    setState(() {
      _loadError = null;
      _editMode = false;
    });
  }

  Future<void> _toggle(bool value) async {
    final id = _kontrakId;
    if (id == null) return;
    final provider = context.read<PengaturanOtomatisProvider>();
    final ok = await provider.ubahStatusPerpanjangan(id, value);
    if (!mounted) return;
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal mengubah status');
      return;
    }
    setState(() {
      _loadError = null;
      _aktif = value;
    });
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Status pengaturan berubah',
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = _kontrakId;
    if (id == null) return const SizedBox.shrink();

    final provider = context.watch<PengaturanOtomatisProvider>();
    final data = provider.perpanjanganByKontrak[id];
    final loading = provider.loadingPerpanjangan[id] == true;
    final hasData = data != null;
    final showForm = !hasData || _editMode;

    return _Shell(
      icon: Icons.event_repeat_rounded,
      title: 'Kontrak otomatis',
      subtitle: hasData
          ? 'Perpanjangan disiapkan dari kontrak aktif ini.'
          : 'Buat aturan agar kontrak berikutnya dibuat oleh cron.',
      loading: loading,
      status: hasData ? '${data['status'] ?? 'aktif'}' : null,
      trailing: hasData
          ? Switch(value: _aktif, onChanged: loading ? null : _toggle)
          : null,
      errorText: _loadError,
      child: showForm
          ? _buildForm(loading, hasData)
          : _buildDetail(data, loading),
    );
  }

  Widget _buildDetail(Map<String, dynamic> data, bool loading) {
    return Column(
      children: [
        _CompactInfoList(
          children: [
            _CompactInfoItem(
              icon: Icons.loop_rounded,
              label: 'Jenis',
              value: _labelSiklus('${data['jenis_perpanjangan'] ?? ''}'),
            ),
            _CompactInfoItem(
              icon: Icons.repeat_rounded,
              label: 'Jumlah',
              value: '${data['jumlah_periode_perpanjangan'] ?? 1} periode',
            ),
            _CompactInfoItem(
              icon: Icons.schedule_outlined,
              label: 'Proses berikutnya',
              value: _tanggal(data['tanggal_proses_berikutnya']),
            ),
            _CompactInfoItem(
              icon: Icons.payments_outlined,
              label: 'Harga',
              value: data['harga_perpanjangan'] == null
                  ? 'Ikuti kontrak lama'
                  : AppDesign.formatRupiah(data['harga_perpanjangan']),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: loading ? null : () => setState(() => _editMode = true),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Ubah pengaturan'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool loading, bool hasData) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            initialValue: _jenis,
            decoration: _inputDecoration(
              context: context,
              label: 'Jenis perpanjangan',
              icon: Icons.loop_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'bulanan', child: Text('Bulanan')),
              DropdownMenuItem(value: 'mingguan', child: Text('Mingguan')),
              DropdownMenuItem(value: 'harian', child: Text('Harian')),
              DropdownMenuItem(value: 'tahunan', child: Text('Tahunan')),
            ],
            onChanged: loading
                ? null
                : (value) => setState(() => _jenis = value ?? 'bulanan'),
          ),
        ),
        CustomInput(
          controller: _jumlah,
          label: 'Jumlah periode',
          hint: '1',
          icon: Icons.repeat_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: angkaSajaFormatter(),
          required: true,
        ),
        CustomInput(
          controller: _hari,
          label: 'Hari sebelum kontrak berakhir',
          hint: '30',
          icon: Icons.schedule_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: angkaSajaFormatter(),
          required: true,
        ),
        CustomInput(
          controller: _harga,
          label: 'Harga perpanjangan',
          hint: 'Kosongkan untuk ikut harga lama',
          icon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: angkaSajaFormatter(),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _aktif,
          onChanged: loading ? null : (value) => setState(() => _aktif = value),
          title: const Text('Aktifkan otomatis'),
          subtitle: const Text('Cron hanya memproses pengaturan aktif.'),
        ),
        Row(
          children: [
            if (hasData) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: loading
                      ? null
                      : () => setState(() => _editMode = false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: loading ? null : _simpan,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(loading ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PengaturanTagihanOtomatisPanel extends StatefulWidget {
  final Map<String, dynamic>? kontrak;

  const PengaturanTagihanOtomatisPanel({super.key, required this.kontrak});

  @override
  State<PengaturanTagihanOtomatisPanel> createState() =>
      _PengaturanTagihanOtomatisPanelState();
}

class _PengaturanTagihanOtomatisPanelState
    extends State<PengaturanTagihanOtomatisPanel> {
  final _hariSebelum = TextEditingController(text: '0');
  final _jatuhTempo = TextEditingController(text: '3');
  bool _aktif = true;
  bool _editMode = false;
  String? _loadError;

  int? get _kontrakId => entityId(widget.kontrak?['id']);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _muat();
    });
  }

  @override
  void didUpdateWidget(PengaturanTagihanOtomatisPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (entityId(oldWidget.kontrak?['id']) != _kontrakId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _muat(force: true);
      });
    }
  }

  @override
  void dispose() {
    _hariSebelum.dispose();
    _jatuhTempo.dispose();
    super.dispose();
  }

  Future<void> _muat({bool force = false}) async {
    final id = _kontrakId;
    if (id == null) return;
    final provider = context.read<PengaturanOtomatisProvider>();
    await provider.ambilTagihan(id, force: force);
    if (!mounted) return;
    final err = provider.ambil_pesan_error();
    _loadError = err;
    _isiForm(provider.tagihanByKontrak[id]);
  }

  void _isiForm(Map<String, dynamic>? data) {
    if (data == null) {
      _hariSebelum.text = '0';
      _jatuhTempo.text = '3';
      _aktif = true;
      _editMode = false;
      setState(() {});
      return;
    }
    _hariSebelum.text = '${data['hari_sebelum_periode_mulai'] ?? 0}';
    _jatuhTempo.text = '${data['jatuh_tempo_setelah_periode_mulai_hari'] ?? 0}';
    _aktif = '${data['status'] ?? 'aktif'}' == 'aktif';
    _editMode = false;
    setState(() {});
  }

  Future<void> _simpan() async {
    final id = _kontrakId;
    if (id == null) return;
    final hari = int.tryParse(_hariSebelum.text.trim());
    final jatuhTempo = int.tryParse(_jatuhTempo.text.trim());

    if (hari == null || hari < 0) {
      AppSnackbar.error(context, 'Hari sebelum periode mulai tidak valid');
      return;
    }
    if (jatuhTempo == null || jatuhTempo < 0) {
      AppSnackbar.error(context, 'Jatuh tempo tidak valid');
      return;
    }

    final provider = context.read<PengaturanOtomatisProvider>();
    final ok = await provider.simpanTagihan(
      kontrakId: id,
      hariSebelumPeriodeMulai: hari,
      jatuhTempoSetelahPeriodeMulaiHari: jatuhTempo,
      status: _aktif ? 'aktif' : 'nonaktif',
    );
    if (!mounted) return;
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal menyimpan pengaturan');
      return;
    }
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Pengaturan berhasil disimpan',
    );
    setState(() {
      _loadError = null;
      _editMode = false;
    });
  }

  Future<void> _toggle(bool value) async {
    final id = _kontrakId;
    if (id == null) return;
    final provider = context.read<PengaturanOtomatisProvider>();
    final ok = await provider.ubahStatusTagihan(id, value);
    if (!mounted) return;
    final err = provider.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal mengubah status');
      return;
    }
    setState(() {
      _loadError = null;
      _aktif = value;
    });
    AppSnackbar.success(
      context,
      provider.ambil_pesan_sukses() ?? 'Status pengaturan berubah',
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = _kontrakId;
    if (id == null) {
      return _Shell(
        icon: Icons.receipt_long_outlined,
        title: 'Tagihan otomatis',
        subtitle:
            'Buat kontrak aktif terlebih dahulu sebelum mengatur tagihan.',
        child: Text(
          'Belum ada kontrak aktif.',
          style: AppDesign.bodyMuted(context),
        ),
      );
    }

    final provider = context.watch<PengaturanOtomatisProvider>();
    final data = provider.tagihanByKontrak[id];
    final loading = provider.loadingTagihan[id] == true;
    final hasData = data != null;
    final showForm = !hasData || _editMode;

    return _Shell(
      icon: Icons.receipt_long_rounded,
      title: 'Tagihan otomatis',
      subtitle: hasData
          ? 'Tagihan sewa dibuat otomatis mengikuti siklus kontrak.'
          : 'Buat aturan agar tagihan sewa digenerate otomatis.',
      loading: loading,
      status: hasData ? '${data['status'] ?? 'aktif'}' : null,
      trailing: hasData
          ? Switch(value: _aktif, onChanged: loading ? null : _toggle)
          : null,
      errorText: _loadError,
      child: showForm
          ? _buildForm(loading, hasData)
          : _buildDetail(data, loading),
    );
  }

  Widget _buildDetail(Map<String, dynamic> data, bool loading) {
    return Column(
      children: [
        _CompactInfoList(
          children: [
            _CompactInfoItem(
              icon: Icons.alarm_rounded,
              label: 'Generate',
              value: '${data['hari_sebelum_periode_mulai'] ?? 0} hari sebelum',
            ),
            _CompactInfoItem(
              icon: Icons.event_available_outlined,
              label: 'Jatuh tempo',
              value:
                  '${data['jatuh_tempo_setelah_periode_mulai_hari'] ?? 0} hari setelah mulai',
            ),
            _CompactInfoItem(
              icon: Icons.schedule_outlined,
              label: 'Proses berikutnya',
              value: _tanggal(data['tanggal_proses_berikutnya']),
            ),
            _CompactInfoItem(
              icon: Icons.history_rounded,
              label: 'Periode terakhir',
              value:
                  '${_tanggal(data['periode_awal_terakhir_dibuat'])} - ${_tanggal(data['periode_akhir_terakhir_dibuat'])}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: loading ? null : () => setState(() => _editMode = true),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Ubah pengaturan'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool loading, bool hasData) {
    return Column(
      children: [
        CustomInput(
          controller: _hariSebelum,
          label: 'Generate sebelum periode mulai',
          hint: '0',
          icon: Icons.alarm_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: angkaSajaFormatter(),
          helperText: '0 berarti dibuat tepat pada tanggal periode dimulai.',
          required: true,
        ),
        CustomInput(
          controller: _jatuhTempo,
          label: 'Jatuh tempo setelah periode mulai',
          hint: '3',
          icon: Icons.event_available_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: angkaSajaFormatter(),
          required: true,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _aktif,
          onChanged: loading ? null : (value) => setState(() => _aktif = value),
          title: const Text('Aktifkan otomatis'),
          subtitle: const Text('Cron hanya memproses pengaturan aktif.'),
        ),
        Row(
          children: [
            if (hasData) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: loading
                      ? null
                      : () => setState(() => _editMode = false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: loading ? null : _simpan,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(loading ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Shell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final String? status;
  final String? errorText;
  final Widget? trailing;
  final Widget child;

  const _Shell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.loading = false,
    this.status,
    this.errorText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final aktif = status == 'aktif';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppDesign.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppDesign.titleBold(
                              context,
                            ).copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (aktif
                                          ? AppDesign.success
                                          : AppDesign.textSecondary)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              aktif ? 'ON' : 'OFF',
                              style: TextStyle(
                                color: aktif
                                    ? AppDesign.success
                                    : AppDesign.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppDesign.bodyMuted(
                        context,
                      ).copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (trailing != null)
                trailing!,
            ],
          ),
          if (errorText != null && errorText!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppDesign.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppDesign.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: AppDesign.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CompactInfoList extends StatelessWidget {
  final List<_CompactInfoItem> children;

  const _CompactInfoList({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1)
            const Divider(height: 18, color: AppDesign.border),
        ],
      ],
    );
  }
}

class _CompactInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppDesign.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration({
  required BuildContext context,
  required String label,
  required IconData icon,
}) {
  return AppFieldDecoration.input(context, labelText: label, prefixIcon: icon);
}

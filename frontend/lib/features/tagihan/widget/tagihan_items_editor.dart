import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_form_dialog.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';

/// Form daftar item tagihan (tambah / edit).
class TagihanItemsEditor extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final bool requireItemIds;
  final bool allowAddItem;
  final int? hargaKamar;
  final int? hargaKontrak;

  const TagihanItemsEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.requireItemIds = false,
    this.allowAddItem = true,
    this.hargaKamar,
    this.hargaKontrak,
  });

  @override
  State<TagihanItemsEditor> createState() => TagihanItemsEditorState();
}

class TagihanItemsEditorState extends State<TagihanItemsEditor> {
  late List<Map<String, dynamic>> _items;
  final _controllers = <int, Map<String, TextEditingController>>{};

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((e) => Map<String, dynamic>.from(e)).toList();
    if (_items.isEmpty) {
      _items.add(TagihanItemUtils.itemBaru());
    }
    _syncControllers();
  }

  void _syncControllers() {
    for (var i = 0; i < _items.length; i++) {
      _controllers[i] ??= {};
      _controllers[i]!['nama'] ??= TextEditingController(
        text: '${_items[i]['nama_item'] ?? ''}',
      );
      _controllers[i]!['deskripsi'] ??= TextEditingController(
        text: '${_items[i]['deskripsi'] ?? ''}',
      );
      _controllers[i]!['nominal'] ??= TextEditingController(
        text: '${_items[i]['nominal'] ?? 0}',
      );
      for (final c in _controllers[i]!.values) {
        c.removeListener(_onFieldChanged);
        c.addListener(_onFieldChanged);
      }
    }
  }

  void _onFieldChanged() {
    for (var i = 0; i < _items.length; i++) {
      _readFromControllers(i);
    }
    widget.onChanged(_items.map((e) => Map<String, dynamic>.from(e)).toList());
    if (mounted) setState(() {});
  }

  void _disposeControllers() {
    for (final m in _controllers.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(_items.map((e) => Map<String, dynamic>.from(e)).toList());
    setState(() {});
  }

  void _readFromControllers(int index) {
    final c = _controllers[index];
    if (c == null) return;
    _items[index]['nama_item'] = c['nama']!.text.trim();
    _items[index]['deskripsi'] = c['deskripsi']!.text.trim();
    _items[index]['nominal'] =
        int.tryParse(c['nominal']!.text.replaceAll('.', '')) ?? 0;
  }

  void _tambahItem() {
    _readAll();
    setState(() {
      _items.add(TagihanItemUtils.itemBaru());
      final i = _items.length - 1;
      _controllers[i] = {
        'nama': TextEditingController(),
        'deskripsi': TextEditingController(),
        'nominal': TextEditingController(text: '0'),
      };
    });
    _notify();
  }

  void _readAll() {
    for (var i = 0; i < _items.length; i++) {
      _readFromControllers(i);
    }
  }

  /// Ambil item terbaru dari form (panggil sebelum simpan).
  List<Map<String, dynamic>> exportItems() {
    _readAll();
    return _items.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _applyHarga(int index, int harga) {
    final c = _controllers[index];
    if (c == null) return;
    c['nominal']!.text = '$harga';
    _items[index]['nominal'] = harga;
    _notify();
  }

  void _hapusItem(int index) {
    if (_items.length <= 1) return;
    _readAll();
    _controllers[index]?.values.forEach((c) => c.dispose());
    _controllers.remove(index);
    final newControllers = <int, Map<String, TextEditingController>>{};
    var j = 0;
    for (var i = 0; i < _items.length; i++) {
      if (i == index) continue;
      newControllers[j] = _controllers[i]!;
      j++;
    }
    _controllers
      ..clear()
      ..addAll(newControllers);
    setState(() {
      _items.removeAt(index);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    _readAll();
    final total = TagihanItemUtils.hitungTotal(_items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Rincian item',
                style: AppDesign.titleBold(context).copyWith(fontSize: 15),
              ),
            ),
            if (widget.allowAddItem)
              TextButton.icon(
                onPressed: _tambahItem,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah item'),
              ),
          ],
        ),
        Text(
          'Tipe: sewa, insiden, denda (+), diskon (−). Total dihitung otomatis.',
          style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _items.length,
          (index) => _buildItemCard(context, index),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppDesign.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total tagihan', style: AppDesign.titleBold(context)),
              Text(
                AppDesign.formatRupiah(total),
                style: AppDesign.titleBold(
                  context,
                ).copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _hargaKamarValid =>
      widget.hargaKamar != null && widget.hargaKamar! > 0;

  bool get _hargaKontrakValid =>
      widget.hargaKontrak != null && widget.hargaKontrak! > 0;

  bool get _adaPresetHarga => _hargaKamarValid || _hargaKontrakValid;

  Widget _buildItemCard(BuildContext context, int index) {
    final item = _items[index];
    final c = _controllers[index]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue:
                      TagihanItemUtils.tipeOptions.any(
                        (o) => o.$1 == item['tipe'],
                      )
                      ? '${item['tipe']}'
                      : 'sewa',
                  decoration: InputDecoration(
                    labelText: 'Tipe *',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: TagihanItemUtils.tipeOptions
                      .map(
                        (o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _items[index]['tipe'] = v ?? 'sewa';
                    });
                    _notify();
                  },
                ),
              ),
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppDesign.danger,
                  ),
                  onPressed: () => _hapusItem(index),
                ),
            ],
          ),
          if (widget.requireItemIds && item['id'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'ID item: ${item['id']}',
                style: AppDesign.bodyMuted(context).copyWith(fontSize: 11),
              ),
            ),
          CustomInput(
            controller: c['nama']!,
            label: 'Nama item',
            hint: 'Sewa bulan Mei',
            icon: Icons.label_outline,
            required: true,
          ),
          CustomInput(
            controller: c['deskripsi']!,
            label: 'Deskripsi',
            hint: 'Opsional',
            icon: Icons.notes_outlined,
            required: false,
          ),
          if (_adaPresetHarga) ...[
            Text(
              'Isi cepat nominal',
              style: AppDesign.bodyMuted(context).copyWith(fontSize: 11.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_hargaKamarValid)
                  ActionChip(
                    avatar: const Icon(Icons.meeting_room_outlined, size: 16),
                    label: Text(
                      'Harga kamar ${AppDesign.formatRupiah(widget.hargaKamar)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _applyHarga(index, widget.hargaKamar!),
                  ),
                if (_hargaKontrakValid)
                  ActionChip(
                    avatar: const Icon(Icons.description_outlined, size: 16),
                    label: Text(
                      'Harga kontrak ${AppDesign.formatRupiah(widget.hargaKontrak)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _applyHarga(index, widget.hargaKontrak!),
                  ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          CustomInput(
            controller: c['nominal']!,
            label: 'Nominal (Rp)',
            hint: '1500000',
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: angkaSajaFormatter(),
            helperText: AppFormHints.rupiah,
            required: true,
          ),
        ],
      ),
    );
  }
}

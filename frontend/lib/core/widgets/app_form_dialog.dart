import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/theme/app_design.dart';

/// Petunjuk format umum untuk form di dialog.
class AppFormHints {
  static const tanggal = 'Format: 2026-05-01 (tahun-bulan-hari)';
  static const rupiah = 'Angka saja, tanpa titik atau Rp. Contoh: 1500000';
  static const telepon = 'Angka saja. Contoh: 081234567890';
  static const email = 'Contoh: nama@email.com';
  static const kapasitas = 'Jumlah orang maksimal di kamar. Contoh: 2';
  static const nomorKamar = 'Kode atau nomor kamar. Contoh: A-01 atau 12';
}

Future<T?> showAppFormDialog<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<Widget> fields,
  required Future<bool> Function() onSave,
  String saveLabel = 'Simpan',
  String cancelLabel = 'Batal',
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFormDialogHeader(title: title, subtitle: subtitle),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                ...fields,
                const SizedBox(height: 28),
                AppFormDialogActions(
                  cancelLabel: cancelLabel,
                  saveLabel: saveLabel,
                  onCancel: () => Navigator.pop(ctx),
                  onSave: () async {
                    final ok = await onSave();
                    if (ok && ctx.mounted) Navigator.pop(ctx, true as T);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class AppFormDialogHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppFormDialogHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.35),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.grey),
        ),
      ],
    );
  }
}

class AppFormDialogActions extends StatelessWidget {
  final String cancelLabel;
  final String saveLabel;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  const AppFormDialogActions({
    super.key,
    this.cancelLabel = 'Batal',
    this.saveLabel = 'Simpan',
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.icon_hapus,
              side: BorderSide(color: AppColors.icon_hapus.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () async => onSave(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(saveLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class AppFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helper;
  final IconData icon;
  final bool required;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const AppFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.helper,
    required this.icon,
    this.required = true,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    const fill = Color(0xFFF8F9FA);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(text: ' *', style: TextStyle(color: AppDesign.danger)),
              ],
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(helper!, style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3)),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: accent, size: 20),
              filled: true,
              fillColor: fill,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class AppFormSectionLabel extends StatelessWidget {
  final String text;

  const AppFormSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppDesign.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Hanya angka (untuk harga, telepon, kapasitas).
List<TextInputFormatter> angkaSajaFormatter() => [FilteringTextInputFormatter.digitsOnly];

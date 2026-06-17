import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

/// Ikon ⓘ — ketuk untuk menampilkan keterangan.
class FormInfoTip extends StatelessWidget {
  final String message;
  final String? dialogTitle;

  const FormInfoTip({
    super.key,
    required this.message,
    this.dialogTitle,
  });

  static void show(BuildContext context, String message, {String? title}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.info_outline_rounded,
          size: 36,
          color: Theme.of(ctx).colorScheme.primary,
        ),
        title: Text(title ?? 'Keterangan'),
        content: Text(
          message,
          style: AppDesign.bodyMuted(ctx).copyWith(
            fontSize: 14,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => show(context, message, title: dialogTitle),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Baris label form + ikon info opsional.
class FormLabelRow extends StatelessWidget {
  final String label;
  final bool required;
  final String? infoText;

  const FormLabelRow({
    super.key,
    required this.label,
    this.required = false,
    this.infoText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1A1C1E),
              ),
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        if (infoText != null && infoText!.isNotEmpty)
          FormInfoTip(message: infoText!, dialogTitle: label),
      ],
    );
  }
}

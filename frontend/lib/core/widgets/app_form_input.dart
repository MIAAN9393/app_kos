import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_field_decoration.dart';
import 'package:kos_management/core/widgets/form_info_tip.dart';

class CustomInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  /// Teks bantuan di bawah label (selalu tampil).
  final String? helperText;

  /// Ketuk ikon info di samping label untuk membaca keterangan.
  final String? infoText;
  final bool required;
  final List<TextInputFormatter>? inputFormatters;

  const CustomInput({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.helperText,
    this.infoText,
    this.required = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infoText != null && infoText!.isNotEmpty
              ? FormLabelRow(
                  label: label,
                  required: required,
                  infoText: infoText,
                )
              : RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: AppDesign.textPrimary,
                    ),
                    children: [
                      TextSpan(text: label),
                      if (required)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppDesign.danger),
                        ),
                    ],
                  ),
                ),
          if (helperText != null && infoText == null) ...[
            const SizedBox(height: 3),
            Text(
              helperText!,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppDesign.textSecondary,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            style: const TextStyle(fontSize: 14),
            decoration: AppFieldDecoration.input(
              context,
              hintText: hint,
              prefixIcon: icon,
            ),
          ),
        ],
      ),
    );
  }
}

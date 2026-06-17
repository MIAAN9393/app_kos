import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_field_decoration.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? helperText;
  final bool required;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.helperText,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
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
          if (helperText != null) ...[
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
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            maxLines: maxLines,
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

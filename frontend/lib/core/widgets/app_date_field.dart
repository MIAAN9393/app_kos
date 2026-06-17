import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_field_decoration.dart';

/// Input tanggal read-only — ketuk untuk buka kalender.
class AppDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final IconData icon;
  final String? helperText;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.calendar_today_outlined,
    this.helperText,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  static String formatDisplay(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) return;
    final today = _dateOnly(DateTime.now());
    final minDate = _dateOnly(firstDate ?? DateTime(2000));
    final maxDate = _dateOnly(lastDate ?? DateTime(2100));
    var initialDate = _dateOnly(value ?? today);

    if (initialDate.isBefore(minDate)) {
      initialDate = minDate;
    }
    if (initialDate.isAfter(maxDate)) {
      initialDate = maxDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'Pilih tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      onChanged(_dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = value == null ? '' : formatDisplay(value!);

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
          InkWell(
            onTap: enabled ? () => _pickDate(context) : null,
            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            child: InputDecorator(
              decoration: AppFieldDecoration.input(
                context,
                hintText: 'Ketuk untuk pilih tanggal',
                prefixIcon: icon,
                suffixIcon: const Icon(Icons.event_outlined, size: 20),
                enabled: enabled,
              ),
              child: Text(
                display,
                style: TextStyle(
                  fontSize: 14,
                  color: display.isEmpty
                      ? AppDesign.textTertiary
                      : AppDesign.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

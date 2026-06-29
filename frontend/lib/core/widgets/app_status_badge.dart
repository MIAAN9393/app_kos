import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

class AppStatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const AppStatusBadge({super.key, required this.status, this.label});

  Color _color() {
    switch (status) {
      case 'penuh':
      case 'telat':
      case 'refund':
        return AppDesign.danger;
      case 'sebagian':
        return AppDesign.warning;
      case 'kosong':
      case 'aktif':
      case 'lunas':
      case 'valid':
        return AppDesign.success;
      case 'pending':
        return AppDesign.info;
      case 'selesai':
        return AppDesign.textSecondary;
      case 'dibatalkan':
      case 'cancelled':
        return AppDesign.danger;
      default:
        return AppDesign.textSecondary;
    }
  }

  String _label() {
    if (label != null) return label!;
    switch (status) {
      case 'penuh':
        return 'Penuh';
      case 'sebagian':
        return 'Sebagian';
      case 'kosong':
        return 'Kosong';
      case 'aktif':
        return 'Aktif';
      case 'pending':
        return 'Pending';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
      case 'cancelled':
        return 'Dibatalkan';
      case 'nonaktif':
        return 'Nonaktif';
      case 'lunas':
        return 'Lunas';
      case 'belum_bayar':
        return 'Belum bayar';
      case 'telat':
        return 'Telat';
      case 'valid':
        return 'Valid';
      case 'refund':
        return 'Refund';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

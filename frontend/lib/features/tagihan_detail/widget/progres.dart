import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgresTagihan extends StatelessWidget {
  final int total_tagihan;
  final int total_dibayar;
  final NumberFormat formatCurrency;
  final double progressBayar;
  const ProgresTagihan({
    super.key,
    required this.total_dibayar,
    required this.total_tagihan,
    required this.formatCurrency,
    required this.progressBayar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress Pembayaran",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                "${(progressBayar * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressBayar,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue.shade700,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                "Total Tagihan",
                formatCurrency.format(total_tagihan),
                Icons.receipt,
              ),
              _buildInfoChip(
                "Total Dibayar",
                formatCurrency.format(total_dibayar),
                Icons.payment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildInfoChip(String label, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    ),
  );
}

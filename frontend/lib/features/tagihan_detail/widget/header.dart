import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';

class HeaderTagihan extends StatelessWidget {
  final String kode_tagihan;
  final String status;
  final DateTime periode_awal;
  final DateTime periode_akhir;
  final DateTime jatuh_tempo;

  const HeaderTagihan({
    super.key,
    required this.periode_awal,
    required this.periode_akhir,
    required this.jatuh_tempo,
    required this.status,
    required this.kode_tagihan,
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
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KODE TAGIHAN",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kode_tagihan,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDateChip(
                  Icons.calendar_today,
                  "Periode",
                  "${DateFormat('dd MMM').format(periode_awal)} - ${DateFormat('dd MMM').format(periode_akhir)}",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateChip(
                  Icons.access_time,
                  "Jatuh Tempo",
                  DateFormat('dd MMM yyyy').format(jatuh_tempo),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        actionButton(
                          Icons.edit,
                          AppColors.icon_edit,
                          AppColors.icon_edit,
                          () {},
                        ),
                        SizedBox(width: 10),
                        actionButton(
                          Icons.delete,
                          AppColors.icon_hapus,
                          AppColors.icon_hapus,
                          () {},
                        ),
                      ],
                    ),
                    actionButton(Icons.share, Colors.grey, Colors.black, () {}),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildDateChip(IconData icon, String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget actionButton(
  IconData icon,
  Color colorBackground,
  Color colorIcon,
  VoidCallback onTap,
) {
  //KOMPONEN BEBAS
  return Material(
    color: colorBackground.withValues(alpha: 0.123),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 18, color: colorIcon),
      ),
    ),
  );
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'lunas':
      return Colors.green;
    case 'sebagian':
      return Colors.orange;
    case 'telat':
      return Colors.red;
    case 'belum_bayar':
      return Colors.blue;
    case 'batal':
      return Colors.grey;
    default:
      return Colors.black;
  }
}

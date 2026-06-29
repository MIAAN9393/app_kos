import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';

/// Tampilan read-only rincian item tagihan.
class TagihanItemsList extends StatelessWidget {
  final List<dynamic> items;

  const TagihanItemsList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final parsed = TagihanItemUtils.parseItems(items);
    if (parsed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Belum ada rincian item',
          style: AppDesign.bodyMuted(context),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parsed.map((item) {
        final tipe = '${item['tipe']}';
        final isDiskon = tipe == 'diskon';
        final nominal = int.tryParse('${item['nominal']}') ?? 0;
        final deskripsi = '${item['deskripsi'] ?? ''}'.trim();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppDesign.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['nama_item']}',
                      style: AppDesign.titleBold(
                        context,
                      ).copyWith(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TagihanItemUtils.labelTipe(tipe),
                      style: AppDesign.bodyMuted(
                        context,
                      ).copyWith(fontSize: 12),
                    ),
                    if (deskripsi.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(deskripsi, style: AppDesign.bodyMuted(context)),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  '${isDiskon ? '-' : '+'} ${AppDesign.formatRupiah(nominal)}',
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDiskon ? AppDesign.danger : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

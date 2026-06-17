// import 'package:flutter/material.dart';
// import 'package:kos_management/core/navigation/app_navigation.dart';
// import 'package:kos_management/core/theme/app_design.dart';
// import 'package:kos_management/core/widgets/app_page_scaffold.dart';

// class TransaksiPage extends StatelessWidget {
//   const TransaksiPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AppPageScaffold(
//       title: 'Transaksi',
//       subtitle: 'Riwayat pembayaran per tagihan',
//       showBack: true,
//       body: Padding(
//         padding: const EdgeInsets.all(AppDesign.spaceLg),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Icon(
//               Icons.receipt_long_outlined,
//               size: 56,
//               color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
//             ),
//             const SizedBox(height: AppDesign.spaceMd),
//             Text(
//               'Buka lewat detail tagihan',
//               style: AppDesign.sectionTitle(context),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: AppDesign.spaceSm),
//             Text(
//               'Property → Kos → Kamar → Penyewa → pilih tagihan → riwayat pembayaran & refund.',
//               style: AppDesign.bodyMuted(context),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: AppDesign.spaceLg),
//             FilledButton.icon(
//               onPressed: () => AppNavigation.toPropertyTab(context),
//               icon: const Icon(Icons.home_work_outlined),
//               label: const Text('Ke Property'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

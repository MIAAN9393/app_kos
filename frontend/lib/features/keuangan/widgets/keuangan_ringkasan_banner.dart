import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

/// Banner ringkasan utama laporan keuangan (gradient + chip ringkas).
class KeuanganRingkasanBanner extends StatelessWidget {
  final String uangMasuk;
  final String sisaTagihan;
  final int jumlahPembayaranValid;
  final int jumlahTagihan;
  final String? bayaranBulanDepan;

  const KeuanganRingkasanBanner({
    super.key,
    required this.uangMasuk,
    required this.sisaTagihan,
    required this.jumlahPembayaranValid,
    required this.jumlahTagihan,
    this.bayaranBulanDepan,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uang masuk periode',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            uangMasuk,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppDesign.spaceMd),
          Row(
            children: [
              _chip(
                context,
                icon: Icons.payments_outlined,
                label: '$jumlahPembayaranValid pembayaran',
              ),
              const SizedBox(width: AppDesign.spaceSm),
              _chip(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Sisa $sisaTagihan',
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spaceSm),
          _chip(
            context,
            icon: Icons.receipt_long_outlined,
            label: '$jumlahTagihan tagihan jatuh tempo',
            fullWidth: true,
          ),
          if (bayaranBulanDepan != null) ...[
            const SizedBox(height: AppDesign.spaceSm),
            _chip(
              context,
              icon: Icons.fast_forward_outlined,
              label: 'Bayar di muka (bulan depan) $bayaranBulanDepan',
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool fullWidth = false,
  }) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (fullWidth) return child;
    return Expanded(child: child);
  }
}

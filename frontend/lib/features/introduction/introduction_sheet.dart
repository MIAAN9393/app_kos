import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/introduction/introduction_store.dart';

class IntroductionSheet extends StatefulWidget {
  const IntroductionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppDesign.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radiusLg),
        ),
      ),
      builder: (_) => const IntroductionSheet(),
    );
  }

  @override
  State<IntroductionSheet> createState() => _IntroductionSheetState();
}

class _IntroductionSheetState extends State<IntroductionSheet> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_IntroItem> _items = [
    _IntroItem(
      icon: Icons.dashboard_rounded,
      color: AppDesign.info,
      title: 'Pantau dari Dashboard',
      body:
          'Lihat pendapatan, okupansi kamar, status tagihan, dan aktivitas terbaru dalam satu layar.',
    ),
    _IntroItem(
      icon: Icons.home_work_rounded,
      color: AppDesign.success,
      title: 'Mulai dari Property',
      body:
          'Tambahkan kos, isi kamar, lalu kelola penyewa dari alur Kos, Kamar, dan Penyewa.',
    ),
    _IntroItem(
      icon: Icons.person_add_alt_1_rounded,
      color: Color(0xFF7C3AED),
      title: 'Check In Penyewa',
      body:
          'Gunakan Check In Cepat untuk memilih kamar, membuat penyewa, dan langsung membuat kontrak.',
    ),
    _IntroItem(
      icon: Icons.receipt_long_rounded,
      color: AppDesign.warning,
      title: 'Tagihan dan Pembayaran',
      body:
          'Buat tagihan, catat pembayaran, proses refund, lalu bagikan invoice PDF atau WhatsApp.',
    ),
    _IntroItem(
      icon: Icons.schedule_send_rounded,
      color: AppDesign.danger,
      title: 'Aktifkan Otomatisasi',
      body:
          'Atur tagihan otomatis, perpanjangan kontrak, notifikasi, dan pengiriman WhatsApp.',
    ),
  ];

  bool get _isLast => _index == _items.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selesai() async {
    await IntroductionStore.tandaiSudahDilihat();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _lanjut() {
    if (_isLast) {
      _selesai();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: height * 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDesign.spaceMd,
            AppDesign.spaceSm,
            AppDesign.spaceMd,
            AppDesign.spaceMd,
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppDesign.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppDesign.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Panduan Singkat',
                      style: AppDesign.sectionTitle(context),
                    ),
                  ),
                  TextButton(onPressed: _selesai, child: const Text('Lewati')),
                ],
              ),
              const SizedBox(height: AppDesign.spaceSm),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    return _IntroPage(item: _items[index]);
                  },
                ),
              ),
              const SizedBox(height: AppDesign.spaceMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _index
                            ? Theme.of(context).colorScheme.primary
                            : AppDesign.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDesign.spaceMd),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _lanjut,
                  icon: Icon(
                    _isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  ),
                  label: Text(_isLast ? 'Mulai Kelola' : 'Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final _IntroItem item;

  const _IntroPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 380;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 88 : 112,
                  height: compact ? 88 : 112,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: compact ? 42 : 54,
                    color: item.color,
                  ),
                ),
                SizedBox(
                  height: compact ? AppDesign.spaceMd : AppDesign.spaceLg,
                ),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppDesign.sectionTitle(context),
                ),
                const SizedBox(height: AppDesign.spaceSm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    item.body,
                    textAlign: TextAlign.center,
                    style: AppDesign.bodyMuted(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IntroItem {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _IntroItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

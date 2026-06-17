import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/controll/widget/controll_kamar_tab.dart';
import 'package:kos_management/features/controll/widget/controll_kontrak_tab.dart';
import 'package:kos_management/features/controll/widget/controll_kos_tab.dart';
import 'package:kos_management/features/controll/widget/controll_pembayaran_tab.dart';
import 'package:kos_management/features/controll/widget/controll_penyewa_tab.dart';
import 'package:kos_management/features/controll/widget/controll_tagihan_tab.dart';

class ControllPage extends StatefulWidget {
  const ControllPage({super.key});

  @override
  State<ControllPage> createState() => _ControllPageState();
}

class _ControllPageState extends State<ControllPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _menuAksi(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppDesign.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Operasional', style: AppDesign.titleBold(ctx)),
              const SizedBox(height: AppDesign.spaceSm),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_rounded),
                title: const Text('Tambah Penyewa + Kontrak'),
                onTap: () {
                  Navigator.pop(ctx);
                  AppNavigation.toTambahPenyewaKontrak(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_work_outlined),
                title: const Text('Buka Property'),
                onTap: () {
                  Navigator.pop(ctx);
                  AppNavigation.toPropertyTab(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'Operasional',
                    onPressed: () => _menuAksi(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kelola', style: AppDesign.titleBold(context)),
                        Text(
                          'Kelola data lintas properti',
                          style: AppDesign.bodyMuted(
                            context,
                          ).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: AppDesign.card,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: AppDesign.textSecondary,
              indicatorColor: Theme.of(context).colorScheme.primary,
              dividerColor: AppDesign.border,
              tabs: const [
                Tab(text: 'Kos'),
                Tab(text: 'Kamar'),
                Tab(text: 'Penyewa'),
                Tab(text: 'Kontrak'),
                Tab(text: 'Tagihan'),
                Tab(text: 'Pembayaran'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                ControllKosTab(),
                ControllKamarTab(),
                ControllPenyewaTab(),
                ControllKontrakTab(),
                ControllTagihanTab(),
                ControllPembayaranTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

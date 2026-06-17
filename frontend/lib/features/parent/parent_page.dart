import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_shell.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/controll/controll_page.dart';
import 'package:kos_management/features/kos/kos_page.dart';
import 'package:kos_management/features/dashboard/dashboard_page.dart';
import 'package:kos_management/features/introduction/introduction_sheet.dart';
import 'package:kos_management/features/introduction/introduction_store.dart';
import 'package:kos_management/features/keuangan/keuangan_page.dart';
import 'package:kos_management/providers/laporan_keuangan_provider.dart';
import 'package:provider/provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int currentIndex = AppShellTabs.dashboard;

  final List<Widget> pages = const [
    DashboardPage(),
    KosPage(),
    ControllPage(),
    KeuanganPage(),
  ];

  void pindahTab(int index) {
    if (index < 0 || index >= AppShellTabs.length) return;
    setState(() => currentIndex = index);
    if (index == AppShellTabs.keuangan) {
      context.read<LaporanKeuanganProvider>().tandai_perlu_muat_ulang();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tampilkanIntroductionJikaPerlu();
    });
  }

  Future<void> _tampilkanIntroductionJikaPerlu() async {
    final sudahDilihat = await IntroductionStore.sudahDilihat();
    if (!mounted || sudahDilihat) return;
    await IntroductionSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      pindahTab: pindahTab,
      child: Scaffold(
        backgroundColor: AppDesign.surface,
        body: IndexedStack(index: currentIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: pindahTab,
          elevation: 0,
          backgroundColor: AppDesign.card,
          indicatorColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_work_outlined),
              selectedIcon: Icon(Icons.home_work_rounded),
              label: 'Property',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Kelola',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Keuangan',
            ),
          ],
        ),
      ),
    );
  }
}

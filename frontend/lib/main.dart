import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kos_management/core/navigation/app_router.dart';
import 'package:kos_management/core/navigation/app_routes.dart';
import 'package:kos_management/core/theme/app_theme.dart';
import 'package:kos_management/firebase_options.dart';
import 'package:kos_management/providers/dashboard_provider.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/laporan_keuangan_provider.dart';
import 'package:kos_management/providers/laporan_kos_provider.dart';
import 'package:kos_management/providers/pembayaran_provider.dart';
import 'package:kos_management/providers/pengaturan_otomatis_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/providers/profile_provider.dart';
import 'package:kos_management/providers/subscription_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/route_observer.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/fcm_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

  final hasSession = await _hasValidSession();
  if (hasSession) {
    await FcmNotificationService(ApiService()).registerDeviceToken();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KosProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => LaporanKosProvider()),
        ChangeNotifierProvider(create: (_) => LaporanKeuanganProvider()),
        ChangeNotifierProvider(create: (_) => KamarProvider()),
        ChangeNotifierProvider(create: (_) => PenyewaProvider()),
        ChangeNotifierProvider(create: (_) => KontrakProvider()),
        ChangeNotifierProvider(create: (_) => TagihanProvider()),
        ChangeNotifierProvider(create: (_) => PengaturanOtomatisProvider()),
        ChangeNotifierProvider(create: (_) => PembayaranProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MyApp(hasSession: hasSession),
    ),
  );
}

Future<bool> _hasValidSession() async {
  final api = ApiService();
  final token = await api.getToken('access_token');

  if (token == null || token.isEmpty) {
    return false;
  }

  try {
    await api.get('profile');
    return true;
  } catch (_) {
    await api.clearToken('access_token');
    await api.clearToken('refresh_token');
    return false;
  }
}

class MyApp extends StatelessWidget {
  final bool hasSession;

  const MyApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kos Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      navigatorObservers: [routeObserver],
      initialRoute: hasSession ? AppRoutes.home : AppRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Halaman tidak ditemukan')),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_add_fab.dart';
import 'package:kos_management/core/widgets/app_icon_button.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/kamar/widget/kamar_list_section.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:provider/provider.dart';

class KamarPage extends StatefulWidget {
  final int id_kos;
  const KamarPage({super.key, required this.id_kos});

  @override
  State<KamarPage> createState() => _KamarPageState();
}

class _KamarPageState extends State<KamarPage> {
  late KamarProvider _read;

  @override
  void initState() {
    super.initState();
    _read = context.read<KamarProvider>();
    _read.addListener(_listener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KosProvider>().ambil_data_kos_provider();
      context.read<KamarProvider>().ambil_data_kamar_provider(widget.id_kos);
    });
  }

  void _listener() {
    final err = _read.ambil_pesan_error();
    final ok = _read.ambil_pesan_sukses();
    if (err != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackbar.error(context, err);
      });
    }
    if (ok != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackbar.success(context, ok);
      });
    }
  }

  @override
  void dispose() {
    _read.removeListener(_listener);
    super.dispose();
  }

  void _tambahKamar() {
    AppNavigation.toTambahKamar(context, idKos: widget.id_kos);
  }

  @override
  Widget build(BuildContext context) {
    final kos = context.watch<KosProvider>().ambil_datasiap_kos_by_id(
      widget.id_kos,
    );

    return Scaffold(
      backgroundColor: AppDesign.surface,
      floatingActionButton: AppAddFab(
        tooltip: 'Tambah Kamar',
        onPressed: _tambahKamar,
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back_rounded,
                    filled: false,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: KamarListSection(
              idKos: widget.id_kos,
              namaKos: kos?['nama_kos']?.toString(),
              showHeader: true,
              embedded: true,
            ),
          ),
        ],
      ),
    );
  }
}

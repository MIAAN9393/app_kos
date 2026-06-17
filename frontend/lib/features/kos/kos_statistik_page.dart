import 'package:flutter/material.dart';
import 'package:kos_management/core/widgets/app_section_header.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/providers/laporan_kos_provider.dart';
import 'package:provider/provider.dart';

class KosStatistikPage extends StatefulWidget {
  final int idKos;

  const KosStatistikPage({super.key, required this.idKos});

  @override
  State<KosStatistikPage> createState() => _KosStatistikPageState();
}

class _KosStatistikPageState extends State<KosStatistikPage> {
  late LaporanKosProvider _read;

  @override
  void initState() {
    super.initState();
    _read = context.read<LaporanKosProvider>();
    _read.addListener(_listener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LaporanKosProvider>().ambil_or_fecth(widget.idKos);
    });
  }

  void _listener() {
    _read.muat_ulang_jika_perlu(widget.idKos);
    final err = _read.ambil_pesan_error();
    if (err != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackbar.error(context, err);
      });
    }
  }

  @override
  void dispose() {
    _read.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LaporanKosProvider>();
    final data = provider.data_laporan_kos[widget.idKos] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik Kos')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const AppSectionHeader(
                  title: 'Statistik Kos',
                  subtitle: 'Data dari backend laporan kos',
                ),
                if (data.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada data statistik.'),
                  )
                else
                  ...data.map(
                    (item) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text('${item['label'] ?? item['nama'] ?? 'Item'}'),
                        subtitle: Text('${item['value'] ?? item['jumlah'] ?? item}'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

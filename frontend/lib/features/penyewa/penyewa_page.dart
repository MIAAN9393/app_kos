import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_add_fab.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/whatsapp/whatsapp_deep_link_service.dart';
import 'package:kos_management/features/penyewa/widget/appbar_costum.dart';
import 'package:kos_management/features/penyewa/widget/custom_card_penyewa.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:provider/provider.dart';

class PenyewaPage extends StatefulWidget {
  final int id_kamar;
  final int id_kos;
  const PenyewaPage({super.key, required this.id_kamar, required this.id_kos});

  @override
  State<PenyewaPage> createState() => _PenyewaPageState();
}

class _PenyewaPageState extends State<PenyewaPage> {
  late PenyewaProvider _providerRead;
  late TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _providerRead = context.read<PenyewaProvider>();
    _search = TextEditingController()..addListener(() => setState(() {}));
    _providerRead.addListener(_listener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenyewaProvider>().ambil_data_penyewa_provider(
        widget.id_kamar,
      );
    });
  }

  void _listener() {
    if (!mounted) return;
    final pesanError = _providerRead.ambil_pesan_error();
    final pesanSukses = _providerRead.ambil_pesan_sukses();
    if (pesanError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSnackbar.error(context, pesanError);
      });
    }
    if (pesanSukses != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSnackbar.success(context, pesanSukses);
      });
    }
  }

  @override
  void dispose() {
    _providerRead.removeListener(_listener);
    _search.dispose();
    super.dispose();
  }

  Future<void> _chatWhatsApp(String? noTelpon, String? nama) async {
    final opened = await WhatsAppDeepLinkService.openChat(
      phoneNumber: noTelpon,
      message:
          '${WhatsAppDeepLinkService.tenantGreeting(nama)}, saya menghubungi dari aplikasi Manajemen Kos.',
    );
    if (!mounted) return;
    if (!opened) {
      AppSnackbar.error(
        context,
        'Nomor WhatsApp belum valid atau WhatsApp tidak bisa dibuka.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PenyewaProvider>();
    final dataPenyewa = provider.tampilkan_data(_search.text, widget.id_kamar);
    final byId = provider.penyewa_by_id;

    return Scaffold(
      appBar: AppBarHelper.appbar_costum(
        context: context,
        controller: _search,
        ftombol_cari: (_) {},
        showFilter: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: provider.loading
            ? Center(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )
            : dataPenyewa.isEmpty
            ? Center(
                child: Text(
                  'Belum ada penyewa di kamar ini',
                  style: AppDesign.bodyMuted(context),
                ),
              )
            : ListView.builder(
                itemCount: dataPenyewa.length,
                itemBuilder: (context, index) {
                  final item = dataPenyewa[index];
                  final id = intFromJson(item['id']);
                  if (id == null) return const SizedBox.shrink();
                  final row = byId[id] ?? item;
                  return CardPenyewa.fromData(
                    item: row,
                    klik_card: (penyewaId) {
                      AppNavigation.toPenyewaDetail(
                        context,
                        idPenyewa: penyewaId,
                        idKamar: widget.id_kamar,
                        idKos: widget.id_kos,
                      );
                    },
                    klik_edit: (penyewaId) {
                      final data = byId[penyewaId];
                      if (data == null) return;
                      AppNavigation.toEditPenyewa(
                        context,
                        idPenyewa: penyewaId,
                        nama: '${data['nama']}',
                        noTelpon: '${data['no_telpon']}',
                        email: '${data['email'] ?? ''}',
                        tanggalLahir: data['tanggal_lahir']?.toString(),
                        jenisKelamin: data['jenis_kelamin']?.toString(),
                        statusHubungan: data['status_hubungan']?.toString(),
                      );
                    },
                    klik_hapus: (penyewaId) {
                      final data = byId[penyewaId];
                      if (data == null) return;
                      showConfirmDeleteDialog(
                        context: context,
                        nama: '${data['nama']}',
                        entityLabel: 'penyewa',
                        onConfirm: () => context
                            .read<PenyewaProvider>()
                            .hapus_penyewa_provider(penyewaId),
                      );
                    },
                    klik_wa: (no) => _chatWhatsApp(no, row['nama']?.toString()),
                  );
                },
              ),
      ),
      floatingActionButton: AppAddFab(
        tooltip: 'Tambah Penyewa',
        onPressed: () {
          AppNavigation.toTambahPenyewaKontrak(
            context,
            idKamar: widget.id_kamar,
            idKos: widget.id_kos,
          );
        },
      ),
    );
  }
}

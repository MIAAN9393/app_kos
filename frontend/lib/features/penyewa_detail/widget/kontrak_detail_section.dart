import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_add_fab.dart';
import 'package:kos_management/core/widgets/app_date_field.dart';
import 'package:kos_management/core/widgets/app_document_action_button.dart';
import 'package:kos_management/core/widgets/app_field_decoration.dart';
import 'package:kos_management/core/widgets/app_form_dialog.dart';
import 'package:kos_management/core/widgets/app_info_row.dart';
import 'package:kos_management/core/widgets/app_kontrak_list_card.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/auth/widget/custom_input.dart';
import 'package:kos_management/features/export_pdf/kontrak_pdf.dart';
import 'package:kos_management/features/export_pdf/pdf_export_service.dart';
import 'package:kos_management/features/export_pdf/pdf_helpers.dart';
import 'package:kos_management/features/penyewa_detail/widget/pengaturan_otomatis_panel.dart';
import 'package:kos_management/features/whatsapp/whatsapp_deep_link_service.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/kontrak_aksi_rules.dart';
import 'package:kos_management/utils/kontrak_status.dart';
import 'package:kos_management/utils/sisa_hari.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';
import 'package:provider/provider.dart';

/// Tab kontrak untuk satu penyewa.
class KontrakDetailSection extends StatefulWidget {
  final int idPenyewa;
  final int idKamar;
  final int idKos;
  final bool embedded;

  const KontrakDetailSection({
    super.key,
    required this.idPenyewa,
    required this.idKamar,
    required this.idKos,
    this.embedded = false,
  });

  @override
  State<KontrakDetailSection> createState() => _KontrakDetailSectionState();
}

class _KontrakDetailSectionState extends State<KontrakDetailSection> {
  bool _sendingKontrakWhatsApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat(force: true));
  }

  Future<void> _muat({bool force = false}) async {
    final provider = context.read<KontrakProvider>();
    await provider.ambil_list_kontrak_penyewa(widget.idPenyewa, force: force);
    await provider.ambil_kontrak_provider(widget.idPenyewa, force: force);
  }

  Future<void> _refreshKamar({int? kosId, int? kamarId}) async {
    final idKos = kosId ?? widget.idKos;
    final idKamar = kamarId ?? widget.idKamar;
    if (idKos <= 0) return;

    final kamar = context.read<KamarProvider>();
    kamar.perubahan_data[idKos] = true;
    await kamar.ambil_data_kamar_provider(idKos);
    if (!mounted) return;

    final penyewa = context.read<PenyewaProvider>();
    if (idKamar > 0) {
      await penyewa.refreshKamar(idKamar, kos_id: idKos);
    }
    await penyewa.ambil_semua_penyewa(force: true);
    if (mounted) {
      await context.read<KosProvider>().ambil_data_kos_provider();
    }
  }

  static String _tanggal(dynamic v) {
    if (v == null) return '-';
    return v.toString().split('T').first;
  }

  static String _labelSiklus(String raw) {
    switch (raw.toLowerCase()) {
      case 'bulanan':
        return 'Bulanan';
      case 'mingguan':
        return 'Mingguan';
      case 'harian':
        return 'Harian';
      default:
        return raw.isEmpty ? '-' : raw;
    }
  }

  static Map<String, dynamic>? _kontrakAktifDariList(
    List<Map<String, dynamic>> list,
  ) {
    for (final kontrak in list) {
      if (KontrakStatus.isAktif(kontrak)) return kontrak;
    }
    return null;
  }

  int? _kosIdForKontrak(Map<String, dynamic> kontrak) {
    final kamar = kontrak['kamar'];
    final kamarId =
        entityId(kontrak['kamar_id']) ??
        (kamar is Map ? entityId(kamar['id']) : null);
    final kosId = kamar is Map ? entityId(kamar['kos_id']) : null;
    return kosId ??
        (kamarId == null
            ? null
            : context.read<KamarProvider>().cari_kos_id(kamarId));
  }

  Future<void> _tambahKontrak() async {
    final dibuat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _TambahKontrakPenyewaPage(
          idPenyewa: widget.idPenyewa,
          idKosAwal: widget.idKos > 0 ? widget.idKos : null,
        ),
      ),
    );

    if (dibuat == true && mounted) {
      await _muat(force: true);
      await _refreshKamar();
    }
  }

  Future<void> _konfirmasiSelesaikan(Map<String, dynamic> kontrak) async {
    final id = entityId(kontrak['id']);
    if (id == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan kontrak?'),
        content: const Text(
          'Kontrak akan diakhiri hari ini dan status menjadi selesai. '
          'Status kamar akan disesuaikan otomatis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppDesign.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<KontrakProvider>();
              final ok = await provider.selesaikan_kontrak_provider(
                kontrakId: id,
                penyewaId: widget.idPenyewa,
              );
              if (!mounted) return;
              final err = provider.ambil_pesan_error();
              if (!ok || err != null) {
                AppSnackbar.error(
                  context,
                  err ?? 'Gagal menyelesaikan kontrak',
                );
                return;
              }
              AppSnackbar.success(
                context,
                provider.ambil_pesan_sukses() ?? 'Kontrak diselesaikan',
              );
              await _muat(force: true);
              await _refreshKamar(kamarId: entityId(kontrak['kamar_id']));
            },
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareKontrakPdf(Map<String, dynamic> kontrak) async {
    final penyewa =
        context.read<PenyewaProvider>().penyewa_by_id[widget.idPenyewa] ??
        context.read<PenyewaProvider>().semua_data_penyewa[widget.idPenyewa];
    final kamarId = entityId(kontrak['kamar_id']) ?? widget.idKamar;
    final kosId = _kosIdForKontrak(kontrak) ?? widget.idKos;
    final kamar = context.read<KamarProvider>().ambil_datasiap_kamar_by_id(
      kamarId,
    );
    final kos = context.read<KosProvider>().ambil_datasiap_kos_by_id(kosId);

    await PdfExportService.sharePdf(
      fileName: PdfHelpers.fileName(
        'detail_kontrak',
        code: '${kontrak['kode_kontrak'] ?? kontrak['id'] ?? widget.idPenyewa}',
      ),
      build: () => KontrakPdf.build(
        kontrak: kontrak,
        penyewa: penyewa,
        namaKos: '${kos?['nama_kos'] ?? ''}',
        nomorKamar:
            '${kamar?['nomor'] ?? kamar?['nama_kamar'] ?? kontrak['kamar_id'] ?? ''}',
      ),
    );
  }

  Future<void> _exportKontrak(Map<String, dynamic> kontrak) async {
    try {
      await _shareKontrakPdf(kontrak);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal export PDF: $e');
    }
  }

  Future<void> _sendKontrakWhatsApp(Map<String, dynamic> kontrak) async {
    if (_sendingKontrakWhatsApp) return;
    setState(() => _sendingKontrakWhatsApp = true);
    try {
      final penyewa =
          context.read<PenyewaProvider>().penyewa_by_id[widget.idPenyewa] ??
          context.read<PenyewaProvider>().semua_data_penyewa[widget.idPenyewa];
      final kode = '${kontrak['kode_kontrak'] ?? kontrak['id'] ?? ''}'.trim();
      final token = '${kontrak['public_token'] ?? ''}'.trim();
      if (kode.isEmpty || token.isEmpty) {
        AppSnackbar.error(
          context,
          'Link PDF publik belum tersedia. Muat ulang kontrak.',
        );
        return;
      }

      final kamarId = entityId(kontrak['kamar_id']) ?? widget.idKamar;
      final kamar = context.read<KamarProvider>().ambil_datasiap_kamar_by_id(
        kamarId,
      );
      final nomorKamar =
          '${kamar?['nomor'] ?? kamar?['nama_kamar'] ?? kontrak['kamar_id'] ?? '-'}';
      final pdfUrl =
          '${ApiService().publicBaseUrl}/public/kontrak/${Uri.encodeComponent(kode)}/pdf?token=${Uri.encodeQueryComponent(token)}';
      final opened = await WhatsAppDeepLinkService.openChat(
        phoneNumber: penyewa?['no_telpon']?.toString(),
        message: [
          '${WhatsAppDeepLinkService.tenantGreeting(penyewa?['nama']?.toString())}, berikut detail kontrak sewa.',
          '',
          'Nama: ${penyewa?['nama'] ?? '-'}',
          'Kode kontrak: $kode',
          'Kamar: $nomorKamar',
          'Tanggal mulai: ${_tanggal(kontrak['tanggal_mulai'])}',
          'Tanggal selesai: ${_tanggal(kontrak['tanggal_selesai'])}',
          'Harga sewa: ${AppDesign.formatRupiah(kontrak['harga_sewa'])}',
          'Siklus: ${_labelSiklus('${kontrak['siklus'] ?? ''}')}',
          '',
          'PDF kontrak: $pdfUrl',
        ].join('\n'),
      );
      if (!mounted) return;
      if (opened) {
        AppSnackbar.success(
          context,
          'Chat WhatsApp dibuka dengan link PDF kontrak.',
        );
      } else {
        AppSnackbar.error(
          context,
          'Nomor WhatsApp belum valid atau WhatsApp tidak bisa dibuka.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal menyiapkan kontrak WhatsApp: $e');
    } finally {
      if (mounted) setState(() => _sendingKontrakWhatsApp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KontrakProvider>();
    final penyewaProvider = context.watch<PenyewaProvider>();
    final penyewa =
        penyewaProvider.penyewa_by_id[widget.idPenyewa] ??
        penyewaProvider.semua_data_penyewa[widget.idPenyewa];
    final penyewaAktif = '${penyewa?['status'] ?? ''}'.toLowerCase() == 'aktif';
    final list = provider.kontrakListByPenyewa[widget.idPenyewa] ?? const [];
    final kontrakAktif = _kontrakAktifDariList(list);
    final lainnya = list
        .where((kontrak) => !KontrakStatus.isAktif(kontrak))
        .toList();
    final loading = provider.loading && list.isEmpty;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await _muat(force: true);
            await _refreshKamar();
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              widget.embedded ? 12 : 16,
              24,
              widget.embedded ? 104 : 112,
            ),
            children: [
              _headerAksi(kontrakAktif),
              const SizedBox(height: 12),
              if (penyewaAktif && kontrakAktif != null)
                _buildKontrakAktifCard(kontrakAktif)
              else
                _buildKontrakAktifKosong(penyewaAktif),
              const SizedBox(height: 16),
              _buildListKontrakLainnya(lainnya),
            ],
          ),
        ),
        Positioned(
          right: 18,
          bottom: 18,
          child: AppAddFab(
            heroTag: 'fab_tambah_kontrak_${widget.idPenyewa}',
            tooltip: 'Tambah Kontrak',
            onPressed: _tambahKontrak,
          ),
        ),
      ],
    );
  }

  Widget _headerAksi(Map<String, dynamic>? kontrakAktif) {
    return Row(
      children: [
        Expanded(
          child: Text('Kontrak', style: AppDesign.sectionTitle(context)),
        ),
        PengaturanOtomatisButton(
          icon: Icons.event_repeat_rounded,
          label: 'Otomatisasi',
          onPressed: kontrakAktif == null
              ? null
              : () => showPengaturanPerpanjanganOtomatisSheet(
                  context,
                  kontrakAktif,
                ),
        ),
      ],
    );
  }

  Widget _buildKontrakAktifKosong(bool penyewaAktif) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kontrak Aktif',
                  style: AppDesign.sectionTitle(context),
                ),
              ),
              const AppStatusBadge(status: 'kosong'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            penyewaAktif
                ? 'Belum ada kontrak aktif yang terbaca untuk penyewa ini.'
                : 'Penyewa sedang tidak aktif, jadi tidak ada kontrak aktif.',
            style: AppDesign.bodyMuted(context),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _muat(force: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Muat ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildListKontrakLainnya(List<Map<String, dynamic>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kontrak Lainnya', style: AppDesign.sectionTitle(context)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppDesign.cardDecoration(),
            child: Text(
              'Belum ada kontrak pending, selesai, atau dibatalkan.',
              style: AppDesign.bodyMuted(context),
            ),
          )
        else
          ...list.map(
            (kontrak) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppKontrakListCard(
                kontrak: kontrak,
                onTap: () {
                  final id = entityId(kontrak['id']);
                  if (id == null) return;
                  AppNavigation.toKontrakDetail(
                    context,
                    kontrakId: id,
                    idPenyewa: widget.idPenyewa,
                    idKamar: entityId(kontrak['kamar_id']),
                    idKos:
                        _kosIdForKontrak(kontrak) ??
                        (widget.idKos > 0 ? widget.idKos : null),
                    kontrak: kontrak,
                  );
                },
                onEdit: () async {
                  final id = entityId(kontrak['id']);
                  final kamarId = entityId(kontrak['kamar_id']);
                  if (id == null || kamarId == null) return;
                  final ok = await AppNavigation.toEditKontrak(
                    context,
                    kontrakId: id,
                    idPenyewa: widget.idPenyewa,
                    idKamar: kamarId,
                    harga: '${kontrak['harga_sewa']}',
                    mulai: _tanggal(kontrak['tanggal_mulai']),
                    selesai: _tanggal(kontrak['tanggal_selesai']),
                    siklus: '${kontrak['siklus'] ?? 'bulanan'}',
                  );
                  if (ok == true && mounted) {
                    await _muat(force: true);
                    await _refreshKamar(kamarId: kamarId);
                  }
                },
                onDelete: () {
                  final id = entityId(kontrak['id']);
                  if (id == null) return;
                  showConfirmDeleteDialog(
                    context: context,
                    nama: '${kontrak['kode_kontrak'] ?? '#$id'}',
                    entityLabel: 'kontrak',
                    onConfirm: () async {
                      final provider = context.read<KontrakProvider>();
                      await provider.batalkan_kontrak_provider(
                        kontrakId: id,
                        penyewaId: widget.idPenyewa,
                      );
                      if (!mounted) return;
                      final kamarId = entityId(kontrak['kamar_id']);
                      await _muat(force: true);
                      await _refreshKamar(kamarId: kamarId);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKontrakAktifCard(Map<String, dynamic> kontrak) {
    final kontrakId = entityId(kontrak['id']);
    final kodeKontrak = '${kontrak['kode_kontrak'] ?? ''}'.trim();
    final kamarId = entityId(kontrak['kamar_id']) ?? widget.idKamar;
    final nomorKamar = KontrakAksiRules.labelNomorKamar(kontrak);
    final bolehEdit = KontrakAksiRules.bolehEdit(kontrak);
    final bolehHapus = KontrakAksiRules.bolehHapus(kontrak);
    final bolehSelesai = KontrakAksiRules.bolehSelesaikan(kontrak);
    final sisaKontrak = SisaHari.labelKontrak(
      kontrak['tanggal_mulai'],
      kontrak['tanggal_selesai'],
      status: kontrak['status'],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kontrak Aktif',
                  style: AppDesign.sectionTitle(context),
                ),
              ),
              AppStatusBadge(
                status: KontrakStatus.normalize(kontrak['status']),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            kodeKontrak.isNotEmpty
                ? 'Kode : $kodeKontrak'
                : (kontrakId != null ? 'Kode : #$kontrakId' : 'Kode : -'),
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 20),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
            ),
            children: [
              AppInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Mulai',
                value: _tanggal(kontrak['tanggal_mulai']),
              ),
              AppInfoRow(
                icon: Icons.event_outlined,
                label: 'Selesai',
                value: _tanggal(kontrak['tanggal_selesai']),
              ),
              AppInfoRow(
                icon: Icons.payments_outlined,
                label: 'Harga sewa',
                value: AppDesign.formatRupiah(kontrak['harga_sewa']),
              ),
              AppInfoRow(
                icon: Icons.loop_rounded,
                label: 'Siklus',
                value: _labelSiklus('${kontrak['siklus'] ?? ''}'),
              ),
              AppInfoRow(
                icon: Icons.meeting_room_outlined,
                label: 'Kamar',
                value: nomorKamar,
              ),
              AppInfoRow(
                icon: Icons.info_outline,
                label: 'Status',
                value: KontrakStatus.label(kontrak['status']),
              ),
              AppInfoRow(
                icon: Icons.timer_outlined,
                label: 'Durasi',
                value: sisaKontrak ?? '-',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),
          AppInfoRow(
            icon: Icons.schedule_outlined,
            label: 'Dibuat',
            value: _tanggal(kontrak['dibuat_pada']),
          ),
          if (kontrak['diperbarui_pada'] != null) ...[
            const SizedBox(height: 12),
            AppInfoRow(
              icon: Icons.update_outlined,
              label: 'Diperbarui',
              value: _tanggal(kontrak['diperbarui_pada']),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _tombolAksi(
                label: 'Edit',
                icon: Icons.edit_rounded,
                warnaAktif: AppColors.icon_edit,
                enabled: bolehEdit,
                onPressed: bolehEdit && kontrakId != null
                    ? () async {
                        final ok = await AppNavigation.toEditKontrak(
                          context,
                          kontrakId: kontrakId,
                          idPenyewa: widget.idPenyewa,
                          idKamar: kamarId,
                          harga: '${kontrak['harga_sewa']}',
                          mulai: _tanggal(kontrak['tanggal_mulai']),
                          selesai: _tanggal(kontrak['tanggal_selesai']),
                          siklus: '${kontrak['siklus'] ?? 'bulanan'}',
                        );
                        if (ok == true && mounted) {
                          await _muat(force: true);
                          await _refreshKamar(kamarId: kamarId);
                        }
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              _tombolAksi(
                label: 'Batalkan',
                icon: Icons.cancel_outlined,
                warnaAktif: AppColors.icon_hapus,
                enabled: bolehHapus,
                onPressed: bolehHapus && kontrakId != null
                    ? () => showConfirmDeleteDialog(
                        context: context,
                        nama: 'kontrak #$kontrakId',
                        entityLabel: 'kontrak',
                        onConfirm: () async {
                          final p = context.read<KontrakProvider>();
                          await p.batalkan_kontrak_provider(
                            kontrakId: kontrakId,
                            penyewaId: widget.idPenyewa,
                          );
                          if (!mounted) return;
                          final err = p.ambil_pesan_error();
                          if (err != null) {
                            AppSnackbar.error(context, err);
                            return;
                          }
                          AppSnackbar.success(
                            context,
                            p.ambil_pesan_sukses() ?? 'Kontrak dibatalkan',
                          );
                          await _muat(force: true);
                          await _refreshKamar(kamarId: kamarId);
                        },
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppDocumentActionButton(
            label: 'Bagikan Kontrak PDF',
            icon: Icons.picture_as_pdf_outlined,
            filled: true,
            onPressed: () => _exportKontrak(kontrak),
          ),
          const SizedBox(height: 8),
          AppDocumentActionButton(
            label: _sendingKontrakWhatsApp
                ? 'Menyiapkan Kontrak...'
                : 'Kirim Kontrak ke WhatsApp',
            icon: _sendingKontrakWhatsApp
                ? Icons.hourglass_top_rounded
                : Icons.send_outlined,
            onPressed: _sendingKontrakWhatsApp
                ? null
                : () => _sendKontrakWhatsApp(kontrak),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _tombolAksi(
              label: 'Selesaikan',
              icon: Icons.task_alt_rounded,
              warnaAktif: AppDesign.success,
              enabled: bolehSelesai,
              fullWidth: true,
              onPressed: bolehSelesai
                  ? () => _konfirmasiSelesaikan(kontrak)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _keteranganAksi(
              bolehEdit: bolehEdit,
              bolehHapus: bolehHapus,
              bolehSelesai: bolehSelesai,
              kontrak: kontrak,
            ),
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  static String _keteranganAksi({
    required bool bolehEdit,
    required bool bolehHapus,
    required bool bolehSelesai,
    required Map<String, dynamic> kontrak,
  }) {
    final parts = <String>[];
    if (!bolehEdit) {
      parts.add('Edit: ${KontrakAksiRules.alasanEdit(kontrak)}');
    }
    if (!bolehHapus) {
      parts.add('Batalkan: ${KontrakAksiRules.alasanHapus(kontrak)}');
    }
    if (!bolehSelesai) {
      parts.add('Selesaikan: ${KontrakAksiRules.alasanSelesaikan(kontrak)}');
    }
    if (parts.isEmpty) {
      return 'Semua aksi tersedia sesuai status dan periode kontrak.';
    }
    return parts.join(' · ');
  }

  Widget _tombolAksi({
    required String label,
    required IconData icon,
    required Color warnaAktif,
    required bool enabled,
    required VoidCallback? onPressed,
    bool fullWidth = false,
  }) {
    final disabledBg = Colors.grey.shade300;
    final disabledFg = Colors.grey.shade600;

    final btn = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: enabled ? warnaAktif : disabledBg,
        foregroundColor: enabled ? Colors.white : disabledFg,
        disabledBackgroundColor: disabledBg,
        disabledForegroundColor: disabledFg,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );

    if (fullWidth) return btn;
    return Expanded(child: btn);
  }
}

class _TambahKontrakPenyewaPage extends StatefulWidget {
  final int idPenyewa;
  final int? idKosAwal;

  const _TambahKontrakPenyewaPage({
    required this.idPenyewa,
    required this.idKosAwal,
  });

  @override
  State<_TambahKontrakPenyewaPage> createState() =>
      _TambahKontrakPenyewaPageState();
}

class _TambahKontrakPenyewaPageState extends State<_TambahKontrakPenyewaPage> {
  final _harga = TextEditingController();
  DateTime? _mulai;
  DateTime? _selesai;
  String _siklus = 'bulanan';
  int? _idKosDipilih;
  int? _idKamarDipilih;
  bool _loading = false;
  bool _loadingKamar = false;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _idKosDipilih = widget.idKosAwal;
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatAwal());
  }

  Future<void> _muatAwal() async {
    final kos = context.read<KosProvider>();
    final kamar = context.read<KamarProvider>();
    final kontrak = context.read<KontrakProvider>();
    await kos.ambil_or_update_data();
    await kontrak.ambil_semua_kontrak(force: true);
    if (!mounted) return;
    final kosId = _idKosDipilih;
    if (kosId != null) {
      await kamar.ambil_data_kamar_provider(kosId);
    }
  }

  @override
  void dispose() {
    _harga.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _kamarTersedia(KamarProvider provider) {
    final kosId = _idKosDipilih;
    if (kosId == null) return const [];
    final list = provider.data_kamar[kosId] ?? const [];
    final kontrakProvider = context.read<KontrakProvider>();
    return list.where((kamar) {
      final status = '${kamar['status'] ?? 'aktif'}'.toLowerCase();
      if (status != 'aktif') return false;

      final kapasitas = int.tryParse('${kamar['kapasitas']}') ?? 0;
      final kamarId = entityId(kamar['id']);
      if (kamarId == null || kapasitas <= 0) return false;

      if (_mulai == null || _selesai == null) {
        final statusKondisi = '${kamar['status_kondisi'] ?? ''}'.toLowerCase();
        return statusKondisi != 'penuh';
      }

      final jumlahTerbooking = kontrakProvider.semua_data_kontrak.values
          .where((kontrak) => _kontrakMengisiKamarPadaPeriode(kontrak, kamarId))
          .length;

      return jumlahTerbooking < kapasitas;
    }).toList();
  }

  DateTime? _parseTanggal(dynamic raw) {
    final text = '${raw ?? ''}'.split('T').first.trim();
    if (text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }

  bool _periodeOverlap({
    required DateTime awalA,
    required DateTime akhirA,
    required DateTime awalB,
    required DateTime akhirB,
  }) {
    return !awalA.isAfter(akhirB) && !awalB.isAfter(akhirA);
  }

  bool _kontrakMengisiKamarPadaPeriode(
    Map<String, dynamic> kontrak,
    int kamarId,
  ) {
    final status = '${kontrak['status'] ?? ''}'.toLowerCase();
    if (status != 'aktif' && status != 'pending') return false;

    final kontrakKamarId = entityId(kontrak['kamar_id']);
    if (kontrakKamarId != kamarId) return false;

    final mulai = _parseTanggal(kontrak['tanggal_mulai']);
    final selesai = _parseTanggal(kontrak['tanggal_selesai']);
    if (mulai == null ||
        selesai == null ||
        _mulai == null ||
        _selesai == null) {
      return false;
    }

    return _periodeOverlap(
      awalA: _mulai!,
      akhirA: _selesai!,
      awalB: mulai,
      akhirB: selesai,
    );
  }

  Future<void> _pilihKos(int? kosId) async {
    setState(() {
      _idKosDipilih = kosId;
      _idKamarDipilih = null;
      _loadingKamar = kosId != null;
    });

    if (kosId != null) {
      final kamar = context.read<KamarProvider>();
      final kontrak = context.read<KontrakProvider>();
      await kamar.ambil_data_kamar_provider(kosId);
      await kontrak.ambil_semua_kontrak(force: true);
    }
    if (mounted) setState(() => _loadingKamar = false);
  }

  Future<void> _simpan() async {
    final idKos = _idKosDipilih;
    final idKamar = _idKamarDipilih;
    if (idKos == null || idKamar == null) {
      AppSnackbar.error(context, 'Pilih kos dan kamar terlebih dahulu');
      return;
    }
    if (_harga.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Harga sewa wajib diisi');
      return;
    }
    if (_mulai == null || _selesai == null) {
      AppSnackbar.error(context, 'Pilih tanggal mulai dan selesai');
      return;
    }
    if (!_selesai!.isAfter(_mulai!)) {
      AppSnackbar.error(context, 'Tanggal selesai harus setelah tanggal mulai');
      return;
    }
    if (!_selesai!.isAfter(_today)) {
      AppSnackbar.error(context, 'Tanggal selesai harus setelah hari ini');
      return;
    }

    final harga = int.tryParse(_harga.text.trim().replaceAll('.', ''));
    if (harga == null || harga <= 0) {
      AppSnackbar.error(context, 'Harga sewa tidak valid');
      return;
    }

    setState(() => _loading = true);
    final kontrak = context.read<KontrakProvider>();
    final ok = await kontrak.buat_kontrak_provider(
      penyewaId: widget.idPenyewa,
      kamarId: idKamar,
      tanggalMulai: TagihanItemUtils.formatTanggalApi(_mulai!),
      tanggalSelesai: TagihanItemUtils.formatTanggalApi(_selesai!),
      hargaSewa: harga,
      siklus: _siklus,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    final err = kontrak.ambil_pesan_error();
    if (!ok || err != null) {
      AppSnackbar.error(context, err ?? 'Gagal membuat kontrak');
      return;
    }

    final penyewa = context.read<PenyewaProvider>();
    await penyewa.refreshKamar(idKamar, kos_id: idKos);
    await penyewa.ambil_semua_penyewa(force: true);
    if (!mounted) return;
    final kamar = context.read<KamarProvider>();
    kamar.perubahan_data[idKos] = true;
    await kamar.ambil_data_kamar_provider(idKos);
    if (!mounted) return;
    await context.read<KosProvider>().ambil_data_kos_provider();
    if (!mounted) return;

    AppSnackbar.success(
      context,
      kontrak.ambil_pesan_sukses() ?? 'Kontrak berhasil dibuat',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final kosProvider = context.watch<KosProvider>();
    final kamarProvider = context.watch<KamarProvider>();
    final kosList = kosProvider.data_kos;
    final selectedKos =
        kosList.any((kos) => entityId(kos['id']) == _idKosDipilih)
        ? _idKosDipilih
        : null;
    final kamarList = _kamarTersedia(kamarProvider);
    final selectedKamar =
        kamarList.any((kamar) => entityId(kamar['id']) == _idKamarDipilih)
        ? _idKamarDipilih
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Kontrak')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [
            const AppFormSectionLabel('PILIH KAMAR'),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: DropdownButtonFormField<int>(
                initialValue: selectedKos,
                isExpanded: true,
                decoration: AppFieldDecoration.input(
                  context,
                  labelText: 'Kos *',
                  helperText: kosProvider.loading
                      ? 'Memuat daftar kos...'
                      : 'Pilih kos untuk melihat kamar tersedia.',
                  prefixIcon: Icons.home_work_outlined,
                  fillColor: Colors.grey[50],
                ),
                items: [
                  for (final kos in kosList)
                    if (entityId(kos['id']) != null)
                      DropdownMenuItem<int>(
                        value: entityId(kos['id'])!,
                        child: Text(
                          '${kos['nama_kos'] ?? 'Kos tanpa nama'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
                onChanged: _loading ? null : _pilihKos,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: DropdownButtonFormField<int>(
                initialValue: selectedKamar,
                isExpanded: true,
                decoration: AppFieldDecoration.input(
                  context,
                  labelText: 'Kamar aktif belum penuh *',
                  helperText: _loadingKamar || kamarProvider.loading
                      ? 'Memuat daftar kamar...'
                      : selectedKos == null
                      ? 'Pilih kos terlebih dahulu.'
                      : _mulai == null || _selesai == null
                      ? 'Hanya kamar aktif dengan status kosong/sebagian.'
                      : 'Hanya kamar aktif yang tersedia pada periode ini.',
                  prefixIcon: Icons.meeting_room_outlined,
                  fillColor: Colors.grey[50],
                ),
                items: [
                  for (final kamar in kamarList)
                    if (entityId(kamar['id']) != null)
                      DropdownMenuItem<int>(
                        value: entityId(kamar['id'])!,
                        child: Text(
                          'Kamar ${kamar['nomor'] ?? '-'}'
                          ' · ${kamar['status_kondisi'] ?? '-'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
                onChanged: _loading || kamarList.isEmpty
                    ? null
                    : (v) => setState(() => _idKamarDipilih = v),
              ),
            ),
            const AppFormSectionLabel('DATA KONTRAK'),
            CustomInput(
              controller: _harga,
              label: 'Harga sewa per siklus (Rp)',
              hint: '1500000',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: angkaSajaFormatter(),
              helperText: AppFormHints.rupiah,
              required: true,
            ),
            AppDateField(
              label: 'Tanggal mulai sewa',
              value: _mulai,
              icon: Icons.calendar_today_outlined,
              helperText:
                  'Mulai hari ini membuat kontrak aktif, masa depan pending.',
              required: true,
              firstDate: DateTime(_today.year - 1),
              lastDate: _selesai ?? DateTime(_today.year + 5),
              onChanged: (d) => setState(() {
                _mulai = d;
                _idKamarDipilih = null;
                if (_selesai != null && !_selesai!.isAfter(d)) {
                  _selesai = null;
                }
              }),
            ),
            AppDateField(
              label: 'Tanggal selesai sewa',
              value: _selesai,
              icon: Icons.event_outlined,
              helperText: 'Harus setelah tanggal mulai dan setelah hari ini.',
              required: true,
              firstDate:
                  _mulai?.add(const Duration(days: 1)) ??
                  _today.add(const Duration(days: 1)),
              lastDate: DateTime(_today.year + 5),
              onChanged: (d) => setState(() {
                _selesai = d;
                _idKamarDipilih = null;
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _siklus,
                decoration: AppFieldDecoration.input(
                  context,
                  labelText: 'Siklus pembayaran *',
                  prefixIcon: Icons.loop_rounded,
                  fillColor: Colors.grey[50],
                ),
                items: const [
                  DropdownMenuItem(value: 'bulanan', child: Text('Bulanan')),
                  DropdownMenuItem(value: 'mingguan', child: Text('Mingguan')),
                  DropdownMenuItem(value: 'harian', child: Text('Harian')),
                  DropdownMenuItem(value: 'tahunan', child: Text('Tahunan')),
                ],
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _siklus = v ?? 'bulanan'),
              ),
            ),
            SizedBox(
              height: 50,
              child: AppPrimaryButton(
                label: 'Buat kontrak',
                icon: Icons.add_rounded,
                loading: _loading,
                onPressed: _loading ? null : _simpan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

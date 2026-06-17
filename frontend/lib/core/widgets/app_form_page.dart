import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_loading_overlay.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';

/// Layout standar halaman form (tambah/edit) — selaras dengan [TambahPenyewaKontrak].
class AppFormPage extends StatelessWidget {
  final String title;
  final String? introText;
  final List<Widget> children;
  final String saveLabel;
  final bool isLoading;
  final Future<void> Function()? onSave;

  const AppFormPage({
    super.key,
    required this.title,
    this.introText,
    required this.children,
    this.saveLabel = 'Simpan',
    this.isLoading = false,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: Scaffold(
        backgroundColor: AppDesign.surface,
        appBar: AppBar(title: Text(title)),
        body: AppLoadingOverlay(
          loading: isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (introText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                      border: Border.all(color: AppDesign.border),
                    ),
                    child: Text(
                      introText!,
                      style: AppDesign.bodyMuted(
                        context,
                      ).copyWith(fontSize: 12.5, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...children,
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: AppPrimaryButton(
                    label: saveLabel,
                    loading: isLoading,
                    onPressed: isLoading || onSave == null
                        ? null
                        : () {
                            onSave!();
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

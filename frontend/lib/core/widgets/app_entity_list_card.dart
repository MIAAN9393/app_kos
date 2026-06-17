import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';

/// Ukuran kartu list standar (kos, kamar, penyewa, tagihan).
abstract class AppEntityListCardMetrics {
  static const double height = 118;
  static const double accentWidth = 72;
  static const int maxMetaLines = 2;
}

/// Baris info di kartu list entitas.
class AppEntityListLine {
  final IconData? icon;
  final String text;

  const AppEntityListLine({this.icon, required this.text});
}

/// Kartu list seragam untuk kos, kamar, penyewa, tagihan.
class AppEntityListCard extends StatelessWidget {
  final String entityLabel;
  final String title;
  final Color accentColor;
  final IconData placeholderIcon;
  final String status;
  final List<AppEntityListLine> lines;
  final String? highlightText;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMessage;
  final IconData messageIcon;
  final bool canEdit;
  final bool canDelete;
  final String? editBlockedMessage;
  final String? deleteBlockedMessage;
  final int titleMaxLines;

  const AppEntityListCard({
    super.key,
    required this.entityLabel,
    required this.title,
    required this.accentColor,
    required this.placeholderIcon,
    required this.status,
    required this.lines,
    this.highlightText,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMessage,
    this.messageIcon = Icons.chat_rounded,
    this.canEdit = true,
    this.canDelete = true,
    this.editBlockedMessage,
    this.deleteBlockedMessage,
    this.titleMaxLines = 2,
  });

  bool get _hasActions =>
      onEdit != null || onDelete != null || onMessage != null;

  List<AppEntityListLine> get _visibleLines =>
      lines.take(AppEntityListCardMetrics.maxMetaLines).toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppDesign.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          side: const BorderSide(color: AppDesign.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: AppEntityListCardMetrics.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: AppEntityListCardMetrics.accentWidth,
                  child: _AccentPanel(
                    accentColor: accentColor,
                    icon: placeholderIcon,
                    entityLabel: entityLabel,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: AppDesign.titleBold(
                                  context,
                                ).copyWith(fontSize: 13.5, height: 1.2),
                                maxLines: titleMaxLines,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            AppStatusBadge(status: status),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (highlightText != null)
                                Text(
                                  highlightText!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                    height: 1.05,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (highlightText != null &&
                                  _visibleLines.isNotEmpty)
                                const SizedBox(height: 2),
                              ..._visibleLines.map(_lineRow),
                            ],
                          ),
                        ),
                        if (_hasActions)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (onMessage != null) ...[
                                _ActionBtn(
                                  icon: messageIcon,
                                  activeColor: accentColor,
                                  enabled: true,
                                  onTap: onMessage!,
                                ),
                                const SizedBox(width: 5),
                              ],
                              if (onEdit != null) ...[
                                _ActionBtn(
                                  icon: Icons.edit_rounded,
                                  activeColor: AppDesign.info,
                                  enabled: canEdit,
                                  blockedMessage: editBlockedMessage,
                                  onTap: onEdit!,
                                ),
                                const SizedBox(width: 5),
                              ],
                              if (onDelete != null)
                                _ActionBtn(
                                  icon: Icons.delete_rounded,
                                  activeColor: AppDesign.danger,
                                  enabled: canDelete,
                                  blockedMessage: deleteBlockedMessage,
                                  onTap: onDelete!,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lineRow(AppEntityListLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          if (line.icon != null) ...[
            Icon(line.icon, size: 13, color: AppDesign.textTertiary),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: Text(
              line.text,
              style: const TextStyle(
                fontSize: 11,
                color: AppDesign.textSecondary,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentPanel extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String entityLabel;

  const _AccentPanel({
    required this.accentColor,
    required this.icon,
    required this.entityLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor.withValues(alpha: 0.88), accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -16,
          right: -12,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                entityLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 6.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color activeColor;
  final bool enabled;
  final VoidCallback onTap;
  final String? blockedMessage;

  static const Color _disabledColor = AppDesign.textTertiary;

  const _ActionBtn({
    required this.icon,
    required this.activeColor,
    required this.enabled,
    required this.onTap,
    this.blockedMessage,
  });

  void _handleTap(BuildContext context) {
    if (enabled) {
      onTap();
      return;
    }
    final msg = blockedMessage?.trim();
    if (msg != null && msg.isNotEmpty) {
      AppSnackbar.error(context, msg);
      return;
    }
    AppSnackbar.error(context, 'Aksi tidak tersedia');
  }

  @override
  Widget build(BuildContext context) {
    final color = enabled ? activeColor : _disabledColor;
    return Material(
      color: color.withValues(alpha: enabled ? 0.1 : 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

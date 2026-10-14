import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Màu (chính, nền nhạt) theo giá trị state Odoo phổ biến của các module LIMS.
/// State lạ → màu thông tin (xanh dương).
(Color, Color) recordStateColors(String state) {
  switch (state) {
    case '':
    case 'draft':
    case 'new':
      return (AppColors.inkMuted, AppColors.divider);
    case 'cancel':
    case 'cancelled':
    case 'rejected':
    case 'refused':
      return (AppColors.danger, AppColors.dangerSoft);
    case 'done':
    case 'received':
    case 'approved':
    case 'confirmed':
    case 'completed':
    case 'result_returned':
    case 'director_confirmed':
    case 'data_synced':
    case 'destroyed':
    case 'assigned':
      return (AppColors.success, AppColors.successSoft);
    case 'returned':
    case 'expired':
    case 'pending':
    case 'warning':
    case 'sent':
      return (AppColors.warning, AppColors.warningSoft);
    default:
      return (AppColors.info, AppColors.infoSoft);
  }
}

/// Card bản ghi dùng chung cho list mobile: viền trái màu trạng thái · tiêu đề
/// + chip trạng thái · dòng phụ (vd khách hàng) · tag (vd loại mẫu) + ghi chú ·
/// footer tham chiếu (icon + text) + chevron.
class RecordCard extends StatelessWidget {
  final String title;
  final String state; // giá trị state Odoo → màu qua [recordStateColors]
  final String stateLabel;
  final String subtitle;
  final String tag;
  final IconData tagIcon;
  final String note;
  final List<(IconData, String)> refs;
  final VoidCallback onTap;

  const RecordCard({
    super.key,
    required this.title,
    required this.onTap,
    this.state = '',
    this.stateLabel = '',
    this.subtitle = '',
    this.tag = '',
    this.tagIcon = Icons.science_outlined,
    this.note = '',
    this.refs = const [],
  });

  @override
  Widget build(BuildContext context) {
    final (stateColor, stateSoft) = recordStateColors(state);
    final refs = [
      for (final r in this.refs)
        if (r.$2.isNotEmpty) r,
    ];
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: stateColor, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title.isEmpty ? '(Chưa có mã)' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppType.bodyLg,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (stateLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _StatePill(
                      label: stateLabel,
                      color: stateColor,
                      soft: stateSoft,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppType.bodyLg,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              if (tag.isNotEmpty || note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (tag.isNotEmpty) ...[
                      _TypeTag(tag, icon: tagIcon),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppType.body,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (refs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          for (final (icon, text) in refs)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 14, color: AppColors.inkMuted),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: AppType.caption,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  final String label;
  final Color color;
  final Color soft;
  const _StatePill({
    required this.label,
    required this.color,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: AppType.caption,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTag extends StatelessWidget {
  final String text;
  final IconData icon;
  const _TypeTag(this.text, {required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.teal),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: AppType.caption,
              fontWeight: FontWeight.w600,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_kit.dart';
import '../widgets/states.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// TRUNG TÂM THÔNG BÁO (Notification Center).
///
/// Tiêu thụ singleton global [notifications] ([NotificationController]):
/// - `attach(sessionId)` + `refresh()` khi vào màn (service có mock fallback nên
///   render được offline cho dev preview).
/// - Pull-to-refresh gọi lại `refresh()`.
/// - Nhấn 1 thông báo → `markRead(id)` (optimistic, target = mail.notification id).
/// - Nút "Đọc hết" trên header → mark từng mục chưa đọc.
///
/// Thiết kế: chưa đọc = nổi bật (chấm + nền nhạt + chữ đậm), đã đọc = mờ đi.
/// Nhóm theo ngày: Hôm nay / Hôm qua / Trước đó. Dùng token [AppColors].
/// ───────────────────────────────────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  final String sessionId;
  const NotificationsScreen({super.key, required this.sessionId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    // Attach session + tải lần đầu sau khi frame dựng xong.
    notifications.attach(widget.sessionId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifications.refresh();
    });
  }

  Future<void> _markAllRead() async {
    final unread = notifications.items
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();
    if (unread.isEmpty || _markingAll) return;
    setState(() => _markingAll = true);
    for (final id in unread) {
      await notifications.markRead(id);
    }
    if (mounted) setState(() => _markingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    // Tự bọc BrandTheme để đúng font cả khi được push như route riêng.
    return BrandTheme(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: AnimatedBuilder(
          animation: notifications,
          builder: (context, _) {
            final unread = notifications.unreadCount;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrandTabHeader(
                  title: 'Thông báo',
                  subtitle: unread > 0
                      ? '$unread thông báo chưa đọc'
                      : 'Bạn đã đọc hết thông báo',
                  action: _MarkAllAction(
                    enabled: unread > 0 && !_markingAll,
                    busy: _markingAll,
                    onTap: _markAllRead,
                  ),
                ),
                Expanded(child: _buildBody(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final items = notifications.items;
    if (notifications.loading && items.isEmpty) {
      return const SkeletonList(itemCount: 6);
    }
    if (items.isEmpty) {
      // EmptyState không cuộn → bọc để pull-to-refresh vẫn hoạt động.
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => notifications.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Chưa có thông báo',
                message: 'Các thông báo mới sẽ xuất hiện tại đây.',
              ),
            ),
          ],
        ),
      );
    }
    return _NotificationList(
      items: items,
      onTap: (n) {
        if (!n.isRead) notifications.markRead(n.id);
      },
      onRefresh: () => notifications.refresh(),
    );
  }
}

/// Nút "Đánh dấu tất cả đã đọc" trên header — có vùng chạm ≥ 44dp + Semantics.
class _MarkAllAction extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;
  const _MarkAllAction({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? kBrandTeal : kBrandMuted;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Đánh dấu tất cả đã đọc',
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: TextButton.icon(
          onPressed: enabled ? onTap : null,
          style: TextButton.styleFrom(
            foregroundColor: color,
            disabledForegroundColor: color,
            backgroundColor: Colors.white.withValues(alpha: enabled ? 1 : 0.6),
            minimumSize: const Size(0, AppType.minTapTarget),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: const StadiumBorder(),
          ),
          icon: busy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : const Icon(Icons.done_all_rounded, size: 18),
          label: const Text(
            'Đọc hết',
            style: TextStyle(
              fontSize: AppType.body,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Danh sách thông báo nhóm theo ngày + pull-to-refresh.
class _NotificationList extends StatelessWidget {
  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;
  final Future<void> Function() onRefresh;

  const _NotificationList({
    required this.items,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDay(items);
    // Mỗi group đóng góp: 1 header + N item.
    final rows = <_Row>[];
    for (final g in groups) {
      rows.add(_Row.header(g.label));
      for (final n in g.items) {
        rows.add(_Row.item(n));
      }
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final row = rows[i];
          if (row.isHeader) return BrandSectionLabel(row.label!);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _NotificationCard(
              n: row.item!,
              onTap: () => onTap(row.item!),
            ),
          );
        },
      ),
    );
  }
}

/// Phần tử danh sách phẳng: header ngày hoặc 1 thông báo.
class _Row {
  final String? label;
  final AppNotification? item;
  const _Row.header(this.label) : item = null;
  const _Row.item(this.item) : label = null;
  bool get isHeader => label != null;
}

class _DayGroup {
  final String label;
  final List<AppNotification> items;
  _DayGroup(this.label, this.items);
}

/// Phân loại thông báo về 3 nhóm theo ngày (so với hôm nay). Giữ nguyên thứ tự
/// backend trả (mới nhất trước). Date có dạng 'YYYY-MM-DD HH:MM:SS'.
List<_DayGroup> _groupByDay(List<AppNotification> items) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final todayItems = <AppNotification>[];
  final yesterdayItems = <AppNotification>[];
  final olderItems = <AppNotification>[];

  for (final n in items) {
    final d = _parseDay(n.date);
    if (d == null) {
      olderItems.add(n);
    } else if (!d.isBefore(today)) {
      todayItems.add(n);
    } else if (!d.isBefore(yesterday)) {
      yesterdayItems.add(n);
    } else {
      olderItems.add(n);
    }
  }

  return [
    if (todayItems.isNotEmpty) _DayGroup('Hôm nay', todayItems),
    if (yesterdayItems.isNotEmpty) _DayGroup('Hôm qua', yesterdayItems),
    if (olderItems.isNotEmpty) _DayGroup('Trước đó', olderItems),
  ];
}

DateTime? _parseDay(String raw) {
  final dt = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (dt == null) return null;
  return DateTime(dt.year, dt.month, dt.day);
}

/// Giờ hiển thị gọn (HH:MM) cho dòng metadata.
String _shortTime(String raw) {
  final dt = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (dt == null) return raw;
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Thẻ 1 thông báo. Chưa đọc: nền primary nhạt + viền primary + chấm + tiêu đề
/// đậm. Đã đọc: surface trơn + mờ nhẹ.
class _NotificationCard extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotificationCard({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !n.isRead;
    final accent = _accentFor(n.resModel);
    final bg = unread
        ? AppColors.teal.withValues(alpha: 0.06)
        : AppColors.surface;
    final borderColor = unread
        ? AppColors.teal.withValues(alpha: 0.3)
        : AppColors.border;

    return Semantics(
      button: true,
      label: '${unread ? 'Chưa đọc. ' : ''}${n.subject}. ${n.bodyPreview}',
      child: Opacity(
        opacity: unread ? 1 : 0.72,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandIconTile(icon: accent.icon, color: accent.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                n.subject.isEmpty
                                    ? '(Không tiêu đề)'
                                    : n.subject,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppType.bodyLg,
                                  fontWeight: unread
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: AppColors.ink,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (unread) ...[
                              const SizedBox(width: 8),
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: AppColors.teal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (n.bodyPreview.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            n.bodyPreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppType.body,
                              color: AppColors.inkSoft,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppColors.inkMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _shortTime(n.date),
                              style: TextStyle(
                                fontSize: AppType.caption,
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Accent {
  final Color color;
  final IconData icon;
  const _Accent(this.color, this.icon);
}

/// Suy icon + màu theo model nguồn của thông báo (gợi ý ngữ cảnh, không bắt buộc
/// khớp 1:1). Mặc định → chuông primary.
_Accent _accentFor(String resModel) {
  switch (resModel) {
    case 'etech.service.request':
      return _Accent(AppColors.primary, Icons.description_outlined);
    case 'etech.sampling.report':
      return _Accent(AppColors.teal, Icons.science_outlined);
    case 'etech.test.report':
      return _Accent(AppColors.success, Icons.fact_check_outlined);
    case 'res.partner':
      return _Accent(AppColors.violet, Icons.person_outline_rounded);
    default:
      return _Accent(AppColors.primary, Icons.notifications_none_rounded);
  }
}

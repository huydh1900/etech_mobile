import 'package:flutter/material.dart';
import '../services/notification_controller.dart';
import '../services/permission_controller.dart';
import '../theme/app_theme.dart';
import '../models/search_spec.dart';
import 'paged_list.dart';
import 'states.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// SCAFFOLD LIST CHUẨN cho mọi module (feature agent tái sử dụng).
///
/// Gói: AppBar (tiêu đề + chuông thông báo có badge) + [PagedListView] (search,
/// chip lọc, infinite scroll, empty/error/loading dùng states.dart). Gating
/// quyền qua [permissions]: nếu [permissionModel] != null và user không có quyền
/// đọc → hiện màn "không có quyền" thay vì danh sách.
///
/// Ví dụ tham chiếu: lib/screens/customers_screens.dart.
/// ───────────────────────────────────────────────────────────────────────────
class ModuleListScaffold<T> extends StatelessWidget {
  /// Tiêu đề AppBar.
  final String title;

  /// Hàm tải trang (signature cố định, khớp [PagedFetch]).
  final PagedFetch<T> fetch;

  /// Builder cho từng item.
  final Widget Function(BuildContext, T) itemBuilder;

  /// Chip lọc trạng thái (value,label); '' = "Tất cả". Rỗng → ẩn chip.
  final List<MapEntry<String, String>> stateFilters;
  final String searchHint;
  final String unitLabel;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final int pageSize;

  /// Tên model Odoo để gating quyền đọc (vd 'res.partner'). null = không gate.
  final String? permissionModel;

  /// Khi nhấn chuông thông báo. null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  /// Actions phụ thêm vào AppBar (bên trái chuông).
  final List<Widget> actions;

  /// FAB tuỳ chọn (vd nút tạo mới — feature agent tự gate canCreate).
  final Widget? floatingActionButton;

  /// Bộ lọc/Nhóm theo theo search view Odoo — xem [PagedListView.searchSpec].
  final Future<SearchSpec> Function()? searchSpec;

  const ModuleListScaffold({
    super.key,
    required this.title,
    required this.fetch,
    required this.itemBuilder,
    this.stateFilters = const [],
    this.searchHint = 'Tìm kiếm…',
    this.unitLabel = 'mục',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Chưa có dữ liệu',
    this.emptyMessage = 'Dữ liệu sẽ hiển thị tại đây.',
    this.pageSize = 80,
    this.permissionModel,
    this.onOpenNotifications,
    this.actions = const [],
    this.floatingActionButton,
    this.searchSpec,
  });

  @override
  Widget build(BuildContext context) {
    final gated =
        permissionModel != null &&
        permissions.loaded &&
        !permissions.canRead(permissionModel!);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...actions,
          if (onOpenNotifications != null)
            NotificationBell(onTap: onOpenNotifications!),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: gated ? null : floatingActionButton,
      body: gated
          ? const _NoPermissionState()
          : PagedListView<T>(
              fetch: fetch,
              itemBuilder: itemBuilder,
              stateFilters: stateFilters,
              searchHint: searchHint,
              unitLabel: unitLabel,
              emptyIcon: emptyIcon,
              emptyTitle: emptyTitle,
              emptyMessage: emptyMessage,
              pageSize: pageSize,
              searchSpec: searchSpec,
            ),
    );
  }
}

/// ───────────────────────────────────────────────────────────────────────────
/// SCAFFOLD DETAIL CHUẨN — bọc FutureBuilder với SkeletonList (loading) /
/// ErrorState+retry (lỗi) / [builder] (data). Feature agent chỉ truyền future
/// factory + builder nội dung.
/// ───────────────────────────────────────────────────────────────────────────
class ModuleDetailScaffold<T> extends StatefulWidget {
  final String title;

  /// Tạo future tải chi tiết — gọi lại khi retry. KHÔNG truyền future sẵn (để
  /// retry tạo future mới).
  final Future<T> Function() load;

  /// Dựng nội dung từ data + callback reload (vd sau khi cập nhật).
  final Widget Function(BuildContext context, T data, VoidCallback reload)
  builder;

  /// Actions phụ trên AppBar.
  final List<Widget> actions;

  const ModuleDetailScaffold({
    super.key,
    required this.title,
    required this.load,
    required this.builder,
    this.actions = const [],
  });

  @override
  State<ModuleDetailScaffold<T>> createState() =>
      _ModuleDetailScaffoldState<T>();
}

class _ModuleDetailScaffoldState<T> extends State<ModuleDetailScaffold<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _reload() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(widget.title), actions: widget.actions),
      body: FutureBuilder<T>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SkeletonList();
          }
          if (snap.hasError) {
            return ErrorState(
              message: snap.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }
          return widget.builder(context, snap.data as T, _reload);
        },
      ),
    );
  }
}

/// Chuông thông báo với badge số chưa đọc — đọc từ [notifications] global và
/// tự rebuild khi đếm thay đổi.
class NotificationBell extends StatelessWidget {
  final VoidCallback onTap;

  /// Màu icon chuông. Mặc định [AppColors.ink]; truyền [Colors.white] khi đặt
  /// trên nền tối (header gradient).
  final Color? color;
  const NotificationBell({super.key, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notifications,
      builder: (context, _) {
        final count = notifications.unreadCount;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            onPressed: onTap,
            tooltip: 'Thông báo',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: color ?? AppColors.ink,
                ),
                if (count > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Trạng thái "không có quyền" — hiển thị khi user không được đọc model.
class _NoPermissionState extends StatelessWidget {
  const _NoPermissionState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.warning,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Không có quyền truy cập',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppType.subtitle,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bạn không được phân quyền xem dữ liệu này. '
              'Liên hệ quản trị viên nếu cần truy cập.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppType.body,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

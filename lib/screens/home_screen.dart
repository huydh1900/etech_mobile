import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config.dart';
import '../menu/app_modules.dart';
import '../models/employee.dart';
import '../services/menu_service.dart';
import '../services/notification_controller.dart';
import '../services/permission_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/states.dart';
import 'account_tab.dart';
import 'auth_shell.dart';
import 'module_screen.dart';
import 'notifications_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final int? uid;
  final Employee? employee;
  final String sessionId;
  const HomeScreen({super.key, this.uid, this.employee, this.sessionId = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  /// Hồ sơ nhân viên hiện tại — giữ ở state để cập nhật ngay sau khi sửa
  /// thông tin/avatar từ tab Tài khoản.
  late Employee? _employee = widget.employee;

  /// Danh sách module hiển thị — mặc định cấu hình tĩnh, được thay bằng kết
  /// quả đồng bộ động từ backend (lọc theo quyền user) khi tải xong.
  List<AppModule> _modules = kAppModules;

  @override
  void initState() {
    super.initState();
    _syncMenus();
    _initControllers();
  }

  /// Nạp quyền + thông báo sau khi đăng nhập, song song với đồng bộ menu.
  /// Bọc try/catch để lỗi mạng/quyền KHÔNG bao giờ chặn UI (default-allow,
  /// notification service có mock fallback).
  Future<void> _initControllers() async {
    final sid = widget.sessionId;
    if (sid.isEmpty) return;
    try {
      await permissions.load(sid);
      // Quyền đã nạp → lọc lại menu theo canSeeMenu (default-allow nếu rỗng).
      if (mounted) setState(() => _modules = _gateModules(_modules));
    } catch (_) {
      // Lỗi → giữ default-allow.
    }
    try {
      notifications.attach(sid);
      await notifications.refresh();
    } catch (_) {
      // Lỗi → badge giữ 0, không chặn UI.
    }
  }

  /// Lọc cây module theo quyền menu của user ([permissions.canSeeMenu]).
  /// Default-allow: trước khi nạp / backend không trả menu → giữ nguyên.
  /// Module rỗng menu con sau khi lọc → ẩn luôn.
  List<AppModule> _gateModules(List<AppModule> modules) {
    final out = <AppModule>[];
    for (final m in modules) {
      final kids = m.children
          .where((c) => permissions.canSeeMenu(c.backendXmlId))
          .toList();
      if (kids.isEmpty) continue;
      out.add(m.copyWith(children: kids));
    }
    return out;
  }

  Future<void> _syncMenus() async {
    if (widget.sessionId.isEmpty) return;
    try {
      final sync = await MenuService(
        baseUrl: AppConfig.odooUrl,
        sessionId: widget.sessionId,
      ).fetch();
      if (!mounted) return;
      setState(() {
        _modules = _gateModules(
          resolveModules(visible: sync.visible, names: sync.names),
        );
      });
    } catch (_) {
      // Lỗi mạng/quyền → giữ nguyên cấu hình tĩnh (fallback), không chặn UI.
    }
  }

  // ── FAB: quét mã QR ───────────────────────────────────────────────────────
  Future<void> _onFabPressed() => _scanCode(
    title: 'Quét mã QR',
    hint: 'Đưa mã QR vào khung để quét',
    formats: const [BarcodeFormat.qrCode],
  );

  Future<void> _scanCode({
    required String title,
    required String hint,
    required List<BarcodeFormat> formats,
  }) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            ScannerScreen(title: title, hint: hint, formats: formats),
      ),
    );
    if (!mounted || code == null) return;
    await _showScanResult(code);
  }

  Future<void> _showScanResult(String code) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Kết quả quét', style: TextStyle(color: AppColors.ink)),
        content: SelectableText(
          code,
          style: TextStyle(color: AppColors.ink, fontSize: AppType.subtitle),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(const SnackBar(content: Text('Đã sao chép')));
            },
            child: const Text('Sao chép'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BrandTheme(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        // Mọi tab tự xử lý vùng status bar (header nền sáng tràn lên trên).
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _HomeTab(
              sessionId: widget.sessionId,
              employee: _employee,
              modules: homeModules(_modules),
              onRefresh: _syncMenus,
            ),
            _CalendarTab(sessionId: widget.sessionId, modules: _modules),
            NotificationsScreen(sessionId: widget.sessionId),
            // Tab Tài khoản cũng tự xử lý status bar (header tràn lên trên).
            _employee == null
                ? const SafeArea(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : AccountTab(
                    employee: _employee!,
                    sessionId: widget.sessionId,
                    onUpdated: (e) => setState(() => _employee = e),
                  ),
          ],
        ),
        // Nút quét QR tròn nổi lên giữa mép trên thanh điều hướng.
        floatingActionButton: _ScanNavButton(onTap: _onFabPressed),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _BottomNav(
          index: _currentIndex,
          onSelect: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

/// Thanh điều hướng đáy kiểu mẫu: icon viền + nhãn, mục đang chọn có vạch
/// chỉ báo phía trên; chừa ô giữa cho nút quét QR nổi ([_ScanNavButton]).
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _BottomNav({required this.index, required this.onSelect});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
    (Icons.event_outlined, Icons.event_rounded, 'Lịch'),
    (
      Icons.notifications_none_rounded,
      Icons.notifications_rounded,
      'Thông báo',
    ),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                // Ô trống giữa (sau 2 tab đầu) cho nút quét QR nổi.
                if (i == _items.length ~/ 2) const Expanded(child: SizedBox()),
                Expanded(
                  child: _BottomNavItem(
                    icon: _items[i].$1,
                    activeIcon: _items[i].$2,
                    label: _items[i].$3,
                    // Tab Thông báo hiện badge số chưa đọc (thay chuông ở header).
                    showUnread: i == 2,
                    selected: i == index,
                    onTap: () => onSelect(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút quét QR tròn màu đặc, viền trắng dày, đổ bóng — nổi lên giữa thanh
/// điều hướng (dùng được từ mọi tab).
class _ScanNavButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanNavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Quét mã QR',
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          boxShadow: AppShadows.lifted,
        ),
        padding: const EdgeInsets.all(4),
        child: Material(
          color: const Color(0xFF0E8A7D),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool showUnread;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showUnread = false,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.teal : AppColors.inkMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: selected ? 28 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(3),
              ),
            ),
          ),
          const Spacer(),
          if (showUnread)
            AnimatedBuilder(
              animation: notifications,
              builder: (context, _) => Badge(
                isLabelVisible: notifications.unreadCount > 0,
                backgroundColor: AppColors.danger,
                label: Text(
                  notifications.unreadCount > 99
                      ? '99+'
                      : '${notifications.unreadCount}',
                ),
                child: Icon(
                  selected ? activeIcon : icon,
                  color: color,
                  size: 24,
                ),
              ),
            )
          else
            Icon(selected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppType.micro,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── HOME TAB ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final String sessionId;
  final Employee? employee;
  final List<AppModule> modules;

  /// Đồng bộ lại dữ liệu thật khi kéo refresh (nối với menu sync ở [HomeScreen]).
  final Future<void> Function() onRefresh;

  const _HomeTab({
    this.sessionId = '',
    required this.employee,
    required this.modules,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ColoredBox(
        // Nền xám nhạt để các thẻ nhóm chức năng (trắng) nổi lên.
        color: AppColors.bg,
        child: RefreshIndicator(
          color: AppColors.primary,
          edgeOffset: top,
          onRefresh: onRefresh,
          child: ListView(
            // Chừa chỗ cho nút quét QR nổi đè mép dưới.
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _HomeHeader(employee: employee, sessionId: sessionId),
              for (final m in modules)
                _ModuleSection(module: m, sessionId: sessionId),
              // Backend lọc menu theo nhóm quyền (vd "Nhân viên hiện trường")
              // → tài khoản không thuộc nhóm nào sẽ không có module trang chủ.
              if (modules.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: EmptyState(
                    icon: Icons.apps_rounded,
                    title: 'Chưa có chức năng nào',
                    message:
                        'Tài khoản của bạn chưa được cấp quyền Hiện trường hoặc '
                        'Lịch công tác. Liên hệ quản trị viên để được cấp quyền.',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ nhóm chức năng của 1 module: tiêu đề + lưới nút tròn 4 cột (icon +
/// nhãn), mỗi nút là 1 menu con. Menu con còn cấp 3 → mở sheet chọn tiếp.
class _ModuleSection extends StatelessWidget {
  final AppModule module;
  final String sessionId;

  const _ModuleSection({required this.module, required this.sessionId});

  static const int _columns = 4;

  void _open(BuildContext context, AppSubMenu sub) {
    if (sub.children.isNotEmpty) {
      showMenuSheet(
        context,
        title: sub.name,
        description: '',
        icon: sub.icon,
        accent: AppColors.teal,
        children: sub.children,
        sessionId: sessionId,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => resolveSubMenuScreen(sub, sessionId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (module.children.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.name,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth / _columns;
              return Wrap(
                children: [
                  for (final sub in module.children)
                    SizedBox(
                      width: w,
                      child: _FeatureButton(
                        sub: sub,
                        onTap: () => _open(context, sub),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Nút chức năng: vòng tròn trắng đổ bóng nhẹ, icon màu thương hiệu, nhãn
/// tối đa 2 dòng bên dưới.
class _FeatureButton extends StatelessWidget {
  final AppSubMenu sub;
  final VoidCallback onTap;

  const _FeatureButton({required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
                boxShadow: AppShadows.soft,
              ),
              child: Icon(sub.icon, color: const Color(0xFF0E8A7D), size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              sub.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header trang chủ: lời chào + avatar —
/// nền sáng cùng họ màu logo, tràn lên dưới status bar, bo góc dưới.
class _HomeHeader extends StatelessWidget {
  final Employee? employee;
  final String sessionId;

  const _HomeHeader({required this.employee, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final e = employee;
    final subtitle = e == null
        ? ''
        : [
            e.jobPosition,
            e.department,
          ].where((s) => s.trim().isNotEmpty).join(' · ');
    return BrandHeader(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: e == null
                ? const Icon(Icons.person_rounded, color: Colors.white)
                : employeeAvatarChild(e, sessionId, 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(color: kBrandMuted, fontSize: AppType.body),
                ),
                const SizedBox(height: 2),
                Text(
                  e?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kBrandNavy,
                    fontSize: AppType.title,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kBrandMuted,
                      fontSize: AppType.caption,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mở sheet menu (dùng chung cho menu cấp 2 của module và menu cấp 3 của một
/// menu con — cùng một thiết kế).
void showMenuSheet(
  BuildContext context, {
  required String title,
  required String description,
  required IconData icon,
  required Color accent,
  required List<AppSubMenu> children,
  required String sessionId,
  VoidCallback? onBack,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _ModuleMenuSheet(
      title: title,
      description: description,
      icon: icon,
      accent: accent,
      children: children,
      sessionId: sessionId,
      onBack: onBack,
    ),
  );
}

/// Sheet menu con — nổi từ dưới lên khi nhấn ô module trên lưới. Liệt kê các
/// menu con dạng hàng bấm được; chọn 1 mục → đóng sheet rồi điều hướng tới màn
/// hình tương ứng (qua [resolveSubMenuScreen]). Mục còn menu con (cấp 3) thì mở
/// tiếp một sheet y hệt thay vì điều hướng.
class _ModuleMenuSheet extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final List<AppSubMenu> children;
  final String sessionId;

  /// Mở lại sheet menu cha (null → đây đã là cấp trên cùng, ẩn nút quay lại).
  final VoidCallback? onBack;

  const _ModuleMenuSheet({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.children,
    required this.sessionId,
    this.onBack,
  });

  void _openChild(BuildContext context, AppSubMenu sub) {
    final navigator = Navigator.of(context);
    final host = navigator.context;
    navigator.pop(); // đóng sheet trước
    if (sub.children.isNotEmpty) {
      showMenuSheet(
        host,
        title: sub.name,
        description: '',
        icon: sub.icon,
        accent: accent,
        children: sub.children,
        sessionId: sessionId,
        onBack: () => showMenuSheet(
          host,
          title: title,
          description: description,
          icon: icon,
          accent: accent,
          children: children,
          sessionId: sessionId,
          onBack: onBack,
        ),
      );
      return;
    }
    navigator.push(
      MaterialPageRoute(builder: (_) => resolveSubMenuScreen(sub, sessionId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header: icon module + tên + mô tả.
            Row(
              children: [
                // Sheet cấp 3 → nút quay lại sheet menu cha.
                if (onBack != null) ...[
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onBack!();
                    },
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.inkSoft,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppType.title,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppType.caption,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Chưa có chức năng trong phân hệ này.',
                  style: TextStyle(
                    fontSize: AppType.body,
                    color: AppColors.inkMuted,
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          _MenuLinkRow(
                            sub: children[i],
                            accent: accent,
                            onTap: () => _openChild(context, children[i]),
                          ),
                          if (i != children.length - 1)
                            Divider(
                              height: 1,
                              color: AppColors.divider,
                              indent: 58,
                              endIndent: 14,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ phân hệ: icon đơn sắc theo màu nhấn của module + tên + mô tả + số mục.
/// Nền surface, viền mảnh, đổ bóng nhẹ — đồng nhất, không pastel sặc sỡ.
// ─── CALENDAR TAB ────────────────────────────────────────────────────────────

class _CalendarTab extends StatelessWidget {
  final String sessionId;
  final List<AppModule> modules;
  const _CalendarTab({required this.sessionId, required this.modules});

  @override
  Widget build(BuildContext context) {
    final module = moduleByKey('calendar', modules);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const BrandTabHeader(
          title: 'Lịch công tác',
          subtitle: 'Lịch & phân công công việc của bạn',
        ),
        if (module != null) ...[
          const BrandSectionLabel('Chức năng'),
          BrandMenuGroup(
            children: [
              for (final sub in module.children)
                BrandMenuRow(
                  icon: sub.icon,
                  color: module.gradient.first,
                  label: sub.name,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => resolveSubMenuScreen(sub, sessionId),
                    ),
                  ),
                  // Chưa có màn mobile thật → gắn nhãn "Sắp có" trước mũi tên.
                  trailing: sub.implemented
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusPill(
                              label: 'Sắp có',
                              color: AppColors.inkMuted,
                              background: AppColors.divider,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: AppColors.inkMuted,
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MenuLinkRow extends StatelessWidget {
  final AppSubMenu sub;
  final Color accent;
  final VoidCallback onTap;

  const _MenuLinkRow({
    required this.sub,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(sub.icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sub.name,
                  style: TextStyle(
                    fontSize: AppType.bodyLg,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (!sub.implemented)
                Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: StatusPill(
                    label: 'Sắp có',
                    color: AppColors.inkMuted,
                    background: AppColors.divider,
                  ),
                ),
              Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

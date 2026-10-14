import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_controller.dart';
import '../services/permission_controller.dart';
import '../theme/app_theme.dart';
import 'paged_list.dart' show PagedFetch;
import 'states.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// CLONE GIAO DIỆN ODOO WEB (mobile) — dùng chung cho mọi module.
///
/// Mục tiêu: mỗi màn list mobile GIỐNG HỆT màn Odoo web render ở khổ điện thoại
/// (theo yêu cầu). Backend mobile là 2 kiểu view:
///   • tree  (bảng cuộn ngang: cột `#` + các cột + icon điều chỉnh)  → [OdooTreeListView]
///   • kanban (thẻ dọc: avatar vuông màu + tiêu đề + dòng phụ có icon) → [OdooKanbanCardList]
///
/// Khung chung ([OdooCloneScaffold]) mô phỏng: AppBar tím Odoo (hamburger + tiêu
/// đề + icon chat/chuông/avatar), thanh công cụ (nút "Mới"/"In" + bánh răng +
/// mũi tên đổi view + kính lúp), nút quét mã nổi góc dưới-phải, nền xám nhạt.
///
/// Bảng màu Odoo (cố định — KHÔNG dùng AppColors vì đây là clone web, không theo
/// theme app):
const Color kOdooBg = Color(0xFFFFFFFF); // nền trắng của list
const Color kOdooToolbarBg = Color(0xFFFFFFFF);
// Màu nhấn: teal đậm thương hiệu (thay tím Odoo #714B67) để các màn list
// đồng nhất với trang chủ (nút quét QR, icon chức năng cùng màu này).
const Color kOdooPurple = Color(0xFF0E8A7D); // nút "Mới", avatar, icon nhấn
const Color kOdooPurpleBtn = Color(0xFF0E8A7D);
const Color kOdooInk = Color(0xFF374151); // chữ chính
const Color kOdooInkSoft = Color(0xFF6B7280); // chữ phụ / index
const Color kOdooLink = Color(0xFF017E84); // many2one link (teal)
const Color kOdooBlue = Color(0xFF4A4AF4); // char code link (xanh)
const Color kOdooBorder = Color(0xFFE5E7EB);
const Color kOdooHeaderBg = Color(0xFFFFFFFF);
const Color kOdooTagBg = Color(0xFFFDEBD0); // pill cam nhạt ($ 1)
const Color kOdooTagInk = Color(0xFF8A5A00);

/// Avatar màu Odoo (giống ô vuông màu theo initial trong kanban).
const List<Color> _kOdooAvatarColors = [
  Color(0xFFB03A5B),
  Color(0xFF3C7DB1),
  Color(0xFF4C4C9D),
  Color(0xFF7C5295),
  Color(0xFF2E8B76),
  Color(0xFFC0632B),
  Color(0xFF8A5A00),
  Color(0xFF9C3848),
];

Color odooAvatarColor(String seed) {
  if (seed.isEmpty) return _kOdooAvatarColors.first;
  return _kOdooAvatarColors[seed.codeUnitAt(0) % _kOdooAvatarColors.length];
}

/// ───────────────────────────────────────────────────────────────────────────
/// KHUNG CHUNG kiểu Odoo web.
class OdooCloneScaffold extends StatelessWidget {
  final String title;

  /// Nút chính bên trái toolbar: "Mới" (tạo) hoặc "In" (test_report). null → ẩn.
  final String? primaryButtonLabel;
  final IconData? primaryButtonIcon;
  final VoidCallback? onPrimaryButton;

  /// Nội dung list (thường [OdooTreeListView] / [OdooKanbanCardList]).
  final Widget body;

  /// Nhấn chuông thông báo. null → vẫn hiện chuông (Odoo luôn có) nhưng no-op.
  final VoidCallback? onOpenNotifications;

  /// Nhấn nút quét mã (FAB tròn góc dưới-phải). null → ẩn FAB.
  final VoidCallback? onScan;

  /// Callback khi bấm kính lúp (mở ô tìm kiếm). Truyền để bật search.
  final VoidCallback? onSearch;
  final bool searchActive;

  /// Model Odoo để gating quyền đọc (vd 'etech.lab.batch'). null = không gate.
  /// Không có quyền → ẩn toolbar/FAB, hiện trạng thái "không có quyền".
  final String? permissionModel;

  /// Hiện cụm icon bên phải AppBar (tin nhắn + chuông + avatar) kiểu Odoo web.
  final bool showAppBarActions;

  /// Hiện nút bánh răng (cog) trên toolbar.
  final bool showSettingsButton;

  const OdooCloneScaffold({
    super.key,
    required this.title,
    required this.body,
    this.primaryButtonLabel,
    this.primaryButtonIcon,
    this.onPrimaryButton,
    this.onOpenNotifications,
    this.onScan,
    this.onSearch,
    this.searchActive = false,
    this.permissionModel,
    this.showAppBarActions = true,
    this.showSettingsButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final gated =
        permissionModel != null &&
        permissions.loaded &&
        !permissions.canRead(permissionModel!);
    return Scaffold(
      backgroundColor: kOdooBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _OdooAppBar(
          title: title,
          onOpenNotifications: onOpenNotifications,
          showActions: showAppBarActions,
        ),
      ),
      floatingActionButton: (gated || onScan == null)
          ? null
          : _OdooScanFab(onTap: onScan!),
      body: gated
          ? const EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Không có quyền truy cập',
              message:
                  'Bạn không được phân quyền xem dữ liệu này. '
                  'Liên hệ quản trị viên nếu cần truy cập.',
            )
          : Column(
              children: [
                _OdooToolbar(
                  primaryButtonLabel: primaryButtonLabel,
                  primaryButtonIcon: primaryButtonIcon,
                  onPrimaryButton: onPrimaryButton,
                  onSearch: onSearch,
                  searchActive: searchActive,
                  showSettingsButton: showSettingsButton,
                ),
                const Divider(height: 1, thickness: 1, color: kOdooBorder),
                Expanded(child: body),
              ],
            ),
    );
  }
}

class _OdooAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onOpenNotifications;
  final bool showActions;
  const _OdooAppBar({
    required this.title,
    this.onOpenNotifications,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    // Thanh trên cùng cùng style AppBar/header trang chủ: nền sáng cùng họ màu
    // logo, bo góc dưới, tiêu đề navy font thương hiệu.
    return Material(
      color: kAppBarTint,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                onPressed: canPop
                    ? () => Navigator.of(context).maybePop()
                    : null,
                icon: Icon(
                  canPop ? Icons.arrow_back_rounded : Icons.menu,
                  color: AppColors.navy,
                ),
                iconSize: 22,
              ),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kBrandFont,
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showActions) ...[
                const Icon(
                  Icons.chat_bubble,
                  color: Color(0xFF1F2937),
                  size: 20,
                ),
                const SizedBox(width: 14),
                _BellIcon(onTap: onOpenNotifications),
                const SizedBox(width: 12),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: kOdooPurple,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chuông có badge đỏ (đọc từ controller global, giống app nhưng style Odoo).
class _BellIcon extends StatelessWidget {
  final VoidCallback? onTap;
  const _BellIcon({this.onTap});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notifications,
      builder: (context, _) {
        final count = notifications.unreadCount;
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications,
                color: Color(0xFF1F2937),
                size: 21,
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE01E5A),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 9 ? '9+' : '$count',
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
        );
      },
    );
  }
}

/// Thanh công cụ Odoo: [Mới/In] [⚙] ......... [<][>] [🔍]
class _OdooToolbar extends StatelessWidget {
  final String? primaryButtonLabel;
  final IconData? primaryButtonIcon;
  final VoidCallback? onPrimaryButton;
  final VoidCallback? onSearch;
  final bool searchActive;
  final bool showSettingsButton;
  const _OdooToolbar({
    this.primaryButtonLabel,
    this.primaryButtonIcon,
    this.onPrimaryButton,
    this.onSearch,
    this.searchActive = false,
    this.showSettingsButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kOdooToolbarBg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          if (primaryButtonLabel != null)
            GestureDetector(
              onTap: onPrimaryButton,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: kOdooPurpleBtn,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    if (primaryButtonIcon != null) ...[
                      Icon(primaryButtonIcon, color: Colors.white, size: 15),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      primaryButtonLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (primaryButtonLabel != null) const SizedBox(width: 8),
          if (showSettingsButton)
            _ToolbarSquare(
              child: const Icon(Icons.settings, color: kOdooInkSoft, size: 17),
            ),
          const Spacer(),
          _ToolbarSquare(
            child: const Icon(
              Icons.chevron_left,
              color: kOdooInkSoft,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          _ToolbarSquare(
            child: const Icon(
              Icons.chevron_right,
              color: kOdooInkSoft,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          _ToolbarSquare(
            active: searchActive,
            onTap: onSearch,
            child: Icon(
              Icons.search,
              color: searchActive ? kOdooPurple : kOdooInkSoft,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarSquare extends StatelessWidget {
  final Widget child;
  final bool active;
  final VoidCallback? onTap;
  const _ToolbarSquare({required this.child, this.active = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE3F4EE) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: kOdooBorder),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// FAB quét mã — cùng kiểu nút quét QR trang chủ (teal đậm, viền trắng dày).
class _OdooScanFab extends StatelessWidget {
  final VoidCallback onTap;
  const _OdooScanFab({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kOdooPurple,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: AppShadows.lifted,
        ),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
      ),
    );
  }
}

/// ───────────────────────────────────────────────────────────────────────────
/// TREE (bảng cuộn ngang) — clone list-view Odoo trên mobile.
/// Một cột: nhãn header + hàm lấy giá trị + kiểu link + độ rộng.
class OdooTreeColumn<T> {
  final String label;
  final String Function(T) value;

  /// true → chữ màu link (many2one). Mặc định false (char thường, chữ đậm ink).
  final bool link;

  /// Màu link riêng (mặc định [kOdooLink]). Vd mã PTM dùng [kOdooBlue].
  final Color? linkColor;
  final double width;

  const OdooTreeColumn({
    required this.label,
    required this.value,
    this.link = false,
    this.linkColor,
    this.width = 120,
  });
}

/// Bảng tree cuộn ngang, phân trang (tái dùng [PagedFetch] như PagedListView).
/// Header dính (`#` + cột + icon điều chỉnh) cuộn ngang đồng bộ với các hàng.
class OdooTreeListView<T> extends StatefulWidget {
  final PagedFetch<T> fetch;
  final List<OdooTreeColumn<T>> columns;
  final void Function(BuildContext, T)? onTapRow;
  final int pageSize;

  /// Ô tìm kiếm hiện phía trên (bật/tắt bởi kính lúp toolbar).
  final bool showSearch;
  final String searchHint;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  const OdooTreeListView({
    super.key,
    required this.fetch,
    required this.columns,
    this.onTapRow,
    this.pageSize = 40,
    this.showSearch = false,
    this.searchHint = 'Tìm kiếm…',
    this.emptyIcon = Icons.description_outlined,
    this.emptyTitle = 'Tạo mới tài liệu',
    this.emptyMessage = '',
  });

  @override
  State<OdooTreeListView<T>> createState() => _OdooTreeListViewState<T>();
}

class _OdooTreeListViewState<T> extends State<OdooTreeListView<T>> {
  final _vCtrl = ScrollController();
  final _hHeader = ScrollController();
  final _hBody = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<T> _items = [];
  int _total = 0;
  String _query = '';
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  bool _syncing = false;

  bool get _hasMore => _items.length < _total;
  static const double _gutter = 44;

  double get _rowWidth =>
      _gutter + widget.columns.fold(0.0, (a, c) => a + c.width) + 40;

  @override
  void initState() {
    super.initState();
    _vCtrl.addListener(_onScroll);
    // Đồng bộ cuộn ngang header <-> body.
    _hBody.addListener(() => _mirror(_hBody, _hHeader));
    _hHeader.addListener(() => _mirror(_hHeader, _hBody));
    _loadFirst();
  }

  void _mirror(ScrollController from, ScrollController to) {
    if (_syncing || !to.hasClients) return;
    _syncing = true;
    if (to.offset != from.offset) to.jumpTo(from.offset);
    _syncing = false;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _vCtrl.dispose();
    _hHeader.dispose();
    _hBody.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_vCtrl.position.pixels >= _vCtrl.position.maxScrollExtent - 240 &&
        _hasMore &&
        !_loadingMore &&
        !_loading) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.fetch(
        state: null,
        query: _query.isEmpty ? null : _query,
        offset: 0,
        limit: widget.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(r.items);
        _total = r.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final r = await widget.fetch(
        state: null,
        query: _query.isEmpty ? null : _query,
        offset: _items.length,
        limit: widget.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(r.items);
        _total = r.total;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_query == v.trim()) return;
      _query = v.trim();
      _loadFirst();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: kOdooInkSoft,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: kOdooBorder),
                ),
              ),
            ),
          ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const SkeletonList();
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadFirst,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorState(message: _error!, onRetry: _loadFirst),
        ),
      );
    }

    final w = _rowWidth;
    return Column(
      children: [
        // Header cuộn ngang đồng bộ.
        SingleChildScrollView(
          controller: _hHeader,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(width: w, child: _headerRow()),
        ),
        const Divider(height: 1, thickness: 1, color: kOdooBorder),
        Expanded(
          child: _items.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadFirst,
                  child: ListView(
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: widget.emptyIcon,
                        title: _query.isEmpty
                            ? widget.emptyTitle
                            : 'Không có kết quả',
                        message: _query.isEmpty
                            ? widget.emptyMessage
                            : 'Thử đổi từ khoá tìm kiếm.',
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFirst,
                  child: SingleChildScrollView(
                    controller: _hBody,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: w,
                      child: ListView.builder(
                        controller: _vCtrl,
                        itemCount: _items.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= _items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                ),
                              ),
                            );
                          }
                          return _dataRow(i, _items[i]);
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _headerRow() {
    return Container(
      height: 40,
      color: kOdooHeaderBg,
      child: Row(
        children: [
          SizedBox(
            width: _gutter,
            child: const Center(
              child: Text(
                '#',
                style: TextStyle(
                  color: kOdooInkSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          for (final c in widget.columns)
            SizedBox(
              width: c.width,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  c.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kOdooInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(
            width: 40,
            child: Icon(Icons.tune, size: 15, color: kOdooInkSoft),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(int i, T item) {
    return InkWell(
      onTap: widget.onTapRow == null
          ? null
          : () => widget.onTapRow!(context, item),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kOdooBorder)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: _gutter,
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(color: kOdooInkSoft, fontSize: 13),
                ),
              ),
            ),
            for (final c in widget.columns)
              SizedBox(
                width: c.width,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    c.value(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.link ? (c.linkColor ?? kOdooLink) : kOdooInk,
                      fontWeight: c.link ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

/// ───────────────────────────────────────────────────────────────────────────
/// KANBAN CARD (thẻ dọc) — clone kanban Odoo (vd Khách hàng).
/// Một dòng phụ dưới tiêu đề: icon nhỏ + text (email/phone/địa chỉ...).
class OdooKanbanLine {
  final IconData icon;
  final String text;

  /// true → chữ link teal (email/phone).
  final bool link;

  /// Số dòng tối đa trước khi cắt "…" (tên dài như tên công ty nên để 2-3).
  final int maxLines;
  const OdooKanbanLine(
    this.icon,
    this.text, {
    this.link = false,
    this.maxLines = 1,
  });
}

class OdooKanbanCard {
  /// Chữ hiển thị trong ô avatar vuông (thường initial). Rỗng → không avatar.
  final String avatarText;
  final String title;
  final List<OdooKanbanLine> lines;

  /// Tag pill nhỏ (vd "$ 1"). Rỗng → ẩn.
  final String tag;
  final VoidCallback? onTap;

  const OdooKanbanCard({
    required this.avatarText,
    required this.title,
    this.lines = const [],
    this.tag = '',
    this.onTap,
  });
}

/// List thẻ kanban, phân trang (tái dùng [PagedFetch]).
class OdooKanbanCardList<T> extends StatefulWidget {
  final PagedFetch<T> fetch;
  final OdooKanbanCard Function(BuildContext, T) cardBuilder;
  final int pageSize;
  final bool showSearch;
  final String searchHint;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  const OdooKanbanCardList({
    super.key,
    required this.fetch,
    required this.cardBuilder,
    this.pageSize = 30,
    this.showSearch = false,
    this.searchHint = 'Tìm kiếm…',
    this.emptyIcon = Icons.people_outline,
    this.emptyTitle = 'Chưa có dữ liệu',
    this.emptyMessage = '',
  });

  @override
  State<OdooKanbanCardList<T>> createState() => _OdooKanbanCardListState<T>();
}

class _OdooKanbanCardListState<T> extends State<OdooKanbanCardList<T>> {
  final _vCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final List<T> _items = [];
  int _total = 0;
  String _query = '';
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _vCtrl.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _vCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_vCtrl.position.pixels >= _vCtrl.position.maxScrollExtent - 240 &&
        _hasMore &&
        !_loadingMore &&
        !_loading) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.fetch(
        state: null,
        query: _query.isEmpty ? null : _query,
        offset: 0,
        limit: widget.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(r.items);
        _total = r.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final r = await widget.fetch(
        state: null,
        query: _query.isEmpty ? null : _query,
        offset: _items.length,
        limit: widget.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(r.items);
        _total = r.total;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_query == v.trim()) return;
      _query = v.trim();
      _loadFirst();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SkeletonList();
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadFirst,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorState(message: _error!, onRetry: _loadFirst),
        ),
      );
    }
    return Column(
      children: [
        if (widget.showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: kOdooInkSoft,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: kOdooBorder),
                ),
              ),
            ),
          ),
        Expanded(
          child: _items.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadFirst,
                  child: ListView(
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: widget.emptyIcon,
                        title: widget.emptyTitle,
                        message: widget.emptyMessage,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFirst,
                  child: ListView.builder(
                    controller: _vCtrl,
                    padding: EdgeInsets.zero,
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            ),
                          ),
                        );
                      }
                      return _OdooKanbanCardTile(
                        card: widget.cardBuilder(context, _items[i]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _OdooKanbanCardTile extends StatelessWidget {
  final OdooKanbanCard card;
  const _OdooKanbanCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: card.onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: kOdooBg,
          border: Border(bottom: BorderSide(color: kOdooBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.avatarText.isNotEmpty) ...[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: odooAvatarColor(card.avatarText),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  card.avatarText.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: const TextStyle(
                      color: kOdooInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final l in card.lines)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            l.icon,
                            size: 14,
                            color: l.link ? kOdooLink : kOdooInkSoft,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l.text,
                              maxLines: l.maxLines,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: l.link ? kOdooLink : kOdooInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (card.tag.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kOdooTagBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        card.tag,
                        style: const TextStyle(
                          color: kOdooTagInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.access_time, size: 16, color: kOdooInkSoft),
          ],
        ),
      ),
    );
  }
}

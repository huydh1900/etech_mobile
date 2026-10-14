import 'dart:async';
import 'package:flutter/material.dart';
import '../models/paged.dart';
import '../models/search_spec.dart';
import '../theme/app_theme.dart';
import 'search_panel.dart';
import 'states.dart';

/// [params]: Bộ lọc/Nhóm theo (filters, date, group_by, group_key…) — service
/// nối nguyên vào query string (xem [extraQuery]); backend tự hiểu.
typedef PagedFetch<T> =
    Future<PagedResult<T>> Function({
      String? state,
      String? query,
      required int offset,
      required int limit,
      Map<String, String>? params,
    });

/// List dùng chung cho mọi màn: search + chip lọc trạng thái (đếm từ server) +
/// infinite scroll + pull-to-refresh. Filter/search/paging chạy SERVER-SIDE
/// nên không bị giới hạn bởi số record đã tải.
class PagedListView<T> extends StatefulWidget {
  final PagedFetch<T> fetch;
  final Widget Function(BuildContext, T) itemBuilder;

  /// Danh sách (value,label) trạng thái; key '' = "Tất cả". Rỗng → ẩn chip.
  final List<MapEntry<String, String>> stateFilters;
  final String searchHint;
  final String unitLabel; // ví dụ 'hồ sơ', 'kế hoạch'
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final int pageSize;

  /// Tải spec Bộ lọc/Nhóm theo (search view Odoo, thường
  /// `() => SearchSpecService.load(sid, 'model')`). null / spec rỗng → ẩn nút
  /// lọc. Có spec: nút lọc cạnh ô search + chip đang bật + chế độ nhóm (nhóm
  /// thu gọn kiểu Odoo, mở nhóm nào mới tải bản ghi nhóm đó).
  final Future<SearchSpec> Function()? searchSpec;

  /// Đổi giá trị (so sánh ==) → tải lại từ trang đầu, giữ search/state hiện
  /// tại. Dùng khi bộ lọc ngoài (nằm trong [fetch]) thay đổi.
  final Object? reloadKey;

  const PagedListView({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.stateFilters = const [],
    this.searchHint = 'Tìm kiếm…',
    this.unitLabel = 'mục',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Không có dữ liệu',
    this.emptyMessage = 'Chưa có bản ghi nào.',
    this.pageSize = 80,
    this.searchSpec,
    this.reloadKey,
  });

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  final _scrollCtrl = ScrollController();

  /// List đã cuộn khỏi đỉnh → hiện viền dưới header.
  bool _scrolled = false;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<T> _items = [];
  Map<String, int> _counts = {};
  // Chế độ nhóm: danh sách nhóm (thứ tự server) + trạng thái từng nhóm mở.
  List<PagedGroup> _groups = const [];
  final Map<String, _GroupSlot<T>> _slots = {};

  SearchSpec _spec = SearchSpec.empty;
  ListQuery _q = const ListQuery();
  bool get _grouped => _q.groupBy != null;
  int _allCount = 0;
  int _total = 0;
  String _state = '';
  String _query = '';

  bool _loading = true;

  /// Trang hiện tại (0-based) — chế độ thường hiển thị đúng 1 trang
  /// [PagedListView.pageSize] bản ghi (kiểu pager Odoo), không cộng dồn.
  int _page = 0;
  bool _pageLoading =
      false; // đang chuyển trang: giữ list cũ + thanh tiến trình
  String? _error;

  int get _pageCount =>
      _total == 0 ? 1 : (_total + widget.pageSize - 1) ~/ widget.pageSize;

  @override
  void initState() {
    super.initState();
    _loadFirst();
    widget.searchSpec?.call().then((s) {
      if (mounted) setState(() => _spec = s);
    });
  }

  Future<void> _openSearchPanel() async {
    final q = await showSearchPanel(context, _spec, _q);
    if (q != null && q != _q) _applyQuery(q);
  }

  void _applyQuery(ListQuery q) {
    setState(() => _q = q);
    _loadFirst();
  }

  @override
  void didUpdateWidget(covariant PagedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadKey != oldWidget.reloadKey) _loadFirst();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
    });
    try {
      final r = await widget.fetch(
        state: _state.isEmpty ? null : _state,
        query: _query.isEmpty ? null : _query,
        offset: 0,
        // Chế độ nhóm chỉ cần groups/đếm — không tải bản ghi (limit 0 ở
        // Odoo = không giới hạn nên dùng 1).
        limit: _grouped ? 1 : widget.pageSize,
        params: _q.toParams(),
      );
      if (!mounted) return;
      setState(() {
        _slots.clear();
        _items
          ..clear()
          ..addAll(r.items);
        _counts = r.counts;
        _groups = r.groups;
        _allCount = r.allCount;
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

  /// Chuyển sang trang [page]: giữ list cũ hiển thị (mờ + thanh tiến trình)
  /// đến khi trang mới về, rồi cuộn lên đầu.
  Future<void> _goToPage(int page) async {
    if (page < 0 || page >= _pageCount || page == _page || _pageLoading) return;
    setState(() => _pageLoading = true);
    try {
      final r = await widget.fetch(
        state: _state.isEmpty ? null : _state,
        query: _query.isEmpty ? null : _query,
        offset: page * widget.pageSize,
        limit: widget.pageSize,
        params: _q.toParams(),
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(r.items);
        _total = r.total;
        _page = page;
        _pageLoading = false;
      });
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pageLoading = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _pickPage() async {
    final page = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _PagePickerSheet(
        pageCount: _pageCount,
        current: _page,
        pageSize: widget.pageSize,
        total: _total,
      ),
    );
    if (page != null) _goToPage(page);
  }

  /// Chế độ tìm kiếm kiểu Odoo: search view có `<field>` → gõ text chỉ hiện
  /// gợi ý `Tìm <trường> cho: …`, chọn mới tìm (facet). Không có → tìm nhanh
  /// theo `q` (search_fields cố định của endpoint) như cũ.
  bool get _facetMode => _spec.fields.isNotEmpty;
  String _typed = '';

  List<SearchField> get _suggestFields => _typed.trim().isEmpty
      ? const []
      : _spec.fields.where((f) => f.accepts(_typed)).toList();

  void _pickField(SearchField f) {
    final text = _typed.trim();
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    setState(() => _typed = '');
    if (text.isNotEmpty) _applyQuery(_q.addFacet(f.name, text));
  }

  void _onSubmitted(String v) {
    if (!_facetMode) return;
    final fields = _suggestFields;
    if (fields.isNotEmpty) _pickField(fields.first);
  }

  void _onSearchChanged(String v) {
    if (_facetMode) {
      setState(() => _typed = v);
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_query == v.trim()) return;
      _query = v.trim();
      _loadFirst();
    });
  }

  void _selectState(String s) {
    if (_state == s) return;
    setState(() => _state = s);
    _loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SearchField(
                controller: _searchCtrl,
                hint: widget.searchHint,
                onChanged: _onSearchChanged,
                onSubmitted: _onSubmitted,
                rightPad: _spec.isEmpty ? 12 : 8,
              ),
            ),
            if (!_spec.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 12, 4),
                child: SearchFilterButton(
                  count: _q.activeCount,
                  onTap: _openSearchPanel,
                ),
              ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  if (widget.stateFilters.isNotEmpty)
                    _StateFilterBar(
                      filters: widget.stateFilters,
                      selected: _state,
                      countFor: (s) =>
                          s.isEmpty ? _allCount : (_counts[s] ?? 0),
                      onSelect: _selectState,
                    ),
                  if (_q.activeCount > 0)
                    ActiveQueryBar(
                      spec: _spec,
                      query: _q,
                      onChanged: _applyQuery,
                    ),
                  if (!_loading && _error == null)
                    _grouped
                        ? _ResultCountBar(
                            count: _total,
                            total: _total,
                            unit: widget.unitLabel,
                            suffix: ' · ${_groups.length} nhóm',
                          )
                        : _PagerBar(
                            from: _total == 0 ? 0 : _page * widget.pageSize + 1,
                            to: _page * widget.pageSize + _items.length,
                            total: _total,
                            unit: widget.unitLabel,
                            page: _page,
                            pageCount: _pageCount,
                            busy: _pageLoading,
                            onPrev: () => _goToPage(_page - 1),
                            onNext: () => _goToPage(_page + 1),
                            onPick: _pickPage,
                          ),
                  if (_pageLoading)
                    LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.primary,
                    )
                  else
                    // Viền phân cách header ↔ list, chỉ hiện khi list đã cuộn
                    // (không thì thẻ trượt sát header trông như bị cắt).
                    Container(
                      height: 2,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 1,
                        color: _scrolled
                            ? AppColors.border
                            : Colors.transparent,
                      ),
                    ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
                          final scrolled = n.metrics.pixels > 0;
                          if (scrolled != _scrolled) {
                            setState(() => _scrolled = scrolled);
                          }
                        }
                        return false;
                      },
                      child: _buildBody(),
                    ),
                  ),
                ],
              ),
              // Gợi ý tìm kiếm nổi trên list (như dropdown ô search Odoo).
              if (_suggestFields.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 12,
                  right: 12,
                  child: SearchSuggestions(
                    text: _typed.trim(),
                    fields: _suggestFields,
                    onPick: _pickField,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ───── Chế độ "Nhóm theo": nhóm thu gọn, mở ra mới tải bản ghi ─────

  Future<void> _loadGroup(String key) async {
    final slot = _slots[key]!;
    setState(() {
      slot.loading = true;
      slot.error = null;
    });
    try {
      final r = await widget.fetch(
        query: _query.isEmpty ? null : _query,
        offset: slot.items.length,
        limit: widget.pageSize,
        params: {..._q.toParams(), 'group_key': key},
      );
      if (!mounted || _slots[key] != slot) return; // đã reload giữa chừng
      setState(() {
        slot.items.addAll(r.items);
        slot.total = r.total;
        slot.loading = false;
      });
    } catch (e) {
      if (!mounted || _slots[key] != slot) return;
      setState(() {
        slot.error = e.toString().replaceFirst('Exception: ', '');
        slot.loading = false;
      });
    }
  }

  void _toggleGroup(PagedGroup g) {
    final slot = _slots[g.key];
    if (slot == null) {
      _slots[g.key] = _GroupSlot<T>(g.count);
      _loadGroup(g.key);
      return;
    }
    setState(() => slot.open = !slot.open);
  }

  /// Nhóm được làm PHẲNG thành 1 ListView.builder (header · bản ghi · nút
  /// xem thêm) để chỉ dựng phần đang hiện trên màn — mở nhóm lớn không lag.
  Widget _buildGroups() {
    final rows = <_GroupRow<T>>[];
    for (final g in _groups) {
      final slot = _slots[g.key];
      final open = slot?.open ?? false;
      rows.add(_GroupRow.header(g, slot));
      if (open && slot != null) {
        for (final it in slot.items) {
          rows.add(_GroupRow.item(g, it));
        }
        rows.add(_GroupRow.footer(g, slot));
      }
    }
    return ListView.builder(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final r = rows[i];
        final g = r.group;
        switch (r.kind) {
          case _RowKind.header:
            final label = g.label.isNotEmpty
                ? g.label
                : (g.key.isEmpty ? 'Không xác định' : g.key);
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: _GroupHeader(
                label: label,
                count: g.count,
                open: r.slot?.open ?? false,
                onTap: () => _toggleGroup(g),
              ),
            );
          case _RowKind.item:
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
              child: widget.itemBuilder(context, r.item as T),
            );
          case _RowKind.footer:
            return _GroupFooter(
              slot: r.slot!,
              onLoadMore: () => _loadGroup(g.key),
            );
        }
      },
    );
  }

  Widget _buildBody() {
    if (_loading) return const SkeletonList();
    if (_error != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadFirst,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorState(message: _error!, onRetry: _loadFirst),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadFirst,
      child: (_grouped ? _groups.isEmpty : _items.isEmpty)
          ? ListView(
              children: [
                const SizedBox(height: 100),
                EmptyState(
                  icon:
                      (_query.isEmpty && _state.isEmpty && _q.activeCount == 0)
                      ? widget.emptyIcon
                      : Icons.search_off_rounded,
                  title:
                      (_query.isEmpty && _state.isEmpty && _q.activeCount == 0)
                      ? widget.emptyTitle
                      : 'Không có kết quả',
                  message:
                      (_query.isEmpty && _state.isEmpty && _q.activeCount == 0)
                      ? widget.emptyMessage
                      : 'Thử đổi từ khoá hoặc bộ lọc.',
                ),
              ],
            )
          : _grouped
          ? _buildGroups()
          // ListView.builder chỉ dựng card đang hiện (lazy) → 80 card/trang
          // vẫn mượt; đổi trang thì làm mờ list cũ tới khi trang mới về.
          : AnimatedOpacity(
              opacity: _pageLoading ? 0.45 : 1,
              duration: const Duration(milliseconds: 150),
              child: ListView.separated(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    widget.itemBuilder(context, _items[i]),
              ),
            ),
    );
  }
}

/// Ô tìm kiếm.
class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final double rightPad;
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
    this.rightPad = 12,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, widget.rightPad, 4),
      child: TextField(
        controller: widget.controller,
        onChanged: (v) {
          setState(() {}); // cập nhật nút xoá
          widget.onChanged(v);
        },
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Thanh chip lọc trạng thái (cuộn ngang) + số lượng từ server.
class _StateFilterBar extends StatelessWidget {
  final List<MapEntry<String, String>> filters;
  final String selected;
  final int Function(String) countFor;
  final ValueChanged<String> onSelect;
  const _StateFilterBar({
    required this.filters,
    required this.selected,
    required this.countFor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppType.minTapTarget + 6,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSel = f.key == selected;
          final count = countFor(f.key);
          // Chip chưa chọn: viền hơi đậm hơn token border để ranh giới còn
          // nhìn rõ trên nền tối (border mặc định gần như tàng hình ở dark).
          final unselectedBorder = Color.alphaBlend(
            AppColors.inkMuted.withValues(alpha: 0.35),
            AppColors.border,
          );
          return Semantics(
            button: true,
            selected: isSel,
            label: '${f.value}, $count mục',
            child: GestureDetector(
              onTap: () => onSelect(f.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSel ? AppColors.primary : unselectedBorder,
                  ),
                ),
                child: Text(
                  '${f.value} ($count)',
                  style: TextStyle(
                    fontSize: AppType.body,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                    color: isSel ? Colors.white : AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dòng đếm kết quả.
class _ResultCountBar extends StatelessWidget {
  final int count;
  final int total;
  final String unit;
  final String suffix;
  const _ResultCountBar({
    required this.count,
    required this.total,
    required this.unit,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          count >= total
              ? '$total $unit$suffix'
              : 'Đang xem $count / $total $unit$suffix',
          style: TextStyle(
            fontSize: AppType.caption,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Trạng thái 1 nhóm đã mở (bản ghi tải dần).
class _GroupSlot<T> {
  final List<T> items = [];
  int total;
  bool open = true;
  bool loading = false;
  String? error;
  _GroupSlot(this.total);
}

enum _RowKind { header, item, footer }

/// 1 dòng trong list nhóm đã làm phẳng.
class _GroupRow<T> {
  final _RowKind kind;
  final PagedGroup group;
  final _GroupSlot<T>? slot;
  final T? item;
  _GroupRow.header(this.group, this.slot) : kind = _RowKind.header, item = null;
  _GroupRow.item(this.group, T this.item) : kind = _RowKind.item, slot = null;
  _GroupRow.footer(this.group, _GroupSlot<T> this.slot)
    : kind = _RowKind.footer,
      item = null;
}

/// Header nhóm: chevron · nhãn · số lượng — bấm để mở/thu.
class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool open;
  final VoidCallback onTap;
  const _GroupHeader({
    required this.label,
    required this.count,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: open,
      label: '$label, $count mục',
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: open
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: open ? AppColors.primary : AppColors.inkMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppType.bodyLg,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: open ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _vnNum(count),
                    style: TextStyle(
                      fontSize: AppType.caption,
                      fontWeight: FontWeight.w700,
                      color: open ? Colors.white : AppColors.inkSoft,
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
}

/// Cuối nhóm đang mở: loading / lỗi + thử lại / "Xem thêm (còn n)".
class _GroupFooter<T> extends StatelessWidget {
  final _GroupSlot<T> slot;
  final VoidCallback onLoadMore;
  const _GroupFooter({required this.slot, required this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    final s = slot;
    if (s.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (s.error != null) {
      return TextButton.icon(
        onPressed: onLoadMore,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text('Lỗi tải: ${s.error} — Thử lại'),
      );
    }
    if (s.items.length < s.total) {
      return TextButton(
        onPressed: onLoadMore,
        child: Text(
          'Xem thêm (còn ${_vnNum(s.total - s.items.length)})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }
    return const SizedBox(height: 4);
  }
}

/// Số kiểu VN: 2947 → "2.947".
String _vnNum(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

/// Thanh phân trang kiểu Odoo: "1–80 / 2.947 phiếu" + ‹ [1/37] ›.
/// Bấm số trang → chọn trang bất kỳ.
class _PagerBar extends StatelessWidget {
  final int from;
  final int to;
  final int total;
  final String unit;
  final int page;
  final int pageCount;
  final bool busy;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;
  const _PagerBar({
    required this.from,
    required this.to,
    required this.total,
    required this.unit,
    required this.page,
    required this.pageCount,
    required this.busy,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
      fontSize: AppType.caption,
      fontWeight: FontWeight.w600,
      color: AppColors.inkMuted,
    );
    final canPrev = page > 0 && !busy;
    final canNext = page < pageCount - 1 && !busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total == 0
                  ? '0 $unit'
                  : '${_vnNum(from)}–${_vnNum(to)} / ${_vnNum(total)} $unit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ),
          if (pageCount > 1) ...[
            IconButton(
              tooltip: 'Trang trước',
              visualDensity: VisualDensity.compact,
              onPressed: canPrev ? onPrev : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Semantics(
              button: true,
              label: 'Trang ${page + 1} trên $pageCount, chọn trang',
              child: InkWell(
                onTap: busy ? null : onPick,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${page + 1} / $pageCount',
                    style: TextStyle(
                      fontSize: AppType.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Trang sau',
              visualDensity: VisualDensity.compact,
              onPressed: canNext ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chọn trang: lưới số trang (dựng lười — nghìn trang vẫn nhẹ), trang hiện
/// tại tô màu; mỗi ô ghi khoảng bản ghi.
class _PagePickerSheet extends StatelessWidget {
  final int pageCount;
  final int current;
  final int pageSize;
  final int total;
  const _PagePickerSheet({
    required this.pageCount,
    required this.current,
    required this.pageSize,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn trang ($pageSize bản ghi/trang)',
                    style: TextStyle(
                      fontFamily: kBrandFont,
                      fontSize: AppType.subtitle,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisExtent: 56,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: pageCount,
              itemBuilder: (context, i) {
                final sel = i == current;
                final from = i * pageSize + 1;
                final to = ((i + 1) * pageSize).clamp(0, total);
                return Material(
                  color: sel ? AppColors.primary : AppColors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => Navigator.pop(context, i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: AppType.bodyLg,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : AppColors.ink,
                          ),
                        ),
                        Text(
                          '${_vnNum(from)}–${_vnNum(to)}',
                          style: TextStyle(
                            fontSize: AppType.micro,
                            color: sel ? Colors.white70 : AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

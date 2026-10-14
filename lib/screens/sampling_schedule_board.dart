import 'dart:async';

import 'package:flutter/material.dart';
import '../config.dart';
import '../models/paged.dart';
import '../models/sampling.dart';
import '../services/permission_controller.dart';
import '../services/sampling_service.dart';
import '../theme/app_theme.dart';
import '../widgets/states.dart';
import '../widgets/status_chip.dart';
import 'sampling_program_screens.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// MÀN "KẾ HOẠCH CẦN LÊN LỊCH" — bố cục riêng theo thiết kế được duyệt:
/// header (tiêu đề) → ô tìm kiếm → danh sách thẻ kế hoạch → dòng kết
/// thúc danh sách.
///
/// Search + paging chạy SERVER-SIDE qua `/api/sampling/programs`
/// (params `q`, `scope`, `offset`, `limit`).
/// ───────────────────────────────────────────────────────────────────────────
class SamplingScheduleBoardScreen extends StatefulWidget {
  final String sessionId;
  final String title;

  /// Phạm vi backend (`need_schedule` / `my`).
  final String scope;

  const SamplingScheduleBoardScreen({
    super.key,
    required this.sessionId,
    this.title = 'Kế hoạch cần lên lịch',
    this.scope = 'need_schedule',
  });

  @override
  State<SamplingScheduleBoardScreen> createState() =>
      _SamplingScheduleBoardScreenState();
}

const int _kPageSize = 30;

class _SamplingScheduleBoardScreenState
    extends State<SamplingScheduleBoardScreen> {
  late final SamplingService _service = SamplingService(
    baseUrl: AppConfig.odooUrl,
    sessionId: widget.sessionId,
  );

  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<SamplingProgram> _items = [];
  int _total = 0;
  String _query = '';

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<PagedResult<SamplingProgram>> _fetch(int offset) =>
      _service.getPrograms(
        query: _query.isEmpty ? null : _query,
        scope: widget.scope,
        offset: offset,
        limit: _kPageSize,
      );

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _fetch(0);
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

  void _onScroll() {
    if (_loadingMore || !_hasMore || _loading) return;
    if (_scrollCtrl.position.pixels >
        _scrollCtrl.position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final r = await _fetch(_items.length);
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
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gated =
        permissions.loaded && !permissions.canRead('etech.sampling.program');
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: _BoardHeader(title: widget.title),
      ),
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
                _SearchBox(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                ),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildList() {
    if (_loading) return const SkeletonList();
    if (_error != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorState(message: _error!, onRetry: _load),
        ),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 90),
            EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Không có kế hoạch',
              message: 'Không còn kế hoạch nào khớp bộ lọc hiện tại.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
        itemCount: _items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == _items.length) {
            return _hasMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                  )
                : const _EndOfList();
          }
          final p = _items[i];
          return _ProgramBoardCard(
            program: p,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SamplingProgramDetailScreen(
                  sessionId: widget.sessionId,
                  programId: p.id,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────

class _BoardHeader extends StatelessWidget {
  final String title;
  const _BoardHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppType.headline,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SEARCH ──────────────────────────────────────────────────────────────────

class _SearchBox extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.controller, required this.onChanged});

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: TextField(
        controller: widget.controller,
        onChanged: (v) {
          setState(() {}); // hiện/ẩn nút xoá
          widget.onChanged(v);
        },
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: AppType.bodyLg, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: 'Tìm mã, khách hàng, mẫu…',
          hintStyle: TextStyle(color: AppColors.inkMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.inkMuted,
          ),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.inkMuted,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

// ─── THẺ KẾ HOẠCH ────────────────────────────────────────────────────────────

class _ProgramBoardCard extends StatelessWidget {
  final SamplingProgram program;
  final VoidCallback onTap;
  const _ProgramBoardCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = program;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.surface,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.event_note_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.code.isEmpty ? '(Chưa có mã)' : p.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppType.subtitle,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip.fromState(state: p.state, label: p.stateLabel),
                ],
              ),
              const SizedBox(height: 8),
              // Không cần nhãn: icon đã đủ nghĩa (khách hàng / mẫu / địa
              // điểm / thời gian); trạng thái đã có chip ở header.
              _CardRow(
                icon: Icons.business_outlined,
                value: p.partnerName,
                highlight: true,
              ),
              _CardRow(icon: Icons.science_outlined, value: p.sampleName),
              _CardRow(icon: Icons.place_outlined, value: p.samplingLocation),
              _CardRow(icon: Icons.schedule_outlined, value: p.scheduled),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một dòng thông tin trong thẻ: icon nhỏ + giá trị. Không nhãn chữ (icon đã
/// đủ nghĩa) và không kẻ ngăn — thẻ gọn, đọc nhanh khi lướt danh sách.
class _CardRow extends StatelessWidget {
  final IconData icon;
  final String value;

  /// Giá trị dùng màu nhấn (tên khách hàng — giống link trong Odoo).
  final bool highlight;

  const _CardRow({
    required this.icon,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: AppColors.inkMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppType.body,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                color: highlight ? AppColors.teal : AppColors.inkSoft,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng kết thúc danh sách (thay cho việc cuộn vào khoảng trắng).
class _EndOfList extends StatelessWidget {
  const _EndOfList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 46,
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'Bạn đã xem hết kế hoạch',
            style: TextStyle(
              fontSize: AppType.bodyLg,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Không còn kế hoạch nào khác',
            style: TextStyle(fontSize: AppType.body, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

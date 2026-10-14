import '../widgets/module_list_scaffold.dart';
import '../services/search_spec_service.dart';
import '../widgets/record_card.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/lab_sample.dart';
import '../services/lab_sample_service.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_kit.dart';
import '../widgets/odoo_web_clone.dart';
import '../widgets/paged_list.dart';
import '../widgets/states.dart';

// ───────── Bộ lọc trạng thái (value,label) cho từng màn list ─────────

const List<MapEntry<String, String>> _handoverStateFilters = [
  MapEntry('', 'Tất cả'),
  MapEntry('draft', 'Nháp'),
  MapEntry('handed', 'Đã bàn giao'),
  MapEntry('received', 'Đã nhận'),
  MapEntry('returned', 'Đã trả'),
  MapEntry('cancel', 'Đã hủy'),
];

const List<MapEntry<String, String>> _preprocessStateFilters = [
  MapEntry('', 'Tất cả'),
  MapEntry('draft', 'Nháp'),
  MapEntry('sent', 'Đã gửi'),
  MapEntry('received', 'Đã nhận'),
  MapEntry('done', 'Hoàn thành'),
  MapEntry('cancel', 'Đã hủy'),
];

// ───────── Tiện ích hiển thị chung (read-only) ─────────

// State của Phiếu bàn giao mẫu: [draft,handed,received,returned,cancel].
Color _handoverStateColor(String state) {
  switch (state) {
    case 'received':
      return AppColors.success;
    case 'handed':
      return AppColors.primary;
    case 'returned':
      return AppColors.warning;
    case 'cancel':
      return AppColors.danger;
    default:
      return AppColors.inkMuted;
  }
}

// State của Phiếu sơ chế / phân tích: [draft,sent,received,done,cancel].
Color _requestStateColor(String state) {
  switch (state) {
    case 'done':
      return AppColors.success;
    case 'received':
      return AppColors.primary;
    case 'sent':
      return AppColors.warning;
    case 'cancel':
      return AppColors.danger;
    default:
      return AppColors.inkMuted;
  }
}

/// ═════════════════════ Phiếu bàn giao mẫu ═════════════════════

class HandoverListScreen extends StatelessWidget {
  final String sessionId;
  const HandoverListScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final service = LabSampleService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Phiếu bàn giao mẫu')),
      body: PagedListView<HandoverBrief>(
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getHandovers(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        stateFilters: _handoverStateFilters,
        searchHint: 'Tìm mã phiếu, khách hàng, tên mẫu…',
        unitLabel: 'phiếu',
        emptyIcon: Icons.move_to_inbox_outlined,
        emptyTitle: 'Chưa có phiếu bàn giao',
        emptyMessage: 'Phiếu bàn giao mẫu sẽ hiển thị tại đây.',
        itemBuilder: (context, item) => ListCard(
          title: item.code,
          stateLabel: item.stateLabel,
          stateColor: _handoverStateColor(item.state),
          meta: [
            if (item.partnerName.isNotEmpty)
              ListMeta(Icons.business_outlined, item.partnerName),
            if (item.sampleName.isNotEmpty)
              ListMeta(Icons.label_outline, item.sampleName),
            if (item.sampleType.isNotEmpty)
              ListMeta(Icons.science_outlined, item.sampleType),
            if (item.requestCode.isNotEmpty)
              ListMeta(Icons.description_outlined, item.requestCode),
          ],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HandoverDetailScreen(
                sessionId: sessionId,
                handoverId: item.id,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HandoverDetailScreen extends StatefulWidget {
  final String sessionId;
  final int handoverId;
  const HandoverDetailScreen({
    super.key,
    required this.sessionId,
    required this.handoverId,
  });

  @override
  State<HandoverDetailScreen> createState() => _HandoverDetailScreenState();
}

class _HandoverDetailScreenState extends State<HandoverDetailScreen> {
  late final LabSampleService _service;
  late Future<HandoverDetail> _future;

  @override
  void initState() {
    super.initState();
    _service = LabSampleService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    _future = _service.getHandover(widget.handoverId);
  }

  void _reload() =>
      setState(() => _future = _service.getHandover(widget.handoverId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Chi tiết bàn giao')),
      body: FutureBuilder<HandoverDetail>(
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
          final r = snap.data!;
          return DetailBody(
            header: DetailHeader(
              code: r.code,
              subtitle: r.partnerName,
              stateLabel: r.stateLabel,
              stateColor: _handoverStateColor(r.state),
            ),
            children: [
              InfoSection(
                number: 1,
                title: 'Thông tin chung',
                icon: Icons.info_outline_rounded,
                children: [
                  InfoRow('Bên gửi mẫu', r.partnerName),
                  InfoRow('Loại mẫu', r.sampleType),
                  InfoRow('Tên mẫu', r.sampleName),
                  InfoRow('Biên bản', r.reportCode),
                  InfoRow('Chương trình', r.programCode),
                  InfoRow('Phiếu yêu cầu', r.requestCode),
                ],
              ),
              _PreprocessRefSection(refs: r.preprocessRequests),
            ],
          );
        },
      ),
    );
  }
}

class _PreprocessRefSection extends StatelessWidget {
  final List<HandoverPreprocessRef> refs;
  const _PreprocessRefSection({required this.refs});

  @override
  Widget build(BuildContext context) {
    if (refs.isEmpty) return const SizedBox.shrink();
    return LineTable(
      number: 2,
      title: 'Phiếu yêu cầu sơ chế',
      icon: Icons.assignment_outlined,
      columns: const [LineCol('Mã phiếu', width: 220)],
      rows: [
        for (final ref in refs) [ref.name],
      ],
    );
  }
}

/// ═════════════════════ Phiếu yêu cầu sơ chế ═════════════════════

class PreprocessRequestListScreen extends StatelessWidget {
  final String sessionId;
  const PreprocessRequestListScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final service = LabSampleService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Phiếu yêu cầu sơ chế')),
      body: PagedListView<PreprocessRequestBrief>(
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getPreprocessRequests(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        stateFilters: _preprocessStateFilters,
        searchHint: 'Tìm mã phiếu, khách hàng, tên mẫu…',
        unitLabel: 'phiếu',
        emptyIcon: Icons.science_outlined,
        emptyTitle: 'Chưa có phiếu sơ chế',
        emptyMessage: 'Phiếu yêu cầu sơ chế sẽ hiển thị tại đây.',
        itemBuilder: (context, item) => ListCard(
          title: item.name,
          stateLabel: item.stateLabel,
          stateColor: _requestStateColor(item.state),
          meta: [
            if (item.partnerName.isNotEmpty)
              ListMeta(Icons.business_outlined, item.partnerName),
            if (item.sampleName.isNotEmpty)
              ListMeta(Icons.label_outline, item.sampleName),
            if (item.sampleType.isNotEmpty)
              ListMeta(Icons.science_outlined, item.sampleType),
            if (item.receivedAt.isNotEmpty)
              ListMeta(Icons.event_outlined, 'Tiếp nhận: ${item.receivedAt}'),
          ],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PreprocessRequestDetailScreen(
                sessionId: sessionId,
                requestId: item.id,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PreprocessRequestDetailScreen extends StatefulWidget {
  final String sessionId;
  final int requestId;
  const PreprocessRequestDetailScreen({
    super.key,
    required this.sessionId,
    required this.requestId,
  });

  @override
  State<PreprocessRequestDetailScreen> createState() =>
      _PreprocessRequestDetailScreenState();
}

class _PreprocessRequestDetailScreenState
    extends State<PreprocessRequestDetailScreen> {
  late final LabSampleService _service;
  late Future<PreprocessRequestDetail> _future;

  @override
  void initState() {
    super.initState();
    _service = LabSampleService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    _future = _service.getPreprocessRequest(widget.requestId);
  }

  void _reload() =>
      setState(() => _future = _service.getPreprocessRequest(widget.requestId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Chi tiết phiếu sơ chế')),
      body: FutureBuilder<PreprocessRequestDetail>(
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
          final r = snap.data!;
          return DetailBody(
            header: DetailHeader(
              code: r.name,
              subtitle: r.partnerName,
              stateLabel: r.stateLabel,
              stateColor: _requestStateColor(r.state),
            ),
            children: [
              InfoSection(
                number: 1,
                title: 'Thông tin chung',
                icon: Icons.info_outline_rounded,
                children: [
                  InfoRow('Bên gửi mẫu', r.sender),
                  InfoRow('Bên nhận mẫu', r.receiver),
                  InfoRow('Phiếu bàn giao mẫu', r.handoverName),
                  InfoRow('Loại mẫu', r.sampleType),
                  InfoRow('Tên mẫu', r.sampleName),
                  InfoRow('Khối lượng mẫu', r.quantity),
                  InfoRow('Thời gian tiếp nhận mẫu', r.receivedAt),
                  InfoRow('Người tiếp nhận', r.receiverUidName),
                  InfoChips('Người sơ chế', r.preprocessors),
                  InfoRow('Thời gian hoàn thành sơ chế', r.preprocessDoneAt),
                  InfoRow('Thời gian trả kết quả dự kiến', r.resultDueAt),
                  InfoRow('Phiếu yêu cầu', r.requestCode),
                ],
              ),
              _PreprocessLinesSection(lines: r.lines),
            ],
          );
        },
      ),
    );
  }
}

class _PreprocessLinesSection extends StatelessWidget {
  final List<PreprocessRequestLine> lines;
  const _PreprocessLinesSection({required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return LineTable(
      number: 2,
      title: 'Thông tin mẫu',
      icon: Icons.label_outline,
      columns: const [
        LineCol('Mã hóa', width: 90),
        LineCol('Chỉ tiêu', width: 150),
        LineCol('Sơ chế', width: 120),
        LineCol('KL tối thiểu', width: 80, numeric: true),
        LineCol('Số lượng', width: 70, numeric: true),
      ],
      rows: [
        for (final l in lines)
          [
            l.codedSample.isEmpty ? '(Chưa mã hóa)' : l.codedSample,
            l.testParameter,
            l.preprocessPart,
            l.testMinWeight,
            l.testSampleCount,
          ],
      ],
    );
  }
}

/// ═════════════════════ Phiếu yêu cầu phân tích ═════════════════════

/// List "Phiếu yêu cầu phân tích" dạng card. Search + Bộ lọc/Nhóm theo (search view Odoo) +
/// phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class AnalysisRequestListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const AnalysisRequestListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final service = LabSampleService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<AnalysisRequestBrief>(
      title: 'Phiếu yêu cầu phân tích',
      permissionModel: 'etech.analysis.request',
      searchSpec: () =>
          SearchSpecService.load(sessionId, 'etech.analysis.request'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm mã phiếu, khách hàng, tên mẫu…',
      unitLabel: 'phiếu',
      emptyIcon: Icons.biotech_outlined,
      emptyTitle: 'Chưa có phiếu phân tích',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getAnalysisRequests(
            query: query,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, item) => RecordCard(
        title: item.name,
        state: item.state,
        stateLabel: item.stateLabel,
        subtitle: item.partnerName,
        tag: item.sampleType,
        note: item.sampleName,
        refs: [
          (
            Icons.move_to_inbox_outlined,
            item.receivedAt.isEmpty ? '' : 'Nhận ${item.receivedAt}',
          ),
          (
            Icons.task_alt_rounded,
            item.analysisDoneAt.isEmpty ? '' : 'Xong ${item.analysisDoneAt}',
          ),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisRequestDetailScreen(
              sessionId: sessionId,
              requestId: item.id,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [AnalysisRequestListScreen]).
// TODO: xoá khi chốt dùng bản card.
class AnalysisRequestTreeListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const AnalysisRequestTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<AnalysisRequestTreeListScreen> createState() =>
      _AnalysisRequestTreeListScreenState();
}

class _AnalysisRequestTreeListScreenState
    extends State<AnalysisRequestTreeListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = LabSampleService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Phiếu yêu cầu phân tích',
      primaryButtonLabel: 'Mới',
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooTreeListView<AnalysisRequestBrief>(
        showSearch: _search,
        searchHint: 'Tìm mã phiếu, khách hàng, tên mẫu…',
        emptyIcon: Icons.biotech_outlined,
        emptyTitle: 'Chưa có phiếu phân tích',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getAnalysisRequests(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        onTapRow: (context, item) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisRequestDetailScreen(
              sessionId: widget.sessionId,
              requestId: item.id,
            ),
          ),
        ),
        columns: [
          OdooTreeColumn(
            label: 'Mã phiếu',
            width: 150,
            link: true,
            linkColor: kOdooBlue,
            value: (item) => item.name,
          ),
          OdooTreeColumn(
            label: 'Khách hàng',
            width: 160,
            link: true,
            value: (item) => item.partnerName,
          ),
          OdooTreeColumn(
            label: 'Tên mẫu',
            width: 150,
            value: (item) => item.sampleName,
          ),
          OdooTreeColumn(
            label: 'Loại mẫu',
            width: 140,
            value: (item) => item.sampleType,
          ),
          OdooTreeColumn(
            label: 'Tiếp nhận',
            width: 110,
            value: (item) => item.receivedAt,
          ),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 120,
            value: (item) => item.stateLabel,
          ),
        ],
      ),
    );
  }
}

class AnalysisRequestDetailScreen extends StatefulWidget {
  final String sessionId;
  final int requestId;
  const AnalysisRequestDetailScreen({
    super.key,
    required this.sessionId,
    required this.requestId,
  });

  @override
  State<AnalysisRequestDetailScreen> createState() =>
      _AnalysisRequestDetailScreenState();
}

class _AnalysisRequestDetailScreenState
    extends State<AnalysisRequestDetailScreen> {
  late final LabSampleService _service;
  late Future<AnalysisRequestDetail> _future;

  @override
  void initState() {
    super.initState();
    _service = LabSampleService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    _future = _service.getAnalysisRequest(widget.requestId);
  }

  void _reload() =>
      setState(() => _future = _service.getAnalysisRequest(widget.requestId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Chi tiết phiếu phân tích')),
      body: FutureBuilder<AnalysisRequestDetail>(
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
          final r = snap.data!;
          return DetailBody(
            header: DetailHeader(
              code: r.name,
              subtitle: r.partnerName,
              stateLabel: r.stateLabel,
              stateColor: _requestStateColor(r.state),
            ),
            children: [
              InfoSection(
                number: 1,
                title: 'Thông tin chung',
                icon: Icons.info_outline_rounded,
                children: [
                  InfoRow('Bên gửi mẫu', r.partnerName),
                  InfoRow('Phiếu yêu cầu sơ chế', r.preprocessRequestName),
                  InfoRow('Loại mẫu', r.sampleType),
                  InfoRow('Tên mẫu', r.sampleName),
                  InfoRow(
                    'Điều kiện bảo quản mẫu',
                    r.samplePreservation,
                    radio: true,
                  ),
                  InfoRow('Thời gian lưu', r.retentionDuration),
                  InfoRow('Thời gian tiếp nhận mẫu', r.receivedAt),
                  InfoRow('Thời gian trả kết quả dự kiến', r.resultDueAt),
                  InfoRow('Thời gian hoàn thành phân tích', r.analysisDoneAt),
                  InfoRow('Phiếu yêu cầu', r.requestCode),
                ],
              ),
              _AnalysisLinesSection(lines: r.lines),
            ],
          );
        },
      ),
    );
  }
}

class _AnalysisLinesSection extends StatelessWidget {
  final List<AnalysisRequestLine> lines;
  const _AnalysisLinesSection({required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    String num(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    return LineTable(
      number: 2,
      title: 'Thông tin mẫu',
      icon: Icons.label_outline,
      columns: const [
        LineCol('Mã hóa', width: 90),
        LineCol('Chỉ tiêu', width: 150),
        LineCol('KL thử nghiệm', width: 80, numeric: true),
        LineCol('Số lượng TN', width: 70, numeric: true),
        LineCol('KL mẫu lưu', width: 80, numeric: true),
      ],
      rows: [
        for (final l in lines)
          [
            l.codedSample.isEmpty ? '(Chưa mã hóa)' : l.codedSample,
            l.testParameter,
            l.testSampleWeight > 0 ? '${num(l.testSampleWeight)} g' : '',
            l.testSampleCount > 0 ? '${l.testSampleCount}' : '',
            l.retainSampleWeight > 0 ? '${num(l.retainSampleWeight)} g' : '',
          ],
      ],
    );
  }
}

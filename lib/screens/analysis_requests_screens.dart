import '../services/search_spec_service.dart';
import '../widgets/record_card.dart';
import 'package:flutter/material.dart';
import '../utils/vn_format.dart';
import '../config.dart';
import '../models/analysis_requests.dart';
import '../services/analysis_requests_service.dart';
import '../services/permission_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_kit.dart';
import '../widgets/module_list_scaffold.dart';
import '../widgets/odoo_web_clone.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// Module "Yêu cầu phân tích" (etech.analysis.request).
///
/// - List: StatelessWidget, dựng [AnalysisRequestsService] inline + [ModuleListScaffold].
/// - Detail: dùng [ModuleDetailScaffold] (tự lo loading/error/retry).
/// - Gating quyền: menu gate qua permissions.canSeeMenu ở router; dữ liệu gate
///   qua `permissionModel: 'etech.analysis.request'`.
/// - Tên class có tiền tố `Ar` để không trùng AnalysisRequestListScreen cũ.
/// ───────────────────────────────────────────────────────────────────────────

/// List "Yêu cầu phân tích" dạng card. Search + Bộ lọc/Nhóm theo (search view Odoo) +
/// phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class ArListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const ArListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final service = AnalysisRequestsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<ArBrief>(
      title: 'Yêu cầu phân tích',
      permissionModel: 'etech.analysis.request',
      searchSpec: () =>
          SearchSpecService.load(sessionId, 'etech.analysis.request'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm theo mã / khách hàng / mẫu…',
      unitLabel: 'yêu cầu',
      emptyIcon: Icons.science_outlined,
      emptyTitle: 'Chưa có yêu cầu phân tích',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getAnalysisRequests(
            query: query,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, ar) => RecordCard(
        title: ar.name,
        state: ar.state,
        stateLabel: ar.stateLabel,
        subtitle: ar.partnerName,
        tag: ar.sampleType,
        note: ar.sampleName,
        refs: [
          (
            Icons.move_to_inbox_outlined,
            ar.receivedAt.isEmpty ? '' : 'Nhận ${ar.receivedAt}',
          ),
          (
            Icons.task_alt_rounded,
            ar.analysisDoneAt.isEmpty ? '' : 'Xong ${ar.analysisDoneAt}',
          ),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ArDetailPage(sessionId: sessionId, requestId: ar.id),
          ),
        ),
      ),
    );
  }
}

/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [ArListScreen]).
// TODO: xoá khi chốt dùng bản card.
class ArTreeListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const ArTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<ArTreeListScreen> createState() => _ArTreeListScreenState();
}

class _ArTreeListScreenState extends State<ArTreeListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = AnalysisRequestsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Yêu cầu phân tích',
      permissionModel: 'etech.analysis.request',
      primaryButtonLabel: 'Mới',
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooTreeListView<ArBrief>(
        showSearch: _search,
        searchHint: 'Tìm theo mã / khách hàng / mẫu…',
        emptyIcon: Icons.science_outlined,
        emptyTitle: 'Chưa có yêu cầu phân tích',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getAnalysisRequests(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        onTapRow: (context, ar) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ArDetailPage(sessionId: widget.sessionId, requestId: ar.id),
          ),
        ),
        columns: [
          OdooTreeColumn(
            label: 'Mã yêu cầu',
            width: 150,
            link: true,
            linkColor: kOdooBlue,
            value: (ar) => ar.name,
          ),
          OdooTreeColumn(
            label: 'Khách hàng',
            width: 160,
            link: true,
            value: (ar) => ar.partnerName,
          ),
          OdooTreeColumn(
            label: 'Loại mẫu',
            width: 140,
            value: (ar) => ar.sampleType,
          ),
          OdooTreeColumn(
            label: 'Mẫu',
            width: 150,
            value: (ar) => ar.sampleName,
          ),
          OdooTreeColumn(
            label: 'Ngày nhận',
            width: 110,
            value: (ar) => ar.receivedAt,
          ),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 130,
            value: (ar) => ar.stateLabel,
          ),
        ],
      ),
    );
  }
}

/// Chi tiết yêu cầu phân tích — dùng [ModuleDetailScaffold].
class ArDetailPage extends StatelessWidget {
  final String sessionId;
  final int requestId;
  const ArDetailPage({
    super.key,
    required this.sessionId,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    final service = AnalysisRequestsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleDetailScaffold<ArDetail>(
      title: 'Yêu cầu phân tích',
      load: () => service.getAnalysisRequest(requestId),
      builder: (context, ar, reload) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  OdooFormHeader(
                    stateLabel: ar.stateLabel,
                    title: 'PHIẾU YÊU CẦU PHÂN TÍCH',
                    subtitle: [
                      HeaderSub(
                        'Phiếu yêu cầu thử nghiệm',
                        ar.requestCode,
                        link: true,
                      ),
                    ],
                    createdBy: ar.createdBy,
                    createdAt: metaDt(ar.createdAt),
                    updatedBy: ar.updatedBy,
                    updatedAt: metaDt(ar.updatedAt),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                    child: Column(children: _detailSections(ar)),
                  ),
                ],
              ),
            ),
            _ArActionBar(service: service, ar: ar, reload: reload),
          ],
        );
      },
    );
  }

  List<Widget> _detailSections(ArDetail ar) {
    return [
      InfoSection(
        number: 1,
        title: 'Thông tin chung',
        children: [
          InfoRow('Bên gửi mẫu', ar.sender),
          InfoRow('Bên nhận mẫu', ar.receiver),
          InfoRow('Phiếu yêu cầu sơ chế', ar.preprocessRequestName),
          InfoRow('Loại mẫu', ar.sampleType),
          InfoRow('Tên mẫu', ar.sampleName),
          InfoRow('Điều kiện bảo quản mẫu', ar.samplePreservation, radio: true),
          InfoRow('Thời gian tiếp nhận mẫu', ar.receivedAt),
          InfoRow('Thời gian trả kết quả dự kiến', ar.resultDueAt),
          InfoRow('Thời gian lưu mẫu sau thử nghiệm', ar.retentionDuration),
          InfoRow('Thời gian hoàn thành sơ chế', ar.preprocessDoneAt),
          InfoRow('Thời gian hoàn thành phân tích', ar.analysisDoneAt),
        ],
      ),
      _LinesSection(lines: ar.lines),
      InfoSection(
        title: 'Chữ ký',
        children: [
          InfoRow('ĐD. Bộ phận chuẩn bị mẫu', ar.senderSignerName),
          InfoRow('ĐD. Bộ phận thí nghiệm', ar.receiverSignerName),
        ],
      ),
    ];
  }
}

/// ───────── Thanh nút hành động (state-aware + permission-gated) ────────────

/// Mô tả 1 action: slug + nhãn + các state hợp lệ (rỗng = luôn hiện) + cờ
/// cần lý do + cờ destructive (để tô màu danger).
class _ArAction {
  final String slug;
  final String label;
  final Set<String> fromStates;
  final bool needsReason;
  final bool destructive;
  final Future<String> Function(
    AnalysisRequestsService s,
    int id,
    String? reason,
  )
  run;
  const _ArAction({
    required this.slug,
    required this.label,
    required this.fromStates,
    required this.run,
    this.needsReason = false,
    this.destructive = false,
  });

  bool visibleFor(String state) =>
      fromStates.isEmpty || fromStates.contains(state);
}

const _kArActions = <_ArAction>[
  _ArAction(
    slug: 'send',
    label: 'Gửi yêu cầu',
    fromStates: {'draft'},
    run: _runSend,
  ),
  _ArAction(
    slug: 'receive',
    label: 'Tiếp nhận mẫu',
    fromStates: {'sent'},
    run: _runReceive,
  ),
  _ArAction(
    slug: 'done',
    label: 'Hoàn thành phân tích',
    fromStates: {'received'},
    run: _runDone,
  ),
  _ArAction(
    slug: 'create_lab_batch',
    label: 'Tạo mẻ mẫu',
    fromStates: {'received', 'done'},
    run: _runCreateLabBatch,
  ),
  _ArAction(
    slug: 'create_test_report',
    label: 'Tạo phiếu kết quả',
    fromStates: {'done'},
    run: _runCreateTestReport,
  ),
  _ArAction(
    slug: 'cancel',
    label: 'Hủy phiếu',
    fromStates: {'draft', 'sent', 'received'},
    needsReason: true,
    destructive: true,
    run: _runCancel,
  ),
];

// Top-level adapters để giữ list const (closure không const được).
Future<String> _runSend(AnalysisRequestsService s, int id, String? _) =>
    s.send(id);
Future<String> _runReceive(AnalysisRequestsService s, int id, String? _) =>
    s.receive(id);
Future<String> _runDone(AnalysisRequestsService s, int id, String? _) =>
    s.done(id);
Future<String> _runCreateLabBatch(
  AnalysisRequestsService s,
  int id,
  String? _,
) => s.createLabBatch(id);
Future<String> _runCreateTestReport(
  AnalysisRequestsService s,
  int id,
  String? _,
) => s.createTestReport(id);
Future<String> _runCancel(AnalysisRequestsService s, int id, String? reason) =>
    s.cancel(id, reason ?? '');

class _ArActionBar extends StatefulWidget {
  final AnalysisRequestsService service;
  final ArDetail ar;
  final VoidCallback reload;
  const _ArActionBar({
    required this.service,
    required this.ar,
    required this.reload,
  });

  @override
  State<_ArActionBar> createState() => _ArActionBarState();
}

class _ArActionBarState extends State<_ArActionBar> {
  bool _busy = false;

  List<_ArAction> get _available {
    if (!permissions.canWrite('etech.analysis.request')) return const [];
    return _kArActions.where((a) => a.visibleFor(widget.ar.state)).toList();
  }

  Future<String?> _askReason() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Lý do hủy',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          style: TextStyle(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'Nhập lý do hủy phiếu…',
            hintStyle: TextStyle(color: AppColors.inkMuted),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Bỏ qua', style: TextStyle(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isEmpty) return; // lý do bắt buộc
              Navigator.of(ctx).pop(v);
            },
            child: Text('Xác nhận', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _run(_ArAction action) async {
    if (_busy) return;
    String? reason;
    if (action.needsReason) {
      reason = await _askReason();
      if (reason == null) return; // user huỷ dialog
    }
    if (!mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action.run(widget.service, widget.ar.id, reason);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${action.label}: thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.reload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_msg(e)), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  @override
  Widget build(BuildContext context) {
    final actions = _available;
    if (actions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final a in actions)
              _ArActionButton(action: a, busy: _busy, onPressed: () => _run(a)),
          ],
        ),
      ),
    );
  }
}

class _ArActionButton extends StatelessWidget {
  final _ArAction action;
  final bool busy;
  final VoidCallback onPressed;
  const _ArActionButton({
    required this.action,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final onTap = busy ? null : onPressed;
    final child = Text(
      action.label,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );

    if (action.destructive) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: child,
      );
    }
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: child,
    );
  }
}

/// ───────── Tiện ích hiển thị read-only dùng chung trong màn detail ─────────

class _LinesSection extends StatelessWidget {
  final List<ArLine> lines;
  const _LinesSection({required this.lines});

  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return LineTable(
      number: 2,
      title: 'Thông tin mẫu',
      icon: Icons.biotech_outlined,
      columns: const [
        LineCol('Mã hóa mẫu', width: 130),
        LineCol('Chỉ tiêu phân tích', width: 150),
        LineCol('Phương pháp phân tích', width: 180),
        LineCol('KL mẫu thử nghiệm (gram)', width: 96, numeric: true),
        LineCol('Số lượng mẫu thử nghiệm', width: 80, numeric: true),
        LineCol('KL mẫu lưu (gram)', width: 96, numeric: true),
        LineCol('Số lượng mẫu lưu', width: 80, numeric: true),
      ],
      rows: [
        for (final l in lines)
          [
            l.codedSample,
            l.testParameter,
            l.testMethods.join(', '),
            _num(l.testSampleWeight),
            '${l.testSampleCount}',
            _num(l.retainSampleWeight),
            '${l.retainSampleCount}',
          ],
      ],
    );
  }
}

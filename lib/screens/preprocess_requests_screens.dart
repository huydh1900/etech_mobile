import '../services/search_spec_service.dart';
import '../widgets/record_card.dart';
import 'package:flutter/material.dart';
import '../utils/vn_format.dart';
import '../config.dart';
import '../models/preprocess_requests.dart';
import '../services/permission_controller.dart';
import '../services/preprocess_requests_service.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_kit.dart';
import '../widgets/module_list_scaffold.dart';
import '../widgets/odoo_web_clone.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// Màn hình "Yêu cầu xử lý mẫu" (etech.preprocess.request).
/// - List: StatelessWidget dựng [PreprocessRequestsService] inline + [ModuleListScaffold].
/// - Detail: [ModuleDetailScaffold] (tự lo loading/error/retry).
/// - Gating dữ liệu qua permissionModel: 'etech.preprocess.request'.
/// ───────────────────────────────────────────────────────────────────────────

/// List "Yêu cầu xử lý mẫu" dạng card. Search + Bộ lọc/Nhóm theo (search view Odoo) +
/// phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class PreprocessRequestsListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const PreprocessRequestsListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final service = PreprocessRequestsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<PreprocessRequestBrief>(
      title: 'Yêu cầu xử lý mẫu',
      permissionModel: 'etech.preprocess.request',
      searchSpec: () =>
          SearchSpecService.load(sessionId, 'etech.preprocess.request'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm theo mã / khách hàng / tên mẫu…',
      unitLabel: 'yêu cầu',
      emptyIcon: Icons.science_outlined,
      emptyTitle: 'Không có yêu cầu',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getPreprocessRequests(
            query: query,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, r) => RecordCard(
        title: r.name,
        state: r.state,
        stateLabel: r.stateLabel,
        subtitle: r.partnerName,
        tag: r.sampleType,
        note: r.sampleName,
        refs: [
          (
            Icons.move_to_inbox_outlined,
            r.receivedAt.isEmpty ? '' : 'Nhận ${r.receivedAt}',
          ),
          (
            Icons.task_alt_rounded,
            r.preprocessDoneAt.isEmpty ? '' : 'Xong ${r.preprocessDoneAt}',
          ),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PreprocessRequestDetailPage(
              sessionId: sessionId,
              requestId: r.id,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [PreprocessRequestsListScreen]).
// TODO: xoá khi chốt dùng bản card.
class PreprocessRequestsTreeListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const PreprocessRequestsTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<PreprocessRequestsTreeListScreen> createState() =>
      _PreprocessRequestsTreeListScreenState();
}

class _PreprocessRequestsTreeListScreenState
    extends State<PreprocessRequestsTreeListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = PreprocessRequestsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Yêu cầu xử lý mẫu',
      permissionModel: 'etech.preprocess.request',
      primaryButtonLabel: 'Mới',
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooTreeListView<PreprocessRequestBrief>(
        showSearch: _search,
        searchHint: 'Tìm theo mã / khách hàng / tên mẫu…',
        emptyIcon: Icons.science_outlined,
        emptyTitle: 'Không có yêu cầu',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getPreprocessRequests(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        onTapRow: (context, r) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PreprocessRequestDetailPage(
              sessionId: widget.sessionId,
              requestId: r.id,
            ),
          ),
        ),
        columns: [
          OdooTreeColumn(
            label: 'Mã yêu cầu',
            width: 150,
            link: true,
            linkColor: kOdooBlue,
            value: (r) => r.name,
          ),
          OdooTreeColumn(
            label: 'Khách hàng',
            width: 160,
            link: true,
            value: (r) => r.partnerName,
          ),
          OdooTreeColumn(
            label: 'Loại mẫu',
            width: 140,
            value: (r) => r.sampleType,
          ),
          OdooTreeColumn(label: 'Mẫu', width: 150, value: (r) => r.sampleName),
          OdooTreeColumn(
            label: 'Ngày nhận',
            width: 110,
            value: (r) => r.receivedAt,
          ),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 130,
            value: (r) => r.stateLabel,
          ),
        ],
      ),
    );
  }
}

/// Chi tiết yêu cầu xử lý mẫu — dùng [ModuleDetailScaffold].
class PreprocessRequestDetailPage extends StatelessWidget {
  final String sessionId;
  final int requestId;
  const PreprocessRequestDetailPage({
    super.key,
    required this.sessionId,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    final service = PreprocessRequestsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleDetailScaffold<PreprocessRequestDetail>(
      title: 'Yêu cầu xử lý mẫu',
      load: () => service.getPreprocessRequest(requestId),
      builder: (context, d, reload) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  OdooFormHeader(
                    stateLabel: d.stateLabel,
                    title: 'PHIẾU YÊU CẦU SƠ CHẾ',
                    subtitle: [HeaderSub('Số phiếu', d.name, link: true)],
                    createdBy: d.createdBy,
                    createdAt: metaDt(d.createdAt),
                    updatedBy: d.updatedBy,
                    updatedAt: metaDt(d.updatedAt),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                    child: Column(children: _detailSections(d)),
                  ),
                ],
              ),
            ),
            _PreprocessActionBar(
              service: service,
              requestId: requestId,
              state: d.state,
              reload: reload,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _detailSections(PreprocessRequestDetail d) {
    return [
      InfoSection(
        number: 1,
        title: 'Thông tin chung',
        children: [
          InfoRow('Bên gửi mẫu', d.sender),
          InfoRow('Bên nhận mẫu', d.receiver),
          InfoRow('Phiếu bàn giao mẫu', d.handoverName),
          InfoRow('Loại mẫu', d.sampleType),
          InfoRow('Tên mẫu', d.sampleName),
          InfoRow('Khối lượng mẫu (Quả/kg)', d.quantity),
          InfoRow('Thời gian tiếp nhận mẫu', d.receivedAt),
          InfoChips('Người sơ chế', d.preprocessors),
          InfoRow('Thời gian hoàn thành sơ chế', d.preprocessDoneAt),
          InfoRow('Xử lý khối lượng mẫu dư', d.excessHandling),
          InfoRow('Thời gian trả kết quả', d.resultDueAt),
        ],
      ),
      _LinesSection(lines: d.lines),
      InfoSection(
        title: 'Chữ ký',
        children: [
          InfoRow('ĐD. Bộ phận tiếp nhận mẫu', d.senderSignerName),
          InfoRow('ĐD. Bộ phận chuẩn bị mẫu', d.receiverSignerName),
        ],
      ),
    ];
  }
}

/// ───────── Thanh nút thao tác (state-aware + permission-gated) ─────────

/// Khai báo 1 action theo cấu hình backend.
class _ActionSpec {
  final String slug;
  final String label;

  /// State được phép hiển thị; rỗng = luôn hiển thị.
  final List<String> fromStates;
  final bool needsReason;

  /// Hành động phá huỷ (hủy/từ chối) → tô màu danger, dạng outlined.
  final bool destructive;

  /// Gọi service tương ứng; trả state mới (hoặc '' nếu không đổi).
  final Future<String> Function(
    PreprocessRequestsService svc,
    int id,
    String? reason,
  )
  run;

  const _ActionSpec({
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

const String _kPreprocessModel = 'etech.preprocess.request';

final List<_ActionSpec> _preprocessActions = [
  _ActionSpec(
    slug: 'send',
    label: 'Gửi yêu cầu',
    fromStates: const ['draft'],
    run: (svc, id, _) => svc.actionSend(id),
  ),
  _ActionSpec(
    slug: 'receive',
    label: 'Tiếp nhận mẫu',
    fromStates: const ['sent'],
    run: (svc, id, _) => svc.actionReceive(id),
  ),
  _ActionSpec(
    slug: 'done',
    label: 'Hoàn thành sơ chế',
    fromStates: const ['received'],
    run: (svc, id, _) => svc.actionDone(id),
  ),
  _ActionSpec(
    slug: 'create_analysis_request',
    label: 'Tạo phiếu yêu cầu phân tích',
    fromStates: const ['done'],
    run: (svc, id, _) => svc.actionCreateAnalysisRequest(id),
  ),
  _ActionSpec(
    slug: 'cancel',
    label: 'Hủy',
    fromStates: const ['draft', 'sent', 'received'],
    needsReason: true,
    destructive: true,
    run: (svc, id, reason) => svc.actionCancel(id, reason ?? ''),
  ),
];

class _PreprocessActionBar extends StatefulWidget {
  final PreprocessRequestsService service;
  final int requestId;
  final String state;
  final VoidCallback reload;

  const _PreprocessActionBar({
    required this.service,
    required this.requestId,
    required this.state,
    required this.reload,
  });

  @override
  State<_PreprocessActionBar> createState() => _PreprocessActionBarState();
}

class _PreprocessActionBarState extends State<_PreprocessActionBar> {
  bool _busy = false;

  Future<void> _run(_ActionSpec spec) async {
    String? reason;
    if (spec.needsReason) {
      reason = await _askReason();
      if (reason == null) return; // user hủy dialog
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await spec.run(widget.service, widget.requestId, reason);
      if (!mounted) return;
      _snack('Thao tác "${spec.label}" thành công', AppColors.success);
      widget.reload();
    } catch (e) {
      if (!mounted) return;
      _snack(_clean(e), AppColors.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _clean(Object e) {
    var s = e.toString();
    if (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
    return s;
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _askReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Lý do hủy',
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            style: TextStyle(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Nhập lý do hủy phiếu…',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Đóng', style: TextStyle(color: AppColors.inkMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return; // bắt buộc nhập lý do
                Navigator.of(ctx).pop(text);
              },
              child: const Text('Xác nhận hủy'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!permissions.canWrite(_kPreprocessModel)) {
      return const SizedBox.shrink();
    }
    final actions = _preprocessActions
        .where((a) => a.visibleFor(widget.state))
        .toList();
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
          children: [for (final a in actions) _buttonFor(a)],
        ),
      ),
    );
  }

  Widget _buttonFor(_ActionSpec spec) {
    final child = _busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(spec.label);
    final onPressed = _busy ? null : () => _run(spec);

    if (spec.destructive) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        child: child,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: child,
    );
  }
}

class _LinesSection extends StatelessWidget {
  final List<PreprocessRequestLine> lines;
  const _LinesSection({required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return LineTable(
      title: 'Thông tin mẫu',
      icon: Icons.science_outlined,
      number: 2,
      columns: const [
        LineCol('Mã hóa mẫu', width: 130),
        LineCol('Chỉ tiêu phân tích', width: 150),
        LineCol('Phương pháp phân tích', width: 180),
        LineCol('Sơ chế', width: 130),
        LineCol('KL tối thiểu/mẫu (TN)', width: 96, numeric: true),
        LineCol('Số lượng mẫu (TN)', width: 80, numeric: true),
        LineCol('KL tối thiểu/mẫu (lưu)', width: 96, numeric: true),
        LineCol('Số lượng mẫu (lưu)', width: 80, numeric: true),
      ],
      rows: [
        for (final l in lines)
          [
            l.codedSample,
            l.testParameter,
            l.testMethods.join(', '),
            _part(l),
            l.testMinWeight,
            l.testSampleCount,
            l.retainMinWeight,
            l.retainSampleCount,
          ],
      ],
    );
  }

  // "Khác" -> hiển thị kèm nội dung tự nhập (preprocess_part_other).
  String _part(PreprocessRequestLine l) {
    if (l.preprocessPart == 'Khác' && l.preprocessPartOther.isNotEmpty) {
      return 'Khác: ${l.preprocessPartOther}';
    }
    return l.preprocessPart;
  }
}

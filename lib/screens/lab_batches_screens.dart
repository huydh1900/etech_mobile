import '../services/search_spec_service.dart';
import '../widgets/record_card.dart';
import 'package:flutter/material.dart';
import '../utils/vn_format.dart';
import '../config.dart';
import '../models/lab_batches.dart';
import '../services/lab_batches_service.dart';
import '../services/permission_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_kit.dart';
import '../widgets/module_list_scaffold.dart';
import '../widgets/odoo_web_clone.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// MÀN HÌNH "Mẻ phân tích" (etech.lab.batch) — list + detail.
///
/// - List: StatelessWidget dựng [LabBatchesService] inline + [ModuleListScaffold]
///   (search, lọc trạng thái, gating quyền đọc qua permissionModel 'etech.lab.batch').
/// - Detail: [ModuleDetailScaffold] (tự lo loading/error/retry).
/// - Menu gating: router gọi qua permissions.canSeeMenu('menu_etech_lab_batch').
/// ───────────────────────────────────────────────────────────────────────────

/// Định dạng khối lượng (g) gọn: bỏ số 0 thừa, dùng dấu phẩy kiểu VN.
String _g(double v) {
  var s = v.toStringAsFixed(4);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

/// List "Mẻ phân tích" dạng card. Search + Bộ lọc/Nhóm theo (search view Odoo) +
/// phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class LabBatchesListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const LabBatchesListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final service = LabBatchesService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<LabBatchesBrief>(
      title: 'Mẻ phân tích',
      permissionModel: 'etech.lab.batch',
      searchSpec: () => SearchSpecService.load(sessionId, 'etech.lab.batch'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm tên mẻ, phương pháp…',
      unitLabel: 'mẻ',
      emptyIcon: Icons.science_outlined,
      emptyTitle: 'Chưa có mẻ phân tích',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getBatches(
            query: query,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, b) => RecordCard(
        title: b.name.isEmpty ? '(chưa đặt tên)' : b.name,
        state: b.state,
        stateLabel: b.stateLabel,
        subtitle: b.methodName,
        tag: b.methodCode,
        tagIcon: Icons.rule_rounded,
        refs: [
          (Icons.event_outlined, formatVn(b.analysisDateStart)),
          (Icons.inventory_2_outlined, '${b.sampleCount} mẫu'),
          (Icons.description_outlined, '${b.requestCount} phiếu'),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                LabBatchesDetailScreen(sessionId: sessionId, batchId: b.id),
          ),
        ),
      ),
    );
  }
}

/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [LabBatchesListScreen]).
// TODO: xoá khi chốt dùng bản card.
class LabBatchesTreeListScreen extends StatefulWidget {
  final String sessionId;
  final VoidCallback? onOpenNotifications;

  const LabBatchesTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<LabBatchesTreeListScreen> createState() =>
      _LabBatchesTreeListScreenState();
}

class _LabBatchesTreeListScreenState extends State<LabBatchesTreeListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = LabBatchesService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Mẻ phân tích',
      permissionModel: 'etech.lab.batch',
      primaryButtonLabel: 'Mới',
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooTreeListView<LabBatchesBrief>(
        showSearch: _search,
        searchHint: 'Tìm tên mẻ, phương pháp…',
        emptyIcon: Icons.science_outlined,
        emptyTitle: 'Chưa có mẻ phân tích',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getBatches(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        onTapRow: (context, b) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LabBatchesDetailScreen(
              sessionId: widget.sessionId,
              batchId: b.id,
            ),
          ),
        ),
        columns: [
          OdooTreeColumn(
            label: 'Tên mẻ',
            width: 160,
            link: true,
            linkColor: kOdooBlue,
            value: (b) => b.name.isEmpty ? '(chưa đặt tên)' : b.name,
          ),
          OdooTreeColumn(
            label: 'Phương pháp',
            width: 160,
            value: (b) => b.methodName,
          ),
          OdooTreeColumn(
            label: 'Số mẫu',
            width: 70,
            value: (b) => '${b.sampleCount}',
          ),
          OdooTreeColumn(
            label: 'Số phiếu',
            width: 70,
            value: (b) => '${b.requestCount}',
          ),
          OdooTreeColumn(
            label: 'Ngày phân tích',
            width: 130,
            value: (b) => b.analysisDateStart,
          ),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 130,
            value: (b) => b.stateLabel,
          ),
        ],
      ),
    );
  }
}

class LabBatchesDetailScreen extends StatelessWidget {
  final String sessionId;
  final int batchId;

  const LabBatchesDetailScreen({
    super.key,
    required this.sessionId,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    final service = LabBatchesService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleDetailScaffold<LabBatchesDetail>(
      title: 'Chi tiết mẻ phân tích',
      load: () => service.getBatch(batchId),
      builder: (context, b, reload) {
        return Column(
          children: [
            Expanded(
              child: DetailBody(
                header: OdooFormHeader(
                  stateLabel: b.stateLabel,
                  title: 'MẺ MẪU',
                  subtitle: [
                    HeaderSub(
                      'Số mẻ',
                      b.name.isEmpty ? '(chưa đặt tên)' : b.name,
                    ),
                  ],
                  createdBy: b.createdBy,
                  createdAt: metaDt(b.createdAt),
                  updatedBy: b.updatedBy,
                  updatedAt: metaDt(b.updatedAt),
                ),
                children: [
                  // Banner lý do hủy (khớp form Odoo khi state == cancel).
                  if (b.state == 'cancel' && b.cancelReason.isNotEmpty)
                    InfoSection(
                      title: 'Lý do hủy',
                      icon: Icons.cancel_outlined,
                      children: [
                        InfoRow('Người hủy', b.cancelUidName),
                        InfoRow(
                          'Lý do hủy',
                          b.cancelReason,
                          valueColor: AppColors.danger,
                        ),
                      ],
                    ),
                  // I. Thông tin chung — Odoo chỉ hiện 2 field (xem ref).
                  InfoSection(
                    title: 'Thông tin chung',
                    number: 1,
                    icon: Icons.info_outline_rounded,
                    children: [
                      InfoRow('Ngày tạo mẻ', metaDt(b.analysisDateStart)),
                      InfoRow(
                        'Phương pháp phân tích',
                        b.methodName,
                        mono: true,
                      ),
                    ],
                  ),
                  LineTable(
                    title: 'Mẫu trong mẻ',
                    number: 2,
                    icon: Icons.science_outlined,
                    columns: const [
                      LineCol('Mã mẫu', width: 130),
                      LineCol('Chỉ tiêu phân tích', width: 150),
                      LineCol('Loại mẫu', width: 100),
                      LineCol('Mẫu lặp', width: 70, numeric: true),
                      LineCol('Thêm chuẩn', width: 80, numeric: true),
                      LineCol('m mẫu (g)', width: 90, numeric: true),
                      LineCol('Kết quả', width: 100),
                    ],
                    rows: [
                      for (final l in b.lines)
                        [
                          l.codedSample,
                          l.parameterName,
                          l.sampleType,
                          l.numDuplicate > 0 ? '${l.numDuplicate}' : '',
                          l.numSpike > 0 ? '${l.numSpike}' : '',
                          l.weightG > 0 ? _g(l.weightG) : '',
                          l.result,
                        ],
                    ],
                  ),
                  // Mẫu con (lặp / thêm chuẩn) gộp từ mọi dòng — chỉ hiện khi có.
                  LineTable(
                    title: 'Mẫu lặp / thêm chuẩn',
                    icon: Icons.copy_all_outlined,
                    columns: const [
                      LineCol('Mã mẫu', width: 200),
                      LineCol('Loại mẫu', width: 130),
                      LineCol('m mẫu (g)', width: 90, numeric: true),
                    ],
                    rows: [
                      for (final l in b.lines)
                        for (final s in l.subLines)
                          [
                            s.codedSample,
                            s.sampleType,
                            s.weightG > 0 ? _g(s.weightG) : '',
                          ],
                    ],
                  ),
                  LineTable(
                    title: 'Biên bản thử nghiệm',
                    number: 3,
                    icon: Icons.description_outlined,
                    columns: const [
                      LineCol('Biên bản', width: 180),
                      LineCol('Chỉ tiêu', width: 90),
                      LineCol('Trạng thái', width: 110),
                    ],
                    rows: [
                      for (final r in b.testRecords)
                        [r.name, r.metal, r.stateLabel],
                    ],
                  ),
                ],
              ),
            ),
            _BatchActionBar(service: service, batch: b, reload: reload),
          ],
        );
      },
    );
  }
}

// ───────────────────────────── Action bar ─────────────────────────────

/// Định nghĩa 1 hành động server-side. [fromStates] rỗng = luôn hiện.
class _BatchAction {
  final String label;
  final List<String> fromStates;
  final bool needsReason;
  final bool destructive;

  /// Gọi service tương ứng; trả về state mới (nếu có).
  final Future<String?> Function(LabBatchesService s, int id, {String? reason})
  run;

  const _BatchAction({
    required this.label,
    required this.fromStates,
    required this.needsReason,
    required this.destructive,
    required this.run,
  });
}

const List<_BatchAction> _batchActions = [
  _BatchAction(
    label: 'Bắt đầu cân mẫu',
    fromStates: ['draft'],
    needsReason: false,
    destructive: false,
    run: _runStartWeighing,
  ),
  _BatchAction(
    label: 'Tạo biên bản thử nghiệm',
    fromStates: ['weighing', 'analyzing'],
    needsReason: false,
    destructive: false,
    run: _runCreateTestRecord,
  ),
  _BatchAction(
    label: 'Tạo phiếu kết quả',
    fromStates: ['analyzing', 'done'],
    needsReason: false,
    destructive: false,
    run: _runCreateTestReport,
  ),
  _BatchAction(
    label: 'Hủy mẻ',
    fromStates: ['draft', 'weighing', 'analyzing'],
    needsReason: true,
    destructive: true,
    run: _runCancel,
  ),
];

// Top-level fn refs (const list không cho phép closure).
Future<String?> _runStartWeighing(
  LabBatchesService s,
  int id, {
  String? reason,
}) => s.startWeighing(id);
Future<String?> _runCreateTestRecord(
  LabBatchesService s,
  int id, {
  String? reason,
}) => s.createTestRecord(id);
Future<String?> _runCreateTestReport(
  LabBatchesService s,
  int id, {
  String? reason,
}) => s.createTestReport(id);
Future<String?> _runCancel(LabBatchesService s, int id, {String? reason}) =>
    s.cancelBatch(id, reason ?? '');

class _BatchActionBar extends StatefulWidget {
  final LabBatchesService service;
  final LabBatchesDetail batch;
  final VoidCallback reload;

  const _BatchActionBar({
    required this.service,
    required this.batch,
    required this.reload,
  });

  @override
  State<_BatchActionBar> createState() => _BatchActionBarState();
}

class _BatchActionBarState extends State<_BatchActionBar> {
  bool _busy = false;

  List<_BatchAction> get _visible {
    if (!permissions.canWrite('etech.lab.batch')) return const [];
    final st = widget.batch.state;
    return _batchActions
        .where((a) => a.fromStates.isEmpty || a.fromStates.contains(st))
        .toList();
  }

  Future<void> _onTap(_BatchAction action) async {
    if (_busy) return;
    String? reason;
    if (action.needsReason) {
      reason = await _askReason(action.label);
      if (reason == null) return; // huỷ dialog
    }
    setState(() => _busy = true);
    try {
      await action.run(widget.service, widget.batch.id, reason: reason);
      if (!mounted) return;
      _snack('${action.label}: thành công', AppColors.success);
      widget.reload();
    } catch (e) {
      if (!mounted) return;
      _snack(_clean(e), AppColors.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(String title) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          title,
          style: TextStyle(color: AppColors.ink, fontSize: AppType.subtitle),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          style: TextStyle(color: AppColors.ink),
          decoration: const InputDecoration(
            hintText: 'Nhập lý do hủy…',
            border: OutlineInputBorder(),
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
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
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

  String _clean(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  @override
  Widget build(BuildContext context) {
    final actions = _visible;
    if (actions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: actions.map(_buildButton).toList(),
      ),
    );
  }

  Widget _buildButton(_BatchAction a) {
    final onPressed = _busy ? null : () => _onTap(a);
    final spinner = _busy
        ? const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : const SizedBox.shrink();

    if (a.destructive) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [spinner, Text(a.label)],
        ),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [spinner, Text(a.label)],
      ),
    );
  }
}

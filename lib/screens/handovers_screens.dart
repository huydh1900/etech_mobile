import 'package:flutter/material.dart';
import '../utils/vn_format.dart';
import '../config.dart';
import '../models/handovers.dart';
import '../services/handovers_service.dart';
import '../services/permission_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_kit.dart';
import '../widgets/module_list_scaffold.dart';
import '../widgets/odoo_web_clone.dart';
import '../widgets/record_card.dart';
import '../services/search_spec_service.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// MÀN HÌNH "Bàn giao mẫu" (etech.sampling.handover).
/// - List: StatelessWidget dựng [HandoverService] inline + [ModuleListScaffold].
/// - Detail: dùng [ModuleDetailScaffold] (tự lo loading/error/retry).
/// - Gating menu qua permissions.canSeeMenu('menu_etech_sampling_handover') ở
///   router; gating dữ liệu qua permissionModel: 'etech.sampling.handover'.
/// ───────────────────────────────────────────────────────────────────────────

/// List "Phiếu bàn giao mẫu" dạng card. Search + Bộ lọc/Nhóm theo (search view
/// Odoo) + phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class HandoverListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const HandoverListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final service = HandoverService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<HandoverBrief>(
      title: 'Phiếu bàn giao mẫu',
      permissionModel: 'etech.sampling.handover',
      searchSpec: () =>
          SearchSpecService.load(sessionId, 'etech.sampling.handover'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm mã phiếu, khách hàng, mẫu…',
      unitLabel: 'phiếu',
      emptyIcon: Icons.swap_horiz_rounded,
      emptyTitle: 'Chưa có phiếu bàn giao',
      emptyMessage: 'Phiếu bàn giao mẫu sẽ hiển thị tại đây.',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getHandovers(
            query: query,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, h) => RecordCard(
        title: h.code,
        state: h.state,
        stateLabel: h.stateLabel,
        subtitle: h.partnerName,
        tag: h.sampleType,
        note: h.sampleName,
        refs: [
          (Icons.folder_outlined, h.requestCode),
          (Icons.assignment_outlined, h.reportCode),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                HandoverDetailPage(sessionId: sessionId, handoverId: h.id),
          ),
        ),
      ),
    );
  }
}

/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [HandoverListScreen]).
// TODO: xoá khi chốt dùng bản card.
class HandoverTreeListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const HandoverTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<HandoverTreeListScreen> createState() => _HandoverTreeListScreenState();
}

class _HandoverTreeListScreenState extends State<HandoverTreeListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = HandoverService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Bàn giao mẫu',
      permissionModel: 'etech.sampling.handover',
      primaryButtonLabel: 'Mới',
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooTreeListView<HandoverBrief>(
        showSearch: _search,
        searchHint: 'Tìm theo mã / khách hàng / mẫu…',
        emptyIcon: Icons.swap_horiz_rounded,
        emptyTitle: 'Chưa có phiếu bàn giao',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getHandovers(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        onTapRow: (context, h) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HandoverDetailPage(
              sessionId: widget.sessionId,
              handoverId: h.id,
            ),
          ),
        ),
        columns: [
          OdooTreeColumn(
            label: 'Số phiếu',
            width: 150,
            link: true,
            linkColor: kOdooBlue,
            value: (h) => h.code.isEmpty ? '(Chưa có mã)' : h.code,
          ),
          OdooTreeColumn(
            label: 'Khách hàng',
            width: 160,
            link: true,
            value: (h) => h.partnerName,
          ),
          OdooTreeColumn(
            label: 'Loại mẫu',
            width: 140,
            value: (h) => h.sampleType,
          ),
          OdooTreeColumn(label: 'Mẫu', width: 150, value: (h) => h.sampleName),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 120,
            value: (h) => h.stateLabel,
          ),
        ],
      ),
    );
  }
}

/// Chi tiết phiếu bàn giao — dùng [ModuleDetailScaffold].
class HandoverDetailPage extends StatelessWidget {
  final String sessionId;
  final int handoverId;
  const HandoverDetailPage({
    super.key,
    required this.sessionId,
    required this.handoverId,
  });

  @override
  Widget build(BuildContext context) {
    final service = HandoverService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleDetailScaffold<HandoverDetail>(
      title: 'Bàn giao mẫu',
      load: () => service.getHandover(handoverId),
      builder: (context, h, reload) {
        return Column(
          children: [
            Expanded(child: _HandoverReadBody(handover: h)),
            _HandoverActions(service: service, handover: h, reload: reload),
          ],
        );
      },
    );
  }
}

/// Phần render chi tiết (read-mode) — khớp formview Odoo: OdooFormHeader +
/// các mục đánh số La Mã, label-trên-value, bảng o2m, mục chữ ký.
class _HandoverReadBody extends StatelessWidget {
  final HandoverDetail handover;
  const _HandoverReadBody({required this.handover});

  @override
  Widget build(BuildContext context) {
    final h = handover;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        OdooFormHeader(
          stateLabel: h.stateLabel,
          state: h.state,
          title: 'PHIẾU BÀN GIAO MẪU',
          subtitle: [
            HeaderSub('Hồ sơ', h.requestCode),
            HeaderSub('Biên bản', h.reportCode, link: true),
          ],
          createdBy: h.createdBy,
          createdAt: metaDt(h.createdAt),
          updatedBy: h.updatedBy,
          updatedAt: metaDt(h.updatedAt),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          child: Column(
            children: [
              InfoSection(
                number: 1,
                title: 'Thông tin chung',
                children: [
                  InfoRow('Bên gửi mẫu', h.senderDept),
                  // Odoo: widget="radio" options="{'horizontal': True}".
                  InfoRadioGroup(
                    'Hình thức gửi mẫu',
                    options: h.sendMethodOptions,
                    selected: h.sendMethodLabel,
                  ),
                  InfoRow('Mã vận đơn', h.trackingNo, mono: true),
                  InfoRow('Loại mẫu', h.sampleType),
                  InfoRow('Tên mẫu', h.sampleName),
                  InfoRow(
                    'Số lượng mẫu thử nghiệm',
                    h.sampleCount > 0 ? '${h.sampleCount}' : '',
                  ),
                  InfoRow(
                    'Thời gian hoàn thành lấy mẫu',
                    h.samplingCompletionLabel,
                  ),
                  InfoRow('Thời gian trả kết quả dự kiến', h.resultDueDate),
                  InfoRow('Thời gian tiếp nhận mẫu', h.receiveDatetimeLabel),
                ],
              ),
              LineTable(
                number: 2,
                title: 'Thông tin mẫu',
                columns: const [
                  LineCol('Mã mẫu', width: 130),
                  LineCol('Chỉ tiêu', width: 170),
                  LineCol('Số tem', width: 90),
                  LineCol('Tình trạng mẫu', width: 120),
                  LineCol('Bao gói', width: 120),
                  LineCol('KL', width: 56, numeric: true),
                  LineCol('Đơn vị', width: 70),
                  LineCol('Lưu mẫu', width: 110),
                  LineCol('KQ tình trạng', width: 100),
                  LineCol('KQ bao gói', width: 100),
                  LineCol('KQ khối lượng', width: 100),
                  LineCol('KQ lưu mẫu', width: 100),
                  LineCol('Kết luận', width: 110),
                ],
                rows: [
                  for (final l in h.lines)
                    [
                      l.originalCode,
                      l.parameters.join(', '),
                      l.sealStampNo,
                      l.evalSampleStatus,
                      l.evalPacking,
                      l.sampleWeight == 0 ? '' : '${l.sampleWeight}',
                      l.packingUnit,
                      l.evalStorage,
                      l.recvStatusResult,
                      l.recvPackingResult,
                      l.recvWeightResult,
                      l.recvStorageResult,
                      l.conclusion,
                    ],
                ],
              ),
              if (h.receptionImageCount > 0)
                InfoSection(
                  number: 3,
                  title: 'Hình ảnh khi nhận mẫu',
                  children: [
                    InfoRow('Số ảnh đã đính kèm', '${h.receptionImageCount}'),
                  ],
                ),
              // Yêu cầu sơ chế đã tạo từ phiếu này (ngoài formview gốc nhưng
              // hữu ích để điều hướng nghiệp vụ trên mobile).
              LineTable(
                title: 'Yêu cầu sơ chế',
                icon: Icons.assignment_outlined,
                columns: const [
                  LineCol('Phiếu', width: 150),
                  LineCol('Trạng thái', width: 130),
                ],
                rows: [
                  for (final p in h.preprocessRequests)
                    [p.name, _preprocessStateLabel(p.state)],
                ],
              ),
              InfoSection(
                title: 'Chữ ký',
                children: [
                  InfoRow('Bên gửi mẫu', h.senderSignerName),
                  InfoRow('Bên nhận mẫu', h.receiverSignerName),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mô tả một action bàn giao (label, slug, các state cho phép, có cần lý do).
class _ActionSpec {
  final String slug;
  final String label;
  final List<String> fromStates;
  final bool needsReason;
  final bool destructive;
  const _ActionSpec({
    required this.slug,
    required this.label,
    required this.fromStates,
    this.needsReason = false,
    this.destructive = false,
  });

  bool visibleFor(String state) =>
      fromStates.isEmpty || fromStates.contains(state);
}

const List<_ActionSpec> _handoverActionSpecs = [
  _ActionSpec(slug: 'hand_over', label: 'Bàn giao mẫu', fromStates: ['draft']),
  _ActionSpec(slug: 'receive', label: 'Tiếp nhận mẫu', fromStates: ['handed']),
  _ActionSpec(
    slug: 'return',
    label: 'Trả lại mẫu',
    fromStates: ['handed'],
    needsReason: true,
    destructive: true,
  ),
];

/// Thanh nút thao tác cho màn chi tiết: chỉ hiện action hợp lệ với state hiện
/// tại VÀ khi có quyền write 'etech.sampling.handover'. Disable khi đang gọi.
class _HandoverActions extends StatefulWidget {
  final HandoverService service;
  final HandoverDetail handover;
  final VoidCallback reload;
  const _HandoverActions({
    required this.service,
    required this.handover,
    required this.reload,
  });

  @override
  State<_HandoverActions> createState() => _HandoverActionsState();
}

class _HandoverActionsState extends State<_HandoverActions> {
  bool _busy = false;

  List<_ActionSpec> get _available => _handoverActionSpecs
      .where((a) => a.visibleFor(widget.handover.state))
      .toList();

  Future<void> _run(_ActionSpec spec) async {
    String? reason;
    if (spec.needsReason) {
      reason = await _askReason(spec.label);
      if (reason == null) return; // user hủy
    }
    setState(() => _busy = true);
    try {
      switch (spec.slug) {
        case 'hand_over':
          await widget.service.handOver(widget.handover.id);
          break;
        case 'receive':
          await widget.service.receive(widget.handover.id);
          break;
        case 'return':
          await widget.service.returnSample(
            widget.handover.id,
            reason: reason!,
          );
          break;
      }
      if (!mounted) return;
      _toast('${spec.label}: thành công');
      widget.reload();
    } catch (e) {
      if (!mounted) return;
      _toast(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(String title) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Nhập lý do…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Bỏ qua'),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _cleanError(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  @override
  Widget build(BuildContext context) {
    if (!permissions.canWrite('etech.sampling.handover')) {
      return const SizedBox.shrink();
    }
    final actions = _available;
    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in actions) ...[
            _ActionButton(
              spec: a,
              busy: _busy,
              onPressed: _busy ? null : () => _run(a),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final _ActionSpec spec;
  final bool busy;
  final VoidCallback? onPressed;
  const _ActionButton({
    required this.spec,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(spec.label, style: const TextStyle(fontWeight: FontWeight.w700));

    if (spec.destructive) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: child,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: child,
    );
  }
}

// Nhãn cho enum trạng thái yêu cầu sơ chế (detail line không kèm state_label).
String _preprocessStateLabel(String s) {
  switch (s) {
    case 'draft':
      return 'Dự thảo';
    case 'sent':
      return 'Đã gửi yêu cầu';
    case 'received':
      return 'Tiếp nhận mẫu';
    case 'done':
      return 'Đã hoàn thành sơ chế';
    case 'cancel':
      return 'Hủy';
    default:
      return s;
  }
}

import '../services/search_spec_service.dart';
import '../widgets/record_card.dart';
import 'package:flutter/material.dart';
import '../utils/vn_format.dart';
import '../config.dart';
import '../models/destructions.dart';
import '../services/destructions_service.dart';
import '../services/permission_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_kit.dart';
import '../widgets/module_list_scaffold.dart';
import '../widgets/odoo_web_clone.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// MÀN HÌNH "Hủy mẫu" (etech.sample.destruction).
/// List + Detail bám mẫu chuẩn customers_screens.dart:
/// - List: StatelessWidget dựng [DestructionsService] inline + ModuleListScaffold.
/// - Detail: ModuleDetailScaffold (tự lo loading/error/retry).
/// - Gating: menu qua permissions.canSeeMenu ở router; dữ liệu qua
///   permissionModel: 'etech.sample.destruction'.
/// ───────────────────────────────────────────────────────────────────────────

/// List "Hủy mẫu" dạng card. Search + Bộ lọc/Nhóm theo (search view Odoo) +
/// phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class DestructionListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const DestructionListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final service = DestructionsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<DestructionBrief>(
      title: 'Hủy mẫu',
      permissionModel: 'etech.sample.destruction',
      searchSpec: () =>
          SearchSpecService.load(sessionId, 'etech.sample.destruction'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm theo số biên bản…',
      unitLabel: 'biên bản',
      emptyIcon: Icons.delete_sweep_outlined,
      emptyTitle: 'Chưa có biên bản hủy mẫu',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getDestructions(
            query: query,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, d) => RecordCard(
        title: d.name,
        state: d.state,
        stateLabel: d.stateLabel,
        subtitle: d.destroyerName,
        refs: [
          (Icons.event_outlined, d.destructionDate),
          (Icons.inventory_2_outlined, '${d.sampleCount} mẫu'),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestructionDetailPage(
              sessionId: sessionId,
              destructionId: d.id,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [DestructionListScreen]).
// TODO: xoá khi chốt dùng bản card.
class DestructionTreeListScreen extends StatefulWidget {
  final String sessionId;
  final VoidCallback? onOpenNotifications;

  const DestructionTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<DestructionTreeListScreen> createState() =>
      _DestructionTreeListScreenState();
}

class _DestructionTreeListScreenState extends State<DestructionTreeListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = DestructionsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Hủy mẫu',
      permissionModel: 'etech.sample.destruction',
      primaryButtonLabel: 'Mới',
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooTreeListView<DestructionBrief>(
        showSearch: _search,
        searchHint: 'Tìm theo số biên bản…',
        emptyIcon: Icons.delete_sweep_outlined,
        emptyTitle: 'Chưa có biên bản hủy mẫu',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getDestructions(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        onTapRow: (context, d) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestructionDetailPage(
              sessionId: widget.sessionId,
              destructionId: d.id,
            ),
          ),
        ),
        columns: [
          OdooTreeColumn(
            label: 'Số biên bản',
            width: 160,
            link: true,
            linkColor: kOdooBlue,
            value: (d) => d.name,
          ),
          OdooTreeColumn(
            label: 'Ngày hủy',
            width: 110,
            value: (d) => d.destructionDate,
          ),
          OdooTreeColumn(
            label: 'Người hủy',
            width: 150,
            value: (d) => d.destroyerName,
          ),
          OdooTreeColumn(
            label: 'Số mẫu',
            width: 70,
            value: (d) => '${d.sampleCount}',
          ),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 130,
            value: (d) => d.stateLabel,
          ),
        ],
      ),
    );
  }
}

/// Chi tiết biên bản hủy mẫu — dùng [ModuleDetailScaffold].
class DestructionDetailPage extends StatelessWidget {
  final String sessionId;
  final int destructionId;
  const DestructionDetailPage({
    super.key,
    required this.sessionId,
    required this.destructionId,
  });

  @override
  Widget build(BuildContext context) {
    final service = DestructionsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleDetailScaffold<DestructionDetail>(
      title: 'Hủy mẫu',
      load: () => service.getDestruction(destructionId),
      builder: (context, d, reload) {
        return Column(
          children: [
            Expanded(
              child: DetailBody(
                header: OdooFormHeader(
                  stateLabel: d.stateLabel,
                  title: 'BIÊN BẢN HỦY MẪU',
                  subtitle: [HeaderSub('Số', d.name)],
                  createdBy: d.createdBy,
                  createdAt: metaDt(d.createdAt),
                  updatedBy: d.updatedBy,
                  updatedAt: metaDt(d.updatedAt),
                ),
                children: [
                  // Banner lý do hủy — chỉ khi biên bản đã hủy bỏ.
                  if (d.state == 'cancel' && d.cancelReason.isNotEmpty)
                    InfoSection(
                      title: 'Lý do hủy bỏ',
                      children: [
                        InfoRow('Người hủy', d.cancelBy),
                        InfoRow(
                          'Lý do hủy',
                          d.cancelReason,
                          valueColor: AppColors.danger,
                        ),
                      ],
                    ),
                  InfoSection(
                    title: 'Thông tin chung',
                    number: 1,
                    children: [
                      InfoRow('Ngày hủy mẫu', d.destructionDate),
                      InfoRow('Phương pháp hủy mẫu', d.method),
                      InfoRow('Người hủy mẫu', d.destroyerName),
                      InfoRow('Thời điểm xác nhận hủy', d.destroyedAt),
                    ],
                  ),
                  _LinesSection(lines: d.lines),
                  InfoSection(
                    title: 'Ghi chú',
                    number: 3,
                    children: [InfoRow('Ghi chú', d.note)],
                  ),
                ],
              ),
            ),
            _DestructionActionBar(service: service, detail: d, reload: reload),
          ],
        );
      },
    );
  }
}

/// Định nghĩa 1 action gắn với endpoint POST `/api/destructions/<id>/<slug>`.
class _DestructionAction {
  final String slug;
  final String label;
  final List<String> fromStates; // rỗng = luôn hiện
  final bool needsReason;
  final bool destructive; // tô màu danger nếu true
  const _DestructionAction({
    required this.slug,
    required this.label,
    required this.fromStates,
    required this.needsReason,
    required this.destructive,
  });

  bool visibleFor(String state) =>
      fromStates.isEmpty || fromStates.contains(state);
}

const List<_DestructionAction> _destructionActions = [
  _DestructionAction(
    slug: 'done',
    label: 'Xác nhận hủy',
    fromStates: ['draft'],
    needsReason: false,
    destructive: false,
  ),
  _DestructionAction(
    slug: 'cancel',
    label: 'Hủy bỏ',
    fromStates: ['draft'],
    needsReason: true,
    destructive: true,
  ),
];

/// Thanh action dưới đáy: chỉ hiện action hợp lệ với state hiện tại + có quyền
/// ghi trên etech.sample.destruction. Disable toàn bộ khi đang gọi API.
class _DestructionActionBar extends StatefulWidget {
  final DestructionsService service;
  final DestructionDetail detail;
  final VoidCallback reload;
  const _DestructionActionBar({
    required this.service,
    required this.detail,
    required this.reload,
  });

  @override
  State<_DestructionActionBar> createState() => _DestructionActionBarState();
}

class _DestructionActionBarState extends State<_DestructionActionBar> {
  bool _busy = false;

  List<_DestructionAction> get _available {
    if (!permissions.canWrite('etech.sample.destruction')) return const [];
    return _destructionActions
        .where((a) => a.visibleFor(widget.detail.state))
        .toList();
  }

  Future<void> _run(_DestructionAction action) async {
    String? reason;
    if (action.needsReason) {
      reason = await _askReason(action.label);
      if (reason == null) return; // user hủy dialog
    }
    setState(() => _busy = true);
    try {
      if (action.needsReason) {
        await widget.service.actionCancel(widget.detail.id, reason!);
      } else {
        await widget.service.actionDone(widget.detail.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${action.label} thành công')));
      widget.reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errMsg(e)), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errMsg(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  Future<String?> _askReason(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do hủy bỏ…',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () {
                final v = controller.text.trim();
                if (v.isEmpty) return; // bắt buộc nhập lý do
                Navigator.of(ctx).pop(v);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
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
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i != 0) const SizedBox(width: 10),
              Expanded(child: _buildButton(actions[i])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButton(_DestructionAction action) {
    final onPressed = _busy ? null : () => _run(action);
    if (action.destructive) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(action.label),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(action.label),
    );
  }
}

class _LinesSection extends StatelessWidget {
  final List<DestructionLine> lines;
  const _LinesSection({required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return LineTable(
      title: 'Mẫu hủy',
      icon: Icons.science_outlined,
      number: 2,
      columns: const [
        LineCol('Mã mẫu', width: 130),
        LineCol('Khách hàng', width: 150),
        LineCol('SL', width: 50, numeric: true),
        LineCol('KL (g)', width: 70, numeric: true),
        LineCol('Hết hạn lưu', width: 130),
        LineCol('Trạng thái', width: 110),
      ],
      rows: [
        for (final l in lines)
          [
            l.codedSample,
            l.partnerName,
            l.retainCount > 0 ? '${l.retainCount}' : '',
            l.retainWeight > 0 ? l.retainWeight.toStringAsFixed(2) : '',
            l.expiryAt,
            l.stateLabel,
          ],
      ],
    );
  }
}

import '../services/search_spec_service.dart';
import '../widgets/record_card.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/test_reports.dart';
import '../services/permission_controller.dart';
import '../services/test_reports_service.dart';
import '../theme/app_theme.dart';
import '../utils/vn_format.dart';
import '../widgets/detail_kit.dart';
import '../widgets/module_list_scaffold.dart';
import '../widgets/odoo_web_clone.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// MÀN HÌNH "Biên bản thử nghiệm" (etech.test.report).
/// - List: StatelessWidget dựng [TestReportsService] inline + [ModuleListScaffold].
/// - Detail: [ModuleDetailScaffold] (tự lo loading/error/retry).
/// - Gating quyền: menu qua permissions.canSeeMenu ở router; dữ liệu qua
///   permissionModel: 'etech.test.report'.
/// ───────────────────────────────────────────────────────────────────────────

/// List "Phiếu kết quả" dạng card. Search + Bộ lọc/Nhóm theo (search view Odoo) +
/// phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class TestReportsListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const TestReportsListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final service = TestReportsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<TestReportBrief>(
      title: 'Phiếu kết quả',
      permissionModel: 'etech.test.report',
      searchSpec: () => SearchSpecService.load(sessionId, 'etech.test.report'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm theo mã / khách hàng / mẫu…',
      unitLabel: 'phiếu',
      emptyIcon: Icons.science_outlined,
      emptyTitle: 'Chưa có phiếu kết quả',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getTestReports(
            query: query,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, r) => RecordCard(
        title: r.code,
        state: r.state,
        stateLabel: r.stateLabel,
        subtitle: r.partnerName,
        note: r.sampleName,
        refs: [
          (Icons.tag_rounded, r.codeInternal),
          (Icons.event_outlined, r.reportDate),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                TestReportDetailPage(sessionId: sessionId, reportId: r.id),
          ),
        ),
      ),
    );
  }
}

/// Clone tree Odoo web (Phiếu kết quả): bảng cuộn ngang `#` + các cột, nút "In".
/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [TestReportsListScreen]).
// TODO: xoá khi chốt dùng bản card.
class TestReportsTreeListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const TestReportsTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<TestReportsTreeListScreen> createState() =>
      _TestReportsTreeListScreenState();
}

class _TestReportsTreeListScreenState extends State<TestReportsTreeListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = TestReportsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Phiếu kết quả',
      primaryButtonLabel: 'In',
      primaryButtonIcon: Icons.print,
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooTreeListView<TestReportBrief>(
        showSearch: _search,
        searchHint: 'Tìm theo mã / khách hàng / mẫu…',
        emptyIcon: Icons.science_outlined,
        emptyTitle: 'Tạo mới tài liệu',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getTestReports(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        onTapRow: (context, r) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TestReportDetailPage(
              sessionId: widget.sessionId,
              reportId: r.id,
            ),
          ),
        ),
        columns: [
          OdooTreeColumn(
            label: 'Số phiếu (khách hàng)',
            width: 150,
            link: true,
            linkColor: kOdooBlue,
            value: (r) => r.code,
          ),
          OdooTreeColumn(
            label: 'Số phiếu (nội bộ)',
            width: 150,
            link: true,
            linkColor: kOdooBlue,
            value: (r) => r.codeInternal,
          ),
          OdooTreeColumn(
            label: 'Khách hàng',
            width: 150,
            link: true,
            value: (r) => r.partnerName,
          ),
          OdooTreeColumn(label: 'Mẫu', width: 140, value: (r) => r.sampleName),
          OdooTreeColumn(
            label: 'Ngày lập',
            width: 110,
            value: (r) => r.reportDate,
          ),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 110,
            value: (r) => r.stateLabel,
          ),
        ],
      ),
    );
  }
}

/// Chi tiết biên bản thử nghiệm — dùng [ModuleDetailScaffold].
class TestReportDetailPage extends StatelessWidget {
  final String sessionId;
  final int reportId;
  const TestReportDetailPage({
    super.key,
    required this.sessionId,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final service = TestReportsService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleDetailScaffold<TestReportDetail>(
      title: 'Biên bản thử nghiệm',
      load: () => service.getTestReport(reportId),
      builder: (context, d, reload) =>
          _TestReportDetailBody(service: service, report: d, reload: reload),
    );
  }
}

/// Action server-side: lọc theo state hiện tại + quyền write, mở dialog lý do
/// nếu cần, gọi service, hiển thị SnackBar + reload khi xong.
class _ReportAction {
  final String label;
  final List<String> fromStates; // rỗng -> luôn hiện
  final bool needsReason;
  final bool destructive;
  final Future<String?> Function(TestReportsService s, int id, String? reason)
  run;
  const _ReportAction({
    required this.label,
    required this.fromStates,
    required this.needsReason,
    required this.destructive,
    required this.run,
  });

  bool visibleFor(String state) =>
      fromStates.isEmpty || fromStates.contains(state);
}

const List<_ReportAction> _reportActions = [
  _ReportAction(
    label: 'Duyệt',
    fromStates: ['draft'],
    needsReason: false,
    destructive: false,
    run: _runApprove,
  ),
  _ReportAction(
    label: 'Hủy phiếu',
    fromStates: ['draft'],
    needsReason: true,
    destructive: true,
    run: _runCancel,
  ),
];

Future<String?> _runApprove(TestReportsService s, int id, String? reason) =>
    s.approve(id);
Future<String?> _runCancel(TestReportsService s, int id, String? reason) =>
    s.cancel(id, reason: reason ?? '');

class _TestReportDetailBody extends StatefulWidget {
  final TestReportsService service;
  final TestReportDetail report;
  final VoidCallback reload;
  const _TestReportDetailBody({
    required this.service,
    required this.report,
    required this.reload,
  });

  @override
  State<_TestReportDetailBody> createState() => _TestReportDetailBodyState();
}

class _TestReportDetailBodyState extends State<_TestReportDetailBody> {
  bool _busy = false;

  List<_ReportAction> get _availableActions {
    if (!permissions.canWrite('etech.test.report')) return const [];
    return _reportActions
        .where((a) => a.visibleFor(widget.report.state))
        .toList();
  }

  Future<String?> _askReason(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          title,
          style: TextStyle(color: AppColors.ink, fontSize: AppType.bodyLg),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          style: TextStyle(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'Nhập lý do…',
            hintStyle: TextStyle(color: AppColors.inkMuted),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Đóng', style: TextStyle(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(ctx).pop(text);
            },
            child: Text(
              'Xác nhận',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAction(_ReportAction action) async {
    if (_busy) return;
    String? reason;
    if (action.needsReason) {
      reason = await _askReason(action.label);
      if (reason == null) return; // hủy dialog
    }
    setState(() => _busy = true);
    try {
      await action.run(widget.service, widget.report.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${action.label} thành công')));
      widget.reload();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.report;
    final actions = _availableActions;
    return Column(
      children: [
        Expanded(
          child: DetailBody(
            // Header formview Odoo: tiêu đề + 2 mã phiếu (KH / nội bộ) + dòng
            // "Hồ sơ | Biên bản hiện trường" + meta tạo/cập nhật.
            header: OdooFormHeader(
              stateLabel: d.stateLabel,
              title: 'PHIẾU KẾT QUẢ THỬ NGHIỆM',
              subtitle: [
                HeaderSub('Số phiếu (KH)', d.code),
                if (d.codeInternal.isNotEmpty)
                  HeaderSub('Số phiếu (nội bộ)', d.codeInternal),
                if (d.requestCode.isNotEmpty) HeaderSub('Hồ sơ', d.requestCode),
                if (d.samplingReportName.isNotEmpty)
                  HeaderSub(
                    'Biên bản hiện trường',
                    d.samplingReportName,
                    link: true,
                  ),
              ],
              createdBy: d.createdBy,
              createdAt: metaDt(d.createdAt),
              updatedBy: d.updatedBy,
              updatedAt: metaDt(d.updatedAt),
            ),
            children: [
              InfoSection(
                title: 'Thông tin khách hàng / Client Information',
                number: 1,
                icon: Icons.business_outlined,
                children: [
                  InfoRow('Khách hàng / Client', d.partnerName),
                  InfoRow('Địa chỉ / Address', d.customerAddress),
                  InfoRow(
                    'Địa điểm và địa chỉ lấy mẫu / Sampling location',
                    d.samplingLocationName,
                  ),
                  InfoRow('Thông tin mẫu / Sample information', d.sampleName),
                  InfoRow(
                    'Mã vùng trồng / Orchard number',
                    d.plantingAreaCode,
                    mono: true,
                  ),
                  InfoRow(
                    'Mã cơ sở đóng gói / Packing house Number',
                    d.packingFacilityCode,
                    mono: true,
                  ),
                  InfoRow(
                    'Biển số xe / Truck plate number',
                    d.vehiclePlate,
                    mono: true,
                  ),
                  InfoRow(
                    'Biển số Rmooc / Rmooc number',
                    d.trailerPlate,
                    mono: true,
                  ),
                  InfoRow(
                    'Mã số container / Container number',
                    d.containerCode,
                    mono: true,
                  ),
                  InfoRow(
                    'Mã số niêm phong (Kẹp chì) / Seal number (seal tag)',
                    d.sealNumber,
                    mono: true,
                  ),
                ],
              ),
              InfoSection(
                title: 'Thông tin mẫu / Sample Information',
                number: 2,
                icon: Icons.science_outlined,
                children: [
                  InfoRow(
                    'Tổng số mẫu / Total number of samples',
                    '${d.totalSampleCount}',
                  ),
                  InfoRow('Ngày lấy mẫu / Sampling date', d.samplingDate),
                  InfoRow(
                    'Ngày nhận mẫu / Sample receipt date',
                    d.sampleReceiptDate,
                  ),
                  InfoRow('Ngày trả kết quả / Date report', d.reportDate),
                  InfoRow(
                    'Thời gian thử nghiệm / Testing time',
                    [
                      formatVn(d.testingDateStart),
                      formatVn(d.testingDateEnd),
                    ].where((s) => s.isNotEmpty).join(' — '),
                  ),
                ],
              ),
              LineTable(
                title: 'Danh sách mẫu',
                icon: Icons.list_alt_outlined,
                columns: const [
                  LineCol('Tên mẫu', width: 150),
                  LineCol('Mã số mẫu', width: 110),
                  LineCol('Mã hóa mẫu', width: 150),
                  LineCol('Tình trạng', width: 130),
                  LineCol('Bao gói', width: 100),
                  LineCol('KL', width: 60, numeric: true),
                  LineCol('Đơn vị', width: 70),
                  LineCol('Lưu mẫu', width: 130),
                ],
                rows: [
                  for (final l in d.sampleLines)
                    [
                      l.sampleName,
                      l.sampleIdCode,
                      l.sampleCodingDisplay,
                      l.sampleStatus,
                      l.packing,
                      l.sampleWeight > 0 ? '${l.sampleWeight}' : '',
                      l.packingUnit,
                      l.storage,
                    ],
                ],
              ),
              InfoSection(
                title: 'Kết quả thử nghiệm / Test Result',
                number: 3,
                icon: Icons.assignment_turned_in_outlined,
                children: [
                  InfoRow('Tên mẫu / Sample name', d.sampleName),
                  InfoRow(
                    'Mã hóa mẫu / Laboratory sample code',
                    d.sampleCodingDisplay,
                    mono: true,
                  ),
                  InfoRow(
                    'Mã số mẫu / Sample ID',
                    d.sampleIdCodeDisplay,
                    mono: true,
                  ),
                ],
              ),
              LineTable(
                title: 'Bảng kết quả',
                icon: Icons.table_chart_outlined,
                columns: const [
                  LineCol('Chỉ tiêu', width: 150),
                  LineCol('Phương pháp', width: 140),
                  LineCol('LOD', width: 70, numeric: true),
                  LineCol('Kết quả', width: 90, numeric: true),
                  LineCol('Đơn vị', width: 70),
                  LineCol('Ghi chú', width: 150),
                ],
                rows: [
                  for (final l in d.resultLines)
                    [
                      l.parameterName,
                      l.methodName,
                      l.lod > 0 ? '${l.lod}' : '',
                      l.result,
                      l.unitName == '-' ? '' : l.unitName,
                      l.remark,
                    ],
                ],
              ),
              InfoSection(
                title: 'Ký duyệt',
                number: 4,
                icon: Icons.draw_outlined,
                children: [
                  InfoRow(
                    'Trưởng phòng thí nghiệm / Head of Laboratory',
                    d.labManagerName,
                  ),
                  InfoRow('Ngày TP Lab ký', formatVn(d.labManagerSignedOn)),
                  InfoRow(
                    [
                      d.signerTitleVi,
                      d.signerTitleEn,
                    ].where((s) => s.isNotEmpty).join(' / '),
                    d.directorName,
                  ),
                  InfoRow(
                    'Ngày người ký duyệt ký',
                    formatVn(d.directorSignedOn),
                  ),
                ],
              ),
              if (d.state == 'cancel' && d.cancelReason.isNotEmpty)
                InfoSection(
                  title: 'Hủy',
                  icon: Icons.cancel_outlined,
                  children: [
                    InfoRow(
                      'Lý do hủy',
                      d.cancelReason,
                      valueColor: AppColors.danger,
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (actions.isNotEmpty) _buildActionBar(actions),
      ],
    );
  }

  Widget _buildActionBar(List<_ReportAction> actions) {
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
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _actionButton(actions[i])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton(_ReportAction action) {
    final spinner = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(
          action.destructive ? AppColors.danger : Colors.white,
        ),
      ),
    );
    final onPressed = _busy ? null : () => _runAction(action);
    if (action.destructive) {
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
        child: _busy
            ? spinner
            : Text(
                action.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
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
      child: _busy
          ? spinner
          : Text(
              action.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    );
  }
}

import '../widgets/module_list_scaffold.dart';
import '../services/search_spec_service.dart';
import '../widgets/record_card.dart';
import 'package:flutter/material.dart';
import '../utils/vn_format.dart';
import '../config.dart';
import '../models/sample_retention.dart';
import '../services/sample_retention_service.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_kit.dart';
import '../widgets/odoo_web_clone.dart';
import '../widgets/paged_list.dart';
import '../widgets/states.dart';

/// ───────── Tiện ích hiển thị chung (read-only) ─────────

Color _destructionStateColor(String state) {
  switch (state) {
    case 'done':
      return AppColors.success;
    case 'cancel':
      return AppColors.danger;
    case 'draft':
      return AppColors.warning;
    default:
      return AppColors.inkMuted;
  }
}

/// ───────── Danh sách mẫu lưu ─────────

/// List "Mẫu lưu" dạng card. Search + Bộ lọc/Nhóm theo (search view Odoo) +
/// phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class RetainedSampleListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const RetainedSampleListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final service = SampleRetentionService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<RetainedSampleBrief>(
      title: 'Mẫu lưu',
      permissionModel: 'etech.retained.sample',
      searchSpec: () =>
          SearchSpecService.load(sessionId, 'etech.retained.sample'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm mã mẫu, khách hàng…',
      unitLabel: 'mẫu',
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: 'Chưa có mẫu lưu nào',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getRetainedSamples(
            query: query,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, s) => RecordCard(
        title: s.codedSample,
        state: s.state,
        stateLabel: s.stateLabel,
        subtitle: s.partnerName,
        refs: [
          (Icons.scale_outlined, '${s.retainWeight} g'),
          (Icons.inventory_2_outlined, '${s.retainCount} mẫu'),
          (
            Icons.event_busy_outlined,
            s.expiryAt.isEmpty ? '' : 'Hết hạn ${s.expiryAt}',
          ),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RetainedSampleDetailScreen(
              sessionId: sessionId,
              sampleId: s.id,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [RetainedSampleListScreen]).
// TODO: xoá khi chốt dùng bản card.
class RetainedSampleTreeListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const RetainedSampleTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<RetainedSampleTreeListScreen> createState() =>
      _RetainedSampleTreeListScreenState();
}

class _RetainedSampleTreeListScreenState
    extends State<RetainedSampleTreeListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = SampleRetentionService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Mẫu lưu',
      primaryButtonLabel: 'Mới',
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooTreeListView<RetainedSampleBrief>(
        showSearch: _search,
        searchHint: 'Tìm mã mẫu, khách hàng…',
        emptyIcon: Icons.inventory_2_outlined,
        emptyTitle: 'Chưa có mẫu lưu nào',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getRetainedSamples(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        onTapRow: (context, s) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RetainedSampleDetailScreen(
              sessionId: widget.sessionId,
              sampleId: s.id,
            ),
          ),
        ),
        columns: [
          OdooTreeColumn(
            label: 'Mã mẫu',
            width: 160,
            link: true,
            linkColor: kOdooBlue,
            value: (s) => s.codedSample,
          ),
          OdooTreeColumn(
            label: 'Khách hàng',
            width: 160,
            link: true,
            value: (s) => s.partnerName,
          ),
          OdooTreeColumn(
            label: 'KL lưu (g)',
            width: 90,
            value: (s) => '${s.retainWeight}',
          ),
          OdooTreeColumn(
            label: 'Số mẫu',
            width: 70,
            value: (s) => '${s.retainCount}',
          ),
          OdooTreeColumn(
            label: 'Hết hạn',
            width: 110,
            value: (s) => s.expiryAt,
          ),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 110,
            value: (s) => s.stateLabel,
          ),
        ],
      ),
    );
  }
}

/// ───────── Chi tiết mẫu lưu ─────────

class RetainedSampleDetailScreen extends StatefulWidget {
  final String sessionId;
  final int sampleId;
  const RetainedSampleDetailScreen({
    super.key,
    required this.sessionId,
    required this.sampleId,
  });

  @override
  State<RetainedSampleDetailScreen> createState() =>
      _RetainedSampleDetailScreenState();
}

class _RetainedSampleDetailScreenState
    extends State<RetainedSampleDetailScreen> {
  late final SampleRetentionService _service;
  late Future<RetainedSampleDetail> _future;

  @override
  void initState() {
    super.initState();
    _service = SampleRetentionService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    _future = _service.getRetainedSample(widget.sampleId);
  }

  void _reload() =>
      setState(() => _future = _service.getRetainedSample(widget.sampleId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Chi tiết mẫu lưu')),
      body: FutureBuilder<RetainedSampleDetail>(
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
            header: OdooFormHeader(
              stateLabel: r.stateLabel,
              title: 'MẪU LƯU',
              subtitle: [HeaderSub('Mã mẫu', r.codedSample)],
              createdBy: r.createdBy,
              createdAt: metaDt(r.createdAt),
              updatedBy: r.updatedBy,
              updatedAt: metaDt(r.updatedAt),
            ),
            children: [
              InfoSection(
                title: 'Thông tin lưu',
                number: 1,
                children: [
                  InfoRow(
                    'Số lượng',
                    r.retainCount > 0 ? '${r.retainCount}' : '',
                  ),
                  InfoRow(
                    'Khối lượng (gram)',
                    r.retainWeight > 0 ? '${r.retainWeight}' : '',
                  ),
                  InfoRow('Điều kiện bảo quản', r.preservation, radio: true),
                  InfoRow('Chính sách lưu mẫu', r.retentionPolicy, radio: true),
                ],
              ),
              InfoSection(
                title: 'Hạn lưu / Hủy mẫu',
                number: 2,
                children: [
                  InfoRow('Giờ trả phiếu', r.reportReturnedAt),
                  InfoRow('Ngày hết hạn lưu', r.expiryAt),
                  InfoRow('Biên bản hủy mẫu', r.destructionName, mono: true),
                  InfoRow('Ngày hủy mẫu', r.destructionDate),
                ],
              ),
              InfoSection(
                title: 'Nguồn',
                number: 3,
                children: [
                  InfoRow(
                    'Phiếu yêu cầu phân tích',
                    r.analysisRequestName,
                    mono: true,
                  ),
                  InfoRow(
                    'Phiếu yêu cầu thử nghiệm',
                    r.serviceRequestCode,
                    mono: true,
                  ),
                  InfoRow('Khách hàng', r.partnerName),
                  InfoRow('Phiếu kết quả', r.testReportCode, mono: true),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ───────── Danh sách biên bản hủy mẫu ─────────

const List<MapEntry<String, String>> _destructionStateFilters = [
  MapEntry('', 'Tất cả'),
  MapEntry('draft', 'Nháp'),
  MapEntry('done', 'Đã hủy'),
  MapEntry('cancel', 'Đã hủy bỏ'),
];

class DestructionListScreen extends StatelessWidget {
  final String sessionId;
  const DestructionListScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final service = SampleRetentionService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Biên bản hủy mẫu')),
      body: PagedListView<DestructionBrief>(
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getDestructions(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        stateFilters: _destructionStateFilters,
        searchHint: 'Tìm số biên bản…',
        unitLabel: 'biên bản',
        emptyIcon: Icons.delete_outline_rounded,
        emptyTitle: 'Chưa có biên bản nào',
        emptyMessage: 'Biên bản hủy mẫu sẽ hiển thị tại đây.',
        itemBuilder: (context, rec) => ListCard(
          title: rec.name,
          stateLabel: rec.stateLabel,
          stateColor: _destructionStateColor(rec.state),
          meta: [
            ListMeta(
              Icons.event_outlined,
              '${rec.destructionDate}  •  ${rec.sampleCount} mẫu',
            ),
            if (rec.destroyerName.isNotEmpty)
              ListMeta(Icons.person_outline_rounded, rec.destroyerName),
          ],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DestructionDetailScreen(
                sessionId: sessionId,
                destructionId: rec.id,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ───────── Chi tiết biên bản hủy mẫu ─────────

class DestructionDetailScreen extends StatefulWidget {
  final String sessionId;
  final int destructionId;
  const DestructionDetailScreen({
    super.key,
    required this.sessionId,
    required this.destructionId,
  });

  @override
  State<DestructionDetailScreen> createState() =>
      _DestructionDetailScreenState();
}

class _DestructionDetailScreenState extends State<DestructionDetailScreen> {
  late final SampleRetentionService _service;
  late Future<DestructionDetail> _future;

  @override
  void initState() {
    super.initState();
    _service = SampleRetentionService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    _future = _service.getDestruction(widget.destructionId);
  }

  void _reload() =>
      setState(() => _future = _service.getDestruction(widget.destructionId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Chi tiết biên bản')),
      body: FutureBuilder<DestructionDetail>(
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
              stateLabel: r.stateLabel,
              stateColor: _destructionStateColor(r.state),
            ),
            children: [
              InfoSection(
                title: 'Thông tin biên bản',
                icon: Icons.description_outlined,
                number: 1,
                children: [
                  InfoRow('Ngày hủy mẫu', r.destructionDate),
                  InfoRow('Phương pháp hủy', r.method),
                  InfoRow('Người hủy mẫu', r.destroyerName),
                  InfoRow('Số mẫu', '${r.sampleCount}'),
                  InfoRow('Thời điểm xác nhận', r.destroyedAt),
                  InfoRow('Ghi chú', r.note),
                ],
              ),
              _DestructionLinesSection(lines: r.lines),
            ],
          );
        },
      ),
    );
  }
}

/// Danh sách mẫu hủy trong biên bản — nhóm one2many dạng thẻ dòng.
class _DestructionLinesSection extends StatelessWidget {
  final List<DestructionLine> lines;
  const _DestructionLinesSection({required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return LineTable(
      title: 'Mẫu hủy',
      icon: Icons.inventory_2_outlined,
      number: 2,
      columns: const [
        LineCol('Mã mẫu', width: 130),
        LineCol('Khách hàng', width: 150),
        LineCol('SL', width: 50, numeric: true),
        LineCol('KL (g)', width: 70, numeric: true),
        LineCol('Hết hạn lưu', width: 130),
        LineCol('Trạng thái', width: 104),
      ],
      rows: [
        for (final l in lines)
          [
            l.codedSample,
            l.partnerName,
            l.retainCount > 0 ? '${l.retainCount}' : '',
            l.retainWeight > 0 ? '${l.retainWeight}' : '',
            l.expiryAt,
            l.stateLabel,
          ],
      ],
    );
  }
}

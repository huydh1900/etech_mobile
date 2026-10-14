import '../services/search_spec_service.dart';
import '../widgets/record_card.dart';
import 'package:flutter/material.dart';
import '../utils/vn_format.dart';
import '../config.dart';
import '../models/sampling.dart';
import '../services/sampling_service.dart';
import '../widgets/detail_kit.dart';
import '../widgets/odoo_web_clone.dart';
import '../widgets/module_list_scaffold.dart';
import '../widgets/paged_list.dart' show PagedFetch;

/// List "Kế hoạch lấy mẫu" dạng card. Search + Bộ lọc/Nhóm theo (search view
/// Odoo) + phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class SamplingProgramListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  /// Tiêu đề màn — đổi theo menu con backend đang mở.
  final String title;

  /// Phạm vi lọc SERVER-side: `my` / `need_schedule` (null → mặc định backend).
  final String? scope;

  const SamplingProgramListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
    this.title = 'Kế hoạch lấy mẫu',
    this.scope,
  });

  @override
  Widget build(BuildContext context) {
    final service = SamplingService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<SamplingProgram>(
      title: title,
      permissionModel: 'etech.sampling.program',
      searchSpec: () =>
          SearchSpecService.load(sessionId, 'etech.sampling.program'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm mã, khách hàng, mẫu…',
      unitLabel: 'kế hoạch',
      emptyIcon: Icons.event_busy_outlined,
      emptyTitle: 'Không có kế hoạch',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getPrograms(
            query: query,
            scope: scope,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, p) => RecordCard(
        title: p.code,
        state: p.state,
        stateLabel: p.stateLabel,
        subtitle: p.partnerName,
        note: p.sampleName,
        refs: [
          (Icons.place_outlined, p.samplingLocation),
          (Icons.event_outlined, p.scheduled),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SamplingProgramDetailScreen(
              sessionId: sessionId,
              programId: p.id,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [SamplingProgramListScreen]).
// TODO: xoá khi chốt dùng bản card.
class SamplingProgramTreeListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  /// Tiêu đề màn — đổi theo menu con backend đang mở.
  final String title;

  /// Phạm vi lọc SERVER-side: `my` / `need_schedule` (null → mặc định backend).
  final String? scope;

  const SamplingProgramTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
    this.title = 'Kế hoạch lấy mẫu',
    this.scope,
  });

  @override
  State<SamplingProgramTreeListScreen> createState() =>
      _SamplingProgramTreeListScreenState();
}

class _SamplingProgramTreeListScreenState extends State<SamplingProgramTreeListScreen> {
  /// Ô tìm kiếm hiện sẵn khi mở màn (kính lúp vẫn dùng để ẩn/hiện lại).
  bool _search = true;

  /// Nguồn dữ liệu dùng chung cho cả 2 chế độ hiển thị (lọc/paging server-side).
  PagedFetch<SamplingProgram> _fetch(SamplingService service) =>
      ({state, query, required offset, required limit, params}) =>
          service.getPrograms(
            state: state,
            query: query,
            scope: widget.scope,
            offset: offset,
            limit: limit,
          );

  void _openDetail(BuildContext context, int id) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SamplingProgramDetailScreen(
        sessionId: widget.sessionId,
        programId: id,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final service = SamplingService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: widget.title,
      permissionModel: 'etech.sampling.program',
      // Màn chỉ để tra cứu: ẩn cụm icon Odoo web (tin nhắn/chuông/avatar),
      // nút "Mới" và nút bánh răng — chỉ giữ tìm kiếm.
      showAppBarActions: false,
      showSettingsButton: false,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      body: OdooTreeListView<SamplingProgram>(
        showSearch: _search,
        searchHint: 'Tìm mã, khách hàng, mẫu…',
        emptyIcon: Icons.event_busy_outlined,
        emptyTitle: 'Không có kế hoạch',
        fetch: _fetch(service),
        onTapRow: (context, p) => _openDetail(context, p.id),
        columns: [
          OdooTreeColumn(
            label: 'Mã kế hoạch',
            width: 150,
            link: true,
            linkColor: kOdooBlue,
            value: (p) => p.code,
          ),
          OdooTreeColumn(
            label: 'Khách hàng',
            width: 160,
            link: true,
            value: (p) => p.partnerName,
          ),
          OdooTreeColumn(label: 'Mẫu', width: 150, value: (p) => p.sampleName),
          OdooTreeColumn(
            label: 'Địa điểm',
            width: 150,
            value: (p) => p.samplingLocation,
          ),
          OdooTreeColumn(
            label: 'Lịch lấy mẫu',
            width: 130,
            value: (p) => p.scheduled,
          ),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 130,
            value: (p) => p.stateLabel,
          ),
        ],
      ),
    );
  }
}

/// Chi tiết kế hoạch lấy mẫu — dùng [ModuleDetailScaffold] (đồng bộ với các
/// màn chi tiết module khác: tự lo skeleton/lỗi/retry).
class SamplingProgramDetailScreen extends StatelessWidget {
  final String sessionId;
  final int programId;
  const SamplingProgramDetailScreen({
    super.key,
    required this.sessionId,
    required this.programId,
  });

  @override
  Widget build(BuildContext context) {
    final service = SamplingService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleDetailScaffold<SamplingProgramDetail>(
      title: 'Kế hoạch lấy mẫu',
      load: () => service.getProgram(programId),
      builder: (context, p, reload) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            OdooFormHeader(
              stateLabel: p.stateLabel,
              state: p.state,
              // AppBar đã ghi "Kế hoạch lấy mẫu" → tiêu đề form dùng MÃ kế
              // hoạch cho khỏi lặp và biết ngay đang xem bản ghi nào.
              title: p.code.isEmpty ? 'KẾ HOẠCH LẤY MẪU' : p.code,
              subtitle: [HeaderSub('Hồ sơ', p.requestCode)],
              createdBy: p.createdBy,
              createdAt: metaDt(p.createdAt),
              updatedBy: p.updatedBy,
              updatedAt: metaDt(p.updatedAt),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
              child: Column(
                children: [
                  InfoSection(
                    title: 'Thông tin chung',
                    number: 1,
                    children: [
                      InfoRow('Mục đích thử nghiệm', p.testingPurpose),
                      InfoRow('Tên khách hàng', p.partnerName),
                      InfoRow('Địa chỉ khách hàng', p.customerAddress),
                      InfoRow(
                        'Địa điểm và địa chỉ lấy mẫu',
                        p.samplingLocation,
                      ),
                      InfoRow('Người liên hệ', p.contactName),
                      InfoRow('Số điện thoại', p.contactPhone),
                      InfoRow('Thời gian dự kiến lấy mẫu', p.scheduled),
                      InfoChips('Trưởng nhóm', p.teamLeaders),
                      InfoChips('Phó nhóm', p.deputyLeaders),
                      InfoChips('Người lấy mẫu', p.members),
                      InfoRow('Biển số xe', p.vehiclePlate),
                      InfoRow('Mã vùng trồng', p.plantingAreaCode),
                      InfoRow('Mã số container', p.containerCode),
                      InfoRow('Mã cơ sở đóng gói', p.packingFacilityCode),
                      InfoRow('Biển số Rmooc', p.trailerPlate),
                      InfoRow(
                        'Số mẫu thử nghiệm',
                        p.sampleCount > 0 ? '${p.sampleCount}' : '',
                      ),
                      InfoRow(
                        'Khối lượng mẫu ban đầu',
                        p.initialSampleWeight > 0
                            ? '${p.initialSampleWeight} ${p.initialSampleUom}'
                            : '',
                      ),
                      // Khối "Mã mẫu ban đầu" của Odoo: mã mẹ căn giữa
                      // (xanh) + các mã con dạng tag ngay dưới.
                      InfoCodeTree(
                        'Mã mẫu ban đầu',
                        parent: p.parentSampleCode,
                        children: p.initialSampleCodes,
                      ),
                      InfoRow(
                        'Xử lý khối lượng mẫu dư',
                        p.excessSampleHandling,
                      ),
                      InfoRow('Tên mẫu', p.sampleName),
                      InfoRow('Loại mẫu', p.sampleType),
                    ],
                  ),
                  // II. Thông số phân tích tại PTN nội bộ (is_outsourced = false)
                  LineTable(
                    title:
                        'Danh mục thông số - phương pháp phân tích trong '
                        'phòng thí nghiệm',
                    number: 2,
                    columns: const [
                      LineCol('Chỉ tiêu cần phân tích', width: 200),
                      LineCol('Đơn vị', width: 90),
                      LineCol('Tên/Số hiệu phương pháp sử dụng', width: 220),
                    ],
                    rows: [
                      for (final pr in p.parameters.where(
                        (e) => !e.isOutsourced,
                      ))
                        [pr.parameter, pr.unit, pr.method],
                    ],
                    showWhenEmpty: true,
                  ),
                  // III. Thông số do đơn vị thầu phụ thực hiện
                  LineTable(
                    title:
                        'Danh mục thông số thực hiện phân tích bởi đơn vị '
                        'thầu phụ',
                    number: 3,
                    columns: const [
                      LineCol('Chỉ tiêu cần phân tích', width: 200),
                      LineCol('Đơn vị', width: 90),
                      LineCol('Tên/Số hiệu phương pháp sử dụng', width: 220),
                      LineCol('Thiết bị phân tích', width: 170),
                    ],
                    rows: [
                      for (final pr in p.parameters.where(
                        (e) => e.isOutsourced,
                      ))
                        [pr.parameter, pr.unit, pr.method, pr.analyzerDevice],
                    ],
                    showWhenEmpty: true,
                  ),
                  // IV. Phương pháp lấy mẫu — bảng + 3 dòng đánh số như Odoo.
                  LineTable(
                    title: 'Phương pháp lấy mẫu',
                    number: 4,
                    columns: const [
                      LineCol('Loại mẫu', width: 170),
                      LineCol('Tên/số hiệu phương pháp', width: 240),
                    ],
                    rows: [
                      for (final m in p.methods) [m.sampleType, m.method],
                    ],
                    showWhenEmpty: true,
                    extra: [
                      InfoRow(
                        'Thiết bị lấy mẫu, bảo quản mẫu',
                        p.samplingEquipment,
                        index: 2,
                      ),
                      InfoCheckboxGroup(
                        'Phương tiện phục vụ hoạt động: lấy mẫu, bảo quản '
                        'và vận chuyển mẫu',
                        options: p.transportModeOptions,
                        selected: p.transportModes,
                        index: 3,
                      ),
                      const InfoRow(
                        'Danh mục máy móc thiết bị được bảo trì bảo dưỡng, '
                            'kiểm định, hiệu chuẩn đúng theo quy định',
                        '',
                        index: 4,
                      ),
                    ],
                  ),
                  // V. Tiêu chuẩn so sánh
                  InfoSection(
                    title: 'Tiêu chuẩn so sánh',
                    number: 5,
                    children: [
                      InfoRadioGroup(
                        'Tiêu chuẩn so sánh',
                        options: p.comparisonStandardOptions,
                        selected: p.comparisonStandardType,
                      ),
                      if (p.comparisonStandard.isNotEmpty)
                        InfoRow('Nội dung TCSS', p.comparisonStandard),
                    ],
                  ),
                  if (p.reports.isNotEmpty)
                    LineTable(
                      title: 'Biên bản hiện trường',
                      number: 6,
                      columns: const [
                        LineCol('Mã biên bản', width: 150),
                        LineCol('Trạng thái', width: 120),
                      ],
                      rows: [
                        for (final rp in p.reports) [rp.code, rp.stateLabel],
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

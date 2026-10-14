import '../widgets/module_list_scaffold.dart';
import '../services/search_spec_service.dart';
import '../widgets/record_card.dart';
import 'package:flutter/material.dart';
import '../utils/vn_format.dart';
import '../config.dart';
import '../models/service_request.dart';
import '../services/service_request_service.dart';
import '../widgets/paged_list.dart';
import '../theme/app_theme.dart';
import '../widgets/states.dart';
import '../widgets/detail_kit.dart';
import '../widgets/odoo_web_clone.dart';

/// ───────── Danh sách phiếu yêu cầu ─────────

/// List "Phiếu yêu cầu" dạng card. Search + Bộ lọc/Nhóm theo (search view Odoo) +
/// phân trang do [ModuleListScaffold] lo — màn chỉ khai báo card.
class ServiceRequestListScreen extends StatelessWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const ServiceRequestListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final service = ServiceRequestService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleListScaffold<ServiceRequestBrief>(
      title: 'Phiếu yêu cầu',
      permissionModel: 'etech.service.request',
      searchSpec: () =>
          SearchSpecService.load(sessionId, 'etech.service.request'),
      onOpenNotifications: onOpenNotifications,
      searchHint: 'Tìm mã hồ sơ, khách hàng, loại mẫu…',
      unitLabel: 'hồ sơ',
      emptyIcon: Icons.description_outlined,
      emptyTitle: 'Chưa có hồ sơ nào',
      fetch: ({state, query, required offset, required limit, params}) =>
          service.getRequests(
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
        tag: r.sampleType,
        note: r.samplingLocation,
        refs: [
          (Icons.event_outlined, r.requestDate),
          (Icons.inventory_2_outlined, '${r.totalSampleQty} mẫu'),
        ],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceRequestDetailScreen(
              sessionId: sessionId,
              requestId: r.id,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bản list dạng bảng clone Odoo web (giữ lại để so sánh với [ServiceRequestListScreen]).
// TODO: xoá khi chốt dùng bản card.
class ServiceRequestTreeListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const ServiceRequestTreeListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<ServiceRequestTreeListScreen> createState() =>
      _ServiceRequestTreeListScreenState();
}

class _ServiceRequestTreeListScreenState
    extends State<ServiceRequestTreeListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = ServiceRequestService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Phiếu yêu cầu',
      primaryButtonLabel: 'Mới',
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooTreeListView<ServiceRequestBrief>(
        showSearch: _search,
        searchHint: 'Tìm mã hồ sơ, khách hàng, loại mẫu…',
        emptyIcon: Icons.description_outlined,
        emptyTitle: 'Chưa có hồ sơ nào',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getRequests(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        onTapRow: (context, r) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceRequestDetailScreen(
              sessionId: widget.sessionId,
              requestId: r.id,
            ),
          ),
        ),
        columns: [
          OdooTreeColumn(
            label: 'Mã hồ sơ',
            width: 150,
            link: true,
            linkColor: kOdooBlue,
            value: (r) => r.code,
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
          OdooTreeColumn(
            label: 'Ngày yêu cầu',
            width: 110,
            value: (r) => r.requestDate,
          ),
          OdooTreeColumn(
            label: 'Số mẫu',
            width: 70,
            value: (r) => '${r.totalSampleQty}',
          ),
          OdooTreeColumn(
            label: 'Trạng thái',
            width: 120,
            value: (r) => r.stateLabel,
          ),
        ],
      ),
    );
  }
}

/// ───────── Chi tiết phiếu yêu cầu ─────────

class ServiceRequestDetailScreen extends StatefulWidget {
  final String sessionId;
  final int requestId;
  const ServiceRequestDetailScreen({
    super.key,
    required this.sessionId,
    required this.requestId,
  });

  @override
  State<ServiceRequestDetailScreen> createState() =>
      _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState
    extends State<ServiceRequestDetailScreen> {
  late final ServiceRequestService _service;
  late Future<ServiceRequestDetail> _future;

  @override
  void initState() {
    super.initState();
    _service = ServiceRequestService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    _future = _service.getRequest(widget.requestId);
  }

  void _reload() =>
      setState(() => _future = _service.getRequest(widget.requestId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Chi tiết hồ sơ')),
      body: FutureBuilder<ServiceRequestDetail>(
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
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              OdooFormHeader(
                stateLabel: r.stateLabel,
                title: 'HỒ SƠ YÊU CẦU DỊCH VỤ',
                subtitle: [HeaderSub('Mã hồ sơ', r.requestCode)],
                createdBy: r.createdBy,
                createdAt: metaDt(r.createdAt),
                updatedBy: r.updatedBy,
                updatedAt: metaDt(r.updatedAt),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoSection(
                      title: 'Thông tin khách hàng',
                      icon: Icons.business_outlined,
                      number: 1,
                      children: [
                        InfoRow('Tên khách hàng (Tiếng Việt)', r.partnerName),
                        InfoRow('Tên khách hàng (Tiếng Anh)', r.partnerNameEn),
                        InfoRow('Mã số thuế', r.partnerVat, mono: true),
                        InfoRow(
                          'Người đại diện theo pháp luật',
                          r.partnerLegalRepresentative,
                        ),
                        InfoRow('Số hợp đồng (nếu có)', r.contractNumber),
                        InfoRow('Chức vụ', r.partnerFunction),
                        InfoRow('Địa chỉ', r.address),
                        InfoRow('Người liên hệ (KH)', r.partnerContactPerson),
                        InfoRow('Người liên hệ', r.contactName),
                        InfoRow('Số điện thoại', r.phone),
                        InfoRow('Email', r.email),
                        InfoRow('Ngày yêu cầu', r.requestDate),
                        InfoRow('Địa điểm lập phiếu', r.signingLocation),
                      ],
                    ),
                    InfoSection(
                      title: 'Thông tin phát hành hóa đơn',
                      icon: Icons.receipt_long_outlined,
                      number: 2,
                      children: [
                        InfoRow('Tên công ty', r.invoiceCompanyName),
                        InfoRow('Địa chỉ', r.invoiceAddress),
                        InfoRow('Mã số thuế', r.invoiceVat, mono: true),
                        InfoRow('Email', r.invoiceEmail),
                      ],
                    ),
                    InfoSection(
                      title: 'Thông tin về mẫu',
                      icon: Icons.science_outlined,
                      number: 3,
                      children: [
                        InfoRow('Địa điểm lấy mẫu', r.samplingLocation),
                        InfoRow(
                          'Mã cơ sở đóng gói',
                          r.packingFacilityCode,
                          mono: true,
                        ),
                        InfoRow('Mã vùng trồng', r.growingAreaCode, mono: true),
                        InfoRow('Biển số xe', r.vehiclePlate, mono: true),
                        InfoRow('Biển số Rmooc', r.rmoocNumber, mono: true),
                        InfoRow(
                          'Mã số container',
                          r.containerNumber,
                          mono: true,
                        ),
                        InfoRow(
                          'Thời gian dự kiến lấy mẫu',
                          r.expectedSamplingDate,
                        ),
                        InfoRow('Loại mẫu', r.sampleType, radio: true),
                        InfoRow(
                          'Mục đích thử nghiệm',
                          r.testingPurpose,
                          radio: true,
                        ),
                        InfoRow('Khác', r.testingPurposeOther),
                      ],
                    ),
                    _RequestLinesSection(lines: r.lines),
                    InfoSection(
                      title: 'Yêu cầu dịch vụ',
                      icon: Icons.biotech_outlined,
                      number: 5,
                      children: [
                        InfoRow(
                          'Phương pháp được công nhận',
                          r.certifiedMethod,
                          radio: true,
                        ),
                        InfoRow(
                          'Sử dụng thầu phụ',
                          r.subcontractorUse,
                          radio: true,
                        ),
                        InfoRow(
                          'Ngôn ngữ kết quả',
                          r.resultLanguage,
                          radio: true,
                        ),
                        InfoRow('Lưu mẫu', r.sampleRetention, radio: true),
                        InfoRow(
                          'Xử lý mẫu dư',
                          r.excessSampleHandling,
                          radio: true,
                        ),
                        InfoRow(
                          'Thời gian phân tích',
                          r.analysisTime,
                          radio: true,
                        ),
                        InfoRow(
                          'Thời gian mong muốn',
                          r.desiredAnalysisDatetime,
                        ),
                        InfoRow('Giao kết quả', r.resultDelivery, radio: true),
                        InfoRow(
                          'Phương thức thanh toán',
                          r.paymentMethod,
                          radio: true,
                        ),
                        InfoRow(
                          'Thời điểm xuất hóa đơn',
                          r.invoiceTiming,
                          radio: true,
                        ),
                        InfoRow('Người lập', r.userName),
                        InfoRow('Phòng ban', r.departmentName),
                        InfoRow('Tổng SL mẫu', '${r.totalSampleQty}'),
                      ],
                    ),
                    if (r.rejectReason.isNotEmpty)
                      InfoSection(
                        title: 'Lý do từ chối',
                        icon: Icons.block_outlined,
                        number: 6,
                        children: [
                          InfoRow(
                            'Lý do',
                            r.rejectReason,
                            valueColor: AppColors.danger,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RequestLinesSection extends StatelessWidget {
  final List<ServiceRequestLine> lines;
  const _RequestLinesSection({required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return LineTable(
      title: 'Chi tiết yêu cầu',
      icon: Icons.list_alt_outlined,
      number: 4,
      columns: const [
        LineCol('Tên mẫu', width: 140),
        LineCol('Loại mẫu', width: 130),
        LineCol('Chỉ tiêu', width: 150),
        LineCol('Phương pháp', width: 150),
        LineCol('SL', width: 64, numeric: true),
        LineCol('Ghi chú', width: 150),
      ],
      rows: [
        for (final l in lines)
          [
            l.name,
            l.sampleType,
            l.parameters.join(', '),
            l.methods.join(', '),
            '${l.sampleQty}',
            l.note,
          ],
      ],
    );
  }
}

/// ───────── Danh sách khách hàng ─────────

class CustomerListScreen extends StatelessWidget {
  final String sessionId;
  const CustomerListScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final service = ServiceRequestService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Khách hàng')),
      body: PagedListView<CustomerBrief>(
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getCustomers(query: query, offset: offset, limit: limit),
        searchHint: 'Tìm theo tên / MST…',
        unitLabel: 'khách hàng',
        emptyIcon: Icons.groups_outlined,
        emptyTitle: 'Không có khách hàng',
        emptyMessage: 'Chưa có khách hàng nào trên hồ sơ.',
        itemBuilder: (context, c) => ListCard(
          title: c.name,
          meta: [
            ListMeta(
              c.isCompany ? Icons.business_outlined : Icons.person_outline,
              c.isCompany ? 'Tổ chức' : 'Cá nhân',
            ),
            if (c.vat.isNotEmpty) ListMeta(Icons.badge_outlined, c.vat),
            if (c.phone.isNotEmpty) ListMeta(Icons.phone_outlined, c.phone),
            if (c.city.isNotEmpty) ListMeta(Icons.location_on_outlined, c.city),
          ],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CustomerDetailScreen(sessionId: sessionId, partnerId: c.id),
            ),
          ),
        ),
      ),
    );
  }
}

/// ───────── Chi tiết khách hàng ─────────

class CustomerDetailScreen extends StatefulWidget {
  final String sessionId;
  final int partnerId;
  const CustomerDetailScreen({
    super.key,
    required this.sessionId,
    required this.partnerId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late final ServiceRequestService _service;
  late Future<CustomerDetail> _future;

  @override
  void initState() {
    super.initState();
    _service = ServiceRequestService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    _future = _service.getCustomer(widget.partnerId);
  }

  void _reload() =>
      setState(() => _future = _service.getCustomer(widget.partnerId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Khách hàng')),
      body: FutureBuilder<CustomerDetail>(
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
          final c = snap.data!;
          final addr = [
            c.street,
            c.street2,
            c.city,
          ].where((s) => s.isNotEmpty).join(', ');
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    c.isCompany ? Icons.business_rounded : Icons.person_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  c.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppType.title,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InfoSection(
                title: 'Liên hệ',
                icon: Icons.info_outline_rounded,
                number: 1,
                children: [
                  InfoRow(
                    'Loại',
                    c.isCompany ? 'Tổ chức' : 'Cá nhân',
                    radio: true,
                  ),
                  InfoRow('Chức vụ', c.function),
                  InfoRow('Tổ chức', c.parentName),
                  InfoRow('MST', c.vat),
                  InfoRow('Điện thoại', c.phone),
                  InfoRow('Email', c.email),
                  InfoRow('Địa chỉ', addr),
                  InfoRow('Số hồ sơ', '${c.requestCount}'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

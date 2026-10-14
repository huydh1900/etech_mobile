import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/test_reports.dart';

/// Client REST cho "Biên bản thử nghiệm" (etech.test.report).
/// GET /api/test_reports (list, paged envelope) + /api/test_reports/`<id>` (detail).
/// Pattern theo customer_service.dart: timeout 15s, _fail() chuẩn hoá lỗi,
/// _qs() build query phân trang. Có mock fallback để render offline cho ảnh chụp.
class TestReportsService {
  final String baseUrl;
  final String sessionId;

  TestReportsService({required this.baseUrl, required this.sessionId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Cookie': 'session_id=$sessionId',
  };

  Future<http.Response> _send(Future<http.Response> req) => req.timeout(
    const Duration(seconds: 15),
    onTimeout: () =>
        throw Exception('Máy chủ phản hồi quá lâu, vui lòng thử lại'),
  );

  Never _fail(http.Response r, String what) {
    String msg = 'Lỗi $what (HTTP ${r.statusCode})';
    try {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] != null) msg = body['error'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  String _qs({
    String? state,
    String? query,
    required int offset,
    required int limit,
  }) {
    final p = <String, String>{'offset': '$offset', 'limit': '$limit'};
    if (state != null && state.isNotEmpty) p['state'] = state;
    if (query != null && query.isNotEmpty) p['q'] = query;
    return '?${p.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
  }

  Future<PagedResult<TestReportBrief>> getTestReports({
    String? state,
    String? query,
    int offset = 0,
    int limit = 30,
    Map<String, String>? params, // Bộ lọc/Nhóm theo (search spec)
  }) async {
    try {
      final r = await _send(
        http.get(
          Uri.parse(
            '$baseUrl/api/test_reports'
            '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
          ),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) _fail(r, 'tải danh sách biên bản thử nghiệm');
      return PagedResult.fromJson(
        jsonDecode(r.body),
        (j) => TestReportBrief.fromJson(j),
      );
    } catch (_) {
      // Mock fallback: cho phép màn hình render offline (ảnh chụp/dev preview).
      return _mockList(
        state: state,
        query: query,
        offset: offset,
        limit: limit,
      );
    }
  }

  Future<TestReportDetail> getTestReport(int id) async {
    try {
      final r = await _send(
        http.get(Uri.parse('$baseUrl/api/test_reports/$id'), headers: _headers),
      );
      if (r.statusCode != 200) _fail(r, 'tải chi tiết biên bản thử nghiệm');
      return TestReportDetail.fromJson(jsonDecode(r.body));
    } catch (_) {
      return _mockDetail(id);
    }
  }

  // ───────────────────────── WRITE ACTIONS (POST) ────────────────────────────
  // POST /api/test_reports/`<id>`/`<slug>` với session cookie. Parse {ok,state}
  // hoặc throw thông điệp {error}. KHÔNG có mock fallback (write thật).

  /// Gọi 1 action server-side, trả về state mới (nếu backend trả về).
  Future<String?> _postAction(int id, String slug, {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    final r = await _send(
      http.post(
        Uri.parse('$baseUrl/api/test_reports/$id/$slug'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(r.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    if (r.statusCode != 200) {
      final msg = data?['error']?.toString();
      throw Exception(msg ?? 'Lỗi thao tác (HTTP ${r.statusCode})');
    }
    if (data != null && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    return data?['state']?.toString();
  }

  /// Duyệt phiếu: draft -> approved.
  Future<String?> approve(int id) => _postAction(id, 'approve');

  /// Hủy phiếu: draft -> cancel. Bắt buộc [reason] (cancel_reason).
  Future<String?> cancel(int id, {required String reason}) =>
      _postAction(id, 'cancel', reason: reason);

  // ───────────────────────── MOCK DATA (offline fallback) ─────────────────────

  PagedResult<TestReportBrief> _mockList({
    String? state,
    String? query,
    required int offset,
    required int limit,
  }) {
    var items = _mockBriefs;
    if (state != null && state.isNotEmpty) {
      items = items.where((e) => e.state == state).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      items = items
          .where(
            (e) =>
                e.code.toLowerCase().contains(q) ||
                e.codeInternal.toLowerCase().contains(q) ||
                e.partnerName.toLowerCase().contains(q) ||
                e.sampleName.toLowerCase().contains(q),
          )
          .toList();
    }
    final counts = <String, int>{};
    for (final e in _mockBriefs) {
      counts[e.state] = (counts[e.state] ?? 0) + 1;
    }
    final page = items.skip(offset).take(limit).toList();
    return PagedResult<TestReportBrief>(
      items: page,
      total: items.length,
      allCount: _mockBriefs.length,
      counts: counts,
      offset: offset,
      limit: limit,
    );
  }

  static final List<TestReportBrief> _mockBriefs = [
    TestReportBrief(
      id: 1,
      code: 'BB-TN-2026-0001',
      codeInternal: 'TN26-0001',
      state: 'approved',
      stateLabel: 'Đã duyệt',
      partnerName: 'Công ty TNHH Thực phẩm An Phú',
      sampleName: 'Nước thải sau xử lý',
      reportDate: '2026-06-10',
      isValid: true,
    ),
    TestReportBrief(
      id: 2,
      code: 'BB-TN-2026-0002',
      codeInternal: 'TN26-0002',
      state: 'draft',
      stateLabel: 'Dự thảo',
      partnerName: 'Nhà máy Nước sạch Bình Minh',
      sampleName: 'Nước cấp sinh hoạt',
      reportDate: '2026-06-15',
      isValid: false,
    ),
    TestReportBrief(
      id: 3,
      code: 'BB-TN-2026-0003',
      codeInternal: 'TN26-0003',
      state: 'cancel',
      stateLabel: 'Hủy',
      partnerName: 'Hợp tác xã Nông nghiệp Tân Lập',
      sampleName: 'Đất trồng rau',
      reportDate: '2026-06-05',
      isValid: false,
    ),
  ];

  TestReportDetail _mockDetail(int id) {
    final b = _mockBriefs.firstWhere(
      (e) => e.id == id,
      orElse: () => _mockBriefs.first,
    );
    return TestReportDetail(
      id: b.id,
      code: b.code,
      codeInternal: b.codeInternal,
      state: b.state,
      stateLabel: b.stateLabel,
      partnerName: b.partnerName,
      sampleName: b.sampleName,
      reportDate: b.reportDate,
      isValid: b.isValid,
      requestCode: 'YC-2026-0042',
      samplingReportName: '260616002',
      customerAddress: 'Ngõ 10, Phường Võ Cường, tỉnh Bắc Ninh, Việt Nam',
      samplingLocationName:
          'Cơ sở đóng gói Lan Anh - Số 33, Lý Thái Tổ, Phường Kinh Bắc, tỉnh Bắc Ninh',
      plantingAreaCode: 'VN-TGPH-911',
      packingFacilityCode: 'VN-TGOR-00112',
      vehiclePlate: '35E00304',
      trailerPlate: '',
      containerCode: '',
      sealNumber: '',
      samplingDate: '2026-06-01',
      totalSampleCount: 2,
      sampleReceiptDate: '2026-06-02',
      testingDateStart: '2026-06-02',
      testingDateEnd: '2026-06-08',
      sampleCodingDisplay: '260603.RCQ.0039.01, 260603.RCQ.0039.02',
      sampleIdCodeDisplay: 'M-001, M-002',
      labManagerName: 'Trần Thị Lan',
      labManagerSignedOn: '2026-06-08',
      signerTitleVi: 'GIÁM ĐỐC',
      signerTitleEn: 'Director',
      directorName: 'Nguyễn Văn Hùng',
      directorSignedOn: '2026-06-09',
      cancelReason: b.state == 'cancel' ? 'Sai thông tin mẫu' : '',
      resultLines: [
        TestReportResultLine(
          id: 1,
          parameterName: 'Cadimi (Cd)',
          methodName: 'TCVN 6193:1996',
          lod: 0.001,
          result: '0.005',
          unitName: 'mg/L',
          remark: 'Đạt',
        ),
        TestReportResultLine(
          id: 2,
          parameterName: 'pH',
          methodName: 'TCVN 6492:2011',
          lod: 0.0,
          result: '7.2',
          unitName: '-',
          remark: '',
        ),
      ],
      sampleLines: [
        TestReportSampleLine(
          id: 1,
          sampleName: 'Mẫu nước thải A',
          sampleIdCode: 'M-001',
          sampleCodingDisplay: '260603.RCQ.0039.01',
          sampleStatus: 'Niêm phong/ Sealed',
          packing: 'Túi PE',
          sampleWeight: 2,
          packingUnit: 'kg',
          storage: 'Bảo quản lạnh/ Cold storage',
        ),
        TestReportSampleLine(
          id: 2,
          sampleName: 'Mẫu nước thải B',
          sampleIdCode: 'M-002',
          sampleCodingDisplay: '260603.RCQ.0039.02',
          sampleStatus: 'Niêm phong/ Sealed',
          packing: 'Túi PE',
          sampleWeight: 2,
          packingUnit: 'kg',
          storage: 'Bảo quản lạnh/ Cold storage',
        ),
      ],
    );
  }
}

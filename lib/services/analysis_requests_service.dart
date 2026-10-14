import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/analysis_requests.dart';

/// Client REST cho "Yêu cầu phân tích" — GET /api/analysis_requests (list) và
/// `/api/analysis_requests/<id>` (detail). Xác thực bằng cookie session_id.
///
/// Có fallback mock để màn hình/ảnh chụp chạy được khi backend offline (theo
/// yêu cầu): mọi lỗi mạng/HTTP đều rơi về dữ liệu mẫu thay vì ném ngoại lệ.
class AnalysisRequestsService {
  final String baseUrl;
  final String sessionId;

  AnalysisRequestsService({required this.baseUrl, required this.sessionId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Cookie': 'session_id=$sessionId',
  };

  Future<http.Response> _send(Future<http.Response> req) => req.timeout(
    const Duration(seconds: 15),
    onTimeout: () =>
        throw Exception('Máy chủ phản hồi quá lâu, vui lòng thử lại'),
  );

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

  Future<PagedResult<ArBrief>> getAnalysisRequests({
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
            '$baseUrl/api/analysis_requests'
            '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
          ),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) {
        throw Exception('Lỗi tải danh sách (HTTP ${r.statusCode})');
      }
      return PagedResult.fromJson(
        jsonDecode(r.body),
        (j) => ArBrief.fromJson(j),
      );
    } catch (_) {
      // Fallback mock để UI/ảnh chụp chạy offline.
      return _mockPage(
        state: state,
        query: query,
        offset: offset,
        limit: limit,
      );
    }
  }

  Future<ArDetail> getAnalysisRequest(int id) async {
    try {
      final r = await _send(
        http.get(
          Uri.parse('$baseUrl/api/analysis_requests/$id'),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) {
        throw Exception('Lỗi tải chi tiết (HTTP ${r.statusCode})');
      }
      return ArDetail.fromJson(jsonDecode(r.body));
    } catch (_) {
      return _mockDetail(id);
    }
  }

  // ── Write actions: POST /api/analysis_requests/<id>/<slug> ───────────────
  //
  // KHÁC với read methods (có mock fallback): action ghi dữ liệu nên KHÔNG
  // được nuốt lỗi — parse {ok, state} hoặc ném message từ {error}.

  /// Gọi 1 action theo slug. [reason] chỉ gửi khi action cần lý do (vd hủy).
  /// Trả về state mới (chuỗi rỗng nếu backend không trả state — vd action
  /// tạo mẻ/phiếu kết quả không đổi trạng thái record).
  Future<String> _postAction(int id, String slug, {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    // KHÔNG mock-fallback: lỗi mạng/timeout ném thẳng (message tiếng Việt từ
    // _send) để UI hiển thị trong SnackBar.
    final r = await _send(
      http.post(
        Uri.parse('$baseUrl/api/analysis_requests/$id/$slug'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );

    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(r.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      data = null;
    }

    if (r.statusCode != 200) {
      final msg = data?['error']?.toString();
      throw Exception(
        msg?.isNotEmpty == true
            ? msg
            : 'Thao tác thất bại (HTTP ${r.statusCode})',
      );
    }

    final err = data?['error']?.toString();
    if (err != null && err.isNotEmpty) throw Exception(err);
    if (data?['ok'] == false) {
      throw Exception('Thao tác không thành công');
    }
    return data?['state']?.toString() ?? '';
  }

  /// action_send — draft → sent.
  Future<String> send(int id) => _postAction(id, 'send');

  /// action_receive — sent → received (tự tạo mẫu lưu + ký tên người nhận).
  Future<String> receive(int id) => _postAction(id, 'receive');

  /// action_done — received → done.
  Future<String> done(int id) => _postAction(id, 'done');

  /// action_cancel — draft/sent/received → cancel. [reason] bắt buộc.
  Future<String> cancel(int id, String reason) =>
      _postAction(id, 'cancel', reason: reason);

  /// action_create_lab_batch — received/done; KHÔNG đổi state record.
  Future<String> createLabBatch(int id) => _postAction(id, 'create_lab_batch');

  /// action_create_test_report — done; KHÔNG đổi state record.
  Future<String> createTestReport(int id) =>
      _postAction(id, 'create_test_report');

  // ── Mock fallback data (chỉ dùng khi backend không sẵn sàng) ──────────────

  static final List<ArBrief> _mockData = [
    ArBrief(
      id: 1,
      name: 'YCPT-2026-0001',
      state: 'draft',
      stateLabel: 'Dự thảo',
      partnerName: 'Công ty CP Môi trường ABC',
      sampleType: 'Nước thải',
      sampleName: 'Mẫu nước thải đầu ra',
      receivedAt: '2026-06-15 09:20:00',
      analysisDoneAt: '',
    ),
    ArBrief(
      id: 2,
      name: 'YCPT-2026-0002',
      state: 'sent',
      stateLabel: 'Đã gửi yêu cầu',
      partnerName: 'Nhà máy XYZ',
      sampleType: 'Đất',
      sampleName: 'Mẫu đất khu vực 3',
      receivedAt: '2026-06-16 14:05:00',
      analysisDoneAt: '',
    ),
    ArBrief(
      id: 3,
      name: 'YCPT-2026-0003',
      state: 'received',
      stateLabel: 'Đã tiếp nhận mẫu',
      partnerName: 'Công ty TNHH Thực phẩm DEF',
      sampleType: 'Nước sạch',
      sampleName: 'Mẫu nước giếng khoan',
      receivedAt: '2026-06-17 08:00:00',
      analysisDoneAt: '',
    ),
    ArBrief(
      id: 4,
      name: 'YCPT-2026-0004',
      state: 'done',
      stateLabel: 'Đã hoàn thành phân tích',
      partnerName: 'Bệnh viện Đa khoa GHI',
      sampleType: 'Không khí',
      sampleName: 'Mẫu khí khu xử lý',
      receivedAt: '2026-06-14 10:30:00',
      analysisDoneAt: '2026-06-18 16:45:00',
    ),
  ];

  PagedResult<ArBrief> _mockPage({
    String? state,
    String? query,
    required int offset,
    required int limit,
  }) {
    var filtered = _mockData.where((e) {
      final stateOk = state == null || state.isEmpty || e.state == state;
      final q = (query ?? '').trim().toLowerCase();
      final queryOk =
          q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.partnerName.toLowerCase().contains(q) ||
          e.sampleName.toLowerCase().contains(q);
      return stateOk && queryOk;
    }).toList();

    final counts = <String, int>{};
    for (final e in _mockData) {
      counts[e.state] = (counts[e.state] ?? 0) + 1;
    }

    final total = filtered.length;
    final page = filtered.skip(offset).take(limit).toList();
    return PagedResult<ArBrief>(
      items: page,
      total: total,
      allCount: _mockData.length,
      counts: counts,
      offset: offset,
      limit: limit,
    );
  }

  ArDetail _mockDetail(int id) {
    final brief = _mockData.firstWhere(
      (e) => e.id == id,
      orElse: () => _mockData.first,
    );
    return ArDetail(
      id: brief.id,
      name: brief.name,
      state: brief.state,
      stateLabel: brief.stateLabel,
      partnerName: brief.partnerName,
      sampleType: brief.sampleType,
      sampleName: brief.sampleName,
      receivedAt: brief.receivedAt,
      analysisDoneAt: brief.analysisDoneAt,
      sender: 'BỘ PHẬN CHUẨN BỊ MẪU',
      receiver: 'BỘ PHẬN THÍ NGHIỆM',
      preprocessRequestName: 'YCSC-2026-00${brief.id}',
      requestCode: 'YCDV-2026-00${brief.id}',
      samplePreservation: 'Bảo quản đông < -18°C',
      retentionDuration: '30 ngày',
      preprocessDoneAt: '2026-06-18 11:20:00',
      resultDueAt: '2026-06-22 17:00:00',
      lines: [
        ArLine(
          id: 1,
          codedSample: 'M-${brief.id}-A',
          testParameter: 'pH',
          testMethods: const ['TCVN 6492:2011'],
          testSampleWeight: 50.0,
          testSampleCount: 2,
          retainSampleWeight: 20.0,
          retainSampleCount: 2,
        ),
        ArLine(
          id: 2,
          codedSample: 'M-${brief.id}-B',
          testParameter: 'COD',
          testMethods: const ['SMEWW 5220C', 'TCVN 6491:1999'],
          testSampleWeight: 100.0,
          testSampleCount: 1,
          retainSampleWeight: 30.0,
          retainSampleCount: 1,
        ),
      ],
    );
  }
}

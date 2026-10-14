import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/preprocess_requests.dart';

/// Client REST cho "Yêu cầu xử lý mẫu" — GET /api/preprocess_requests (list) và
/// `/api/preprocess_requests/<id>` (detail). Theo mẫu chuẩn customer_service.dart
/// (timeout 15s, _fail chuẩn hoá lỗi, _qs build query phân trang).
///
/// Có MOCK FALLBACK: khi gọi mạng lỗi (offline) trả về dữ liệu mẫu để màn hình
/// vẫn render được cho screenshot/dev preview.
class PreprocessRequestsService {
  final String baseUrl;
  final String sessionId;

  PreprocessRequestsService({required this.baseUrl, required this.sessionId});

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

  Future<PagedResult<PreprocessRequestBrief>> getPreprocessRequests({
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
            '$baseUrl/api/preprocess_requests'
            '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
          ),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) _fail(r, 'tải danh sách yêu cầu xử lý mẫu');
      return PagedResult.fromJson(
        jsonDecode(r.body),
        (j) => PreprocessRequestBrief.fromJson(j),
      );
    } catch (_) {
      return _mockList(
        state: state,
        query: query,
        offset: offset,
        limit: limit,
      );
    }
  }

  Future<PreprocessRequestDetail> getPreprocessRequest(int id) async {
    try {
      final r = await _send(
        http.get(
          Uri.parse('$baseUrl/api/preprocess_requests/$id'),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) _fail(r, 'tải chi tiết yêu cầu xử lý mẫu');
      return PreprocessRequestDetail.fromJson(jsonDecode(r.body));
    } catch (_) {
      return _mockDetail(id);
    }
  }

  // ───────────────────────── WRITE ACTIONS (POST) ────────────────────────────
  // Mỗi action -> POST /api/preprocess_requests/<id>/<slug>. Body JSON; với action
  // cần lý do (cancel) truyền 'reason'. Server trả {ok, state} hoặc {error}.

  /// Hàm chung gọi 1 action. Trả về state mới (nếu server trả) hoặc '' nếu không.
  /// Ném Exception với message từ {error} khi thất bại.
  Future<String> _postAction(int id, String slug, {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    final r = await _send(
      http.post(
        Uri.parse('$baseUrl/api/preprocess_requests/$id/$slug'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(r.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {}
    if (r.statusCode != 200) {
      final msg = json?['error']?.toString();
      throw Exception(msg ?? 'Lỗi thao tác (HTTP ${r.statusCode})');
    }
    if (json != null && json['error'] != null) {
      throw Exception(json['error'].toString());
    }
    if (json != null && json['ok'] == false) {
      throw Exception(json['error']?.toString() ?? 'Thao tác không thành công');
    }
    return json?['state']?.toString() ?? '';
  }

  /// draft -> sent.
  Future<String> actionSend(int id) => _postAction(id, 'send');

  /// sent -> received.
  Future<String> actionReceive(int id) => _postAction(id, 'receive');

  /// received -> done.
  Future<String> actionDone(int id) => _postAction(id, 'done');

  /// done -> tạo phiếu yêu cầu phân tích (không đổi state phiếu này).
  Future<String> actionCreateAnalysisRequest(int id) =>
      _postAction(id, 'create_analysis_request');

  /// Hủy phiếu — bắt buộc kèm lý do.
  Future<String> actionCancel(int id, String reason) =>
      _postAction(id, 'cancel', reason: reason);

  // ───────────────────────── MOCK FALLBACK (offline) ─────────────────────────

  static const List<Map<String, dynamic>> _mockItems = [
    {
      'id': 1,
      'name': 'XLM/2026/0001',
      'state': 'received',
      'state_label': 'Tiếp nhận mẫu',
      'partner_name': 'Công ty TNHH Môi trường ABC',
      'sample_type': 'Nước thải',
      'sample_name': 'NT-01',
      'quantity': '3',
      'received_at': '2026-06-18 08:30:00',
      'preprocess_done_at': '',
    },
    {
      'id': 2,
      'name': 'XLM/2026/0002',
      'state': 'done',
      'state_label': 'Đã hoàn thành sơ chế',
      'partner_name': 'Nhà máy Giấy Tân Mai',
      'sample_type': 'Đất',
      'sample_name': 'Đ-12',
      'quantity': '5',
      'received_at': '2026-06-15 09:00:00',
      'preprocess_done_at': '2026-06-16 14:20:00',
    },
    {
      'id': 3,
      'name': 'XLM/2026/0003',
      'state': 'sent',
      'state_label': 'Đã gửi yêu cầu',
      'partner_name': 'Khu công nghiệp Sóng Thần',
      'sample_type': 'Khí thải',
      'sample_name': 'KT-07',
      'quantity': '',
      'received_at': '',
      'preprocess_done_at': '',
    },
    {
      'id': 4,
      'name': 'XLM/2026/0004',
      'state': 'draft',
      'state_label': 'Dự thảo',
      'partner_name': 'Công ty CP Thực phẩm Đồng Tâm',
      'sample_type': 'Nước mặt',
      'sample_name': 'NM-03',
      'quantity': '2',
      'received_at': '',
      'preprocess_done_at': '',
    },
  ];

  PagedResult<PreprocessRequestBrief> _mockList({
    String? state,
    String? query,
    required int offset,
    required int limit,
  }) {
    Iterable<Map<String, dynamic>> rows = _mockItems;
    if (state != null && state.isNotEmpty) {
      rows = rows.where((m) => m['state'] == state);
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      rows = rows.where(
        (m) =>
            (m['name'] as String).toLowerCase().contains(q) ||
            (m['partner_name'] as String).toLowerCase().contains(q) ||
            (m['sample_name'] as String).toLowerCase().contains(q),
      );
    }
    final list = rows.toList();
    final counts = <String, int>{};
    for (final m in _mockItems) {
      final s = m['state'] as String;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final page = list.skip(offset).take(limit).toList();
    return PagedResult<PreprocessRequestBrief>(
      items: page.map((e) => PreprocessRequestBrief.fromJson(e)).toList(),
      total: list.length,
      allCount: _mockItems.length,
      counts: counts,
      offset: offset,
      limit: limit,
    );
  }

  PreprocessRequestDetail _mockDetail(int id) {
    final base = _mockItems.firstWhere(
      (m) => m['id'] == id,
      orElse: () => _mockItems.first,
    );
    return PreprocessRequestDetail.fromJson({
      ...base,
      'request_code': 'YC/2026/0042',
      'handover_name': 'BG/2026/0011',
      'sender': 'Nguyễn Văn A',
      'receiver': 'Trần Thị B',
      'receiver_uid_name': 'Trần Thị B',
      'preprocessors': ['Lê Văn C', 'Phạm Thị D'],
      'excess_handling': 'Trả lại khách hàng',
      'result_due_at': '2026-06-22 17:00:00',
      'lines': [
        {
          'id': 101,
          'coded_sample': '2606.RC.0001.01',
          'coded_suffix': '01',
          'test_parameter': 'pH',
          'test_methods': ['TCVN 6492:2011'],
          'preprocess_part': 'Toàn bộ',
          'preprocess_part_other': '',
          'test_min_weight': '50 g',
          'test_sample_count': '02',
          'retain_min_weight': '50 g',
          'retain_sample_count': '02',
        },
        {
          'id': 102,
          'coded_sample': '2606.RC.0002.03',
          'coded_suffix': '03',
          'test_parameter': 'Kim loại nặng (Cd)',
          'test_methods': ['SMEWW 3113B', 'AOAC 999.10'],
          'preprocess_part': 'Khác',
          'preprocess_part_other': 'Phần thịt + vỏ',
          'test_min_weight': '100 g',
          'test_sample_count': '01',
          'retain_min_weight': '100 g',
          'retain_sample_count': '01',
        },
      ],
    });
  }
}

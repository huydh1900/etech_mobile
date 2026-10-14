import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/lab_batches.dart';

/// Client REST cho module "Mẻ phân tích" — GET /api/lab_batches (list) và
/// `/api/lab_batches/<id>` (detail). Theo mẫu canonical customer_service.dart:
/// timeout 15s, _fail() chuẩn hoá lỗi, _qs() build query phân trang.
///
/// Có mock fallback: khi gọi mạng lỗi (offline/no backend) trả về dữ liệu mẫu
/// để màn hình vẫn render được cho screenshot/preview.
class LabBatchesService {
  final String baseUrl;
  final String sessionId;

  LabBatchesService({required this.baseUrl, required this.sessionId});

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

  Future<PagedResult<LabBatchesBrief>> getBatches({
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
            '$baseUrl/api/lab_batches'
            '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
          ),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) _fail(r, 'tải danh sách mẻ phân tích');
      return PagedResult.fromJson(
        jsonDecode(r.body),
        (j) => LabBatchesBrief.fromJson(j),
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

  Future<LabBatchesDetail> getBatch(int id) async {
    try {
      final r = await _send(
        http.get(Uri.parse('$baseUrl/api/lab_batches/$id'), headers: _headers),
      );
      if (r.statusCode != 200) _fail(r, 'tải chi tiết mẻ phân tích');
      return LabBatchesDetail.fromJson(jsonDecode(r.body));
    } catch (_) {
      return _mockDetail(id);
    }
  }

  // ───────────────────────── Hành động (write) ─────────────────────────
  // POST /api/lab_batches/<id>/<slug> với session cookie. Trả về state mới
  // (nếu backend gửi) hoặc throw thông điệp {error} của Odoo.

  /// Gọi 1 action server-side trên mẻ. [reason] chỉ gửi khi action cần lý do
  /// (vd: hủy mẻ). Trả về 'state' mới nếu có trong payload {ok, state}.
  Future<String?> _action(int id, String slug, {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    final r = await _send(
      http.post(
        Uri.parse('$baseUrl/api/lab_batches/$id/$slug'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    if (r.statusCode != 200) _fail(r, 'thực hiện hành động');
    try {
      final j = jsonDecode(r.body);
      if (j is Map) {
        if (j['error'] != null) throw Exception(j['error'].toString());
        return j['state']?.toString();
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }
    return null;
  }

  /// draft → weighing. Bắt đầu cân mẫu.
  Future<String?> startWeighing(int id) => _action(id, 'start_weighing');

  /// weighing → analyzing (hoặc no-op khi đang analyzing). Tạo biên bản thử nghiệm.
  Future<String?> createTestRecord(int id) => _action(id, 'create_test_record');

  /// analyzing/done → tạo phiếu kết quả (etech.test.report).
  Future<String?> createTestReport(int id) => _action(id, 'create_test_report');

  /// Hủy mẻ (bắt buộc [reason]). draft/weighing/analyzing → cancel.
  Future<String?> cancelBatch(int id, String reason) =>
      _action(id, 'cancel', reason: reason);

  // ───────────────────────── Mock fallback (offline) ─────────────────────────

  PagedResult<LabBatchesBrief> _mockList({
    String? state,
    String? query,
    required int offset,
    required int limit,
  }) {
    var items = _mockBatches.map(LabBatchesBrief.fromJson).toList();
    if (state != null && state.isNotEmpty) {
      items = items.where((b) => b.state == state).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      items = items
          .where(
            (b) =>
                b.name.toLowerCase().contains(q) ||
                b.methodName.toLowerCase().contains(q),
          )
          .toList();
    }
    final counts = <String, int>{};
    for (final b in _mockBatches.map(LabBatchesBrief.fromJson)) {
      counts[b.state] = (counts[b.state] ?? 0) + 1;
    }
    final total = items.length;
    final page = items.skip(offset).take(limit).toList();
    return PagedResult<LabBatchesBrief>(
      items: page,
      total: total,
      allCount: _mockBatches.length,
      counts: counts,
      offset: offset,
      limit: limit,
    );
  }

  LabBatchesDetail _mockDetail(int id) {
    final base = _mockBatches.firstWhere(
      (b) => b['id'] == id,
      orElse: () => _mockBatches.first,
    );
    return LabBatchesDetail.fromJson({
      ...base,
      'num_blank': 1,
      'num_qc': 2,
      'weighing_done': base['state'] != 'draft',
      'test_record_count': 2,
      'cancel_uid_name': base['state'] == 'cancel' ? 'Administrator' : '',
      'cancel_reason': base['state'] == 'cancel' ? 'Sai phương pháp' : '',
      'line_ids': [
        {
          'id': 1,
          'sequence': 10,
          'coded_sample': 'M001',
          'sample_type': 'Mẫu thật',
          'parameter_name': 'Cadimi (Cd)',
          'method_name': base['method_name'],
          'num_duplicate': 1,
          'num_spike': 1,
          'weight_g': 2.5012,
          'result': '0,005',
          'sub_line_ids': [
            {
              'id': 101,
              'coded_sample': 'M001.L1',
              'sample_type': 'Mẫu lặp',
              'weight_g': 2.4988,
            },
            {
              'id': 102,
              'coded_sample': 'M001.TC1 + 5 µg/kg',
              'sample_type': 'Mẫu thêm chuẩn',
              'weight_g': 2.5031,
            },
          ],
        },
        {
          'id': 2,
          'sequence': 20,
          'coded_sample': 'M002',
          'sample_type': 'Mẫu thật',
          'parameter_name': 'Cadimi (Cd)',
          'method_name': base['method_name'],
          'num_duplicate': 0,
          'num_spike': 0,
          'weight_g': 2.4990,
          'result': 'KPH',
          'sub_line_ids': const [],
        },
      ],
      'test_record_ids': [
        {
          'id': 11,
          'name': 'TR-2026-0011',
          'state': 'done',
          'state_label': 'Hoàn thành',
          'metal': 'Cd',
        },
        {
          'id': 12,
          'name': 'TR-2026-0012',
          'state': 'draft',
          'state_label': 'Dự thảo',
          'metal': 'Cd',
        },
      ],
    });
  }

  static final List<Map<String, dynamic>> _mockBatches = [
    {
      'id': 1,
      'name': 'MPT-2026-001',
      'state': 'weighing',
      'state_label': 'Cân mẫu',
      'analysis_date_start': '2026-06-18 08:30:00',
      'method_name': 'AAS - Kim loại nặng',
      'method_code': 'ET.PTN.TP-02',
      'sample_count': 12,
      'request_count': 4,
    },
    {
      'id': 2,
      'name': 'MPT-2026-002',
      'state': 'analyzing',
      'state_label': 'Đã chuyển phân tích',
      'analysis_date_start': '2026-06-17 09:15:00',
      'method_name': 'ICP-MS - Đa nguyên tố',
      'method_code': 'ET.PTN.TP-01',
      'sample_count': 8,
      'request_count': 3,
    },
    {
      'id': 3,
      'name': 'MPT-2026-003',
      'state': 'done',
      'state_label': 'Hoàn thành',
      'analysis_date_start': '2026-06-15 14:00:00',
      'method_name': 'UV-Vis - Định lượng',
      'method_code': 'ET.PTN.TP-03',
      'sample_count': 20,
      'request_count': 6,
    },
    {
      'id': 4,
      'name': 'MPT-2026-004',
      'state': 'draft',
      'state_label': 'Dự thảo',
      'analysis_date_start': '',
      'method_name': 'AAS - Kim loại nặng',
      'method_code': 'ET.PTN.TP-02',
      'sample_count': 0,
      'request_count': 0,
    },
  ];
}

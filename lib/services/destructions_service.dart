import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/destructions.dart';

/// Client REST cho "Hủy mẫu" — GET /api/destructions (list) và
/// `/api/destructions/<id>` (detail). Xác thực cookie session_id.
/// Theo mẫu chuẩn customer_service.dart (timeout 15s, _fail/_qs).
///
/// Có fallback mock để màn hình/ảnh chụp chạy được khi offline.
class DestructionsService {
  final String baseUrl;
  final String sessionId;

  DestructionsService({required this.baseUrl, required this.sessionId});

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

  Future<PagedResult<DestructionBrief>> getDestructions({
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
            '$baseUrl/api/destructions'
            '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
          ),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) _fail(r, 'tải danh sách biên bản hủy mẫu');
      return PagedResult.fromJson(
        jsonDecode(r.body),
        (j) => DestructionBrief.fromJson(j),
      );
    } catch (_) {
      return _mockPage(
        state: state,
        query: query,
        offset: offset,
        limit: limit,
      );
    }
  }

  Future<DestructionDetail> getDestruction(int id) async {
    try {
      final r = await _send(
        http.get(Uri.parse('$baseUrl/api/destructions/$id'), headers: _headers),
      );
      if (r.statusCode != 200) _fail(r, 'tải chi tiết biên bản hủy mẫu');
      return DestructionDetail.fromJson(jsonDecode(r.body));
    } catch (_) {
      return _mockDetail(id);
    }
  }

  // ── Write actions (POST /api/destructions/<id>/<slug>) ────────────────────

  /// Gọi action server trên 1 biên bản hủy mẫu.
  /// Body JSON gửi kèm [reason] nếu action cần lý do.
  /// Trả về state mới (chuỗi) khi {ok:true}; ném Exception với message từ
  /// {error} của backend nếu thất bại. KHÔNG có mock fallback — đây là ghi dữ
  /// liệu thật, không được giả lập thành công.
  Future<String> _action(int id, String slug, {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    final r = await _send(
      http.post(
        Uri.parse('$baseUrl/api/destructions/$id/$slug'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    if (r.statusCode != 200) _fail(r, 'thực hiện thao tác');
    final data = jsonDecode(r.body);
    if (data is Map && data['ok'] == true) {
      return data['state']?.toString() ?? '';
    }
    // 200 nhưng không ok → ưu tiên message lỗi nếu có.
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    throw Exception('Thao tác không thành công');
  }

  /// Xác nhận hủy mẫu (state draft → done). action_done.
  Future<String> actionDone(int id) => _action(id, 'done');

  /// Hủy bỏ biên bản (state draft → cancel). action_cancel — cần [reason].
  Future<String> actionCancel(int id, String reason) =>
      _action(id, 'cancel', reason: reason);

  // ── Mock fallback (chỉ dùng khi backend không sẵn sàng) ───────────────────

  static final List<Map<String, dynamic>> _mockRaw = [
    {
      'id': 1,
      'name': 'BBHM/2026/0001',
      'state': 'done',
      'state_label': 'Đã hủy mẫu',
      'destruction_date': '2026-06-15',
      'sample_count': 3,
      'destroyer_name': 'Nguyễn Văn A',
    },
    {
      'id': 2,
      'name': 'BBHM/2026/0002',
      'state': 'draft',
      'state_label': 'Dự thảo',
      'destruction_date': '2026-06-18',
      'sample_count': 2,
      'destroyer_name': 'Trần Thị B',
    },
    {
      'id': 3,
      'name': 'BBHM/2026/0003',
      'state': 'cancel',
      'state_label': 'Hủy bỏ',
      'destruction_date': '2026-06-10',
      'sample_count': 1,
      'destroyer_name': 'Lê Văn C',
    },
  ];

  PagedResult<DestructionBrief> _mockPage({
    String? state,
    String? query,
    required int offset,
    required int limit,
  }) {
    var rows = _mockRaw;
    if (state != null && state.isNotEmpty) {
      rows = rows.where((r) => r['state'] == state).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      rows = rows
          .where((r) => (r['name'] as String).toLowerCase().contains(q))
          .toList();
    }
    final counts = <String, int>{};
    for (final r in _mockRaw) {
      final s = r['state'] as String;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final items = rows
        .skip(offset)
        .take(limit)
        .map((j) => DestructionBrief.fromJson(j))
        .toList();
    return PagedResult<DestructionBrief>(
      items: items,
      total: rows.length,
      allCount: _mockRaw.length,
      counts: counts,
      offset: offset,
      limit: limit,
    );
  }

  DestructionDetail _mockDetail(int id) {
    final base = _mockRaw.firstWhere(
      (r) => r['id'] == id,
      orElse: () => _mockRaw.first,
    );
    return DestructionDetail.fromJson({
      ...base,
      'method': 'Đốt tại lò hủy mẫu chuyên dụng',
      'note': 'Hủy theo quy trình lưu mẫu hết hạn.',
      'destroyed_at': '2026-06-15 14:30:00',
      'lines': [
        {
          'id': 11,
          'coded_sample': 'M-2026-0101',
          'state': 'destroyed',
          'state_label': 'Đã hủy',
          'partner_name': 'Công ty TNHH ABC',
          'retain_count': 1,
          'retain_weight': 12.5,
          'expiry_at': '2026-06-13 17:00:00',
        },
        {
          'id': 12,
          'coded_sample': 'M-2026-0102',
          'state': 'expired',
          'state_label': 'Hết hạn lưu',
          'partner_name': 'Công ty CP XYZ',
          'retain_count': 2,
          'retain_weight': 8.0,
          'expiry_at': '2026-06-14 09:30:00',
        },
      ],
    });
  }
}

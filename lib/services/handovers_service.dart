import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/handovers.dart';
import '../utils/vn_format.dart';

/// Client REST cho "Bàn giao mẫu" — GET /api/handovers (list) và
/// `/api/handovers/<id>` (detail). Theo mẫu chuẩn customer_service.dart:
/// timeout 15s, _fail() chuẩn hoá lỗi, _qs() build query phân trang.
///
/// Có fallback mock để màn hình/ảnh chụp chạy được khi offline.
class HandoverService {
  final String baseUrl;
  final String sessionId;

  HandoverService({required this.baseUrl, required this.sessionId});

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
    Map<String, String>? params,
  }) {
    final p = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      ...?params,
    };
    if (state != null && state.isNotEmpty) p['state'] = state;
    if (query != null && query.isNotEmpty) p['q'] = query;
    return '?${p.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
  }

  Future<PagedResult<HandoverBrief>> getHandovers({
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
            '$baseUrl/api/handovers'
            '${_qs(state: state, query: query, offset: offset, limit: limit, params: params)}',
          ),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) _fail(r, 'tải danh sách bàn giao mẫu');
      return PagedResult.fromJson(
        jsonDecode(r.body),
        (j) => HandoverBrief.fromJson(j),
      );
    } catch (_) {
      // Fallback mock để UI/ảnh chụp chạy offline.
      return _mockPage(
        state: state,
        query: query,
        offset: offset,
        limit: limit,
        params: params,
      );
    }
  }

  Future<HandoverDetail> getHandover(int id) async {
    try {
      final r = await _send(
        http.get(Uri.parse('$baseUrl/api/handovers/$id'), headers: _headers),
      );
      if (r.statusCode != 200) _fail(r, 'tải chi tiết bàn giao mẫu');
      return HandoverDetail.fromJson(jsonDecode(r.body));
    } catch (_) {
      // Fallback mock để UI/ảnh chụp chạy offline.
      return _mockDetail(id);
    }
  }

  // ── Write actions (POST /api/handovers/<id>/<slug>) ───────────────────────
  // Mỗi action map 1:1 tới một backend action. Body JSON; với action cần lý do
  // thì gửi {'reason': ...}. Trả về state mới (nếu backend trả {ok,state}).
  // KHÔNG có mock fallback cho write — lỗi mạng/permission phải nổi lên UI.

  /// Chuyển draft -> handed.
  Future<String?> handOver(int id) => _action(id, 'hand_over');

  /// Chuyển handed -> received (yêu cầu user đã cài chữ ký cá nhân).
  Future<String?> receive(int id) => _action(id, 'receive');

  /// Chuyển handed -> returned (bắt buộc nhập lý do + yêu cầu chữ ký).
  Future<String?> returnSample(int id, {required String reason}) =>
      _action(id, 'return', body: {'reason': reason});

  /// POST chung cho mọi action. Parse {ok,state} hoặc ném message {error}.
  Future<String?> _action(
    int id,
    String slug, {
    Map<String, dynamic>? body,
  }) async {
    final r = await _send(
      http.post(
        Uri.parse('$baseUrl/api/handovers/$id/$slug'),
        headers: _headers,
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
    if (r.statusCode != 200) _fail(r, 'thực hiện thao tác');
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

  // ── Mock fallback data (chỉ dùng khi backend không sẵn sàng) ──────────────

  static final List<Map<String, dynamic>> _mockData = [
    {
      'id': 1,
      'code': 'BG-2026-0001',
      'state': 'handed',
      'state_label': 'Đã bàn giao',
      'report_code': 'BB-2026-0011',
      'program_code': 'KH-2026-003',
      'request_code': 'YC-2026-0102',
      'partner_name': 'Công ty TNHH Môi trường Xanh',
      'sample_type': 'Nước thải',
      'sample_name': 'Mẫu nước thải đầu ra',
      'receive_date': '2026-10-10',
      'completion_date': '2026-10-09',
      'sla_state': 'on_track',
      'sla_state_label': 'Trong hạn',
    },
    {
      'id': 2,
      'code': 'BG-2026-0002',
      'state': 'received',
      'state_label': 'Đã tiếp nhận',
      'report_code': 'BB-2026-0012',
      'program_code': 'KH-2026-003',
      'request_code': 'YC-2026-0103',
      'partner_name': 'Nhà máy Giấy Tân Mai',
      'sample_type': 'Khí thải',
      'sample_name': 'Mẫu khí ống khói số 2',
      'receive_date': '2026-10-10',
      'completion_date': '2026-10-08',
      'sla_state': 'done_on_time',
      'sla_state_label': 'Hoàn thành đúng hạn',
    },
    {
      'id': 3,
      'code': 'BG-2026-0003',
      'state': 'draft',
      'state_label': 'Dự thảo',
      'report_code': '',
      'program_code': 'KH-2026-004',
      'request_code': '',
      'partner_name': 'Khu công nghiệp Long Thành',
      'sample_type': 'Đất',
      'sample_name': 'Mẫu đất khu B',
      'receive_date': '',
      'completion_date': '2026-10-11',
      'sla_state': 'warning',
      'sla_state_label': 'Sắp đến hạn',
    },
    {
      'id': 4,
      'code': 'BG-2026-0004',
      'state': 'returned',
      'state_label': 'Trả lại mẫu',
      'report_code': 'BB-2026-0009',
      'program_code': 'KH-2026-002',
      'request_code': 'YC-2026-0099',
      'partner_name': 'Công ty CP Thực phẩm An Bình',
      'sample_type': 'Nước sạch',
      'sample_name': 'Mẫu nước giếng khoan',
      'receive_date': '2026-10-07',
      'completion_date': '2026-10-05',
      'sla_state': 'done_late',
      'sla_state_label': 'Hoàn thành trễ hạn',
    },
    {
      'id': 5,
      'code': 'BG-2026-0005',
      'state': 'cancel',
      'state_label': 'Hủy',
      'report_code': '',
      'program_code': 'KH-2026-001',
      'request_code': '',
      'partner_name': 'Bệnh viện Đa khoa tỉnh',
      'sample_type': 'Nước thải y tế',
      'sample_name': 'Mẫu nước thải sau xử lý',
      'receive_date': '',
      'completion_date': '2026-10-02',
      'sla_state': 'overdue',
      'sla_state_label': 'Quá hạn',
    },
  ];

  PagedResult<HandoverBrief> _mockPage({
    String? state,
    String? query,
    required int offset,
    required int limit,
    Map<String, String>? params,
  }) {
    final p = params ?? const {};
    // Mock tên filter/group theo search view Odoo của etech.sampling.handover.
    final sla = {
      for (final f in (p['filters'] ?? '').split(','))
        if (f.startsWith('sla_')) f.substring(4),
    };
    final groupBy = const {
      'g_receive_date': 'receive_date',
      'g_completion_date': 'completion_date',
      'g_state': 'state',
      'g_sla_state': 'sla_state',
    }[p['group_by']];
    final groupKey = p['group_key'];
    final dateFrom = p['date_from'], dateTo = p['date_to'];
    // Facet tìm kiếm (mock 2 trường): cùng trường OR, khác trường AND.
    final facets = <String, List<String>>{};
    if (p['search'] != null) {
      for (final f in jsonDecode(p['search']!) as List) {
        facets.putIfAbsent('${f[0]}', () => []).add('${f[1]}'.toLowerCase());
      }
    }
    var rows = _mockData;
    // Mock: lọc tình trạng hạn + ngày tiếp nhận; "Của tôi" bỏ qua (không có user).
    for (final MapEntry(key: field, value: values) in facets.entries) {
      final col = const {'code': 'code', 'partner_id': 'partner_name'}[field];
      if (col == null) continue;
      rows = rows
          .where((r) => values
              .any((v) => (r[col] as String).toLowerCase().contains(v)))
          .toList();
    }
    if (sla.isNotEmpty) {
      rows = rows.where((r) => sla.contains(r['sla_state'])).toList();
    }
    if (dateFrom != null || dateTo != null) {
      rows = rows.where((r) {
        final v = r['receive_date'] as String;
        if (v.isEmpty) return false;
        if (dateFrom != null && v.compareTo(dateFrom) < 0) return false;
        return dateTo == null || v.compareTo(dateTo) <= 0;
      }).toList();
    }
    if (groupBy != null) {
      // Cùng thứ tự backend: ngày desc (rỗng cuối), selection theo value.
      final desc = groupBy.endsWith('_date');
      rows = [...rows]
        ..sort((x, y) {
          final a = x[groupBy] as String, b = y[groupBy] as String;
          if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
          return desc ? b.compareTo(a) : a.compareTo(b);
        });
    }
    final base = rows;
    if (state != null && state.isNotEmpty) {
      rows = rows.where((r) => r['state'] == state).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      rows = rows
          .where(
            (r) =>
                (r['code'] as String).toLowerCase().contains(q) ||
                (r['partner_name'] as String).toLowerCase().contains(q) ||
                (r['sample_name'] as String).toLowerCase().contains(q),
          )
          .toList();
    }
    final inGroup = groupBy == null || groupKey == null
        ? rows
        : rows.where((r) => r[groupBy] == groupKey).toList();
    final total = inGroup.length;
    final counts = <String, int>{};
    for (final r in base) {
      final s = r['state'] as String;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final groups = <String, PagedGroup>{};
    if (groupBy != null) {
      // Selection → nhãn ở key '<field>_label'; ngày → label rỗng (app tự format).
      final labelKey = groupBy.endsWith('state') ? '${groupBy}_label' : null;
      for (final r in rows) {
        final k = r[groupBy] as String;
        // Như backend: ngày → dd/MM/yyyy, rỗng → "Không xác định".
        final label = k.isEmpty
            ? 'Không xác định'
            : labelKey == null
            ? formatVn(k)
            : r[labelKey] as String;
        groups[k] = PagedGroup(k, label, (groups[k]?.count ?? 0) + 1);
      }
    }
    final page = inGroup.skip(offset).take(limit).toList();
    return PagedResult<HandoverBrief>(
      items: page.map((j) => HandoverBrief.fromJson(j)).toList(),
      total: total,
      allCount: base.length,
      counts: counts,
      offset: offset,
      limit: limit,
      groups: groups.values.toList(),
    );
  }

  HandoverDetail _mockDetail(int id) {
    final base = _mockData.firstWhere(
      (r) => r['id'] == id,
      orElse: () => _mockData.first,
    );
    return HandoverDetail.fromJson({
      ...base,
      'sender_dept': 'PHÒNG HIỆN TRƯỜNG',
      'send_method': 'direct',
      'send_method_label': 'Trực tiếp',
      'sample_count': 1,
      'sampling_completion_label': '16 giờ 06 phút, ngày 18 tháng 06 năm 2026',
      'result_due_date': '04 giờ 06 phút, ngày 20 tháng 06 năm 2026',
      'receive_datetime_label': '16 giờ 10 phút, ngày 18 tháng 06 năm 2026',
      'preprocess_requests': [
        {'id': 11, 'name': 'SC-2026-0021', 'state': 'received'},
        {'id': 12, 'name': 'SC-2026-0022', 'state': 'done'},
      ],
    });
  }
}

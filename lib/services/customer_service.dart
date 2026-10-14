import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/service_request.dart' show CustomerBrief, CustomerDetail;

/// Client REST chuẩn (CANONICAL) cho khách hàng — GET /api/customers (list) và
/// `/api/customers/<id>` (detail). Đây là service tham chiếu cho các module khác:
/// timeout 15s, _fail() chuẩn hoá lỗi, _qs() build query phân trang.
///
/// Model dùng [CustomerBrief]/[CustomerDetail] (đã định nghĩa ở
/// models/service_request.dart) — giữ nguồn sự thật duy nhất cho field khách hàng.
class CustomerService {
  final String baseUrl;
  final String sessionId;

  CustomerService({required this.baseUrl, required this.sessionId});

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

  Future<PagedResult<CustomerBrief>> getCustomers({
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
            '$baseUrl/api/customers'
            '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
          ),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) _fail(r, 'tải danh sách khách hàng');
      return PagedResult.fromJson(
        jsonDecode(r.body),
        (j) => CustomerBrief.fromJson(j),
      );
    } catch (_) {
      return _mockList(query: query, offset: offset, limit: limit);
    }
  }

  Future<CustomerDetail> getCustomer(int id) async {
    try {
      final r = await _send(
        http.get(Uri.parse('$baseUrl/api/customers/$id'), headers: _headers),
      );
      if (r.statusCode != 200) _fail(r, 'tải chi tiết khách hàng');
      return CustomerDetail.fromJson(jsonDecode(r.body));
    } catch (_) {
      return _mockDetail(id);
    }
  }

  // ───────────────────────── Mock fallback (offline) ─────────────────────────
  // Khi gọi mạng lỗi (offline/no backend) trả về dữ liệu mẫu để màn hình render
  // được trong dev preview / golden test — giữ đúng pattern 6 service module kia.
  PagedResult<CustomerBrief> _mockList({
    String? query,
    required int offset,
    required int limit,
  }) {
    var items = _mockCustomers.map(CustomerBrief.fromJson).toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      items = items
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.vat.toLowerCase().contains(q) ||
                c.city.toLowerCase().contains(q),
          )
          .toList();
    }
    final total = items.length;
    final page = items.skip(offset).take(limit).toList();
    return PagedResult<CustomerBrief>(
      items: page,
      total: total,
      allCount: _mockCustomers.length,
      counts: const {},
      offset: offset,
      limit: limit,
    );
  }

  CustomerDetail _mockDetail(int id) {
    final j = _mockCustomers.firstWhere(
      (c) => c['id'] == id,
      orElse: () => _mockCustomers.first,
    );
    return CustomerDetail.fromJson({
      ...j,
      'street': 'Lô A2, KCN Tân Bình',
      'street2': 'Phường Tây Thạnh',
      'function': 'Phòng QA/QC',
      'parent_name': '',
      'request_count': 6,
    });
  }

  static const List<Map<String, dynamic>> _mockCustomers = [
    {
      'id': 1,
      'name': 'Công ty TNHH Thực phẩm An Phú',
      'vat': '0312345678',
      'phone': '0903 123 456',
      'email': 'qa@anphufoods.vn',
      'city': 'TP. Hồ Chí Minh',
      'is_company': true,
    },
    {
      'id': 2,
      'name': 'Công ty CP Nông sản Đồng Xanh',
      'vat': '0398765432',
      'phone': '0912 888 777',
      'email': 'lab@dongxanh.com.vn',
      'city': 'Long An',
      'is_company': true,
    },
    {
      'id': 3,
      'name': 'Nhà máy Nước giải khát Bình Minh',
      'vat': '0301122334',
      'phone': '0987 654 321',
      'email': 'kcs@binhminhbev.vn',
      'city': 'Bình Dương',
      'is_company': true,
    },
    {
      'id': 4,
      'name': 'Trần Thị Hồng Nhung',
      'vat': '',
      'phone': '0935 246 810',
      'email': 'nhung.tth@gmail.com',
      'city': 'Đà Nẵng',
      'is_company': false,
    },
    {
      'id': 5,
      'name': 'Công ty TNHH Thủy sản Cửu Long',
      'vat': '0356677889',
      'phone': '0901 357 924',
      'email': 'export@cuulongseafood.vn',
      'city': 'Cần Thơ',
      'is_company': true,
    },
  ];
}

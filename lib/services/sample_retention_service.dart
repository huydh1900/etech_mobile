import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/sample_retention.dart';

/// Client REST cho luồng "Lưu mẫu + Biên bản hủy mẫu" —
/// gọi /api/retained_samples/* và /api/destructions/*.
/// Cùng pattern xác thực cookie session_id như ServiceRequestService.
class SampleRetentionService {
  final String baseUrl;
  final String sessionId;

  SampleRetentionService({required this.baseUrl, required this.sessionId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Cookie': 'session_id=$sessionId',
  };

  /// Bọc request với timeout để tránh treo vô hạn khi máy chủ chậm/đang nâng cấp.
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

  /// Build query string từ các tham số phân trang/lọc (bỏ qua giá trị rỗng).
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

  Future<PagedResult<RetainedSampleBrief>> getRetainedSamples({
    String? state,
    String? query,
    int offset = 0,
    int limit = 30,
    Map<String, String>? params, // Bộ lọc/Nhóm theo (search spec)
  }) async {
    final r = await _send(
      http.get(
        Uri.parse(
          '$baseUrl/api/retained_samples'
          '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
        ),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải danh sách mẫu lưu');
    return PagedResult.fromJson(
      jsonDecode(r.body),
      (j) => RetainedSampleBrief.fromJson(j),
    );
  }

  Future<RetainedSampleDetail> getRetainedSample(int id) async {
    final r = await _send(
      http.get(
        Uri.parse('$baseUrl/api/retained_samples/$id'),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải mẫu lưu');
    return RetainedSampleDetail.fromJson(jsonDecode(r.body));
  }

  Future<PagedResult<DestructionBrief>> getDestructions({
    String? state,
    String? query,
    int offset = 0,
    int limit = 30,
    Map<String, String>? params, // Bộ lọc/Nhóm theo (search spec)
  }) async {
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
  }

  Future<DestructionDetail> getDestruction(int id) async {
    final r = await _send(
      http.get(Uri.parse('$baseUrl/api/destructions/$id'), headers: _headers),
    );
    if (r.statusCode != 200) _fail(r, 'tải biên bản hủy mẫu');
    return DestructionDetail.fromJson(jsonDecode(r.body));
  }
}

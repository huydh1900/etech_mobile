import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/lab_sample.dart';

// Client REST cho luồng "Tiếp nhận mẫu / Chuẩn bị mẫu" — gọi /api/handovers/*,
// /api/preprocess_requests/* và /api/analysis_requests/*.
// Cùng pattern xác thực cookie session_id như ServiceRequestService.
class LabSampleService {
  final String baseUrl;
  final String sessionId;

  LabSampleService({required this.baseUrl, required this.sessionId});

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

  // ------- Phiếu bàn giao mẫu -------
  Future<PagedResult<HandoverBrief>> getHandovers({
    String? state,
    String? query,
    int offset = 0,
    int limit = 30,
    Map<String, String>? params, // Bộ lọc/Nhóm theo (search spec)
  }) async {
    final r = await _send(
      http.get(
        Uri.parse(
          '$baseUrl/api/handovers'
          '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
        ),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải danh sách phiếu bàn giao');
    return PagedResult.fromJson(
      jsonDecode(r.body),
      (j) => HandoverBrief.fromJson(j),
    );
  }

  Future<HandoverDetail> getHandover(int id) async {
    final r = await _send(
      http.get(Uri.parse('$baseUrl/api/handovers/$id'), headers: _headers),
    );
    if (r.statusCode != 200) _fail(r, 'tải phiếu bàn giao');
    return HandoverDetail.fromJson(jsonDecode(r.body));
  }

  // ------- Phiếu yêu cầu sơ chế -------
  Future<PagedResult<PreprocessRequestBrief>> getPreprocessRequests({
    String? state,
    String? query,
    int offset = 0,
    int limit = 30,
    Map<String, String>? params, // Bộ lọc/Nhóm theo (search spec)
  }) async {
    final r = await _send(
      http.get(
        Uri.parse(
          '$baseUrl/api/preprocess_requests'
          '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
        ),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải danh sách phiếu sơ chế');
    return PagedResult.fromJson(
      jsonDecode(r.body),
      (j) => PreprocessRequestBrief.fromJson(j),
    );
  }

  Future<PreprocessRequestDetail> getPreprocessRequest(int id) async {
    final r = await _send(
      http.get(
        Uri.parse('$baseUrl/api/preprocess_requests/$id'),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải phiếu sơ chế');
    return PreprocessRequestDetail.fromJson(jsonDecode(r.body));
  }

  // ------- Phiếu yêu cầu phân tích -------
  Future<PagedResult<AnalysisRequestBrief>> getAnalysisRequests({
    String? state,
    String? query,
    int offset = 0,
    int limit = 30,
    Map<String, String>? params, // Bộ lọc/Nhóm theo (search spec)
  }) async {
    final r = await _send(
      http.get(
        Uri.parse(
          '$baseUrl/api/analysis_requests'
          '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
        ),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải danh sách phiếu phân tích');
    return PagedResult.fromJson(
      jsonDecode(r.body),
      (j) => AnalysisRequestBrief.fromJson(j),
    );
  }

  Future<AnalysisRequestDetail> getAnalysisRequest(int id) async {
    final r = await _send(
      http.get(
        Uri.parse('$baseUrl/api/analysis_requests/$id'),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải phiếu phân tích');
    return AnalysisRequestDetail.fromJson(jsonDecode(r.body));
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/sampling.dart';

/// Client REST cho luồng biên bản hiện trường — gọi /api/sampling/*.
/// Cùng pattern xác thực cookie session_id như EmployeeService.
class SamplingService {
  final String baseUrl;
  final String sessionId;

  SamplingService({required this.baseUrl, required this.sessionId});

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

  Future<SamplingOptions> getOptions() async {
    final r = await _send(
      http.get(Uri.parse('$baseUrl/api/sampling/options'), headers: _headers),
    );
    if (r.statusCode != 200) _fail(r, 'tải tuỳ chọn');
    return SamplingOptions.fromJson(jsonDecode(r.body));
  }

  /// Build query string từ các tham số phân trang/lọc (bỏ qua giá trị rỗng).
  String _qs({
    String? state,
    String? query,
    String? scope,
    required int offset,
    required int limit,
  }) {
    final p = <String, String>{'offset': '$offset', 'limit': '$limit'};
    if (state != null && state.isNotEmpty) p['state'] = state;
    if (scope != null && scope.isNotEmpty) p['scope'] = scope;
    if (query != null && query.isNotEmpty) p['q'] = query;
    return '?${p.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
  }

  /// [scope]: `my` (kế hoạch của tôi — mặc định) hoặc `need_schedule`
  /// (chưa lên lịch) — khớp 2 menu con backend dưới "Kế hoạch lấy mẫu".
  Future<PagedResult<SamplingProgram>> getPrograms({
    String? state,
    String? query,
    String? scope,
    int offset = 0,
    int limit = 30,
    Map<String, String>? params, // Bộ lọc/Nhóm theo (search spec)
  }) async {
    final r = await _send(
      http.get(
        Uri.parse(
          '$baseUrl/api/sampling/programs'
          '${_qs(state: state, query: query, scope: scope, offset: offset, limit: limit)}${extraQuery(params)}',
        ),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải kế hoạch');
    return PagedResult.fromJson(
      jsonDecode(r.body),
      (j) => SamplingProgram.fromJson(j),
    );
  }

  Future<SamplingProgramDetail> getProgram(int id) async {
    final r = await _send(
      http.get(
        Uri.parse('$baseUrl/api/sampling/programs/$id'),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải kế hoạch');
    return SamplingProgramDetail.fromJson(jsonDecode(r.body));
  }

  Future<PagedResult<SamplingReportBrief>> getReports({
    String? state,
    String? query,
    int offset = 0,
    int limit = 30,
    Map<String, String>? params, // Bộ lọc/Nhóm theo (search spec)
  }) async {
    final r = await _send(
      http.get(
        Uri.parse(
          '$baseUrl/api/sampling/reports'
          '${_qs(state: state, query: query, offset: offset, limit: limit)}${extraQuery(params)}',
        ),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải danh sách biên bản');
    return PagedResult.fromJson(
      jsonDecode(r.body),
      (j) => SamplingReportBrief.fromJson(j),
    );
  }

  Future<SamplingReportDetail> getReport(int id) async {
    final r = await _send(
      http.get(
        Uri.parse('$baseUrl/api/sampling/reports/$id'),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải biên bản');
    return SamplingReportDetail.fromJson(jsonDecode(r.body));
  }

  Future<SamplingReportDetail> saveReport(SamplingReportDetail report) async {
    final r = await _send(
      http.post(
        Uri.parse('$baseUrl/api/sampling/reports/${report.id}/save'),
        headers: _headers,
        body: jsonEncode(report.toSaveJson()),
      ),
    );
    if (r.statusCode != 200) _fail(r, 'lưu biên bản');
    return SamplingReportDetail.fromJson(jsonDecode(r.body));
  }

  /// Upload 1 ảnh vào cột [column]; trả id attachment vừa tạo.
  Future<int> addPhoto(
    int reportId,
    String column,
    String imageBase64, {
    String? filename,
  }) async {
    final r = await _send(
      http.post(
        Uri.parse('$baseUrl/api/sampling/reports/$reportId/photos'),
        headers: _headers,
        body: jsonEncode({
          'column': column,
          'image_base64': imageBase64,
          'filename': filename ?? 'mobile_photo.jpg',
        }),
      ),
    );
    if (r.statusCode != 200) _fail(r, 'tải ảnh lên');
    return jsonDecode(r.body)['id'] as int;
  }

  Future<void> deletePhoto(int reportId, int attId) async {
    final r = await _send(
      http.delete(
        Uri.parse('$baseUrl/api/sampling/reports/$reportId/photos/$attId'),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'xoá ảnh');
  }

  Future<SamplingReportDetail> complete(int reportId) async {
    final r = await _send(
      http.post(
        Uri.parse('$baseUrl/api/sampling/reports/$reportId/complete'),
        headers: _headers,
      ),
    );
    if (r.statusCode != 200) _fail(r, 'hoàn thành biên bản');
    return SamplingReportDetail.fromJson(jsonDecode(r.body));
  }
}

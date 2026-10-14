import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';

class EmployeeService {
  final String baseUrl;
  final String sessionId;

  EmployeeService({required this.baseUrl, required this.sessionId});

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

  Future<Employee> getMe() async {
    final response = await _send(
      http.get(Uri.parse('$baseUrl/api/me'), headers: _headers),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Lỗi tải thông tin cá nhân (HTTP ${response.statusCode})',
      );
    }
    return Employee.fromJson(jsonDecode(response.body));
  }

  /// Cập nhật thông tin cá nhân cơ bản + avatar của chính mình.
  /// Chỉ truyền field cần đổi (null = giữ nguyên, không gửi lên).
  /// [imageBase64]: nội dung ảnh base64 (không kèm tiền tố data URI),
  /// chuỗi rỗng để xoá avatar.
  Future<Employee> updateMe({
    String? phone,
    String? address,
    String? birthday,
    String? imageBase64,
  }) async {
    final body = <String, dynamic>{};
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    if (birthday != null) body['birthday'] = birthday;
    if (imageBase64 != null) body['image'] = imageBase64;

    final response = await _send(
      http.post(
        Uri.parse('$baseUrl/api/me'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Lỗi cập nhật thông tin (HTTP ${response.statusCode})');
    }
    return Employee.fromJson(jsonDecode(response.body));
  }

  /// URL ảnh avatar đầy đủ kèm tham số cache-busting theo write_date.
  String avatarUrl(Employee e) =>
      '$baseUrl${e.avatarUrl}?v=${Uri.encodeComponent(e.writeDate)}';
}

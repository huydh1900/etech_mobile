import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class OdooAuthResult {
  final bool success;
  final int? uid;
  final String? sessionId;
  final String? errorMessage;

  OdooAuthResult.success(this.uid, this.sessionId)
    : success = true,
      errorMessage = null;

  OdooAuthResult.failure(this.errorMessage)
    : success = false,
      uid = null,
      sessionId = null;
}

/// Đại diện cho phiên do trình duyệt giữ (web): không đọc được giá trị
/// session_id thật, request cùng origin tự mang cookie.
const String kWebCookieSession = 'browser-cookie';

class OdooAuthService {
  final String baseUrl;
  final String database;

  OdooAuthService({required this.baseUrl, required this.database});

  Future<OdooAuthResult> login(String login, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/web/session/authenticate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {'db': database, 'login': login, 'password': password},
        }),
      );

      if (response.statusCode != 200) {
        return OdooAuthResult.failure(
          'Lỗi máy chủ (HTTP ${response.statusCode})',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['error'] != null) {
        final data = body['error']['data'];
        final name = data?['name']?.toString() ?? '';
        final rawMsg = data?['message']?.toString() ?? '';
        // Odoo raises AccessDenied khi sai login/password
        if (name.contains('AccessDenied') ||
            rawMsg.toLowerCase().contains('access denied')) {
          return OdooAuthResult.failure('Sai tên đăng nhập hoặc mật khẩu');
        }
        return OdooAuthResult.failure(
          rawMsg.isEmpty ? 'Lỗi không xác định' : rawMsg,
        );
      }

      final result = body['result'];
      if (result is Map && result['uid'] != null && result['uid'] != false) {
        // Lấy session_id từ Set-Cookie header.
        // Trên web trình duyệt CHẶN đọc Set-Cookie (forbidden header) nên
        // luôn null -> dùng cờ [kWebCookieSession] làm đại diện: cookie thật
        // do trình duyệt giữ và tự gửi kèm (cùng origin qua web_proxy).
        // Không có cờ này thì SessionStore không lưu gì -> reload là mất phiên.
        final rawCookie = response.headers['set-cookie'] ?? '';
        final sessionId =
            RegExp(r'session_id=([^;]+)').firstMatch(rawCookie)?.group(1) ??
            (kIsWeb ? kWebCookieSession : null);
        return OdooAuthResult.success(result['uid'] as int, sessionId);
      }

      return OdooAuthResult.failure('Sai tên đăng nhập hoặc mật khẩu');
    } catch (e) {
      return OdooAuthResult.failure('Không kết nối được máy chủ: $e');
    }
  }

  /// Gửi email đặt lại mật khẩu theo mã nhân viên (login).
  /// Trả về null nếu thành công, hoặc chuỗi thông báo lỗi.
  Future<String?> resetPassword(String employeeCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/reset_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {'login': employeeCode},
        }),
      );

      if (response.statusCode != 200) {
        return 'Lỗi máy chủ (HTTP ${response.statusCode})';
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['error'] != null) {
        final msg = body['error']['data']?['message'] ?? body['error'];
        return msg.toString();
      }

      final result = body['result'];
      if (result is Map && result['error'] != null) {
        return result['error'].toString();
      }
      if (result is Map && result['success'] == true) {
        return null;
      }
      return 'Không đặt lại được mật khẩu';
    } catch (e) {
      return 'Không kết nối được máy chủ: $e';
    }
  }
}

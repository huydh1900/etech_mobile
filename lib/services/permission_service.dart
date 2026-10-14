import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_permissions.dart';

/// Client REST cho GET /api/permissions (addon etech_mobile_core). Cùng pattern
/// xác thực cookie session_id như các service khác.
///
/// Theo convention app: lỗi mạng/HTTP → fallback "mở hết" ([AppPermissions.allowAll])
/// để UI không bao giờ bị chặn. Caller (PermissionController) quyết định default-allow.
class PermissionService {
  final String baseUrl;
  final String sessionId;

  PermissionService({required this.baseUrl, required this.sessionId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Cookie': 'session_id=$sessionId',
  };

  /// Tải permission từ backend. Ném exception khi lỗi để caller fallback;
  /// dùng [fetchOrAllowAll] nếu muốn fallback im lặng.
  Future<AppPermissions> fetch() async {
    final r = await http
        .get(Uri.parse('$baseUrl/api/permissions'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('Lỗi tải phân quyền (HTTP ${r.statusCode})');
    }
    final body = jsonDecode(r.body);
    if (body is! Map) {
      throw Exception('Phản hồi phân quyền không hợp lệ');
    }
    return AppPermissions.fromJson(Map<String, dynamic>.from(body));
  }

  /// Tải permission; mọi lỗi → trả [AppPermissions.allowAll] (default-allow)
  /// để không chặn UI khi offline / backend chưa cài addon.
  Future<AppPermissions> fetchOrAllowAll() async {
    try {
      return await fetch();
    } catch (_) {
      return AppPermissions.allowAll;
    }
  }
}

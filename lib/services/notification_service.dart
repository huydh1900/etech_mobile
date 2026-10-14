import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paged.dart';
import '../models/app_notification.dart';

/// Client REST cho thông báo (inbox) — GET /api/notifications,
/// `POST /api/notifications/<id>/read`, GET /api/notifications/unread_count
/// (addon etech_mobile_core). Xác thực cookie session_id.
///
/// Có fallback mock để màn hình/ảnh chụp chạy được khi offline (theo yêu cầu).
class NotificationService {
  final String baseUrl;
  final String sessionId;

  NotificationService({required this.baseUrl, required this.sessionId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Cookie': 'session_id=$sessionId',
  };

  Future<http.Response> _send(Future<http.Response> req) => req.timeout(
    const Duration(seconds: 15),
    onTimeout: () =>
        throw Exception('Máy chủ phản hồi quá lâu, vui lòng thử lại'),
  );

  /// Backend trả {items, total, offset, limit} (KHÔNG có all_count/counts) →
  /// PagedResult.fromJson tự suy all_count = total, counts = {}.
  Future<PagedResult<AppNotification>> getNotifications({
    int offset = 0,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    final p = <String, String>{'offset': '$offset', 'limit': '$limit'};
    if (unreadOnly) p['unread'] = '1';
    final qs = p.entries.map((e) => '${e.key}=${e.value}').join('&');
    try {
      final r = await _send(
        http.get(
          Uri.parse('$baseUrl/api/notifications?$qs'),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) {
        throw Exception('Lỗi tải thông báo (HTTP ${r.statusCode})');
      }
      return PagedResult.fromJson(
        jsonDecode(r.body),
        (j) => AppNotification.fromJson(j),
      );
    } catch (_) {
      // Fallback mock để UI/ảnh chụp chạy offline.
      return _mockPage(offset: offset, limit: limit, unreadOnly: unreadOnly);
    }
  }

  /// Đánh dấu đã đọc 1 thông báo (target = mail.notification id). Idempotent.
  /// Trả true nếu thành công; lỗi mạng → false (không ném, để UI vẫn mượt).
  Future<bool> markRead(int notifId) async {
    try {
      final r = await _send(
        http.post(
          Uri.parse('$baseUrl/api/notifications/$notifId/read'),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) return false;
      final body = jsonDecode(r.body);
      return body is Map && body['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Số thông báo chưa đọc. Lỗi → đếm từ mock fallback.
  Future<int> unreadCount() async {
    try {
      final r = await _send(
        http.get(
          Uri.parse('$baseUrl/api/notifications/unread_count'),
          headers: _headers,
        ),
      );
      if (r.statusCode != 200) {
        throw Exception('Lỗi đếm thông báo (HTTP ${r.statusCode})');
      }
      final body = jsonDecode(r.body);
      if (body is Map) {
        return (body['count'] as num?)?.toInt() ??
            (body['unread_count'] as num?)?.toInt() ??
            0;
      }
      return 0;
    } catch (_) {
      return _mockData.where((n) => !n.isRead).length;
    }
  }

  // ── Mock fallback data (chỉ dùng khi backend không sẵn sàng) ──────────────
  static final List<AppNotification> _mockData = [
    const AppNotification(
      id: 1,
      messageId: 101,
      subject: 'Hồ sơ mới cần tiếp nhận',
      bodyPreview: 'Khách hàng A vừa gửi phiếu yêu cầu dịch vụ mới.',
      date: '2026-06-19 08:30:00',
      isRead: false,
      type: 'inbox',
      resModel: 'etech.service.request',
      resId: 42,
    ),
    const AppNotification(
      id: 2,
      messageId: 102,
      subject: 'Phân công lấy mẫu',
      bodyPreview: 'Bạn được phân công lấy mẫu tại hiện trường ngày mai.',
      date: '2026-06-18 16:10:00',
      isRead: false,
      type: 'inbox',
      resModel: 'etech.sampling.report',
      resId: 17,
    ),
    const AppNotification(
      id: 3,
      messageId: 103,
      subject: 'Kết quả phân tích đã duyệt',
      bodyPreview: 'Phiếu kết quả KQ-2026-0091 đã được phê duyệt.',
      date: '2026-06-17 11:05:00',
      isRead: true,
      type: 'inbox',
      resModel: 'etech.test.report',
      resId: 91,
    ),
  ];

  PagedResult<AppNotification> _mockPage({
    required int offset,
    required int limit,
    required bool unreadOnly,
  }) {
    final src = unreadOnly
        ? _mockData.where((n) => !n.isRead).toList()
        : _mockData;
    final slice = src.skip(offset).take(limit).toList();
    return PagedResult<AppNotification>(
      items: slice,
      total: src.length,
      allCount: src.length,
      counts: const {},
      offset: offset,
      limit: limit,
    );
  }
}

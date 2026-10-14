// Model cho một thông báo (inbox) — map 1:1 với item của GET /api/notifications
// (addon etech_mobile_core). `id` là mail.notification id, dùng làm target cho
// POST /api/notifications/<id>/read.

// Odoo trả `false` cho field rỗng (char/m2o/date) -> coerce về ''/0,
// tránh render "false" và crash cast khi backend thiếu dữ liệu.
String _sv(Object? v) => (v == null || v == false) ? '' : v.toString();
int _iv(Object? v) => v is num ? v.toInt() : 0;

class AppNotification {
  /// mail.notification id — target để đánh dấu đã đọc.
  final int id;

  /// mail.message id (tham chiếu nội dung gốc).
  final int messageId;
  final String subject;
  final String bodyPreview;
  final String date;
  final bool isRead;

  /// Luôn là 'inbox' theo thiết kế backend.
  final String type;
  final String resModel;
  final int resId;

  const AppNotification({
    required this.id,
    required this.messageId,
    required this.subject,
    required this.bodyPreview,
    required this.date,
    required this.isRead,
    required this.type,
    required this.resModel,
    required this.resId,
  });

  static String _s(Map<String, dynamic> j, String k) => _sv(j[k]);

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: _iv(j['id']),
    messageId: _iv(j['message_id']),
    subject: _s(j, 'subject'),
    bodyPreview: _s(j, 'body_preview'),
    date: _s(j, 'date'),
    isRead: j['is_read'] == true,
    type: _s(j, 'type'),
    resModel: _s(j, 'res_model'),
    resId: _iv(j['res_id']),
  );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    messageId: messageId,
    subject: subject,
    bodyPreview: bodyPreview,
    date: date,
    isRead: isRead ?? this.isRead,
    type: type,
    resModel: resModel,
    resId: resId,
  );
}

import 'package:flutter/foundation.dart';
import '../config.dart';
import '../models/app_notification.dart';
import 'notification_service.dart';

/// Singleton global giữ danh sách thông báo + số chưa đọc. ChangeNotifier global
/// đồng nhất với [themeController] / [permissions]. Dùng để vẽ badge chuông trên
/// AppBar (module_list_scaffold) và màn Thông báo.
class NotificationController extends ChangeNotifier {
  NotificationService? _service;
  final List<AppNotification> _items = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  /// Gắn session hiện tại (gọi sau đăng nhập). Idempotent với cùng session.
  void attach(String sessionId) {
    _service = NotificationService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
  }

  NotificationService get _svc =>
      _service ??
      (throw StateError('NotificationController chưa attach session'));

  /// Tải lại danh sách (trang đầu) + số chưa đọc. An toàn gọi nhiều lần.
  Future<void> refresh({int limit = 30}) async {
    if (_service == null) return;
    _loading = true;
    notifyListeners();
    try {
      final page = await _svc.getNotifications(offset: 0, limit: limit);
      final count = await _svc.unreadCount();
      _items
        ..clear()
        ..addAll(page.items);
      _unreadCount = count;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Đánh dấu đã đọc 1 thông báo; cập nhật optimistic danh sách + badge.
  Future<void> markRead(int notifId) async {
    if (_service == null) return;
    final ok = await _svc.markRead(notifId);
    if (!ok) return;
    final idx = _items.indexWhere((n) => n.id == notifId);
    if (idx != -1 && !_items[idx].isRead) {
      _items[idx] = _items[idx].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }

  /// Xoá trạng thái (đăng xuất).
  void clear() {
    _service = null;
    _items.clear();
    _unreadCount = 0;
    _loading = false;
    notifyListeners();
  }
}

/// Instance global.
final notifications = NotificationController();

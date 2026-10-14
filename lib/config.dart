import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  /// Base URL của Odoo.
  ///
  /// - **Web**: luôn gọi CÙNG ORIGIN với trang đang mở (`Uri.base.origin`).
  ///   Odoo không gửi CORS header và cookie `session_id` không phải
  ///   `SameSite=None`, nên gọi cross-origin (vd trang ở :5001 → Odoo :8001)
  ///   sẽ bị chặn / mất session. Vì vậy web phải chạy qua reverse proxy:
  ///   `./run_web_dev.sh` (proxy :5000 forward /web,/api về Odoo :8001).
  /// - **Mobile/desktop**: không có ràng buộc CORS → trỏ thẳng vào Odoo.
  ///   Đổi `_nativeOdooUrl` khi chuyển môi trường
  ///   (`10.0.2.2` cho Android emulator, IP LAN cho máy thật).
  static final String odooUrl = kIsWeb ? Uri.base.origin : _nativeOdooUrl;

  static const String _nativeOdooUrl = 'http://192.168.1.145:8001';

  static const String odooDb = 'elabtech_11';

  /// Tên hiển thị + phiên bản app — nguồn duy nhất cho footer/about, giữ khớp
  /// `version` trong pubspec.yaml (không hard-code rải rác ở UI nữa).
  /// TODO(optional): thay bằng package_info_plus để đọc tự động từ build.
  static const String appName = 'ETECH Lab';
  static const String appVersion = '1.0.0';
}

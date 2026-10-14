import 'package:shared_preferences/shared_preferences.dart';

/// Lưu trữ phiên đăng nhập để "Duy trì đăng nhập trên thiết bị này".
/// Chỉ lưu session_id + uid Odoo, KHÔNG lưu mật khẩu.
class SessionStore {
  static const _kSessionId = 'session_id';
  static const _kUid = 'uid';

  Future<void> save({required String sessionId, int? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionId, sessionId);
    if (uid != null) {
      await prefs.setInt(_kUid, uid);
    } else {
      await prefs.remove(_kUid);
    }
  }

  Future<({String sessionId, int? uid})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_kSessionId);
    if (sessionId == null || sessionId.isEmpty) return null;
    return (sessionId: sessionId, uid: prefs.getInt(_kUid));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionId);
    await prefs.remove(_kUid);
  }
}

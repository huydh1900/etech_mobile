import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý chế độ giao diện Sáng/Tối toàn app.
/// Dùng ChangeNotifier global (không qua provider) vì palette là static.
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'theme_dark';

  bool _dark = false;
  bool get isDark => _dark;

  Brightness get brightness => _dark ? Brightness.dark : Brightness.light;

  /// Đọc lựa chọn đã lưu (mặc định: Sáng). Gọi 1 lần trước runApp.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _dark = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    if (_dark == value) return;
    _dark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  Future<void> toggle() => setDark(!_dark);
}

/// Instance global, truy cập trực tiếp ở màn Cài đặt.
final themeController = ThemeController();

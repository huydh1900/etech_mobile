import 'package:flutter/foundation.dart';
import '../config.dart';
import '../models/app_permissions.dart';
import 'permission_service.dart';

/// Singleton global giữ tập quyền của user hiện tại. Dùng ChangeNotifier global
/// (không qua provider) đồng nhất với [themeController].
///
/// Default-allow: trước khi nạp xong, hoặc khi nạp lỗi, mọi helper trả `true`
/// để UI không bị chặn (convention fallback của app). Backend ir.rule vẫn là
/// lớp chặn thật ở tầng dữ liệu — đây chỉ là gating UI.
class PermissionController extends ChangeNotifier {
  AppPermissions _perms = AppPermissions.allowAll;
  bool _loaded = false;

  /// `true` sau khi đã nạp thật từ backend (kể cả khi rỗng).
  bool get loaded => _loaded;
  AppPermissions get permissions => _perms;

  /// Nạp permission cho [sessionId]. Lỗi → giữ default-allow, đặt loaded=true.
  Future<void> load(String sessionId) async {
    if (sessionId.isEmpty) {
      _loaded = true;
      notifyListeners();
      return;
    }
    final service = PermissionService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    _perms = await service.fetchOrAllowAll();
    _loaded = true;
    notifyListeners();
  }

  /// Xoá quyền (vd khi đăng xuất) — quay về default-allow.
  void clear() {
    _perms = AppPermissions.allowAll;
    _loaded = false;
    notifyListeners();
  }

  ModelPermission _model(String model) =>
      _perms.models[model] ?? ModelPermission.allowed;

  /// Menu có hiển thị không. Nhận cả `module.xmlid` lẫn xmlid trần (cấu hình
  /// [AppSubMenu.backendXmlId] dùng xmlid trần, còn backend trả `module.xmlid`)
  /// → so theo phần sau dấu chấm. Default-allow: chưa nạp hoặc backend không
  /// trả danh sách menu → cho hiện.
  bool canSeeMenu(String xmlid) {
    if (!_loaded || _perms.menus.isEmpty) return true;
    final local = xmlid.split('.').last;
    return _perms.menus.any((m) => m.split('.').last == local);
  }

  bool canRead(String model) => _model(model).canRead;
  bool canWrite(String model) => _model(model).canWrite;
  bool canCreate(String model) => _model(model).canCreate;
  bool canUnlink(String model) => _model(model).canUnlink;

  /// Cờ nhóm (`module.group_xmlid`). Mặc định false khi không có key (nhóm là
  /// opt-in: thiếu thông tin → coi như KHÔNG thuộc nhóm để tránh lộ UI nhạy cảm).
  bool inGroup(String groupXmlId) => _perms.groups[groupXmlId] ?? false;

  /// Số record user thấy được theo model (đã tôn trọng ir.rule). 0 nếu không rõ.
  int visibleCount(String model) => _model(model).visibleCount;
}

/// Instance global — truy cập trực tiếp ở widget gating quyền.
final permissions = PermissionController();

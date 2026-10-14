// Model cho quyền truy cập của user — map 1:1 với GET /api/permissions
// (addon etech_mobile_core). Gồm: tập menu xmlid được thấy, quyền CRUD theo
// model, và cờ nhóm (group) để bật/tắt UI theo vai trò.

// Odoo trả `false` cho field rỗng (char/m2o/date) -> coerce về ''/0,
// tránh render "false" và crash cast khi backend thiếu dữ liệu.
String _sv(Object? v) => (v == null || v == false) ? '' : v.toString();
int _iv(Object? v) => v is num ? v.toInt() : 0;

class ModelPermission {
  final bool canRead;
  final bool canWrite;
  final bool canCreate;
  final bool canUnlink;
  final int visibleCount;

  const ModelPermission({
    required this.canRead,
    required this.canWrite,
    required this.canCreate,
    required this.canUnlink,
    required this.visibleCount,
  });

  /// Quyền mặc định "mở hết" — dùng khi lỗi tải permission để không chặn UI
  /// (theo convention fallback của app).
  static const ModelPermission allowed = ModelPermission(
    canRead: true,
    canWrite: true,
    canCreate: true,
    canUnlink: true,
    visibleCount: 0,
  );

  factory ModelPermission.fromJson(Map<String, dynamic> j) => ModelPermission(
    canRead: j['can_read'] == true,
    canWrite: j['can_write'] == true,
    canCreate: j['can_create'] == true,
    canUnlink: j['can_unlink'] == true,
    visibleCount: _iv(j['visible_count']),
  );
}

class AppPermissions {
  /// Tập menu xmlid (đầy đủ, dạng `module.xmlid`) user được phép thấy.
  final Set<String> menus;

  /// Quyền theo model — key là tên model Odoo (vd 'res.partner').
  final Map<String, ModelPermission> models;

  /// Cờ nhóm — key là `module.group_xmlid`, value true nếu user thuộc nhóm.
  final Map<String, bool> groups;

  const AppPermissions({
    required this.menus,
    required this.models,
    required this.groups,
  });

  /// Quyền mặc định "mở hết" — fallback khi offline / lỗi tải để UI không chặn.
  static const AppPermissions allowAll = AppPermissions(
    menus: <String>{},
    models: <String, ModelPermission>{},
    groups: <String, bool>{},
  );

  factory AppPermissions.fromJson(Map<String, dynamic> j) {
    final menus = <String>{};
    for (final m in (j['menus'] is List ? j['menus'] as List : const [])) {
      final s = _sv(m);
      if (s.isNotEmpty) menus.add(s);
    }
    final models = <String, ModelPermission>{};
    (j['models'] is Map ? (j['models'] as Map) : null)?.forEach((k, v) {
      if (v is Map) {
        models[k.toString()] = ModelPermission.fromJson(
          Map<String, dynamic>.from(v),
        );
      }
    });
    final groups = <String, bool>{};
    (j['groups'] is Map ? (j['groups'] as Map) : null)?.forEach((k, v) {
      groups[k.toString()] = v == true;
    });
    return AppPermissions(menus: menus, models: models, groups: groups);
  }
}

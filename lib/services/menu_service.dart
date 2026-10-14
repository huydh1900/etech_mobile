import 'dart:convert';
import 'package:http/http.dart' as http;

/// Kết quả đồng bộ menu từ backend Odoo.
class MenuSync {
  /// Tập xmlid (đã bỏ tiền tố module) mà user được phép thấy.
  final Set<String> visible;

  /// Map xmlid (đã bỏ tiền tố) -> tên menu lấy từ backend (để override nhãn).
  final Map<String, String> names;

  const MenuSync({required this.visible, required this.names});
}

/// Đọc cây menu khả dụng của user từ Odoo (`/api/menus`), phục vụ đồng bộ
/// động giữa menu mobile và backend `elab-tech`. Cùng pattern xác thực
/// cookie session_id như [SamplingService].
class MenuService {
  final String baseUrl;
  final String sessionId;

  MenuService({required this.baseUrl, required this.sessionId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Cookie': 'session_id=$sessionId',
  };

  /// Trả [MenuSync]; ném exception nếu lỗi mạng/HTTP để caller fallback tĩnh.
  Future<MenuSync> fetch() async {
    final r = await http
        .get(Uri.parse('$baseUrl/api/menus'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception('Lỗi tải menu (HTTP ${r.statusCode})');
    }
    final list = jsonDecode(r.body) as List;
    final visible = <String>{};
    final names = <String, String>{};
    for (final e in list) {
      final xmlid = (e['xmlid'] ?? '').toString();
      if (xmlid.isEmpty) continue;
      final local = xmlid.split('.').last; // bỏ tiền tố module
      visible.add(local);
      final name = (e['name'] ?? '').toString();
      if (name.isNotEmpty) names[local] = name;
    }
    return MenuSync(visible: visible, names: names);
  }
}

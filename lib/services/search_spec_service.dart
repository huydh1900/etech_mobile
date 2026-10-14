import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/search_spec.dart';

/// Tải spec Bộ lọc/Nhóm theo của 1 model từ search view Odoo
/// (GET /api/search_spec?model=...). Cache theo model trong phiên app.
/// Lỗi/offline → [debugSpecs] (dev preview, golden test) hoặc spec rỗng
/// (ẩn nút lọc — list vẫn dùng bình thường).
class SearchSpecService {
  SearchSpecService._();

  static final Map<String, SearchSpec> _cache = {};

  /// Spec giả lập theo model cho dev preview / golden test khi không có backend.
  static final Map<String, SearchSpec> debugSpecs = {};

  static Future<SearchSpec> load(String sessionId, String model) async {
    final hit = _cache[model];
    if (hit != null) return hit;
    try {
      final r = await http
          .get(
            Uri.parse(
              '${AppConfig.odooUrl}/api/search_spec'
              '?model=${Uri.encodeQueryComponent(model)}',
            ),
            headers: {'Cookie': 'session_id=$sessionId'},
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final spec = SearchSpec.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>,
      );
      _cache[model] = spec;
      return spec;
    } catch (_) {
      return debugSpecs[model] ?? SearchSpec.empty;
    }
  }
}

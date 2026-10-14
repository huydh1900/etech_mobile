// Bộ lọc / Nhóm theo / Trường tìm kiếm của list — sinh từ search view Odoo
// (GET /api/search_spec). Backend: etech_service_request/controllers/search_spec.py.
import 'dart:convert';

/// 1 lựa chọn trong spec (filter / lọc ngày / nhóm theo).
class SpecItem {
  final String name; // attr name trong search view — gửi lại backend
  final String label;
  const SpecItem(this.name, this.label);

  factory SpecItem.fromJson(Map<String, dynamic> j) =>
      SpecItem('${j['name'] ?? ''}', '${j['label'] ?? j['name'] ?? ''}');
}

/// Trường tìm kiếm (thẻ `<field>` trong search view): gõ text → chọn trường để tìm.
class SearchField {
  final String name;
  final String label;
  final String type; // kiểu field Odoo (char, many2one, integer…)
  const SearchField(this.name, this.label, [this.type = 'char']);

  bool get isNumeric =>
      type == 'integer' || type == 'float' || type == 'monetary';

  /// Có nên gợi ý trường này cho [text] không (số → chỉ khi gõ số).
  bool accepts(String text) =>
      !isNumeric || double.tryParse(text.trim().replaceAll(',', '.')) != null;

  factory SearchField.fromJson(Map<String, dynamic> j) => SearchField(
    '${j['name'] ?? ''}',
    '${j['label'] ?? j['name'] ?? ''}',
    '${j['type'] ?? 'char'}',
  );
}

class SearchSpec {
  /// Các khối filter (giữa 2 separator): cùng khối → OR, khác khối → AND.
  final List<List<SpecItem>> filters;
  final List<SpecItem> dates; // lọc theo khoảng ngày
  final List<SpecItem> groups; // nhóm theo
  final List<SearchField> fields; // trường tìm kiếm của ô search

  const SearchSpec({
    this.filters = const [],
    this.dates = const [],
    this.groups = const [],
    this.fields = const [],
  });

  static const empty = SearchSpec();

  /// Không có Bộ lọc/Nhóm theo (ẩn nút lọc). Trường search xét riêng.
  bool get isEmpty => filters.isEmpty && dates.isEmpty && groups.isEmpty;

  factory SearchSpec.fromJson(Map<String, dynamic> j) {
    List<SpecItem> items(dynamic v) => [
      for (final e in (v is List ? v : const []))
        if (e is Map<String, dynamic>) SpecItem.fromJson(e),
    ];
    return SearchSpec(
      filters: [
        for (final b
            in (j['filters'] is List ? j['filters'] as List : const []))
          if (items(b).isNotEmpty) items(b),
      ],
      dates: items(j['dates']),
      groups: items(j['groups']),
      fields: [
        for (final e in (j['fields'] is List ? j['fields'] as List : const []))
          if (e is Map<String, dynamic>) SearchField.fromJson(e),
      ],
    );
  }

  String labelOf(String name) {
    for (final f in fields) {
      if (f.name == name) return f.label;
    }
    for (final it in [...filters.expand((b) => b), ...dates, ...groups]) {
      if (it.name == name) return it.label;
    }
    return name;
  }
}

/// Lựa chọn hiện tại của người dùng (chạy server-side qua params).
class ListQuery {
  /// Facet tìm kiếm (trường, text) theo thứ tự thêm: cùng trường → OR,
  /// khác trường → AND (như Odoo).
  final List<(String, String)> facets;
  final Set<String> filters;
  final String? date; // tên filter ngày đang áp
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? groupBy;

  const ListQuery({
    this.facets = const [],
    this.filters = const {},
    this.date,
    this.dateFrom,
    this.dateTo,
    this.groupBy,
  });

  bool get hasDate => date != null && (dateFrom != null || dateTo != null);

  /// Các trường có facet (giữ thứ tự) — mỗi trường hiển thị 1 chip.
  List<String> get facetFields => [
    for (final (i, f) in facets.indexed)
      if (facets.indexWhere((x) => x.$1 == f.$1) == i) f.$1,
  ];

  List<String> valuesOf(String field) => [
    for (final f in facets)
      if (f.$1 == field) f.$2,
  ];

  /// Số mục đang bật (badge nút lọc) — tính cả tìm kiếm & nhóm theo.
  int get activeCount =>
      facetFields.length +
      filters.length +
      (hasDate ? 1 : 0) +
      (groupBy != null ? 1 : 0);

  ListQuery copyWith({
    List<(String, String)>? facets,
    Set<String>? filters,
    String? Function()? date,
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
    String? Function()? groupBy,
  }) => ListQuery(
    facets: facets ?? this.facets,
    filters: filters ?? this.filters,
    date: date != null ? date() : this.date,
    dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
    dateTo: dateTo != null ? dateTo() : this.dateTo,
    groupBy: groupBy != null ? groupBy() : this.groupBy,
  );

  ListQuery clearDate() =>
      copyWith(date: () => null, dateFrom: () => null, dateTo: () => null);

  /// Thêm facet (bỏ qua nếu trùng y hệt).
  ListQuery addFacet(String field, String value) =>
      facets.contains((field, value))
      ? this
      : copyWith(facets: [...facets, (field, value)]);

  ListQuery removeField(String field) => copyWith(
    facets: [
      for (final f in facets)
        if (f.$1 != field) f,
    ],
  );

  /// Query params gửi backend (date dạng yyyy-MM-dd).
  Map<String, String> toParams() {
    String d(DateTime x) => x.toIso8601String().substring(0, 10);
    return {
      if (facets.isNotEmpty)
        'search': jsonEncode([
          for (final f in facets) [f.$1, f.$2],
        ]),
      if (filters.isNotEmpty) 'filters': filters.join(','),
      if (hasDate) 'date': date!,
      if (hasDate && dateFrom != null) 'date_from': d(dateFrom!),
      if (hasDate && dateTo != null) 'date_to': d(dateTo!),
      'group_by': ?groupBy,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ListQuery &&
      _sameFacets(other.facets, facets) &&
      other.filters.length == filters.length &&
      other.filters.containsAll(filters) &&
      other.date == date &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.groupBy == groupBy;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(facets),
    Object.hashAllUnordered(filters),
    date,
    dateFrom,
    dateTo,
    groupBy,
  );

  static bool _sameFacets(List<(String, String)> a, List<(String, String)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

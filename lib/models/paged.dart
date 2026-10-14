// Kết quả list phân trang chung cho mọi API list (server-side filter/search/paging).
// Map với response {items, total, all_count, counts, offset, limit}.

/// Nối params Bộ lọc/Nhóm theo (search spec) vào query string đã có '?'.
String extraQuery(Map<String, String>? params) =>
    params == null || params.isEmpty
    ? ''
    : params.entries
          .map(
            (e) =>
                '&${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
          )
          .join();

/// Một nhóm khi list được "Nhóm theo" (server trả 'groups': [{key,label,count}]).
class PagedGroup {
  final String key;
  final String label;
  final int count;
  const PagedGroup(this.key, this.label, this.count);
}

class PagedResult<T> {
  final List<T> items;
  final int total; // tổng record của filter hiện tại
  final int allCount; // tổng record bỏ qua filter trạng thái
  final Map<String, int> counts; // {state: số lượng}
  final int offset;
  final int limit;
  final List<PagedGroup> groups; // rỗng khi không nhóm

  PagedResult({
    required this.items,
    required this.total,
    required this.allCount,
    required this.counts,
    required this.offset,
    required this.limit,
    this.groups = const [],
  });

  bool get hasMore => offset + items.length < total;

  factory PagedResult.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) parse,
  ) {
    int asInt(dynamic v) => v is num ? v.toInt() : 0;
    final rawCounts = (j['counts'] is Map ? (j['counts'] as Map) : const {});
    final counts = <String, int>{};
    rawCounts.forEach((k, v) {
      counts[k.toString()] = asInt(v);
    });
    return PagedResult<T>(
      items: (j['items'] is List ? j['items'] as List : const [])
          .map((e) => parse(e as Map<String, dynamic>))
          .toList(),
      total: asInt(j['total']),
      allCount: j['all_count'] is num
          ? asInt(j['all_count'])
          : asInt(j['total']),
      counts: counts,
      offset: asInt(j['offset']),
      limit: asInt(j['limit']),
      groups: [
        for (final g in (j['groups'] is List ? j['groups'] as List : const []))
          if (g is Map)
            PagedGroup(
              '${g['key'] ?? ''}',
              '${g['label'] ?? ''}',
              asInt(g['count']),
            ),
      ],
    );
  }
}

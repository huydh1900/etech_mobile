/// Định dạng ngày/giờ kiểu Việt Nam từ chuỗi ISO mà backend Odoo trả về.
///
/// - `'yyyy-MM-dd'`            → `'dd/MM/yyyy'`
/// - `'yyyy-MM-dd HH:mm[:ss]'` → `'dd/MM/yyyy HH:mm'` (bỏ giây)
///
/// Tự nhận biết có phần giờ hay không nên dùng được cho cả field `date` lẫn
/// `datetime`. Chuỗi rỗng → `''`. Không parse được → trả NGUYÊN bản (không nuốt
/// hay đổi dữ liệu lạ).
///
/// LƯU Ý: KHÔNG đổi múi giờ — giữ nguyên giá trị đồng hồ backend trả, chỉ đổi
/// CÁCH TRÌNH BÀY. Đây là hàm thuần trình bày; giữ chuỗi ISO gốc ở model cho
/// các logic cần (date-picker, cache-busting, gửi ngược lên backend).
String formatVn(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  // Bỏ hậu tố múi giờ ("+07:00"/"Z") TRƯỚC khi parse: backend đã localize sẵn
  // giờ tường (context_timestamp). Giữ NGUYÊN giờ tường, không để DateTime.parse
  // quy đổi về UTC làm lệch giờ.
  final naive = s.replaceFirst(RegExp(r'(Z|[+-]\d{2}:?\d{2})$'), '');
  final dt = DateTime.tryParse(naive.replaceFirst(' ', 'T'));
  if (dt == null) return raw;
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  // Có phần giờ khi chuỗi gốc dài hơn 'yyyy-MM-dd' (10 ký tự) và chứa ':'.
  final hasTime = s.length > 10 && s.contains(':');
  return hasTime ? '$date ${two(dt.hour)}:${two(dt.minute)}' : date;
}

/// Định dạng meta "Tạo bởi / Cập nhật lần cuối" ở header formview:
/// `'yyyy-MM-dd HH:mm[:ss]'` → `'HH:mm dd/MM/yyyy'` (giờ trước, ngày sau).
///
/// Cùng quy ước với [formatVn]: KHÔNG đổi múi giờ, chỉ đổi cách trình bày;
/// không parse được → trả nguyên bản.
String metaDt(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  final naive = s.replaceFirst(RegExp(r'(Z|[+-]\d{2}:?\d{2})$'), '');
  final dt = DateTime.tryParse(naive.replaceFirst(' ', 'T'));
  if (dt == null) return raw;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)} '
      '${two(dt.day)}/${two(dt.month)}/${dt.year}';
}

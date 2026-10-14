import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'status_chip.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// BỘ WIDGET DÙNG CHUNG cho màn LIST + DETAIL (formview) — nguồn sự thật duy
/// nhất để mọi màn có cùng "ngôn ngữ thiết kế".
///
/// FORMVIEW theo format Odoo mobile (sheet) nhưng chỉnh chu hơn:
///   • [DetailHeader] — dải nền sáng cùng họ màu logo (đồng nhất header trang
///     chủ): mã phiếu + chip trạng thái.
///   • [InfoSection]  — nhóm field: THANH TIÊU ĐỀ teal nhạt (style trang chủ),
///     thân là các hàng field XẾP DỌC (nhãn đậm trên, giá trị to bên dưới) ngăn
///     bởi gạch mảnh — đọc tốt cho text dài tiếng Việt.
///   • [InfoRow]      — 1 hàng field (char/date/number/selection-pill/link).
///   • [InfoChips]    — hàng many2many_tags (wrap chip).
///   • [LineTable] + [LineCol] — one2many/bảng biểu dạng cột (hàng tiêu đề +
///     cột "#" + sọc xen kẽ + cuộn ngang) như formview Odoo.
/// ───────────────────────────────────────────────────────────────────────────

/// Marker cho các hàng "field" trong [InfoSection]; dùng để tự chèn gạch ngăn
/// chỉ giữa các hàng field (không chèn quanh thẻ dòng / divider thủ công).
mixin _FormRow on Widget {}

/// ───────────────────────────────────────────────────────────────────────────
/// TOKEN LẤY 1:1 TỪ CSS FORMVIEW ODOO (backend `etech_field_sampling`,
/// `static/src/scss/sampling_program_paper.scss` — nhánh media <992px, tức
/// layout Odoo dùng trên điện thoại). Giữ nguyên số để formview mobile của app
/// trùng khít formview Odoo web; sửa CSS backend thì cập nhật lại ở đây.
/// ───────────────────────────────────────────────────────────────────────────
/// Bo góc thẻ section — theo thẻ nhóm chức năng trang chủ (không theo 7px
/// của Odoo) để đồng nhất giao diện.
const double _kCardRadius = AppRadius.lg;

/// `.o_etech_card_header` ở <768px: font-size .9rem (14px), padding 8px 12px.
/// Màu nền KHÔNG theo Odoo (#1E293B) nữa mà theo style trang chủ (teal nhạt)
/// để mọi màn đồng nhất với trang chủ.
const double _kCardHeaderFs = 14.4; // .9rem
const double _kCardHeaderLh = 1.5; // line-height 21.6px

/// `.o_etech_kv_table td.lbl` (<992px) — .8rem (13px), weight 600, color
/// #475569, padding 4px 14px 0; value `td:not(.lbl)` padding 0 14px 4px; `tr`
/// padding 4px 0 → tổng đệm dọc 8px. Cỡ chữ giá trị = 14px (nền form Odoo).
const double _kLabelFs = 12.8; // .8rem — line-height 19.2px (1.5)
const double _kValueFs = 14; // font nền form Odoo — line-height 21px (1.5)
const double _kRowPadH = 14;

/// `.o_etech_detail_table tr` (<768px): flex cột, padding 7px 12px; `td.lbl`
/// margin-bottom 3px. Hàng có số thứ tự: grid `40px 1fr`, padding 7px 12px 7px 0.
const double _kIdxRowPadH = 12;
const double _kIdxW = 40;

/// Số La Mã (1→I, 2→II…) để đánh số tiêu đề section như formview Odoo
/// ("I. Thông tin chung", "II. …").
String _roman(int n) {
  const table = <(int, String)>[
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];
  var v = n;
  final sb = StringBuffer();
  for (final (val, sym) in table) {
    while (v >= val) {
      sb.write(sym);
      v -= val;
    }
  }
  return sb.toString();
}

/// Header chi tiết: dải nền sáng cùng họ màu logo bo góc dưới (đồng nhất header
/// trang chủ), chứa mã phiếu lớn + dòng phụ + chip trạng thái. Đặt làm phần tử
/// đầu của ListView chi tiết (full-bleed, không padding ngang).
class DetailHeader extends StatelessWidget {
  /// Dòng nổi bật nhất — thường là mã phiếu (vd YCPT-2026-0001).
  final String code;

  /// Dòng phụ tuỳ chọn (tên/khách hàng…).
  final String? subtitle;

  /// Nhãn trạng thái; rỗng → ẩn chip.
  final String stateLabel;

  /// Màu trạng thái (thường từ [statusColorFor]).
  final Color stateColor;

  const DetailHeader({
    super.key,
    required this.code,
    this.subtitle,
    this.stateLabel = '',
    this.stateColor = Colors.white,
  });

  /// Dựng nhanh từ mã state nghiệp vụ.
  factory DetailHeader.fromState({
    Key? key,
    required String code,
    String? subtitle,
    required String state,
    required String stateLabel,
  }) => DetailHeader(
    key: key,
    code: code,
    subtitle: subtitle,
    stateLabel: stateLabel,
    stateColor: statusColorFor(state),
  );

  @override
  Widget build(BuildContext context) {
    final sub = subtitle?.trim() ?? '';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        // Nền luôn sáng (không theo dark mode) như header trang chủ.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE4F1F9), Color(0xFFE3F4EE)],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stateLabel.isNotEmpty) ...[
            _StatePill(label: stateLabel, color: stateColor),
            const SizedBox(height: 12),
          ],
          Text(
            code.isEmpty ? '—' : code,
            style: const TextStyle(
              fontFamily: kBrandFont,
              fontSize: AppType.headline,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B2E52),
              letterSpacing: -0.2,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(
                fontSize: AppType.bodyLg,
                color: Color(0xFF5B7083),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Một cặp nhãn–giá trị ở dòng subtitle của [OdooFormHeader] (vd "Hồ sơ: X").
class HeaderSub {
  final String label;
  final String value;

  /// Tô màu primary (như link Odoo) thay vì ink.
  final bool link;
  const HeaderSub(this.label, this.value, {this.link = false});
}

/// Header formview — dựng theo đúng formview Odoo trên điện thoại (xem CSS
/// `.o_etech_status_banner` / `.o_etech_report_doc_title` trong
/// `etech_field_sampling/static/src/scss/sampling_program_paper.scss`):
///   1. pill trạng thái căn phải (statusbar Odoo),
///   2. banner meta nền nhạt viền mảnh: "Tạo bởi …" / "Cập nhật lần cuối …",
///      xếp DỌC như breakpoint <992px,
///   3. tiêu đề tài liệu IN HOA căn giữa + dòng phụ "Nhãn: giá trị" cỡ nhỏ.
class OdooFormHeader extends StatelessWidget {
  final String stateLabel;

  /// Mã state nghiệp vụ để lấy màu pill ([statusColorFor]). Rỗng → màu mặc định.
  final String state;
  final String title;
  final List<HeaderSub> subtitle;
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;

  const OdooFormHeader({
    super.key,
    required this.title,
    this.stateLabel = '',
    this.state = '',
    this.subtitle = const [],
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
  });

  @override
  Widget build(BuildContext context) {
    final accent = state.isEmpty ? AppColors.primary : statusColorFor(state);
    final subSpans = <TextSpan>[];
    for (final sub in subtitle) {
      if (sub.value.isEmpty) continue;
      if (subSpans.isNotEmpty) {
        subSpans.add(const TextSpan(text: '   |   '));
      }
      subSpans.add(TextSpan(text: '${sub.label}: '));
      subSpans.add(
        TextSpan(
          text: sub.value,
          style: TextStyle(
            color: sub.link ? AppColors.primary : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stateLabel.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: _StatePill(label: stateLabel, color: accent),
            ),
          if (createdBy.isNotEmpty || updatedBy.isNotEmpty) ...[
            const SizedBox(height: 8),
            _StatusBanner(
              createdBy: createdBy,
              createdAt: createdAt,
              updatedBy: updatedBy,
              updatedAt: updatedAt,
            ),
          ],
          const SizedBox(height: 12),
          // `.o_etech_report_doc_title h2` — 1.1rem, bold, in hoa, căn giữa.
          Center(
            child: Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                // `.o_etech_report_doc_title h2`: 1.1rem, weight 500,
                // line-height 21.12px, letter-spacing .02em.
                fontSize: 17.6,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
                letterSpacing: 0.35,
                height: 1.2,
              ),
            ),
          ),
          if (subSpans.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text.rich(
                TextSpan(children: subSpans),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppType.caption,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.o_etech_status_banner` (<992px): nền nhạt, viền mảnh, bo 8px, 2 dòng meta
/// xếp dọc — người bên trái, thời điểm ngay sau.
class _StatusBanner extends StatelessWidget {
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;

  const _StatusBanner({
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (createdBy.isNotEmpty)
            _MetaLine(label: 'Tạo bởi', name: createdBy, at: createdAt),
          if (createdBy.isNotEmpty && updatedBy.isNotEmpty)
            const SizedBox(height: 2),
          if (updatedBy.isNotEmpty)
            _MetaLine(
              label: 'Cập nhật lần cuối',
              name: updatedBy,
              at: updatedAt,
            ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String name;
  final String at;

  const _MetaLine({required this.label, required this.name, this.at = ''});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          if (at.isNotEmpty) TextSpan(text: '  •  $at'),
        ],
      ),
      style: TextStyle(
        // `.o_etech_status_banner` <576px: font-size .78rem, line-height 1.35.
        fontSize: 12.5,
        color: AppColors.inkMuted,
        height: 1.35,
      ),
    );
  }
}

/// Pill trạng thái (statusbar Odoo thu gọn trên điện thoại).
class _StatePill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.14),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppType.caption,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// ─────────────────────── Khung sheet thu gọn được ───────────────────────────

/// Card "sheet" dùng chung cho [InfoSection] và [LineGroup]: thanh tiêu đề teal
/// nhạt (icon teal + tiêu đề đậm + badge số đếm) — style thẻ trang chủ.
class _SheetCard extends StatefulWidget {
  final IconData? icon;
  final String title;

  /// Số thứ tự section (1-based) → tiền tố La Mã "I. ", "II. "… như Odoo. null → ẩn.
  final int? number;
  final int? count;
  final EdgeInsets bodyPadding;
  final List<Widget> body;

  const _SheetCard({
    this.icon,
    required this.title,
    this.number,
    this.count,
    required this.bodyPadding,
    required this.body,
  });

  @override
  State<_SheetCard> createState() => _SheetCardState();
}

class _SheetCardState extends State<_SheetCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh tiêu đề TĨNH (không thu gọn) — bám formview Odoo.
          Container(
            width: double.infinity,
            color: AppColors.teal.withValues(alpha: 0.08),
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 17, color: AppColors.teal),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.number != null
                        ? '${_roman(widget.number!)}. ${widget.title}'
                        : widget.title,
                    style: TextStyle(
                      fontFamily: kBrandFont,
                      fontSize: _kCardHeaderFs,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: _kCardHeaderLh,
                    ),
                  ),
                ),
                if (widget.count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: TextStyle(
                        fontSize: AppType.caption,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: widget.bodyPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.body,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section card (nhóm field) chi tiết: thanh tiêu đề tối + danh sách hàng field
/// xếp dọc, tự chèn gạch mảnh giữa các hàng. Tự ẩn khi mọi con là [SizedBox]
/// rỗng (các hàng giá trị trống).
class InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  /// Icon nhỏ cạnh tiêu đề (tuỳ chọn) — gợi ý nhóm thông tin.
  final IconData? icon;

  /// Số thứ tự section → tiền tố La Mã "I. ", "II. "… như Odoo. null → ẩn.
  final int? number;

  /// Số đếm hiển thị ở badge bên phải tiêu đề. null → ẩn.
  final int? count;

  const InfoSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.number,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final visible = children.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    // Chèn gạch mảnh GIỮA hai hàng field liên tiếp.
    final body = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      if (i != 0 && visible[i - 1] is _FormRow && visible[i] is _FormRow) {
        body.add(Divider(height: 1, thickness: 1, color: AppColors.divider));
      }
      body.add(visible[i]);
    }

    return _SheetCard(
      icon: icon,
      title: title,
      number: number,
      count: count,
      bodyPadding: EdgeInsets.zero,
      body: body,
    );
  }
}

/// Hàng field xếp dọc: NHÃN đậm ở trên, GIÁ TRỊ to bên dưới (full-width). Tự ẩn
/// khi [value] rỗng. Hỗ trợ:
///  • [valueColor] — tô màu giá trị (vd danger cho cảnh báo).
///  • [pill] — render giá trị dạng pill mềm (field selection/radio).
///  • [onTap] — render giá trị như liên kết (màu primary) + bắt chạm.
///  • [mono] — giãn chữ nhẹ cho mã/code.
class InfoRow extends StatelessWidget with _FormRow {
  final String label;
  final String value;
  final Color? valueColor;
  final bool pill;

  /// Render giá trị như 1 lựa chọn radio đã chọn (chấm tròn đặc + nhãn) — khớp
  /// field selection/radio của Odoo.
  final bool radio;
  final bool mono;
  final VoidCallback? onTap;

  /// Số thứ tự hiển thị ở máng trái (thẳng cột "#" của [LineTable]) — dùng cho
  /// các dòng đánh số 2, 3, 4 trong mục IV của formview Odoo. null → không có.
  final int? index;

  const InfoRow(
    this.label,
    this.value, {
    super.key,
    this.valueColor,
    this.pill = false,
    this.radio = false,
    this.mono = false,
    this.onTap,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Hàng có số thứ tự (mục IV formview Odoo) có thể CHỈ có nhãn, không giá trị.
    if (value.isEmpty && index == null) return const SizedBox.shrink();
    final linked = onTap != null;
    final color = linked ? AppColors.primary : (valueColor ?? AppColors.ink);

    Widget valueWidget;
    if (radio) {
      final c = valueColor ?? AppColors.primary;
      valueWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c, width: 2),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: _kValueFs,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),
        ],
      );
    } else if (pill) {
      final c = valueColor ?? AppColors.primary;
      valueWidget = Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: c.withValues(alpha: 0.20)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppType.body,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ),
      );
    } else {
      valueWidget = Text(
        value,
        style: TextStyle(
          fontSize: _kValueFs,
          color: color,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: mono ? 0.2 : 0,
          decoration: linked ? TextDecoration.underline : null,
          decorationColor: linked
              ? AppColors.primary.withValues(alpha: 0.4)
              : null,
        ),
      );
      if (linked) {
        valueWidget = GestureDetector(onTap: onTap, child: valueWidget);
      }
    }

    return _IndexedRow(
      index: index,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: _kLabelFs,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          if (value.isNotEmpty) ...[const SizedBox(height: 2), valueWidget],
        ],
      ),
    );
  }
}

/// Bọc một hàng field: nếu có [index] thì chừa máng trái 34px chứa số (thẳng
/// hàng với cột "#" của [LineTable], như grid `td.idx` của Odoo trên mobile).
class _IndexedRow extends StatelessWidget {
  final int? index;
  final Widget child;
  const _IndexedRow({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    if (index == null) {
      // `.o_etech_kv_table`: tr 4px + td 4px = 8px trên/dưới, 14px hai bên.
      return Padding(
        padding: const EdgeInsets.fromLTRB(_kRowPadH, 8, _kRowPadH, 8),
        child: child,
      );
    }
    // `tr:has(td.idx)`: grid 40px + nội dung, padding 7px 12px 7px 0.
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 7, _kIdxRowPadH, 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _kIdxW,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppType.body,
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Ô nhập dùng chung cho [InfoEditRow] / [InfoEditSelect] — gọn, nền chìm, để
/// field sửa được vẫn nằm vừa trong hàng của `.o_etech_kv_table`.
InputDecoration _editDecoration({String? hint}) => InputDecoration(
  isDense: true,
  hintText: hint,
  hintStyle: TextStyle(fontSize: _kValueFs, color: AppColors.inkMuted),
  filled: true,
  fillColor: AppColors.bg,
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: AppColors.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: AppColors.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: AppColors.primary, width: 1.6),
  ),
);

/// Nhãn của một hàng field sửa được: giống hệt nhãn [InfoRow], thêm dấu `*` đỏ
/// khi bắt buộc (khớp `<span class="text-danger">*</span>` của formview Odoo).
/// Dùng [Text.rich] chứ không phải `RichText`: `RichText` KHÔNG kế thừa
/// `DefaultTextStyle` nên mất font Inter của app (chữ thành ô vuông).
Widget _editLabel(String label, bool required) => Text.rich(
  TextSpan(
    text: label,
    style: TextStyle(
      fontSize: _kLabelFs,
      fontWeight: FontWeight.w600,
      color: AppColors.inkSoft,
      height: 1.5,
    ),
    children: required
        ? [
            TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.danger),
            ),
          ]
        : const [],
  ),
);

/// Hàng field CÓ THỂ SỬA — cùng ngữ pháp thị giác với [InfoRow] (nhãn nhỏ ở
/// trên, giá trị bên dưới, cùng đệm hàng) nhưng giá trị là ô nhập.
///
/// Có widget này để formview mobile giữ ĐÚNG bố cục Odoo cả khi biên bản còn
/// nháp: Odoo dùng chung một form view cho mọi trạng thái, chỉ đổi `readonly`
/// từng field — app cũng vậy, thay vì đổi hẳn sang một form phẳng khác.
///
/// Khác [InfoRow]: KHÔNG tự ẩn khi rỗng (field trống chính là chỗ cần nhập).
class InfoEditRow extends StatelessWidget with _FormRow {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  /// Hiện dấu `*` đỏ sau nhãn — khớp `required="show_required"` bên Odoo.
  final bool required;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const InfoEditRow(
    this.label,
    this.value,
    this.onChanged, {
    super.key,
    this.required = false,
    this.hint,
    this.keyboard,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kRowPadH, 8, _kRowPadH, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editLabel(label, required),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            keyboardType: keyboard,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            style: TextStyle(fontSize: _kValueFs, color: AppColors.ink),
            decoration: _editDecoration(hint: hint),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Hàng field selection CÓ THỂ SỬA — bản dropdown của [InfoEditRow]. [options]
/// là cặp (value, label) theo đúng selection của field Odoo.
class InfoEditSelect extends StatelessWidget with _FormRow {
  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String?> onChanged;
  final bool required;
  final String? hint;

  const InfoEditSelect(
    this.label,
    this.value,
    this.options,
    this.onChanged, {
    super.key,
    this.required = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final known = options.any((o) => o.$1 == value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kRowPadH, 8, _kRowPadH, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editLabel(label, required),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: known ? value : null,
            isExpanded: true,
            // Dropdown KHÔNG merge `style` với theme như TextField → phải kế
            // thừa từ DefaultTextStyle, nếu không mất font Inter.
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(fontSize: _kValueFs, color: AppColors.ink),
            decoration: _editDecoration(hint: hint),
            items: [
              for (final o in options)
                DropdownMenuItem(value: o.$1, child: Text(o.$2)),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Hàng "Mã mẫu ban đầu" — dựng theo đúng block Odoo
/// `.o_etech_initial_sample_block` (`initial_sample_tree.scss`): mã mẹ CĂN GIỮA,
/// weight 600, màu xanh nước biển #1E88E5; ngay dưới là các mã con dạng
/// many2many_tags mặc định (pill xám nhạt). Tự ẩn khi không có dữ liệu.
class InfoCodeTree extends StatelessWidget with _FormRow {
  final String label;

  /// Mã mẫu mẹ (`parent_sample_code`).
  final String parent;

  /// Mã mẫu con (`initial_sample_code_ids`).
  final List<String> children;

  const InfoCodeTree(
    this.label, {
    super.key,
    required this.parent,
    this.children = const [],
  });

  /// `.o_etech_isb_parent` — color: #1e88e5.
  static const Color _parentColor = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    final items = children.where((v) => v.trim().isNotEmpty).toList();
    if (parent.isEmpty && items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kRowPadH, 8, _kRowPadH, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: _kLabelFs,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 1),
          if (parent.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  parent,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: _kValueFs,
                    fontWeight: FontWeight.w600,
                    color: _parentColor,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          if (items.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final v in items)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      // Tag màu 0 của Odoo: pill xám nhạt, chữ tối.
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      v,
                      style: TextStyle(
                        fontSize: AppType.caption,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Hàng `widget="radio"` của Odoo (vd "Tiêu chuẩn so sánh"): liệt kê ĐỦ các
/// lựa chọn, ô đã chọn là chấm tròn đặc, ô còn lại là vòng tròn rỗng.
/// `options="{'horizontal': true}"` → xếp ngang, tự xuống dòng khi hẹp.
class InfoRadioGroup extends StatelessWidget with _FormRow {
  final String label;

  /// Danh sách nhãn lựa chọn theo đúng thứ tự selection của backend.
  final List<String> options;

  /// Nhãn đang được chọn.
  final String selected;

  const InfoRadioGroup(
    this.label, {
    super.key,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return _OptionRow(
      label: label,
      children: [
        for (final o in options)
          _OptionMark(label: o, checked: o == selected, circle: true),
      ],
    );
  }
}

/// Hàng `widget="many2many_checkboxes"` của Odoo (vd "Phương tiện phục vụ hoạt
/// động…"): liệt kê ĐỦ lựa chọn, ô đã chọn có dấu tích.
class InfoCheckboxGroup extends StatelessWidget with _FormRow {
  final String label;
  final List<String> options;
  final List<String> selected;

  /// Số thứ tự ở máng trái (xem [InfoRow.index]).
  final int? index;

  const InfoCheckboxGroup(
    this.label, {
    super.key,
    required this.options,
    required this.selected,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    // many2many_checkboxes của Odoo xếp DỌC, mỗi lựa chọn 1 dòng.
    return _OptionRow(
      label: label,
      index: index,
      vertical: true,
      children: [
        for (final o in options)
          _OptionMark(label: o, checked: selected.contains(o), circle: false),
      ],
    );
  }
}

/// Khung chung cho 2 widget lựa chọn: nhãn trên, các ô lựa chọn wrap bên dưới.
class _OptionRow extends StatelessWidget {
  final String label;
  final List<Widget> children;

  /// true → mỗi lựa chọn 1 dòng (checkbox); false → xếp ngang (radio).
  final bool vertical;
  final int? index;

  const _OptionRow({
    required this.label,
    required this.children,
    this.vertical = false,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return _IndexedRow(
      index: index,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: _kLabelFs,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          if (vertical)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i != 0) const SizedBox(height: 6),
                  children[i],
                ],
              ],
            )
          else
            Wrap(spacing: 18, runSpacing: 6, children: children),
        ],
      ),
    );
  }
}

/// Một ô lựa chọn: vòng tròn (radio) hoặc ô vuông (checkbox) + nhãn. Ô chưa
/// chọn vẫn hiện (viền mảnh, chữ mờ) giống formview Odoo ở chế độ chỉ đọc.
class _OptionMark extends StatelessWidget {
  final String label;
  final bool checked;
  final bool circle;

  const _OptionMark({
    required this.label,
    required this.checked,
    required this.circle,
  });

  /// Odoo tô radio/checkbox đã chọn bằng màu cam #EA580C
  /// (`.o_radio_input.form-check-input:checked` trong
  /// `sampling_program_paper.scss`) — `AppColors.orange` đúng bằng giá trị này
  /// ở palette sáng, và tự đổi sang tông cam sáng hơn ở dark mode.
  Color get _accent => AppColors.orange;

  @override
  Widget build(BuildContext context) {
    final c = checked ? _accent : AppColors.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle ? null : BorderRadius.circular(3),
            color: (!circle && checked) ? _accent : null,
            border: Border.all(
              color: checked ? _accent : AppColors.border,
              width: checked ? 2 : 1.4,
            ),
          ),
          alignment: Alignment.center,
          child: circle
              ? (checked
                    ? Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null)
              : (checked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                    : null),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: _kValueFs,
            fontWeight: checked ? FontWeight.w500 : FontWeight.w400,
            color: checked ? AppColors.ink : c,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Dải tiêu đề phụ trong card (`tr.subhead-row` / `.o_etech_vehicle_col_header`
/// của Odoo): nền #F1F5F9, chữ đậm .8rem màu #1E293B, có kẻ trên/dưới.
class InfoSubhead extends StatelessWidget with _FormRow {
  final String text;

  /// Icon nhỏ đứng trước (Odoo dùng fa-link / fa-pencil ở mục 4).
  final IconData? icon;

  const InfoSubhead(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: _kRowPadH, vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.inkSoft),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.64, // .79rem của `tr.subhead-row`
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Đoạn ghi chú in nghiêng, chữ mờ (vd khối tên/địa chỉ đơn vị lấy mẫu ở mục 2
/// formview Odoo: `.px-3.py-2.fst-italic.small.text-muted`).
class InfoNote extends StatelessWidget with _FormRow {
  final String text;
  const InfoNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kRowPadH, 8, _kRowPadH, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppType.caption,
          fontStyle: FontStyle.italic,
          color: AppColors.inkMuted,
          height: 1.45,
        ),
      ),
    );
  }
}

/// Câu văn chạy ngang trong card (`.o_etech_info_row.inline-text` — vd mục 12
/// "Biên bản lập hồi [thời điểm] để xác nhận lấy mẫu đã hoàn thành.").
class InfoSentence extends StatelessWidget with _FormRow {
  final String before;
  final String value;
  final String after;

  const InfoSentence({
    super.key,
    required this.before,
    required this.value,
    this.after = '',
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kRowPadH, 8, _kRowPadH, 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: before),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            TextSpan(text: after),
          ],
        ),
        style: TextStyle(
          fontSize: _kValueFs,
          color: AppColors.inkSoft,
          height: 1.45,
        ),
      ),
    );
  }
}

/// Hàng many2many_tags xếp dọc: nhãn đậm ở trên, wrap các chip mềm bên dưới. Tự
/// ẩn khi rỗng. Mỗi giá trị là 1 chip bo tròn nền nhạt theo [color].
class InfoChips extends StatelessWidget with _FormRow {
  final String label;
  final List<String> values;
  final Color? color;

  const InfoChips(this.label, this.values, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final items = values.where((v) => v.trim().isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final c = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kRowPadH, 8, _kRowPadH, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: _kLabelFs,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in items)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: c.withValues(alpha: 0.20)),
                  ),
                  child: Text(
                    v,
                    style: TextStyle(
                      fontSize: AppType.body,
                      fontWeight: FontWeight.w600,
                      color: c,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────── One2many / bảng biểu ───────────────────────────────

/// Định nghĩa 1 cột của [LineTable].
class LineCol {
  final String label;

  /// Bề rộng cố định của cột (px). Cột text dài → đặt rộng hơn.
  final double width;

  /// Canh phải (dùng cho cột số/khối lượng).
  final bool numeric;

  /// Canh giữa — khớp `text-align: center` mà CSS Odoo đặt cho vài cột (vd
  /// Loại mẫu / Tên mẫu / Số tem niêm phong ở mục 5 biên bản hiện trường).
  final bool center;

  const LineCol(
    this.label, {
    this.width = 104,
    this.numeric = false,
    this.center = false,
  });
}

/// Bảng biểu one2many dạng cột (khớp formview Odoo): thanh tiêu đề tối thu gọn
/// được + bảng có hàng tiêu đề, cột "#" tự đánh số, các hàng sọc xen kẽ, cuộn
/// ngang khi tổng bề rộng vượt màn hình. Tự ẩn khi không có dòng.
class LineTable extends StatelessWidget {
  final String title;
  final IconData? icon;
  final int? number;
  final List<LineCol> columns;

  /// Mỗi phần tử là 1 hàng; độ dài khớp [columns]. Ô rỗng để trống.
  final List<List<String>> rows;

  /// Hàng phụ nằm NGAY DƯỚI bảng, trong cùng card — khớp formview Odoo (vd mục
  /// IV "Phương pháp lấy mẫu" có thêm các dòng đánh số 2, 3, 4).
  final List<Widget> extra;

  /// `true` → không có dòng nào vẫn hiện card + hàng tiêu đề (như formview
  /// Odoo giữ bảng rỗng). Mặc định `false`: ẩn hẳn để tránh card trống.
  final bool showWhenEmpty;

  /// Widget nằm TRÊN bảng, trong cùng card (vd khối ghi chú đơn vị lấy mẫu ở
  /// mục 2 formview biên bản hiện trường).
  final List<Widget> leading;

  /// Ô dạng WIDGET thay cho text — dùng khi cột có widget riêng bên Odoo
  /// (many2many_tags, ô nhập, block nhiều dòng…). Khi có, [rows] chỉ còn dùng
  /// để biết số dòng. Độ dài mỗi phần tử khớp [columns].
  final List<List<Widget>>? cellRows;

  /// Bề rộng cột "#". Odoo bóp còn 28px ở bảng mục 5 biên bản hiện trường
  /// (`o_list_row_number` trong `sampling_program_paper.scss`).
  final double idxWidth;

  const LineTable({
    super.key,
    required this.title,
    this.icon,
    this.number,
    required this.columns,
    required this.rows,
    this.extra = const [],
    this.showWhenEmpty = false,
    this.leading = const [],
    this.cellRows,
    this.idxWidth = _kIdxW,
  });

  Widget _cell(
    String text,
    double width,
    bool header,
    bool numeric, {
    bool center = false,
  }) {
    return Container(
      width: width,
      // Odoo mobile: th padding 8px 10px / td 7px 10px, chữ 14px; header đậm
      // xám (#888) trên nền #F1F5F9.
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: header ? 8 : 7),
      alignment: numeric
          ? Alignment.centerRight
          : (center ? Alignment.center : Alignment.centerLeft),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: header ? _kLabelFs : _kValueFs,
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
          color: header ? AppColors.inkMuted : AppColors.inkSoft,
          height: 1.35,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleExtra = extra.where((w) => w is! SizedBox).toList();
    if (rows.isEmpty &&
        (cellRows?.isEmpty ?? true) &&
        visibleExtra.isEmpty &&
        leading.isEmpty &&
        !showWhenEmpty) {
      return const SizedBox.shrink();
    }
    final rowCount = cellRows?.length ?? rows.length;
    final totalW = idxWidth + columns.fold<double>(0, (s, c) => s + c.width);

    Widget headerRow() => Container(
      color: AppColors.bg,
      child: Row(
        children: [
          SizedBox(
            width: idxWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '#',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _kLabelFs,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
          for (final c in columns)
            _cell(c.label, c.width, true, c.numeric, center: c.center),
        ],
      ),
    );

    Widget dataRow(int i) => Container(
      color: i.isOdd ? AppColors.bg.withValues(alpha: 0.5) : AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: idxWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${i + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppType.body,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
          for (var c = 0; c < columns.length; c++)
            if (cellRows != null)
              SizedBox(
                width: columns[c].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: c < cellRows![i].length
                      ? cellRows![i][c]
                      : const SizedBox.shrink(),
                ),
              )
            else
              _cell(
                c < rows[i].length ? rows[i][c] : '',
                columns[c].width,
                false,
                columns[c].numeric,
                center: columns[c].center,
              ),
        ],
      ),
    );

    final table = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        headerRow(),
        Divider(height: 1, thickness: 1, color: AppColors.border),
        for (var i = 0; i < rowCount; i++) ...[
          if (i != 0)
            Divider(height: 1, thickness: 1, color: AppColors.divider),
          dataRow(i),
        ],
      ],
    );

    return _SheetCard(
      icon: icon,
      title: title,
      number: number,
      // Formview Odoo không hiện badge đếm dòng trên tiêu đề mục.
      count: null,
      bodyPadding: EdgeInsets.zero,
      body: [
        for (final w in leading.where((w) => w is! SizedBox)) ...[
          w,
          Divider(height: 1, thickness: 1, color: AppColors.divider),
        ],
        if (rowCount > 0 || showWhenEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: totalW, child: table),
          ),
        for (var i = 0; i < visibleExtra.length; i++) ...[
          Divider(height: 1, thickness: 1, color: AppColors.divider),
          visibleExtra[i],
        ],
      ],
    );
  }
}

/// Một mẩu metadata trên [ListCard]: icon nhỏ + text (vd 📍 địa điểm, 📅 ngày).
class ListMeta {
  final IconData icon;
  final String text;
  const ListMeta(this.icon, this.text);
}

/// Thẻ item danh sách dùng chung: dải màu trạng thái bên trái + tiêu đề + chip
/// trạng thái + các dòng metadata + chevron. Phân cấp rõ, đồng nhất mọi list.
class ListCard extends StatelessWidget {
  /// Dòng tiêu đề (mã/tên) — đậm.
  final String title;

  /// Dòng phụ gộp (tuỳ chọn) — vd "Khách hàng • Loại mẫu • Tên mẫu".
  final String? subtitle;

  /// Các dòng metadata có icon (tuỳ chọn) — ưu tiên dùng thay [subtitle] khi
  /// muốn cấu trúc rõ ràng.
  final List<ListMeta> meta;

  /// Nhãn + màu trạng thái (chip góc phải + dải màu trái). Rỗng → không hiện.
  final String stateLabel;
  final Color stateColor;

  final VoidCallback onTap;

  const ListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.stateLabel = '',
    this.stateColor = Colors.transparent,
    required this.onTap,
  });

  factory ListCard.fromState({
    Key? key,
    required String title,
    String? subtitle,
    List<ListMeta> meta = const [],
    required String state,
    required String stateLabel,
    required VoidCallback onTap,
  }) => ListCard(
    key: key,
    title: title,
    subtitle: subtitle,
    meta: meta,
    stateLabel: stateLabel,
    stateColor: statusColorFor(state),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final sub = subtitle?.trim() ?? '';
    final hasState = stateLabel.isNotEmpty;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dải màu trạng thái bên trái — tín hiệu thị giác nhanh.
                Container(
                  width: 4,
                  color: hasState ? stateColor : AppColors.border,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 6, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title.isEmpty ? '—' : title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: AppType.bodyLg,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (hasState) ...[
                              const SizedBox(width: 8),
                              StatusChip(label: stateLabel, color: stateColor),
                            ],
                          ],
                        ),
                        if (sub.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            sub,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppType.caption,
                              height: 1.35,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                        for (final m in meta) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(m.icon, size: 13, color: AppColors.inkMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  m.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppType.caption,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bọc nội dung chi tiết: header full-bleed + phần thân có padding ngang. Dùng
/// làm body cho [ModuleDetailScaffold] để mọi màn detail có cùng bố cục.
class DetailBody extends StatelessWidget {
  final Widget header;
  final List<Widget> children;

  /// Padding đáy (chừa chỗ cho action bar nếu có).
  final double bottomPadding;

  const DetailBody({
    super.key,
    required this.header,
    required this.children,
    this.bottomPadding = 28,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        header,
        Padding(
          padding: EdgeInsets.fromLTRB(12, 16, 12, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

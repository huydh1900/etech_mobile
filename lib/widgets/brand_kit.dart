// Bộ thành phần giao diện "style mới" dùng chung (đăng nhập, trang chủ, tài
// khoản và các màn con): font Lexend, header nền sáng cùng họ màu logo bo góc
// dưới, tiêu đề mục, nhóm menu dạng thẻ, nút CTA gradient, ô nhập gạch chân.
// Màn mới theo style này chỉ cần gọi lại các widget ở đây, không tự vẽ lại.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Nền header: tông nhạt cùng họ màu logo (xanh dương #1A78A6, xanh lá
/// #0A7463) để logo/avatar đậm màu nổi lên. Nền luôn sáng (không theo dark
/// mode) → chữ trên header dùng [kBrandNavy] / [kBrandMuted] cố định.
const LinearGradient kBrandHeaderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFE4F1F9), Color(0xFFE3F4EE)],
);

/// Chữ đậm / chữ phụ trên nền header sáng.
const Color kBrandNavy = Color(0xFF0B2E52);
const Color kBrandMuted = Color(0xFF5B7083);

/// Teal cố định cho chữ/icon trên nền luôn sáng (header, pill trắng) —
/// không theo dark mode như [AppColors.teal]. CTA gradient: [AppGradients.cta].
const Color kBrandTeal = Color(0xFF0E9E8E);

/// Áp font thương hiệu [kBrandFont] cho cả cây con (chỉ đổi font, giữ màu/
/// cỡ chữ theo theme hiện tại).
class BrandTheme extends StatelessWidget {
  final Widget child;

  const BrandTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: kBrandFont),
      ),
      child: child,
    );
  }
}

/// Header nền sáng bo góc dưới, tràn lên dưới status bar (tự cộng
/// `viewPadding.top`). Đặt ở đầu một ListView/Column không bọc SafeArea top.
class BrandHeader extends StatelessWidget {
  final Widget child;

  /// Padding bên trong (phần trên đã cộng thêm status bar).
  final EdgeInsets padding;

  const BrandHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 22),
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        gradient: kBrandHeaderGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: padding.copyWith(top: padding.top + top),
      child: child,
    );
  }
}

/// Header cho tab gốc (Lịch, Thông báo…): tiêu đề lớn + dòng phụ + hành động
/// bên phải. Tự hiện nút quay lại nếu màn đang được push (route pop được).
class BrandTabHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const BrandTabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return BrandHeader(
      padding: EdgeInsets.fromLTRB(canPop ? 8 : 20, 14, 12, 20),
      child: Row(
        children: [
          if (canPop) ...[
            IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, color: kBrandNavy),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kBrandNavy,
                    fontSize: AppType.headline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kBrandMuted,
                      fontSize: AppType.body,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Khung chuẩn cho màn con (push từ tab): header sáng có nút quay lại + tiêu
/// đề (+ [headerChild] tuỳ chọn bên dưới tiêu đề), nội dung cuộn [children],
/// và [bottom] dính đáy (vd nút Xác nhận).
class BrandPage extends StatelessWidget {
  final String title;
  final Widget? headerChild;
  final List<Widget> children;
  final Widget? bottom;

  /// Lớp phủ trên toàn màn (vd loading khi đang lưu).
  final bool busy;

  const BrandPage({
    super.key,
    required this.title,
    required this.children,
    this.headerChild,
    this.bottom,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return BrandTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        BrandHeader(
                          padding: const EdgeInsets.fromLTRB(8, 4, 20, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Quay lại',
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: kBrandNavy,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: kBrandNavy,
                                        fontSize: AppType.headline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (headerChild != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    0,
                                    0,
                                  ),
                                  child: headerChild,
                                ),
                            ],
                          ),
                        ),
                        ...children,
                      ],
                    ),
                  ),
                  if (bottom != null)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: bottom,
                      ),
                    ),
                ],
              ),
              if (busy)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.15),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiêu đề một mục nội dung (vd "Phân hệ", "Cá nhân").
class BrandSectionLabel extends StatelessWidget {
  final String text;

  const BrandSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: AppType.title,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Nhóm các hàng trong 1 thẻ viền mảnh, ngăn bằng divider (lề ngang 20).
class BrandMenuGroup extends StatelessWidget {
  final List<Widget> children;

  const BrandMenuGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 66,
                  endIndent: 16,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Ô icon bo góc nền nhạt theo màu nhấn.
class BrandIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;

  const BrandIconTile({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// Một hàng trong [BrandMenuGroup]: icon + nhãn (+ dòng phụ) + phần cuối.
/// Mặc định phần cuối là mũi tên khi có [onTap]; truyền [trailing] để thay
/// (vd Switch, nút sửa). [danger] → tô đỏ, bỏ mũi tên.
class BrandMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;

  /// Dòng phụ được phép xuống tối đa 3 dòng (vd địa chỉ).
  final bool multiline;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final Color? color;

  /// true: [label] là nhãn nhỏ, [subtitle] là giá trị đậm (kiểu "trường: giá
  /// trị" của màn thông tin). false: [label] là tiêu đề hàng.
  final bool valueStyle;

  const BrandMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.multiline = false,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.color,
    this.valueStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.danger : (color ?? AppColors.teal);
    final titleStyle = TextStyle(
      color: danger ? AppColors.danger : AppColors.ink,
      fontSize: AppType.subtitle,
      fontWeight: FontWeight.w500,
    );
    final subStyle = TextStyle(
      color: AppColors.inkMuted,
      fontSize: AppType.caption,
    );
    final end =
        trailing ??
        (onTap != null && !danger
            ? Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.inkMuted,
              )
            : null);
    return Semantics(
      button: onTap != null,
      label: subtitle == null ? label : '$label: $subtitle',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                BrandIconTile(icon: icon, color: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: valueStyle ? subStyle : titleStyle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: multiline ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: valueStyle
                              ? titleStyle.copyWith(height: 1.3)
                              : subStyle,
                        ),
                      ],
                    ],
                  ),
                ),
                ?end,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút CTA gradient dạng viên thuốc. [onPressed] null → mờ, không bấm được.
class BrandPrimaryButton extends StatelessWidget {
  final String label;

  /// Nhãn hiển thị khi đang xử lý (kèm spinner).
  final String loadingLabel;
  final bool loading;
  final VoidCallback? onPressed;

  const BrandPrimaryButton({
    super.key,
    required this.label,
    this.loadingLabel = '',
    this.loading = false,
    required this.onPressed,
  });

  static const double _radius = AppRadius.pill;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabled ? 0.5 : (loading ? 0.85 : 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient: AppGradients.cta,
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: loading || disabled ? null : AppShadows.lifted,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(_radius),
            onTap: loading ? null : onPressed,
            child: Center(
              child: loading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          loadingLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppType.title,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppType.title,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ô nhập kiểu gạch chân + icon (theo mẫu), không viền hộp.
InputDecoration brandInputDecoration({
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  UnderlineInputBorder line(Color c, [double w = 1]) => UnderlineInputBorder(
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.inkMuted, fontSize: AppType.subtitle),
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Icon(prefixIcon, color: AppColors.inkMuted, size: 22),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffixIcon,
    filled: false,
    border: line(AppColors.divider),
    enabledBorder: line(AppColors.divider),
    focusedBorder: line(AppColors.teal, 1.6),
    errorBorder: line(AppColors.danger),
    focusedErrorBorder: line(AppColors.danger, 1.5),
  );
}

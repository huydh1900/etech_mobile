import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens and shared widgets for the ETECH app.
/// Keep this file as the single source of truth for colors, gradients,
/// radii, shadows and typography so the UI stays consistent.

/// Immutable colour palette. Two instances exist ([kLightPalette],
/// [kDarkPalette]); [AppColors.apply] swaps the active one at runtime.
@immutable
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.navy,
    required this.navyHeaderTop,
    required this.navyHeaderBottom,
    required this.teal,
    required this.tealSoft,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.border,
    required this.divider,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.violet,
    required this.violetSoft,
    required this.orange,
    required this.orangeSoft,
  });

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;
  final Color navy;
  final Color navyHeaderTop;
  final Color navyHeaderBottom;
  final Color teal;
  final Color tealSoft;
  final Color bg;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color border;
  final Color divider;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;
  final Color violet;
  final Color violetSoft;
  final Color orange;
  final Color orangeSoft;
}

/// Font thương hiệu (hình học, đủ dấu tiếng Việt) cho các màn đã thiết kế lại
/// theo mẫu mới: đăng nhập, quên mật khẩu, trang chủ.
const String kBrandFont = 'Lexend';

const AppPalette kLightPalette = AppPalette(
  // Deep Ocean: teal (logo) là màu hành động; tương phản chữ trắng 5.1:1 (AA).
  primary: Color(0xFF0A7C70),
  primaryDark: Color(0xFF075E55),
  primaryLight: Color(0xFF2BB3A3),
  // Xanh biển sáng — điểm cuối gradient CTA (teal → biển).
  accent: Color(0xFF1794C4),
  navy: Color(0xFF0B2E52),
  navyHeaderTop: Color(0xFF0B2E52),
  navyHeaderBottom: Color(0xFF0A2540),
  teal: Color(0xFF0E9E8E),
  tealSoft: Color(0xFFDFF5F2),
  bg: Color(0xFFF4F7FB),
  surface: Colors.white,
  ink: Color(0xFF0F172A),
  inkSoft: Color(0xFF475569),
  inkMuted: Color(0xFF5F6F84), // ≥4.5:1 trên surface/bg (WCAG AA)
  border: Color(0xFFE2E8F0),
  divider: Color(0xFFEEF2F7),
  success: Color(0xFF16A34A),
  successSoft: Color(0xFFDCFCE7),
  warning: Color(0xFFD97706),
  warningSoft: Color(0xFFFEF3C7),
  danger: Color(0xFFDC2626),
  dangerSoft: Color(0xFFFEE2E2),
  // Tách khỏi primary để chip thông tin không trông như nút bấm được.
  info: Color(0xFF2563EB),
  infoSoft: Color(0xFFDBEAFE),
  violet: Color(0xFF7C3AED),
  violetSoft: Color(0xFFEDE9FE),
  orange: Color(0xFFEA580C),
  orangeSoft: Color(0xFFFFEDD5),
);

const AppPalette kDarkPalette = AppPalette(
  primary: Color(0xFF16A394),
  primaryDark: Color(0xFF0E8F82),
  primaryLight: Color(0xFF5EEAD4),
  // Giữ đậm như bản sáng: là nền chữ trắng trong CTA, không phải màu chữ.
  accent: Color(0xFF1794C4),
  navy: Color(0xFF0B2E52),
  navyHeaderTop: Color(0xFF142B47),
  navyHeaderBottom: Color(0xFF0C1B30),
  teal: Color(0xFF2DD4BF),
  tealSoft: Color(0xFF10302F),
  bg: Color(0xFF0D1117),
  surface: Color(0xFF161A22),
  ink: Color(0xFFF1F5F9),
  inkSoft: Color(0xFFAEB9C7),
  inkMuted: Color(0xFF7C8694),
  border: Color(0xFF252C38),
  divider: Color(0xFF1C232E),
  success: Color(0xFF22C55E),
  successSoft: Color(0xFF14301F),
  warning: Color(0xFFF59E0B),
  warningSoft: Color(0xFF3A2A0E),
  danger: Color(0xFFF87171),
  dangerSoft: Color(0xFF3A1A1A),
  info: Color(0xFF60A5FA),
  infoSoft: Color(0xFF16263F),
  violet: Color(0xFFA78BFA),
  violetSoft: Color(0xFF241B3A),
  orange: Color(0xFFFB923C),
  orangeSoft: Color(0xFF3A1F0E),
);

/// Active colour tokens. Mutable so the whole app can swap palettes at
/// runtime without touching ~187 call-sites. Field names are unchanged.
class AppColors {
  AppColors._();

  // Brand — Deep Ocean: primary (teal) CHỈ dùng cho thứ bấm được
  // (CTA, link, tab active, focus); navy cho header/nền đậm.
  static Color primary = kLightPalette.primary;
  static Color primaryDark = kLightPalette.primaryDark;
  static Color primaryLight = kLightPalette.primaryLight;
  static Color accent = kLightPalette.accent;

  // Navy (login / dark headers) — Deep Ocean
  static Color navy = kLightPalette.navy;
  static Color navyHeaderTop = kLightPalette.navyHeaderTop;
  static Color navyHeaderBottom = kLightPalette.navyHeaderBottom;

  // Teal accent (lấy từ logo — nước/môi trường)
  static Color teal = kLightPalette.teal;
  static Color tealSoft = kLightPalette.tealSoft;

  // Neutrals
  static Color bg = kLightPalette.bg;
  static Color surface = kLightPalette.surface;
  static Color ink = kLightPalette.ink;
  static Color inkSoft = kLightPalette.inkSoft;
  static Color inkMuted = kLightPalette.inkMuted;
  static Color border = kLightPalette.border;
  static Color divider = kLightPalette.divider;

  // Semantic
  static Color success = kLightPalette.success;
  static Color successSoft = kLightPalette.successSoft;
  static Color warning = kLightPalette.warning;
  static Color warningSoft = kLightPalette.warningSoft;
  static Color danger = kLightPalette.danger;
  static Color dangerSoft = kLightPalette.dangerSoft;
  static Color info = kLightPalette.info;
  static Color infoSoft = kLightPalette.infoSoft;
  static Color violet = kLightPalette.violet;
  static Color violetSoft = kLightPalette.violetSoft;
  static Color orange = kLightPalette.orange;
  static Color orangeSoft = kLightPalette.orangeSoft;

  /// Swap every token to [p]. Call before building the theme/widget tree.
  static void apply(AppPalette p) {
    primary = p.primary;
    primaryDark = p.primaryDark;
    primaryLight = p.primaryLight;
    accent = p.accent;
    navy = p.navy;
    navyHeaderTop = p.navyHeaderTop;
    navyHeaderBottom = p.navyHeaderBottom;
    teal = p.teal;
    tealSoft = p.tealSoft;
    bg = p.bg;
    surface = p.surface;
    ink = p.ink;
    inkSoft = p.inkSoft;
    inkMuted = p.inkMuted;
    border = p.border;
    divider = p.divider;
    success = p.success;
    successSoft = p.successSoft;
    warning = p.warning;
    warningSoft = p.warningSoft;
    danger = p.danger;
    dangerSoft = p.dangerSoft;
    info = p.info;
    infoSoft = p.infoSoft;
    violet = p.violet;
    violetSoft = p.violetSoft;
    orange = p.orange;
    orangeSoft = p.orangeSoft;
  }
}

/// Mọi gradient đọc từ [AppColors] (getter) để tự đổi theo light/dark —
/// không hardcode mã màu ở đây.
class AppGradients {
  AppGradients._();

  /// CTA chính (teal → xanh biển): nút chính, banner, nút quét QR.
  /// Dùng primary (không dùng [AppColors.teal] — bản tối của teal là màu chữ
  /// sáng, chữ trắng trên đó chỉ ~1.9:1).
  static LinearGradient get cta => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppColors.primary, AppColors.accent],
      );

  static LinearGradient tile(Color start, Color end) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [start, end],
      );
}

/// 4 mức bo góc + pill. Không dùng số lẻ (10/14/18).
class AppRadius {
  AppRadius._();
  static const double xs = 8; // chip, tag, ô nhỏ
  static const double md = 12; // ô nhập, nút, ô icon
  static const double lg = 16; // thẻ
  static const double xl = 24; // header/hero, bottom sheet
  static const double pill = 999; // CTA, badge
}

/// Thang khoảng cách hệ 4/8 — padding, gap, margin chỉ lấy từ đây,
/// không dùng số lẻ (10/14/18).
class AppSpace {
  AppSpace._();
  static const double xxs = 4;
  static const double xs = 8; // icon ↔ chữ
  static const double sm = 12; // giữa các item trong list
  static const double md = 16; // lề màn hình, padding trong thẻ
  static const double lg = 24; // giữa các section
  static const double xl = 32;
}

/// Thang cỡ chữ chuẩn của app — nguồn sự thật duy nhất để tránh các cỡ "lẻ"
/// (11.5/12.5/13.5) rải rác do ướm mắt. Mọi màn nên tham chiếu hằng số này.
class AppType {
  AppType._();
  static const double micro = 11; // badge, nhãn phụ rất nhỏ
  static const double caption = 12; // nhãn phụ, metadata
  static const double body = 13; // nội dung phụ
  static const double bodyLg = 14; // nội dung chính
  static const double subtitle = 16; // tiêu đề mục / tên dòng
  static const double title = 18; // tiêu đề card, AppBar
  static const double headline = 22; // tiêu đề header màn
  static const double display = 28; // tiêu đề màn đăng nhập

  /// Min touch target theo Material (đảm bảo vùng chạm ≥ 44dp).
  static const double minTapTarget = 44;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Bóng màu thương hiệu cho phần tử nổi (CTA, thẻ nổi bật) — theo primary.
  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Builds the active theme from the current [AppColors] tokens.
/// Call [AppColors.apply] with the matching palette BEFORE this.
/// Nền AppBar ở theme sáng — tông giữa của [kBrandHeaderGradient] (header
/// trang chủ) để AppBar các màn module đồng nhất với trang chủ.
const Color kAppBarTint = Color(0xFFE4F2F4);

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkRipple.splashFactory,
    // AppBar mọi màn đồng nhất với header trang chủ: nền sáng cùng họ màu
    // logo (sáng) / surface (tối), bo góc dưới, tiêu đề trái chữ navy.
    appBarTheme: AppBarTheme(
      backgroundColor: brightness == Brightness.light
          ? kAppBarTint
          : AppColors.surface,
      foregroundColor:
          brightness == Brightness.light ? AppColors.navy : AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 60,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
      titleTextStyle: TextStyle(
        fontFamily: kBrandFont,
        color: brightness == Brightness.light ? AppColors.navy : AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: AppType.title,
      ),
    ),
    // Inter cho nội dung, Lexend ([kBrandFont]) cho tiêu đề.
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontFamily: kBrandFont,
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: AppType.display,
        letterSpacing: -0.4,
      ),
      headlineMedium: TextStyle(
        fontFamily: kBrandFont,
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: AppType.headline,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        fontFamily: kBrandFont,
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: AppType.title,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: AppType.subtitle,
      ),
      bodyLarge: TextStyle(color: AppColors.ink, fontSize: AppType.bodyLg),
      bodyMedium: TextStyle(color: AppColors.inkSoft, fontSize: AppType.body),
      bodySmall: TextStyle(color: AppColors.inkMuted, fontSize: AppType.caption),
      labelLarge: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        fontSize: AppType.caption,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(color: AppColors.inkMuted, fontSize: AppType.bodyLg),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.divider,
      space: 1,
      thickness: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 2,
    ),
  );
}

/// Tạo [InputDecoration] thống nhất cho toàn app — cùng bán kính ([AppRadius.md]),
/// cùng trạng thái focus (viền primary) và phân biệt rõ trạng thái chỉ-đọc
/// (nền xám, không cho cảm giác gõ được). Dùng thay cho các bản tự chế rải rác.
InputDecoration appInputDecoration({
  String? label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
  bool readOnly = false,
  Color? focusColor,
}) {
  final focus = focusColor ?? AppColors.primary;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    filled: true,
    // Trạng thái chỉ-đọc: nền nhạt hơn để user thấy ngay "không sửa được".
    fillColor: readOnly ? AppColors.bg : AppColors.surface,
    hintStyle: TextStyle(color: AppColors.inkMuted, fontSize: AppType.bodyLg),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: AppColors.inkMuted, size: 20),
    suffixIcon: suffixIcon,
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(focus, 1.6),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.5),
  );
}

/// A reusable gradient CTA button used across the app.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  /// null → [AppGradients.cta].
  final Gradient? gradient;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: gradient ?? AppGradients.cta,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: disabled ? null : AppShadows.lifted,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppType.subtitle,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft coloured pill used for status labels.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: AppType.micro,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

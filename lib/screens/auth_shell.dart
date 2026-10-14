import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_kit.dart';

export '../widgets/brand_kit.dart';

/// Khung dùng chung cho các màn xác thực (đăng nhập, quên mật khẩu): banner
/// nền sáng bo góc dưới có logo công ty ở giữa + nội dung trắng bên dưới,
/// font Lexend (hình học, đủ dấu tiếng Việt) theo mẫu thiết kế.

class AuthHeroScaffold extends StatelessWidget {
  /// Nội dung bên dưới banner.
  final List<Widget> children;

  /// Phần dính đáy màn (trên dòng bản quyền), vd link "Quên mật khẩu".
  final Widget? footer;

  /// Bọc phần nội dung để chạy animation intro (tùy màn).
  final Widget Function(BuildContext context, Widget body)? animate;

  const AuthHeroScaffold({
    super.key,
    required this.children,
    this.footer,
    this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final body = Padding(
      padding: EdgeInsets.fromLTRB(28, 30, 28, 20 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          const SizedBox(height: 24),
          const Spacer(),
          ?footer,
          Center(
            child: Text(
              '© ${DateTime.now().year} ${AppConfig.appName} · v${AppConfig.appVersion}',
              style: TextStyle(
                fontSize: AppType.micro,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
    return BrandTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // Banner nền sáng tràn lên dưới status bar → icon status bar màu tối.
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  // IntrinsicHeight + Spacer: footer dính đáy khi nội dung ngắn,
                  // màn thấp/bàn phím mở thì vẫn scroll được.
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(context),
                        Expanded(
                          child: animate == null
                              ? body
                              : animate!(context, body),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    // Hero cùng tag ở mọi màn xác thực → khi chuyển màn banner đứng yên,
    // chỉ phần nội dung bên dưới cross-fade (xem [authRoute]).
    return Hero(
      tag: 'auth-hero',
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
        child: Container(
          height: 270 + top,
          decoration: const BoxDecoration(gradient: kBrandHeaderGradient),
          padding: EdgeInsets.only(top: top),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/logo.png',
            height: 190,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) =>
                Icon(Icons.water_drop, size: 64, color: AppColors.teal),
          ),
        ),
      ),
    );
  }
}

/// Route chuyển giữa các màn xác thực: chỉ fade (không zoom/trượt như route
/// mặc định) vì banner dùng chung đã được [Hero] giữ cố định.
Route<T> authRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}

/// Tiêu đề lớn của màn xác thực.
class AuthTitle extends StatelessWidget {
  final String text;

  const AuthTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.ink,
        fontSize: AppType.display,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
      ),
    );
  }
}

/// Banner lỗi đỏ dùng chung cho màn xác thực.
class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.danger,
                fontSize: AppType.body,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

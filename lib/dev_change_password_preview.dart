import 'package:flutter/material.dart';

import 'screens/change_password_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

/// Harness độc lập để xem màn Đổi mật khẩu mà không cần login/backend.
/// Chạy: flutter run -t lib/dev_change_password_preview.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  runApp(const _ChangePasswordPreviewApp());
}

class _ChangePasswordPreviewApp extends StatelessWidget {
  const _ChangePasswordPreviewApp();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        AppColors.apply(themeController.isDark ? kDarkPalette : kLightPalette);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(themeController.brightness),
          home: const ChangePasswordScreen(),
        );
      },
    );
  }
}

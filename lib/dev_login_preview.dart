import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

/// Harness độc lập để render/chụp màn Đăng nhập mà không cần backend.
/// Chạy: flutter run -t lib/dev_login_preview.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  runApp(const _LoginPreviewApp());
}

class _LoginPreviewApp extends StatelessWidget {
  const _LoginPreviewApp();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        AppColors.apply(themeController.isDark ? kDarkPalette : kLightPalette);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(themeController.brightness),
          home: const LoginScreen(),
        );
      },
    );
  }
}

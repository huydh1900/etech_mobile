import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/phone_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final isDark = themeController.isDark;
        AppColors.apply(isDark ? kDarkPalette : kLightPalette);
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
        );
        return MaterialApp(
          title: 'ETECH',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(themeController.brightness),
          // App tiếng Việt → bật localization để các picker/dialog hệ thống
          // (date/time picker, text selection…) hiển thị tiếng Việt.
          locale: const Locale('vi'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('vi'),
            Locale('en'),
          ],
          // Dev trên web/desktop: bọc toàn app trong khung điện thoại giả
          // (tự tắt trên mobile thật). Dùng `builder` để dialog/route cũng
          // nằm trong khung.
          builder: (context, child) => PhoneFrame(child: child!),
          home: const SplashScreen(),
        );
      },
    );
  }
}

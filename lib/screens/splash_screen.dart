import 'package:flutter/material.dart';
import '../config.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';
import '../services/session_store.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Màn khởi động: kiểm tra phiên đã lưu (Duy trì đăng nhập).
/// Phiên còn hạn → vào thẳng Home; hết hạn/không có → về Login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    Widget next = const LoginScreen();

    final saved = await SessionStore().load();
    if (saved != null) {
      // Validate phiên bằng 1 lệnh nhẹ; lỗi => phiên hết hạn.
      try {
        final empService = EmployeeService(
          baseUrl: AppConfig.odooUrl,
          sessionId: saved.sessionId,
        );
        final Employee employee = await empService.getMe();
        next = HomeScreen(
          uid: saved.uid,
          employee: employee,
          sessionId: saved.sessionId,
        );
      } catch (_) {
        await SessionStore().clear();
      }
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyHeaderTop,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

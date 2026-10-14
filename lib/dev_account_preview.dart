import 'package:flutter/material.dart';

import 'models/employee.dart';
import 'screens/account_tab.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

/// Harness độc lập để render/chụp tab Tài khoản mà không cần login/backend.
/// Chạy: flutter run -t lib/dev_account_preview.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  runApp(const _AccountPreviewApp());
}

final _mockEmployee = Employee(
  id: 1024,
  name: 'Nguyễn Văn An',
  email: 'an.nguyen@etech.com',
  department: 'Phòng Kiểm nghiệm',
  departmentManager: 'Trần Thị Bình',
  manager: 'Lê Văn Cường',
  company: 'ETECH',
  dateStart: '01/03/2021',
  birthday: '15/08/1995',
  phone: '0988 411 115',
  address: '172 Ngô Quyền, Bắc Ninh',
  jobPosition: 'Kỹ thuật viên',
  employeeCode: '1024',
);

class _AccountPreviewApp extends StatelessWidget {
  const _AccountPreviewApp();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        AppColors.apply(
            themeController.isDark ? kDarkPalette : kLightPalette);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(themeController.brightness),
          home: Scaffold(
            backgroundColor: AppColors.bg,
            body: SafeArea(
              child: AccountTab(
                employee: _mockEmployee,
                sessionId: '',
                onUpdated: (_) {},
              ),
            ),
          ),
        );
      },
    );
  }
}

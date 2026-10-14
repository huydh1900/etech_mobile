// Smoke test cho LoginScreen sau khi đồng bộ input decoration + footer động +
// touch target. (Test counter mặc định cũ đã bị thay vì main.dart không phải
// app counter.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etech_lab/config.dart';
import 'package:etech_lab/screens/login_screen.dart';
import 'package:etech_lab/theme/app_theme.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: const LoginScreen(),
    ));
    await tester.pump(const Duration(milliseconds: 700)); // xong intro anim
  }

  testWidgets('Login render các field + nút chính', (tester) async {
    await pumpLogin(tester);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Quên mật khẩu'), findsOneWidget);
  });

  testWidgets('Footer hiển thị version động từ AppConfig', (tester) async {
    await pumpLogin(tester);
    expect(find.textContaining(AppConfig.appName), findsOneWidget);
    expect(find.textContaining('v${AppConfig.appVersion}'), findsOneWidget);
    // Năm động, không hard-code 2026 nữa.
    expect(find.textContaining('${DateTime.now().year}'), findsOneWidget);
  });

  testWidgets('Vùng chạm "Quên mật khẩu" ≥ 44dp', (tester) async {
    await pumpLogin(tester);
    final box = tester.getSize(
      find.ancestor(
        of: find.text('Quên mật khẩu'),
        matching: find.byType(InkWell),
      ).first,
    );
    expect(box.height, greaterThanOrEqualTo(44));
  });
}

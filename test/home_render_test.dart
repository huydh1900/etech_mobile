import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:etech_lab/models/employee.dart';
import 'package:etech_lab/screens/home_screen.dart';
import 'package:etech_lab/screens/notifications_screen.dart';
import 'package:etech_lab/theme/app_theme.dart';

void main() {
  Employee buildEmp() => Employee(
    id: 2,
    name: 'Nguyen Van Admin',
    email: 'admin@etech.vn',
    department: 'Ban',
    departmentManager: 'Tran B',
    manager: 'Le C',
    company: 'ETECH',
    dateStart: '01/01/2020',
    birthday: '01/01/1990',
    phone: '0900',
    address: 'HN',
    jobPosition: 'Admin',
    employeeCode: 'AD001',
  );

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: HomeScreen(uid: 2, employee: buildEmp(), sessionId: ''),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets('Trang chủ chỉ hiện module Hiện trường + Lịch công tác', (
    tester,
  ) async {
    await pumpHome(tester);
    // 'Hiện trường' còn xuất hiện làm nhãn nhóm ở "Truy cập nhanh".
    expect(find.text('Hiện trường'), findsWidgets);
    // Vừa là tiêu đề thẻ nhóm vừa là tên menu con trùng tên.
    expect(find.text('Lịch công tác'), findsWidgets);
    // Module ngoài kHomeModuleKeys không lên lưới trang chủ.
    expect(find.text('Hồ sơ'), findsNothing);
  });

  testWidgets('Đã gỡ nút search chết khỏi TopBar', (tester) async {
    await pumpHome(tester);
    // Trước đây có nút search onTap rỗng (dead button) — phải biến mất.
    expect(find.byIcon(Icons.search_rounded), findsNothing);
  });

  testWidgets('Bottom nav điều hướng sang tab Thông báo', (tester) async {
    await pumpHome(tester);

    // IndexedStack giữ MỌI tab trong cây cùng lúc → "điều hướng" = đổi index
    // được hiển thị, KHÔNG phải sự xuất hiện của widget. Vì vậy kiểm tra qua
    // IndexedStack.index thay vì text trong tab Thông báo (offline tab này nạp
    // mock data → không có empty-state "Chưa có thông báo"; nó cũng có thể đang
    // ở skeleton loading trong thời gian test, nên text nội dung không đáng tin).
    IndexedStack stackOf() =>
        tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stackOf().index, 0);

    // Header trang chủ đã gỡ → điểm vào Thông báo duy nhất là bottom nav.
    await tester.tap(find.text('Thông báo'));
    await tester.pump(const Duration(milliseconds: 300));

    // Đã chuyển sang tab Thông báo (index 2) và màn Trung tâm thông báo có mặt.
    expect(stackOf().index, 2);
    expect(find.byType(NotificationsScreen), findsOneWidget);
  });

  testWidgets('Pull-to-refresh là thật (RefreshIndicator có mặt)', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('Lưới chức năng: menu lá hiện trực tiếp, menu cấp 3 mở sheet',
      (tester) async {
    await pumpHome(tester);
    // Menu con của module hiện thẳng trên thẻ nhóm (không cần mở sheet).
    expect(find.text('Biên bản hiện trường'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    // 'Kế hoạch lấy mẫu' còn menu cấp 3 → bấm mở sheet chứa 'Của tôi'.
    await tester.tap(find.text('Kế hoạch lấy mẫu'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Của tôi'),
      ),
      findsOneWidget,
    );
  });
}

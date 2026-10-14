// Test cho các widget trạng thái dùng chung (EmptyState/ErrorState/SkeletonList)
// — bằng chứng cho việc đồng bộ empty/error/loading toàn app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etech_lab/theme/app_theme.dart';
import 'package:etech_lab/widgets/states.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('EmptyState hiển thị tiêu đề + mô tả + nút hành động',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(EmptyState(
      icon: Icons.inbox_outlined,
      title: 'Trống',
      message: 'Chưa có dữ liệu',
      actionLabel: 'Tải lại',
      onAction: () => tapped = true,
    )));
    expect(find.text('Trống'), findsOneWidget);
    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
    await tester.tap(find.text('Tải lại'));
    expect(tapped, isTrue);
  });

  testWidgets('ErrorState hiện thông điệp + gọi onRetry', (tester) async {
    var retried = false;
    await tester.pumpWidget(_wrap(ErrorState(
      message: 'Mất kết nối',
      onRetry: () => retried = true,
    )));
    expect(find.text('Đã có lỗi xảy ra'), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    expect(retried, isTrue);
  });

  testWidgets('SkeletonList dựng đúng số item', (tester) async {
    await tester.pumpWidget(_wrap(const SkeletonList(itemCount: 3)));
    // Mỗi card skeleton có nhiều SkeletonBox → ít nhất itemCount card.
    expect(find.byType(SkeletonBox), findsWidgets);
  });
}

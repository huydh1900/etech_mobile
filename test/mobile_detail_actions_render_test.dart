// Render-evidence cho các màn CHI TIẾT mới: pump detail của từng module ở một
// state mà có ÍT NHẤT 1 nút action state-machine hiển thị, rồi xuất PNG vào
// test/screenshots/<module>_detail.png.
//
// Chạy:  flutter test --update-goldens test/mobile_detail_actions_render_test.dart
//
// Dữ liệu: offline → service trả mock fallback. Quyền: permissions mặc định
// allowAll (chưa load) nên canWrite()=true → nút action hiện. Chọn id ở state
// 'draft' (hoặc state có action) theo mock của từng service:
//   handovers            id=3 draft  → "Bàn giao mẫu"
//   lab_batches          id=4 draft  → "Bắt đầu cân mẫu" / "Hủy mẻ"
//   destructions         id=2 draft  → "Xác nhận hủy" / "Hủy bỏ"
//   test_reports         id=2 draft  → "Duyệt" / "Hủy phiếu"
//   preprocess_requests  id=4 draft  → "Gửi yêu cầu" / "Hủy"
//   analysis_requests    id=1 draft  → "Gửi yêu cầu" / "Hủy phiếu"
//
// Font-loading mirror nguyên test/mobile_screens_render_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etech_lab/screens/handovers_screens.dart';
import 'package:etech_lab/screens/lab_batches_screens.dart';
import 'package:etech_lab/screens/destructions_screens.dart';
import 'package:etech_lab/screens/test_reports_screens.dart';
import 'package:etech_lab/screens/preprocess_requests_screens.dart';
import 'package:etech_lab/screens/analysis_requests_screens.dart';
import 'package:etech_lab/theme/app_theme.dart';

const _fontDir =
    '/home/huytq/snap/flutter/common/flutter/bin/cache/artifacts/material_fonts';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('$_fontDir/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadInter() async {
  const dir = '/home/huytq/flutter/etech_lab/assets/fonts';
  final loader = FontLoader('Inter');
  for (final f in [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
    'Inter-Italic.ttf',
  ]) {
    final bytes = File('$dir/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
  // Lexend (kBrandFont) — font tiêu đề/thẻ theo style trang chủ.
  final lexend = FontLoader('Lexend');
  for (final f in [
    'Lexend-Regular.ttf',
    'Lexend-Medium.ttf',
    'Lexend-SemiBold.ttf',
    'Lexend-Bold.ttf',
  ]) {
    final bytes = File('$dir/$f').readAsBytesSync();
    lexend.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await lexend.load();
}

// Xem chú thích trong mobile_screens_render_test.dart: bơm lại fontFamily Inter
// cho AppBar title để vá bug header "ô đen" trong môi trường flutter_test.
ThemeData harnessTheme(Brightness brightness) {
  final base = buildAppTheme(brightness);
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle:
          base.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Inter'),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    AppColors.apply(kLightPalette);
    await _loadFont('Roboto', [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Black.ttf',
    ]);
    await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
    await _loadInter();
  });

  // Pump 1 màn chi tiết; network thật fail nhanh offline → mock fallback; assert
  // ÍT NHẤT 1 nút action xuất hiện; rồi ghi golden PNG.
  Future<void> renderDetail(
    WidgetTester tester,
    String name,
    Widget screen,
    List<String> expectedActions, {
    AppPalette palette = kLightPalette,
    Brightness brightness = Brightness.light,
  }) async {
    AppColors.apply(palette);
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: harnessTheme(brightness),
      home: screen,
    ));

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Bằng chứng action button: ít nhất 1 label kỳ vọng phải có trên cây widget.
    final foundAny = expectedActions.any((label) =>
        find.widgetWithText(ElevatedButton, label).evaluate().isNotEmpty ||
        find.text(label).evaluate().isNotEmpty);
    expect(foundAny, isTrue,
        reason: 'Không thấy nút action nào trong $expectedActions ở màn $name');

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/${name}_detail.png'),
    );
  }

  const sid = 'mock-session';

  testWidgets('handovers_detail', (tester) async {
    await renderDetail(
      tester,
      'handovers',
      const HandoverDetailPage(sessionId: sid, handoverId: 3),
      ['Bàn giao mẫu'],
    );
  });

  testWidgets('lab_batches_detail', (tester) async {
    await renderDetail(
      tester,
      'lab_batches',
      const LabBatchesDetailScreen(sessionId: sid, batchId: 4),
      ['Bắt đầu cân mẫu', 'Hủy mẻ'],
    );
  });

  testWidgets('destructions_detail', (tester) async {
    await renderDetail(
      tester,
      'destructions',
      const DestructionDetailPage(sessionId: sid, destructionId: 2),
      ['Xác nhận hủy', 'Hủy bỏ'],
    );
  });

  testWidgets('test_reports_detail', (tester) async {
    await renderDetail(
      tester,
      'test_reports',
      const TestReportDetailPage(sessionId: sid, reportId: 2),
      ['Duyệt', 'Hủy phiếu'],
    );
  });

  testWidgets('preprocess_requests_detail', (tester) async {
    await renderDetail(
      tester,
      'preprocess_requests',
      const PreprocessRequestDetailPage(sessionId: sid, requestId: 4),
      ['Gửi yêu cầu', 'Hủy'],
    );
  });

  testWidgets('analysis_requests_detail', (tester) async {
    await renderDetail(
      tester,
      'analysis_requests',
      const ArDetailPage(sessionId: sid, requestId: 1),
      ['Gửi yêu cầu', 'Hủy phiếu'],
    );
  });

  // ── DARK MODE detail variant → screenshots/handovers_detail_dark.png ───────
  testWidgets('handovers_detail dark', (tester) async {
    AppColors.apply(kDarkPalette);
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: harnessTheme(Brightness.dark),
      home: const HandoverDetailPage(sessionId: sid, handoverId: 3),
    ));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('screenshots/handovers_detail_dark.png'));
  });
}

// Render-evidence cho formview redesign: dựng 1 màn chi tiết mẫu bằng đúng bộ
// widget dùng chung (detail_kit) với dữ liệu literal — không cần backend — rồi
// xuất PNG vào test/screenshots/formview_*.png để soi mắt thường.
//
// Chạy:  flutter test --update-goldens test/formview_render_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etech_lab/theme/app_theme.dart';
import 'package:etech_lab/widgets/detail_kit.dart';

Future<void> _loadFont(String family, List<String> files) async {
  const dir =
      '/home/huytq/snap/flutter/common/flutter/bin/cache/artifacts/material_fonts';
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('$dir/$f').readAsBytesSync();
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
}

Widget _sampleFormview() {
  return DetailBody(
    header: DetailHeader.fromState(
      code: 'YCPT-2026-0042',
      subtitle: 'Công ty TNHH Môi trường Xanh',
      state: 'received',
      stateLabel: 'Đã tiếp nhận mẫu',
    ),
    children: [
      InfoSection(
        title: 'Thông tin chung',
        number: 1,
        icon: Icons.info_outline_rounded,
        children: [
          const InfoRow('Mã phiếu dịch vụ', 'DV-2026-0042', mono: true),
          const InfoRow('Khách hàng', 'Công ty TNHH Môi trường Xanh'),
          const InfoRow('Điều kiện bảo quản mẫu', 'Bảo quản đông < -18°C',
              radio: true),
          const InfoRow('Loại mẫu', 'Nước thải sinh hoạt', pill: true),
          InfoRow('Hồ sơ liên kết', 'YCSC-2026-0011', onTap: () {}),
        ],
      ),
      InfoSection(
        title: 'Bảo quản & thời hạn',
        number: 2,
        icon: Icons.schedule_rounded,
        children: const [
          InfoRow('Thời gian lưu', '30 ngày'),
          InfoRow('Tiếp nhận lúc', '18/06/2026 09:15'),
          InfoRow('Hạn trả kết quả', '25/06/2026', valueColor: Color(0xFFD97706)),
          InfoChips('Người phụ trách',
              ['Nguyễn Văn An', 'Trần Thị Bình', 'Lê Quốc C']),
        ],
      ),
      const LineTable(
        title: 'Chỉ tiêu phân tích',
        number: 3,
        icon: Icons.biotech_outlined,
        columns: [
          LineCol('Chỉ tiêu', width: 120),
          LineCol('Mã mẫu', width: 90),
          LineCol('KL (g)', width: 70, numeric: true),
          LineCol('Số mẫu', width: 64, numeric: true),
        ],
        rows: [
          ['pH', 'CS-001', '50', '2'],
          ['Hàm lượng COD', 'CS-002', '120', '3'],
          ['Tổng chất rắn lơ lửng', 'CS-003', '80', '2'],
        ],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
    await _loadInter();
  });

  Future<void> render(WidgetTester tester, String name, AppPalette palette,
      Brightness brightness) async {
    AppColors.apply(palette);
    tester.view.physicalSize = const Size(390 * 3, 1100 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final base = buildAppTheme(brightness);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        appBarTheme: base.appBarTheme
            .copyWith(titleTextStyle: base.appBarTheme.titleTextStyle
                ?.copyWith(fontFamily: 'Inter')),
      ),
      home: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Yêu cầu phân tích')),
        body: _sampleFormview(),
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/$name.png'),
    );
  }

  testWidgets('formview light', (tester) async {
    await render(tester, 'formview_light', kLightPalette, Brightness.light);
  });

  testWidgets('formview dark', (tester) async {
    await render(tester, 'formview_dark', kDarkPalette, Brightness.dark);
  });
}

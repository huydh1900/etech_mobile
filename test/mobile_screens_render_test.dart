// Render-evidence cho các màn hình mới: pump từng màn (MaterialApp + palette
// light) với dữ liệu mock-fallback do service cung cấp (không cần backend), rồi
// xuất PNG vào test/screenshots/<screen>.png.
//
// Chạy:  flutter test --update-goldens test/mobile_screens_render_test.dart
//
// Font thật nạp từ Flutter cache cục bộ (giống test/login_visual_test.dart).
// Các list-screen gọi service thật tới AppConfig.odooUrl; offline → connection
// refused nhanh → service trả mock fallback (trừ CustomerService: KHÔNG có mock
// fallback nên hiện trạng thái lỗi/empty — vẫn là bằng chứng render hợp lệ).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etech_lab/models/employee.dart';
import 'package:etech_lab/screens/notifications_screen.dart';
import 'package:etech_lab/screens/customers_screens.dart';
import 'package:etech_lab/screens/handovers_screens.dart';
import 'package:etech_lab/screens/home_screen.dart';
import 'package:etech_lab/screens/account_tab.dart';
import 'package:etech_lab/screens/login_screen.dart';
import 'package:etech_lab/screens/lab_batches_screens.dart';
import 'package:etech_lab/screens/preprocess_requests_screens.dart';
import 'package:etech_lab/screens/destructions_screens.dart';
import 'package:etech_lab/screens/analysis_requests_screens.dart';
import 'package:etech_lab/screens/test_reports_screens.dart';
import 'package:etech_lab/theme/app_theme.dart';
import 'package:etech_lab/widgets/record_card.dart';
import 'package:etech_lab/widgets/module_list_scaffold.dart';
import 'package:etech_lab/models/paged.dart';
import 'package:etech_lab/models/search_spec.dart';
import 'package:etech_lab/services/search_spec_service.dart';

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

// Font thật của app — Inter (có glyph tiếng Việt), nạp từ assets dự án để
// golden hiển thị đúng tiếng Việt thay vì ô vuông (Roboto cache thiếu glyph VN).
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

// Theme cho golden test. FIX bug header "ô đen": appBarTheme.titleTextStyle của
// app KHÔNG khai báo fontFamily (runtime kế thừa ThemeData.fontFamily='Inter',
// nhưng trong môi trường flutter_test style này resolve về font mặc định thiếu
// glyph → render ô đen). Bơm lại fontFamily='Inter' cho title để mirror đúng
// hành vi thật. KHÔNG đổi styling của app — chỉ vá ở harness.
ThemeData harnessTheme(Brightness brightness) {
  final base = buildAppTheme(brightness);
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle:
          base.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Inter'),
    ),
  );
}

Employee _mockEmployee() => Employee(
      id: 7,
      name: 'Nguyễn Văn An',
      email: 'an.nguyen@etech.vn',
      department: 'Phòng Phân tích',
      departmentManager: 'Trần Thị Bình',
      manager: 'Trần Thị Bình',
      company: 'ETECH LIMS',
      dateStart: '2022-03-01',
      birthday: '1995-08-12',
      phone: '0901 234 567',
      address: '12 Nguyễn Trãi, Q.1, TP.HCM',
      jobPosition: 'Kỹ thuật viên phòng thí nghiệm',
      employeeCode: 'NV-007',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    AppColors.apply(kLightPalette);
    // Spec Bộ lọc/Nhóm theo khi offline — khớp search view Odoo thật của
    // etech.sampling.handover (GET /api/search_spec).
    SearchSpecService.debugSpecs['etech.sampling.handover'] = const SearchSpec(
      filters: [
        [SpecItem('my_handovers', 'Của tôi')],
        [
          SpecItem('sla_overdue', 'Quá hạn tiếp nhận'),
          SpecItem('sla_warning', 'Sắp đến hạn'),
        ],
      ],
      dates: [SpecItem('filter_receive_datetime', 'Thời gian tiếp nhận mẫu')],
      fields: [
        SearchField('code', 'Mã phiếu / Số biên bản / Mã tem'),
        SearchField('line_ids', 'Mã hóa mẫu', 'one2many'),
        SearchField('partner_id', 'Khách hàng', 'many2one'),
        SearchField('print_count', 'Số lần in', 'integer'),
      ],
      groups: [
        SpecItem('g_receive_date', 'Ngày tiếp nhận'),
        SpecItem('g_completion_date', 'Ngày hoàn thành'),
        SpecItem('g_state', 'Trạng thái'),
        SpecItem('g_sla_state', 'Tình trạng hạn'),
      ],
    );
    await _loadFont('Roboto', [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Black.ttf',
    ]);
    await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
    await _loadInter();
  });

  // Pump 1 màn hình, để network thật fail nhanh + service trả mock fallback,
  // rồi so khớp golden (ghi PNG khi chạy với --update-goldens).
  Future<void> renderScreen(
    WidgetTester tester,
    String name,
    Widget screen, {
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

    // Cho phép HTTP thật (connection refused offline) + fallback mock hoàn tất.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/$name.png'),
    );
  }

  const sid = 'mock-session';

  testWidgets('notifications_screen', (tester) async {
    await renderScreen(
        tester, 'notifications', const NotificationsScreen(sessionId: sid));
  });

  testWidgets('customers_screen', (tester) async {
    await renderScreen(
        tester, 'customers', const CustomersListScreen(sessionId: sid));
  });

  testWidgets('handovers_screen', (tester) async {
    await renderScreen(
        tester, 'handovers', const HandoverListScreen(sessionId: sid));
  });

  testWidgets('handovers_filter_sheet', (tester) async {
    await renderScreen(
        tester, 'handovers', const HandoverListScreen(sessionId: sid));
    Future<void> settle() async {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await settle();
    await tester.tap(find.text('Sắp đến hạn'));
    await tester.tap(find.text('Quá hạn tiếp nhận'));
    await tester.tap(find.text('Tình trạng hạn'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('screenshots/handovers_filter_sheet.png'));

    // Bỏ lọc hạn, chỉ nhóm theo → thấy đủ header nhóm.
    await tester.tap(find.text('Sắp đến hạn'));
    await tester.tap(find.text('Quá hạn tiếp nhận'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng (1)'));
    await settle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('screenshots/handovers_filtered.png'));

    // Mở 1 nhóm → tải bản ghi của nhóm đó.
    await tester.tap(find.text('Quá hạn'));
    await settle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('screenshots/handovers_group_open.png'));
  });

  testWidgets('handovers_search_facets', (tester) async {
    await renderScreen(
        tester, 'handovers', const HandoverListScreen(sessionId: sid));
    Future<void> settle() async {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    await tester.enterText(find.byType(TextField), 'xanh');
    await tester.pumpAndSettle();
    // Trường số không gợi ý khi gõ chữ.
    expect(find.textContaining('Số lần in'), findsNothing);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('screenshots/handovers_search_suggest.png'));

    await tester.tap(find.textContaining('Tìm Khách hàng', findRichText: true));
    await settle();
    await tester.enterText(find.byType(TextField), 'BG-2026-0002');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle();
    // Enter → trường đầu (Mã phiếu); khác trường với Khách hàng → AND → 0.
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('screenshots/handovers_search_facets.png'));
  });

  testWidgets('paged_list_pager', (tester) async {
    // 200 bản ghi giả → 3 trang × 80; render trang 2 để thấy thanh pager.
    Future<PagedResult<int>> fetch({
      String? state,
      String? query,
      required int offset,
      required int limit,
      Map<String, String>? params,
    }) async {
      final ids = List.generate(200, (i) => i + 1).skip(offset).take(limit);
      return PagedResult<int>(
        items: ids.toList(),
        total: 200,
        allCount: 200,
        counts: const {},
        offset: offset,
        limit: limit,
      );
    }
    await renderScreen(
      tester,
      'paged_list_page1',
      ModuleListScaffold<int>(
        title: 'Phiếu bàn giao mẫu',
        unitLabel: 'phiếu',
        fetch: fetch,
        itemBuilder: (context, i) => RecordCard(
          title: 'BG-2026-${i.toString().padLeft(4, '0')}',
          state: const ['draft', 'handed', 'received'][i % 3],
          stateLabel: const ['Dự thảo', 'Đã bàn giao', 'Đã tiếp nhận'][i % 3],
          subtitle: 'Khách hàng số $i',
          tag: 'Nước thải',
          note: 'Mẫu số $i',
          onTap: () {},
        ),
      ),
    );
    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('screenshots/paged_list_pager.png'));
    await tester.tap(find.text('2 / 3'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('screenshots/paged_list_page_picker.png'));
  });

  testWidgets('lab_batches_screen', (tester) async {
    await renderScreen(
        tester, 'lab_batches', const LabBatchesListScreen(sessionId: sid));
  });

  testWidgets('preprocess_requests_screen', (tester) async {
    await renderScreen(tester, 'preprocess_requests',
        const PreprocessRequestsListScreen(sessionId: sid));
  });

  testWidgets('destructions_screen', (tester) async {
    await renderScreen(
        tester, 'destructions', const DestructionListScreen(sessionId: sid));
  });

  testWidgets('analysis_requests_screen', (tester) async {
    await renderScreen(
        tester, 'analysis_requests', const ArListScreen(sessionId: sid));
  });

  testWidgets('test_reports_screen', (tester) async {
    await renderScreen(
        tester, 'test_reports', const TestReportsListScreen(sessionId: sid));
  });

  testWidgets('login_screen', (tester) async {
    await renderScreen(tester, 'login', const LoginScreen());
  });

  testWidgets('home_screen', (tester) async {
    await renderScreen(
      tester,
      'home',
      HomeScreen(uid: 7, sessionId: sid, employee: _mockEmployee()),
    );
  });

  testWidgets('account_screen', (tester) async {
    // AccountTab thật sống trong Scaffold body của HomeScreen → bọc Scaffold để
    // có DefaultTextStyle/Material ancestor đúng (nếu pump trần, Text style
    // không fontFamily sẽ rơi về font mặc định thiếu glyph → ô đen).
    await renderScreen(
      tester,
      'account',
      Scaffold(
        backgroundColor: AppColors.bg,
        body: AccountTab(
          employee: _mockEmployee(),
          sessionId: sid,
          onUpdated: (_) {},
        ),
      ),
    );
  });

  testWidgets('customers_detail', (tester) async {
    await renderScreen(tester, 'customers_detail',
        const CustomerDetailPage(sessionId: sid, partnerId: 1));
  });

  // ── DARK MODE variants ────────────────────────────────────────────────────
  testWidgets('home_screen dark', (tester) async {
    await renderScreen(
      tester,
      'home_dark',
      HomeScreen(uid: 7, sessionId: sid, employee: _mockEmployee()),
      palette: kDarkPalette,
      brightness: Brightness.dark,
    );
  });

  testWidgets('handovers_screen dark', (tester) async {
    await renderScreen(
      tester,
      'handovers_dark',
      const HandoverListScreen(sessionId: sid),
      palette: kDarkPalette,
      brightness: Brightness.dark,
    );
  });
}

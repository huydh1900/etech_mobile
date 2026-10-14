// Golden harness: render từng formview ở 375px với FIXTURE THẬT (lấy từ Odoo
// đang chạy) qua MockClient, xuất PNG để so khớp pixel với ref/ (ảnh Odoo mobile).
//   flutter test --update-goldens test/form_golden_test.dart   # tạo/cập nhật golden
//   flutter test test/form_golden_test.dart                    # so khớp
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:etech_lab/theme/app_theme.dart';
import 'package:etech_lab/screens/sampling_detail_screen.dart';
import 'package:etech_lab/screens/lab_batches_screens.dart';
import 'package:etech_lab/screens/customers_screens.dart';
import 'package:etech_lab/screens/sample_retention_screens.dart';
import 'package:etech_lab/screens/service_request_screens.dart';
import 'package:etech_lab/screens/handovers_screens.dart';
import 'package:etech_lab/screens/preprocess_requests_screens.dart';
import 'package:etech_lab/screens/analysis_requests_screens.dart';
import 'package:etech_lab/screens/test_reports_screens.dart';
import 'package:etech_lab/screens/sampling_program_screens.dart';

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

String _fx(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();

/// MockClient: khớp URL theo phần path; trả fixture JSON cho mọi /api/*, và 1
/// ảnh PNG trong suốt 1x1 cho /web/image/* (ảnh đính kèm) để không vỡ test.
final _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

/// routes: khớp theo path SUFFIX → fixture name. Mặc định trả [fallback].
http.Client _client(String fallback, [Map<String, String> routes = const {}]) {
  return MockClient((req) async {
    final p = req.url.path;
    if (p.startsWith('/web/image') || p.contains('/avatar')) {
      return http.Response.bytes(_transparentPng, 200,
          headers: {'content-type': 'image/png'});
    }
    for (final e in routes.entries) {
      if (p.endsWith(e.key) || p.contains(e.key)) {
        return http.Response(_fx(e.value), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }
    }
    return http.Response(fallback, 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Font app thật là 'Inter' (assets/fonts) — phải load đúng family, nếu không
    // golden render ra ô vuông (Ahem fallback).
    final inter = FontLoader('Inter');
    for (final f in [
      'Inter-Regular.ttf',
      'Inter-Medium.ttf',
      'Inter-SemiBold.ttf',
      'Inter-Bold.ttf',
    ]) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      inter.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await inter.load();
    await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  Future<void> golden(
    WidgetTester tester,
    Widget home,
    String fallbackFixture,
    String goldenName, {
    Map<String, String> routes = const {},
    double height = 4000,
  }) async {
    AppColors.apply(kLightPalette);
    tester.view.physicalSize = Size(375 * 2, height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.light),
        home: home,
      ));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }, () => _client(_fx(fallbackFixture), routes));
    await expectLater(
        find.byType(home.runtimeType), matchesGoldenFile('goldens/$goldenName'));
  }

  testWidgets('sampling_report formview', (tester) async {
    await golden(
      tester,
      const SamplingDetailScreen(sessionId: 'x', reportId: 1362),
      'sampling_report',
      'form_sampling_report.png',
      routes: {'sampling/options': 'sampling_options'},
      height: 6200,
    );
  });

  // Bản NHÁP dùng chung formview với bản đã chốt (như Odoo), chỉ khác là các
  // field Odoo cho sửa thì render thành ô nhập → phủ luôn nhánh đó.
  testWidgets('sampling_report formview draft', (tester) async {
    await golden(
      tester,
      const SamplingDetailScreen(sessionId: 'x', reportId: 1362),
      'sampling_report_draft',
      'form_sampling_report_draft.png',
      routes: {'sampling/options': 'sampling_options'},
      height: 6200,
    );
  });

  testWidgets('lab_batch formview', (tester) async {
    await golden(tester,
        const LabBatchesDetailScreen(sessionId: 'x', batchId: 66),
        'lab_batch', 'form_lab_batch.png');
  });

  testWidgets('customer formview', (tester) async {
    await golden(tester,
        const CustomerDetailPage(sessionId: 'x', partnerId: 200),
        'customer', 'form_customer.png');
  });

  testWidgets('retained_sample formview', (tester) async {
    await golden(tester,
        const RetainedSampleDetailScreen(sessionId: 'x', sampleId: 599),
        'retained_sample', 'form_retained_sample.png');
  });

  testWidgets('service_request formview', (tester) async {
    await golden(tester,
        const ServiceRequestDetailScreen(sessionId: 'x', requestId: 1345),
        'service_request', 'form_service_request.png');
  });

  testWidgets('handover formview', (tester) async {
    await golden(tester,
        const HandoverDetailPage(sessionId: 'x', handoverId: 1260),
        'handover', 'form_handover.png');
  });

  testWidgets('preprocess formview', (tester) async {
    await golden(tester,
        const PreprocessRequestDetailPage(sessionId: 'x', requestId: 827),
        'preprocess_request', 'form_preprocess.png');
  });

  testWidgets('analysis formview', (tester) async {
    await golden(tester,
        const ArDetailPage(sessionId: 'x', requestId: 476),
        'analysis_request', 'form_analysis.png');
  });

  testWidgets('test_report formview', (tester) async {
    await golden(tester,
        const TestReportDetailPage(sessionId: 'x', reportId: 17),
        'test_report', 'form_test_report.png');
  });

  testWidgets('sampling_program formview', (tester) async {
    await golden(tester,
        const SamplingProgramDetailScreen(sessionId: 'x', programId: 2335),
        'sampling_program', 'form_sampling_program.png');
  });
}

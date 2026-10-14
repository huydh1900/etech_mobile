// Visual check cho LoginScreen: render với font thật rồi xuất golden PNG
// (chạy: flutter test --update-goldens test/login_visual_test.dart).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etech_lab/screens/login_screen.dart';
import 'package:etech_lab/theme/app_theme.dart';

const _fontDir =
    '/home/huytq/snap/flutter/common/flutter/bin/cache/artifacts/material_fonts';

Future<void> _loadFont(String family, List<String> files,
    {String dir = _fontDir}) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('$dir/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inter (font thật của app) có đủ dấu tiếng Việt — Roboto trong cache
    // Flutter thiếu glyph nên golden ra ô vuông.
    await _loadFont(
      'Inter',
      [
        'Inter-Regular.ttf',
        'Inter-Medium.ttf',
        'Inter-SemiBold.ttf',
        'Inter-Bold.ttf',
      ],
      dir: 'assets/fonts',
    );
    await _loadFont(
      'Lexend',
      [
        'Lexend-Regular.ttf',
        'Lexend-Medium.ttf',
        'Lexend-SemiBold.ttf',
        'Lexend-Bold.ttf',
      ],
      dir: 'assets/fonts',
    );
    await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  testWidgets('login screen visual', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      home: const LoginScreen(),
    ));
    await tester.pumpAndSettle();
    // Ảnh asset decode bất đồng bộ — cần runAsync để logo kịp vẽ vào golden.
    await tester.runAsync(() async {
      for (final el in find.byType(Image).evaluate()) {
        final img = el.widget as Image;
        await precacheImage(img.image, el);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login.png'),
    );
  });
}

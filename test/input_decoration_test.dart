// Test helper appInputDecoration — bằng chứng cho: (1) read-only field có nền
// phân biệt rõ, (2) luôn có focusedBorder, (3) bán kính nhất quán = AppRadius.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etech_lab/theme/app_theme.dart';

void main() {
  setUp(() => AppColors.apply(kLightPalette));

  test('Field editable dùng nền surface; read-only dùng nền bg', () {
    final editable = appInputDecoration(label: 'A');
    final readOnly = appInputDecoration(label: 'A', readOnly: true);
    expect(editable.fillColor, AppColors.surface);
    expect(readOnly.fillColor, AppColors.bg);
    expect(readOnly.fillColor, isNot(editable.fillColor));
  });

  test('Luôn có focusedBorder với màu focus chỉ định', () {
    final d = appInputDecoration(label: 'A', focusColor: AppColors.teal);
    final border = d.focusedBorder as OutlineInputBorder;
    expect(border.borderSide.color, AppColors.teal);
    expect(border.borderSide.width, greaterThan(1));
  });

  test('Bán kính bo nhất quán = AppRadius.md', () {
    final d = appInputDecoration(label: 'A');
    final enabled = d.enabledBorder as OutlineInputBorder;
    expect(
      enabled.borderRadius,
      BorderRadius.circular(AppRadius.md),
    );
  });
}

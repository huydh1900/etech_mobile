import 'package:flutter_test/flutter_test.dart';
import 'package:etech_lab/menu/app_modules.dart';
import 'package:etech_lab/screens/module_screen.dart';

/// Đảm bảo MỌI menu đánh dấu implemented:true đều được wire tới 1 màn thật
/// (không rơi về FeaturePlaceholderScreen) — bắt lỗi quên thêm case router.
void main() {
  test('mọi sub-menu implemented đều resolve ra màn thật', () {
    final missing = <String>[];
    var implementedCount = 0;
    for (final m in kAppModules) {
      for (final sub in m.children) {
        if (!sub.implemented) continue;
        implementedCount++;
        final screen = resolveSubMenuScreen(sub, 'test-session');
        if (screen is FeaturePlaceholderScreen) {
          missing.add('${m.key} / ${sub.backendXmlId} (${sub.name})');
        }
      }
    }
    expect(missing, isEmpty,
        reason: 'Các menu implemented nhưng chưa wire router: $missing');
    // Chốt số lượng để biết có bao nhiêu màn đã nối.
    expect(implementedCount, greaterThanOrEqualTo(11));
  });

  test('mọi placeholder vẫn instantiate được (không crash router)', () {
    for (final m in kAppModules) {
      for (final sub in m.children) {
        // chỉ cần không ném exception khi tạo widget
        resolveSubMenuScreen(sub, 'test-session');
      }
    }
  });
}

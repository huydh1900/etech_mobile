// Test resolveModules() — gating quyền theo tập menu backend trả về + override
// nhãn. Bổ trợ menu_routing_test.dart (vốn chỉ kiểm wiring router).

import 'package:flutter_test/flutter_test.dart';
import 'package:etech_lab/menu/app_modules.dart';

void main() {
  group('resolveModules', () {
    test('visible null -> giữ nguyên cấu hình tĩnh (offline/lỗi tải)', () {
      expect(resolveModules(visible: null), same(kAppModules));
    });

    test('chỉ giữ menu con có xmlid trong visible; ẩn module rỗng', () {
      final out = resolveModules(visible: {
        'menu_etech_service_request', // module "Hồ sơ"
        'menu_etech_sampling_report', // module "Hiện trường"
      });
      // 2 module có ít nhất 1 con khả dụng -> còn lại; module khác bị ẩn.
      expect(out.map((m) => m.key), containsAll(['request', 'field']));
      expect(out.any((m) => m.key == 'lab'), isFalse);
      expect(out.any((m) => m.key == 'calendar'), isFalse);

      final request = out.firstWhere((m) => m.key == 'request');
      expect(request.children, hasLength(1));
      expect(request.children.first.backendXmlId, 'menu_etech_service_request');
    });

    test('visible rỗng -> không module nào hiện', () {
      expect(resolveModules(visible: <String>{}), isEmpty);
    });

    test('override nhãn module + menu con từ backend names', () {
      final out = resolveModules(
        visible: {'menu_etech_service_request'},
        names: {
          'menu_etech_request_root': 'Hồ sơ (BE)',
          'menu_etech_service_request': 'Phiếu YC (BE)',
        },
      );
      final request = out.firstWhere((m) => m.key == 'request');
      expect(request.name, 'Hồ sơ (BE)');
      expect(request.children.first.name, 'Phiếu YC (BE)');
    });

    test('giữ nguyên icon/flag implemented khi copyWith override tên', () {
      final out = resolveModules(visible: {'menu_etech_service_request'});
      final sub = out.first.children.first;
      expect(sub.implemented, isTrue);
      expect(sub.icon, isNotNull);
    });

    test('thứ tự module theo cấu hình tĩnh được giữ', () {
      final out = resolveModules(visible: {
        'menu_etech_sample_destruction', // lab (module 5)
        'menu_etech_service_request', // request (module 1)
      });
      expect(out.map((m) => m.key).toList(), ['request', 'lab']);
    });
  });

  group('tính toàn vẹn cấu hình tĩnh', () {
    test('mọi backendXmlId menu con là duy nhất', () {
      final ids = <String>[];
      for (final m in kAppModules) {
        for (final c in m.children) {
          ids.add(c.backendXmlId);
        }
      }
      expect(ids.toSet().length, ids.length,
          reason: 'Trùng backendXmlId: $ids');
    });
  });
}

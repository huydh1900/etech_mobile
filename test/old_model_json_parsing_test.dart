// Hồi quy: hardening parse JSON Odoo cho các model CŨ (đồng bộ với fix đã làm
// ở 6 model mới). Odoo trả `false` cho field rỗng (char/m2o/date) và đôi khi
// thiếu/null id → model phải coerce về ''/0, KHÔNG render "false" hay crash cast.
import 'package:flutter_test/flutter_test.dart';

import 'package:etech_lab/models/service_request.dart';
import 'package:etech_lab/models/sample_retention.dart';
import 'package:etech_lab/models/app_notification.dart';
import 'package:etech_lab/models/lab_sample.dart';
import 'package:etech_lab/models/sampling.dart';
import 'package:etech_lab/models/app_permissions.dart';
import 'package:etech_lab/models/employee.dart';

void main() {
  group('Odoo false → coerce ʼʼ/0 (model cũ)', () {
    test('ServiceRequestBrief: false→ʼʼ, id/qty false→0', () {
      final b = ServiceRequestBrief.fromJson({
        'id': false,
        'code': false,
        'state': false,
        'partner_name': false,
        'total_sample_qty': false,
      });
      expect(b.id, 0);
      expect(b.code, '');
      expect(b.state, '');
      expect(b.partnerName, '');
      expect(b.totalSampleQty, 0);
    });

    test('ServiceRequestBrief: giá trị thật KHÔNG bị nuốt', () {
      final b = ServiceRequestBrief.fromJson({
        'id': 7,
        'code': 'PR001',
        'total_sample_qty': 3,
      });
      expect(b.id, 7);
      expect(b.code, 'PR001');
      expect(b.totalSampleQty, 3);
    });

    test('ServiceRequestLine._strList lọc false/null', () {
      final l = ServiceRequestLine.fromJson({
        'id': 1,
        'parameters': ['pH', false, '', null, 'As'],
        'methods': false,
      });
      expect(l.parameters, ['pH', 'As']);
      expect(l.methods, isEmpty); // false → [] (không phải ["false"])
    });

    test('RetainedSampleBrief: double field false→0.0', () {
      final r = RetainedSampleBrief.fromJson({
        'id': false,
        'retain_weight': false,
        'retain_count': false,
        'coded_sample': false,
      });
      expect(r.id, 0);
      expect(r.retainWeight, 0.0);
      expect(r.retainCount, 0);
      expect(r.codedSample, '');
      // double thật giữ nguyên
      final r2 = RetainedSampleBrief.fromJson({'id': 2, 'retain_weight': 1.5});
      expect(r2.retainWeight, 1.5);
    });

    test('AppNotification: false→ʼʼ/0, bool thật giữ nguyên', () {
      final n = AppNotification.fromJson({
        'id': false,
        'message_id': false,
        'subject': false,
        'res_id': false,
        'is_read': false,
      });
      expect(n.id, 0);
      expect(n.messageId, 0);
      expect(n.subject, '');
      expect(n.resId, 0);
      expect(n.isRead, false);
      expect(AppNotification.fromJson({'id': 5, 'is_read': true}).isRead, true);
    });

    test('HandoverBrief (lab_sample): report_code false→ʼʼ', () {
      final h = HandoverBrief.fromJson({
        'id': false,
        'report_code': false,
        'partner_name': false,
      });
      expect(h.id, 0);
      expect(h.reportCode, ''); // không phải "false"
      expect(h.partnerName, '');
    });

    test('SamplingReportBrief: false→ʼʼ, id false→0', () {
      final s = SamplingReportBrief.fromJson({
        'id': false,
        'code': false,
        'sample_count': false,
      });
      expect(s.id, 0);
      expect(s.code, '');
      expect(s.sampleCount, 0);
    });

    test('AppPermissions.menus lọc phần tử false/rỗng', () {
      final p = AppPermissions.fromJson({
        'menus': ['menu_a', false, '', 'menu_b'],
      });
      expect(p.menus, {'menu_a', 'menu_b'});
    });

    test('Employee: id false→0, many2one false→ʼʼ (không crash cast)', () {
      final e = Employee.fromJson({
        'id': false,
        'name': false,
        'parent_id': false, // many2one rỗng → Odoo trả false
        'department_manager': false,
      });
      expect(e.id, 0);
      expect(e.name, '');
      expect(e.manager, ''); // không phải "false"
      expect(e.departmentManager, '');
    });
  });
}

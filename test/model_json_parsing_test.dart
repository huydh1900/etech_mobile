// Test parsing JSON cho 6 module mới — tập trung vào các payload Odoo "khó":
//   - Odoo trả `false` cho field rỗng (char/many2one/date) -> phải coerce về ''
//     (KHÔNG được hiển thị chuỗi "false") và 0 cho số.
//   - id / số là `false` -> không được crash (regression cho cast `as num?`).
//   - line list thiếu / null / rỗng -> trả [] thay vì ném.
// Đây là bằng chứng hồi quy cho 3 bug đã sửa trong models/*.dart.

import 'package:flutter_test/flutter_test.dart';

import 'package:etech_lab/models/handovers.dart';
import 'package:etech_lab/models/lab_batches.dart';
import 'package:etech_lab/models/destructions.dart';
import 'package:etech_lab/models/test_reports.dart';
import 'package:etech_lab/models/preprocess_requests.dart';
import 'package:etech_lab/models/analysis_requests.dart';
import 'package:etech_lab/models/paged.dart';

void main() {
  group('Odoo false coercion -> chuỗi rỗng / 0 (không in "false")', () {
    test('HandoverBrief: field false -> ""', () {
      final h = HandoverBrief.fromJson({
        'id': 5,
        'code': 'BG-1',
        'report_code': false,
        'program_code': false,
        'request_code': false,
        'partner_name': false,
        'sample_type': false,
        'sample_name': false,
      });
      expect(h.id, 5);
      expect(h.reportCode, '');
      expect(h.partnerName, '');
      expect(h.sampleName, '');
      // không bao giờ là chuỗi "false"
      expect(h.reportCode, isNot('false'));
    });

    test('HandoverDetail: preprocess_requests thiếu -> []', () {
      final d = HandoverDetail.fromJson({'id': 1, 'code': 'BG-1'});
      expect(d.preprocessRequests, isEmpty);
      expect(d.partnerName, '');
    });

    test('TestReportBrief: false -> "", is_valid false', () {
      final t = TestReportBrief.fromJson({
        'id': 1,
        'code': 'TR-1',
        'code_internal': false,
        'report_date': false,
        'partner_name': false,
        'is_valid': false,
      });
      expect(t.codeInternal, '');
      expect(t.reportDate, '');
      expect(t.isValid, isFalse);
    });

    test('TestReportDetail: lod false -> 0.0, lines thiếu -> []', () {
      final t = TestReportDetail.fromJson({
        'id': 1,
        'result_line_ids': [
          {'id': 1, 'parameter_name': false, 'lod': false, 'result': false}
        ],
      });
      expect(t.resultLines, hasLength(1));
      expect(t.resultLines.first.lod, 0.0);
      expect(t.resultLines.first.parameterName, '');
      expect(t.sampleLines, isEmpty);
    });

    test('DestructionBrief: id false -> 0, sample_count false -> 0', () {
      final d = DestructionBrief.fromJson({
        'id': false,
        'name': false,
        'sample_count': false,
        'destroyer_name': false,
      });
      expect(d.id, 0);
      expect(d.sampleCount, 0);
      expect(d.name, '');
    });

    test('DestructionLine: retain_weight false -> 0.0', () {
      final d = DestructionDetail.fromJson({
        'id': 1,
        'lines': [
          {'id': 2, 'coded_sample': false, 'retain_weight': false}
        ],
      });
      expect(d.lines.first.retainWeight, 0.0);
      expect(d.lines.first.codedSample, '');
    });

    test('PreprocessRequestDetail: preprocessors có false/"" bị lọc bỏ', () {
      final p = PreprocessRequestDetail.fromJson({
        'id': 1,
        'name': false,
        'quantity': false,
        'preprocessors': ['An', false, '', 'Bình'],
        'lines': [
          {'id': 1, 'coded_sample': false, 'test_parameter': false}
        ],
      });
      expect(p.name, '');
      expect(p.quantity, '');
      expect(p.preprocessors, ['An', 'Bình']);
      expect(p.lines.first.codedSample, '');
    });

    test('ArDetail: số trong line là false -> 0; lines thiếu -> []', () {
      final a = ArDetail.fromJson({
        'id': 2,
        'name': false,
        'sample_name': false,
        'lines': [
          {
            'id': false,
            'coded_sample': false,
            'test_sample_weight': false,
            'test_sample_count': false,
            'retain_sample_weight': false,
          }
        ],
      });
      expect(a.sampleName, '');
      expect(a.lines.first.id, 0);
      expect(a.lines.first.testSampleWeight, 0.0);
      expect(a.lines.first.testSampleCount, 0);
      expect(a.lines.first.retainSampleWeight, 0.0);

      final empty = ArDetail.fromJson({'id': 3});
      expect(empty.lines, isEmpty);
    });

    test('LabBatchesDetail: số false -> 0; weighing_done false -> false', () {
      final b = LabBatchesDetail.fromJson({
        'id': 7,
        'name': false,
        'sample_count': false,
        'num_blank': false,
        'weighing_done': false,
        'line_ids': [
          {'id': 1, 'sequence': false, 'coded_sample': false}
        ],
      });
      expect(b.name, '');
      expect(b.sampleCount, 0);
      expect(b.numBlank, 0);
      expect(b.weighingDone, isFalse);
      expect(b.lines.first.sequence, 0);
      expect(b.testRecords, isEmpty);
    });
  });

  group('Giá trị thật vẫn parse đúng (không vô tình nuốt 0/false hợp lệ)', () {
    test('số 0 hợp lệ giữ nguyên 0, không nhầm với rỗng', () {
      final d = DestructionDetail.fromJson({
        'id': 9,
        'sample_count': 0,
        'lines': [
          {'id': 1, 'retain_weight': 0}
        ],
      });
      expect(d.sampleCount, 0);
      expect(d.lines.first.retainWeight, 0.0);
    });

    test('weighing_done true khi backend trả true', () {
      final b = LabBatchesDetail.fromJson({'id': 1, 'weighing_done': true});
      expect(b.weighingDone, isTrue);
    });

    test('chuỗi/số bình thường parse đúng', () {
      final t = TestReportDetail.fromJson({
        'id': 4,
        'code': 'TR-2026-0001',
        'total_sample_count': 12,
        'result_line_ids': [
          {'id': 1, 'parameter_name': 'Cd', 'lod': 0.05, 'result': '0.12'}
        ],
      });
      expect(t.code, 'TR-2026-0001');
      expect(t.totalSampleCount, 12);
      expect(t.resultLines.first.lod, 0.05);
      expect(t.resultLines.first.result, '0.12');
    });
  });

  group('PagedResult.fromJson', () {
    int identity(Map<String, dynamic> j) => (j['id'] as num).toInt();

    test('envelope đầy đủ: items/total/counts/hasMore', () {
      final p = PagedResult.fromJson({
        'items': [
          {'id': 1},
          {'id': 2}
        ],
        'total': 5,
        'all_count': 9,
        'counts': {'draft': 3, 'done': 2},
        'offset': 0,
        'limit': 2,
      }, identity);
      expect(p.items, [1, 2]);
      expect(p.total, 5);
      expect(p.allCount, 9);
      expect(p.counts, {'draft': 3, 'done': 2});
      expect(p.hasMore, isTrue); // 0 + 2 < 5
    });

    test('thiếu all_count -> fallback về total', () {
      final p = PagedResult.fromJson(
          {'items': [], 'total': 4}, identity);
      expect(p.allCount, 4);
    });

    test('hasMore: đã tải hết -> false', () {
      final p = PagedResult.fromJson({
        'items': [
          {'id': 1},
          {'id': 2}
        ],
        'total': 2,
        'offset': 0,
        'limit': 30,
      }, identity);
      expect(p.hasMore, isFalse); // 0 + 2 >= 2
    });

    test('total/counts là false (Odoo rỗng) -> 0, không crash', () {
      final p = PagedResult.fromJson({
        'items': [],
        'total': false,
        'counts': {'draft': false, 'done': 3},
      }, identity);
      expect(p.total, 0);
      expect(p.counts, {'draft': 0, 'done': 3});
    });

    test('envelope thiếu hết -> giá trị mặc định an toàn', () {
      final p = PagedResult.fromJson(<String, dynamic>{}, identity);
      expect(p.items, isEmpty);
      expect(p.total, 0);
      expect(p.counts, isEmpty);
      expect(p.hasMore, isFalse);
    });
  });
}

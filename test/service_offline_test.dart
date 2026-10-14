// Test hành vi service khi KHÔNG có backend (môi trường test):
//  - list: rơi về mock fallback -> filter state/query + paging + counts hoạt động
//    (đây là logic _mockPage thật, đáng kiểm).
//  - write action: KHÔNG có fallback -> phải ném Exception (lỗi nổi lên UI),
//    đúng như cam kết trong source ("KHÔNG có mock fallback cho write").
//
// Lưu ý: các service trỏ tới http://localhost:8001 (AppConfig). Trong test
// không có server nên request fail nhanh -> nhánh fallback/throw được kích hoạt.

import 'package:flutter_test/flutter_test.dart';
import 'package:etech_lab/services/handovers_service.dart';

void main() {
  late HandoverService svc;
  setUp(() {
    svc = HandoverService(baseUrl: 'http://127.0.0.1:1', sessionId: 'x');
  });

  group('list fallback mock (offline)', () {
    test('không filter -> trả toàn bộ mock + counts theo state', () async {
      final r = await svc.getHandovers();
      expect(r.items, isNotEmpty);
      expect(r.allCount, r.items.length); // mock có <= limit record
      // counts phải cộng đủ tổng record
      final sum = r.counts.values.fold<int>(0, (a, b) => a + b);
      expect(sum, r.allCount);
    });

    test('filter theo state chỉ trả record đúng state', () async {
      final r = await svc.getHandovers(state: 'draft');
      expect(r.items, isNotEmpty);
      expect(r.items.every((e) => e.state == 'draft'), isTrue);
      // total phản ánh số record sau filter
      expect(r.total, r.items.length);
    });

    test('filter state không tồn tại -> rỗng', () async {
      final r = await svc.getHandovers(state: 'khong_co_state');
      expect(r.items, isEmpty);
      expect(r.total, 0);
    });

    test('query lọc theo code/partner/sample (case-insensitive)', () async {
      final r = await svc.getHandovers(query: 'bg-2026-0001');
      expect(r.items, isNotEmpty);
      expect(
        r.items.every((e) =>
            e.code.toLowerCase().contains('bg-2026-0001') ||
            e.partnerName.toLowerCase().contains('bg-2026-0001') ||
            e.sampleName.toLowerCase().contains('bg-2026-0001')),
        isTrue,
      );
    });

    test('paging: limit cắt số item, offset bỏ qua', () async {
      final first = await svc.getHandovers(offset: 0, limit: 2);
      expect(first.items.length, lessThanOrEqualTo(2));
      final second = await svc.getHandovers(offset: 2, limit: 2);
      // 2 trang không trùng id
      final idsA = first.items.map((e) => e.id).toSet();
      final idsB = second.items.map((e) => e.id).toSet();
      expect(idsA.intersection(idsB), isEmpty);
    });

    test('detail fallback trả về bản ghi (kèm preprocess refs)', () async {
      final d = await svc.getHandover(1);
      expect(d.id, isNonZero);
      expect(d.preprocessRequests, isNotEmpty);
    });
  });

  group('write action không có fallback -> ném khi offline', () {
    test('handOver ném Exception (không nuốt lỗi)', () async {
      await expectLater(svc.handOver(1), throwsException);
    });

    test('receive ném Exception', () async {
      await expectLater(svc.receive(1), throwsException);
    });

    test('returnSample (kèm reason) ném Exception', () async {
      await expectLater(
          svc.returnSample(1, reason: 'mẫu hỏng'), throwsException);
    });
  });
}

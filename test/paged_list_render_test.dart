import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:etech_lab/models/paged.dart';
import 'package:etech_lab/widgets/paged_list.dart';

/// Render PagedListView (component dùng chung của cả 10 màn list) ở kích thước
/// màn hình điện thoại để bắt overflow/crash thật — không chỉ phân tích tĩnh.
void main() {
  const filters = <MapEntry<String, String>>[
    MapEntry('', 'Tất cả'),
    MapEntry('draft', 'Nháp'),
    MapEntry('done', 'Hoàn thành'),
  ];

  PagedFetch<String> fakeFetch(int total) {
    return ({state, query, required offset, required limit, params}) async {
      var all = List.generate(total, (i) => 'Bản ghi số $i — tên rất dài để thử tràn dòng trên màn hình hẹp');
      if (state != null && state.isNotEmpty) {
        all = all.where((e) => e.hashCode % 2 == 0).toList();
      }
      if (query != null && query.isNotEmpty) {
        all = all.where((e) => e.contains(query)).toList();
      }
      final page = all.skip(offset).take(limit).toList();
      return PagedResult<String>(
        items: page,
        total: all.length,
        allCount: total,
        counts: {'draft': total ~/ 2, 'done': total - total ~/ 2},
        offset: offset,
        limit: limit,
      );
    };
  }

  Widget harness(PagedFetch<String> fetch) => MaterialApp(
        home: Scaffold(
          body: PagedListView<String>(
            fetch: fetch,
            stateFilters: filters,
            unitLabel: 'mục',
            itemBuilder: (_, s) => Card(
              child: ListTile(
                title: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ),
      );

  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340); // ~360x780 logic
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('render danh sách + chip + count ở màn mobile, không overflow',
      (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(harness(fakeFetch(25)));
    await tester.pumpAndSettle();

    // Chip "Tất cả" hiển thị tổng count từ server.
    expect(find.text('Tất cả (25)'), findsOneWidget);
    expect(find.text('Nháp (12)'), findsOneWidget);
    // Có item render (page đầu).
    expect(find.textContaining('Bản ghi số 0'), findsOneWidget);
    // Thanh đếm kết quả.
    expect(find.textContaining('25 mục'), findsOneWidget);
    // pumpAndSettle sẽ throw nếu có overflow/exception trong render.
  });

  testWidgets('chọn chip trạng thái -> reload, vẫn render OK', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(harness(fakeFetch(25)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nháp (12)'));
    await tester.pumpAndSettle();
    // Không crash; chip vẫn còn.
    expect(find.text('Nháp (12)'), findsOneWidget);
  });

  testWidgets('phân trang 80/trang: ‹ › và chọn số trang', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(harness(fakeFetch(200)));
    await tester.pumpAndSettle();
    expect(find.text('1–80 / 200 mục'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.textContaining('Bản ghi số 0 '), findsOneWidget);

    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(find.text('81–160 / 200 mục'), findsOneWidget);
    expect(find.textContaining('Bản ghi số 80 '), findsOneWidget);
    expect(find.textContaining('Bản ghi số 0 '), findsNothing);

    await tester.tap(find.text('2 / 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.text('161–200 / 200 mục'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('list rỗng -> EmptyState', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(harness(fakeFetch(0)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('fetch lỗi -> ErrorState + nút thử lại', (tester) async {
    usePhoneSize(tester);
    Future<PagedResult<String>> boom(
            {String? state,
            String? query,
            required int offset,
            required int limit,
            Map<String, String>? params}) async =>
        throw Exception('Lỗi mạng giả lập');
    await tester.pumpWidget(harness(boom));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lỗi mạng giả lập'), findsOneWidget);
  });
}

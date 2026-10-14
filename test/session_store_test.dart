import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etech_lab/services/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('load trả null khi chưa lưu phiên', () async {
    expect(await SessionStore().load(), isNull);
  });

  test('save rồi load trả đúng session_id + uid', () async {
    await SessionStore().save(sessionId: 'abc123', uid: 7);
    final s = await SessionStore().load();
    expect(s, isNotNull);
    expect(s!.sessionId, 'abc123');
    expect(s.uid, 7);
  });

  test('save không uid vẫn load được session_id', () async {
    await SessionStore().save(sessionId: 'xyz');
    final s = await SessionStore().load();
    expect(s!.sessionId, 'xyz');
    expect(s.uid, isNull);
  });

  test('clear xóa phiên đã lưu', () async {
    await SessionStore().save(sessionId: 'abc', uid: 1);
    await SessionStore().clear();
    expect(await SessionStore().load(), isNull);
  });

  test('session_id rỗng coi như không có phiên', () async {
    await SessionStore().save(sessionId: '', uid: 1);
    expect(await SessionStore().load(), isNull);
  });
}

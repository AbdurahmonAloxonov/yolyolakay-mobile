import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/drafts.dart';

/// QORALAMALAR.
///
/// 🔴 NEGA TEST: qoralamaning eng yomon xatosi — u ESKI matnni qaytarib
/// chiqarishi. Odam xabarni yuboradi, chatga qaytadi va o'sha matnni
/// yana ko'radi: «yuborilmadimi?» deb ikkinchi marta yuboradi. Ya'ni
/// noto'g'ri qoralama qoralamasizlikdan YOMONROQ.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Drafts drafts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    drafts = Drafts(await SharedPreferences.getInstance());
  });

  test('yozilgan matn qaytadi', () async {
    await drafts.write(Drafts.chat('u-1'), 'Yo\'ldaman, 10 daqiqa');
    expect(drafts.read(Drafts.chat('u-1')), 'Yo\'ldaman, 10 daqiqa');
  });

  test('suhbatlar bir-biriga ARALASHMAYDI', () async {
    await drafts.write(Drafts.chat('u-1'), 'birinchiga');
    await drafts.write(Drafts.chat('u-2'), 'ikkinchiga');

    expect(drafts.read(Drafts.chat('u-1')), 'birinchiga');
    expect(drafts.read(Drafts.chat('u-2')), 'ikkinchiga');
  });

  /// 🔴 ENG MUHIM: yuborilgach qoralama O'CHADI.
  test('tozalangach qaytmaydi', () async {
    await drafts.write(Drafts.chat('u-1'), 'salom');
    await drafts.clear(Drafts.chat('u-1'));
    expect(drafts.read(Drafts.chat('u-1')), isNull);
  });

  /// Odam matnni O'ZI o'chirgan bo'lsa, uni qaytarib qo'yish g'alati.
  test('bo\'sh matn saqlanmaydi', () async {
    await drafts.write(Drafts.chat('u-1'), 'salom');
    await drafts.write(Drafts.chat('u-1'), '   ');
    expect(drafts.read(Drafts.chat('u-1')), isNull);
  });

  test('bo\'shliqlar kesiladi', () async {
    await drafts.write(Drafts.chat('u-1'), '  salom  ');
    expect(drafts.read(Drafts.chat('u-1')), 'salom');
  });

  test('yo\'q qoralama — null', () {
    expect(drafts.read(Drafts.chat('yoq')), isNull);
  });

  group('forma qoralamasi (map)', () {
    test('yoziladi va o\'qiladi', () async {
      await drafts.writeMap(Drafts.createRide, {
        'from': 'Toshkent',
        'seats': 3,
      });
      final read = drafts.readMap(Drafts.createRide);
      expect(read?['from'], 'Toshkent');
      expect(read?['seats'], 3);
    });

    test('buzuq JSON — null, tashlamaydi', () async {
      await drafts.write(Drafts.createRide, 'bu JSON emas {{{');
      expect(drafts.readMap(Drafts.createRide), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/format.dart';
import 'package:yolyolakay/l10n/strings.dart';
import 'package:yolyolakay/data/models/user.dart';

/// Pasportdan kelgan BOSH HARFLI ism (egasi qurilmada ko'rdi, 2026-08-13):
/// suhbatlar ro'yxatida "MUXAMMAD RAXMATILLAYEV" baqirayotgandek turardi.
void main() {
  _shortNameTests();

  group('prettyName', () {
    test('butunlay bosh harfli ism yumshatiladi', () {
      expect(prettyName('MUXAMMAD RAXMATILLAYEV'), 'Muxammad Raxmatillayev');
    });

    test('odam o\'zi yozgan ismga TEGILMAYDI', () {
      // Kichik harf bor — demak bu bizning "tuzatishimiz" kerak emas.
      expect(prettyName('Muxammad'), 'Muxammad');
      expect(prettyName('Aziz Karimov'), 'Aziz Karimov');
      // Ataylab katta yozilgan qism ham saqlanadi.
      expect(prettyName('Ali MDH'), 'Ali MDH');
    });

    test('apostrof saqlanadi', () {
      expect(prettyName("SOBIROV O'G'LI"), "Sobirov O'g'li");
    });

    test('bo\'sh qiymatlar yiqilmaydi', () {
      expect(prettyName(null), isNull);
      expect(prettyName(''), '');
    });
  });

  test('displayName ham yumshatilgan ismni beradi', () {
    const user = User(
      id: 'u-1',
      phoneNumber: '+998901234567',
      firstName: 'MUXAMMAD',
      lastName: 'RAXMATILLAYEV',
    );
    expect(user.displayName, 'Muxammad Raxmatillayev');
  });

  test('ismsiz foydalanuvchida telefon raqami buzilmaydi', () {
    const user = User(id: 'u-1', phoneNumber: '+998901234567');
    expect(user.displayName, '+998901234567');
  });

  /// 🔴 Sanada yil yo'qligi MENI ham chalg'itdi (2026-08-13): tariflar
  /// ekranida "Amal qiladi: 9 avgust" turardi, men uni o'tgan sana deb
  /// hisobotga yozdim — aslida u keyingi yilniki edi.
  group('formatDate — yil', () {
    test('joriy yilda yil yozilmaydi', () {
      final thisYear = DateTime(DateTime.now().year, 8, 9);
      expect(formatDate(thisYear, Lang.uz), '9 avgust');
    });

    test('boshqa yil bo\'lsa YIL ko\'rsatiladi', () {
      final nextYear = DateTime(DateTime.now().year + 1, 8, 9);
      expect(
        formatDate(nextYear, Lang.uz),
        '9 avgust ${DateTime.now().year + 1}',
      );
      final lastYear = DateTime(DateTime.now().year - 1, 8, 9);
      expect(
        formatDate(lastYear, Lang.uz),
        '9 avgust ${DateTime.now().year - 1}',
      );
    });
  });
}

/// ISM QISQARTIRISH — joy tor bo'lgan sarlavhalar uchun.
///
/// 🔴 NEGA (2026-09-02 ko'rigi): yozishma sarlavhasida to'liq ism
/// «Abdurahmon Rahm…» bo'lib KESILARDI. Kesilgan familiya hech narsa
/// bermaydi, bosh harf esa beradi.
void _shortNameTests() {
  test('familiya bosh harfga qisqaradi', () {
    expect(shortName('Abdurahmon Rahmatullayev'), 'Abdurahmon R.');
  });

  test('bitta so\'zli ism TEGILMAYDI', () {
    expect(shortName('Dilnoza'), 'Dilnoza');
  });

  test('apostrofli familiya bosh harfi butun qoladi', () {
    expect(shortName('Aziz O\'ktamov'), 'Aziz O\'.');
  });

  test('BOSH HARFLI yozuv avval tartibga solinadi', () {
    expect(shortName('MUXAMMAD RAXMATILLAYEV'), 'Muxammad R.');
  });

  test('bo\'sh qiymat o\'zgarmaydi', () {
    expect(shortName(null), isNull);
    expect(shortName(''), '');
  });
}

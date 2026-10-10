import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/l10n/cyrillic.dart';

/// LOTIN → KIRILL o'girgichi.
///
/// 🔴 NEGA TEST MUHIM: bu funksiya ilovaning BUTUN matnini o'giradi.
/// Bitta qoida xato bo'lsa, xato 763 ta joyda bir vaqtda ko'rinadi —
/// va uni kirillda o'qimaydigan odam (men ham) payqamaydi.
void main() {
  group('Asosiy qoidalar', () {
    test('oddiy so\'zlar', () {
      expect(toCyrillic('safar'), 'сафар');
      expect(toCyrillic('hamroh'), 'ҳамроҳ');
      expect(toCyrillic('qidirish'), 'қидириш');
      expect(toCyrillic('haydovchi'), 'ҳайдовчи');
    });

    /// 🔴 ENG NOZIK QOIDA: «yo'» — bu «ё» emas, y + o' = «йў».
    /// Digrafni oldin ushlasak «ёъл» chiqadi (prototipda shunday bo'ldi).
    test('yo\' → йў, ё EMAS', () {
      expect(toCyrillic("yo'l"), 'йўл');
      expect(toCyrillic("yo'q"), 'йўқ');
      expect(toCyrillic("yo'nalish"), 'йўналиш');
      expect(toCyrillic("Yo'l-yo'lakay"), 'Йўл-йўлакай');
    });

    test('o\' va g\' — ў va ғ', () {
      expect(toCyrillic("bo'sh"), 'бўш');
      expect(toCyrillic("to'g'ri"), 'тўғри');
      expect(toCyrillic("o'rindiq"), 'ўриндиқ');
    });

    test('digraflar', () {
      expect(toCyrillic('shahar'), 'шаҳар');
      expect(toCyrillic('uchrashuv'), 'учрашув');
      expect(toCyrillic('yozuv'), 'ёзув');
      expect(toCyrillic('yuk'), 'юк');
      expect(toCyrillic('yaqin'), 'яқин');
    });

    /// So'z boshida «e» → «э», o'rtada → «е».
    test('e harfi joyiga qarab', () {
      expect(toCyrillic('ertaga'), 'эртага');
      expect(toCyrillic('kelmoq'), 'келмоқ');
    });

    test('tutuq belgisi → ъ', () {
      expect(toCyrillic("ma'no"), 'маъно');
      expect(toCyrillic("e'lon"), "эълон");
    });
  });

  group('Saqlanadigan narsalar', () {
    test('brend va qisqartmalar LOTINDA qoladi', () {
      expect(toCyrillic('YolYolakay'), 'YolYolakay');
      expect(toCyrillic('SMS kod'), 'SMS код');
      expect(toCyrillic('Premium'), 'Premium');
    });

    test('raqam, tinish belgisi va bo\'shliq tegilmaydi', () {
      expect(toCyrillic('3 ta joy · 80 000'), '3 та жой · 80 000');
      expect(toCyrillic('01 A 123 BC'), '01 A 123 BC');
    });

    test('BOSH HARF va TO\'LIQ KATTA yozuv saqlanadi', () {
      expect(toCyrillic('Safar'), 'Сафар');
      // Urg'u vositasi: ilovada bunday yozuv ataylab ishlatiladi.
      expect(toCyrillic("BO'LMAYDI"), 'БЎЛМАЙДИ');
    });

    test('kirill matn IKKINCHI marta o\'girilmaydi', () {
      const already = 'Сафар қидириш';
      expect(toCyrillic(already), already);
    });
  });
}

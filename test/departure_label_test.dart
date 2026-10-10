import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/format.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// "Jo'nashiga qancha qoldi" yorlig'i.
///
/// Nima uchun test bor: yorliq VAQTGA bog'liq, ya'ni uni ko'z bilan tekshirish
/// ishonchsiz — kunning qaysi soatida qaraganingga qarab boshqacha chiqadi.
/// `now` parametri shuning uchun bor, testlar esa chegaralarni qotiradi.
void main() {
  final now = DateTime(2026, 8, 20, 10, 0);

  String uz(DateTime dt) => departureLabel(dt, Lang.uz, now: now);

  test('o\'tgan safar — "Jo\'nab ketdi"', () {
    expect(uz(now.subtract(const Duration(minutes: 1))), 'Jo\'nab ketdi');
  });

  test('bir daqiqadan kam — "Hozir jo\'naydi"', () {
    expect(uz(now.add(const Duration(seconds: 30))), 'Hozir jo\'naydi');
  });

  test('daqiqalar', () {
    expect(uz(now.add(const Duration(minutes: 25))), '25 daqiqadan keyin');
  });

  test('faqat soat — qo\'shimcha SOAT so\'ziga qo\'shiladi', () {
    expect(uz(now.add(const Duration(hours: 3))), '3 soatdan keyin');
  });

  test('soat + daqiqa — qo\'shimcha OXIRGI so\'zga qo\'shiladi', () {
    expect(
      uz(now.add(const Duration(hours: 2, minutes: 40))),
      '2 soat 40 daqiqadan keyin',
    );
  });

  test('12 soatdan uzoq, lekin BUGUN — "Bugun HH:MM"', () {
    // 10:00 + 13 soat = 23:00, o'sha kun.
    expect(uz(DateTime(2026, 8, 20, 23, 0)), 'Bugun 23:00');
  });

  test('ERTAGA', () {
    expect(uz(DateTime(2026, 8, 21, 8, 0)), 'Ertaga 08:00');
  });

  test('uzoq sana — BO\'SH (chaqiruvchi o\'z sanasini ko\'rsatadi)', () {
    expect(uz(DateTime(2026, 8, 25, 8, 0)), '');
  });

  test('null — bo\'sh', () {
    expect(uz2(null, now), '');
  });

  test('boshqa tillar ham to\'g\'ri qo\'shimcha oladi', () {
    final dt = now.add(const Duration(hours: 2, minutes: 40));
    expect(departureLabel(dt, Lang.ru, now: now), 'через 2 ч 40 мин');
    expect(departureLabel(dt, Lang.en, now: now), 'in 2 h 40 min');
  });

  test('hasDeparted', () {
    expect(hasDeparted(now.subtract(const Duration(minutes: 1)), now: now), isTrue);
    expect(hasDeparted(now.add(const Duration(minutes: 1)), now: now), isFalse);
    expect(hasDeparted(null, now: now), isFalse);
  });

  /// 🔴 KECHIKISH SHAFFOFLIGI (egasi tanlagan band, 2026-08-25).
  ///
  /// `departureLabel` jo'nash vaqti o'tgan zahoti «Jo'nab ketdi» derdi —
  /// HOLATDAN QAT'I NAZAR. Haydovchi hali qimirlamagan bo'lsa ham
  /// yo'lovchi «ketib qolibdi» deb o'ylardi, va bu aynan uchrashuv
  /// nuqtasida turgan daqiqada aytilardi.
  group('kechikish shaffofligi', () {
    test('vaqt o\'tdi, safar BOSHLANMAGAN — «kechikmoqda»', () {
      final dt = now.subtract(const Duration(minutes: 12));
      expect(
        departureStatusLabel(dt, RideStatus.active, Lang.uz, now: now),
        startsWith('Kechikmoqda'),
      );
      expect(
        departureStatusLabel(dt, RideStatus.active, Lang.ru, now: now),
        startsWith('Задерживается'),
      );
    });

    test('safar boshlangan — «yo\'lda»', () {
      final dt = now.subtract(const Duration(minutes: 30));
      expect(
        departureStatusLabel(dt, RideStatus.inProgress, Lang.uz, now: now),
        'Yo\'lda',
      );
    });

    test('tugagan safarда «kechikmoqda» DEYILMAYDI', () {
      final dt = now.subtract(const Duration(hours: 5));
      expect(
        departureStatusLabel(dt, RideStatus.completed, Lang.uz, now: now),
        'Jo\'nab ketdi',
      );
    });

    test('vaqt hali kelmagan — avvalgidek hisob', () {
      final dt = now.add(const Duration(hours: 2));
      expect(
        departureStatusLabel(dt, RideStatus.active, Lang.uz, now: now),
        departureLabel(dt, Lang.uz, now: now),
      );
    });
  });
}

String uz2(DateTime? dt, DateTime now) => departureLabel(dt, Lang.uz, now: now);

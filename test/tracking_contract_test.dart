import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/api/api_exception.dart';
import 'package:yolyolakay/data/models/telematics.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// 2026-08-30 da JONLI o'lchangan kontrakt nozikliklari.
///
/// Uchalasi ham egasining shikoyatidan chiqdi ("qabul qilib bo'lmayapti",
/// "navigatsiya shunchaki qo'yilgan") va uchalasi ham JIM xato edi:
/// `flutter analyze` ularni ko'rmaydi, ekranda esa noto'g'ri raqam yoki
/// inglizcha xom matn chiqadi.
void main() {
  group('/telematics/nearby — `distance` BIRLIGI', () {
    // O'lchov (probe.py tracking): ping nuqtasidan 1 km narida javob
    // `1000.99`, 10 km da `10010.4`. Ya'ni METR.
    test('`distance` metrda o\'qiladi, kilometrda emas', () {
      final d = NearbyDriver.fromJson({
        'driver_id': 'x',
        'distance': 1000.9999999999999,
        'latitude': 41.3,
        'longitude': 69.24,
      });

      expect(d.distanceMeters, closeTo(1001, 1));
      // 🔴 Ilgari shu maydon 1001 «kilometr» bo'lib o'qilardi.
      expect(d.distanceKm, closeTo(1.0, 0.01));
    });

    test('`distance_km` nomi kelsa u ROSTDAN kilometr deb olinadi', () {
      final d = NearbyDriver.fromJson({'driver_id': 'x', 'distance_km': 2.5});

      expect(d.distanceMeters, closeTo(2500, 1));
      expect(d.distanceKm, closeTo(2.5, 0.01));
    });

    test('`distance` yo\'q bo\'lsa null — nol emas', () {
      final d = NearbyDriver.fromJson({'driver_id': 'x'});

      expect(d.distanceMeters, isNull);
      expect(d.distanceKm, isNull);
    });
  });

  /// ═══ PING YOSHI (17.09.2026) ═══
  ///
  /// 🔴 NEGA: `updated_at` serverdan KELARDI, sayt uni ko'rsatardi,
  /// ilova esa umuman o'qimasdi — mashina nuqtasi ping to'xtaganda
  /// joyida qotib qolib, jonli nuqtadan farq qilmasdi.
  group('`updated_at` — nuqta qachonlik ekani', () {
    test('vaqt o\'qiladi va yoshga aylanadi', () {
      final at = DateTime.now().toUtc().subtract(const Duration(minutes: 7));
      final d = NearbyDriver.fromJson({
        'driver_id': 'x',
        'latitude': 41.3,
        'longitude': 69.24,
        'updated_at': at.toIso8601String(),
      });

      expect(d.updatedAt, isNotNull);
      expect(d.ageAt(DateTime.now())!.inMinutes, 7);
    });

    /// 🔴 Go'ning NOL VAQTI — «sana yo'q» degani. O'qib qo'ysak ping
    /// yoshi million daqiqa bo'lib chiqardi va nuqta DOIM «eskirgan»
    /// ko'rinardi (izohi `core/json.dart` da).
    test('Go nol vaqti — sana emas, null', () {
      final d = NearbyDriver.fromJson({
        'driver_id': 'x',
        'updated_at': '0001-01-01T00:00:00Z',
      });

      expect(d.updatedAt, isNull);
      expect(d.ageAt(DateTime.now()), isNull);
    });

    test('vaqt kelmasa yosh TAXMIN QILINMAYDI', () {
      final d = NearbyDriver.fromJson({'driver_id': 'x'});
      expect(d.ageAt(DateTime.now()), isNull);
    });

    /// Qurilma soati oldinda bo'lsa «-3 daqiqa oldin» chiqmasin.
    test('kelajakdagi vaqt nolga qisiladi', () {
      final d = NearbyDriver.fromJson({
        'driver_id': 'x',
        'updated_at': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 5))
            .toIso8601String(),
      });

      expect(d.ageAt(DateTime.now()), Duration.zero);
    });
  });

  group('Bron xatolari o\'zbekchaga tarjima qilinadi', () {
    String uz(String backend) => ApiException(
      kind: ApiErrorKind.badRequest,
      statusCode: 400,
      backendMessage: backend,
    ).localized(Lang.uz);

    // 🔴 AYNAN shu matn haydovchida chiqardi va tarjimasiz edi: shart
    // `not enough seats` ni qidirardi, backend esa `available` so'zini
    // orasiga qo'yadi.
    test(
      '«not enough available seats to accept this bid» — inglizcha qolmaydi',
      () {
        final text = uz('not enough available seats to accept this bid');

        expect(text, isNot(contains('seats')));
        expect(text, contains("Bo'sh o'rin"));
        // Haydovchiga NIMA QILISHI aytiladi, quruq "yetarli emas" emas.
        expect(text.toLowerCase(), contains('rad eting'));
      },
    );

    test('yo\'lovchining bron xatosi umumiy matn bilan qoladi', () {
      final text = uz('transaction failed: not enough available seats');

      expect(text, contains("Bo'sh o'rin yetarli emas"));
      // Haydovchiga aytiladigan maslahat yo'lovchiga KERAK EMAS.
      expect(text.toLowerCase(), isNot(contains('rad eting')));
    });

    /// 🔴 HAYDOVCHI BO'LISH OQIMINI TO'SADIGAN XATO (30.08 da jonli
    /// o'lchandi): `POST /users/upgrade` takrorlangan davlat raqamida
    /// XOM POSTGRES matnini `422` bilan qaytaradi. Xom matn to'siladi,
    /// lekin odam «Tizimda xatolik yuz berdi» degan foydasiz jumlani
    /// ko'rib, qayta-qayta yuboraverardi.
    test('takrorlangan davlat raqami — SABABI aytiladi', () {
      const backend =
          'ERROR: duplicate key value violates unique '
          'constraint "cars_gov_number_key" (SQLSTATE 23505)';
      final text = ApiException(
        // 422 bizda `unknown` ga tushadi — aynan shu yo'l sinaladi.
        kind: ApiErrorKind.unknown,
        statusCode: 422,
        backendMessage: backend,
      ).localized(Lang.uz);

      expect(text, contains('davlat raqami'));
      expect(text, isNot(contains('Tizimda xatolik')));
      // Xom SQL ekranga CHIQMASIN.
      expect(text.toLowerCase(), isNot(contains('sqlstate')));
      expect(text.toLowerCase(), isNot(contains('cars_gov_number_key')));
    });

    /// Notanish ichki xato esa AVVALGIDEK umumiy matn bilan qolsin —
    /// tarjima ro'yxati xom Postgres matnini ochib yubormasin.
    test('notanish ichki xato xom matnni OCHMAYDI', () {
      final text = ApiException(
        kind: ApiErrorKind.unknown,
        statusCode: 422,
        backendMessage:
            'ERROR: relation "widgets" does not exist '
            '(SQLSTATE 42P01)',
      ).localized(Lang.uz);

      expect(text, 'Tizimda xatolik yuz berdi');
    });

    test('«booking is not in a valid state» — ikki marta bosish', () {
      final text = uz('booking is not in a valid state to be accepted');

      expect(text, contains('allaqachon javob berilgan'));
    });
  });

  group('Bron statuslari', () {
    // `BookingStatus.cancelled` kodda BOR va tekshiriladi ham, lekin
    // tarjimasi yozilmagan edi — ekranda xom `cancelled` turardi.
    test('`cancelled` uchala tilda ham tarjima qilingan', () {
      for (final lang in Lang.values) {
        final label = AppStrings(lang).bookingStatus('cancelled');
        expect(label, isNot('cancelled'), reason: '$lang');
      }
    });

    test('barcha ma\'lum statuslar tarjimasi bor', () {
      const known = [
        'pending',
        'pending_negotiation',
        'confirmed',
        'rejected',
        'cancelled',
        'no_show',
      ];
      for (final status in known) {
        expect(
          AppStrings(Lang.uz).bookingStatus(status),
          isNot(status),
          reason: status,
        );
      }
    });
  });

  group('Fon rejimi — Android manifesti', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');

    test('oldingi plan xizmati uchun ruxsat e\'lon qilingan', () {
      if (!manifest.existsSync()) return;
      final xml = manifest.readAsStringSync().replaceAll(
        RegExp(r'<!--.*?-->', dotAll: true),
        '',
      );

      // targetSdk 34+ da bu ruxsatsiz xizmat ishga tushishi bilan
      // SecurityException tashlaydi. Plagin manifestida faqat
      // `<service>` bor, ruxsat esa BIZDAN.
      expect(xml, contains('android.permission.FOREGROUND_SERVICE_LOCATION'));
      expect(xml, contains('android.permission.FOREGROUND_SERVICE'));
      expect(xml, contains('android.permission.ACCESS_FINE_LOCATION'));
    });

    test('ACCESS_BACKGROUND_LOCATION so\'ralmaydi', () {
      if (!manifest.existsSync()) return;
      // ⚠️ IZOHLAR OLIB TASHLANADI: manifestda bu ruxsat NEGA yo'qligi
      // izohda tushuntirilgan va uni matn qidiruvi "bor" deb topib,
      // testni yolg'on yiqitardi.
      final xml = manifest.readAsStringSync().replaceAll(
        RegExp(r'<!--.*?-->', dotAll: true),
        '',
      );

      // 🔴 Bu ruxsat Google'ning eng qattiq tekshiruvidan o'tadi
      // (video bilan ariza, haftalab kutish, rad etilishi mumkin) va
      // bizga KERAK EMAS: joylashuv faqat foydalanuvchi o'zi boshlagan
      // safar davomida, ko'rinib turgan bildirishnoma bilan olinadi.
      // Kimdir uni "ishlamayapti" deb qo'shib qo'ysa, reliz Play'da
      // tiqilib qoladi — shuning uchun test.
      expect(
        xml,
        isNot(contains('ACCESS_BACKGROUND_LOCATION')),
        reason:
            'Oldingi plan xizmati yetadi. Bu ruxsat Play tekshiruvini '
            'haftalarga cho\'zadi va rad etilishi mumkin.',
      );
    });
  });
}

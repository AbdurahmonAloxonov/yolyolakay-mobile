import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:yolyolakay/features/map/live_point.dart';

/// JONLI NUQTA — silliq harakat YOLG'ON gapirmaydimi?
///
/// 🔴 NEGA YOZILDI (18.09.2026): nuqtani ikki ping orasida surish —
/// ko'rinishdan kichik o'zgarish, mohiyatdan esa MA'LUMOTGA ARALASHUV:
/// ekranda mashina BIZ chizgan joyda turadi, serverdan kelgan joyda
/// emas. Uchta qoidaning har biri jimgina buzilishi mumkin va buzilgani
/// ekranda XATO bo'lib KO'RINMAYDI — harakat chiroyli, ishonarli va
/// noto'g'ri bo'ladi.
///
/// 🔑 Saytdagi juftligi: `scripts/check-live-point.ts` (aynan shu
/// holatlar). Ikki mijozda qoida bir xil bo'lishi kerak.
void main() {
  const tashkent = LatLng(41.2995, 69.2401);
  // ~1.4 km janubi-g'arbda — 100 km/soat bilan ~50 soniyalik yo'l,
  // ya'ni ikki ping orasidagi ODATIY farq.
  const nextPing = LatLng(41.2895, 69.2301);
  const samarkand = LatLng(39.6542, 66.9597);

  group('Silliqlash qoidalari', () {
    test('odatiy qadam suriladi', () {
      expect(
        canSmooth(tashkent, nextPing, age: const Duration(seconds: 5)),
        isTrue,
      );
    });

    test('KATTA SAKRASH surilmaydi', () {
      // GPS qayta ushlagan yoki haydovchi aloqasiz yurib kelgan —
      // buni 10 soniyada silliq chizsak, mashina yo'q joydan o'tadi.
      expect(
        canSmooth(tashkent, samarkand, age: const Duration(seconds: 5)),
        isFalse,
      );
    });

    test('ESKIRGAN ping surilmaydi', () {
      expect(
        canSmooth(tashkent, nextPing, age: const Duration(minutes: 11)),
        isFalse,
      );
      expect(
        canSmooth(tashkent, nextPing, age: const Duration(minutes: 9)),
        isTrue,
      );
    });

    test("yoshi NOMA'LUM ping suriladi", () {
      // `updated_at` ko'p javobda umuman kelmaydi — bu harakatni
      // taqiqlash uchun asos emas.
      expect(canSmooth(tashkent, nextPing, age: null), isTrue);
    });

    test('qimirlamagan nuqta animatsiya QILINMAYDI', () {
      expect(canSmooth(tashkent, tashkent, age: Duration.zero), isFalse);
    });

    test('nuqta yo\'q bo\'lsa surilmaydi', () {
      expect(canSmooth(null, nextPing), isFalse);
      expect(canSmooth(tashkent, null), isFalse);
    });
  });

  group('Kadrlar', () {
    test('boshi va oxiri AYNAN joyida', () {
      final a = frameAt(tashkent, nextPing, 0);
      final b = frameAt(tashkent, nextPing, 1);
      expect(a.latitude, closeTo(tashkent.latitude, 1e-9));
      expect(b.latitude, closeTo(nextPing.latitude, 1e-9));
      expect(b.longitude, closeTo(nextPing.longitude, 1e-9));
    });

    test('EKSTRAPOLYATSIYA YO\'Q — manzildan nariga o\'tmaydi', () {
      // Ping kechiksa nuqta TO'XTAYDI. «Shu tezlikda davom etdi» deb
      // chizish — joyni o'ylab topish bo'lardi.
      final over = frameAt(tashkent, nextPing, 2.5);
      expect(over.latitude, closeTo(nextPing.latitude, 1e-9));
      final under = frameAt(tashkent, nextPing, -3);
      expect(under.latitude, closeTo(tashkent.latitude, 1e-9));
    });

    test('harakat faqat OLDINGA', () {
      const d = Distance();
      var prev = d.as(LengthUnit.Meter, tashkent, nextPing);
      for (var i = 1; i <= 20; i++) {
        final f = frameAt(tashkent, nextPing, i / 20);
        final left = d.as(LengthUnit.Meter, f, nextPing);
        expect(left, lessThanOrEqualTo(prev + 1e-6));
        prev = left;
      }
    });

    test('egri chiziq chegaradan chiqmaydi', () {
      expect(easeInOut(0), 0);
      expect(easeInOut(1), 1);
      expect(easeInOut(-1), 0);
      expect(easeInOut(5), 1);
      expect(easeInOut(0.5), closeTo(0.5, 1e-9));
    });
  });

  group('Yo\'nalish', () {
    test('350° → 10° QISQA tomondan buriladi', () {
      // Uzun tomondan borsa strelka ekranda g'ildirakdek aylanardi.
      final mid = lerpHeading(350, 10, 0.5)!;
      expect(mid > 355 || mid < 5, isTrue, reason: '$mid gradus');
    });

    test('qiymat 0–360 oralig\'ida qoladi', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final v = lerpHeading(350, 10, t)!;
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThan(360));
      }
    });

    test('noma\'lum yo\'nalish o\'ylab topilmaydi', () {
      expect(lerpHeading(null, null, 0.5), isNull);
      // Faqat yangisi ma'lum bo'lsa — o'sha olinadi (yo'q joydan burish
      // ma'nosiz).
      expect(lerpHeading(null, 90, 0.3), 90);
      expect(lerpHeading(90, null, 0.3), 90);
    });
  });

  group('SmoothPoint vidjeti', () {
    /// Nuqtani berib, kadrlarni o'lchaydigan yordamchi.
    Future<List<LatLng>> run(
      WidgetTester tester, {
      required LatLng from,
      required LatLng to,
      Duration? age,
    }) async {
      final seen = <LatLng>[];
      Widget build(LatLng p) => MaterialApp(
        home: SmoothPoint(
          point: p,
          age: age,
          builder: (context, point, heading) {
            seen.add(point);
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpWidget(build(from));
      seen.clear();
      await tester.pumpWidget(build(to));
      await tester.pump(const Duration(seconds: 5));
      return seen;
    }

    testWidgets('yangi ping kelsa nuqta ORALIQ joylardan o\'tadi', (
      tester,
    ) async {
      final seen = await run(
        tester,
        from: tashkent,
        to: nextPing,
        age: const Duration(seconds: 5),
      );
      // Oraliq kadr — na boshida, na oxirida turgan joy.
      final between = seen.any(
        (p) =>
            p.latitude < tashkent.latitude - 1e-6 &&
            p.latitude > nextPing.latitude + 1e-6,
      );
      expect(
        between,
        isTrue,
        reason: 'nuqta sakrab o\'tdi — oraliq kadr umuman bo\'lmadi',
      );
    });

    testWidgets('KATTA SAKRASH darhol ko\'chadi (oraliq kadr yo\'q)', (
      tester,
    ) async {
      final seen = await run(
        tester,
        from: tashkent,
        to: samarkand,
        age: const Duration(seconds: 5),
      );
      expect(seen, isNotEmpty);
      // Hamma kadr AYNAN manzilda: hech qachon oraliqda chizilmagan.
      for (final p in seen) {
        expect(p.latitude, closeTo(samarkand.latitude, 1e-9));
      }
    });

    testWidgets('ESKIRGAN ping darhol ko\'chadi', (tester) async {
      final seen = await run(
        tester,
        from: tashkent,
        to: nextPing,
        age: const Duration(minutes: 30),
      );
      for (final p in seen) {
        expect(p.latitude, closeTo(nextPing.latitude, 1e-9));
      }
    });
  });
}

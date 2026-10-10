import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/rides/seat_map.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// O'RINDIQ SXEMASI — salon shaklida.
///
/// 🔴 NEGA TEST: sxema «bu safarda joy bormi» degan savolga BIR
/// QARASHDA javob beradi. Noto'g'ri chizsa, odam bo'sh deb o'ylab bosadi
/// yoki band deb o'ylab ketadi — ikkalasi ham matnli xatodan yomonroq,
/// chunki hech qanday xato xabari chiqmaydi.
///
/// 🔴 HALOL CHEKLOV shu yerda qotiriladi: backend o'rindiq POZITSIYASINI
/// saqlamaydi (bronda faqat `seats_booked` SONI bor). Shuning uchun
/// sxema hech qachon «kim qayerda» demaydi — faqat nechtasi band.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(420, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      // 🔴 ILOVANING O'Z TEMASI (2026-09-02): busiz test standart
      // Material BINAFSHASINI o'lchardi — foydalanuvchi hech qachon
      // ko'rmaydigan rangni. Rang qarorlari shu sababli tekshirilmay
      // qolardi.
      theme: buildTheme(brightness: Brightness.light),
      locale: const Locale('uz'),
      supportedLocales: const [Locale('uz')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const t = AppStrings(Lang.uz);

  /// Yo'lovchi o'rindiqlari (haydovchiniki BOSHQA belgi).
  int passengerSeats(WidgetTester tester) => tester
      .widgetList<Icon>(find.byType(Icon))
      .where((i) => i.icon == Icons.event_seat)
      .length;

  testWidgets('4 o\'rindiq: OLD va ORQA qatorga bo\'linadi', (tester) async {
    await _pump(tester, const SeatMap(totalSeats: 4, availableSeats: 4));

    // Haydovchi o'rindig'i chizilgan — usiz qator "mashina" bo'lib
    // ko'rinmaydi, shunchaki nuqtalar bo'lib qoladi.
    expect(
      tester
          .widgetList<Icon>(find.byType(Icon))
          .where((i) => i.icon == Icons.airline_seat_recline_extra)
          .length,
      1,
    );
    expect(passengerSeats(tester), 4);

    // Old qator BITTA o'rindiq: O'zbekistonda sotiladigan mashinalarning
    // deyarli hammasi shunday (Cobalt, Nexia, Malibu).
    final driver = tester.getCenter(
      find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.airline_seat_recline_extra,
      ),
    );
    final seats = find.byWidgetPredicate(
      (w) => w is Icon && w.icon == Icons.event_seat,
    );
    final front = tester
        .widgetList<Icon>(seats)
        .toList()
        .asMap()
        .keys
        .map((i) => tester.getCenter(seats.at(i)))
        .where((c) => (c.dy - driver.dy).abs() < 4)
        .length;
    expect(front, 1, reason: 'oldinda faqat bitta yo\'lovchi o\'rindig\'i');
  });

  testWidgets('bandlar ORQADAN to\'ladi, old o\'rindiq oxirida', (
    tester,
  ) async {
    // 4 tadan 1 tasi bo'sh = 3 tasi band. Orqada 3 joy bor, ya'ni
    // uchalasi ham orqada; old o'rindiq BO'SH qolishi kerak.
    await _pump(tester, const SeatMap(totalSeats: 4, availableSeats: 1));

    final driverY = tester
        .getCenter(
          find.byWidgetPredicate(
            (w) => w is Icon && w.icon == Icons.airline_seat_recline_extra,
          ),
        )
        .dy;
    final seats = find.byWidgetPredicate(
      (w) => w is Icon && w.icon == Icons.event_seat,
    );
    Icon frontSeat = tester.widget<Icon>(seats.at(0));
    for (var i = 0; i < tester.widgetList(seats).length; i++) {
      if ((tester.getCenter(seats.at(i)).dy - driverY).abs() < 4) {
        frontSeat = tester.widget<Icon>(seats.at(i));
      }
    }
    // Bo'sh o'rindiq brend rangida, band esa so'ngan — ranglar bir xil
    // bo'lsa sxema hech nima aytmaydi.
    final ctx = tester.element(seats.at(0));
    final scheme = Theme.of(ctx).colorScheme;
    expect(frontSeat.color, isNot(scheme.surfaceContainerHighest));
  });

  testWidgets('hamma joy band — hech biri bo\'sh rangda emas', (tester) async {
    await _pump(tester, const SeatMap(totalSeats: 4, availableSeats: 0));

    final seats = find.byWidgetPredicate(
      (w) => w is Icon && w.icon == Icons.event_seat,
    );
    final ctx = tester.element(seats.at(0));
    final scheme = Theme.of(ctx).colorScheme;
    final taken = tester.widget<Icon>(seats.at(0)).color!;

    // Hammasi BIR XIL rangda — «band» rangida.
    for (var i = 0; i < 4; i++) {
      expect(tester.widget<Icon>(seats.at(i)).color, taken);
    }

    /*
     * 🔴 BAND VA BO'SH O'RINDIQ AJRALIB TURSIN (2026-09-02 ko'rigi).
     *
     * Ilgari bu yerda aniq token (`surfaceContainerHighest`) yozilgan
     * edi va test o'tardi — lekin AYNAN o'sha token oq zaminda deyarli
     * oq bo'lib chiqardi. Bo'sh o'rindiq esa brend rangining 32% i edi,
     * ya'ni u ham deyarli oq. Rasmda band va bo'sh o'rindiqni ajratib
     * bo'lmasdi, test esa buni ko'rmasdi: u RANG NOMINI tekshirardi,
     * KO'RINISHNI emas.
     *
     * ⚠️ Ranglar SHAFFOF — `computeLuminance()` alfani hisobga OLMAYDI.
     * Shuning uchun ikkalasi ham avval zamin ustiga QO'YILADI, keyin
     * o'lchanadi. Busiz test yolg'on natija berardi.
     */
    await _pump(tester, const SeatMap(totalSeats: 4, availableSeats: 4));
    final free = tester.widget<Icon>(seats.at(0)).color!;

    Color on(Color c) => Color.alphaBlend(c, scheme.surface);

    /*
     * ⚠️ YORUG'LIK KONTRASTI BU YERDA YARAMAYDI. Bo'sh o'rindiq pushti,
     * band o'rindiq kulrang — ularning YORUG'LIGI deyarli bir xil,
     * farqi TUSDA. Yorug'lik nisbati 1.17 chiqadi va test «bir xil»
     * deb yolg'on xabar berardi.
     *
     * Shuning uchun ranglar orasidagi masofa o'lchanadi (RGB fazoda).
     * 60 — o'lchovdan: eski (deyarli oq) juftlik 58 berardi, hozirgisi
     * 100 dan yuqori.
     */
    double distance(Color a, Color b) {
      final x = on(a);
      final y = on(b);
      final dr = (x.r - y.r) * 255;
      final dg = (x.g - y.g) * 255;
      final db = (x.b - y.b) * 255;
      return math.sqrt(dr * dr + dg * dg + db * db);
    }

    expect(
      distance(taken, free),
      greaterThanOrEqualTo(60),
      reason:
          'band va bo\'sh o\'rindiq bir xil ko\'rinadi — sxema '
          '«joy bormi» degan savolga javob bermaydi',
    );
  });

  testWidgets('7 o\'rindiq (Damas): orqa qator IKKIGA bo\'linadi', (
    tester,
  ) async {
    await _pump(tester, const SeatMap(totalSeats: 7, availableSeats: 7));
    expect(passengerSeats(tester), 7);

    // Uchta ALOHIDA qator bo'lishi kerak: sakkizta belgi bitta qatorga
    // tiqilsa tor telefonda hech nima o'qilmaydi.
    final seats = find.byWidgetPredicate(
      (w) => w is Icon && w.icon == Icons.event_seat,
    );
    final rows = <double>{};
    for (var i = 0; i < 7; i++) {
      rows.add(tester.getCenter(seats.at(i)).dy.roundToDouble());
    }
    expect(rows.length, 3);
  });

  testWidgets('«orqada 2 kishi» qoidasi sxema YONIDA aytiladi', (tester) async {
    await _pump(
      tester,
      const SeatMap(totalSeats: 4, availableSeats: 2, maxTwoBack: true),
    );
    expect(find.text(t.maxTwoBack), findsOneWidget);
    expect(find.text(t.seatsFreeOfTotal(2, 4)), findsOneWidget);
  });

  testWidgets('ixcham ko\'rinishda sarlavha va matn YO\'Q', (tester) async {
    await _pump(
      tester,
      const SeatMap(totalSeats: 4, availableSeats: 2, compact: true),
    );
    // Kartada joy tor: sxema o'qishga emas, bir qarashda javob berishga.
    expect(find.text(t.seatsTitle), findsNothing);
    expect(find.text(t.seatsFreeOfTotal(2, 4)), findsNothing);
    expect(passengerSeats(tester), 4);
  });

  testWidgets('yaroqsiz ma\'lumotda HECH NIMA chizilmaydi', (tester) async {
    // Bo'sh ramka "ilova buzuq" degandek ko'rinadi.
    await _pump(tester, const SeatMap(totalSeats: 0, availableSeats: 0));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('bo\'sh o\'rindiqqa bosilsa TANLANADI', (tester) async {
    int? picked;
    await _pump(
      tester,
      SeatMap(
        totalSeats: 4,
        availableSeats: 4,
        maxSelectable: 4,
        onSelect: (n) => picked = n,
      ),
    );
    final seats = find.byWidgetPredicate(
      (w) => w is Icon && w.icon == Icons.event_seat,
    );
    await tester.tap(seats.at(0));
    await tester.pumpAndSettle();
    expect(picked, isNotNull);
    expect(picked, greaterThan(0));
  });
}

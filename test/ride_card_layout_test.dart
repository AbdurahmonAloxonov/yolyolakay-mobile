import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/core/format.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/ride_card.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// SAFAR KARTASI — VAQT VA NARX HAR DOIM O'QILADI.
///
/// 🔴 NEGA BU TEST BOR (2026-09-02 ko'rigi).
///
/// Kartaning sarlavha qatorida to'rt narsa turardi: jo'nash vaqti,
/// o'rindiq sxemasi, «N joy qoldi» nishoni va narx. Sxema ~95 piksel,
/// nishon yana ~95 piksel QAT'IY joy egallaydi — ikkalasini ham hech
/// narsa qisqartira olmaydi. Natijada matnga joy qolmasdi va O'LCHANDI:
///
///   jo'nash vaqti  →  eni 0.0 px — 320, 360 VA 412 px ekranlarda,
///                     o'zbekcha ham, ruscha ham. Ya'ni ilovadagi eng
///                     ko'p ochiladigan ro'yxatda safar QACHON ekani
///                     HECH QAYSI telefonda ko'rinmasdi;
///   narx           →  110 px kerak, 55–92 px berilardi → «150 000 s…».
///
/// 🔑 NEGA HECH QANDAY TEST TUTMADI: matn KESILGAN, toshgan emas.
/// `TextOverflow.ellipsis` toshishni yutadi — `RenderFlex overflowed`
/// chiqmaydi, `flutter analyze` jim, ekranda ham sariq chiziq yo'q.
/// `find.text` esa eni nol bo'lgan vidjetni ham TOPADI.
///
/// 🔑 Shuning uchun bu yerda MATN EMAS, unga BERILGAN EN o'lchanadi.
///
/// 🔴 QAYTA YOZILDI (10.09.2026). Bu yerda ilgari qat'iy piksel
/// chegaralari turardi (80 va 100) va ustida «chegaralar shriftga
/// bog'liq emas» deb yozilgan edi. IKKALASI HAM NOTO'G'RI bo'lib
/// chiqdi:
///
///   • ilova o'sha paytda umuman boshqa shriftda o'lchanardi —
///     `ThemeData` dagi `fontFamily` ishlamayotgan edi va testlarda
///     Inter emas, yuklanmagan Roboto (ya'ni glifsiz sinov shrifti)
///     chizilardi (`theme_font_test.dart`);
///   • shrift to'g'rilangach eni 79.63 va 98.69 px bo'ldi — ya'ni
///     chegaralar SHRIFTGA BOG'LIQ ekan: qatordagi qo'shni
///     elementlarning o'z eni shriftdan keladi va flex'ga qolgan
///     joyni o'zgartiradi.
///
/// Qat'iy raqamni yana tanlash — o'sha xatoni takrorlash bo'lardi.
/// Endi savol to'g'ri qo'yiladi: matn KESILDIMI. Ya'ni unga berilgan
/// en, o'sha matn haqiqiy shriftda talab qiladigan endan kam emasmi.
/// Nol pikselli falokat uchun esa yengil quyi chegara qoladi.
void main() {
  /// FALOKAT CHEGARASI — asl xato (eni 0.0 px) uchun. Kesilish
  /// tekshiruvi buni allaqachon tutadi; bu esa matn UMUMAN
  /// topilmagan (`-1`) yoki yo'q qilingan holatni ochiq aytadi.
  const minAnyWidth = 20.0;

  Future<Map<String, double>> widths(
    WidgetTester tester, {
    required double screen,
    required String lang,
    required double scale,
    required int availableSeats,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(Size(screen, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final departure = DateTime.now().add(const Duration(hours: 20));
    final ride = Ride(
      id: 'r1',
      originAddress: 'Toshkent, Chilonzor tumani, Bunyodkor shoh ko\'chasi 12',
      destinationAddress: 'Samarqand, Registon maydoni yaqinida',
      originLat: 41.3,
      originLon: 69.2,
      destinationLat: 39.6,
      destinationLon: 66.9,
      // «Ertaga …» yorlig'i chiqishi uchun ertangi kun.
      departureTime: departure,
      totalSeats: 4,
      availableSeats: availableSeats,
      pricePerSeat: 150000,
      status: RideStatus.active,
      hasAc: true,
      hasLuggage: true,
      noSmoking: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          locale: Locale(lang),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(children: [RideCard(ride: ride)]),
          ),
        ),
      ),
    );
    // Jonlanishlar tugasin.
    await tester.pump(const Duration(seconds: 2));

    final lg = Lang.values.firstWhere((l) => l.name == lang);
    // Yorliq matnini KODNING O'ZIDAN olamiz — «Ertaga»/«Завтра» ni
    // testda qayta yozsak, tarjima o'zgarganda test jim yiqilardi.
    final timeLabel = departureStatusLabel(departure, RideStatus.active, lg);
    /// Matnga berilgan en va u haqiqatan talab qiladigan en.
    /// `needed` haqiqiy shriftda hisoblanadi (`flutter_test_config.dart`
    /// Inter'ni yuklaydi) — shriftsiz muhitda bu raqam yolg'on chiqadi.
    ({double given, double needed}) measure(String startsWith) {
      for (final e in find.byType(RichText).evaluate()) {
        final rp = e.renderObject! as RenderParagraph;
        if (rp.text.toPlainText().startsWith(startsWith)) {
          return (
            given: rp.size.width,
            needed: rp.getMaxIntrinsicWidth(double.infinity),
          );
        }
      }
      return (given: -1, needed: -1);
    }

    final time = measure(timeLabel);
    final price = measure(formatPrice(150000));
    return {
      // Jo'nash yorlig'i «Ertaga»/«Завтра»/«Tomorrow» bilan boshlanadi.
      'time': time.given,
      'timeNeeded': time.needed,
      'price': price.given,
      'priceNeeded': price.needed,
    };
  }

  for (final screen in const [320.0, 360.0, 412.0]) {
    for (final lang in const ['uz', 'ru', 'en']) {
      for (final scale in const [1.0, 1.3]) {
        // Nishonli (1-2 joy qolgan — eng tor holat) VA nishonsiz.
        for (final seats in const [2, 3]) {
          testWidgets(
            'karta ${screen.toInt()} · $lang · x$scale · $seats joy — '
            'vaqt va narx O\'QILADI',
            (tester) async {
              final w = await widths(
                tester,
                screen: screen,
                lang: lang,
                scale: scale,
                availableSeats: seats,
              );

              expect(
                w['time'],
                greaterThanOrEqualTo(minAnyWidth),
                reason:
                    'jo\'nash vaqti topilmadi yoki eni ${w['time']} px — '
                    'ro\'yxatda safar QACHON ekani umuman ko\'rinmaydi',
              );
              expect(
                w['price'],
                greaterThanOrEqualTo(minAnyWidth),
                reason:
                    'narx topilmadi yoki eni ${w['price']} px — '
                    'kartadagi eng muhim raqam yo\'q',
              );

              // ASOSIY SHART: kesilmasin. Yarim piksel — yaxlitlash
              // uchun, undan kattasi haqiqiy kesilish.
              expect(
                w['time'],
                greaterThanOrEqualTo(w['timeNeeded']! - 0.5),
                reason:
                    'jo\'nash vaqti KESILADI: ${w['time']!.toStringAsFixed(1)} px '
                    'berildi, ${w['timeNeeded']!.toStringAsFixed(1)} px kerak. '
                    '`ellipsis` buni jimgina yutadi.',
              );
              expect(
                w['price'],
                greaterThanOrEqualTo(w['priceNeeded']! - 0.5),
                reason:
                    'narx KESILADI: ${w['price']!.toStringAsFixed(1)} px '
                    'berildi, ${w['priceNeeded']!.toStringAsFixed(1)} px kerak.',
              );
            },
          );
        }
      }
    }
  }
}

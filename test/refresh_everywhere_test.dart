import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/audit_screens.dart';

/// TORTIB-YANGILASH HAMMA JOYDA — VA HAR HOLATDA.
///
/// 🔴 NEGA QAYTA YOZILDI (egasi, 2026-09-04: «refreshni ilovada ko'rib
/// chiq — profilda ham yo'q, asosiy qidirish qismida ham yo'q, har bir
/// joyda tepadan pastga surish hissi bo'lishi kerak»).
///
/// Test 30-avgustdan beri bor edi va YASHIL turardi — lekin ichida
/// qochiriq bor edi:
///
/// ```dart
/// final scrollables = find.byType(Scrollable).evaluate().length;
/// if (scrollables == 0) return;          // ← AYNAN SHU
/// ```
///
/// Ya'ni: «ekranda suriladigan qism bo'lmasa, tekshirmaymiz». Holbuki
/// SURILADIGAN QISMNING YO'QLIGI — bu xatoning O'ZI. Ma'lumot
/// kelmaganda ekran `Center(child: CircularProgressIndicator())` bo'lib
/// qoladi, tortadigan narsa yo'q, odam esa AYNAN o'shanda tortadi.
/// Test o'sha holatni ko'rib turib jimgina o'tkazib yuborardi.
///
/// O'lchov (o'sha kuni, tarmoqsiz holatda): o'n bitta ma'lumot ekranida
/// tortib-yangilash YO'Q edi — profil, safarlarim, mashinalar, daromad,
/// tariflar, posilkalarim, pochta, begona profil, qidiruv va boshqalar.
///
/// Endi qochiriq yo'q: FORMA bo'lmagan har bir ekranda `RefreshIndicator`
/// BO'LISHI SHART — u tarmoqsiz, ya'ni yuklanish/xato holatida ochiladi.
///
/// 🔑 IKKINCHI SHART — HARAKAT ISHLASIN: vidjetning turgani yetmaydi,
/// barmoq tortilganda indikator KO'RINISHI kerak. Shuning uchun test
/// haqiqiy sudrash qiladi va aylanma paydo bo'lganini tekshiradi.
///
/// FORMALAR ro'yxatdan chiqarilgan: forma yangilanmaydi, u to'ldiriladi.
/// Tortish kiritilgan ma'lumotni yo'qotish xavfini tug'diradi va
/// «yangilash» so'zining ma'nosi ham yo'q.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Yangilanmaydigan ekranlar — ular FORMA yoki bir martalik oqim.
  const forms = {
    'intro',
    'phone',
    'otp',
    'create_ride',
    'create_parcel',
    'complete_profile',
    'edit_profile',
    'driver_verification',
    'add_car_sheet',
    'password_sheet',
    'support_sheet',
    'sos_sheet',
  };

  for (final entry in auditScreens().entries) {
    if (forms.contains(entry.key)) continue;

    testWidgets('${entry.key}: tarmoqsiz holatda ham tortib bo\'ladi', (
      tester,
    ) async {
      await pumpAuditScreen(tester, entry.value);

      expect(
        find.byType(RefreshIndicator),
        findsWidgets,
        reason:
            '${entry.key}: ma\'lumot kelmagan holatda tortib-yangilash '
            'YO\'Q. Odam aynan shunda tortadi — `YolRefreshable` yoki '
            '`refreshableState` ni ishlating.',
      );

      /*
       * HARAKATNING O'ZI: tepadan pastga sudraymiz va aylanma
       * chiqishini kutamiz. Vidjet turgani bilan tortish ishlamasligi
       * mumkin — masalan mazmun surilmasa yoki tortish boshqa vidjetga
       * tushib ketsa.
       *
       * ⚠️ TORTISH HAQIQIY SO'ROV YUBORADI va test muhitida u tabiiy
       * ravishda YIQILADI (server yo'q). Bu kutilgan holat: biz
       * tortishning ISHLAGANINI tekshiryapmiz, so'rov natijasini emas.
       * Shuning uchun tarmoq xatolari yutiladi — aks holda har bir
       * ekran «ApiException» bilan qizil bo'lardi.
       */
      /*
       * 🔴 TORTISH MAZMUN TURGAN JOYDAN BO'LSIN (18.09.2026).
       *
       * Ilgari bu yerda QAT'IY nuqta turardi: `Offset(180, 220)`. U
       * ekranning yuqori qismi — va bosh ekran xarita-birinchi
       * bo'lgach o'sha nuqta XARITAGA tushdi: barmoq xaritani surardi,
       * test esa «tortib-yangilash ishlamayapti» derdi. Ya'ni test
       * mahsulotni emas, o'zining koordinatasini o'lchayotgan edi.
       *
       * ⚠️ Bu YENGILLASHTIRISH EMAS: shart o'sha — barmoq tortilsa
       * aylanma CHIQSIN. Faqat barmoq endi `RefreshIndicator` ning
       * o'z maydonidan tortadi, ya'ni har ekranda TO'G'RI joydan.
       */
      final area = tester.getRect(find.byType(RefreshIndicator).first);
      await tester.dragFrom(
        Offset(area.center.dx, area.top + 40),
        const Offset(0, 300),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.byType(RefreshProgressIndicator),
        findsWidgets,
        reason:
            '${entry.key}: `RefreshIndicator` bor, lekin BARMOQ bilan '
            'tortilganda aylanma chiqmadi — demak tortish shu ekranda '
            'ishlamaydi.',
      );
      /*
       * ⚠️ TORTISH HAQIQIY SO'ROV YUBORADI va test muhitida u tabiiy
       * ravishda yiqiladi (server yo'q). Biz tortishning ISHLAGANINI
       * tekshiryapmiz, so'rov natijasini emas — shuning uchun kutilgan
       * xatolar shu yerda YIG'IB OLINADI.
       *
       * 🔴 `FlutterError.onError` ni ALMASHTIRIB BO'LMAYDI: xatoni
       * butunlay yutsak, test binding'i «onError o'zgartirilgan-u,
       * qaytarilmagan» deb assert tashlaydi. To'g'ri yo'l —
       * `takeException()` bilan navbatni bo'shatish.
       */
      await tester.pumpAndSettle(const Duration(seconds: 3));
      while (tester.takeException() != null) {}
      // So'rovning yiqilishi keyingi aylanishda kelishi mumkin —
      // navbatni ikkinchi marta bo'shatamiz.
      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}
    });
  }
}

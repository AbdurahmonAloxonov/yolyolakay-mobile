import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/core/drafts.dart';
import 'package:yolyolakay/features/profile/driver_verification_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// HAYDOVCHI TEKSHIRUVI paneli — qadamlar.
///
/// Nima uchun test bor: panelning butun ma'nosi QADAMLARDA (egasi
/// 2026-08-21: "bitta pageda bo'lib qolmasin"). Agar kimdir keyinchalik
/// hujjatlarni bitta ekranga yig'ib qo'ysa yoki hujjatsiz oldinga
/// o'tkazsa — bu testlar shuni ushlaydi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const t = AppStrings(Lang.uz);

  Future<void> pump(
    WidgetTester tester, {
    Map<String, Object> prefs0 = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs0);
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: DriverVerificationScreen(),
        ),
      ),
    );
    await tester.pump();
    // `initState` qoralamani post-frame'da o'qiydi.
    await tester.pump();
  }

  testWidgets('birinchi qadamdan boshlanadi va nechtaligi ko\'rinadi', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(t.stepOf(1, 6)), findsOneWidget);
  });

  testWidgets('HUJJATSIZ oldinga o\'tkazmaydi', (tester) async {
    await pump(tester);
    // "Keyingisi" bor, lekin BOSILMAYDI: hujjatsiz ariza baribir rad
    // etiladi, ya'ni oldinga o'tkazish faqat vaqtni oldiradi.
    final next = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, t.next),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('birinchi qadamda ORQAGA tugmasi YO\'Q', (tester) async {
    await pump(tester);
    expect(find.widgetWithText(TextButton, t.back), findsNothing);
  });

  /// Birinchi qadam endi odamning O'Z surati (egasi, 2026-08-28) —
  /// pasport/ID karta tanlovi butunlay olib tashlandi.
  testWidgets('birinchi qadam — odamning surati', (tester) async {
    await pump(tester);
    expect(find.text(t.docSelfieTitle), findsOneWidget);
    // Eski tanlov qaytib kelmasin.
    expect(find.text(t.docPassport), findsNothing);
    expect(find.text(t.docIdCard), findsNothing);
  });

  testWidgets('surat olish QO\'LLANMASI ko\'rinadi', (tester) async {
    await pump(tester);
    // Qo'llanma yuklashdan OLDIN turishi kerak: rad etilgach o'qish kech.
    expect(find.text(t.docSelfieHints.first), findsOneWidget);
  });

  /// Galereya yo'qolgani odamga TUSHUNTIRILADI — aks holda u buni
  /// nosozlik deb o'ylaydi («tayyor suratim bor, nega qo'shib bo'lmayapti»).
  testWidgets('ayni paytda olinishi haqida eslatma bor', (tester) async {
    await pump(tester);
    expect(find.text(t.docLiveOnlyNote), findsOneWidget);
  });

  /// 🔴 HUJJATNING IKKI TOMONI (2026-08-27). Guvohnomaning ORQASIDA
  /// toifalar (B, C, D) yozilgan — odam yo'lovchi tashishga haqlimi
  /// yoki yo'qmi aynan o'sha tomonda ko'rinadi.
  ///
  /// ⚠️ Bu MATN shartnomasi testi, oqim testi EMAS: 1-qadamga o'tish
  /// uchun haqiqiy surat yuklash kerak (`ImagePicker` + tarmoq), buni
  /// widget testida qo'zg'atib bo'lmaydi. Shuning uchun bu yerda
  /// nusxa-ko'chirish xatosi ushlanadi — old va orqa tomon matnlari
  /// ADASHTIRIB YUBORILMAGANI.
  test('old va orqa tomon matnlari BIR XIL EMAS', () {
    expect(t.docFrontSide, isNot(t.docBackSide));
    expect(t.docLicenseBackTitle, isNot(t.docLicenseTitle));
    expect(t.docTechPassportBackTitle, isNot(t.docTechPassportTitle));
    // Qo'llanmalar ham boshqacha: orqa tomonda BOSHQA narsa ko'rinishi
    // kerak (toifalar / egalik yozuvlari), ya'ni old tomonning
    // qo'llanmasini ko'chirish — xato.
    expect(t.docLicenseBackHints, isNot(t.docLicenseHints));
    expect(t.docTechPassportBackHints, isNot(t.docTechPassportHints));
  });

  /// Mashina UCH rakursda — yo'lovchi taniy olishi va moderatsiya davlat
  /// raqamini texpasport bilan solishtira olishi uchun. Chap/o'ng
  /// ajratish KERAK EMAS (egasi, 2026-08-28) — bitta yon tomon yetadi.
  test('mashina uchta rakursi bir-biridan farq qiladi', () {
    final titles = {t.docCarFrontTitle, t.docCarBackTitle, t.docCarSideTitle};
    expect(titles.length, 3, reason: 'sarlavhalar takrorlanmasin');

    final hints = [t.docCarFrontHints, t.docCarBackHints, t.docCarSideHints];
    for (final h in hints) {
      expect(h.length, greaterThanOrEqualTo(3));
    }
    expect(hints[0], isNot(hints[1]));
    expect(hints[1], isNot(hints[2]));
  });

  /// 🔴 PASPORT VA ID KARTA OLIB TASHLANDI (egasi, 2026-08-28): ular
  /// backendga hech qachon yetib bormagan (maydonning o'zi yo'q edi) —
  /// ya'ni odamdan hech qayerga bormaydigan hujjat so'ralardi.
  ///
  /// Test qayta paydo bo'lishidan qo'riqlaydi: bunday qadam jimgina
  /// qaytib qolsa, uni faqat foydalanuvchi shikoyati bilan bilardik.
  test('shaxs hujjati oqimda YO\'Q, o\'rnida odamning surati', () {
    final src = File(
      'lib/features/profile/driver_verification_screen.dart',
    ).readAsStringSync();

    for (final gone in ['IdentityType', 'docPassportTitle', 'docIdCardTitle']) {
      expect(
        src.contains(gone),
        isFalse,
        reason: '`\$gone` tekshiruv oqimiga qaytib kelgan',
      );
    }
    expect(src.contains('docSelfieTitle'), isTrue);
  });

  /// 🔴 TEKSHIRUV SURATLARI AYNI PAYTDA OLINADI. Galereya ochiq qolsa,
  /// odam internetdan olingan yoki boshqa odamning hujjatini yuklashi
  /// mumkin va moderatsiya buni surat sifatidan ajrata olmaydi.
  ///
  /// Bu bog'lanish KO'RINMAYDI: `liveOnly` yozilmagan `DocumentUpload`
  /// jimgina galereyani ochadi va hech qanday xato chiqmaydi.
  test('tekshiruvdagi HAR bir surat `liveOnly` bilan olinadi', () {
    for (final path in const [
      'lib/features/profile/driver_verification_screen.dart',
      'lib/features/profile/add_car_sheet.dart',
    ]) {
      final src = File(path).readAsStringSync();
      final uploads = 'DocumentUpload('.allMatches(src).length;
      final live = 'liveOnly: true'.allMatches(src).length;
      expect(
        live,
        uploads,
        reason:
            '\$path: \$uploads ta `DocumentUpload`, lekin \$live tasida '
            '`liveOnly` bor — qolganlari galereyani ochadi',
      );
    }
  });

  /// Uchala tilda ham to'ldirilgan bo'lsin — `uz` yozib, `ru`/`en` ni
  /// unutish bu loyihada bir necha marta bo'lgan (2026-08-16: English
  /// ruscha matn ko'rsatardi).
  test('yangi matnlar UCHALA tilda ham bor', () {
    for (final lang in Lang.values) {
      final s = AppStrings(lang);
      expect(s.docCarPhotos, isNotEmpty, reason: '$lang docCarPhotos');
      expect(s.docLicenseBackTitle, isNotEmpty, reason: '$lang licenseBack');
      expect(s.docTechPassportBackHints, isNotEmpty, reason: '$lang techBack');
      for (final h in [
        s.docCarFrontHints,
        s.docCarBackHints,
        s.docCarSideHints,
        s.docLicenseBackHints,
        s.docTechPassportBackHints,
      ]) {
        expect(h.every((e) => e.trim().isNotEmpty), isTrue, reason: '$lang');
      }
    }
  });

  /// 🔴 QORALAMA. Oqim sakkizta suratga o'sgach, uni bir o'tirishda
  /// tugatish har doim ham iloji bo'lmay qoldi. Agar kimdir keyinchalik
  /// saqlashni buzsa, odam telefon jiringlagani uchun hamma suratini
  /// qaytadan yuklashga majbur bo'ladi — shu test o'shani ushlaydi.
  testWidgets('saqlangan qoralama TIKLANADI', (tester) async {
    await pump(
      tester,
      prefs0: {
        'draft_${Drafts.driverVerification}': jsonEncode({
          'step': 4,
          'identity': 'https://x/id.jpg',
          'license_front': 'https://x/lf.jpg',
          'license_back': 'https://x/lb.jpg',
          'tech_front': 'https://x/tf.jpg',
          'tech_back': 'https://x/tb.jpg',
          'car_front': 'https://x/cf.jpg',
          'car_back': 'https://x/cb.jpg',
          'brand': 'Chevrolet',
          'model': 'Cobalt',
          'gov_number': '01A777AA',
        }),
      },
    );

    // Qadam tiklandi — 5-qadam (0 dan sanaganda 4).
    expect(find.text(t.stepOf(5, 6)), findsOneWidget);
    // Matn maydonlari ham tiklandi.
    expect(find.text('Chevrolet'), findsOneWidget);
    expect(find.text('01A777AA'), findsOneWidget);
  });

  /// Qadam raqami qoralamadan KO'R-KO'RONA olinmaydi: eski versiyadan
  /// qolgan qoralamada mavjud bo'lmagan qadam raqami bo'lishi mumkin.
  testWidgets('qoralamadagi NOTO\'G\'RI qadam e\'tiborsiz qoldiriladi', (
    tester,
  ) async {
    await pump(
      tester,
      prefs0: {
        'draft_${Drafts.driverVerification}': jsonEncode({
          'step': 99,
          'brand': 'Chevrolet',
        }),
      },
    );
    // 99-qadam yo'q — birinchisida qolamiz.
    expect(find.text(t.stepOf(1, 6)), findsOneWidget);
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/core/drafts.dart';
import 'package:yolyolakay/features/profile/add_car_sheet.dart';
import 'package:yolyolakay/features/profile/driver_verification_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// ASOSIY TUGMA DOIM KO'RINIB TURSIN.
///
/// 🔴 NEGA TEST (egasi IKKI MARTA aytdi — 2026-08-27 va 28): «keyingisi
/// tugmasi yo'q». Ikkala safar ham tugma BOR edi, lekin:
///   • `driver_verification_screen` da — o'chiq va SABABSIZ;
///   • `add_car_sheet` da — suriladigan formaning ICHIDA, uchta surat
///     ramkasidan KEYIN, ya'ni telefonda unga yetib borish uchun uzoq
///     surish kerak edi.
///
/// 🔴 UCHINCHI MARTA (2026-08-30): «rasm joylangandan keyin keyingisi
/// tugmasi yo'q — hech kim haydovchi bo'lolmaydi». Bu safar tugma
/// o'chiq ham emas, suriladigan qismda ham emas edi — u ekranning
/// O'NG CHEKKASIDAN TASHQARIDA chizilardi:
///
///   • oxirgi qadamda `Row([Orqaga, Spacer, «Ko'rib chiqishga
///     yuborish»])` 360 px ekranda 111 piksel toshardi — asosiy tugma
///     94 piksel ekrandan tashqarida qolardi;
///   • surat yuklangach chiqadigan «Almashtirish / O'chirish» qatori
///     133 piksel (320 px ekranda 173) toshardi.
///
/// 🔑 NEGA OLDINGI TESTLAR TUTMADI: ular BO'SH forma bilan ishlardi.
/// Toshish esa faqat SURAT YUKLANGANDAN KEYIN paydo bo'ladi —
/// «Almashtirish/O'chirish» qatori shunda chiziladi. Endi testlar
/// to'ldirilgan qoralama bilan ishlaydi.
///
/// 🔑 Va ular tugmaning BOR-YO'QLIGINI tekshirardi, JOYINI emas.
/// `find.text` ekrandan chiqib ketgan vidjetni ham TOPADI. Endi
/// tugmaning to'rtburchagi ekran ichida yotishi ham tekshiriladi.
void main() {
  const t = AppStrings(Lang.uz);

  Future<void> pumpSheet(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: AddCarSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mashina varag\'ida saqlash tugmasi KO\'RINADI', (tester) async {
    await pumpSheet(tester);
    expect(find.text(t.save), findsOneWidget);
  });

  /// 🔴 ENG MUHIMI: tugma suriladigan qismning ICHIDA turmasin. Aks
  /// holda surat ramkalari uni pastga surib yuboradi va odam uni
  /// umuman ko'rmaydi — aynan shu bo'lgan.
  testWidgets('tugma suriladigan forma ICHIDA emas', (tester) async {
    await pumpSheet(tester);
    final scroller = find.byType(SingleChildScrollView);
    expect(scroller, findsWidgets);
    expect(
      find.descendant(of: scroller.first, matching: find.text(t.save)),
      findsNothing,
      reason: 'tugma surilganda yo\'qolib ketmasin',
    );
  });

  /// Tugma o'chiq bo'lsa NEGA ekani yozilsin — bo'sh forma bilan
  /// ochilganda odam nima kiritish kerakligini bilishi kerak.
  testWidgets('tugma o\'chiq bo\'lsa sababi yozilgan', (tester) async {
    await pumpSheet(tester);
    final btn = tester.widget<FilledButton>(
      find.ancestor(of: find.text(t.save), matching: find.byType(FilledButton)),
    );
    expect(btn.onPressed, isNull, reason: 'forma bo\'sh — o\'chiq bo\'lsin');
    expect(find.text(t.carNeedBasics), findsOneWidget);
  });

  testWidgets('tor ekranda ham qator toshmaydi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: AddCarSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(t.save), findsOneWidget);
  });

  // ══════════════════════════════════════════════════════════════
  // HAYDOVCHI TEKSHIRUVI — hamma qadam, hamma til, tor ekranlar
  // ══════════════════════════════════════════════════════════════

  /// Hamma surat yuklangan qoralama: toshish AYNAN shu holatda
  /// paydo bo'ladi (bo'sh formada «Almashtirish/O'chirish» qatori
  /// umuman chizilmaydi).
  String filledDraft(int step) => jsonEncode({
    'step': step,
    'selfie': 'https://x/s.jpg',
    'license_front': 'https://x/lf.jpg',
    'license_back': 'https://x/lb.jpg',
    'tech_front': 'https://x/tf.jpg',
    'tech_back': 'https://x/tb.jpg',
    'car_front': 'https://x/cf.jpg',
    'car_back': 'https://x/cb.jpg',
    'car_side': 'https://x/cs.jpg',
    'brand': 'Chevrolet',
    'model': 'Cobalt',
    'gov_number': '01A777AA',
  });

  Future<void> pumpVerification(
    WidgetTester tester, {
    required Size size,
    required Lang lang,
    required int step,
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues({
      'draft_${Drafts.driverVerification}': filledDraft(step),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          // ⚠️ `Locale(lang.name)` EMAS: u kirill uchun `uzCyrl` beradi
          // va ilova uni tanimay lotinga tushib qolardi — sinov esa
          // kirill matnini kutardi. `LocaleController` bilan bir xil
          // yo'l: kod → Locale.
          locale: LocaleController.localeOf(langCode(lang)),
          supportedLocales: const [
            Locale('uz'),
            Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
            Locale('ru'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // ⚠️ MediaQuery'ni BUTUNLAY almashtirib bo'lmaydi — u bilan
          // birga ekran o'lchami ham yo'qoladi va test yolg'on «o'tdi»
          // beradi. Shuning uchun mavjudi `copyWith` bilan o'zgartiriladi.
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: const DriverVerificationScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Qoralama post-frame'da o'qiladi.
    await tester.pump();
  }

  /// 🔴 TO'RTINCHI MARTA QAYTMASLIGI UCHUN — TO'LIQ MATRITSA
  /// (2026-09-02, egasi: «hamma telefonlarni o'ylab qilish kerak,
  /// ko'rinmay qolgandir»).
  ///
  /// Oldingi tekshiruv 3 o'lcham × 3 til × 6 qadam edi va UCHTA teshigi
  /// bor edi — uchalasi ham tugmani ko'rinmas qiladi:
  ///
  ///   • KATTA MATN sinalmasdi. Ilova matnni 1.3 gacha kattalashtirishga
  ///     ruxsat beradi (`textScaler.clamp(1.0, 1.3)`), tugma yozuvi esa
  ///     aynan shunda uzayadi — «Ko'rib chiqishga yuborish» 1.3 da
  ///     oddiy holatdagidan ~30% kengroq.
  ///
  ///   • faqat GORIZONTAL chegara tekshirilardi. Pastdan chiqib ketgan
  ///     tugma ham xuddi o'ngdan chiqqani kabi ko'rinmaydi — kalta
  ///     ekranda (320×568) qadam sarlavhasi, xato yozuvi va tugma
  ///     birgalikda balandlikka sig'masligi mumkin.
  ///
  ///   • tugma ustini boshqa vidjet TO'SIB qo'ygan holat umuman
  ///     tekshirilmasdi: `getRect` uni joyida deb ko'rsatadi, barmoq
  ///     esa yetib bormaydi. Endi markazidan hit-test qilinadi.
  ///
  /// 6 o'lcham × 3 til × 2 matn kattaligi × 6 qadam = 216 holat.
  const sizes = <Size>[
    Size(320, 568), // eng tor VA eng kalta hali tirik Android
    Size(320, 640),
    Size(360, 640), // eng ko'p tarqalgani
    Size(360, 780),
    Size(390, 844), // iPhone 14
    Size(412, 915), // Pixel 7
  ];

  for (final size in sizes) {
    for (final lang in Lang.values) {
      for (final scale in const [1.0, 1.3]) {
        for (var step = 0; step < 6; step++) {
          testWidgets(
            'tekshiruv: ${size.width.toInt()}×${size.height.toInt()} · '
            '${lang.name} · matn ${scale}x · $step-qadam — '
            'asosiy tugma KO\'RINADI va BOSILADI',
            (tester) async {
              await pumpVerification(
                tester,
                size: size,
                lang: lang,
                step: step,
                textScale: scale,
              );
              final s = AppStrings(lang);
              final label = step < 5 ? s.next : s.sendForReview;
              final button = find.widgetWithText(FilledButton, label);

              expect(button, findsOneWidget, reason: 'tugma umuman yo\'q');

              // Qoralama to'liq — tugma BOSILADIGAN bo'lishi kerak.
              expect(
                tester.widget<FilledButton>(button).onPressed,
                isNotNull,
                reason: 'hamma surat bor, lekin tugma o\'chiq',
              );

              // 🔴 ENG MUHIMI: tugma EKRAN ICHIDA yotsin. `find.text`
              // ekrandan chiqib ketgan vidjetni ham topadi — aynan shu
              // sabab oldingi testlar xatoni ko'rmagan.
              final rect = tester.getRect(button);
              expect(
                rect.left >= 0 && rect.right <= size.width,
                isTrue,
                reason:
                    'tugma yon chekkadan chiqqan: $rect, ekran eni '
                    '${size.width}',
              );
              expect(
                rect.top >= 0 && rect.bottom <= size.height,
                isTrue,
                reason:
                    'tugma pastdan/tepadan chiqqan: $rect, ekran '
                    'balandligi ${size.height}',
              );

              // 🔴 BARMOQ YETADIMI: joyida turgan tugmani ham boshqa
              // vidjet to'sib qo'yishi mumkin (varaq, banner, klaviatura
              // oldi paneli). `getRect` buni KO'RMAYDI.
              final target = tester.renderObject(button);
              final hit = tester.hitTestOnBinding(tester.getCenter(button));
              expect(
                hit.path.any((entry) => entry.target == target),
                isTrue,
                reason: 'tugma joyida, lekin ustini boshqa vidjet to\'sgan',
              );

              // Toshish (`RenderFlex overflowed`) ham xato sifatida
              // chiqadi — uni jimgina yutib yubormaymiz.
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // QOROVUL: asosiy amal paneli QO'LDA yozilmasin
  // ══════════════════════════════════════════════════════════════

  /// 🔴 NEGA MANBANI O'QIYMIZ: «keyingisi tugmasi yo'q» to'rt marta
  /// qaytdi va har safar BOSHQA ekranda edi. Vidjet testi faqat o'zi
  /// bilgan ekranni tekshiradi — yangi ekran yozilsa, u testsiz qoladi
  /// va xato beshinchi marta qaytadi.
  ///
  /// Shuning uchun qoida MANBADA tekshiriladi: suriladigan formaning
  /// tagida qotib turadigan asosiy amal `BottomActionBar` orqali
  /// beriladi. Panel ichida zamin, tepa chizig'i va `SafeArea` bir
  /// joyda — ularni har ekranda qaytadan yozish kerak emas va
  /// unutib qo'yish ham mumkin emas.
  test('asosiy amal ekranlari BottomActionBar ishlatadi', () {
    const screens = <String>[
      'lib/features/profile/driver_verification_screen.dart',
      'lib/features/rides/create_ride_screen.dart',
      'lib/features/parcels/create_parcel_screen.dart',
      'lib/features/rides/driver_ride_screen.dart',
      'lib/features/rides/ride_details_screen.dart',
      // 22.09.2026 da qo'shildi: ekran IKKI QADAMGA bo'lindi (rol, keyin
      // ism) va tugma ilgari ro'yxat OXIRIDA turardi — katta matnli tor
      // telefonda u oxirgi maydonga yopishib qolardi.
      'lib/features/profile/complete_profile_screen.dart',
    ];
    for (final path in screens) {
      final src = File(path).readAsStringSync();
      expect(
        src.contains('BottomActionBar('),
        isTrue,
        reason:
            '$path — pastdagi asosiy amal `BottomActionBar` ichida '
            'bo\'lsin, aks holda u ro\'yxatga yopishib qoladi',
      );
    }
  });

  /// Panelning o'zi: KO'RINADIGAN AJRATGICH bor, soya YO'Q.
  ///
  /// ⚠️ Qorong'i temada soya chizilmaydi (loyiha qoidasi). Kimdir
  /// ajratgich o'rniga `BoxShadow` qo'ysa, panel tungi rejimda
  /// ro'yxatdan umuman ajralmay qoladi — ya'ni xato jimgina qaytadi.
  ///
  /// 2026-09-03 dan ajratgich — ATLAS IPI (`AtlasEdge`): sarlavha
  /// panellari ostidagi ip bilan bir oila. Chegara chizig'i ham
  /// qabul qilinadi, muhimi — ko'rinadigan ajratgich BO'LSIN.
  test('panelda ajratgich bor, soya yo\'q', () {
    final src = File(
      'lib/features/shared/bottom_action_bar.dart',
    ).readAsStringSync();
    expect(
      src.contains('AtlasEdge(') || src.contains('BorderSide('),
      isTrue,
      reason: 'panelni mazmundan ajratadigan chiziq yo\'q',
    );
    expect(
      src.contains('BoxShadow'),
      isFalse,
      reason: 'soya emas, chiziq ishlatilsin',
    );
  });
}

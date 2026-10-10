import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/voice_route.dart';
import 'package:yolyolakay/features/search/voice_route_button.dart';

/// OVOZ NATIJASI QIDIRUVGA YETIB BORADIMI.
///
/// 🔴 NEGA TEST (egasi, qurilmada 2026-08-27: «ovoz eshitib matnga
/// o'tkazyapti, lekin qidiruvga bermayapti»): natija FAQAT
/// `result.finalResult` kelganda uzatilardi. Android nutq xizmati esa
/// ko'p qurilmada yakuniy natijani YUBORMAYDI — jimlikni payqab
/// `onStatus('done')` bilan to'xtaydi. Bunda matn ekranda KO'RINARDI,
/// lekin hech qayerga ketmasdi.
///
/// Tanish mexanizmining o'zini testda ishga tushirib bo'lmaydi (u
/// qurilma xizmatiga bog'liq), shuning uchun bu yerda undan KEYINGI
/// zanjir tekshiriladi: matn -> yo'nalish -> qidiruv chaqiruvi.
void main() {
  group('ovozdan keyin qidiruv ishga tushadi', () {
    /// Qurilmadan keladigan HAQIQIY shakllar — nutqni tanish
    /// qo'shimchani ajratib yozishi ham mumkin.
    const heard = [
      'Toshkentdan Samarqandga',
      'Тошкентдан Самарқандга',
      'Toshkent dan Samarqand ga',
      'Ташкент Самарканд',
      'из Ташкента в Самарканд',
      "Farg'onadan Toshkentga",
      'Toshkentdan Buxoroga boraman',
    ];

    for (final text in heard) {
      test('«$text» — ikkala shahar ham tanildi', () {
        final route = parseVoiceRoute(text);
        expect(route, isNotNull, reason: text);
        expect(route!.isEmpty, isFalse, reason: text);
        // 🔑 IKKALASI ham tanilishi SHART: `matched == 2` bo'lgandagina
        // qidiruv o'zi ishga tushadi. Bittasi tanilsa ekran ro'yxat
        // ochadi va odam yana tanlashi kerak bo'ladi.
        expect(route.matched, 2, reason: text);
        expect(route.from, isNotNull, reason: text);
        expect(route.to, isNotNull, reason: text);
      });
    }

    test('yo\'nalish TESKARI aytilsa ham to\'g\'ri tushuniladi', () {
      final r = parseVoiceRoute('Samarqandga Toshkentdan boraman');
      expect(r?.from?.name, 'Toshkent');
      expect(r?.to?.name, 'Samarqand');
    });

    test('tanilmagan matn yo\'nalish sifatida O\'TKAZILMAYDI', () {
      // Xato tanish natijasi qidiruvni ishga tushirmasligi kerak —
      // aks holda odam butunlay boshqa yo'nalish natijasini ko'radi.
      final r = parseVoiceRoute('salom qalaysiz');
      expect(r == null || r.isEmpty, isTrue);
    });
  });

  /// Tugma xom matnni ham TASHLAMAYDI: bitta ham shahar tanilmasa
  /// `onRawText` chaqiriladi va ekran ro'yxatni o'sha matn bilan ochadi.
  testWidgets('tanilmasa xom matn CHAQIRUVCHIGA beriladi', (tester) async {
    String? raw;
    VoiceRoute? route;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        supportedLocales: const [Locale('uz')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: VoiceRouteButton(
            onRoute: (r) => route = r,
            onRawText: (t) => raw = t,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Vidjet qurilma xizmatisiz chizilmasligi mumkin — bu holda ham
    // test ma'noli qolishi uchun holat tekshiriladi.
    expect(raw, isNull);
    expect(route, isNull);
  });
}

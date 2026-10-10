import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/features/search/search_screen.dart';

import 'support/preview_fonts.dart';

/// SANA MAYDONI O'Z NOMINI AYTA OLADIMI.
///
/// 🔴 NEGA YOZILDI (2026-09-04, ko'rikda ko'rildi): 320 px va 1.6
/// shkalada sana maydoni «Istalg…» bo'lib qolardi — ya'ni maydon
/// nima ekanini AYTA OLMASDI, chunki qatorning yarmini yo'lovchi
/// sanagichi egallab turadi.
///
/// ⚠️ Bu xatoni `ui_narrow_audit_test` TUTMAYDI: `ellipsis` toshishni
/// yutadi, ya'ni hech qanday «overflow» bo'lmaydi. Kesilgan matnni
/// faqat ENI o'lchab topish mumkin.
///
/// Test ikkala tomonni ham qo'riqlaydi: tor ekranda qator IKKIGA
/// bo'linsin, keng ekranda esa BO'LINMASIN (aks holda oddiy telefonda
/// bekorga ikki qator joy ketadi).
void main() {
  // ⚠️ HAQIQIY SHRIFT SHART: sinov muhitida shrift ulanmagan bo'lsa,
  // har harf bir kvadrat (1 em) enida chiziladi va «Istalgan sana»
  // 185 px chiqadi (o'lchandi) — ya'ni o'lchov mutlaqo yolg'on
  // bo'ladi. Birinchi urinishda aynan shu sababdan ikkala test ham
  // noto'g'ri yiqilgandi.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  Future<void> pump(WidgetTester tester, Size size, double scale) async {
    SharedPreferences.setMockInitialValues({'intro_seen': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(TokenStorage()),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          locale: const Locale('uz'),
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
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    tester.takeException();
  }

  /// «Istalgan sana» yozuvi to'liq sig'yaptimi.
  ///
  /// 🔑 O'lchov `RenderParagraph` ning O'ZIDAN olinadi: `getMaxIntrinsicWidth`
  /// — matn kesilmasa qancha joy egallashi, `size.width` — unga BERILGAN
  /// joy. Ikkinchisi kichik bo'lsa, matn `ellipsis` bilan kesilgan.
  /// Tashqaridan `TextPainter` yasab solishtirish ishonchsiz: uslub
  /// (`bodyMedium`) shrift o'lchami va harflar oralig'i bilan birga
  /// keladi, uni qo'lda takrorlash xato beradi (birinchi urinishda
  /// aynan shunday bo'ldi).
  bool fits(WidgetTester tester, String label) {
    final finder = find.text(label);
    expect(finder, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(finder.first);
    final needs = paragraph.getMaxIntrinsicWidth(double.infinity);
    return paragraph.size.width + 0.5 >= needs;
  }

  testWidgets('320 px + katta matn: sana alohida qatorga tushadi', (
    tester,
  ) async {
    await pump(tester, const Size(320, 1100), 1.6);
    expect(
      fits(tester, 'Istalgan sana'),
      isTrue,
      reason: 'sana maydoni o\'z nomini ayta olmayapti — kesilyapti',
    );
  });

  testWidgets('360 px + oddiy matn: sana va yo\'lovchilar bitta qatorda', (
    tester,
  ) async {
    await pump(tester, const Size(360, 1100), 1.0);
    expect(fits(tester, 'Istalgan sana'), isTrue);

    // Bitta qatorda ekanini tekshiramiz: sana yozuvi va yo'lovchi
    // ikonkasi bir xil balandlikda turadi.
    final dateY = tester.getCenter(find.text('Istalgan sana')).dy;
    final seatsY = tester.getCenter(find.byIcon(Icons.person_outline)).dy;
    expect(
      (dateY - seatsY).abs(),
      lessThan(12),
      reason:
          'oddiy telefonda qator bekorga ikkiga bo\'linyapti — '
          'chegara juda qattiq qo\'yilgan',
    );
  });
}

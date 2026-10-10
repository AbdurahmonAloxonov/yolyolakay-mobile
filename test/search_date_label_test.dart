import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/core/format.dart';
import 'package:yolyolakay/features/search/search_results_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// NATIJALAR SARLAVHASIDAGI SANA QATORI O'QILADIMI — TO'RT TILDA.
///
/// 🔴 NEGA YOZILDI (10.09.2026): bu qator sana va natija sonini birga
/// ko'taradi («12 sentabr · 5 ta safar topildi») va o'lchov ko'rsatdiki,
/// 320 px ekranda matn shkalasi 1.3 bo'lganda u sarlavha uyasiga
/// SIG'MASDI — `ellipsis` bilan KESILARDI. Ya'ni katta matn tanlagan
/// odam, aynan o'qishi qiyin bo'lgan odam, ma'lumotning yarmini
/// yo'qotardi va buni bilmasdi ham.
///
/// Qatorga «…dan boshlab» qo'shish urinishi ham shu test bilan
/// to'xtatildi: u qatorni 65% ga kichraytirib yuborardi (izohi
/// `_ResultsTitle` da).
///
/// `text_not_cut_test` buni TUTMAYDI: u ekranni qidiruv PARAMETRLARISIZ
/// ochadi, o'shanda sarlavha umumiy «Natijalar» ga tushadi va sana
/// qatori umuman chizilmaydi.
///
/// Qator endi KESILMAYDI: u `FittedBox(scaleDown)` ichida va sig'masa
/// kichrayadi (izohi `_ResultsTitle` da). Ya'ni savol «sig'adimi» emas,
/// «QANCHALIK KICHRAYADI» — juda kichrayса o'qib bo'lmaydi va bu
/// kesishdan yaxshi bo'lmay qoladi.
///
/// Usul: ekranni haqiqiy o'lchamda chizib, sarlavha uyasiga BERILGAN
/// enni olamiz (`FittedBox` ning `constraints.maxWidth` i — uning O'Z
/// eni bolasiga teng bo'lgani uchun yaramaydi), keyin eng uzun qator
/// haqiqiy uslubda qancha en talab qilishini o'lchab, nisbatni
/// hisoblaymiz.
///
/// ⚠️ Shrift SHART: `flutter_test_config.dart` Inter'ni yuklaydi.
/// Shriftsiz har harf 1 em bo'lib o'lchanadi va natija YOLG'ON chiqadi
/// (bu test yozilayotganda aynan shu tuzoqqa tushildi — va u orqali
/// temadagi shrift umuman qo'llanmayotgani topildi, `theme_font_test`).
void main() {
  for (final (size, scale) in [
    (const Size(320, 900), 1.0),
    (const Size(320, 900), 1.3),
    (const Size(360, 900), 1.0),
  ]) {
    testWidgets('sana qatori sig\'adi · ${size.width.toInt()} px · x$scale', (
      tester,
    ) async {
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
            debugShowCheckedModeBanner: false,
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
            home: const SearchResultsScreen(),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      // Tarmoq yo'qligi tabiiy — test muhitida server yo'q.
      tester.takeException();

      // `AppBar` sarlavha uyasi — `ScreenTitle` ichidagi `FittedBox`.
      // Uning eni = sarlavhaga ajratilgan en (orqaga tugmasi va o'ng
      // tomondagi amallar allaqachon ayrilgan).
      RenderBox? slot;
      void walk(RenderObject o) {
        if (slot == null && o.runtimeType.toString() == 'RenderFittedBox') {
          slot = o as RenderBox;
        }
        o.visitChildren(walk);
      }

      walk(tester.binding.rootElement!.renderObject!);
      expect(
        slot,
        isNotNull,
        reason:
            'Sarlavha uyasi (`ScreenTitle` ichidagi `FittedBox`) topilmadi — '
            'ekran o\'zgargan bo\'lsa bu testni ham yangilang.',
      );

      // ⚠️ `size.width` EMAS, `constraints.maxWidth`: `FittedBox` o'z
      // BOLASINING eniga teng bo'ladi (kerak bo'lsa kichraytirib), ya'ni
      // uning `size` i qisqa sarlavhada uyadan kichik chiqadi. Uyaning
      // haqiqiy eni — unga BERILGAN cheklov.
      final available = slot!.constraints.maxWidth;
      final style = buildTheme(brightness: Brightness.light).textTheme.labelSmall;

      // O'LCHOV USULINI TEKSHIRISH: shrift haqiqatan yuklanganmi.
      // Yuklanmasa har harf 1 em bo'lib o'lchanadi va natija yolg'on
      // chiqadi — shuning uchun bir harf enini nazorat qilamiz.
      final probe = TextPainter(
        text: TextSpan(text: 'i', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(
        probe.width,
        lessThan((style?.fontSize ?? 11) * 0.6),
        reason:
            'Shrift yuklanmagan ko\'rinadi ("i" harfi juda keng chiqdi) — '
            'bunday o\'lchovdan xulosa chiqarib bo\'lmaydi.',
      );

      // Chegara: qator eng ko'pi bilan 30% ga kichraysin. Bugungi eng
      // yomon holat (uz, kelasi yil sanasi, 320 px, x1.3) bundan
      // yuqorida turadi — qatorga yangi ma'lumot qo'shilsa test
      // yiqiladi. Aynan shunday to'xtatildi: «…dan boshlab» qo'shilganda
      // nisbat 65% ga tushgan edi.
      const minReadable = 0.70;

      final tight = <String>[];
      for (final lang in Lang.values) {
        final t = AppStrings(lang);
        // Eng uzun holat: kelasi yil sanasi (`formatDate` yilni ham
        // qo'shadi) + natija soni.
        final worst = [
          formatDate(DateTime(DateTime.now().year + 1, 9, 12), lang),
          t.ridesFound(5),
        ].join(' · ');
        final painter = TextPainter(
          text: TextSpan(text: worst, style: style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(scale),
        )..layout();
        final factor = painter.width <= available
            ? 1.0
            : available / painter.width;
        if (factor < minReadable) {
          tight.add(
            '${lang.name}: "$worst" — ${available.toStringAsFixed(0)} px '
            'berilgan, ${painter.width.toStringAsFixed(0)} px kerak, '
            'ya\'ni ${(factor * 100).toStringAsFixed(0)}% ga kichrayadi',
          );
        }
      }

      expect(
        tight,
        isEmpty,
        reason:
            'Sarlavha ostidagi sana qatori o\'qib bo\'lmaydigan darajada '
            'kichrayadi. Qatorga yangi ma\'lumot qo\'shilgan bo\'lsa — uni '
            'shu yerdan emas, ro\'yxat ustidagi kontekst qatoridan bering.',
      );
    });
  }
}

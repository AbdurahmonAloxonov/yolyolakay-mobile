import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/support/faq.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// SAVOL-JAVOB.
///
/// 🔴 NEGA TEST: javoblar foydalanuvchiga MA'LUMOT beradi va ular
/// eskirishi mumkin. Eng xavflisi — hozir MUMKIN BO'LMAGAN narsani
/// va'da qilish. Bekor qilish endpointi backendda YO'Q (xat §1), va
/// javob buni ochiq aytishi kerak; «bekor qiling» deb yozib qo'yish
/// odamni yo'q tugmani qidirishga majbur qilardi.
void main() {
  Widget boot(Lang lang) => MaterialApp(
    locale: LocaleController.localeOf(langCode(lang)),
    supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const Scaffold(body: SingleChildScrollView(child: FaqList())),
  );

  testWidgets('savollar ro\'yxati chiziladi', (tester) async {
    await tester.pumpWidget(boot(Lang.uz));
    await tester.pumpAndSettle();

    const t = AppStrings(Lang.uz);
    expect(find.text(t.faqItems.first.$1), findsOneWidget);
    expect(find.byType(ExpansionTile), findsWidgets);
  });

  testWidgets('qidiruv filtrlaydi', (tester) async {
    await tester.pumpWidget(boot(Lang.uz));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bekor');
    await tester.pumpAndSettle();

    // Faqat bekor qilish haqidagi savol qolsin.
    expect(find.byType(ExpansionTile), findsOneWidget);
  });

  testWidgets('topilmasa boshi berk bo\'lmaydi', (tester) async {
    await tester.pumpWidget(boot(Lang.uz));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'qwertyuiop');
    await tester.pumpAndSettle();

    const t = AppStrings(Lang.uz);
    // «Pastda bizga yozing» — murojaat formasiga ishora.
    expect(find.text(t.faqNothingFound), findsOneWidget);
  });

  /// Uchala tilda ham savol soni bir xil bo'lishi kerak: bittasi
  /// tushib qolsa, o'sha tildagi odam javobni topa olmaydi va buni
  /// hech kim payqamaydi.
  test('hamma tilda savollar soni bir xil', () {
    const uz = AppStrings(Lang.uz);
    for (final lang in Lang.values) {
      expect(
        AppStrings(lang).faqItems,
        hasLength(uz.faqItems.length),
        reason: '$lang da savol tushib qolgan',
      );
    }
  });

  /// 🔴 Bekor qilish HOZIR ishlamaydi — javob buni ochiq aytishi shart.
  test('bekor qilish javobi VA\'DA bermaydi', () {
    for (final lang in Lang.values) {
      final items = AppStrings(lang).faqItems;
      // ⚠️ Kirill shakllari ham: «bekor» → «бекор», «yo'q» → «йўқ».
      // Ular avtomatik o'giriladi, ya'ni sinov ularni ham bilishi shart
      // (aks holda kirill tilida savol umuman topilmaydi).
      final cancel = items.firstWhere(
        (i) =>
            i.$1.toLowerCase().contains('bekor') ||
            i.$1.toLowerCase().contains('бекор') ||
            i.$1.toLowerCase().contains('отмен') ||
            i.$1.toLowerCase().contains('cancel'),
      );
      // Javobda «hozircha yo'q» ma'nosi bo'lishi kerak.
      final answer = cancel.$2.toLowerCase();
      expect(
        answer.contains("yo'q") ||
            answer.contains('йўқ') ||
            answer.contains('нет') ||
            answer.contains('no cancel'),
        isTrue,
        reason:
            '$lang: bekor qilish javobi hozirgi HAQIQATNI aytmayapti — '
            'endpoint backendda hali yo\'q',
      );
    }
  });
}

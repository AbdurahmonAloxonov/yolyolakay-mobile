import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/billing.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/billing/tariffs_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// TARIF TAFSILOTI VARAG'I — surish sog'ligini qulflaydi.
///
/// 🔴 NEGA YOZILDI (egasi, 2026-08-26: «tarif tafsiloti varag'ini ham
/// qara»): ro'yxatlardagi «qotish» `YolRefresh` fizikasidan edi
/// (`test/scroll_physics_test.dart`), lekin bu varaq undan TASHQARIDA —
/// u modal ichida, o'z fizikasi bilan. O'lchandi: varaqning o'zi sog'lom,
/// va shu holat shu yerda qotiriladi.
///
/// ⚠️ ENG QIMMAT SINOV — KATTA MATN. Arzon telefonda (360×640) tizim
/// shrifti 1.6 ga qo'yilsa varaq mazmuni 1187 px ga cho'ziladi, ya'ni
/// ekrandan ikki barobar uzun. Agar surish buzilsa, «Sotib olish»
/// tugmasi va oylik shart izohi umuman YETIB BO'LMAYDIGAN bo'lib qoladi —
/// va bu aynan pul to'laydigan ekran.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> boot(WidgetTester tester, {double textScale = 1.0}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Arzon Android telefon o'lchami.
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          meProvider.overrideWith(
            (ref) async => const MeResponse(
              user: User(
                id: 'u-1',
                phoneNumber: '+998900000000',
                firstName: 'Aziz',
                role: 'driver',
              ),
              cars: [],
            ),
          ),
          subscriptionProvider.overrideWith((ref) async => null),
          billingPlansProvider.overrideWith(
            (ref) async => const [
              BillingPlan(
                name: 'Pro',
                price: 60000,
                ridesQuota: 40,
                parcelsQuota: 5,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child!,
          ),
          home: const TariffsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Varaqni ochadi va uning surish holatini qaytaradi.
  Future<ScrollableState> openSheet(WidgetTester tester) async {
    const t = AppStrings(Lang.uz);
    await tester.ensureVisible(find.text(t.planDetails));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.planDetails));
    await tester.pumpAndSettle();

    final sheet = find.byType(SingleChildScrollView);
    expect(sheet, findsWidgets, reason: 'Varaq ochilmadi');
    return tester.state<ScrollableState>(
      find.descendant(of: sheet.first, matching: find.byType(Scrollable)).first,
    );
  }

  testWidgets('varaqda INERSIYA bor (fizikaning parenti joyida)', (
    tester,
  ) async {
    await boot(tester);
    final scroll = await openSheet(tester);
    final physics = scroll.position.physics;

    expect(
      physics.createBallisticSimulation(scroll.position, 1200),
      isNotNull,
      reason:
          'Ballistik simulyatsiya yo\'q — barmoq uzilgach varaq o\'lik '
          'to\'xtaydi. Odatda fizikaga parent berilmagani sabab bo\'ladi.',
    );
  });

  testWidgets('KATTA matn: eng pastki izoh ham o\'qiladi', (tester) async {
    await boot(tester, textScale: 1.6);
    const t = AppStrings(Lang.uz);
    await tester.ensureVisible(find.text(t.planDetails));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.planDetails));
    await tester.pumpAndSettle();

    final sheet = find.byType(SingleChildScrollView).first;
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: sheet, matching: find.byType(Scrollable)).first,
    );

    expect(
      scroll.position.maxScrollExtent,
      greaterThan(scroll.position.viewportDimension),
      reason: '1.6 da mazmun ekrandan uzun bo\'lishi kerak — sinov shunda '
          'ma\'noga ega',
    );

    await tester.drag(sheet, const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(
      scroll.position.pixels,
      moreOrLessEquals(scroll.position.maxScrollExtent, epsilon: 1),
      reason: 'Varaq oxirigacha surilmadi',
    );
    expect(
      find.text(t.planPeriodNote),
      findsOneWidget,
      reason: 'Eng pastki izoh yetib bo\'lmaydigan bo\'lib qoldi',
    );
  });

  /// 🔴 EGASI TOPGAN NOSOZLIK (2026-08-26): mazmuni suriladigan varaqni
  /// pastga surib yopib bo'lmasdi. O'lchov: 500 px surildi — varaq hali
  /// ochiq. Sabab Flutter imo-ishora maydonchasida (izohi
  /// `SheetDragToClose` da), va u odamga «qotish» bo'lib ko'rinardi:
  /// barmoq ostida HECH NIMA bo'lmaydi.
  testWidgets('tepada turib pastga surilsa varaq YOPILADI', (tester) async {
    await boot(tester);
    final scroll = await openSheet(tester);
    expect(
      scroll.position.pixels,
      0,
      reason: 'Sinov varaq TEPASIDAN boshlanishi kerak',
    );

    await tester.drag(find.byType(SingleChildScrollView).first,
        const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(
      find.byType(SingleChildScrollView),
      findsNothing,
      reason: 'Varaq yopilmadi — mazmunni surib yopish yana ishlamayapti',
    );
  });

  /// Yopilish FAQAT tepada bo'lishi kerak: o'rtada turib pastga surish —
  /// bu oddiy o'qish, varaq yopilmasligi shart.
  testWidgets('o\'rtada turib pastga surilsa varaq OCHIQ qoladi', (
    tester,
  ) async {
    await boot(tester);
    final scroll = await openSheet(tester);
    final sheet = find.byType(SingleChildScrollView).first;

    // Avval pastga tushamiz.
    await tester.drag(sheet, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));

    // Endi ozgina yuqoriga — bu oddiy o'qish, yopilish emas.
    await tester.drag(sheet, const Offset(0, 100));
    await tester.pumpAndSettle();

    expect(
      find.byType(SingleChildScrollView),
      findsWidgets,
      reason: 'O\'rtada surilganda varaq yopilib ketmasligi kerak',
    );
  });
}

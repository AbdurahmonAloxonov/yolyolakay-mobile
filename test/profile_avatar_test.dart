import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/billing.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/profile/profile_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// PROFIL SURATI — joylashuvi va bosilganda nima bo'lishi.
///
/// 🔴 Egasi (2026-08-28), ikkita alohida shikoyat:
///   1. «tomchi yoki nuqta kamerali telefonlarda noqulaylik bo'lyapti» —
///      surat ekranning eng tepasida turardi va kamera o'yig'i ostiga
///      tushib qolardi (`SafeArea(top: false)`).
///   2. «ustiga bossa boshqa rasm qo'yish chiqyapti» — o'z suratini
///      kattalashtirib ko'rishning iloji yo'q edi, holbuki BEGONA
///      profilda surat bosilsa to'liq ekranda ochiladi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const t = AppStrings(Lang.uz);

  /// Kamera o'yig'i baland telefonni taqlid qiladi.
  const notch = EdgeInsets.only(top: 60);

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester tester, {String? avatarUrl}) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          meProvider.overrideWith(
            (ref) async => MeResponse(
              user: User(
                id: 'u-1',
                phoneNumber: '+998900000000',
                firstName: 'Aziz',
                role: 'passenger',
                avatarUrl: avatarUrl,
              ),
              cars: const [],
            ),
          ),
          subscriptionProvider.overrideWith((ref) async => null),
          billingPlansProvider.overrideWith(
            (ref) async => const <BillingPlan>[],
          ),
          notificationsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: MediaQueryData(padding: notch, viewPadding: notch),
            child: ProfileScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('surat kamera o\'yig\'i OSTIDA emas', (tester) async {
    await pump(tester, avatarUrl: '/media/avatar.jpg');

    final rect = tester.getRect(find.bySemanticsLabel(t.viewPhoto));
    expect(
      rect.top,
      greaterThanOrEqualTo(notch.top),
      reason:
          'Surat ekranning ${rect.top}px balandligida turibdi, tizim '
          'o\'yig\'i esa ${notch.top}px gacha yetadi — o\'yiqli yoki '
          'teshikli kamerali telefonda surat kamera ostiga tushadi.',
    );
  });

  testWidgets('suratga bosilsa TO\'LIQ EKRANDA ochiladi', (tester) async {
    await pump(tester, avatarUrl: '/media/avatar.jpg');

    // ATAYIN markazga bosiladi: odam suratni ko'rmoqchi bo'lsa aynan
    // o'rtasiga bosadi. Kamera nishonining bosish maydoni markazgacha
    // yetib kelsa, shu yerda tutiladi.
    await tester.tap(find.bySemanticsLabel(t.viewPhoto));
    await tester.pumpAndSettle();

    expect(
      find.byType(InteractiveViewer),
      findsOneWidget,
      reason:
          'Suratni bosganda ko\'rish oynasi ochilishi kerak. Ilgari bu '
          'yerda «boshqa rasm qo\'yish» tanlovi chiqardi.',
    );
  });

  testWidgets('surat YO\'Q bo\'lsa — bosish suratni tanlashga olib boradi', (
    tester,
  ) async {
    await pump(tester);

    // Ko'rsatadigan narsa yo'q: yorliq «o'zgartirish» bo'lib qoladi,
    // ya'ni bosish javobsiz qolmaydi.
    expect(find.bySemanticsLabel(t.viewPhoto), findsNothing);
    expect(find.bySemanticsLabel(t.changePhoto), findsWidgets);
  });

  testWidgets('kamera nishoni ALOHIDA tugma — surati borida ham', (
    tester,
  ) async {
    await pump(tester, avatarUrl: '/media/avatar.jpg');

    // Surat bor: ikkita alohida amal ko'rinishi shart — ko'rish va
    // o'zgartirish. Ilgari butun blok bitta amal edi.
    expect(find.bySemanticsLabel(t.viewPhoto), findsOneWidget);
    expect(find.bySemanticsLabel(t.changePhoto), findsOneWidget);
  });
}

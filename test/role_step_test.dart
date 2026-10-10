import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/features/auth/otp_screen.dart';
import 'package:yolyolakay/features/auth/phone_screen.dart';
import 'package:yolyolakay/features/profile/complete_profile_screen.dart';
import 'package:yolyolakay/features/shared/yol_button.dart';
import 'package:yolyolakay/features/support/support_entry.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// ROL SAVOLI va YORDAM YO'LI — ikkalasi ham 22.09.2026 da egasi so'radi.
///
/// 🔑 NEGA TEST: ikkala talab ham TARTIB haqida, ya'ni ular jimgina
/// buzilishi mumkin. Rol savoli ism maydonlaridan keyinga tushib qolsa
/// ham ekran "ishlaydi"; yordam havolasi kirish ekranidan olinsa ham
/// hech qanday xato chiqmaydi. Shuning uchun tartibning O'ZI o'lchanadi.
void main() {
  const t = AppStrings(Lang.uz);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    SharedPreferences.setMockInitialValues({'intro_seen': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 900));
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
          home: screen,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    tester.takeException(); // tarmoq yo'q — tabiiy
  }

  group('Rol savoli — kod tasdiqlangandan keyin, ma\'lumotdan OLDIN', () {
    testWidgets('birinchi ko\'rinadigan narsa — rol, ism maydonlari EMAS', (
      tester,
    ) async {
      await pump(tester, const CompleteProfileScreen());

      expect(find.text(t.chooseRoleTitle), findsOneWidget);
      expect(find.text(t.rolePassenger), findsOneWidget);
      expect(find.text(t.roleDriver), findsOneWidget);

      // 🔴 ILDIZ TALAB: hisob ma'lumoti rol tanlanmaguncha SO'RALMAYDI.
      expect(find.text(t.firstName), findsNothing);
      expect(find.text(t.lastName), findsNothing);
    });

    testWidgets('tanlanmaguncha tugma o\'chiq va SABABI yozilgan', (
      tester,
    ) async {
      await pump(tester, const CompleteProfileScreen());

      expect(tester.widget<YolButton>(find.byType(YolButton)).onPressed, isNull);
      // Jim o'chiq tugma — boshi berk ko'cha (loyiha qoidasi).
      expect(find.text(t.chooseRoleRequired), findsOneWidget);
    });

    testWidgets('haydovchi tanlansa — TEKSHIRUV haqida darhol aytiladi', (
      tester,
    ) async {
      await pump(tester, const CompleteProfileScreen());
      await tester.tap(find.text(t.roleDriver));
      await tester.pump();

      // Va'da emas, keyingi qadam: hujjatlar tekshiruvi.
      expect(find.text(t.chooseRoleDriverNote), findsOneWidget);
      expect(
        tester.widget<YolButton>(find.byType(YolButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('roldan keyin — ism/familiya, va orqaga qaytish mumkin', (
      tester,
    ) async {
      await pump(tester, const CompleteProfileScreen());
      await tester.tap(find.text(t.rolePassenger));
      await tester.pump();
      await tester.tap(find.byType(YolButton));
      await tester.pump();

      expect(find.text(t.firstName), findsOneWidget);
      expect(find.text(t.lastName), findsOneWidget);

      // Noto'g'ri bosgan odam qaytib tanlay olsin.
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      expect(find.text(t.chooseRoleTitle), findsOneWidget);
    });
  });

  group('Yordam — kirishdan OLDIN ham', () {
    testWidgets('kod ekranida yordam yo\'li bor', (tester) async {
      await pump(tester, const OtpScreen(phoneNumber: '+998901234567'));
      expect(find.byType(SupportLink), findsOneWidget);
      expect(find.text(t.supportNeedHelp), findsOneWidget);
    });

    testWidgets('telefon ekranida yordam yo\'li bor', (tester) async {
      await pump(tester, const PhoneScreen());
      expect(find.byType(SupportLink), findsOneWidget);
    });
  });
}

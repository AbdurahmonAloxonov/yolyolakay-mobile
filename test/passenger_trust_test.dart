import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/rides/passenger_trust.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// YO'LOVCHI HAQIDA HAYDOVCHIGA.
///
/// 🔴 NEGA TEST: bu vidjet odam haqida GAP AYTADI, ya'ni xato qilsa
/// birovga nisbatan yolg'on ayblov yoki yolg'on kafolat bo'ladi. Ikkalasi
/// ham reyting raqamini noto'g'ri chizishdan og'irroq.
void main() {
  const t = AppStrings(Lang.uz);

  User user({String? kyc, DateTime? created}) => User(
    id: 'u-1',
    phoneNumber: '+998901234567',
    firstName: 'Aziz',
    kycStatus: kyc,
    createdAt: created,
  );

  Future<void> pump(WidgetTester tester, User? u) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userByIdProvider.overrideWith((ref, id) async => u),
        ],
        child: const MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: PassengerTrust(userId: 'u-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tasdiqlangan bo\'lsa nishon BOR', (tester) async {
    await pump(tester, user(kyc: 'approved'));
    expect(find.text(t.passengerVerified), findsOneWidget);
  });

  /// 🔴 ENG MUHIM QOIDA. Bizda yo'lovchi uchun tekshiruv oqimi UMUMAN
  /// yo'q — ya'ni odam uni o'ta olmaydi ham. «Tasdiqlanmagan» deb yozish
  /// o'tib bo'lmaydigan imtihondan yiqilgan deb e'lon qilish bo'lardi.
  testWidgets('tasdiqlanmagan bo\'lsa AYBLOV yozilmaydi', (tester) async {
    for (final k in [null, '', 'none', 'pending', 'rejected']) {
      await pump(tester, user(kyc: k));
      expect(
        find.textContaining('tasdiqlanmagan', findRichText: true),
        findsNothing,
        reason: 'kyc=$k',
      );
      expect(find.text(t.passengerVerified), findsNothing, reason: 'kyc=$k');
    }
  });

  testWidgets('ro\'yxatdan o\'tgan yil ko\'rsatiladi', (tester) async {
    await pump(tester, user(created: DateTime(2024, 3, 1)));
    expect(find.text(t.memberSinceYear(2024)), findsOneWidget);
  });

  /// Ma'lumot kelmasa vidjet BO'SH joy egallamasin: bron kartasi tor va
  /// har piksel hisobda (u yerda toshish tarixi bor).
  testWidgets('profil yuklanmasa hech nima chizilmaydi', (tester) async {
    await pump(tester, null);
    expect(find.byType(Icon), findsNothing);
    expect(tester.getSize(find.byType(PassengerTrust)).height, 0);
  });

  testWidgets('bo\'sh id bilan so\'rov ham qilinmaydi', (tester) async {
    var called = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userByIdProvider.overrideWith((ref, id) async {
            called = true;
            return null;
          }),
        ],
        child: const MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: PassengerTrust(userId: '')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(called, isFalse);
  });

  /// ✅ 2026-08-27: backend `PassengerProfile` ga `kyc_status` va
  /// `created_at` qo'shdi. Ya'ni ma'lumot BRONDA keladi va qo'shimcha
  /// `GET /users/{id}` KETMASLIGI kerak — aks holda haydovchi ekranida
  /// har bron uchun ortiqcha so'rov qolib ketardi.
  group('bronda kelgan profil', () {
    testWidgets('so\'rov QILINMAYDI', (tester) async {
      var called = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userByIdProvider.overrideWith((ref, id) async {
              called = true;
              return null;
            }),
          ],
          child: const MaterialApp(
            locale: Locale('uz'),
            supportedLocales: [Locale('uz')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: PassengerTrust(
                userId: 'u-1',
                profile: DriverProfile(kycStatus: 'approved'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(called, isFalse, reason: 'bronda ma\'lumot bor edi');
      expect(find.text(t.passengerVerified), findsOneWidget);
    });

    /// Eski keshdagi javoblarda bu maydonlar YO'Q — shunda zaxira
    /// so'rovi ishlashi kerak, aks holda nishon jimgina yo'qolardi.
    testWidgets('maydonlar yo\'q bo\'lsa ZAXIRA so\'rov ishlaydi',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userByIdProvider.overrideWith((ref, id) async {
              called = true;
              return User(
                id: 'u-1',
                phoneNumber: '+998901234567',
                kycStatus: 'approved',
              );
            }),
          ],
          child: const MaterialApp(
            locale: Locale('uz'),
            supportedLocales: [Locale('uz')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: PassengerTrust(
                userId: 'u-1',
                profile: DriverProfile(name: 'Aziz'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(find.text(t.passengerVerified), findsOneWidget);
    });
  });
}

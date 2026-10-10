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

/// HAYDOVCHI ARIZASI RAD ETILGANDA — SABAB.
///
/// 🔴 Ilgari ilova sababni TAXMIN qilardi: "ko'pincha sabab — xira surat
/// yoki kesilgan burchak". Bu matn haqiqiy sabab bo'lmasligi mumkin edi
/// (masalan mashina raqami noto'g'ri) va odam bir xil hujjatni qayta-qayta
/// yuborardi. Backend `kyc_rejection_reason` ni qaytaradigan bo'ldi
/// (`frontend_updates.md` 4.1) — endi taxmin qilmaymiz.
///
/// 🔑 Sabab KELMASLIGI ODDIY hol (eski akkauntlar, yoki backend hali
/// qaytarmasa — 09.09.2026 o'lchovida biz uni jonli KO'RA OLMADIK).
/// Shuning uchun test IKKALA yo'lni ham qo'riqlaydi: sabab bo'lsa u
/// ko'rinadi, bo'lmasa eski maslahat qoladi va ekran SINMAYDI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const t = AppStrings(Lang.uz);

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester tester, {String? reason}) async {
    // Balandlik katta: karta profil ro'yxatining ichida turadi va past
    // ekranda surish kerak bo'lardi.
    await tester.binding.setSurfaceSize(const Size(400, 2400));
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
                kycStatus: 'rejected',
                kycRejectionReason: reason,
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
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('modarator sababi KO\'RSATILADI, taxmin esa yo\'q', (
    tester,
  ) async {
    const reason = 'Texnik pasport surati xira, raqamlar o\'qilmayapti.';
    await pump(tester, reason: reason);

    expect(find.text(t.kycRejected), findsOneWidget);
    expect(
      find.text(reason),
      findsOneWidget,
      reason:
          'Modarator yozgan sabab ko\'rinmayapti — odam nimani tuzatishni '
          'bilmaydi va o\'sha hujjatni qayta yuboradi.',
    );
    // Eng muhimi: TAXMIN endi yo'q. Ikkalasi yonma-yon tursa, odam
    // qaysi biriga ishonishni bilmaydi.
    expect(
      find.text(t.kycRejectedHint),
      findsNothing,
      reason:
          'Aniq sabab bor ekan, "ko\'pincha sabab — xira surat" degan '
          'taxmin ko\'rsatilmasligi kerak.',
    );
    expect(find.text(t.kycRejectedFix), findsOneWidget);
  });

  testWidgets('sabab KELMASA eski maslahat qoladi (ekran sinmaydi)', (
    tester,
  ) async {
    await pump(tester, reason: null);

    expect(find.text(t.kycRejected), findsOneWidget);
    expect(find.text(t.kycRejectedHint), findsOneWidget);
    expect(find.text(t.kycRejectedFix), findsNothing);
  });

  testWidgets('BO\'SH satr ham "sabab yo\'q" demakdir', (tester) async {
    // Backend `null` emas, `""` qaytarishi mumkin — o'shanda bo'sh
    // qizil quti chiqib qolmasin.
    await pump(tester, reason: '   ');

    expect(find.text(t.kycRejectedHint), findsOneWidget);
    expect(find.text(t.kycRejectedFix), findsNothing);
  });
}

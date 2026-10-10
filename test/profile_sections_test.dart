import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/active_role.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/billing.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/profile/my_stuff_section.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// «MENING NARSALARIM» — nima kimga ko'rinadi.
///
/// ⚠️ 18.09.2026: bo'lim SOZLAMALARDAN PROFILGA ko'chdi (egasi:
/// «sozlamalarda turishi g'alati ekan»), shuning uchun sinov endi
/// `MyStuffSection` ni o'lchaydi. KAFOLATLAR O'ZGARMADI — pastdagi
/// uchta holat aynan o'sha-o'sha.
///
/// 🔴 Egasi haqiqiy hisob bilan kirib ko'rsatdi (2026-08-14): "tariflar
/// qani?". Sabab — men "rol = mazmun" tuzatishida butun "Mening
/// narsalarim" blokini haydovchi rejimiga bog'lab yuborgan edim va
/// haydovchi bo'lmagan odam tariflar sahifasiga HECH QANDAY yo'l topa
/// olmasdi.
///
/// To'g'ri qoida:
///   • Tariflar — HAMMAGA;
///   • Mashinalarim va Daromadim — faqat haydovchi rejimida.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const t = AppStrings(Lang.uz);

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool isDriver,
    bool driverMode = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          activeRoleProvider.overrideWith(
            (ref) => _FixedRole(
              prefs,
              driverMode ? AppRole.driver : AppRole.passenger,
            ),
          ),
          meProvider.overrideWith(
            (ref) async => MeResponse(
              user: User(
                id: 'u-1',
                phoneNumber: '+998900000000',
                firstName: 'Aziz',
                role: isDriver ? 'driver' : 'passenger',
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
        child: MaterialApp(
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: MyStuffSection(cars: [])),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('yo\'lovchida TARIFLAR bor', (tester) async {
    await pump(tester, isDriver: false);

    expect(find.text(t.tariffsTitle), findsOneWidget);
    // Haydovchining narsalari esa yo'q.
    expect(find.text(t.myCars), findsNothing);
    expect(find.text(t.earningsTitle), findsNothing);
  });

  testWidgets('haydovchi YO\'LOVCHI rejimida ham tariflarni ko\'radi', (
    tester,
  ) async {
    await pump(tester, isDriver: true, driverMode: false);

    expect(find.text(t.tariffsTitle), findsOneWidget);
    expect(find.text(t.myCars), findsNothing);
  });

  testWidgets('haydovchi rejimida uchalasi ham bor', (tester) async {
    await pump(tester, isDriver: true);

    expect(find.text(t.tariffsTitle), findsOneWidget);
    expect(find.text(t.myCars), findsOneWidget);
    expect(find.text(t.earningsTitle), findsOneWidget);
  });
}

/// Sinov uchun o'zgarmas rol.
class _FixedRole extends ActiveRoleNotifier {
  _FixedRole(super.prefs, super.initial);
}

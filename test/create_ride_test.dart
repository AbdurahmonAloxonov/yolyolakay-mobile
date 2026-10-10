import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/billing.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/rides/create_ride_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// E'lon berish formasi — uzunligi va tartibi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const t = AppStrings(Lang.uz);

  /// Standart holat — PRO haydovchi.
  ///
  /// Obunasiz haydovchida premium belgilar qulflangan bo'ladi (backend
  /// xati 2026-08-13), shuning uchun forma tarkibini tekshiradigan testlar
  /// tarifi bor haydovchidan boshlanadi. Qulf o'zi alohida tekshiriladi.
  Future<Widget> boot({
    Subscription? plan = const Subscription(planName: 'pro', status: 'active'),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        meProvider.overrideWith(
          (ref) async => MeResponse(
            user: const User(
              id: 'u-1',
              phoneNumber: '+998900000000',
              role: 'driver',
            ),
            cars: const [
              Car(
                id: 'c-1',
                brand: 'Chevrolet',
                model: 'Cobalt',
                govNumber: '01 A 123 BC',
                moderationStatus: 'approved',
              ),
            ],
          ),
        ),
        subscriptionProvider.overrideWith((ref) async => plan),
      ],
      child: const MaterialApp(
        locale: Locale('uz'),
        supportedLocales: [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CreateRideScreen(),
      ),
    );
  }

  /// Ekran uzunroq: standart 800x600 da forma pastki qismi umuman
  /// chizilmaydi (ListView faqat ko'rinadiganini quradi).
  Future<void> pumpScreen(
    WidgetTester tester, {
    Subscription? plan = const Subscription(planName: 'pro', status: 'active'),
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(await boot(plan: plan));
    await tester.pumpAndSettle();
  }

  testWidgets('qo\'shimcha sozlamalar YOPIQ turadi', (tester) async {
    await pumpScreen(tester);

    // Bo'lim bor, lekin ichidagilar chizilmagan — forma qisqa.
    expect(find.text(t.extrasSection), findsOneWidget);
    expect(find.text(t.hasAc), findsNothing);
    expect(find.text(t.drivingSpeedTitle), findsNothing);
  });

  testWidgets('ochilsa qulayliklar chiqadi', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(t.extrasSection));
    await tester.pumpAndSettle();

    expect(find.text(t.hasAc), findsOneWidget);
    expect(find.text(t.pickupPoint), findsWidgets);
  });

  testWidgets('"E\'lon qilish" tugmasi AYLANTIRMASDAN ko\'rinadi', (
    tester,
  ) async {
    await pumpScreen(tester);

    // Ilgari u formaning eng oxirida edi.
    expect(find.text(t.publish), findsOneWidget);
    final buttonY = tester.getTopLeft(find.text(t.publish)).dy;
    final screenHeight = tester.getSize(find.byType(MaterialApp)).height;
    expect(
      buttonY,
      lessThan(screenHeight),
      reason: 'tugma ekran ichida turishi kerak',
    );
  });

  testWidgets('yoqilgan sozlamalar soni sarlavhada ko\'rinadi', (tester) async {
    await pumpScreen(tester);

    // Yopiq bo'limda nima yoqilganini bilish uchun yagona ishora shu.
    expect(find.text(t.extrasHint), findsOneWidget);

    await tester.tap(find.text(t.extrasSection));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.hasAc));
    await tester.pumpAndSettle();

    expect(find.text(t.extrasEnabled(1)), findsOneWidget);
    expect(find.text(t.extrasHint), findsNothing);
  });

  /// 🔴 Backend xati 2026-08-13: premium filtrlar FAQAT Pro va Premium'da.
  /// Ilgari obunasiz haydovchida ular OCHIQ turardi — u konditsionerni yoqib,
  /// e'lon qilishda 400 olardi va sababini bilmasdi.
  testWidgets('obunasiz haydovchida premium belgilar QULFLI', (tester) async {
    await pumpScreen(tester, plan: null);

    await tester.tap(find.text(t.extrasSection));
    await tester.pumpAndSettle();

    final ac = tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text(t.hasAc),
        matching: find.byType(SwitchListTile),
      ),
    );
    expect(ac.onChanged, isNull, reason: 'tumbler bosilmasligi kerak');
    expect(find.text(t.proOnlyFilter), findsWidgets, reason: 'sabab yozilsin');
  });

  /// «FAQAT AYOLLAR» — e'lon formasida (qaytarildi 08.09.2026).
  ///
  /// 🔴 IKKI SHART bir vaqtda tekshiriladi:
  ///   1. tanlov TARIFGA BOG'LIQ EMAS — obunasiz haydovchida ham ishlaydi
  ///      (xavfsizlik pullik bo'lmasin);
  ///   2. tanlangach IZOH chiqadi — bunday e'lon oddiy qidiruvda
  ///      ko'rinmasligini haydovchi BILIB tanlashi kerak.
  testWidgets('«faqat ayollar» obunasiz ham tanlanadi va izoh chiqadi', (
    tester,
  ) async {
    await pumpScreen(tester, plan: null);

    await tester.tap(find.text(t.extrasSection));
    await tester.pumpAndSettle();

    // ⚠️ `scrollUntilVisible` EMAS: ekranda bir nechta aylanadigan
    // qism bor va u «Too many elements» bilan yiqiladi.
    await tester.ensureVisible(find.text(t.forWomen));
    await tester.pumpAndSettle();

    // Izoh tanlashdan OLDIN chiqmaydi — bo'sh joyni bekorga yemasin.
    expect(find.text(t.womenOnlyDriverHint), findsNothing);

    await tester.tap(find.text(t.forWomen));
    await tester.pumpAndSettle();

    expect(find.text(t.womenOnlyDriverHint), findsOneWidget);
  });

  testWidgets('bo\'lim nomlari bor va BOSH HARFDA', (tester) async {
    await pumpScreen(tester);

    // `SectionLabel` matnni o'zi bosh harfga aylantiradi — tarjimalarda
    // qo'lda BOSH HARF yozib qo'yilmasin (uch tilda uch marta takrorlanardi).
    expect(find.text(t.routeSection.toUpperCase()), findsOneWidget);
    expect(find.text(t.whenAndPriceSection.toUpperCase()), findsOneWidget);
    expect(find.text(t.vehicle.toUpperCase()), findsOneWidget);
  });
}

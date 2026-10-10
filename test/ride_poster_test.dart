import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/ride_poster.dart';
import 'package:yolyolakay/l10n/strings.dart';

import 'support/preview_fonts.dart';

/// ULASHILADIGAN PLAKAT — ikki nisbat.
///
/// 🔴 NEGA TEST: bu rasm ilovadan TASHQARIDA yashaydi — Telegramda,
/// Statusda, begona odamning telefonida. U yerda buzuq chiqsa biz
/// buni hech qachon ko'rmaymiz, chunki ilovada hammasi joyida
/// ko'rinaveradi.
///
/// Ikki narsa qo'riqlanadi:
///   1. nisbat AYNAN 4:5 va 9:16 — «taxminan» bo'lmaydi, Status
///      to'g'ri kelmagan rasmni qirqadi yoki chetiga oq qo'yadi;
///   2. tanlov ISHLAYDI — ilgari plakat bitta nisbatda edi va
///      «hikoya» varianti umuman yo'q edi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  const t = AppStrings(Lang.uz);

  final ride = Ride(
    id: 'r1',
    originAddress: 'Toshkent',
    destinationAddress: 'Samarqand',
    originLat: 41.2995,
    originLon: 69.2401,
    destinationLat: 39.6542,
    destinationLon: 66.9597,
    departureTime: DateTime(2026, 9, 9, 7),
    totalSeats: 4,
    availableSeats: 3,
    pricePerSeat: 80000,
    status: RideStatus.active,
  );

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
  );

  double aspectOf(WidgetTester tester) {
    final size = tester.getSize(find.byType(RidePoster));
    return size.width / size.height;
  }

  testWidgets('lenta varianti — 4:5', (tester) async {
    await tester.pumpWidget(wrap(RidePoster(ride: ride)));
    await tester.pumpAndSettle();
    expect(aspectOf(tester), closeTo(4 / 5, 0.001));
  });

  testWidgets('hikoya varianti — 9:16', (tester) async {
    await tester.pumpWidget(wrap(RidePoster(ride: ride, story: true)));
    await tester.pumpAndSettle();
    expect(aspectOf(tester), closeTo(9 / 16, 0.001));
  });

  /// Ikkala variantda ham ASOSIY ma'lumot bo'lishi shart: yo'nalish va
  /// narx. Nisbat o'zgarganda biror qator tushib qolmasin.
  testWidgets('ikkala nisbatda ham yo\'nalish va narx bor', (tester) async {
    for (final story in [false, true]) {
      await tester.pumpWidget(wrap(RidePoster(ride: ride, story: story)));
      await tester.pumpAndSettle();
      expect(find.text('Toshkent'), findsOneWidget, reason: 'story=$story');
      expect(find.text('Samarqand'), findsOneWidget, reason: 'story=$story');
      expect(
        find.textContaining('80'),
        findsWidgets,
        reason: 'narx yo\'q, story=$story',
      );
    }
  });

  testWidgets('varaqda nisbat TANLANADI', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showRidePoster(context, ride),
                child: const Text('och'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('och'));
    await tester.pumpAndSettle();

    // Standart — lenta (4:5).
    expect(aspectOf(tester), closeTo(4 / 5, 0.01));

    await tester.tap(find.text(t.posterStory));
    await tester.pumpAndSettle();
    expect(aspectOf(tester), closeTo(9 / 16, 0.01));
  });
}

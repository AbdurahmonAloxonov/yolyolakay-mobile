import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/features/rides/journey_view.dart';
import 'package:yolyolakay/features/rides/ride_card.dart';
import 'package:yolyolakay/features/shared/ui.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// TOR EKRAN QO'RIQCHISI.
///
/// Egasi ro'yxatiga qo'shdi (2026-08-13): "joylashuvni to'g'irlash".
/// Qurilmada topilgan kamchiliklarning aksariyati bitta turdagi edi: matn
/// yoki tugma tor ekranga sig'may, qatorni buzib yuborardi
/// ("Nechta joy bor" ikki qatorga tushib boshqaruvni surgani, pochta
/// yorliqlarining kesilgani, "E'lon berish" yorlig'ining chetga yopishgani).
///
/// Bu sinov shu turdagi xatoni ODAMDAN OLDIN topadi: eng tor telefon
/// (320dp) va eng yomon ma'lumot (uzun shahar nomlari, uzun ism, katta
/// narx) bilan chizadi. Flutter toshib ketishni xato sifatida beradi va
/// sinov yiqiladi.
void main() {
  /// Eng yomon holat: uzun nomlar + katta raqamlar.
  Ride ride() => Ride(
    id: 'r-1',
    originAddress: 'Toshkent, Chilonzor tumani, 9-kvartal',
    originLat: 41.3,
    originLon: 69.2,
    destinationAddress: 'Qashqadaryo, Shahrisabz tumani markazi',
    destinationLat: 39.0,
    destinationLon: 66.8,
    departureTime: DateTime(2026, 8, 20, 16, 0),
    totalSeats: 4,
    availableSeats: 3,
    pricePerSeat: 1250000,
    status: 'active',
    driver: const DriverProfile(
      id: 'd-1',
      name: 'ABDURAHMON MUXAMMADALIYEV TOSHMUHAMMAD O\'G\'LI',
      rating: 4.9,
    ),
    hasAc: true,
    hasLuggage: true,
    noSmoking: true,
    noPets: true,
    maxTwoBack: true,
    takesParcels: true,
    isNegotiable: true,
    hasFairPriceBadge: true,
  );

  /// [textScale] — tizim shrifti kattalashtirilgan telefon (keksalar va
  /// ko'zi xira odamlarda odatiy holat). Bu turdagi buzilish 320dp dan ham
  /// ko'proq uchraydi: matn kattalashadi, qatorlar toshadi.
  Widget wrap(Widget child, {double width = 320, double textScale = 1.0}) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness: Brightness.light),
        locale: const Locale('uz'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: SizedBox(
              width: width,
              child: ListView(children: [child]),
            ),
          ),
        ),
      );

  const t = AppStrings(Lang.uz);

  testWidgets('safar kartochkasi 320dp da toshmaydi', (tester) async {
    await tester.pumpWidget(wrap(RideCard(ride: ride(), distanceKm: 12.5)));
    await tester.pump();
  });

  testWidgets('o\'z e\'lonim kartochkasi ham toshmaydi', (tester) async {
    await tester.pumpWidget(wrap(RideCard(ride: ride(), mine: true)));
    await tester.pump();
  });

  // 🔴 SHRIFT KATTALASHTIRILGAN TELEFON (egasi, 2026-08-20). Ilova
  // `textScaler` ni 1.3 gacha CHEKLAYDI (`app.dart`), ya'ni real eng yomon
  // holat aynan shu. 320dp + 1.3 da ham kartochka toshmasligi kerak —
  // narx, "adolatli narx" chipi va belgilar shu chegarada butun qolsin.
  testWidgets('safar kartochkasi katta shriftda (1.3) toshmaydi', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(RideCard(ride: ride(), distanceKm: 12.5), textScale: 1.3),
    );
    await tester.pump();
  });

  testWidgets('haydovchi qatori katta shriftda toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DriverRow(
          name: 'ABDURAHMON MUXAMMADALIYEV TOSHMUHAMMAD O\'G\'LI',
          rating: 4.9,
          inlineRating: true,
        ),
        textScale: 1.3,
      ),
    );
    await tester.pump();
  });

  testWidgets('marshrut chizig\'i uzun manzillarda toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(
        JourneyLine(
          origin: 'Toshkent, Yunusobod tumani, Amir Temur ko\'chasi 108-uy',
          destination: 'Qoraqalpog\'iston Respublikasi, Nukus shahri',
          stops: const ['Guliston shahri markazi', 'Jizzax, Sharof Rashidov'],
        ),
      ),
    );
    await tester.pump();
  });

  testWidgets('haydovchi qatori uzun ismda toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DriverRow(
          name: 'ABDURAHMON MUXAMMADALIYEV TOSHMUHAMMAD O\'G\'LI',
          rating: 4.9,
          inlineRating: true,
        ),
      ),
    );
    await tester.pump();
  });

  testWidgets('ma\'lumot qutisi uzun matnda toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(InfoBox(tone: InfoTone.warning, child: Text(t.driverCounterHint))),
    );
    await tester.pump();
  });

  testWidgets('holat yorlig\'i uzun so\'zda toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => Row(
            children: [
              const Expanded(child: Text('20 avgust, 16:00')),
              StatusPill(
                tone: StatusTone.forBooking(
                  Theme.of(context).colorScheme,
                  'pending_negotiation',
                ),
                label: t.bookingStatus('pending_negotiation'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  });

  /// KATTA SHRIFT — tizim sozlamasida matn kattalashtirilgan telefon.
  /// Bu holatda qatorlar eng oson toshadi.
  testWidgets('safar kartochkasi KATTA shriftda ham toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(RideCard(ride: ride(), distanceKm: 12.5), textScale: 1.6),
    );
    await tester.pump();
  });

  testWidgets('marshrut chizig\'i katta shriftda toshmaydi', (tester) async {
    await tester.pumpWidget(
      wrap(
        const JourneyLine(
          origin: 'Toshkent, Yunusobod tumani',
          destination: 'Qoraqalpog\'iston, Nukus shahri',
        ),
        textScale: 1.6,
      ),
    );
    await tester.pump();
  });

  /// KATTA EKRAN — planshet yoki katalanuvchi telefon. Kartochka butun
  /// kenglikka cho'zilib ketmasligi kerak (o'qish qiyinlashadi).
  testWidgets('keng ekranda ham chiziladi', (tester) async {
    await tester.pumpWidget(wrap(RideCard(ride: ride()), width: 900));
    await tester.pump();
  });
}

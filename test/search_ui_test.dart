import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/ride.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/rides/ride_card.dart';
import 'package:yolyolakay/features/search/filter_bar.dart';
import 'package:yolyolakay/features/rides/seat_map.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// Qidiruv ekranining ko'rinishi — egasi qurilmada aytgan kamchiliklar
/// bo'yicha (2026-08-12): filtrlar tepada yoyilib yotardi, kartalar esa
/// juda baland edi.
void main() {
  const t = AppStrings(Lang.uz);

  Widget wrap(Widget child, {List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: ListView(children: [child])),
        ),
      );

  /// Ko'p belgili safar — aynan shunday e'lonlar kartani cho'zib yuborardi.
  final loadedRide = Ride.fromJson(const {
    'id': 'r-1',
    'origin_address': 'Toshkent',
    'origin_lat': 41.2995,
    'origin_lon': 69.2401,
    'destination_address': 'Samarqand',
    'destination_lat': 39.6542,
    'destination_lon': 66.9597,
    'departure_time': '2026-08-20T09:00:00+05:00',
    'total_seats': 4,
    'available_seats': 3,
    'price_per_seat': 150000,
    'status': 'active',
    'driver': {'id': 'd-1', 'name': 'Aziz', 'rating': 4.9},
    'no_smoking': true,
    'no_pets': true,
    'has_ac': true,
    'has_luggage': true,
    'takes_parcels': true,
    'is_negotiable': true,
    'driving_speed': 'calm',
  });

  group('ro\'yxatdagi karta', () {
    testWidgets('belgilar EMOJI, to\'liq matn bilan emas', (tester) async {
      await tester.pumpWidget(wrap(RideCard(ride: loadedRide)));
      await tester.pumpAndSettle();

      // Ilgari har belgi to'liq matnli Chip edi va karta uch-to'rt qatorga
      // yoyilardi. Endi ro'yxatda matn yo'q — u safar ochilganda ko'rinadi.
      expect(find.text(t.noSmoking), findsNothing);
      expect(find.text(t.hasAc), findsNothing);
      // To'rttadan ortig'i "+N" bo'lib yig'iladi (bu safarda 7 ta belgi bor).
      expect(find.textContaining('+'), findsOneWidget);
    });

    testWidgets('eng muhimi qoladi: marshrut, narx, haydovchi', (tester) async {
      await tester.pumpWidget(wrap(RideCard(ride: loadedRide)));
      await tester.pumpAndSettle();

      expect(find.text('Toshkent'), findsOneWidget);
      expect(find.text('Samarqand'), findsOneWidget);
      expect(find.text('Aziz'), findsOneWidget);
      expect(find.textContaining('150'), findsOneWidget);
    });

    /// 🔴 Sxema kartadan JIMGINA yo'qolib qolmasin: u meta matn bilan
    /// bitta qatorni bo'lishadi, ya'ni kelajakda o'sha qatorga biror narsa
    /// qo'shilsa eng oson qurbon shu bo'ladi. Ilgari bu yerda «2 joy»
    /// degan matn turardi va u ikki xil o'qilardi — mashinada ikkita joy
    /// bormi yoki ikkitasi BO'SHMI.
    testWidgets('kartada o\'rindiq sxemasi BOR', (tester) async {
      await tester.pumpWidget(wrap(RideCard(ride: loadedRide)));
      await tester.pumpAndSettle();

      expect(find.byType(SeatMap), findsOneWidget);
      // Ixcham: kartada sarlavha ham, «N tadan M tasi bo'sh» matni ham
      // ortiqcha — ular balandlik budjetini yeb qo'yardi.
      expect(tester.widget<SeatMap>(find.byType(SeatMap)).compact, isTrue);
    });

    testWidgets('karta past: balandligi 170 pikseldan oshmaydi', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(RideCard(ride: loadedRide)));
      await tester.pumpAndSettle();

      final height = tester.getSize(find.byType(RideCard)).height;
      // O'lchov: qayta yiriklashib ketmasin. Ilgari matnli belgilar bilan
      // 260 pikseldan oshardi — ekranga bittayu yarimta safar sig'ardi.
      expect(
        height,
        lessThan(170),
        reason: 'ekranga kamida uchta safar sig\'ishi kerak',
      );
    });
  });

  group('filtr qatori', () {
    // ⚠️ `sharedPrefsProvider` SHART: 2026-09-05 dan boshlab filtrlar
    // qurilmada saqlanadi (izohi `SearchFilters.toJson` da) va
    // kontroller ilova ochilishida o'sha xotirani o'qiydi. Override
    // bo'lmasa u «main.dart da override qilinadi» deb tashlaydi.
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    List<Override> overrides({String gender = 'male'}) => [
      sharedPrefsProvider.overrideWithValue(prefs),
      meProvider.overrideWith(
        (ref) async => MeResponse(
          user: User(id: 'u-1', phoneNumber: '+998900000000', gender: gender),
          cars: const [],
        ),
      ),
    ];

    testWidgets('bitta qator: filtr tugmasi + saralash', (tester) async {
      await tester.pumpWidget(wrap(const FilterBar(), overrides: overrides()));
      await tester.pumpAndSettle();

      expect(find.text(t.filters), findsOneWidget);
      // Ilgari o'nta filtr chipi tepada yoyilib yotardi.
      expect(find.byType(FilterChip), findsNothing);
      // Balandligi bitta tugma qatoricha.
      expect(tester.getSize(find.byType(FilterBar)).height, lessThan(64));
    });

    testWidgets('tugma bosilsa varaq ochiladi', (tester) async {
      await tester.pumpWidget(wrap(const FilterBar(), overrides: overrides()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.filters));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
      expect(find.text(t.noSmoking), findsOneWidget);
      expect(find.text(t.showResults), findsOneWidget);
    });

    /// 🔴 Filtr QAYTARILDI (egasi, 2026-09-08), lekin 13.08.2026 dagi
    /// qoida kuchida: «erkaklar ham uni qidira olsin» — ya'ni u
    /// HAMMADA ko'rinadi, jinsga qarab yashirilmaydi.
    ///
    /// Eski sinov teskarisini qo'riqlardi (filtr hech kimda yo'q).
    /// Aynan shu yerda ehtiyot bo'lish kerak: filtrni ayolga
    /// "ochib", erkakdan yashirish — biz allaqachon bir marta qilgan
    /// va egasi rad etgan xato.
    testWidgets('"faqat ayollar" filtri HAMMADA bor', (tester) async {
      for (final gender in ['', 'female', 'male']) {
        await tester.pumpWidget(
          wrap(const FilterBar(), overrides: overrides(gender: gender)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.filters));
        await tester.pumpAndSettle();

        expect(
          find.text(t.womenOnlyFilter),
          findsOneWidget,
          reason: 'jins = "$gender"',
        );
        // Izoh SHART: belgi haydovchining jinsi deb tushunilmasin.
        expect(find.text(t.womenOnlyHint), findsOneWidget);

        // Varaqni yopamiz — keyingi aylanish uchun.
        Navigator.of(tester.element(find.text(t.showResults))).pop();
        await tester.pumpAndSettle();
      }
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/data/models/parcel.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/data/repositories/parcels_repository.dart';
import 'package:yolyolakay/features/parcels/find_parcels_screen.dart';

import 'support/preview_fonts.dart';

/// HAYDOVCHI TOMONI — posilkani qanday oladi.
///
/// Egasi haydovchi hisobiga kira olmaydi: haydovchi bo'lish moderatsiya
/// tasdig'ini talab qiladi va telefonda
/// ochilmaydi. Shu sabab bu ekranni FAQAT shu yerda ko'rish mumkin —
/// haydovchi profili va posilkalar soxta beriladi, ekranning o'zi esa
/// ilovadagi haqiqiy vidjet.
///
/// Rasmini yangilash:
///   flutter test test/parcel_driver_test.dart --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  Parcel parcel({
    required String id,
    required String from,
    required String to,
    double price = 50000,
    String? driverId,
  }) => Parcel(
    id: id,
    originLat: 41.2995,
    originLon: 69.2401,
    destinationLat: 39.6542,
    destinationLon: 66.9597,
    fromAddress: from,
    toAddress: to,
    price: price,
    driverId: driverId,
    size: 'small',
    description: 'Hujjatlar solingan konvert',
    status: driverId == null ? 'pending' : 'accepted',
  );

  /// [carrying] — "Olib ketayotganlarim" yorlig'i (aks holda qidiruv).
  Future<_FakeParcels> pumpDriver(
    WidgetTester tester, {
    bool carrying = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _FakeParcels(
      carrying: [
        parcel(
          id: 'p-carry',
          from: 'Toshkent, Chilonzor',
          to: 'Samarqand',
          price: 60000,
          driverId: 'u-1',
        ),
      ],
      found: [
        parcel(id: 'p-1', from: 'Toshkent, Yunusobod', to: 'Andijon'),
        parcel(
          id: 'p-2',
          from: 'Toshkent, Sergeli',
          to: 'Buxoro',
          price: 80000,
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          parcelsRepositoryProvider.overrideWithValue(repo),
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
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: withPreviewFont(buildTheme(brightness: Brightness.light)),
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: carrying
                ? const CarryingParcelsView()
                : const FindParcelsView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  /// Shahar tanlash → "Qidirish".
  Future<void> search(WidgetTester tester) async {
    // Shahar maydoni endi `CityField` (ilovaning yagona shahar
    // qatori) — «nishonga olish» ikonkasi yo'q, shuning uchun
    // maydonning YORLIG'IGA bosamiz: odam ham shunday qiladi.
    await tester.tap(find.text('Qayerdan olib ketasiz'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Toshkent');
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    await tester.tap(find.text('Toshkent').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qidirish'));
    await tester.pumpAndSettle();
  }

  testWidgets('olib ketayotganlarim ALOHIDA yorliqda', (t) async {
    // Ilgari bu ro'yxat ilovada umuman yo'q edi: taklif qabul qilingach
    // posilka haydovchi ekranidan yo'qolardi. Keyin u qidiruv ekranining
    // tepasiga qo'yildi va asosiy ishni pastga surib yubordi — endi
    // o'z yorlig'ida.
    await pumpDriver(t, carrying: true);
    expect(find.textContaining('Samarqand'), findsOneWidget);
    // Bu yorliqda taklif tugmasi bo'lmaydi — bu allaqachon meniki.
    expect(find.text('Taklif berish'), findsNothing);
  });

  testWidgets('qidiruv ekranida olib ketayotganlarim ARALASHMAYDI', (t) async {
    await pumpDriver(t);
    expect(find.textContaining('Samarqand'), findsNothing);
  });

  testWidgets('topilgan posilkada TAKLIF tugmasi bor', (t) async {
    await pumpDriver(t);
    await search(t);

    // Yo'nalish bitta qatorda chiziladi ("... → Andijon").
    expect(find.textContaining('Andijon'), findsWidgets);
    // 🔴 Tugma "Olib ketaman" EMAS: haydovchi posilkani jo'natuvchidan
    // so'ramasdan olib qo'ymaydi, narx taklif qiladi.
    expect(find.widgetWithText(FilledButton, 'Taklif berish'), findsWidgets);
    expect(find.text('Olib ketaman'), findsNothing);
  });

  testWidgets('taklif narxi so\'raladi va serverga ketadi', (t) async {
    final repo = await pumpDriver(t);
    await search(t);

    await t.tap(find.widgetWithText(FilledButton, 'Taklif berish').first);
    await t.pumpAndSettle();

    // Boshlang'ich narx — jo'natuvchi aytgani (ko'pincha shunga rozi bo'ladi).
    expect(find.text('50000'), findsOneWidget);

    await t.enterText(find.byType(TextField).last, '45000');
    await t.tap(find.widgetWithText(FilledButton, 'Taklif berish').last);
    await t.pumpAndSettle();

    expect(repo.offers, [('p-1', 45000.0)]);
  });

  testWidgets('rasm — haydovchi ekrani', (t) async {
    await pumpDriver(t);
    await search(t);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/ekran_haydovchi_pochta.png'),
    );
  });
}

/// Tarmoqsiz posilka ombori.
class _FakeParcels implements ParcelsRepository {
  _FakeParcels({required this.carrying, required this.found});

  final List<Parcel> carrying;
  final List<Parcel> found;

  /// Yuborilgan takliflar: (posilka, narx).
  final List<(String, double)> offers = [];

  @override
  Future<List<Parcel>> mine({String role = 'sender'}) async =>
      role == 'driver' ? carrying : const [];

  @override
  Future<List<Parcel>> search({
    required double lat,
    required double lon,
    double radiusKm = 25,
  }) async => found;

  @override
  Future<ParcelResponse> respond(String parcelId, double offeredPrice) async {
    offers.add((parcelId, offeredPrice));
    return ParcelResponse(id: 'r-1', parcelId: parcelId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} sinovda kerak emas');
}

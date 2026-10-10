import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/app/router.dart';
import 'package:yolyolakay/core/api/api_client.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/features/shared/connection_banner.dart';

/// UZILISH CHIZIG'I — ikkita xato uchun qo'riqchi.
///
/// 🔴 IKKALASI HAM 07.09.2026 da JONLI O'LCHOVDA topildi, na 1355 ta
/// test, na ko'z bilan ko'rik ularni ko'rgan edi:
///
///   1. chiziq bosilganda `context.push` «No GoRouter found in context»
///      bilan YIQILARDI — vidjet `MaterialApp.router` ning `builder` ida,
///      ya'ni router'dan YUQORIDA. «Xizmat holatiga eng qisqa yo'l» deb
///      qo'yilgan chiziq 25-avgustdan buyon HECH QACHON ishlamagan;
///
///   2. chiziq kontent USTIDAN chizilardi va ko'ringanda AppBar'ning
///      yuqori qismini qoplardi — ORQAGA tugmasi aynan o'sha yerda.
///      Ya'ni uzilish paytida odam orqaga qayta olmasdi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient client;

  /// Bosilganda qayerga o'tganini yozib boradigan haqiqiy router.
  late GoRouter router;
  late SharedPreferences prefs;

  Widget app({required Widget child}) => ProviderScope(
    overrides: [
      // `sharedPrefsProvider` odatda `main.dart` da beriladi — testda
      // uni bermаsak, chiziq ichidagi NAVBAT hisoblagichi yiqiladi.
      sharedPrefsProvider.overrideWithValue(prefs),
      // Navbat (`outboxProvider`) repozitoriylarni quradi, ular esa
      // tokenlarni so'raydi — bu ham odatda `main.dart` da beriladi.
      tokenStorageProvider.overrideWithValue(TokenStorage()),
      apiClientProvider.overrideWithValue(client),
      routerProvider.overrideWithValue(router),
    ],
    child: MaterialApp(home: ConnectionBanner(child: child)),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    FlutterSecureStorage.setMockInitialValues({});
    client = ApiClient(tokens: TokenStorage());
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
        GoRoute(
          path: Routes.serviceStatus,
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  });

  testWidgets('chiziq bosilsa YIQILMAYDI va xizmat holatiga o\'tadi', (
    tester,
  ) async {
    client.connected.value = false;
    await tester.pumpWidget(app(child: const Text('kontent')));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byType(InkWell).first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.takeException(),
      isNull,
      reason: 'bosish istisno tashlamasligi kerak',
    );
    // 🔑 Ekran CHIZILISHINI kutmaymiz: testda `MaterialApp` (router
    // emas) ishlatilyapti, ya'ni delegat ulanmagan va u hech narsa
    // qurmaydi. O'lchanadigan narsa — bosish ROUTER'GA yetdimi, ya'ni
    // manzil o'zgardimi.
    expect(
      router.routeInformationProvider.value.uri.toString(),
      Routes.serviceStatus,
    );
  });

  testWidgets('chiziq KO\'RINGANDA kontent pastga suriladi', (tester) async {
    // Avval ULANGAN holat — kontent eng tepada.
    client.connected.value = true;
    await tester.pumpWidget(app(child: const Text('kontent')));
    await tester.pump(const Duration(milliseconds: 300));
    final ulangan = tester.getTopLeft(find.text('kontent')).dy;

    // Endi UZILGAN holat — kontent chiziq balandligicha pastga tushsin.
    client.connected.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final uzilgan = tester.getTopLeft(find.text('kontent')).dy;

    expect(
      uzilgan,
      greaterThan(ulangan),
      reason: 'chiziq ko\'ringanda kontent pastga surilishi kerak — aks holda '
          'u AppBar ustiga tushadi va orqaga tugmasini o\'g\'irlaydi',
    );
  });

  testWidgets('ULANGAN holatda chiziq bosishni O\'ZIGA OLMAYDI', (
    tester,
  ) async {
    // 🔑 `IgnorePointer` allaqachon bor edi — bu test uni SAQLAYDI:
    // olib tashlansa, ko'rinmas chiziq har ekranning tepasidagi
    // bosishlarni yutib qo'yadi.
    client.connected.value = true;
    var tapped = false;
    await tester.pumpWidget(
      app(
        child: Align(
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => tapped = true,
            child: const SizedBox(height: 40, width: 200, child: Text('tepa')),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('tepa'));
    expect(tapped, isTrue, reason: 'ko\'rinmas chiziq bosishni yutmasin');
  });
}

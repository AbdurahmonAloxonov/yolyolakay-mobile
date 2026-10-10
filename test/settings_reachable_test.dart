import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/app.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/features/chat/chats_screen.dart';
import 'package:yolyolakay/features/parcels/parcels_screen.dart';
import 'package:yolyolakay/features/profile/profile_screen.dart';
import 'package:yolyolakay/features/rides/create_ride_screen.dart';
import 'package:yolyolakay/features/search/search_screen.dart';
import 'package:yolyolakay/features/trips/my_trips_screen.dart';

import 'support/audit_screens.dart';

/// ⚙️ SOZLAMALARGA HAR TABDAN YETIB BORISH MUMKINMI.
///
/// 🔴 NEGA YOZILDI (2026-09-05, egasi aytdi): «settings ikoni faqat
/// profilda bo'lib qolgan». 02.09 da sozlamalar profildan ATAYIN
/// ajratilgan edi (profilga hamma narsa tiqilgandi), lekin ⚙️ o'sha
/// ajratishda faqat profil sarlavhasida qoldi. Natijada "Safarlarim"
/// yoki "Pochta" da turgan odam til/tema/parolga yetish uchun avval
/// profilga o'tishi kerak edi.
///
/// Bu AYNAN qo'ng'iroqcha bilan bo'lgan xatoning takrori — u ham bir
/// paytlar faqat qidiruvda edi (izohi `NotificationBell` da). Shuning
/// uchun endi qo'riqchi test bor: yangi tab qo'shilsa yoki sarlavha
/// qayta yozilsa, ⚙️ ning jimgina tushib qolishi shu yerda ushlanadi.
///
/// 🔑 IKKINCHI TALAB — «bosilsa 1 ta oldinga qaytarsin». Ya'ni
/// sozlamadan chiqqan odam O'ZI KIRGAN tabga qaytsin. Buni faqat
/// ikonka borligini sanash bilan tekshirib bo'lmaydi: `go` ishlatilsa
/// ikonka JOYIDA turadi-yu, orqaga qaytish odamni qidiruvga tashlaydi.
/// Shuning uchun quyidagi ikkinchi guruh haqiqiy router bilan yuradi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('⚙️ har bir asosiy ekranda bor', () {
    // Pastki qatordagi BESH tab. Birinchisi rolga qarab ikkiga
    // bo'linadi: yo'lovchida qidiruv, haydovchida e'lon berish
    // (izohi `router.dart` da) — ikkalasi ham tekshiriladi.
    final screens = <String, Widget>{
      'qidiruv': const SearchScreen(),
      'e\'lon berish (haydovchi rejimi)': const CreateRideScreen(),
      'safarlarim': const MyTripsScreen(),
      'pochta': const ParcelsScreen(),
      'suhbatlar': const ChatsScreen(),
      'profil': const ProfileScreen(),
    };

    for (final entry in screens.entries) {
      testWidgets('${entry.key} — sozlamalar tugmasi ko\'rinadi', (
        tester,
      ) async {
        await pumpAuditScreen(tester, entry.value);

        expect(
          find.byIcon(Icons.settings_outlined),
          findsOneWidget,
          reason:
              '${entry.key} ekranida ⚙️ yo\'q — bu tabdagi odam '
              'sozlamalarga yeta olmaydi',
        );
      });
    }
  });

  group('orqaga — AYNAN BIR QADAM', () {
    Future<void> boot(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'intro_seen': true});
      final prefs = await SharedPreferences.getInstance();
      final tokens = TokenStorage()..access = 'test-token';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(tokens),
            sharedPrefsProvider.overrideWithValue(prefs),
          ],
          child: const YolYolakayApp(),
        ),
      );
      // ⚠️ `pumpAndSettle` ISHLAMAYDI: ekranlarda to'xtovsiz aylanuvchi
      // yuklanish belgisi bor va u hech qachon "tinchimaydi".
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      while (tester.takeException() != null) {}
    }

    testWidgets('«Safarlarim» dan kirilsa — o\'sha tabga qaytadi', (
      tester,
    ) async {
      await boot(tester);

      // 1. Ikkinchi tabga o'tamiz.
      await tester.tap(find.text('Safarlarim').last);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      while (tester.takeException() != null) {}
      expect(find.byType(MyTripsScreen), findsOneWidget);

      // 2. ⚙️ ni bosamiz.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      while (tester.takeException() != null) {}
      expect(
        find.text('Sozlamalar'),
        findsWidgets,
        reason: '⚙️ bosilgach sozlamalar ekrani ochilishi kerak',
      );

      // 3. Orqaga — BIR marta.
      // ⚠️ `byTooltip('Back')` ISHLAMAYDI: ilova o'zbek tilida va
      // tooltip matni tarjimadan keladi. Vidjet turi bo'yicha qidiramiz.
      final back = find.byType(BackButton);
      expect(back, findsOneWidget, reason: 'sozlamalarda orqaga tugmasi yo\'q');
      await tester.tap(back);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      while (tester.takeException() != null) {}

      // 4. 🔑 O'SHA tabda turibmiz — qidiruvga tushib ketmadik.
      expect(
        find.byType(MyTripsScreen),
        findsOneWidget,
        reason:
            'orqaga bosilgach odam O\'ZI KIRGAN tabga qaytishi kerak; '
            'qidiruvga tushsa — `push` o\'rniga `go` ishlatilgan',
      );
      expect(find.byType(SearchScreen), findsNothing);
    });

    testWidgets('«Pochta» dan kirilsa — o\'sha tabga qaytadi', (tester) async {
      await boot(tester);

      await tester.tap(find.text('Pochta').last);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      while (tester.takeException() != null) {}
      expect(find.byType(ParcelsScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      while (tester.takeException() != null) {}

      await tester.tap(find.byType(BackButton));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      while (tester.takeException() != null) {}

      expect(find.byType(ParcelsScreen), findsOneWidget);
      expect(find.byType(SearchScreen), findsNothing);
    });
  });
}

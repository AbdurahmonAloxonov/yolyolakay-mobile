import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/chat.dart';
import 'package:yolyolakay/data/models/parcel.dart';
import 'package:yolyolakay/features/chat/chats_screen.dart';
import 'package:yolyolakay/features/parcels/find_parcels_screen.dart';
import 'package:yolyolakay/features/parcels/my_parcels_screen.dart';
import 'package:yolyolakay/features/shared/state_views.dart';
import 'package:yolyolakay/l10n/strings.dart';

import 'support/audit_screens.dart';

/// BO'SH EKRANDAN CHIQISH YO'LI BOR-MI VA U ISHLAYDIMI.
///
/// 🔴 NEGA YOZILDI (2026-09-05, qulaylik auditining B bosqichi):
/// ilovada 14 ta bo'sh holat bor edi va ularning **10 tasi boshi berk**
/// edi — «posilkangiz yo'q», «suhbat yo'q», «bron yo'q» deb yozilardi,
/// nima qilish kerakligi esa aytilmasdi. Odam orqaga chiqib, boshqa
/// yo'ldan qaytadan kirishga majbur edi.
///
/// 🔑 IKKI XIL O'LCHOV BOR va ikkalasi ham kerak:
///
///   `tools/qulaylik_audit.py`  — tugma BORMI (kodni o'qiydi)
///   shu fayl                   — tugma ISHLAYDIMI (bosib ko'radi)
///
/// Faqat birinchisi bo'lsa, `onAction: () {}` yozib qo'yish auditni
/// yashil qilardi. Shuning uchun bu yerda tugma haqiqatan BOSILADI.
///
/// ⚠️ Yorliq almashtiradigan tugmalar (`DefaultTabController.animateTo`)
/// shu testda o'lchanadi; yo'l ochadiganlari (`context.go`) esa
/// `settings_reachable_test.dart` dagi kabi haqiqiy router talab
/// qiladi — ular u yerda emas, chaqiruv borligi bilan tekshiriladi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('posilkalarim — «Yuborish» yorlig\'iga o\'tkazadi', (
    tester,
  ) async {
    // Yorliqli ekranni O'ZIDA, ya'ni `DefaultTabController` ichida
    // chizamiz: `animateTo` aynan shu kontrollerni qidiradi va yakka
    // chizilganda test yolg'on xato berardi.
    await pumpAuditScreen(
      tester,
      DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: const TabBar(tabs: [Tab(text: 'A'), Tab(text: 'B')]),
          body: const TabBarView(
            children: [Center(child: Text('YUBORISH')), MyParcelsView()],
          ),
        ),
      ),
      // ⚠️ Provayder BO'SH RO'YXAT qaytarsin. Serversiz muhitda u
      // XATO holatiga tushadi va bo'sh holat UMUMAN chizilmaydi —
      // ya'ni test o'lchamoqchi bo'lgan narsa ekranga chiqmaydi.
      overrides: [
        myParcelsProvider.overrideWith((_) async => const <Parcel>[]),
      ],
    );

    // Ikkinchi yorliqqa o'tamiz — bo'sh holat o'sha yerda.
    await tester.tap(find.text('B'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    while (tester.takeException() != null) {}

    final action = find.descendant(
      of: find.byType(EmptyView),
      matching: find.byType(FilledButton),
    );
    expect(
      action,
      findsOneWidget,
      reason: 'posilkalarim bo\'sh holatida chiqish tugmasi yo\'q',
    );

    await tester.tap(action);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(
      find.text('YUBORISH'),
      findsOneWidget,
      reason: 'tugma bosildi, lekin birinchi yorliqqa o\'tmadi',
    );
  });

  testWidgets('olib ketayotganlarim — «Yuk topish» yorlig\'iga o\'tkazadi', (
    tester,
  ) async {
    await pumpAuditScreen(
      tester,
      DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: const TabBar(tabs: [Tab(text: 'A'), Tab(text: 'B')]),
          body: const TabBarView(
            children: [Center(child: Text('TOPISH')), CarryingParcelsView()],
          ),
        ),
      ),
      overrides: [
        carryingParcelsProvider.overrideWith((_) async => const <Parcel>[]),
      ],
    );

    await tester.tap(find.text('B'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    while (tester.takeException() != null) {}

    final action = find.descendant(
      of: find.byType(EmptyView),
      matching: find.byType(FilledButton),
    );
    expect(action, findsOneWidget);

    await tester.tap(action);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(find.text('TOPISH'), findsOneWidget);
  });

  testWidgets('suhbatlar bo\'sh — safar qidirishga taklif qiladi', (
    tester,
  ) async {
    await pumpAuditScreen(
      tester,
      const ChatsScreen(),
      overrides: [
        conversationsProvider.overrideWith((_) async => const <Conversation>[]),
      ],
    );

    final t = AppStrings(Lang.uz);
    expect(
      find.widgetWithText(FilledButton, t.searchButton),
      findsOneWidget,
      reason:
          'yozishma SAFARdan boshlanadi — bo\'sh suhbatlar ekrani '
          'qidiruvga yo\'l ko\'rsatishi kerak',
    );
  });
}

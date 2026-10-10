import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/app.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/core/env.dart';
import 'package:yolyolakay/features/rides/ride_card.dart';
import 'package:yolyolakay/features/shared/state_views.dart';

/// 🚗 ILOVANI HAQIQIY BACKEND BILAN BOSHDAN-OXIR HAYDAB CHIQADI.
///
/// 🔴 NEGA YOZILDI (2026-09-05). Bizda ikkita o'lchov bor edi va
/// ikkalasi ham ORADAGI bo'shliqni ko'rmasdi:
///
///   `probe.py`         SERVERNI o'lchaydi  — 34 amal, hammasi 200
///   `flutter test`     SOXTA ma'lumot bilan ishlaydi (111 fayl)
///
/// Ya'ni "server to'g'ri javob berdi" va "test yashil" bo'la turib,
/// odam ekranda hech narsa ko'rmasligi mumkin. Bu FARAZ emas: posilka
/// `picked_up` holatida qotib qolgan xato AYNAN shu bo'shliqda uch
/// hafta yashiringan edi — server to'g'ri ishlardi, testlar yashil
/// edi, «Yetkazdim» tugmasi esa HECH QACHON chiqmagan.
///
/// Bu test o'sha bo'shliqni yopadi: HAQIQIY ilova, HAQIQIY qurilma,
/// HAQIQIY prod backend, sinov akkaunti bilan.
///
/// ## Ishlatish
///
///     flutter emulators --launch yol_video
///     flutter test integration_test/live_walk_test.dart -d emulator-5554
///
/// ## 🔑 QOIDALAR
///
/// * BIRINCHI XATODA TO'XTAMAYDI. Maqsad — "hammasi ishlaydimi"
///   degan savolga TO'LIQ javob berish, birinchi qoqilgan joyni
///   topish emas. Har qadam alohida yoziladi, oxirida `probe.py`
///   uslubidagi hisobot chiqadi;
/// * O'CHIRUVCHI amallar YO'Q: hisobni o'chirish va haqiqiy to'lov
///   ATAYIN chaqirilmaydi (sinov akkaunti yo'qolsa qolgan hamma
///   o'lchov ham yo'qoladi);
/// * o'lchov PRODGA boradi. Sinov akkaunti — `probe.py` dagi bilan
///   BIR XIL raqam, ya'ni ikkala vosita bir xil ma'lumotni ko'radi.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Sinov haydovchisi — `scripts/backend-probe/probe.py` dagi
  /// `DRIVER` bilan bir xil. Kod har doim `99887` (backend sinov
  /// raqamlari uchun qat'iy kod beradi).
  const phoneDigits = '991234567';
  const otpCode = '99887';

  final report = <_Step>[];

  /// Belgilangan vaqt davomida kadrlarni haydaydi (tarmoq javobini
  /// kutish uchun) — `pumpAndSettle` o'rniga, izohi `waitFor` da.
  Future<void> idle(WidgetTester tester, Duration d) async {
    final end = DateTime.now().add(d);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Finder paydo bo'lishini KUTADI (tarmoq javobini kutish).
  ///
  /// ⚠️ `pumpAndSettle` bu ilovada ISHLAMAYDI: yuklanish belgisi
  /// (`LoomLoader`) to'xtovsiz aylanadi va kadrlar hech qachon
  /// tugamaydi — `pumpAndSettle` timeout bilan yiqiladi.
  Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 150));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  /// Ekrandagi matnlarni yig'adi — «topilmadi» degan xabar O'ZI YETMAYDI.
  ///
  /// 🔴 NEGA (07.09.2026): birinchi chuqur o'lchovda beshta qadamdan
  /// to'rttasi «topilmadi» deb yozdi va men ularni o'qib НИМА bo'lganini
  /// ayta olmadim — ilova xatomi yoki finder xatomi, farqi ko'rinmasdi.
  /// Endi har bir topilmaslik ekranda NIMA borligini ham yozadi.
  String screenTexts(WidgetTester tester, {int limit = 14}) {
    final seen = <String>{};
    for (final w in tester.widgetList<Text>(find.byType(Text))) {
      final t = (w.data ?? '').trim();
      if (t.isNotEmpty && t.length < 40) seen.add(t);
      if (seen.length >= limit) break;
    }
    return seen.join(' · ');
  }

  /// Suradi va matnni qidiradi — uzun ekranlarda element hali QURILMAGAN
  /// bo'lishi mumkin va `find.text` uni ko'rmaydi.
  ///
  /// 🔴 07.09.2026: profilda «Mashinalarim» aynan shu sababdan
  /// «yo'q» bo'lib chiqqandi.
  Future<bool> scrollTo(WidgetTester tester, Finder finder,
      {int steps = 12}) async {
    for (var i = 0; i <= steps; i++) {
      if (finder.evaluate().isNotEmpty) {
        // 🔴 07.09.2026, TASHXIS BILAN O'LCHANDI: element DARAXTDA bor
        // edi (`tugma oldin=1`), lekin EKRANDAN TASHQARIDA. `tester.tap`
        // bunday vidjetni bosganda koordinata ekran tashqarisiga tushadi
        // va bosish MO'LJALGA TEGMAYDI — jim, xatosiz. Uch marta
        // «rejim almashmadi» degan qizil aynan shundan edi.
        //
        // 🔑 Va meni chalg'itgan narsa: profil ro'yxati DANGASA EMAS,
        // ya'ni hamma matn surishdan qat'i nazar daraxtda turadi —
        // «matnlar o'zgarmadi» degan belgim surish ishlamayapti degani
        // EMAS edi.
        await tester.ensureVisible(finder.first);
        await idle(tester, const Duration(milliseconds: 400));
        return true;
      }
      if (i == steps) break;
      // Hali qurilmagan bo'lsa (dangasa ro'yxatlar) — suramiz.
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.dragFrom(
        Offset(size.width / 2, size.height * 0.7),
        const Offset(0, -400),
      );
      await idle(tester, const Duration(milliseconds: 400));
    }
    return false;
  }

  /// Bitta o'lchov qadami. Yiqilsa YOZIB QO'YADI va davom etadi.
  ///
  /// Qadam `_NoData` tashlasa — bu xato EMAS: shunchaki o'lchash uchun
  /// ma'lumot yo'q (bo'sh baza). Hisobotda alohida belgi bilan chiqadi.
  Future<void> step(
    String section,
    String name,
    Future<void> Function() body,
  ) async {
    try {
      await body();
      report.add(_Step(section, name, true, null));
    } on _NoData catch (e) {
      report.add(_Step(section, name, true, e.why, skipped: true));
    } catch (error) {
      report.add(_Step(section, name, false, '$error'.split('\n').first));
    }
  }

  testWidgets('ilova jonli backend bilan boshdan-oxir', (tester) async {
    // Sessiyani TOZADAN boshlaymiz: eski token qolsa login oqimi
    // umuman o'lchanmay qoladi.
    SharedPreferences.setMockInitialValues({'intro_seen': true});
    final prefs = await SharedPreferences.getInstance();
    final tokens = TokenStorage();
    await tokens.clear();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokens),
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const YolYolakayApp(),
      ),
    );
    await idle(tester, const Duration(seconds: 3));

    // ───────────────────────── KIRISH ─────────────────────────
    await step('Kirish', 'login ekrani ochiladi', () async {
      final ok = await waitFor(tester, find.byType(TextField));
      if (!ok) throw StateError('telefon maydoni chiqmadi');
    });

    await step('Kirish', 'telefon raqam kiritiladi', () async {
      await tester.enterText(find.byType(TextField).first, phoneDigits);
      await idle(tester, const Duration(milliseconds: 600));
    });

    await step('Kirish', 'kod so\'raladi (SMS yuboriladi)', () async {
      final button = find.widgetWithText(FilledButton, 'Kod yuborish');
      if (button.evaluate().isEmpty) throw StateError('«Kod yuborish» yo\'q');
      await tester.tap(button);
      // OTP ekrani ochilishini kutamiz — beshta katakli maydon.
      final ok = await waitFor(tester, find.text('Tasdiqlash'));
      if (!ok) throw StateError('OTP ekrani ochilmadi');
    });

    await step('Kirish', 'kod kiritilib ichkariga o\'tiladi', () async {
      await tester.enterText(find.byType(TextField).first, otpCode);
      // `onCompleted` o'zi tasdiqlaydi — tugmani bosish shart emas,
      // lekin tasdiqlash tugmasi ham bo'lsa bosamiz (ikki xil qurilmada
      // avtomatik tasdiq turlicha ishlaydi).
      await idle(tester, const Duration(seconds: 2));
      final confirm = find.widgetWithText(FilledButton, 'Tasdiqlash');
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm);
      }
      final ok = await waitFor(
        tester,
        find.byType(NavigationBar),
        timeout: const Duration(seconds: 40),
      );
      if (!ok) throw StateError('ichkariga kirmadi — pastki tab qatori yo\'q');
    });

    // Kirolmadik — qolgan hamma qadam ma'nosiz, hisobotni chiqarib
    // to'xtaymiz (aks holda 30 ta yolg'on «buzuq» yoziladi).
    final loggedIn = report.every((s) => s.ok);
    if (!loggedIn) {
      _print(report);
      fail('Kirish oqimi yiqildi — qolgan o\'lchovlar o\'tkazilmadi');
    }

    // ───────────────────────── TABLAR ─────────────────────────
    Future<void> openTab(String label) async {
      final tab = find.text(label);
      if (tab.evaluate().isEmpty) throw StateError('«$label» tabi yo\'q');
      await tester.tap(tab.last);
      await idle(tester, const Duration(seconds: 3));
    }

    /// Ekranda XATO KO'RINISHI yo'qligini tekshiradi.
    ///
    /// 🔑 Aynan shu narsa o'lchanadi: server 200 qaytargan bo'lsa ham
    /// mijoz javobni o'qiy olmasa odam shu ekranni ko'radi.
    void expectNoError(String where) {
      if (find.byType(ErrorView).evaluate().isNotEmpty) {
        throw StateError('$where — xato ko\'rinishi chiqdi');
      }
    }

    for (final tab in const [
      'Safarlarim',
      'Pochta',
      'Suhbatlar',
      'Profil',
    ]) {
      await step('Tablar', '«$tab» ochiladi va xatosiz', () async {
        await openTab(tab);
        expectNoError(tab);
      });
    }

    // ──────────────────────── PROFIL ────────────────────────
    await step('Profil', 'server ma\'lumoti ekranda ko\'rinadi', () async {
      await openTab('Profil');
      // Ism yoki telefon — biror haqiqiy maydon chizilgan bo'lsin.
      final ok = await waitFor(tester, find.textContaining('99'));
      if (!ok) throw StateError('profilda hech qanday ma\'lumot yo\'q');
    });

    await step('Profil', '⚙️ sozlamalar ochiladi', () async {
      final gear = find.byIcon(Icons.settings_outlined);
      if (gear.evaluate().isEmpty) throw StateError('⚙️ topilmadi');
      await tester.tap(gear.first);
      final ok = await waitFor(tester, find.text('Sozlamalar'));
      if (!ok) throw StateError('sozlamalar ochilmadi');
    });

    await step('Profil', 'orqaga — AYNAN bir qadam', () async {
      await tester.tap(find.byType(BackButton));
      await idle(tester, const Duration(seconds: 2));
      if (find.text('Profil').evaluate().isEmpty) {
        throw StateError('orqaga bosilgach profilga qaytmadi');
      }
    });

    // ──────────────────────── QIDIRUV ────────────────────────
    await step('Qidiruv', 'bosh ekran ochiladi', () async {
      // Birinchi tabga qaytamiz — nomi ROLGA qarab o'zgaradi
      // («Qidirish» / «Yaratish»), shuning uchun yorliq bo'yicha emas,
      // TARTIB bo'yicha bosamiz.
      //
      // 🔴 07.09.2026: bu yerda `find.byType(InkWell)` turardi va
      // o'lchov «Bad state: No element» bilan yiqilgandi. Ilova emas,
      // TEST xato edi: Material'ning `NavigationBar` i ichida InkWell
      // YO'Q — u `_IndicatorInkWell` ni ishlatadi, u esa `InkResponse`
      // dan meros oladi va `byType(InkWell)` uni KO'RMAYDI.
      final dest = find.byType(NavigationDestination);
      if (dest.evaluate().isEmpty) throw StateError('tab qatori yo\'q');
      await tester.tap(dest.first);
      await idle(tester, const Duration(seconds: 2));

      // 🔑 Bosish YETMAYDI — ekran haqiqatan chizilganini tekshiramiz.
      // Ilgari bu qadam faqat bosardi va hech nima tasdiqlamasdi: tab
      // ochilmay qolsa ham «✅» yozilaverardi.
      final ok = await waitFor(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data == 'Qayerga boramiz?' || w.data == 'E\'lon berish'),
        ),
      );
      if (!ok) {
        throw StateError('birinchi tab ochilmadi — na qidiruv, na e\'lon ekrani');
      }
      expectNoError('bosh ekran');
    });

    // ═════════════════ CHUQUR ZANJIR (rejimga qarab) ═════════════════
    //
    // 🔴 NEGA CHUQURROQ (07.09.2026): oldingi o'lchov faqat TABLARNI
    // ochib ko'rardi. Bizni ikki marta urgan xato turi esa chuqurroqda
    // yashiringan edi — server 200 qaytaradi, testlar yashil, ekranda
    // esa hech narsa yo'q («Yetkazdim» tugmasi uch hafta chiqmagan,
    // xaritadagi mashina jimgina yo'qolgan).
    //
    // 🔴 VA BIRINCHI URINISHDA ADASHDIM: o'lchov yo'lovchi rejimini
    // FARAZ qilgandi, sinov akkaunti esa HAYDOVCHI rejimida turgan
    // ekan. «Qidirish tugmasi yo'q» degan qizil aslida «ekranda e'lon
    // berish formasi turibdi» degani edi. Endi rejim ANIQLANADI.

    /// Pastki menyuli QOBIQQA qaytaradi.
    ///
    /// 🔴 07.09.2026: qidiruv natijalari va safar tafsiloti qobiq
    /// USTIDAN ochiladi va ularda pastki menyu YO'Q. Men undan
    /// chiqmasdan tab qidiravergandim — ketma-ket to'rtta qadam
    /// «tab yo'q» deb yiqilgandi. Xato ilovada emas, o'lchovda edi.
    Future<void> returnToShell(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        if (find.byType(NavigationBar).evaluate().isNotEmpty) return;
        final back = find.byType(BackButton);
        if (back.evaluate().isEmpty) return;
        await tester.tap(back.first);
        await idle(tester, const Duration(seconds: 2));
      }
    }

    /// Hozir haydovchi rejimimi — pastki tabdagi nom bilan aniqlanadi.
    bool driverMode() => find.text('Yaratish').evaluate().isNotEmpty;

    final startedAsDriver = driverMode();

    // ─────────── MASHINALAR (haydovchi rejimida) ───────────
    await step('Profil', 'mashinalar ro\'yxati ochiladi', () async {
      if (!startedAsDriver) {
        throw _NoData('akkaunt yo\'lovchi rejimida — mashinalar bo\'limi yo\'q');
      }
      // 🔑 Mashinalar PROFILDA emas, ⚙️ SOZLAMALAR ichida — 02.09 dagi
      // qayta tartiblashdan keyin shunday (o'lchov buni bilmasdi va
      // «Mashinalarim yo'q» deb yiqilgandi).
      await openTab('Profil');
      final gear = find.byIcon(Icons.settings_outlined);
      if (gear.evaluate().isEmpty) throw StateError('⚙️ topilmadi');
      await tester.tap(gear.first);
      await idle(tester, const Duration(seconds: 2));

      final cars = find.text('Mashinalarim');
      if (!await scrollTo(tester, cars)) {
        throw StateError('«Mashinalarim» yo\'q. Ekranda: ${screenTexts(tester)}');
      }
      await tester.tap(cars.first);
      await idle(tester, const Duration(seconds: 4));
      expectNoError('mashinalar');
      await returnToShell(tester);
    });

    // ─────────── REJIMNI ALMASHTIRISH ───────────
    //
    // 🔑 Bu qadamning O'ZI ham o'lchov: rejim almashtirish ilovaning
    // eng katta tugmasi va u ilgari onboarding'ga uloqtirib yuborgan.
    /// 🔴 07.09.2026: tugmani TO'LIQ matn bo'yicha qidirgandim va u
    /// «topilmadi» bo'lardi. Matnda ikkita apostrof bor
    /// («Yo'lovchi rejimiga o'tish») — bunday satrni testda aynan
    /// takrorlash mo'rt. Endi BO'LAK bo'yicha qidiriladi.
    Future<bool> switchMode(String fragment, String expectedTab) async {
      await openTab('Profil');
      final button = find.textContaining(fragment);
      if (!await scrollTo(tester, button)) return false;
      await tester.tap(button.first, warnIfMissed: true);
      await idle(tester, const Duration(seconds: 4));
      return await waitFor(tester, find.text(expectedTab));
    }

    await step('Rejim', 'yo\'lovchi rejimiga o\'tiladi', () async {
      if (!startedAsDriver) throw _NoData('akkaunt allaqachon yo\'lovchi rejimida');
      if (!await switchMode('lovchi rejimiga', 'Qidirish')) {
        throw StateError('rejim almashmadi. Ekranda: ${screenTexts(tester)}');
      }
    });

    // ─────────── QIDIRUV → SAFAR (yo'lovchi) ───────────

    /// Shahar tanlash oynasi: maydonni bosadi, yozadi, ro'yxatdan tanlaydi.
    Future<void> pickCity(String label, String query) async {
      final field = find.text(label);
      if (field.evaluate().isEmpty) throw StateError('«$label» maydoni yo\'q');
      await tester.tap(field.first);
      await idle(tester, const Duration(seconds: 1));

      final input = find.byType(TextField);
      if (input.evaluate().isEmpty) throw StateError('shahar qidiruvi ochilmadi');
      await tester.enterText(input.first, query);
      await idle(tester, const Duration(seconds: 2));

      final tile = find.ancestor(
        of: find.textContaining(query),
        matching: find.byType(ListTile),
      );
      if (tile.evaluate().isEmpty) throw StateError('«$query» ro\'yxatda yo\'q');
      await tester.tap(tile.first);
      await idle(tester, const Duration(seconds: 1));
    }

    await step('Qidiruv', 'shaharlar tanlanadi (Toshkent → Samarqand)',
        () async {
      // Birinchi tabga — qidiruv ekraniga qaytamiz.
      await tester.tap(find.byType(NavigationDestination).first);
      await idle(tester, const Duration(seconds: 2));
      await pickCity('Qayerdan', 'Toshkent');
      await pickCity('Qayerga', 'Samarqand');
    });

    await step('Qidiruv', 'natijalar ochiladi — XATO ko\'rinishi yo\'q',
        () async {
      final button = find.widgetWithText(FilledButton, 'Qidirish');
      if (button.evaluate().isEmpty) {
        throw StateError('«Qidirish» yo\'q. Ekranda: ${screenTexts(tester)}');
      }
      await tester.tap(button.first);
      await idle(tester, const Duration(seconds: 6));
      expectNoError('natijalar');

      // 🔑 Bo'sh natija ham TO'G'RI javob: yo'nalishda safar bo'lmasligi
      // mumkin. Xato — ekranda NA ro'yxat, NA halol bo'sh holat bo'lishi.
      final cards = find.byType(RideCard);
      final empty = find.byType(EmptyView);
      if (cards.evaluate().isEmpty && empty.evaluate().isEmpty) {
        throw StateError('na safar, na bo\'sh holat. Ekranda: ${screenTexts(tester)}');
      }
    });

    await step('Safar', 'kartochka bosilsa tafsilot chiziladi', () async {
      final cards = find.byType(RideCard);
      if (cards.evaluate().isEmpty) {
        throw _NoData('bu yo\'nalishda hozir safar yo\'q (bo\'sh holat chizildi)');
      }
      await tester.tap(cards.first);
      await idle(tester, const Duration(seconds: 5));
      expectNoError('safar tafsiloti');
      final priced = await waitFor(tester, find.textContaining('so\'m'));
      if (!priced) throw StateError('tafsilotda narx ko\'rinmadi');
      // Tafsilot ham, natijalar ham qobiq USTIDA — ikkalasidan chiqamiz.
      await returnToShell(tester);
    });

    // ─────────── POCHTA (yo'lovchi ko'rinishi) ───────────
    //
    // ⚠️ Forma FAQAT OCHILADI, YUBORILMAYDI: o'lchov prodga boradi va
    // har haydashda soxta posilka qoldirish bazani axlat qiladi.
    await step('Pochta', 'yuborish formasi ochiladi (yuborilmaydi)', () async {
      // Safar topilmasa oldingi qadam o'tkazib yuboriladi va biz hamon
      // natijalar ekranida turgan bo'lamiz — qobiqqa qaytamiz.
      await returnToShell(tester);
      await openTab('Pochta');
      expectNoError('pochta');
      final send = find.textContaining('Pochta yuborish');
      if (!await scrollTo(tester, send, steps: 4)) {
        throw StateError('«Pochta yuborish» yo\'q. Ekranda: ${screenTexts(tester)}');
      }
      await tester.tap(send.first);
      await idle(tester, const Duration(seconds: 3));
      expectNoError('posilka formasi');
      await returnToShell(tester);
    });

    // ─────────── SUHBAT ───────────
    await step('Suhbatlar', 'suhbat ochiladi va xabarlar chiziladi', () async {
      await openTab('Suhbatlar');
      expectNoError('suhbatlar');
      final tiles = find.byType(ListTile);
      if (tiles.evaluate().isEmpty) {
        throw _NoData('ro\'yxat bo\'sh. Ekranda: ${screenTexts(tester)}');
      }
      await tester.tap(tiles.first);
      await idle(tester, const Duration(seconds: 5));
      expectNoError('yozishma');
      if (find.byType(TextField).evaluate().isEmpty) {
        throw StateError('yozishma ochilmadi (kiritish maydoni yo\'q)');
      }
      await returnToShell(tester);
    });

    // ─────────── REJIM QAYTARILADI ───────────
    //
    // 🔴 SHART: o'lchov akkauntni O'ZGARTIRIB QOLDIRMASLIGI kerak.
    // Sinov akkaunti haydovchi rejimida turgan bo'lsa, keyingi o'lchov
    // (va probe) ham shundan boshlanadi deb hisoblaydi.
    await step('Rejim', 'haydovchi rejimi QAYTARILADI', () async {
      if (!startedAsDriver) throw _NoData('rejim o\'zgartirilmagan edi');
      if (!await switchMode('Haydovchi rejimiga', 'Yaratish')) {
        throw StateError('rejim qaytarilmadi. Ekranda: ${screenTexts(tester)}');
      }
    });

    // ───────────────────── BILDIRISHNOMALAR ─────────────────────
    await step('Bildirishnomalar', 'qo\'ng\'iroqcha ochiladi', () async {
      final bell = find.byIcon(Icons.notifications_none);
      if (bell.evaluate().isEmpty) throw StateError('qo\'ng\'iroqcha yo\'q');
      await tester.tap(bell.first);
      await idle(tester, const Duration(seconds: 3));
      expectNoError('bildirishnomalar');
      await tester.tap(find.byType(BackButton));
      await idle(tester, const Duration(seconds: 2));
    });

    _print(report);

    final broken = report.where((s) => !s.ok).toList();
    expect(
      broken,
      isEmpty,
      reason: broken.map((s) => '${s.name}: ${s.error}').join('\n'),
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}

class _Step {
  _Step(this.section, this.name, this.ok, this.error, {this.skipped = false});
  final String section;
  final String name;
  final bool ok;
  final String? error;

  /// «O'LCHANMADI» — ma'lumot yo'qligi uchun (masalan bazada suhbat yo'q).
  ///
  /// 🔴 NEGA ALOHIDA HOLAT: bunday qadamni «buzuq» deb yozsak, bo'sh
  /// bazada o'lchov qip-qizil chiqadi va biz haqiqiy xatoni SHOVQIN
  /// ichida yo'qotamiz. «Ishlaydi» deb yozsak esa undan ham yomon —
  /// tekshirilmagan narsa tekshirilgandek ko'rinadi.
  final bool skipped;
}

void _print(List<_Step> report) {
  debugPrint('\n${'─' * 60}');
  debugPrint('  ILOVA — JONLI O\'LCHOV (${Env.apiBaseUrl})');
  debugPrint('─' * 60);
  String? section;
  for (final s in report) {
    if (s.section != section) {
      section = s.section;
      debugPrint('\n$section');
    }
    final mark = s.skipped ? '⏭️' : (s.ok ? '✅' : '🔴');
    final tail = s.skipped
        ? ' — o\'lchanmadi: ${s.error}'
        : (s.ok ? '' : ' — ${s.error}');
    debugPrint('  $mark ${s.name}$tail');
  }
  final ok = report.where((s) => s.ok && !s.skipped).length;
  final skipped = report.where((s) => s.skipped).length;
  debugPrint('\n${'─' * 60}');
  debugPrint(
    '  Qadam: ${report.length} · ishlaydi: $ok · '
    'buzuq: ${report.length - ok - skipped} · o\'lchanmadi: $skipped',
  );
  debugPrint('${'─' * 60}\n');
}

/// «Ma'lumot yo'q» — qadam o'lchanmadi, lekin bu XATO emas.
class _NoData implements Exception {
  _NoData(this.why);
  final String why;
  @override
  String toString() => why;
}

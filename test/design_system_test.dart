import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';

/// O'lchov tizimining QO'RIQCHISI.
///
/// 2026-08-13 da ekranlarda vertikal bo'shliqning 15 xil qiymati va temadan
/// tashqarida qo'lda yozilgan 7 xil radius bor edi. Ular `AppSpace`/`AppRadius`
/// ga keltirildi — bu test o'shanga qaytib ketmasligi uchun.
///
/// NEGA TEST: qoidani izohga yozib qo'yish yetmaydi, chunki keyingi ekranni
/// yozayotgan odam (yoki men) izohni o'qimasligi mumkin. Yiqilgan test esa
/// e'tibordan qochmaydi.
void main() {
  _displayFontTests();
  _noEmojiInUiTests();
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// Fayl va qator raqami bilan buzilish ro'yxati — xabar tushunarli bo'lsin.
  List<String> findViolations(RegExp pattern, {String? skipFile}) {
    final hits = <String>[];
    for (final file in dartFiles) {
      if (skipFile != null && file.path.endsWith(skipFile)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          hits.add('${file.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    return hits;
  }

  test('radius qo\'lda yozilmaydi — AppRadius ishlatiladi', () {
    // `dimens.dart` ning o'zida raqam bo'lishi TABIIY — u manba.
    //
    // 🔴 Ilgari bu tekshiruv FAQAT `BorderRadius.circular` ni ko'rardi va
    // `Radius.circular` (burchakma-burchak radius) undan o'tib ketardi —
    // chat pufagi va profil sarlavhasi shu yo'l bilan tizimdan tashqarida
    // qolgan edi. Ikkalasi ham ushlanadi.
    final hits = findViolations(
      RegExp(
        r'\bBorderRadius\.circular\(\s*\d|(?<!Border)\bRadius\.circular\(\s*\d',
      ),
      skipFile: 'dimens.dart',
    );
    expect(
      hits,
      isEmpty,
      reason:
          'Radius uchun raqam yozilgan. AppRadius.card / control / badge / '
          'pill dan birini tanlang — qaysi ROL ekaniga qarab:\n${hits.join('\n')}',
    );
  });

  test('bo\'shliq shkaladan tashqariga chiqmaydi', () {
    // Bir argumentli `SizedBox(height: N)` — bu ANIQ bo'shliq. Ikki
    // argumentlisi (`height: 20, width: 20`) o'lcham, unga tegilmaydi.
    //
    // 64 dan katta qiymat ham bo'shliq EMAS: bu rasm o'rni yoki element
    // balandligi (`SizedBox(height: 160)` — yuklanmagan surat joyi).
    // Ularni shkalaga tiqishtirish mantiqsiz bo'lardi.
    final hits = findViolations(
      RegExp(r'SizedBox\((height|width): ([0-9]|[1-5][0-9]|6[0-4])\)'),
      skipFile: 'dimens.dart',
    );
    expect(
      hits,
      isEmpty,
      reason:
          'Bo\'shliq uchun raqam yozilgan. AppSpace.xs/sm/md/lg/xl/xxl/huge '
          'dan birini oling:\n${hits.join('\n')}',
    );
  });

  test('EdgeInsets.all raqam bilan yozilmaydi', () {
    final hits = findViolations(
      RegExp(r'EdgeInsets\.all\(\s*\d'),
      skipFile: 'dimens.dart',
    );
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('CLASSIC karta chegarasi qaytib kelmasin', () {
    // Qoida: CLASSIC uslub kartasi chegarasiz, chuqurlik soyadan.
    // NEON uslub esa ATAYIN neon chegara bilan (egasi, 2026-08-20) — shu
    // sabab `side:` bo'lса ham, u FAQAT `neon` shartли bo'lishi kerak.
    // Shartsiz `side:` classic'ni ham buzadi va o'shani tutamiz.
    final theme = File('lib/app/theme.dart').readAsStringSync();
    final cardTheme = theme.substring(
      theme.indexOf('cardTheme:'),
      theme.indexOf('filledButtonTheme:'),
    );
    // `side:` bor bo'lса, o'sha satrдан oldин `neon` bo'lishi shart.
    final sideIndex = cardTheme.indexOf('side:');
    if (sideIndex != -1) {
      final around = cardTheme.substring(
        sideIndex,
        cardTheme.indexOf(')', sideIndex) + 1,
      );
      expect(
        around.contains('neon'),
        isTrue,
        reason:
            'Karta chegarasi neon shartига bog\'lanмаган — classic buziladi',
      );
    }
  });
}

/// Brend shrifti zaxira zanjirini O'CHIRIB QO'YMASIN.
///
/// Fraunces'da kirill umuman yo'q, shuning uchun kirill matn tizim shriftiga
/// tushishi kerak — `fontFamilyFallback: const []` esa buni to'sadi.
///
/// ⚠️ Bu qoida "ruscha ismdan `й` tushib qolyapti" degan xato tashxisdan
/// keyin yozilgan; o'sha nosozlikning sababi boshqa bo'lib chiqdi
/// (ma'lumotda `й` yo'q edi). Qoida shunday ham to'g'ri.
void _displayFontTests() {
  /// 🔴 SARLAVHA SHRIFTI OILANI O'ZGARTIRMAYDI (2026-09-02).
  ///
  /// Ilgari sarlavhalar Fraunces (serif) bilan chizilardi va unda kirill
  /// UMUMAN yo'q edi (o'lchandi: 0 ta belgi). Ya'ni ruscha va o'zbek
  /// kirilidagi har qanday sarlavha tizim shriftiga tushib ketardi —
  /// bitta ekranda ikki xil shrift ko'rinardi.
  ///
  /// 🔑 Bu xatoni na `analyze`, na oddiy test ko'radi: matn chiziladi,
  /// faqat BOSHQA shrift bilan. Shuning uchun qoida test bilan
  /// mahkamlanadi — kimdir «brendli ko'rinsin» deb yana serif qo'ymasin.
  test('sarlavha uslubi shrift OILASINI almashtirmaydi', () {
    final style = displayFontStyle(const TextStyle());
    expect(
      style.fontFamily,
      isNull,
      reason:
          'sarlavhaga alohida oila berilsa, unda kirill bor-yo\'qligi '
          'tekshirilmagan bo\'ladi va ruscha interfeys jimgina buziladi',
    );
    // Sarlavhalik QALINLIK va ZICHLIK bilan beriladi.
    expect(style.fontWeight, FontWeight.w800);
    expect(style.letterSpacing, lessThan(0));
  });
}

/// Interfeysda EMOJI ishlatilmaydi.
///
/// 🔴 Egasi qurilmada aytdi (2026-08-13): "emoji bo'lgani uchun chiroyli
/// chiqmayapti". Sabab texnik ham: emoji har telefonda boshqacha chiziladi
/// (Samsung, Google, Xiaomi — uch xil rasm), rangi mavzuga bo'ysunmaydi va
/// yonidagi chiziqli ikonkalar bilan bir uslubda ko'rinmaydi.
///
/// IZOHLARDAGI emoji (🔴 ⚠️ ✅) tegilmaydi — ular kodni o'qiydigan odam
/// uchun, ekranga chiqmaydi.
void _noEmojiInUiTests() {
  test('Text() ichida emoji yo\'q — Material ikonkalari ishlatiladi', () {
    final hits = <String>[];
    // Emoji oralig'i: belgilar, ranglar, transport, bayroqlar.
    final emoji = RegExp(
      r"""Text\(\s*'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}]""",
      unicode: true,
    );
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//') || line.startsWith('///')) continue;
        if (emoji.hasMatch(lines[i])) {
          hits.add('${file.path}:${i + 1}  $line');
        }
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Emoji o\'rniga Material ikonkasi qo\'ying (RideBadgeIcon yoki '
          'Icon(...)):\n${hits.join('\n')}',
    );
  });

  /// RANG QO'LDA YOZILMAYDI — nomi bo'lsin.
  ///
  /// 🔴 O'LCHAB TOPILDI (2026-09-03): reyting yulduzining oltini
  /// (`0xFFF5A623`) BESHTA faylda, «bajarildi» yashili
  /// (`0xFF1FA971`) IKKITA faylda qo'lda yozilgan edi. Bittasida bir
  /// belgi xato bo'lsa ilovada ikki xil oltin paydo bo'lardi va buni
  /// hech qanday test tutmasdi — ko'z esa 5 ekranni yonma-yon
  /// solishtira olmaydi.
  ///
  /// ⚠️ `lib/app/theme.dart` ISTISNO: rang ta'riflari o'sha yerda.
  test('brend ranglari qo\'lda yozilmaydi', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path == 'lib/app/theme.dart') continue;
      // Naqsh fayllari — xonatlas ranglari (mato, temaga bog'liq emas).
      if (file.path.contains('/brand/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final hex in const ['0xFFF5A623', '0xFF1FA971']) {
          if (lines[i].contains(hex)) {
            offenders.add('${file.path}:${i + 1}  ${lines[i].trim()}');
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Brend rangi qo\'lda yozilgan. `BrandColors.star` yoki '
          '`BrandColors.success` ishlating:\n${offenders.join('\n')}',
    );
  });
}

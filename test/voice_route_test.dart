import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/voice_route.dart';

/// Ovozli yo'nalish tahlili — web'dagi `voiceRoute.ts` bilan BIR XIL
/// misollarda tekshiriladi. Ikkala mijoz bir gapni bir xil tushunishi shart:
/// aks holda odam saytda aytgan gapni ilovada takrorlab, boshqa natija oladi.
void main() {
  void expectRoute(String text, String? from, String? to) {
    final route = parseVoiceRoute(text);
    expect(route?.from?.name, from, reason: '"$text" — jo\'nash');
    expect(route?.to?.name, to, reason: '"$text" — manzil');
  }

  group('o\'zbekcha kelishik', () {
    test('to\'liq gap', () {
      expectRoute('Toshkentdan Samarqandga', 'Toshkent', 'Samarqand');
    });

    test('qo\'shimchasiz — aytilish tartibi', () {
      expectRoute('Toshkent Samarqand', 'Toshkent', 'Samarqand');
    });

    test('yarim qo\'shimcha', () {
      expectRoute('Toshkentdan Samarqand', 'Toshkent', 'Samarqand');
    });

    /// 🔴 ENG MUHIM HOLAT: grammatika TARTIBDAN ustun. Ilgari (saytda)
    /// tartibga tayanilardi va bunday gap teskari tushunilardi.
    test('teskari tartib — grammatika ustun', () {
      expectRoute('Samarqandga Toshkentdan boraman', 'Toshkent', 'Samarqand');
    });

    test('apostrofli nom', () {
      expectRoute("Farg'onadan Toshkentga", "Farg'ona", 'Toshkent');
    });

    test('apostrofsiz yozilgan nom ham tanilsin', () {
      expectRoute('Fargonadan Toshkentga', "Farg'ona", 'Toshkent');
    });

    test('«gacha» ham manzil', () {
      expectRoute('Qo‘qondan Toshkentgacha', "Qo'qon", 'Toshkent');
    });

    test('ortiqcha so\'zlar xalaqit bermaydi', () {
      expectRoute('Andijondan Namanganga ketaman', 'Andijon', 'Namangan');
    });
  });

  group('rus va ingliz', () {
    test('ruscha old ko\'makchi', () {
      expectRoute('из Ташкента в Самарканд', 'Toshkent', 'Samarqand');
    });

    test('ruscha ko\'makchisiz', () {
      expectRoute('Ташкент Самарканд', 'Toshkent', 'Samarqand');
    });

    test('inglizcha', () {
      expectRoute('from Tashkent to Samarkand', 'Toshkent', 'Samarqand');
    });
  });

  group('yarim va bo\'sh natija', () {
    test('faqat manzil aytildi', () {
      expectRoute('Samarqandga', null, 'Samarqand');
    });

    test('faqat jo\'nash aytildi', () {
      expectRoute('Toshkentdan', 'Toshkent', null);
    });

    /// Qo'shimchasiz bitta nom — jo'nash deb olinadi (eski xatti-harakat:
    /// ovoz tugmasi "qayerdan" maydonining yonida turadi).
    test('qo\'shimchasiz bitta nom — jo\'nash', () {
      expectRoute('Toshkent', 'Toshkent', null);
    });

    test('shahar yo\'q — null', () {
      expect(parseVoiceRoute('salom qalaysiz'), isNull);
    });

    test('bo\'sh matn — null', () {
      expect(parseVoiceRoute('   '), isNull);
    });
  });

  /// Nomning O'ZI kelishikka o'xshash harflar bilan tugasa, u qo'shimcha deb
  /// kesilmasligi kerak: aynan mos kelish AVVAL tekshiriladi.
  test('nom oxiridagi harflar qo\'shimcha deb o\'qilmasin', () {
    final route = parseVoiceRoute('Nurota');
    expect(route?.from?.name, 'Nurota');
  });

  test('bir xil shahar ikki marta — ikkinchi joy bo\'sh qoladi', () {
    expectRoute('Toshkent Toshkent', 'Toshkent', null);
  });

  /// 🔴 EGASI, 2026-08-25: «ovozdan olingan natija qidiruvga qo'yilmayapti».
  ///
  /// Ikki alohida sabab topilgan edi, ikkalasi ham shu yerda qulflanadi.
  group('ovoz — qurilma qanday yozsa, shunday tushunilsin', () {
    /// SABAB 1: Android nutqni tanish `uz` tilida KIRILL qaytaradi, joylar
    /// ro'yxatida esa o'zbek kirilli umuman yo'q edi. Ya'ni o'zbekcha
    /// aytilgan yo'nalish deyarli har doim tanilmasdi.
    test('o\'zbek kirilli — yo\'nalish to\'liq tanilsin', () {
      expectRoute('Тошкентдан Самарқандга', 'Toshkent', 'Samarqand');
      expectRoute('Фарғонадан Тошкентга', "Farg'ona", 'Toshkent');
      expectRoute('Бухородан Андижонга', 'Buxoro', 'Andijon');
      expectRoute('Қўқондан Урганчга', "Qo'qon", 'Urganch');
    });

    test('o\'zbek kirilli — TARTIB emas, grammatika ustun', () {
      expectRoute('Самарқандга Тошкентдан', 'Toshkent', 'Samarqand');
    });

    /// SABAB 2: nutqni tanish qo'shimchani nomdan AJRATIB yozadi. Belgisi
    /// yo'q deb hisoblanib, aytilish tartibiga tushardi — va teskari
    /// natija berardi.
    test('qo\'shimcha alohida so\'z bo\'lsa ham yo\'nalish saqlansin', () {
      expectRoute('Toshkent dan Samarqand ga', 'Toshkent', 'Samarqand');
      expectRoute('Samarqand ga Toshkent dan', 'Toshkent', 'Samarqand');
      expectRoute('Тошкент дан Самарқанд га', 'Toshkent', 'Samarqand');
    });

    /// Eski xatti-harakat buzilmagan bo'lsin: ruscha va inglizcha old
    /// ko'makchilari avvalgidek ishlaydi.
    test('rus va ingliz avvalgidek', () {
      expectRoute('из Ташкента в Самарканд', 'Toshkent', 'Samarqand');
      expectRoute('from Tashkent to Samarkand', 'Toshkent', 'Samarqand');
    });
  });
}

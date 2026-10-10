import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// EKRANDAGI MATNDA ICHKI ATAMA BO'LMASIN.
///
/// 🔴 NEGA (2026-09-02 ko'rigi): «Daromadim» ekranida haydovchiga
/// quyidagi jumla ko'rinardi:
///
///     «Backend hozircha oy yoki hafta bo'yicha bo'linish bermaydi»
///
/// Haydovchi «backend» nima ekanini bilmaydi — bu bizning ichki
/// tilimiz. Cheklovning O'ZI rost edi, faqat uni odam tilida aytish
/// kerak. Yana ikki joyda shunday edi: posilkani topshirishni
/// tasdiqlashda «Avval serverga yozishga urinamiz» va xatoda
/// «Server bu amalni qabul qilmadi».
///
/// 🔑 Bunday matn tabiiy paydo bo'ladi: biz cheklovni backend xatida
/// muhokama qilamiz va o'sha jumlani to'g'ridan-to'g'ri ekranga
/// ko'chiramiz. Shuning uchun qorovul kerak.
void main() {
  test('foydalanuvchi matnida ichki atama yo\'q', () {
    final src = File('lib/l10n/strings.dart').readAsStringSync();

    // Izohlar TEKSHIRILMAYDI — ular dasturchi uchun va u yerda
    // «backend» so'zi to'g'ri va kerakli.
    final code = src
        .replaceAll(RegExp(r'//[^\n]*'), '')
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

    /// Ekranda TURMASLIGI kerak bo'lgan so'zlar.
    const banned = [
      'backend',
      'бэкенд',
      'endpoint',
      'swagger',
      'stacktrace',
      'exception',
      'nullptr',
    ];

    final literals = RegExp(r"'((?:[^'\\]|\\.)*)'").allMatches(code);
    final violations = <String>[];
    for (final m in literals) {
      final text = m.group(1)!;
      // `import 'package:...'` kabi qatorlar matn emas.
      if (text.startsWith('package:') || text.startsWith('dart:')) continue;
      final low = text.toLowerCase();
      for (final word in banned) {
        if (low.contains(word)) {
          violations.add(
            '«$word» → "${text.length > 90 ? '${text.substring(0, 90)}…' : text}"',
          );
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'ekranga chiqadigan matnda ichki atama bor — odam tilida '
          'qayta yozing:\n${violations.join('\n')}',
    );
  });
}

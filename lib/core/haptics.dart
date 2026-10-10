import 'dart:async';

import 'package:flutter/services.dart';

/// Sezilarli amallarда yengil tebranish — ilova "native" his beradi.
///
/// 🔴 Egasi (2026-08-20): muhim amallarда tebranish. Flutter'ning O'Z
/// `HapticFeedback`i — qo'shimcha paket kerak emas. Har amal turi uchun
/// mos kuch: tasodifiy tebranish ma'nosini yo'qotadi.
///
/// KAM ISHLATILADI: har bosishда emas, faqat NATIJA bo'lган amalда
/// (yuborildi, band qilindi, xato, xavf). Aks holда tebranish "shovqin"
/// bo'lib, o'z ma'nosini yo'qotadi.
abstract final class AppHaptics {
  /// Muvaffaqiyatли amal — xabar yuborildi, yangilandi.
  static void success() => HapticFeedback.lightImpact();

  /// E'tibor talab — ariza keldi, band qilindi.
  static void notice() => HapticFeedback.mediumImpact();

  /// Xato yoki qaytarib bo'lmaydigan/xavfli amal — SOS, o'chirish.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Tanlov — segment/tab almashishi. Eng yengil.
  static void select() => HapticFeedback.selectionClick();

  // ===== NAQSHLAR: bir zarba emas, KETMA-KETLIK =====
  //
  // 🔴 NEGA KERAK (2026-08-25): to'rt kuch bilan faqat "qanchalik muhim"
  // deyish mumkin, "NIMA bo'ldi" deyish mumkin emas. Bron tasdiqlanishi
  // ham, bekor qilinishi ham bir xil tebranish berardi — ya'ni telefon
  // cho'ntakda turganda ikkalasi FARQLANMASDI.
  //
  // Naqsh esa ma'no tashiydi va uni ko'zga qaramasdan tanish mumkin:
  //   • tasdiq  — yengildan og'irga ko'tariladi (dvigatel yurishi);
  //   • bekor   — og'irdan yengilga tushadi (to'xtash).
  //
  // Oraliq 90 ms: undan qisqasi bitta uzun tebranishga qo'shilib ketadi,
  // uzunrog'i esa ikki alohida hodisadek eshitiladi.
  static const _gap = Duration(milliseconds: 90);

  /// BRON TASDIQLANDI / safar boshlandi — ko'tariluvchi uch zarba.
  ///
  /// Bu ilovadagi eng quvonarli xabar va u shunday HIS qilinishi kerak.
  static Future<void> confirmed() async {
    HapticFeedback.selectionClick();
    await Future<void>.delayed(_gap);
    HapticFeedback.lightImpact();
    await Future<void>.delayed(_gap);
    HapticFeedback.mediumImpact();
  }

  /// BEKOR QILINDI / rad etildi — tushuvchi ikki zarba.
  ///
  /// Ataylab qisqaroq: yomon xabarni cho'zish shafqatsizlik.
  static Future<void> cancelled() async {
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(_gap);
    HapticFeedback.selectionClick();
  }
}

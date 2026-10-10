/// Rasm yasagichlar uchun shrift yuklash.
///
/// NEGA KERAK: sinov muhitida hech qanday shrift ulanmagan — matn ham,
/// ikonka ham QORA KVADRATCHA bo'lib chiziladi. Rasmning butun ma'nosi
/// ko'rsatishda bo'lgani uchun bu yaroqsiz.
///
/// Shriftlar Flutter SDK'sining O'ZIDAN olinadi (`material_fonts`) — ya'ni
/// ilova Androidda ishlatadigan AYNAN o'sha Roboto va ikonka shrifti.
/// Tizimdagi boshqa shrift bilan rasm "o'xshash" bo'lardi, lekin bir xil emas.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter SDK'dagi shriftlar papkasi. Snap orqali o'rnatilgan SDK'da yo'l
/// boshqacha, shuning uchun bir nechta joy tekshiriladi.
Directory? _materialFontsDir() {
  final home = Platform.environment['HOME'] ?? '';
  final candidates = [
    if (Platform.environment['FLUTTER_ROOT'] != null)
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts',
    '$home/snap/flutter/common/flutter/bin/cache/artifacts/material_fonts',
    '$home/flutter/bin/cache/artifacts/material_fonts',
    '/opt/flutter/bin/cache/artifacts/material_fonts',
  ];
  for (final path in candidates) {
    final dir = Directory(path);
    if (dir.existsSync()) return dir;
  }
  return null;
}

/// Roboto (uch qalinlikda) va Material ikonkalarini yuklaydi.
///
/// Shriftlar topilmasa JIM o'tadi: rasm kvadratchalar bilan chiqadi, lekin
/// sinov yiqilmaydi — bu yasagich, tekshirgich emas.
Future<void> loadPreviewFonts() async {
  final dir = _materialFontsDir();
  if (dir == null) return;

  Future<ByteData> read(String name) => File(
    '${dir.path}/$name',
  ).readAsBytes().then((b) => b.buffer.asByteData());

  // Qalinliklar ALOHIDA yuklanadi: faqat Regular yuklansa, qalin sarlavha
  // (`fontWeight: w700`) mos shrift topolmay yana kvadratchaga aylanadi.
  final roboto = FontLoader('Roboto')
    ..addFont(read('Roboto-Regular.ttf'))
    ..addFont(read('Roboto-Medium.ttf'))
    ..addFont(read('Roboto-Bold.ttf'));
  await roboto.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();

  /*
   * 🔴 ILOVANING O'Z SHRIFTI — INTER (2026-09-08).
   *
   * Ilgari rasmlar Roboto'da chizilardi, ilova esa Inter bilan
   * chiqadi. Ya'ni do'kondagi skrinshot foydalanuvchi ko'radigan
   * ekrandan BOSHQA shriftda edi.
   *
   * Buni ko'z bilan qaraganda topdim: «Toshkent → Samarqand» chipida
   * strelka o'rniga QORA KVADRATCHA turgandi. SDK'dagi Roboto
   * nusxasida U+2192 yo'q ekan; Inter'da esa bor (o'lchandi).
   *
   * Fayl ilovaning O'ZIDAN olinadi, ya'ni shrift almashsa rasm ham
   * avtomatik o'zgaradi.
   */
  final inter = File('assets/fonts/Inter-var.ttf');
  if (inter.existsSync()) {
    final loader = FontLoader('Inter')
      ..addFont(
        inter.readAsBytes().then((b) => b.buffer.asByteData()),
      );
    await loader.load();
  }

  // ⚠️ FRAUNCES OLIB TASHLANDI (2026-09-02): sarlavha shrifti endi
  // interfeys shriftining O'ZI, faqat qalinroq va zichroq
  // (`displayFontStyle`). Shu sababli bu yerda alohida yuklash kerak
  // emas — Inter allaqachon yuklangan.
  //
  // 🔑 Sabab: Fraunces'da kirill YO'Q edi (o'lchandi — 0 ta belgi) va
  // ruscha sarlavhalar tizim shriftiga tushib ketardi.
}

/// Faqat RASM uchun tuzatish — ilova kodiga aloqasi yo'q.
///
/// Temadagi ba'zi yozuvlar (AppBar sarlavhasi, tugma matni, Chip yorlig'i)
/// o'z `TextStyle`iga ega, lekin ularda shrift OILASI ko'rsatilmagan.
/// Qurilmada bu muammo emas: tizim standart oilani beradi. Sinovda esa
/// standart oila yo'q va o'sha yozuvlar QORA BLOK bo'lib chiziladi.
///
/// Ikkala rasm yasagich ham shu funksiyani chaqiradi — ilgari nusxasi
/// faqat bittasida bor edi va ikkinchisining rasmlari bloklar bilan
/// chiqardi.
ThemeData withPreviewFont(ThemeData base) {
  // Ilovadagi bilan AYNI oila (`kUiFont`). Roboto edi — rasm ilovadan
  // boshqacha ko'rinardi (izohi `loadPreviewFonts` da).
  const family = 'Inter';
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: family,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: (base.chipTheme.labelStyle ?? const TextStyle()).copyWith(
        fontFamily: family,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: family,
          ),
        ),
      ),
    ),
  );
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'atlas.dart';

/// SHAXSIY SUZANI MUHRI — rasmsiz foydalanuvchi uchun generativ avatar.
///
/// 🔴 Egasi (2026-08-20): "boshqa ilovalar qila olmagan" noyob narsa. Odatда
/// rasmsiz odamга bosh harf yoki tasodifiy rang beriladi. Bu yerда esa uning
/// ID'sidan NOYOB suzani gul GENERATSIYA qilinadi — rang, barg soni va
/// markaz aynan shu odamга tegishli, va u DOIM bir xil (deterministik).
/// Ya'ni har foydalanuvchining o'z "milliy muhri" bo'ladi.
///
/// Determinizm: bir xil `seed` -> bir xil naqsh (id o'zgармаса).
///
/// 🔴 RANG VA SHAKL QAYTA QURILDI (2026-09-03, milliylashtirish).
/// Ilgari rang HSL bo'yicha 175°–285° oralig'idan olinardi va uning
/// yarmi BINAFSHA edi — muhrlar «ochiq rangli romashka»ga o'xshab,
/// ilovaning yangi naqsh tilidan (girih, peshtoq, atlas) butunlay
/// ajralib turardi. Endi rang XONATLAS termalaridan (`AtlasPalette`)
/// olinadi — ya'ni muhr sarlavhalar ostidagi jiyak bilan BIR MATODAN.
/// Shakl esa PAXTA GULI: barglari yumaloq, an'anaviy motiv.
class SuzaniAvatar extends StatelessWidget {
  const SuzaniAvatar({super.key, required this.seed, this.size = 48});

  /// Foydalanuvchi ID yoki ismi — naqshни aniqlaydi.
  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SuzaniPainter(seed)),
    );
  }
}

class _SuzaniPainter extends CustomPainter {
  _SuzaniPainter(String seed) : _h = _hash(seed);

  final int _h;

  // Barqaror hash (ID -> son). Dart `hashCode` run'lar orasида o'zgармаsligi
  // kafolatlanмаган, shuning uchun o'zimiz yig'amiz.
  static int _hash(String s) {
    var h = 2166136261;
    for (final c in s.codeUnits) {
      h = (h ^ c) * 16777619 & 0x7fffffff;
    }
    return h;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    /*
     * ===== RANG — XONATLAS RANGLARIDAN TERILADI =====
     *
     * 🔴 Birinchi urinishda tayyor terma olingandi (`AtlasPalette.at`)
     * va O'LCHAB KO'RILGANDA 24 ta muhrning HAMMASI bir xil chiqdi:
     * termalar atigi uchta va hash ularning bittasiga tushib qolgandi.
     * Muhrning butun ma'nosi — har odamda BOSHQACHA bo'lishi.
     *
     * Endi to'rtta rang ETTITA atlas rangidan alohida-alohida
     * teriladi va bir-birini takrorlamaydi: 7×6×5 = 210 ta rang
     * uyg'unligi, ustiga barg soni va ichki qatlam — ya'ni muhr
     * amalda takrorlanmaydi, lekin RANGLAR baribir xonatlasniki.
     */
    const wheel = [
      AtlasColors.crimson,
      AtlasColors.saffron,
      AtlasColors.turquoise,
      AtlasColors.indigo,
      AtlasColors.pink,
      AtlasColors.ink,
      AtlasColors.ivory,
    ];
    // Takrorlanmaydigan tanlov: har qadamda ro'yxatdan olinadi va
    // olingani chiqarib tashlanadi (shuning uchun ranglar hech qachon
    // ustma-ust tushmaydi va gul «yo'qolib» qolmaydi).
    final bag = [...wheel];
    Color pick(int salt) => bag.removeAt((_h ~/ salt) % bag.length);

    // ⚠️ BARG hech qachon IVORY bo'lmaydi (ro'yxatdagi oxirgi rang):
    // och barg och zaminda yo'qoladi — o'lchab ko'rildi, bir necha muhr
    // «bo'sh doira» bo'lib qolgandi. Ivory ichki qatlam va urug' uchun
    // qoladi: ular to'yingan barg USTIDA turadi.
    // 🔴 BOSIQ RANG (12.09.2026, «premium» ko'rigi): to'liq to'yingan
    // atlas ranglari (crimson/pink) muhrni «klip-art» qilib, narx bilan
    // ikkita issiq pushti bo'lib raqobatlashardi. Dadillik narxда qoladi —
    // muhr endi kashtadek BOSIQ: har rang ivory tomon 22% suriladi.
    // Naqsh, gul, xonatlas hue'lari O'ZGARMAYDI, faqat to'yinganlik pasaydi.
    Color muted(Color c) => Color.lerp(c, const Color(0xFFF3ECE4), 0.22)!;
    final petalColor = muted(bag.removeAt(_h % (bag.length - 1)));
    final innerColor = muted(pick(7));
    final coreColor = muted(pick(53));
    final groundColor = pick(211);

    // Zamin — tanlangan rangning juda och tusi: muhr oq karta ustida
    // turadi, ya'ni zamini yorug' bo'lishi shart, lekin u ham matoning
    // rangidan.
    canvas.drawCircle(
      c,
      r,
      Paint()..color = Color.lerp(groundColor, Colors.white, 0.82)!,
    );

    // ===== PAXTA BARGLARI: 5..8 ta, seed'dan =====
    //
    // ⚠️ Barg YUMALOQ: paxta ko'sagi shunday ochiladi. Ilgari cho'zilgan
    // oval edi va gul romashkaga o'xshardi.
    final petals = 5 + (_h % 4);
    final rot = (_h % 30) * math.pi / 180;
    final petal = Paint()..color = petalColor;

    for (var i = 0; i < petals; i++) {
      final a = rot + 2 * math.pi * i / petals - math.pi / 2;
      canvas.drawCircle(
        c + Offset(r * 0.44 * math.cos(a), r * 0.44 * math.sin(a)),
        r * 0.30,
        petal,
      );
    }

    // Ikkinchi qatlam — ichkarida, siljigan (xilma-xillik uchun).
    if (_h.isEven) {
      final inner = Paint()..color = innerColor;
      for (var i = 0; i < petals; i++) {
        final a =
            rot + math.pi / petals + 2 * math.pi * i / petals - math.pi / 2;
        canvas.drawCircle(
          c + Offset(r * 0.26 * math.cos(a), r * 0.26 * math.sin(a)),
          r * 0.17,
          inner,
        );
      }
    }

    // ===== URUG' — markaz =====
    canvas.drawCircle(c, r * 0.20, Paint()..color = coreColor);
    canvas.drawCircle(c, r * 0.09, Paint()..color = groundColor);
  }

  @override
  bool shouldRepaint(_SuzaniPainter old) => old._h != _h;
}

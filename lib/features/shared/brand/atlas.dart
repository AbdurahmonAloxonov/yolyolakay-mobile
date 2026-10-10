import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'ornament.dart';

/// ATLAS (abr bandi) — MATO, chiziq emas.
///
/// 🔴 SAYTDA TO'RT MARTA QAYTA YOZILGAN va har safar bitta sabab bilan:
/// atlas TEKIS chiziqqa aylantirilgandi. Haqiqiy xonatlasda uchta narsa
/// bor va uchalasi ham kerak:
///
///  1. NAQSH — bodom (qalampir), taroq. Chiziq emas, SHAKL.
///  2. IPAK NURI — atlas to'quvi yorug'likni aks ettiradi: matoda bir
///     tomondan ikkinchisiga nur yo'li o'tadi. Tekis rang = bosma chit.
///  3. TO'QUV — yaqindan tik ip sezilib turadi.
///
/// ⚠️ ABR CHEKKASI — matoning butun siri. Marg'ilonda ipni bo'yashdan
/// oldin bog'lashadi, bo'yoq bog'lam ostiga sizadi va chekka PATLI
/// chiqadi. Saytda buni `feTurbulence` + `feDisplacementMap` beradi;
/// Flutterda SVG filtri yo'q, shuning uchun shakl chegarasi
/// NUQTAMA-NUQTA suriladi (`_feather`) — natija bir xil.
///
/// 🔑 Sizish faqat IP BO'YLAB ketadi: shovqin ikki o'qda HAR XIL
/// bo'lishi shart. Teng qo'ysang naqsh «bulut»ga aylanadi va
/// o'zbekistonlik odam uni darhol soxta deb biladi.
///
/// 🔑 ATLAS SAHIFADA BIR MARTA YIRIK. 4–6 pikselli chiziqda hech qanday
/// mato ko'rinmaydi — ingichka joyga [AtlasEdge] (jiyak) qo'yiladi.

/// Xonatlasning klassik palitrasi. Bu ranglar TEMAGA BOG'LIQ EMAS:
/// atlas — haqiqiy mato, uning rangi tungi rejimda o'zgarmaydi.
abstract final class AtlasColors {
  static const crimson = Color(0xFFA81F2A);
  static const saffron = Color(0xFFD08A2C);
  static const turquoise = Color(0xFF17796F);
  static const indigo = Color(0xFF22306B);
  static const pink = Color(0xFFC4157A);
  static const ivory = Color(0xFFEFE3D2);
  static const ink = Color(0xFF241017);
}

@immutable
class AtlasPalette {
  const AtlasPalette({
    required this.ground,
    required this.motif,
    required this.core,
    required this.accent,
    required this.light,
  });

  final Color ground;
  final Color motif;
  final Color core;
  final Color accent;
  final Color light;

  /// Uchta klassik terma — bir joyda ikki xil atlas bo'lmasin.
  ///
  /// ⚠️ Bu ranglar TEMAGA BOG'LIQ EMAS va ulashiladigan rasmlarda
  /// (pasport, plakat, taklif) AYNAN shular ishlatiladi: rasm boshqa
  /// odamning telefonida ochiladi.
  static const all = <AtlasPalette>[
    AtlasPalette(
      ground: AtlasColors.crimson,
      motif: AtlasColors.indigo,
      core: AtlasColors.saffron,
      accent: AtlasColors.turquoise,
      light: AtlasColors.ivory,
    ),
    AtlasPalette(
      ground: AtlasColors.indigo,
      motif: AtlasColors.turquoise,
      core: AtlasColors.crimson,
      accent: AtlasColors.saffron,
      light: AtlasColors.ivory,
    ),
    AtlasPalette(
      ground: AtlasColors.turquoise,
      motif: AtlasColors.crimson,
      core: AtlasColors.ivory,
      accent: AtlasColors.pink,
      light: AtlasColors.saffron,
    ),
  ];

  static AtlasPalette at(int i) => all[i.abs() % all.length];

  /*
   * ═══ USLUBGA MOSLASHGAN TERMALAR ═══
   *
   * 🔴 O'LCHAB TOPILDI (2026-09-03, zo'riqish ko'rigi): jiyak
   * TUNGI HAYDASH (amber) uslubida ham xonatlasning to'q ko'k va
   * yashil ranglarida chizilardi — ya'ni ruldagi odamning ekrani
   * tepasida yorqin SOVUQ chiziq turardi. Amber uslubi aynan shuning
   * uchun bor: tunda ko'k yorug'lik ko'zni qamashtiradi va
   * qorong'ilikka moslashishni buzadi (izohi `BrandColors` da).
   * Ya'ni bu bezak masalasi emas edi.
   *
   * Endi to'quv HAR USLUBDA o'z rang dunyosida qoladi: tuzilma bir
   * xil, ranglar esa temanikidek.
   */

  /// TUNGI HAYDASH — faqat ISSIQ ranglar, bitta ham sovuq rang yo'q.
  static const amber = <AtlasPalette>[
    AtlasPalette(
      ground: Color(0xFF8A4A12),
      motif: Color(0xFF3A2410),
      core: Color(0xFFD79A45),
      accent: Color(0xFFB86B22),
      light: Color(0xFFF0D8B8),
    ),
    AtlasPalette(
      ground: Color(0xFFB86B22),
      motif: Color(0xFF5A3312),
      core: Color(0xFFF0D8B8),
      accent: Color(0xFF8A4A12),
      light: Color(0xFFD79A45),
    ),
    AtlasPalette(
      ground: Color(0xFF5A3312),
      motif: Color(0xFFD79A45),
      core: Color(0xFF8A4A12),
      accent: Color(0xFFF0D8B8),
      light: Color(0xFFB86B22),
    ),
  ];

  /// NEON — pushti/cyan dunyosi (uslub faqat rangni almashtiradi).
  static const neon = <AtlasPalette>[
    AtlasPalette(
      ground: Color(0xFF0E1618),
      motif: Color(0xFFFF2BA0),
      core: Color(0xFF16E7CE),
      accent: Color(0xFF7A1450),
      light: Color(0xFFEAFBF7),
    ),
    AtlasPalette(
      ground: Color(0xFF16E7CE),
      motif: Color(0xFF0E1618),
      core: Color(0xFFFF2BA0),
      accent: Color(0xFF0A4A44),
      light: Color(0xFFEAFBF7),
    ),
    AtlasPalette(
      ground: Color(0xFFFF2BA0),
      motif: Color(0xFF0E1618),
      core: Color(0xFFEAFBF7),
      accent: Color(0xFF16E7CE),
      light: Color(0xFF7A1450),
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════
//  SHOVQIN — abr sizishi
// ═══════════════════════════════════════════════════════════════════

/// Qiymat shovqini (value noise) — chekkani «patli» qiladi.
///
/// ⚠️ Ikki o'qda HAR XIL to'lqin uzunligi (`px`, `py`): sizish faqat ip
/// bo'ylab ketadi. Teng bo'lsa mato emas, bulut chiqadi.
class _Noise {
  const _Noise(this.seed, this.px, this.py);

  final int seed;

  /// To'lqin uzunligi (piksel) — x va y bo'ylab.
  final double px;
  final double py;

  static double _hash(int x, int y, int seed) {
    var h = x * 374761393 + y * 668265263 + seed * 1442695040888963407;
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h ^ (h >> 16)) & 0xFFFF) / 0xFFFF * 2 - 1;
  }

  static double _smooth(double t) => t * t * (3 - 2 * t);

  /// −1…1 oralig'idagi silliq qiymat.
  double at(double x, double y) {
    final u = x / px;
    final v = y / py;
    final x0 = u.floor();
    final y0 = v.floor();
    final tx = _smooth(u - x0);
    final ty = _smooth(v - y0);
    final a = _hash(x0, y0, seed);
    final b = _hash(x0 + 1, y0, seed);
    final c = _hash(x0, y0 + 1, seed);
    final d = _hash(x0 + 1, y0 + 1, seed);
    return (a + (b - a) * tx) * (1 - ty) + (c + (d - c) * tx) * ty;
  }
}

/// Shakl chegarasini shovqin bilan suradi — abr sizishi.
///
/// Yo'l nuqtama-nuqta qayta teriladi: har nuqta ikki shovqin maydoni
/// bo'yicha suriladi. `SourceGraphic` ni siljitadigan SVG filtrining
/// aynan o'zi, faqat rastr emas, vektor ustida.
Path _feather(Path src, _Noise nx, _Noise ny, double amp) {
  final out = Path();
  for (final metric in src.computeMetrics()) {
    final len = metric.length;
    if (len < 2) continue;
    // Qadam ~2.5 px: undan yiriq bo'lsa chekka burchakli, maydasi
    // esa bekorga sekin.
    final steps = math.max(10, (len / 2.5).round());
    for (var i = 0; i <= steps; i++) {
      final tan = metric.getTangentForOffset(len * i / steps);
      if (tan == null) continue;
      final p = tan.position;
      final q = Offset(
        p.dx + nx.at(p.dx, p.dy) * amp,
        p.dy + ny.at(p.dx, p.dy) * amp,
      );
      if (i == 0) {
        out.moveTo(q.dx, q.dy);
      } else {
        out.lineTo(q.dx, q.dy);
      }
    }
    out.close();
  }
  return out;
}

// ═══════════════════════════════════════════════════════════════════
//  ATLAS MATOSI
// ═══════════════════════════════════════════════════════════════════

/// Atlas matosi — takrorlanuvchi abr naqshi.
///
/// [vertical] — ip yo'nalishi. `true` da naqsh tik teriladi (mato
/// osilgan holat), `false` da yotiq.
///
/// ⚠️ Chiziqlar TIK bo'lsin: yotiq bo'lsa gilamga o'xshaydi, atlas
/// to'pi esa tik osiladi.
class AtlasCloth extends StatelessWidget {
  const AtlasCloth({
    super.key,
    this.palette = 0,
    this.vertical = true,
    this.scale = 1,
    this.seed = 7,
    this.sheen = true,
  });

  final int palette;
  final bool vertical;

  /// Naqsh yirikligi. 1 — asl (katak 120×200 px).
  final double scale;
  final int seed;

  /// Ipak nuri. Busiz mato bosma qog'ozdek yassi ko'rinadi.
  final bool sheen;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ClothPainter(
          palette: AtlasPalette.at(palette),
          paletteIndex: palette,
          vertical: vertical,
          scale: scale,
          seed: seed,
          sheen: sheen,
        ),
      ),
    ),
  );
}

/// Bitta katakning tayyor shakllari — narx qimmat, shuning uchun
/// bir marta hisoblanadi va SAQLANADI.
class _ClothTile {
  const _ClothTile(this.shapes, this.size);

  final List<(Path, Color)> shapes;
  final Size size;
}

final Map<String, _ClothTile> _tileCache = {};

class _ClothPainter extends CustomPainter {
  const _ClothPainter({
    required this.palette,
    required this.paletteIndex,
    required this.vertical,
    required this.scale,
    required this.seed,
    required this.sheen,
  });

  final AtlasPalette palette;
  final int paletteIndex;
  final bool vertical;
  final double scale;
  final int seed;
  final bool sheen;

  /// Katak o'lchami (asl holatda).
  static const double _w = 120;
  static const double _h = 200;

  /// Chegaradan TASHQARIGA chiqish.
  ///
  /// 🔴 Nega kerak (saytda o'lchab topilgan): abr chekkasi pikselni
  /// surganda katak chetida OQ BO'SHLIQ ochilib, mato yamoq-yamoq
  /// bo'lib ko'rinardi.
  static const double _bleed = 16;

  /// BODOM (qalampir) — atlasning eng tanish abr shakli: pastki qismi
  /// to'la, uchi cho'zilgan. Suzanidagi bodom bilan bir oila.
  static Path _bodom(double cx, double cy, double w, double h) => Path()
    ..moveTo(cx, cy - h / 2)
    ..cubicTo(
      cx + w * 0.62,
      cy - h * 0.34,
      cx + w * 0.58,
      cy + h * 0.26,
      cx,
      cy + h / 2,
    )
    ..cubicTo(
      cx - w * 0.58,
      cy + h * 0.26,
      cx - w * 0.62,
      cy - h * 0.34,
      cx,
      cy - h / 2,
    )
    ..close();

  /// TAROQ — tishli toj, bodomlar orasida turadi.
  static Path _taroq(double cx, double cy, double w, double h) {
    const teeth = 5;
    final step = w / teeth;
    final path = Path()
      ..moveTo(cx - w / 2, cy + h / 2)
      ..lineTo(cx - w / 2, cy);
    for (var i = 0; i < teeth; i++) {
      final x = cx - w / 2 + i * step;
      path
        ..lineTo(x + step * 0.25, cy - h / 2)
        ..lineTo(x + step * 0.75, cy)
        ..lineTo(x + step, cy);
    }
    return path
      ..lineTo(cx + w / 2, cy + h / 2)
      ..close();
  }

  _ClothTile _tile() {
    final key = '$paletteIndex/$seed/$vertical';
    final cached = _tileCache[key];
    if (cached != null) return cached;

    // Abr sizishi: x bo'ylab qisqa to'lqin, y bo'ylab uzun — ya'ni
    // chekka ip bo'ylab uzoq masofada BIR XIL suriladi va patli
    // «tomchi» hosil bo'ladi.
    final nx = _Noise(seed, 28, 125);
    final ny = _Noise(seed + 101, 28, 125);
    const amp = 8.0;
    Path f(Path p) => _feather(p, nx, ny, amp);

    final shapes = <(Path, Color)>[
      // 1 — ZAMIN: tik bandlar, kengliklari ATAYIN notekis.
      (
        f(
          Path()..addRect(
            Rect.fromLTWH(-_bleed, -_bleed, _w + 2 * _bleed, _h + 2 * _bleed),
          ),
        ),
        palette.ground,
      ),
      (
        f(
          Path()..addRect(
            Rect.fromLTWH(-_bleed, -_bleed, 14 + _bleed, _h + 2 * _bleed),
          ),
        ),
        palette.accent,
      ),
      (
        f(Path()..addRect(Rect.fromLTWH(14, -_bleed, 5, _h + 2 * _bleed))),
        palette.light,
      ),
      (
        f(
          Path()..addRect(
            Rect.fromLTWH(_w - 20, -_bleed, 20 + _bleed, _h + 2 * _bleed),
          ),
        ),
        palette.motif,
      ),
      (
        f(Path()..addRect(Rect.fromLTWH(_w - 24, -_bleed, 4, _h + 2 * _bleed))),
        palette.light,
      ),

      // 2 — ABR NAQSHLARI: bodom ustuni, ichida yadro.
      (f(_bodom(_w * 0.5, _h * 0.27, 62, 96)), palette.motif),
      (f(_bodom(_w * 0.5, _h * 0.27, 30, 50)), palette.core),
      (f(_bodom(_w * 0.5, _h * 0.27, 12, 20)), palette.ground),

      // Teskari bodom — ustun jonli bo'lsin.
      (
        f(
          _bodom(_w * 0.5, _h * 0.74, 54, 84).transform(
            (Matrix4.identity()
                  ..translateByDouble(_w * 0.5, _h * 0.74, 0, 1)
                  ..rotateZ(math.pi)
                  ..translateByDouble(-_w * 0.5, -_h * 0.74, 0, 1))
                .storage,
          ),
        ),
        palette.core,
      ),
      (
        f(
          _bodom(_w * 0.5, _h * 0.74, 26, 44).transform(
            (Matrix4.identity()
                  ..translateByDouble(_w * 0.5, _h * 0.74, 0, 1)
                  ..rotateZ(math.pi)
                  ..translateByDouble(-_w * 0.5, -_h * 0.74, 0, 1))
                .storage,
          ),
        ),
        palette.ground,
      ),

      // 3 — TAROQ: ikki bodom orasida. Katak chegarasida pastda ham,
      // TEPADA ham chiziladi — takrorlanganda naqsh uzilmasin.
      (f(_taroq(_w * 0.5, _h * 0.5, 46, 18)), palette.light),
      (f(_taroq(_w * 0.5, _h * 0.99, 46, 18)), palette.light),
      (f(_taroq(_w * 0.5, -_h * 0.01, 46, 18)), palette.light),
    ];

    final tile = _ClothTile(shapes, const Size(_w, _h));
    _tileCache[key] = tile;
    return tile;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final tile = _tile();

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Yotiq holat: katak 90° buriladi va mato ko'ndalang osiladi.
    if (!vertical) {
      canvas.translate(0, size.height);
      canvas.rotate(-math.pi / 2);
    }
    final area = vertical ? size : Size(size.height, size.width);

    canvas.scale(scale);
    final w = tile.size.width;
    final h = tile.size.height;
    for (var y = 0.0; y < area.height / scale + h; y += h) {
      for (var x = 0.0; x < area.width / scale + w; x += w) {
        canvas.save();
        canvas.translate(x, y);
        canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
        for (final (path, color) in tile.shapes) {
          canvas.drawPath(path, Paint()..color = color);
        }
        canvas.restore();
      }
    }
    canvas.restore();

    // 4 — TO'QUV: tik iplar. Yaqindan sezilsin, uzoqdan bilinmasin.
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final warp = Paint()..color = Colors.black.withValues(alpha: 0.12);
    if (vertical) {
      for (var x = 0.0; x < size.width; x += 3) {
        canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), warp);
      }
    } else {
      for (var y = 0.0; y < size.height; y += 3) {
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), warp);
      }
    }

    // 5 — IPAK NURI: matoda bir tomondan ikkinchisiga o'tuvchi nur.
    if (sheen) {
      final rect = Offset.zero & size;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            vertical ? rect.topRight : rect.bottomLeft,
            [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.30),
              Colors.white.withValues(alpha: 0.05),
              Colors.black.withValues(alpha: 0.16),
              Colors.black.withValues(alpha: 0.30),
            ],
            const [0, 0.26, 0.44, 0.62, 1],
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClothPainter old) =>
      old.paletteIndex != paletteIndex ||
      old.vertical != vertical ||
      old.scale != scale ||
      old.seed != seed ||
      old.sheen != sheen;
}

// ═══════════════════════════════════════════════════════════════════
//  JIYAK — ingichka atlas chekkasi
// ═══════════════════════════════════════════════════════════════════

/// Jiyak — INGICHKA atlas chekkasi.
///
/// 🔴 NEGA ALOHIDA (egasi, 2026-08-30: «boshida g'alati ko'k chiziq
/// turibdi»): ilgari bu [AtlasCloth] ning ingichka bo'lagi edi va 6
/// pikselli chiziqda 120 pikselli katakning ATIGI BIR RANGI ko'rinardi
/// — natijada tepada tushunarsiz to'q ko'k chiziq turardi. Bodom naqshi
/// bunday balandlikda umuman ko'rinmaydi.
///
/// Jiyak boshqacha ishlaydi: ranglar chiziq BO'YLAB teriladi, ya'ni
/// qanchalik ingichka bo'lmasin, HAMMA rang ko'rinadi. Chekkasi esa
/// o'sha abr sizishi bilan — bu baribir atlas, chizilgan chiziq emas.
///
/// 🔑 QOIDA: naqshni KICHRAYTIRIB ishlatma — har o'lchamga o'z naqshi.
class AtlasEdge extends StatelessWidget {
  const AtlasEdge({
    super.key,
    this.height = 6,
    this.palette = 0,
    this.seed = 3,
    this.vertical = false,
    this.scale = 1,
    this.themed = true,
  });

  final double height;
  final int palette;
  final int seed;

  /// Terma TEMADAN olinsinmi.
  ///
  /// `false` — doim klassik xonatlas ranglari. Ulashiladigan rasmlar
  /// uchun SHART: ular boshqa odamning telefonida ochiladi va u yerda
  /// bizning temamiz yo'q.
  final bool themed;

  /// Naqsh zichligi. INGICHKA jiyakda kichraytiriladi: 1.0 da bitta
  /// rang 13 pikselgacha cho'ziladi va 3 pikselli chiziqda u to'quv
  /// emas, rangli KVADRATCHALAR bo'lib ko'rinadi. 0.55 da esa bir xil
  /// balandlikda to'quv qayta paydo bo'ladi.
  final double scale;

  /// Tik jiyak — kartaning yon chekkasi uchun.
  final bool vertical;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: SizedBox(
        height: vertical ? null : height,
        width: vertical ? height : double.infinity,
        child: CustomPaint(
          size: Size.infinite,
          painter: _EdgePainter(
            palette: themed
                ? OrnamentTokens.of(context).threads[palette.abs() % 3]
                : AtlasPalette.at(palette),
            paletteIndex: themed ? palette + 100 : palette,
            seed: seed,
            vertical: vertical,
            scale: scale,
          ),
        ),
      ),
    ),
  );
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.palette,
    required this.paletteIndex,
    required this.seed,
    required this.vertical,
    required this.scale,
  });

  final AtlasPalette palette;
  final int paletteIndex;
  final int seed;
  final bool vertical;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Jiyak termasi: kengliklar notekis, oq oraliqlar ingichka.
    final bands = <(Color, double)>[
      (palette.ground, 13 * scale),
      (palette.light, 3 * scale),
      (palette.motif, 10 * scale),
      (palette.core, 6 * scale),
      (palette.light, 2 * scale),
      (palette.accent, 9 * scale),
      (palette.ground, 5 * scale),
      (palette.light, 2 * scale),
    ];
    final unit = bands.fold<double>(0, (a, b) => a + b.$2);

    // Sizish chiziqqa KO'NDALANG: chekka mayda tishli bo'ladi,
    // bo'yoq sizganidek.
    //
    // 🔴 O'LCHAB TUZATILDI: birinchi urinishda kuch 3.5 va y bo'yicha
    // to'lqin 3.3 edi — 4–10 pikselli tasmada bandlar BIR-BIRIDAN
    // AJRALIB ketardi va jiyak rangli konfettiga o'xshab qolgandi.
    // Endi sizish yengil (1.2) va uzunroq to'lqinli.
    final nx = _Noise(seed, 22, 7);
    final ny = _Noise(seed + 57, 22, 7);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (vertical) {
      canvas.translate(size.width, 0);
      canvas.rotate(math.pi / 2);
    }
    final len = vertical ? size.height : size.width;
    final thick = vertical ? size.width : size.height;

    // ZAMIN — sizish tufayli bandlar orasida bo'shliq ochilsa, oq
    // emas, atlas rangi ko'rinsin.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, len, thick),
      Paint()..color = palette.ground,
    );

    for (var x = 0.0; x < len + unit; x += unit) {
      var at = x;
      for (final (color, w) in bands) {
        // Bandlar bir-birining ustiga 0.6 px chiqadi va balandligi
        // chiziqdan TASHQARIGA chiqadi — sizish chekkada bo'shliq
        // ochib qo'ymasin.
        final rect = Path()
          ..addRect(Rect.fromLTWH(at - 0.6, -thick, w + 1.2, thick * 3));
        canvas.drawPath(_feather(rect, nx, ny, 1.2), Paint()..color = color);
        at += w;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.paletteIndex != paletteIndex ||
      old.seed != seed ||
      old.vertical != vertical ||
      old.scale != scale;
}

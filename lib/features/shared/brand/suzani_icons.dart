/// SUZANI IKONKALARI — ilovaning o'z ikonka tili.
///
/// 🔴 NEGA YOZILDI (2026-08-24 auditi): butun ilovada 125 xil stok Material
/// ikonkasi ishlatilardi. Brendimizda suzani muhri, ikat to'quvi va o'z
/// palitramiz bor edi-yu, EKRANNING ENG KO'P KO'RINADIGAN qismi — pastki
/// menyu — har qanday boshqa Flutter ilovasidagidek ko'rinardi. Skrinshotdan
/// ilovani tanib bo'lmasdi.
///
/// QOIDA (eng muhimi): SILUET TEGILMAYDI, ICHI SUZANI BO'LADI.
/// Mashina mashinaga, posilka qutiga, pufak pufakka o'xshab qolishi shart —
/// odam ikonkani "o'qishga" majbur bo'lmasin. Milliy naqsh siluetning
/// ICHIDA yashaydi: linza o'rnida gul, g'ildirak o'rnida rozetka, tugun
/// o'rnida to'rt bargli naqsh. Shu sabab bu yerda "mashina o'rniga bodom"
/// kabi yechimlar YO'Q — ular chiroyli-yu, tushunarsiz.
///
/// Ikkinchi qoida: 24 pikselda o'qilsin. Shuning uchun chiziq qalin
/// (0.085 × o'lcham), mayda bezak yo'q, har ikonkada bittadan suzani
/// urg'usi bor — ikkitasi loyga aylanadi.
///
/// [filled] — Material'ning tanlangan/tanlanmagan an'anasi: menyuda faol
/// bo'lim to'ldirilgan holda chiziladi.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// To'plamdagi ikonkalar.
enum SuzaniIcon {
  /// Lupa — linzasi to'rt bargli gul.
  search,

  /// E'lon berish — sakkiz burchakli suzani yulduzi, markazida qo'shuv.
  create,

  /// Mashina — g'ildiraklari rozetka.
  car,

  /// Posilka — bog'ichi tugunida to'rt bargli naqsh.
  parcel,

  /// Suhbat pufagi — dumi bodom (boteh) shaklida.
  chat,

  /// Odam — boshi rozetka.
  person,

  /// Reyting yulduzi — sakkiz nurli suzani yulduzi.
  star,
}

class SuzaniIconWidget extends StatelessWidget {
  const SuzaniIconWidget(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.filled = false,
  });

  final SuzaniIcon icon;
  final double size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    // Rang berilmasa Material'ning o'z ikonka rangi olinadi — shunda ikonka
    // `NavigationBar`, `IconButton` va tugmalar ichida O'ZI to'g'ri
    // ranglanadi va har chaqiruvda rang yozish kerak bo'lmaydi.
    final resolved =
        color ??
        IconTheme.of(context).color ??
        Theme.of(context).iconTheme.color ??
        Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SuzaniIconPainter(
          icon: icon,
          color: resolved,
          filled: filled,
        ),
        // Ekran o'quvchisi uchun yorliq CHAQIRUVCHIDA beriladi
        // (`NavigationDestination` ning o'z `label` i bor) — bu yerda
        // takrorlansa TalkBack nomni ikki marta o'qiydi.
        isComplex: false,
      ),
    );
  }
}

class _SuzaniIconPainter extends CustomPainter {
  _SuzaniIconPainter({
    required this.icon,
    required this.color,
    required this.filled,
  });

  final SuzaniIcon icon;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (icon) {
      case SuzaniIcon.search:
        _search(canvas, s, stroke, fill);
      case SuzaniIcon.create:
        _create(canvas, s, stroke, fill);
      case SuzaniIcon.car:
        _car(canvas, s, stroke, fill);
      case SuzaniIcon.parcel:
        _parcel(canvas, s, stroke, fill);
      case SuzaniIcon.chat:
        _chat(canvas, s, stroke, fill);
      case SuzaniIcon.person:
        _person(canvas, s, stroke, fill);
      case SuzaniIcon.star:
        _star(canvas, s, stroke, fill);
    }
  }

  // ===== Umumiy naqsh g'ishtlari =====

  /// SCALLOP (palak gulining chetи) — doiraning o'rniga to'lqinli chekka.
  ///
  /// 🔴 BU YERDA BUTUN YONDASHUV O'ZGARDI (birinchi qoralama rasmga
  /// olib ko'rilgach, 2026-08-24): naqshni siluetning ICHIGA chizish
  /// 24 pikselda ISHLAMAYDI. Lupaning 14 pikselli linzasi ichidagi to'rt
  /// bargli gul oddiy "+" bo'lib ko'rindi (ya'ni "kattalashtirish"), odam
  /// boshi esa yulduzchaga aylanib, umuman odamga o'xshamay qoldi.
  ///
  /// Yechim: naqsh CHEKKAGA chiqdi. Doira o'rniga to'lqinli doira —
  /// silueti hamon doira (bosh boshligicha, linza linzaligicha qoladi),
  /// lekin cheti suzani gulining barglaridek. 24 pikselda "biroz
  /// boshqacha" bo'lib sezilaadi, 72 pikselda naqsh ochiq ko'rinadi.
  ///
  /// [lobes] — barg soni, [depth] — barg chuqurligi (0.14–0.20 oralig'i:
  /// undan sayozi bilinmaydi, chuquri esa doirani yulduzga aylantiradi).
  Path _scalloped(
    Offset c,
    double radius, {
    int lobes = 8,
    double depth = 0.16,
  }) {
    const steps = 128;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final a = 2 * math.pi * i / steps;
      final r = radius * (1 - depth + depth * (math.cos(lobes * a / 2)).abs());
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// Sakkiz nurli suzani yulduzi — an'anaviy "yulduz" naqshi. Oddiy besh
  /// burchakli yulduzdan farqi shu: bu bizniki.
  Path _eightPointStar(Offset center, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? outer : inner;
      // -90° dan boshlaymiz: yulduzning nuri TEPAGA qarasin.
      final a = -math.pi / 2 + math.pi * i / 8;
      final p = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// Siluetdan shakl KESIB oladi.
  ///
  /// 🔴 Ilgari bu `saveLayer` + `BlendMode.clear` bilan qilingandi va
  /// ISHLAMAGAN: to'ldirilgan lupa oddiy dog'ga, posilka esa to'la
  /// kvadratga aylanib qolgandi (rasmda ko'rindi). `Path.combine`
  /// natijasi qatlamlarga bog'liq emas — u shunchaki boshqa shakl.
  Path _cut(Path shape, List<Path> holes) {
    var out = shape;
    for (final h in holes) {
      out = Path.combine(PathOperation.difference, out, h);
    }
    return out;
  }

  Path _rectPath(Rect r, [double radius = 0]) =>
      Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)));

  // ===== Ikonkalar =====

  void _search(Canvas canvas, double s, Paint stroke, Paint fill) {
    final lens = Offset(s * 0.43, s * 0.43);
    final r = s * 0.29;
    // Linza — to'lqinli chekkali doira. Silueti lupanikidek qoladi.
    final rim = _scalloped(lens, r, lobes: 8, depth: 0.15);
    if (filled) {
      // Ichidan halqa kesiladi — "linza" ma'nosi to'ldirilgan holatda ham
      // yo'qolmasin (aks holda oddiy dog' bo'lib qoladi).
      canvas.drawPath(
        _cut(rim, [
          Path()..addOval(Rect.fromCircle(center: lens, radius: r * 0.42)),
        ]),
        fill,
      );
    } else {
      canvas.drawPath(rim, stroke);
    }
    canvas.drawLine(
      Offset(s * 0.64, s * 0.64),
      Offset(s * 0.88, s * 0.88),
      stroke,
    );
  }

  void _create(Canvas canvas, double s, Paint stroke, Paint fill) {
    final c = Offset(s / 2, s / 2);
    final star = _eightPointStar(c, s * 0.44, s * 0.24);
    final arm = s * 0.115;
    final thick = s * 0.085;

    if (filled) {
      canvas.drawPath(
        _cut(star, [
          _rectPath(
            Rect.fromCenter(center: c, width: arm * 2, height: thick),
            thick / 2,
          ),
          _rectPath(
            Rect.fromCenter(center: c, width: thick, height: arm * 2),
            thick / 2,
          ),
        ]),
        fill,
      );
    } else {
      canvas.drawPath(star, stroke);
      canvas.drawLine(
        Offset(c.dx - arm, c.dy),
        Offset(c.dx + arm, c.dy),
        stroke,
      );
      canvas.drawLine(
        Offset(c.dx, c.dy - arm),
        Offset(c.dx, c.dy + arm),
        stroke,
      );
    }
  }

  void _car(Canvas canvas, double s, Paint stroke, Paint fill) {
    final body = _rectPath(
      Rect.fromLTRB(s * 0.06, s * 0.45, s * 0.94, s * 0.70),
      s * 0.11,
    );
    final roof = Path()
      ..moveTo(s * 0.23, s * 0.46)
      ..lineTo(s * 0.35, s * 0.23)
      ..lineTo(s * 0.67, s * 0.23)
      ..lineTo(s * 0.79, s * 0.46);

    canvas.drawPath(roof, stroke);
    canvas.drawPath(body, filled ? fill : stroke);

    // G'ILDIRAKLAR — to'lqinli chekkali doira. Masofadan g'ildirak,
    // yaqindan gul. Markazi kesilgan: g'ildirak "to'ldirilgan dog'"
    // bo'lib qolmasin.
    for (final x in [s * 0.27, s * 0.73]) {
      final wheel = Offset(x, s * 0.75);
      final wr = s * 0.135;
      canvas.drawPath(
        _cut(_scalloped(wheel, wr, lobes: 8, depth: 0.18), [
          Path()..addOval(Rect.fromCircle(center: wheel, radius: wr * 0.34)),
        ]),
        fill,
      );
    }
  }

  void _parcel(Canvas canvas, double s, Paint stroke, Paint fill) {
    final rect = Rect.fromLTRB(s * 0.12, s * 0.25, s * 0.88, s * 0.87);
    final box = _rectPath(rect, s * 0.10);
    final tw = s * 0.075;
    final ties = [
      _rectPath(
        Rect.fromCenter(
          center: Offset(s * 0.5, s * 0.45),
          width: rect.width,
          height: tw,
        ),
      ),
      _rectPath(
        Rect.fromCenter(
          center: Offset(s * 0.5, rect.center.dy),
          width: tw,
          height: rect.height,
        ),
      ),
    ];
    // TUGUN — tasmalar kesishgan joyda to'lqinli chekkali doira.
    final knot = _scalloped(
      Offset(s * 0.5, s * 0.45),
      s * 0.115,
      lobes: 6,
      depth: 0.22,
    );

    if (filled) {
      // Tasmalar kesiladi, tugun esa QAYTA qo'shiladi — ya'ni tasmalar
      // tugundan "o'tib ketmaydi", unga kelib to'xtaydi.
      canvas.drawPath(
        Path.combine(PathOperation.union, _cut(box, ties), knot),
        fill,
      );
    } else {
      canvas.drawPath(box, stroke);
      canvas.drawPath(ties[0], fill);
      canvas.drawPath(ties[1], fill);
      canvas.drawPath(knot, fill);
    }
  }

  void _chat(Canvas canvas, double s, Paint stroke, Paint fill) {
    final bubble = _rectPath(
      Rect.fromLTRB(s * 0.09, s * 0.15, s * 0.91, s * 0.65),
      s * 0.17,
    );
    // DUM — uchburchak emas, BODOM (boteh) egri chizig'i: suzanining
    // ikkinchi eng mashhur motivi. Pufakning o'zi tanish bo'lib qoladi.
    final tail = Path()
      ..moveTo(s * 0.26, s * 0.60)
      ..cubicTo(s * 0.27, s * 0.80, s * 0.23, s * 0.87, s * 0.15, s * 0.92)
      ..cubicTo(s * 0.29, s * 0.89, s * 0.41, s * 0.78, s * 0.45, s * 0.60)
      ..close();
    final whole = Path.combine(PathOperation.union, bubble, tail);

    final dots = [
      for (final x in [s * 0.31, s * 0.50, s * 0.69])
        Path()..addOval(
          Rect.fromCircle(center: Offset(x, s * 0.40), radius: s * 0.058),
        ),
    ];

    if (filled) {
      canvas.drawPath(_cut(whole, dots), fill);
    } else {
      canvas.drawPath(whole, stroke);
      for (final d in dots) {
        canvas.drawPath(d, fill);
      }
    }
  }

  void _person(Canvas canvas, double s, Paint stroke, Paint fill) {
    // BOSH — to'lqinli chekkali doira. Silueti doira bo'lib qolgani uchun
    // ODAM o'qiladi; cheti esa suzani.
    final head = _scalloped(
      Offset(s * 0.5, s * 0.30),
      s * 0.21,
      lobes: 8,
      depth: 0.15,
    );
    // Yelka — pastdan yarim doira. Odam ikonkasining tanish shakli.
    final shoulders = Path()
      ..moveTo(s * 0.13, s * 0.88)
      ..cubicTo(s * 0.15, s * 0.58, s * 0.85, s * 0.58, s * 0.87, s * 0.88)
      ..close();

    if (filled) {
      canvas.drawPath(head, fill);
      canvas.drawPath(shoulders, fill);
    } else {
      canvas.drawPath(head, stroke);
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.13, s * 0.88)
          ..cubicTo(s * 0.15, s * 0.58, s * 0.85, s * 0.58, s * 0.87, s * 0.88),
        stroke,
      );
    }
  }

  void _star(Canvas canvas, double s, Paint stroke, Paint fill) {
    final c = Offset(s / 2, s / 2);
    canvas.drawPath(
      _eightPointStar(c, s * 0.46, s * 0.20),
      filled ? fill : stroke,
    );
    if (!filled) canvas.drawCircle(c, s * 0.07, fill);
  }

  @override
  bool shouldRepaint(_SuzaniIconPainter old) =>
      old.icon != icon || old.color != color || old.filled != filled;
}

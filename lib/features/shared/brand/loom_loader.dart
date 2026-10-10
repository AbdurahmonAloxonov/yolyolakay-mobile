import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/motion.dart';

/// DASTGOH — aylanma spinner o'rniga milliy to'quv.
///
/// 🔴 Egasi (2026-08-20): «boshqa ilovalar qila olmagan». Har yuklanishda
/// oddiy `CircularProgressIndicator` aylanadi — hamma ilovada bir xil.
/// Bu yerda esa naqsh IPLARDAN TO'QILADI: arqoq iplar yuqoridan pastga
/// birma-bir tushadi, shakl to'ladi, keyin qaytadan — xuddi dastgohda
/// to'qilayotgandek.
///
/// 🔴 SHAKL ALMASHTIRILDI (2026-09-03): ilgari bu ROMB edi va
/// `ikat_texture.dart` bilan bir geometriyada ishlardi. Egasi saytda
/// aynan shu motivni rad etgan: «romb har madaniyatda bor». Endi
/// to'qiladigan shakl — BODOM (qalampir), xonatlasning eng tanish abr
/// naqshi; ya'ni yuklanish belgisi ham matoning o'zidan chiqadi.
///
/// Sof dekorativ va davomli: aniq foizni ko'rsatmaydi (indeterminate),
/// faqat «ishlayapti» degani. Kichik o'lchamda ham toza ko'rinadi.
class LoomLoader extends StatefulWidget {
  const LoomLoader({super.key, this.size = 48, this.color});

  final double size;
  final Color? color;

  @override
  State<LoomLoader> createState() => _LoomLoaderState();
}

class _LoomLoaderState extends State<LoomLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    // Reduce-motion: to'qishni animatsiya qilmay, to'lgan shaklni STATIK
    // ko'rsatamiz (harakat yo'q, lekin brend belgisi qoladi).
    if (!AppMotion.on(context)) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _WeavePainter(0.68, color)),
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) =>
              CustomPaint(painter: _WeavePainter(_c.value, color)),
        ),
      ),
    );
  }
}

class _WeavePainter extends CustomPainter {
  _WeavePainter(this.t, this.color);

  /// 0..1 — to'qish bosqichi (yuqoridan pastga), keyin o'chishi.
  final double t;
  final Color color;

  /// BODOM (qalampir) — `atlas.dart` dagi bilan bir xil egrilik:
  /// pastki qismi to'la, uchi cho'zilgan.
  static Path _bodom(Offset c, double w, double h) => Path()
    ..moveTo(c.dx, c.dy - h / 2)
    ..cubicTo(
      c.dx + w * 0.62,
      c.dy - h * 0.34,
      c.dx + w * 0.58,
      c.dy + h * 0.26,
      c.dx,
      c.dy + h / 2,
    )
    ..cubicTo(
      c.dx - w * 0.58,
      c.dy + h * 0.26,
      c.dx - w * 0.62,
      c.dy - h * 0.34,
      c.dx,
      c.dy - h / 2,
    )
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, w / 2);
    final shape = _bodom(c, w * 0.60, w * 0.88);
    final top = c.dy - w * 0.44;
    final bottom = c.dy + w * 0.44;

    // Ikki faza: [0..0.7] to'qish (yuqoridan pastga to'ladi),
    //            [0.7..1] hammasini birga ko'rsatib, so'ng o'chishi.
    final weave = (t / 0.7).clamp(0.0, 1.0);
    final fade = t < 0.7 ? 1.0 : 1.0 - (t - 0.7) / 0.3;

    // Xira kontur — dastgohdagi «asos» iplar (warp).
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withValues(alpha: 0.22 * fade),
    );

    // To'qilgan qismni shakl ichiga kesib, arqoq iplarni chizamiz.
    canvas.save();
    canvas.clipPath(shape);
    final revealY = top + (bottom - top) * weave;
    const gap = 3.0;
    final thread = Paint()..strokeWidth = 1.6;
    for (double y = top; y <= revealY; y += gap) {
      // Chekka iplar biroz shaffofroq — abrning «patli» cheti hissi.
      final edge = 1.0 - ((y - c.dy).abs() / (w * 0.44)).clamp(0.0, 1.0);
      thread.color = color.withValues(alpha: (0.35 + 0.55 * edge) * fade);
      canvas.drawLine(Offset(0, y), Offset(w, y), thread);
    }
    canvas.restore();

    // Yadro — to'qish oxirida yonadi (bodomning ichki nuqtasi).
    if (weave > 0.9) {
      canvas.drawCircle(
        c,
        w * 0.05,
        Paint()..color = BrandColors.turquoise.withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(_WeavePainter old) => old.t != t || old.color != color;
}

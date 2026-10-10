import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../core/motion.dart';

/// ETA HALQASI — haydovchi kelayotganini KO'RSATADIGAN belgi.
///
/// 🔴 NEGA (2026-08-25 auditi): ETA allaqachon bor edi, lekin u oddiy
/// bir qator matn ("Taxminan 40 daqiqada yetib boradi") bo'lib, ekrandagi
/// boshqa o'nta qator orasida yo'qolib ketardi. Ayni paytda bu — safar
/// boshlangandan keyin yo'lovchini QIZIQTIRADIGAN YAGONA narsa. Odam uni
/// ko'rmasa, telefon qilishga majbur bo'ladi.
///
/// Endi haydovchi surati atrofida turkuaz halqa aylanadi — "jonli, hozir
/// ketyapti" hissi. Raqamning o'zi halqa ichida emas, ostida: suratni
/// yopib qo'ysak, kim kelayotgani ko'rinmay qoladi.
///
/// ⚠️ HALQA ANIQLIK EMAS, TIRIKLIK belgisidir. U foizni ko'rsatmaydi va
/// to'lmaydi — chunki bizda "yo'lning necha foizi bosib o'tildi" degan
/// ma'lumot YO'Q. Aylanadigan yoy aynan shuni bildiradi: harakat bor,
/// lekin qancha qolgani faqat taxminiy (matnda «taxminan» deb yozilgan).
///
/// Reduce-motion yoqilgan bo'lsa halqa AYLANMAYDI — to'liq doira bo'lib
/// turadi (tizim sozlamasi hurmat qilinadi).
class EtaRing extends StatefulWidget {
  const EtaRing({super.key, required this.child, this.size = 72});

  /// Odatda haydovchi surati (`PersonAvatar`).
  final Widget child;
  final double size;

  @override
  State<EtaRing> createState() => _EtaRingState();
}

class _EtaRingState extends State<EtaRing> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    // Sekin: tez aylanish "yuklanmoqda" degan ma'no beradi va odamni
    // kutishga majburlaydi. Bu esa holat belgisi, jarayon emas.
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    _spin.repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final animate = AppMotion.on(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Doimiy xira halqa — yoy qayerda aylanayotgani ko'rinsin.
          CustomPaint(
            size: Size.square(widget.size),
            painter: _RingPainter(
              color: scheme.secondary.withValues(alpha: 0.22),
              sweep: math.pi * 2,
              start: 0,
            ),
          ),
          if (animate)
            AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: _RingPainter(
                  color: scheme.secondary,
                  // Chorak yoy — to'liq doira "yuklandi" degan ma'no
                  // berardi, juda kichigi esa ko'rinmasdi.
                  sweep: math.pi / 2,
                  start: _spin.value * math.pi * 2,
                ),
              ),
            )
          else
            // Reduce-motion: harakat yo'q, lekin halqa BOR — belgi
            // butunlay yo'qolib ketmasin.
            CustomPaint(
              size: Size.square(widget.size),
              painter: _RingPainter(
                color: scheme.secondary,
                sweep: math.pi * 2,
                start: 0,
              ),
            ),
          Padding(
            // Halqa suratga tegib turmasin. `AppSpace.sm` — shkaladan
            // (qo'lda 6 yozilgan edi, `design_system_test` ushladi).
            padding: const EdgeInsets.all(AppSpace.sm),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.color,
    required this.sweep,
    required this.start,
  });

  final Color color;
  final double sweep;
  final double start;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.055;
    canvas.drawArc(
      Rect.fromLTWH(
        stroke / 2,
        stroke / 2,
        size.width - stroke,
        size.height - stroke,
      ),
      start - math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.start != start || old.sweep != sweep || old.color != color;
}

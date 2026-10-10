import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../core/haptics.dart';

/// BARMOQNI BOSIB USHLAB TASDIQLASH — tugma bosish o'rniga.
///
/// 🔴 Egasi (2026-08-20): "boshqa ilovalar qila olmagan" interaction.
/// Qaytarib bo'lmaydigan amalда (hisob o'chirish, safar bekor) oddiy tugма
/// TASODIFAN bosiladi. Bu yerда esa barmoqни ~1.4s USHLAB turish kerak:
/// atrofdаги halqа suzani gulдек barg-barg to'ladi, to'lgач — tasdiq.
/// Tasodifan bo'lmaydi, va harakat "og'ir/qarorli" his beradi.
///
/// Qo'yib yuborilса — halqа orqаga yig'iladi (bekor). To'lish oxирида
/// yengil tebranish (haptic).
class HoldToConfirm extends StatefulWidget {
  const HoldToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.color,
    this.icon = Icons.check,
  });

  final String label;
  final VoidCallback onConfirmed;
  final Color? color;
  final IconData icon;

  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
        )
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) {
            AppHaptics.heavy();
            widget.onConfirmed();
            _c.value = 0;
            _lastTick = 0;
          }
        })
        // "Yaqinlashuv" hissi: to'lish oxirlagan sari haptic TEZLASHADI (barmoq
        // maqsadga yaqinlashgandek). Tick oralig'i 12% -> 4% ga qisqaradi.
        ..addListener(() {
          final v = _c.value;
          if (v <= 0) {
            _lastTick = 0;
            return;
          }
          final step = 0.12 - 0.08 * v; // yuqorida tez-tez
          if (v - _lastTick >= step) {
            _lastTick = v;
            AppHaptics.select();
          }
        });

  double _lastTick = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.error;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          height: AppSize.buttonHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08 + _c.value * 0.10),
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // To'lish halqаsi — suzani barglардек (`_c` ulushiga qarab).
              Positioned(
                left: AppSpace.md,
                child: CustomPaint(
                  size: const Size(26, 26),
                  painter: _HoldRing(progress: _c.value, color: color),
                ),
              ),
              Text(
                widget.label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// To'lish halqаsi — suzani barglари birma-bir yonadi.
class _HoldRing extends CustomPainter {
  _HoldRing({required this.progress, required this.color});
  final double progress;
  final Color color;
  static const _petals = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    for (var i = 0; i < _petals; i++) {
      final t = (progress * _petals - i).clamp(0.0, 1.0);
      if (t <= 0) continue;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(2 * math.pi * i / _petals);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -r * 0.6),
          width: 3 * t,
          height: 6 * t,
        ),
        Paint()..color = color.withValues(alpha: t),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_HoldRing old) => old.progress != progress;
}

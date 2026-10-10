import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../core/motion.dart';

/// JONLI NUQTANING SILLIQ HARAKATI — mashina SAKRAMASIN, SURILSIN.
///
/// 🔴 NEGA YOZILDI (egasi, 18.09.2026 — «karta ishlashi bo'yicha
/// solishtirish kerak edi»): kuzatuvimiz jonli emas edi. Haydovchi 20
/// soniyada bir yuboradi (`LivePing._minGap`), yo'lovchi esa 30 soniyada
/// bir so'rardi — ekrandagi nuqta 50 soniyagacha eskirib, har safar yangi
/// joyga SAKRAB tushardi. Yandex Go'da mashina suzib boradi.
///
/// 🔑 SAYTDAGI `shared/lib/livePosition.ts` BILAN AYNAN BIR XIL QOIDA.
/// Ikki mijoz bitta safar haqida bir xil hikoya aytishi kerak: nuqta
/// telefonda suzib, saytda sakrab yursa, ikkalasining biri yolg'on
/// gapirgan bo'ladi.
///
/// Uch qoida — har biri jimgina buzilishi mumkin bo'lgani uchun
/// `test/live_point_test.dart` da o'lchanadi:
///
///   1. **EKSTRAPOLYATSIYA YO'Q.** Nuqta faqat ikkita KELGAN ping orasida
///      suriladi. Ping kechiksa u oxirgi joyida TO'XTAYDI — «davom
///      etaverdi» deb chizish joyni O'YLAB TOPISH bo'lardi.
///   2. **KATTA SAKRASH SURILMAYDI** ([kMaxSmoothKm]). 3 km dan katta
///      farq harakat emas: GPS qayta ushladi, ilova qayta ochildi yoki
///      haydovchi aloqasiz yurib kelib endi yubordi.
///   3. **ESKIRGAN PING SURILMAYDI.** Ma'lumot eski bo'lsa (panel buni
///      qizil yozuv bilan aytadi) nuqta qimirlamasligi kerak: harakat —
///      «aloqa bor» degan signal.

/// Undan katta sakrash SURILMAYDI — nuqta darhol ko'chadi.
///
/// 3 km: trassada 100 km/soat bilan ketayotgan mashina 50 soniyada ~1.4
/// km yuradi, ya'ni odatiy ping oralig'i bu chegaraga yetmaydi.
const double kMaxSmoothKm = 3;

/// Silliq surish davomiyligi — so'rov oralig'iga TENG (`driverPositionProvider`).
///
/// Nuqta keyingi ping kelgan payt manzilga yetadi: harakat uzluksiz
/// ko'rinadi, «tez yurib to'xtab qolish» bo'lmaydi.
const Duration kSmoothDuration = Duration(seconds: 10);

const Distance _distance = Distance();

/// Bu ikki nuqta orasini SURIB ko'rsatsa bo'ladimi?
///
/// [age] — oxirgi ping qanchalik eski. `null` (noma'lum) bo'lsa harakat
/// TAQIQLANMAYDI: `updated_at` ko'p javobda umuman kelmaydi.
bool canSmooth(LatLng? from, LatLng? to, {Duration? age, Duration? maxAge}) {
  if (from == null || to == null) return false;
  final limit = maxAge ?? const Duration(minutes: 10);
  if (age != null && age > limit) return false;
  final km = _distance.as(LengthUnit.Kilometer, from, to);
  // Nol masofada animatsiya qilish — kadrni bekorga yoqish.
  return km > 0 && km <= kMaxSmoothKm;
}

/// Boshi va oxiri sekin egri chiziq.
///
/// 🔑 CHIZIQLI EMASLIGI MUHIM: chiziqli harakatda nuqta har ping kelganda
/// to'satdan «start» va «stop» qiladi — ko'zga u ham sakrash bo'lib
/// ko'rinadi, faqat cho'zilgani.
double easeInOut(double t) {
  final x = t.clamp(0.0, 1.0);
  return x < 0.5 ? 2 * x * x : 1 - math.pow(-2 * x + 2, 2) / 2;
}

/// YO'NALISHNI burish — QISQA TOMONDAN.
///
/// 🔴 Oddiy `a + (b - a) * t` bu yerda XATO: 350° dan 10° ga o'tishda
/// strelka 20 gradus o'ngga emas, 340 gradus CHAPGA aylanib ketadi.
double? lerpHeading(double? a, double? b, double t) {
  if (b == null) return a;
  if (a == null) return b;
  final diff = ((((b - a) % 360) + 540) % 360) - 180;
  final v = a + diff * t.clamp(0.0, 1.0);
  return (v % 360 + 360) % 360;
}

/// `t` ulushidagi joy (0 → [from], 1 → [to]).
LatLng frameAt(LatLng from, LatLng to, double t) {
  final e = easeInOut(t);
  return LatLng(
    from.latitude + (to.latitude - from.latitude) * e,
    from.longitude + (to.longitude - from.longitude) * e,
  );
}

/// Nuqtani ikki ping ORASIDA suradigan o'rovchi.
///
/// Bola [builder] ga HAR KADRDA oraliq joy va yo'nalish beriladi.
/// Silliqlab bo'lmasa (birinchi nuqta, katta sakrash, eskirgan ping yoki
/// tizimda animatsiya o'chirilgan) qiymat DARHOL yangisiga o'tadi.
class SmoothPoint extends StatefulWidget {
  const SmoothPoint({
    super.key,
    required this.point,
    required this.builder,
    this.heading,
    this.age,
    this.duration = kSmoothDuration,
  });

  final LatLng point;
  final double? heading;

  /// Oxirgi ping yoshi — eskirgan nuqta SURILMAYDI.
  final Duration? age;
  final Duration duration;
  final Widget Function(BuildContext context, LatLng point, double? heading)
  builder;

  @override
  State<SmoothPoint> createState() => _SmoothPointState();
}

class _SmoothPointState extends State<SmoothPoint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// Animatsiya BOSHLANGAN joy — ko'rsatilayotgan nuqta, oldingi PING emas.
  /// Aks holda animatsiya o'rtasida kelgan ping nuqtani orqaga sakratardi.
  late LatLng _from = widget.point;
  late LatLng _to = widget.point;
  double? _fromHeading;
  double? _toHeading;

  @override
  void initState() {
    super.initState();
    _fromHeading = widget.heading;
    _toHeading = widget.heading;
  }

  @override
  void didUpdateWidget(SmoothPoint old) {
    super.didUpdateWidget(old);
    if (old.point == widget.point && old.heading == widget.heading) return;

    final shown = _current;
    /* Tizimda «harakatni kamaytir» yoqilgan bo'lsa nuqta SAKRAYDI —
       bu yerda harakat bezak emas, lekin qoida loyihada yagona
       (`AppMotion.on`) va foydalanuvchining tanlovi ustun. */
    if (!AppMotion.on(context) ||
        !canSmooth(shown, widget.point, age: widget.age)) {
      _c.stop();
      setState(() {
        _from = widget.point;
        _to = widget.point;
        _fromHeading = widget.heading;
        _toHeading = widget.heading;
        _c.value = 1;
      });
      return;
    }
    setState(() {
      _from = shown;
      _to = widget.point;
      _fromHeading = _currentHeading ?? widget.heading;
      _toHeading = widget.heading;
    });
    _c.forward(from: 0);
  }

  LatLng get _current => frameAt(_from, _to, _c.value);

  /// ⚠️ Burilish ham AYNAN O'SHA egri chiziq bilan: joy silliq surilib,
  /// strelka chiziqli burilsa, ikkisi bir-biridan ajralib ko'rinadi.
  double? get _currentHeading =>
      lerpHeading(_fromHeading, _toHeading, easeInOut(_c.value));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => widget.builder(context, _current, _currentHeading),
    );
  }
}

/// SAFAR O'TISHLARI — kartadan tafsilotga o'tganda joyida qoladigan qismlar.
///
/// 🔴 NEGA YOZILDI (2026-08-24 auditi): butun ilovada `Hero` atigi 4 marta,
/// tasodifiy joylarda ishlatilgan edi. Natijada ro'yxatdan safarni ochganda
/// ekran BUTUNLAY almashardi: narx bir joydan yo'qolib boshqa joyda paydo
/// bo'lardi, marshrut chizig'i qaytadan chizilardi. Odam har safar "bu
/// o'sha safarmi?" deb sarlavhani qayta o'qishga majbur bo'lardi.
///
/// Endi to'rt qism ikkala ekranda ham AYNAN bir xil "narsa" hisoblanadi va
/// o'rtada uchib o'tadi. Bu bezak emas — u "qayerdan qayerga keldim"
/// savoliga javob beradi.
///
/// QOIDALAR:
///  1. Teg SAFAR ID siga bog'langan — ikkita karta bir xil safarni
///     ko'rsatmaydi, ya'ni teg takrorlanmaydi (takrorlansa Flutter yiqiladi).
///  2. `id` bo'sh bo'lsa o'tish YO'Q. Bo'sh teg hamma safarni bitta narsa
///     deb qo'yardi va ro'yxatda ikkita karta bo'lsa ilova yiqilardi.
///  3. Reduce-motion yoqilgan bo'lsa o'tish YO'Q — tizim sozlamasi
///     hurmat qilinadi (`AppMotion`).
///  4. Matn uchun `Material` o'ramasi SHART: usiz uchayotgan matn ostida
///     sariq chiziqlar chiqadi (`Hero` ichida `DefaultTextStyle` yo'qoladi).
library;

import 'package:flutter/material.dart';

import '../../core/motion.dart';

/// Safar kartasining qaysi qismi uchib o'tadi.
enum RideHeroPart {
  /// Marshrut chizig'i (jo'nash → manzil).
  journey,

  /// Narx — ro'yxatdagi eng ko'p qidiriladigan raqam.
  price,

  /// Haydovchi surati.
  avatar,

  /// «Qancha qoldi» yozuvi.
  countdown,
}

class RideHero extends StatelessWidget {
  const RideHero({
    super.key,
    required this.rideId,
    required this.part,
    required this.child,
  });

  final String rideId;
  final RideHeroPart part;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (rideId.isEmpty || !AppMotion.on(context)) return child;

    return Hero(
      tag: 'ride-$rideId-${part.name}',
      // Uchish paytida matn/ikonka o'z uslubini yo'qotmasin.
      flightShuttleBuilder: (_, _, _, _, toContext) =>
          Material(type: MaterialType.transparency, child: toContext.widget),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

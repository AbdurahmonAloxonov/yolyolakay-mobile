/// ENG YAQIN SAFAR — bitta joyda hisoblanadi.
///
/// 🔴 NEGA ALOHIDA FAYL (2026-09-08): bu tanlov ilgari faqat `TodayCard`
/// ichida yashardi. Bosh ekran vidjeti ham AYNI safarni ko'rsatishi
/// kerak, va mantiqni ikkinchi marta yozsak — ertaga ikkalasi ikki xil
/// safar ko'rsatib turardi. Loyihada bu xato allaqachon bo'lgan (sana
/// filtri saytda va ilovada boshqa-boshqa edi), takrorlamaymiz.
///
/// Sinf emas, SOF funksiyalar: shu sabab ular testda tarmoqsiz,
/// ekransiz o'lchanadi.
library;

import '../../data/models/booking.dart';
import '../../data/models/ride.dart';

/// Safar hali AHAMIYATLIMI.
///
/// Jo'nab ketganlari ham qoladi, lekin faqat 2 soat ichida: odam yo'lda
/// bo'lishi mumkin va karta unga hamon kerak. Undan keyin safar tarixga
/// aylanadi va bosh ekranda ham, vidjetda ham o'rin egallamaydi.
bool tripRelevant(DateTime? departure, DateTime now) {
  if (departure == null) return false;
  return departure.isAfter(now.subtract(const Duration(hours: 2)));
}

/// Ro'yxatdan eng ERTA jo'naydiganini tanlaydi.
T? nearestByTime<T>(Iterable<T> items, DateTime? Function(T) time) {
  T? best;
  DateTime? bestTime;
  for (final item in items) {
    final t = time(item);
    if (t == null) continue;
    if (bestTime == null || t.isBefore(bestTime)) {
      best = item;
      bestTime = t;
    }
  }
  return best;
}

/// HAYDOVCHI uchun: o'z e'lonlaridan eng yaqini.
///
/// Bekor qilingan va tugagan safarlar chiqarib tashlanadi — ular
/// «keyingi safar» emas.
Ride? nearestDriverRide(Iterable<Ride>? rides, DateTime now) {
  if (rides == null) return null;
  return nearestByTime(
    rides.where(
      (r) =>
          r.status != RideStatus.cancelled &&
          r.status != RideStatus.completed &&
          tripRelevant(r.departureTime, now),
    ),
    (r) => r.departureTime,
  );
}

/// YO'LOVCHI uchun: tirik bronlaridan eng yaqini.
///
/// `isLive` — bekor qilingan/rad etilgan bron chiqarib tashlanadi
/// (izohi `Booking.isLive` da).
Booking? nearestPassengerBooking(Iterable<Booking>? bookings, DateTime now) {
  if (bookings == null) return null;
  return nearestByTime(
    bookings.where((b) => b.isLive && tripRelevant(b.ride?.departureTime, now)),
    (b) => b.ride?.departureTime,
  );
}

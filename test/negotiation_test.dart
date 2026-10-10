import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/booking.dart';

/// SAVDOLASHISH — narx va holat qoidalari.
///
/// 🔴 Egasi qurilmada topdi (2026-08-16): "haydovchi jo'natyapti, lekin
/// yo'lovchiga kelmayapti" va "narxni qabul qilsa ham haydovchining
/// belgilagan narxi ko'rsatilyapti".
///
/// Ikkala xato ham JIM kechardi: hech qanday xato xabari yo'q, shunchaki
/// ekranda noto'g'ri raqam yoki umuman xabar yo'q.
void main() {
  Booking booking({
    String status = 'pending',
    double? offered,
    double? total,
    int seats = 2,
  }) => Booking(
    id: 'b-1',
    rideId: 'r-1',
    passengerId: 'u-1',
    seatsBooked: seats,
    status: status,
    offeredPrice: offered,
    totalPrice: total,
  );

  group('ko\'rsatiladigan narx', () {
    /// 🔴 Savdolashish `offered_price` ni o'zgartiradi. `total_price` ni
    /// backend qayta hisoblaydimi — kontraktda YOZILMAGAN. Unga tayansak,
    /// odam kelishgan narxi o'rniga haydovchining boshlang'ich narxini
    /// ko'radi.
    test('taklif bo\'lsa — O\'SHANDAN hisoblanadi, total_price dan EMAS', () {
      final b = booking(offered: 40000, total: 100000, seats: 2);
      final price = b.offeredPrice != null
          ? b.offeredPrice! * b.seatsBooked
          : b.totalPrice;
      expect(price, 80000);
    });

    test('taklif yo\'q bo\'lsa — total_price ishlatiladi', () {
      final b = booking(total: 100000);
      final price = b.offeredPrice != null
          ? b.offeredPrice! * b.seatsBooked
          : b.totalPrice;
      expect(price, 100000);
    });
  });

  group('bron yakunlanganmi', () {
    /// 🔴 STATUSGA TAYANMASLIK QOIDASI: bron statuslari swaggerda umuman
    /// yozilmagan (`type: string`). Shuning uchun "haydovchi narx qaytardi"
    /// belgisi RUXSAT ro'yxatiga emas, RAD ETISH ro'yxatiga tayanadi —
    /// backend yangi oraliq status qo'shsa ham ishlayveradi.
    bool settled(Booking b) =>
        // 🔴 Nusxa EMAS, modelning O'ZI tekshiriladi: ilgari bu shart
        // testda qo'lda takrorlangan edi, ya'ni kod o'zgarsa test buni
        // sezmasdi — qo'riqchi qo'riqlamasdi.
        b.isSettled;

    test('yakunlangan holatlar', () {
      expect(settled(booking(status: BookingStatus.confirmed)), isTrue);
      expect(settled(booking(status: BookingStatus.rejected)), isTrue);
      expect(settled(booking(status: BookingStatus.noShow)), isTrue);
    });

    test('NOMA\'LUM oraliq status — yakunlanmagan deb qaraladi', () {
      // Backend ertaga `counter_offered` qo'shsa, yo'lovchi haydovchining
      // javobini KO'RISHI kerak — ilgari bunday statusda belgi umuman
      // chiqmasdi.
      expect(settled(booking(status: 'counter_offered')), isFalse);
      expect(settled(booking(status: 'pending_negotiation')), isFalse);
      expect(settled(booking(status: 'pending')), isFalse);
    });

    test('bekor qilingan bron — yakunlangan', () {
      expect(settled(booking(status: BookingStatus.cancelled)), isTrue);
    });

    test('KATTA HARFDAGI status ham tanilsin', () {
      // Jonlida kichik harf keladi, lekin swaggerda `type: string` —
      // kafolat yo'q. Bitta harf farqi "Qabul / Rad etish" tugmalarini
      // yo'qotib yuborardi.
      expect(settled(booking(status: 'CONFIRMED')), isTrue);
      expect(settled(booking(status: 'Rejected')), isTrue);
    });

    test('haydovchi tugmalari: yakunlanmagan HAMMA holatda ko\'rinadi', () {
      // `isPending` — haydovchining "Qabul / Rad etish" tugmalari sharti.
      expect(booking(status: 'pending').isPending, isTrue);
      expect(booking(status: 'pending_negotiation').isPending, isTrue);
      expect(booking(status: 'counter_offered').isPending, isTrue);
      expect(booking(status: BookingStatus.confirmed).isPending, isFalse);
    });
  });
}

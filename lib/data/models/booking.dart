import '../../core/api/api_client.dart' show asMap;
import '../../core/json.dart';
import 'ride.dart';

/// Bron statusi.
///
/// ⚠ Haydovchi qabul qilgach status `confirmed` bo'ladi (`accepted` EMAS) —
/// jonli tasdiqlangan, Swagger adashtiradi.
class BookingStatus {
  static const pending = 'pending';

  /// Yo'lovchi haydovchi narxidan boshqa narx taklif qilganda.
  static const pendingNegotiation = 'pending_negotiation';
  static const confirmed = 'confirmed';
  static const rejected = 'rejected';

  /// Yo'lovchi o'zi bekor qilgan bron.
  static const cancelled = 'cancelled';
  static const noShow = 'no_show';
}

/// Bron — gateway `PascalCase` qaytaradi (Swagger'dagi camelCase jonlida
/// tasdiqlanmadi). Ikkala yozuvni ham qabul qilamiz, UI faqat shu modelni ko'radi.
class Booking {
  const Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.status,
    this.offeredPrice,
    this.totalPrice,
    this.isFullCarBuyout = false,
    this.createdAt,
    this.ride,
    this.passenger,
  });

  final String id;
  final String rideId;
  final String passengerId;
  final int seatsBooked;
  final String status;

  /// `null` bo'lishi mumkin — rides/my ro'yxatida jonli kuzatilgan.
  final double? offeredPrice;
  final double? totalPrice;
  final bool isFullCarBuyout;
  final DateTime? createdAt;

  /// Bronga QO'SHIB yuborilgan safar (`http.BookingResponse.ride`) — ichida
  /// `driver` ham bor.
  ///
  /// NEGA MUHIM: yo'lovchi tomonda haydovchi ID'si va ISMI faqat shu yerdan
  /// keladi. Ilgari o'qilmasdi va suhbatlar ro'yxati har bron uchun alohida
  /// `GET /rides/{id}` yuborardi; u 404 bersa suhbat BUTUNLAY tushib qolardi,
  /// vebda esa ism o'rniga "Haydovchi" so'zi chiqardi.
  final Ride? ride;

  /// Bronni qilgan YO'LOVCHI (`Passenger` / `passenger`).
  ///
  /// 🔴 2026-08-12 gacha O'QILMASDI: haydovchi o'z safarini ochganda bronlar
  /// "2 joy" degan bosh sarlavha bilan turardi va KIM bron qilganini bilishning
  /// yo'li yo'q edi — qabul qilishdan oldin odamning ismini ham, reytingini ham
  /// ko'rmasdi. Ma'lumot javobda BOR edi (`/rides/my?role=driver` ni backend
  /// shunday to'ldirishi xatda tasdiqlangan), shunchaki modelda maydon yo'q edi.
  final DriverProfile? passenger;

  /// Status katta-kichik harfga BOG'LIQ BO'LMASIN.
  ///
  /// Jonlida `confirmed` kichik harfda keladi, lekin swagger buni
  /// kafolatlamaydi (`type: string`). Bitta harf farqi tugmalarni
  /// yo'qotib yuborishi mumkin — arzon ehtiyot chorasi.
  String get _status => status.toLowerCase();

  bool get isConfirmed => _status == BookingStatus.confirmed;

  /// Bron YAKUNLANGANMI — ustida boshqa amal qilib bo'lmaydimi.
  ///
  /// Yakunlangan holatlar aniq va o'zgarmas: qabul qilindi, rad etildi,
  /// bekor qilindi, kelmadi.
  bool get isSettled =>
      isConfirmed ||
      _status == BookingStatus.rejected ||
      _status == BookingStatus.cancelled ||
      _status == BookingStatus.noShow;

  /// Bron hali KUCHDAMI — safar kartasida ko'rsatishga arziydimi.
  ///
  /// 🔴 [isSettled] BILAN ADASHTIRMANG. U "ustida boshqa AMAL qilib
  /// bo'lmaydi" degani va `confirmed` ni ham o'z ichiga oladi —
  /// tasdiqlangan bron esa aynan eng muhimi: odam o'sha safarga chiqadi.
  /// «Yaqin safar» kartasi ilgari shu chalkashlik tufayli tasdiqlangan
  /// bronni YASHIRARDI.
  ///
  /// RAD ETISH RO'YXATI (ruxsat ro'yxati emas — sabab [isPending] da):
  /// noma'lum status tirik deb hisoblanadi. Xato tomoni to'g'ri — ortiqcha
  /// karta ko'rinsa odam uni o'zi tushunadi, kerakli karta yo'qolsa esa
  /// safaridan bexabar qoladi.
  bool get isLive =>
      _status != BookingStatus.rejected &&
      _status != BookingStatus.cancelled &&
      _status != BookingStatus.noShow;

  /// Hali javob kutayotgan bron — haydovchiga "Qabul / Rad etish"
  /// tugmalari aynan shunda ko'rsatiladi.
  ///
  /// 🔴 RUXSAT RO'YXATI EMAS, RAD ETISH RO'YXATI (2026-08-16 dagi
  /// savdolashish nosozligining ildizi shu edi):
  ///
  /// Ilgari shart `status == pending || status == pending_negotiation`
  /// edi. Bron statuslari swaggerda `type: string` — ro'yxat YO'Q, ya'ni
  /// biz ularni to'liq bilamiz deb faraz qila olmaymiz. Backend
  /// savdolashish statusini boshqacha nomlashi bilanoq tugmalar
  /// BUTUNLAY yo'qolardi va haydovchi arizaga javob bera olmasdi.
  ///
  /// Xato tomoni ham to'g'ri: noma'lum statusda ortiqcha tugma ko'rinsa
  /// server "bo'lmaydi" deydi; tugma ko'rinmasa esa odam nima qilishini
  /// umuman bilmaydi.
  bool get isPending => !isSettled;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final offered = pick(json, [
      'OfferedPrice',
      'offered_price',
      'offeredPrice',
    ]);
    final total = pick(json, ['TotalPrice', 'total_price', 'totalPrice']);
    return Booking(
      id: asString(pick(json, ['ID', 'id'])),
      rideId: asString(pick(json, ['RideID', 'ride_id', 'rideId'])),
      passengerId: asString(
        pick(json, ['PassengerID', 'passenger_id', 'passengerId']),
      ),
      seatsBooked: asInt(pick(json, ['SeatsBooked', 'seats_booked', 'seats'])),
      status: asString(pick(json, ['Status', 'status'])),
      offeredPrice: offered == null ? null : asDouble(offered),
      totalPrice: total == null ? null : asDouble(total),
      isFullCarBuyout: asBool(
        pick(json, ['IsFullCarBuyout', 'is_full_car_buyout']),
      ),
      createdAt: asDate(pick(json, ['CreatedAt', 'created_at'])),
      ride: () {
        final raw = asMap(pick(json, ['Ride', 'ride']));
        return raw == null ? null : Ride.fromJson(raw);
      }(),
      passenger: () {
        final raw = asMap(pick(json, ['Passenger', 'passenger']));
        if (raw != null) return DriverProfile.fromJson(raw);
        // Yassi shakl: ba'zi javoblarda faqat ism keladi (`passenger_name`).
        final flat = asStringOrNull(
          pick(json, ['PassengerName', 'passenger_name']),
        );
        return (flat == null || flat.trim().isEmpty)
            ? null
            : DriverProfile(name: flat.trim());
      }(),
    );
  }
}

/// POST /rides/{id}/book tanasi — maydon `seats` (`seats_booked` EMAS).
class BookRideRequest {
  const BookRideRequest({
    required this.seats,
    this.offeredPrice,
    this.isFullCarBuyout = false,
  });

  final int seats;

  /// Haydovchi narxidan farq qilsa bron `pending_negotiation` bo'ladi.
  final double? offeredPrice;

  /// Butun salonni sotib olish — bunda `seats` e'tiborga olinmaydi.
  final bool isFullCarBuyout;

  Map<String, dynamic> toJson() => {
    'seats': seats,
    if (offeredPrice != null) 'offered_price': offeredPrice,
    if (isFullCarBuyout) 'is_full_car_buyout': true,
  };
}

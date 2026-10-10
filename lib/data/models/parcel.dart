import '../../core/json.dart';

/// `parcel_domain.Parcel`
///
/// Manzil MATNI: backend `from_address`/`to_address` ni qaytaradi (swagger
/// sverkasi 2026-08-12). Ilgari ular yo'q deb hisoblanardi va shahar nomi
/// koordinatadan taxmin qilinardi — endi matn bo'lsa O'SHA ishlatiladi,
/// bo'lmasa eski taxmin zaxira bo'lib qoladi (eski yozuvlar uchun).
class Parcel {
  const Parcel({
    required this.id,
    required this.originLat,
    required this.originLon,
    required this.destinationLat,
    required this.destinationLon,
    this.fromAddress,
    this.toAddress,
    this.senderId,
    this.senderName,
    this.senderRating,
    this.responsesCount,
    this.driverId,
    this.price,
    this.receiverPhone,
    this.status,
    this.createdAt,
    this.size,
    this.description,
    this.deliverBy,
  });

  final String id;
  final double originLat;
  final double originLon;
  final double destinationLat;
  final double destinationLon;
  final String? fromAddress;
  final String? toAddress;
  final String? senderId;

  /// Jo'natuvchi ISMI va reytingi — backend xati (2026-08-14) bo'yicha
  /// qo'shiladi (`sender_name`, `sender_rating`). Kelmasa `null` bo'ladi va
  /// ekranda hech narsa ko'rsatilmaydi (bo'sh "—" chiqarmaymiz).
  final String? senderName;
  final double? senderRating;

  /// Nechta haydovchi taklif berdi.
  ///
  /// ✅ Backend 2026-08-16 kechqurun qo'shdi. Ungacha jo'natuvchi taklif
  /// kelganini BILMASDI — har posilkani ochib tekshirishi kerak edi
  /// (egasining eski shikoyati).
  final int? responsesCount;
  final String? driverId;
  final double? price;
  final String? receiverPhone;
  final String? status;
  final DateTime? createdAt;

  /// `small` / `medium` / `large`. Backend enum EMAS, oddiy string qabul
  /// qiladi — shuning uchun qiymatlar sayt bilan AYNAN bir xil bo'lishi shart
  /// (`ParcelSize` tipi u yerda), aks holda saytda yaratilgan posilkani ilova
  /// tanimay qoladi va aksincha.
  final String? size;
  final String? description;

  /// «Shu kungacha yetkazilsin». Backend ISO8601 kutadi.
  final DateTime? deliverBy;

  /// Haydovchi biriktirilgan bo'lsa boshqa haydovchi ololmaydi.
  bool get isTaken => driverId != null && driverId!.isNotEmpty;

  /// HAYDOVCHI POSILKANI OLGANMI.
  ///
  /// 🔴 Backend `picked_up` beradi, mijozlar esa `in_transit` ni
  /// kutishardi (o'lchandi 2026-09-04: `pickup` dan keyingi holat
  /// AYNAN `picked_up`). Natijada ilovada ham, saytda ham «Yetkazdim»
  /// tugmasi HECH QACHON chiqmasdi va posilka oxirgi qadamda qotib
  /// qolardi — 16-avgustdan beri quvib yurgan muammoning qolgan yarmi
  /// shu edi.
  ///
  /// Ikkala nom ham qabul qilinadi: gateway `in_transit` ga qaytsa
  /// ham buzilmaymiz. Saytdagi juftligi — `isParcelPickedUp`.
  bool get isPickedUp {
    final s = (status ?? '').toLowerCase();
    return s == 'picked_up' || s == 'in_transit';
  }

  bool get isDelivered => (status ?? '').toLowerCase() == 'delivered';

  factory Parcel.fromJson(Map<String, dynamic> json) {
    final price = pick(json, ['Price', 'price']);
    return Parcel(
      id: asString(pick(json, ['ID', 'id'])),
      originLat: asDouble(pick(json, ['OriginLat', 'origin_lat'])),
      originLon: asDouble(pick(json, ['OriginLon', 'origin_lon'])),
      destinationLat: asDouble(
        pick(json, ['DestinationLat', 'destination_lat']),
      ),
      destinationLon: asDouble(
        pick(json, ['DestinationLon', 'destination_lon']),
      ),
      senderId: asStringOrNull(pick(json, ['SenderID', 'sender_id'])),
      senderName: asStringOrNull(pick(json, ['SenderName', 'sender_name'])),
      responsesCount: () {
        final raw = pick(json, ['ResponsesCount', 'responses_count']);
        return raw == null ? null : asInt(raw);
      }(),
      senderRating: () {
        final raw = pick(json, ['SenderRating', 'sender_rating']);
        return raw == null ? null : asDouble(raw);
      }(),
      driverId: asStringOrNull(pick(json, ['DriverID', 'driver_id'])),
      price: price == null ? null : asDouble(price),
      receiverPhone: asStringOrNull(
        pick(json, ['ReceiverPhone', 'receiver_phone']),
      ),
      status: asStringOrNull(pick(json, ['Status', 'status'])),
      createdAt: asDate(pick(json, ['CreatedAt', 'created_at'])),
      fromAddress: asStringOrNull(pick(json, ['FromAddress', 'from_address'])),
      toAddress: asStringOrNull(pick(json, ['ToAddress', 'to_address'])),
      size: asStringOrNull(pick(json, ['Size', 'size'])),
      description: asStringOrNull(pick(json, ['Description', 'description'])),
      deliverBy: asDate(pick(json, ['DeliverBy', 'deliver_by'])),
    );
  }
}

/// `http.ParcelResponseDTO` — haydovchining posilkaga taklifi.
///
/// `domain.ParcelResponse` dan farqi: bunda haydovchi haqida ko'rsatiladigan
/// ma'lumot ham bor (ism, avatar, reyting). Ro'yxatda aynan shu kerak —
/// aks holda yuboruvchi tanlash uchun faqat ID ko'rardi.
class ParcelResponse {
  const ParcelResponse({
    required this.id,
    required this.parcelId,
    this.driverId,
    this.driverName,
    this.driverAvatar,
    this.driverRating,
    this.offeredPrice,
    this.status,
    this.createdAt,
  });

  final String id;
  final String parcelId;
  final String? driverId;
  final String? driverName;
  final String? driverAvatar;
  final double? driverRating;
  final double? offeredPrice;
  final String? status;
  final DateTime? createdAt;

  /// Yuboruvchi faqat KUTAYOTGAN taklifni qabul qila oladi — allaqachon hal
  /// bo'lgani uchun tugma ko'rsatish odamni chalg'itardi.
  bool get isPending => (status ?? 'pending').toLowerCase() == 'pending';

  factory ParcelResponse.fromJson(Map<String, dynamic> json) {
    final price = pick(json, ['OfferedPrice', 'offered_price']);
    final rating = pick(json, ['DriverRating', 'driver_rating']);
    return ParcelResponse(
      id: asString(pick(json, ['ID', 'id'])),
      parcelId: asString(pick(json, ['ParcelID', 'parcel_id'])),
      driverId: asStringOrNull(pick(json, ['DriverID', 'driver_id'])),
      driverName: asStringOrNull(pick(json, ['DriverName', 'driver_name'])),
      driverAvatar: asStringOrNull(
        pick(json, ['DriverAvatar', 'driver_avatar']),
      ),
      driverRating: rating == null ? null : asDouble(rating),
      offeredPrice: price == null ? null : asDouble(price),
      status: asStringOrNull(pick(json, ['Status', 'status'])),
      createdAt: asDate(pick(json, ['CreatedAt', 'created_at'])),
    );
  }
}

/// `POST /parcels` tanasi.
///
/// 🔴 2026-08-12 da qurilmada topilgan: bu so'rov 400 ("Noto'g'ri so'rov
/// yuborildi") qaytarardi va ilovadan posilka joylash UMUMAN ishlamasdi.
/// Sabab — swagger'da `http.createParcelRequest.required`:
///
///   origin_lat, origin_lon, destination_lat, destination_lon,
///   from_address, to_address, price, receiver_phone
///
/// Ya'ni backend to'rtta maydonni majburiy qilgan: manzil MATNLARI (ilova
/// ularni umuman yubormasdi) hamda narx va qabul qiluvchi raqami (ilovada
/// "ixtiyoriy" deb turardi). Saytda hammasi yuborilardi, shuning uchun
/// muammo faqat mobil tomonda ko'rinmay yotgan edi.
class CreateParcelRequest {
  const CreateParcelRequest({
    required this.originLat,
    required this.originLon,
    required this.destinationLat,
    required this.destinationLon,
    required this.fromAddress,
    required this.toAddress,
    required this.price,
    required this.receiverPhone,
    this.size,
    this.description,
    this.deliverBy,
  });

  final double originLat;
  final double originLon;
  final double destinationLat;
  final double destinationLon;
  final String fromAddress;
  final String toAddress;
  final double price;
  final String receiverPhone;

  /// ✅ 2026-08-12: quyidagi uchtasini backend QO'SHGAN (swagger sverkasi).
  /// Ilgari ikkala klientda ham "backend saqlamaydi" deb hisoblanardi va
  /// so'ralmasdi — natijada haydovchi posilkani faqat "Toshkent → Samarqand,
  /// 50 000 so'm" deb ko'rardi, NIMA tashiyotganini bilmasdi.
  final String? size;
  final String? description;
  final DateTime? deliverBy;

  Map<String, dynamic> toJson() => {
    'origin_lat': originLat,
    'origin_lon': originLon,
    'destination_lat': destinationLat,
    'destination_lon': destinationLon,
    'from_address': fromAddress,
    'to_address': toAddress,
    'price': price,
    'receiver_phone': receiverPhone,
    // Ixtiyoriylar: bo'sh bo'lsa YUBORILMAYDI. Bo'sh satr yuborish
    // "tavsif kiritilgan, lekin bo'sh" degan yolg'on holat yaratardi.
    if (size != null) 'size': size,
    if (description != null && description!.trim().isNotEmpty)
      'description': description!.trim(),
    if (deliverBy != null) 'deliver_by': deliverBy!.toUtc().toIso8601String(),
  };
}

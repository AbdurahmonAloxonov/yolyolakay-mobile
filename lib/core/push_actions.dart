import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/booking.dart';
import '../data/models/ride.dart';

/// PUSH'DAGI TUGMALAR — «Qabul qilaman» / «Rad etaman».
///
/// 🔴 NEGA (egasi tanladi, 18.09.2026): bron zanjiri bugun besh qadam —
/// yo'lovchi bron qiladi → haydovchiga push keladi → u ilovani ochadi →
/// safarni topadi → bronni topadi → bosadi. Har qadam vaqt, va aynan shu
/// kutish Yandex Go bilan solishtirganda eng og'ir farqimiz edi
/// («darhol tasdiq»). Androidda bildirishnomaning O'ZIDA tugma bo'lishi
/// mumkin.
///
/// ─────────────────────────────────────────────────────────────────
/// 🔴 IKKI CHEKLOV — O'LCHANGAN, TAXMIN EMAS
/// ─────────────────────────────────────────────────────────────────
///
/// 1. **Bildirishnomada `ride_id` ham, `booking_id` ham YO'Q**
///    (16.09.2026 da `GET /notifications` bilan o'lchangan, backendga
///    xat yozilgan). Ya'ni tugma bosilganda qaysi bronni tasdiqlashni
///    push AYTIB BERMAYDI.
///
///    Yechim: bronni ILOVA O'ZI topadi — `GET /rides/my?role=driver`
///    javobidagi `bookings[]` dan (haydovchi ekrani ham shu manbadan
///    ishlaydi). Bitta so'rov yetarli.
///
/// 2. **Kutayotgan bron BITTA bo'lsagina amal bajariladi.** Ikkitasi
///    bo'lsa tugma HECH NIMANI TASDIQLAMAYDI — ro'yxat ochiladi va
///    sababi aytiladi. 🔑 Bu eng muhim qoida: noto'g'ri yo'lovchini
///    qabul qilish — sukut bilan xato qilishning eng yomon turi, uni
///    haydovchi ham, yo'lovchi ham keyin biladi.
///
/// ⚠️ Tugmalar `showsUserInterface: true` bilan ishlaydi, ya'ni ILOVA
/// OCHILADI va amal o'sha yerda bajariladi. Fon isolate'ida bajarish
/// ham mumkin edi, lekin u yerda token yangilash kerak bo'ladi va
/// `refresh` AYLANADI — eskisi darhol o'ladi ([sessiya uzilishi
/// 24.08.2026]). Fon isolate'i bilan asosiy isolate poyga qilsa odam
/// login ekraniga uchib chiqardi. Ochilgan ilova esa beshta qadamning
/// TO'RTTASINI olib tashlaydi va natijani KO'RSATADI.

/// Bildirishnoma tugmalarining kalitlari (Android `actionId`).
const String bookingAcceptAction = 'booking_accept';
const String bookingRejectAction = 'booking_reject';

/// Bosilgan TUGMA push ma'lumotiga shu kalit bilan qo'shiladi.
///
/// 🔑 Pastki chiziq bilan boshlanadi: backend maydonlari bilan hech
/// qachon to'qnashmasin — bu BIZNING ichki belgimiz.
const String pushActionKey = '_action';

/// Bu bosish — tugmami yoki bildirishnomaning o'zimi?
bool isBookingAction(Map<String, dynamic> data) {
  final a = data[pushActionKey];
  return a == bookingAcceptAction || a == bookingRejectAction;
}

/// Push «yangi bron» haqidami — tugmalar faqat shunda chiziladi.
///
/// Backend turni uch xil yozgan (`booking_created`, `BookingCreated`,
/// `BOOKING_CREATED`) — `push_routes.dart` dagi kabi normallaymiz.
bool isNewBookingPush(Map<String, dynamic> data) {
  final raw = '${data['type'] ?? data['event'] ?? data['kind'] ?? ''}';
  final type = raw.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
  // `bookingcancelled` va `bookingrejected` ga tugma KERAK EMAS: ular
  // xabar, so'rov emas.
  if (!type.contains('booking')) return false;
  return type.contains('created') || type.contains('new') || type == 'booking';
}

/// TUGMA YOZUVLARI — to'rt tilda.
///
/// 🔴 NEGA SHU YERDA, `AppStrings` da EMAS: bildirishnoma FON
/// ISOLATE'ida chiziladi. U yerda `BuildContext` ham, `AppStrings` ham
/// YO'Q — `AppStrings.of(context)` ni chaqirib bo'lmaydi. Til esa
/// saqlangan sozlamadan o'qiladi (`SharedPreferences`, kalit `locale` —
/// `LocaleController._key` bilan AYNAN bir xil).
///
/// ⚠️ Kalit ikki joyda yozilgan: bu yerda va `LocaleController` da.
/// Ularni bog'lab bo'lmaydi (fon isolate'i providerlarni ko'rmaydi),
/// shuning uchun moslik SINOV bilan qo'riqlanadi
/// (`push_actions_test.dart`).
const String localePrefsKey = 'locale';

/// Saqlangan til kodi → tugma yozuvlari.
///
/// Noma'lum kodda o'zbekcha: ilovaning standart tili o'sha.
({String accept, String reject}) bookingActionLabels(String? localeCode) =>
    switch (localeCode) {
      'ru' => (accept: 'Принять', reject: 'Отклонить'),
      'en' => (accept: 'Accept', reject: 'Decline'),
      'uz-Cyrl' => (accept: 'Қабул қиламан', reject: 'Рад этаман'),
      _ => (accept: 'Qabul qilaman', reject: 'Rad etaman'),
    };

/// Bron havolasi — qaysi safarning qaysi broni.
class BookingRef {
  const BookingRef(this.rideId, this.bookingId);

  final String rideId;
  final String bookingId;

  @override
  bool operator ==(Object other) =>
      other is BookingRef &&
      other.rideId == rideId &&
      other.bookingId == bookingId;

  @override
  int get hashCode => Object.hash(rideId, bookingId);
}

/// Haydovchining safarlari ichidan JAVOB KUTAYOTGAN bronlar.
///
/// `pending` ham, `pending_negotiation` ham kiradi: ikkalasi ham
/// haydovchining qaroriga qarab turibdi.
List<BookingRef> pendingBookings(List<Ride> rides) {
  final out = <BookingRef>[];
  for (final ride in rides) {
    // Bekor qilingan yoki tugagan safardagi bron — qaror kutmaydi.
    if (ride.status == RideStatus.cancelled ||
        ride.status == RideStatus.completed) {
      continue;
    }
    for (final b in ride.bookings) {
      if (b.status == BookingStatus.pending ||
          b.status == BookingStatus.pendingNegotiation) {
        out.add(BookingRef(ride.id, b.id));
      }
    }
  }
  return out;
}

/// Tugma bosilganda nima qilinsin.
///
/// 🔑 `null` — «amal bajarilmaydi, ro'yxatni ochamiz». Bu XATO EMAS,
/// halol javob: bitta so'rov aniq bo'lmasa tanlashni odamga qoldiramiz.
BookingRef? resolveSinglePending(List<Ride> rides) {
  final all = pendingBookings(rides);
  return all.length == 1 ? all.first : null;
}

/// Saqlangan til kodi — FON ISOLATE'ida o'qish uchun.
///
/// ⚠️ `SharedPreferences` fon isolate'ida ham ishlaydi, lekin plaginlar
/// ro'yxatdan o'tgan bo'lishi shart (`DartPluginRegistrant.
/// ensureInitialized()` — `handleBackgroundMessage` uni allaqachon
/// chaqiradi). O'qib bo'lmasa `null` qaytadi va yozuv o'zbekcha bo'ladi:
/// til noma'lumligi bildirishnomani yo'qotish uchun sabab emas.
Future<String?> savedLocaleCode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(localePrefsKey);
  } catch (_) {
    return null;
  }
}

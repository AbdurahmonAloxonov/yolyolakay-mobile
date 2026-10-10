import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api/api_client.dart';

/// Foydalanish statistikasi — `POST /analytics/events`.
///
/// Backend buni ancha oldin qurgan, lekin bizga aytmagan (swagger sverkasi,
/// 2026-08-16). Biz hech narsa yubormasdik, ya'ni egasi "odamlar ilovada
/// nima qilyapti?" degan savolga javob ololmasdi.
///
/// ═══ NIMA UCHUN AYNAN SHU HODISALAR ═══
///
/// Ro'yxat ATAYIN qisqa. Hamma bosishni yozish oson, lekin keyin undan
/// hech narsa o'qib bo'lmaydi — shovqin ichida javob ko'rinmaydi.
/// Shuning uchun har bir hodisa BITTA aniq savolga javob beradi
/// (`AnalyticsEvent` izohlariga qarang). Yangi hodisa qo'shishdan oldin
/// "bu qaysi savolga javob beradi?" degan savolga javob bo'lishi kerak.
///
/// ═══ MAXFIYLIK ═══
///
/// 🔴 Ism, telefon raqami, chat matni va manzilning ANIQ nuqtasi
/// YUBORILMAYDI. Faqat shahar nomlari, sonlar va ID'lar. Maxfiylik
/// siyosatiga ham shu tarzda yozilgan — u yerda va'da qilinganidan
/// ko'proq ma'lumot yig'ish eng yomon xil xato.
///
/// ═══ ISHLAMAY QOLSA ═══
///
/// Statistika HECH QACHON foydalanuvchi oqimini to'xtatmaydi: xato
/// yutiladi, natija kutilmaydi (`unawaited`), kirmagan foydalanuvchida
/// umuman yuborilmaydi.
class Analytics {
  Analytics(this._client);

  final ApiClient _client;

  /// Hodisani yuborish. Chaqiruvchi natijani KUTMAYDI.
  void log(String event, {Map<String, dynamic> payload = const {}}) {
    // `unawaited` emas, ataylab `.ignore()`: xato ham, natija ham kerak emas.
    _send(event, payload).ignore();
  }

  Future<void> _send(String event, Map<String, dynamic> payload) async {
    try {
      await _client.dio.post<dynamic>(
        '/analytics/events',
        data: {'event_type': event, 'payload': payload},
      );
    } on DioException catch (error) {
      // Jim: statistika yiqilgani foydalanuvchiga hech qanday aloqasi yo'q.
      debugPrint('Analitika yuborilmadi ($event): ${error.message}');
    }
  }
}

/// Yuboriladigan hodisalar. Har biri BITTA savolga javob beradi.
abstract final class AnalyticsEvent {
  /// «Qaysi yo'nalishlar qidirilyapti va ularda safar BORMI?»
  ///
  /// 🔴 Bu ro'yxatdagi eng qimmatli hodisa. Natija soni bilan birga
  /// yuborilgani uchun egasi "talab bor, taklif yo'q" yo'nalishlarni
  /// ko'radi — ya'ni qayerga haydovchi jalb qilish kerakligini biladi.
  /// Boshqa hech qanday manbadan bu ma'lumotni olib bo'lmaydi.
  static const search = 'search_performed';

  /// «Qidiruvdan safar sahifasiga qanchasi o'tadi?»
  static const rideOpened = 'ride_opened';

  /// «Safar sahifasidan bronga qanchasi yetib boradi?»
  ///
  /// Qidiruv → ochish → bron zanjiri odam qayerda to'xtab qolishini
  /// ko'rsatadi. Uchtasi birga ma'noga ega, alohida emas.
  static const bookingCreated = 'booking_created';

  /// «Haydovchilar e'lon berayaptimi?» — taklif tomonining o'lchovi.
  static const ridePublished = 'ride_published';

  /// «Paket tugagani uchun tariflar ochilgani — nechta va qanchasi
  /// sotib olishga aylanadi?»
  static const paywallShown = 'paywall_shown';

  /// «Qaysi tarif tanlanyapti va to'lov boshlanganidan keyin nima
  /// bo'lyapti?» — to'lov oqimidagi uzilishni ko'rsatadi.
  static const planPurchaseStarted = 'plan_purchase_started';
}

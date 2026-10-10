import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/telematics_repository.dart';

/// HAYDOVCHI joylashuvini serverga yuborib turadi (`POST /telematics/ping`).
///
/// 🔴 NEGA KERAK: safar boshlangach yo'lovchi KO'R bo'lib qolardi —
/// haydovchi yaqinmi, kechikayaptimi, umuman yo'ldami? Yagona yo'l —
/// qo'ng'iroq qilish. Yandex Go va inDrive'ning asosiy ustunligi shu.
///
/// ─────────────────────────────────────────────────────────────────
/// 🔴 2026-08-30 — FON REJIMI QO'SHILDI (egasi roziligi bilan)
/// ─────────────────────────────────────────────────────────────────
///
/// Ilgari bu oddiy `Timer` edi va u FAQAT ilova ekranda turganda
/// ishlardi. Ya'ni haydovchi telefonni cho'ntagiga solishi bilan
/// ping to'xtardi va yo'lovchi mashinani YO'QOTARDI — «jonli
/// kuzatuv» degan va'daning ma'nosi qolmasdi. Aynan shuni egasi
/// ko'rgan: «Yandexda ko'rish mumkin, bizda mumkin emas».
///
/// Endi joylashuv OQIM orqali olinadi va Android'da OLDINGI PLAN
/// XIZMATI sifatida ishlaydi (`ForegroundNotificationConfig`):
/// tizim panelida doimiy bildirishnoma turadi va Android jarayonni
/// o'ldirmaydi. Ekran o'chsa ham ping ketaveradi.
///
/// 🔑 NEGA AYNAN OLDINGI PLAN XIZMATI, `ACCESS_BACKGROUND_LOCATION` EMAS:
/// ikkinchisi Google'ning eng qattiq tekshiruvidan o'tadi (video bilan
/// ariza, haftalab kutish, rad etilishi mumkin) va bizga KERAK EMAS —
/// biz joylashuvni faqat safar davomida, foydalanuvchi O'ZI boshlagan
/// ishda olamiz. Oldingi plan xizmati aynan shu holat uchun. Manifestda
/// shuning uchun `FOREGROUND_SERVICE_LOCATION` bor,
/// `ACCESS_BACKGROUND_LOCATION` esa ATAYIN yo'q.
///
/// ⚠️ Doimiy bildirishnoma — MAJBURIY, yashirib bo'lmaydi va yashirish
/// kerak ham emas: odam telefoni joyini yuborayotganini bilishi shart.
///
/// ⚠️ Ruxsat SO'RALMAYDI, faqat BOR-YO'QLIGI tekshiriladi: safar
/// o'rtasida to'satdan chiqadigan tizim oynasi haydovchini chalg'itadi.
/// Ruxsat yo'q bo'lsa xizmat jimgina ishlamaydi — safar buzilmaydi.
class LivePing {
  LivePing(this._repo);

  final TelematicsRepository _repo;

  StreamSubscription<Position>? _sub;
  Timer? _deadline;
  DateTime? _lastSent;

  /// Serverga yuborish oralig'i: 20 soniya — ETA aniqligi bilan
  /// batareya orasidagi murosa.
  ///
  /// GPS oqimi bundan tez-tez kelishi mumkin (masalan mashina tez
  /// yursa), lekin biz uni SHU chegara bilan siyraklashtiramiz:
  /// serverga har soniyada yozishning ma'nosi yo'q.
  static const _minGap = Duration(seconds: 20);

  /// ⚠️ XAVFSIZLIK KLAPANI. Haydovchi safarni «Yakunlandi» deb
  /// belgilamasa, xizmat abadiy ishlab, batareyani tunab yeb qo'yardi.
  /// 12 soat — O'zbekiston bo'ylab eng uzun safardan ham uzoq.
  static const _maxRun = Duration(hours: 12);

  bool get isRunning => _sub != null;

  /// [notificationTitle] / [notificationText] — tizim panelidagi doimiy
  /// bildirishnoma matni. Tilga bog'liq, shuning uchun chaqiruvchidan
  /// keladi (`LivePing` da `BuildContext` yo'q).
  Future<void> start({
    required String notificationTitle,
    required String notificationText,
    required String notificationChannelName,
  }) async {
    if (_sub != null) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final settings = _settings(
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      notificationChannelName: notificationChannelName,
    );

    try {
      _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
        _onPosition,
        // Oqim yiqilsa (GPS o'chirildi, ruxsat qaytarib olindi) —
        // jimgina to'xtaymiz. Haydovchiga ko'rsatiladigan xato emas:
        // u ruldа va bu ma'lumot unga hech nima bermaydi.
        onError: (Object error) {
          debugPrint('LivePing oqimi to\'xtadi: $error');
          stop();
        },
        cancelOnError: true,
      );
    } catch (error) {
      debugPrint('LivePing boshlanmadi: $error');
      return;
    }

    _deadline = Timer(_maxRun, stop);

    // Birinchi ping DARHOL: oqimning birinchi nuqtasini kutish
    // yo'lovchiga «ma'lumot yo'q» bo'lib ko'rinardi.
    unawaited(_sendCurrent());
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _deadline?.cancel();
    _deadline = null;
    _lastSent = null;
  }

  /// Platformaga qarab sozlama. Android'da oldingi plan xizmati
  /// yoqiladi, iOS'da esa tizimning o'z fon rejimi ishlatiladi.
  LocationSettings _settings({
    required String notificationTitle,
    required String notificationText,
    required String notificationChannelName,
  }) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        // 25 metr: shahar ichida burilishlarni ushlaydi, turgan
        // mashinada esa bekorga nuqta yubormaydi.
        distanceFilter: 25,
        intervalDuration: _minGap,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: notificationTitle,
          notificationText: notificationText,
          notificationChannelName: notificationChannelName,
          // `setOngoing` — foydalanuvchi surib yubora olmasin: xizmat
          // ishlab turganda bildirishnoma yo'qolsa, odam joyi
          // yuborilayotganidan BEXABAR qoladi.
          setOngoing: true,
          // Ekran o'chsa ham protsessor uyg'oq tursin, aks holda
          // Android nuqtalarni to'plab, uyg'onganda BIRDANIGA
          // yuboradi va yo'lovchi mashinani sakragan holda ko'radi.
          enableWakeLock: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        // iOS'da fon rejimi `Info.plist` dagi `location` rejimiga
        // bog'liq; ko'k indikatorni yashirmaymiz — Android'dagi
        // doimiy bildirishnoma bilan bir xil ochiqlik.
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );
  }

  void _onPosition(Position position) {
    final last = _lastSent;
    // Oqim `distanceFilter` sabab tez-tez kelishi mumkin — serverga
    // baribir 20 soniyada bir marta yozamiz.
    if (last != null && DateTime.now().difference(last) < _minGap) return;
    unawaited(_send(position));
  }

  Future<void> _sendCurrent() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await _send(position);
    } catch (_) {
      // Birinchi nuqta kelmasa ham oqim o'z ishini qiladi.
    }
  }

  Future<void> _send(Position position) async {
    // Vaqtni YUBORISHDAN OLDIN belgilaymiz: tarmoq sekin bo'lsa
    // navbatga o'nlab so'rov to'planib qolardi.
    _lastSent = DateTime.now();
    try {
      await _repo.ping(
        lat: position.latitude,
        lon: position.longitude,
        speed: position.speed,
        heading: position.heading,
      );
    } catch (_) {
      // Xato YUTILADI: bitta yiqilgan ping hech nimani buzmaydi va
      // haydovchiga ko'rsatiladigan xabar emas. Keyingi urinish 20
      // soniyadan keyin.
    }
  }
}

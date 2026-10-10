import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'format.dart';
import 'push_actions.dart';

/// Manifestdagi kanallar bilan AYNAN bir xil bo'lishi shart
/// (`android/app/src/main/res/values/strings.xml` + `MainActivity.kt`).
/*
 * 🔴 KANAL ID'si «v2» — ESKISINI TUZATIB BO'LMAYDI (2026-08-28).
 *
 * Egasi: «ilovadan tashqarida ovoz bilan keladi-yu, tepadan SMS kabi
 * chiqmayapti». Sabab topildi:
 *
 *   Manifestda `yolyolakay_default` FCM ning standart kanali deb
 *   e'lon qilingan, LEKIN u hech qachon YARATILMAGAN edi. Ilova yopiq
 *   bo'lganda bildirishnomani Android ning O'ZI chizadi va kanal yo'q
 *   bo'lsa uni O'ZI yaratadi — `IMPORTANCE_DEFAULT` bilan. Bu esa
 *   AYNAN «ovoz bor, banner yo'q» degani.
 *
 * ⚠️ Android'da kanal bir marta yaratilgach uning muhimligini ILOVA
 * KO'TARA OLMAYDI — buni faqat foydalanuvchi sozlamalardan qiladi.
 * Shuning uchun eski ID ni tuzatishning imkoni yo'q va YANGI ID
 * olinadi. Eskisi `deleteNotificationChannel` bilan o'chiriladi, aks
 * holda tizim sozlamalarida o'lik kanal bo'lib osilib qolardi.
 *
 * 🔑 ID uch joyda AYNAN bir xil bo'lishi shart:
 *   • shu yer,
 *   • `android/app/src/main/res/values/strings.xml`,
 *   • manifestdagi `default_notification_channel_id`.
 */
/// 🔑 OMMAVIY: mahalliy bildirishnoma yuboradigan HAMMA joy shu nomni
/// ishlatishi shart (`route_watcher`, `trip_reminders`,
/// `car_moderation_watch`).
///
/// 🔴 07.09.2026 da topildi: ular eski `yolyolakay_default` ga yozardi,
/// push esa `_v3` ga. Android'da bu ikkita ALOHIDA kanal degani —
/// `flutter_local_notifications` mavjud bo'lmagan kanalni o'zi yaratadi,
/// ya'ni odamda «Bildirishnomalar» yonida ikkinchi, ovozsiz kanal paydo
/// bo'lardi va u BIRINCHISINI jimlatganda ham chiqaverardi.
const _channelDefault = 'yolyolakay_default_v3';

/// Yuqoridagining OMMAVIY nomi — mahalliy bildirishnoma yuboradigan
/// hamma joy shuni ishlatadi (`route_watcher`, `trip_reminders`,
/// `car_moderation_watch`).
///
/// ⚠️ Literal ATAYIN `_channelDefault` da qoladi: `push_channel_ids_test`
/// aynan shu satrni o'qib manifest bilan solishtiradi. Qiymatni bu yerga
/// ko'chirsak qo'riqchi manbani topolmay qoladi (07.09.2026 da shunday
/// bo'ldi ham).
const defaultChannelId = _channelDefault;

/// ILOVANING O'ZI yaratgan bildirishnoma (kuzatuvchilar, eslatmalar).
///
/// ⚠️ Serverdan kelgan push uchun EMAS — u pastda,
/// `showLocalNotification(RemoteMessage)`.
///
/// 🔑 Nega funksiya: kanal, muhimlik va ovoz sozlamalari BIR joyda
/// tursin. Ilgari har bir kuzatuvchi o'z `AndroidNotificationDetails`
/// ini yozardi va shu sababli ikkitasi eski kanalga tushib qolgandi
/// (07.09.2026 da topildi).
Future<void> showAppNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String title,
  required String body,
}) => plugin.show(
  id,
  title,
  body,
  const NotificationDetails(
    android: AndroidNotificationDetails(
      defaultChannelId,
      'Bildirishnomalar',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  ),
);

/// `res/raw/yol_ovoz.wav` — safar xabarlarining OVOZI.
///
/// 🔴 NEGA KANAL YANA YANGILANDI (`_v2` → `_v3`, 2026-08-28):
/// kanalning ovozi ham, muhimligi kabi, YARATILGANDAN KEYIN
/// o'zgartirib bo'lmaydi. `_v2` allaqachon 1026 relizida odamlarda
/// tizim ovozi bilan yaratilgan — unga ovoz qo'shishning imkoni yo'q.
///
/// 🔑 Fayl manzili NOM bo'yicha saqlanadi
/// (`android.resource://<paket>/raw/yol_ovoz`), raqamli resurs ID
/// bo'yicha emas. Ya'ni faylning O'ZINI keyingi relizda almashtirsak
/// ovoz o'zgaradi va kanalni QAYTA YARATISH shart emas.
///
/// Hozirgi fayl (07.09.2026) — sun'iy ovoz: «Yolyolakay» deb aytiladi.
/// Yasovchisi `tools/ovoz_yasash.py` (gTTS, TURKCHA ovoz — o'zbek tili
/// qo'llanmaydi, turkcha imlo esa fonetik jihatdan eng yaqini).
/// Ilgari bu yerda vaqtinchalik ohang turardi. Egasi o'z ovozini
/// yozganda shu nom bilan almashtiriladi — kod tegmaydi.
const _voiceSound = 'yol_ovoz';

/// Chat xabarlari alohida kanalda: foydalanuvchi safar xabarlarini o'chirmasdan
/// FAQAT chatni jimlatishi (yoki aksincha) mumkin bo'lsin. Ovoz/vibratsiya
/// kanalning o'zida yoqilgan — Android'da bularni har bir bildirishnoma emas,
/// KANAL belgilaydi.
const _channelChat = 'yolyolakay_chat_v3';

/// Eski kanallar — `IMPORTANCE_DEFAULT` bilan qotib qolgan (izohi
/// yuqorida). Faqat o'chirish uchun ro'yxatda turadi.
const _legacyChannels = [
  'yolyolakay_default',
  'yolyolakay_chat',
  'yolyolakay_default_v2',
  'yolyolakay_chat_v2',
];

/// Ilova YOPIQ yoki fonda turganda kelgan xabar.
///
/// 🔴 NEGA KERAK (2026-08-13, egasi: "push telefonning o'ziga kelmayapti"):
/// FCM tizim bildirishnomasini FAQAT `notification` bloki bo'lgan xabarda
/// o'zi chizadi. Backend faqat `data` yuborsa (Go tomonda eng keng tarqalgan
/// shakl), telefonda HECH NIMA ko'rinmaydi — xabar jimgina ilovaga tushadi.
/// Shu holatda bildirishnomani ilovaning o'zi ko'rsatishi kerak.
///
/// `notification` bloki bo'lsa TEGMAYMIZ: aks holda bitta xabar uchun ikkita
/// bildirishnoma chiqadi.
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  if (message.notification != null) return;
  try {
    // Fon isolate'ida plaginlar avtomatik ro'yxatga OLINMAYDI — usiz
    // `flutter_local_notifications` "MissingPluginException" beradi.
    DartPluginRegistrant.ensureInitialized();
    await Firebase.initializeApp();
    await showLocalNotification(message);
  } catch (error) {
    debugPrint('Fon bildirishnomasi ko\'rsatilmadi: $error');
  }
}

/// Lokal bildirishnomalar plagini — ISHGA TUSHIRILGAN holda.
///
/// 🔴 NEGA BITTA JOYDA: `initialize` bosish callback'ini ham ro'yxatdan
/// o'tkazadi. Ilgari u faqat bildirishnoma CHIZILAYOTGANDA (fon isolate'ida)
/// chaqirilardi — ya'ni ilova tirik turganda foydalanuvchi bosgan
/// bildirishnoma hech qayerga bormasdi. Endi `PushService.init` ham shu
/// funksiyani chaqiradi, ikkala isolate'da ham callback ulangan bo'ladi.
/// Plagin singleton — takroriy chaqiruv zararsiz.
Future<FlutterLocalNotificationsPlugin> _localNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notification'),
      iOS: DarwinInitializationSettings(
        // Ruxsat `PushService.init` da FCM orqali so'raladi — bu yerda
        // qayta so'ralsa foydalanuvchi ikkita oyna ko'rardi.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
    onDidReceiveNotificationResponse: _onTapLocal,
    onDidReceiveBackgroundNotificationResponse: _onTapLocalBackground,
  );
  await _ensureChannels(plugin);
  return plugin;
}

/// KANALLARNI ANIQ YARATADI — push kelishidan OLDIN.
///
/// 🔴 NEGA SHART (izohi `_channelDefault` da): ilova yopiq bo'lganda
/// bildirishnomani Android ning o'zi chizadi. Kanal oldindan
/// yaratilmagan bo'lsa u `IMPORTANCE_DEFAULT` bilan o'zi yaratadi va
/// banner CHIQMAYDI — faqat ovoz eshitiladi.
///
/// `Importance.max` ATAYIN: `high` da ham banner chiqadi, lekin `max`
/// ekran qulflangan holatda ham ustuvor turadi. Safar xabari — vaqtga
/// bog'liq narsa, odam uni keyin ko'rsa foydasi qolmaydi.
Future<void> _ensureChannels(FlutterLocalNotificationsPlugin plugin) async {
  if (kIsWeb || !Platform.isAndroid) return;
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (android == null) return;

  // Eskilarini olib tashlaymiz — ular tuzatib bo'lmaydigan holatda va
  // sozlamalarda o'lik yozuv bo'lib qolardi.
  for (final id in _legacyChannels) {
    try {
      await android.deleteNotificationChannel(id);
    } catch (_) {
      /* bo'lmasa ham ziyoni yo'q */
    }
  }

  await android.createNotificationChannel(
    const AndroidNotificationChannel(
      _channelDefault,
      'Bildirishnomalar',
      description: 'Bron, safar va tizim xabarlari',
      importance: Importance.max,
      playSound: true,
      // Ovozli xabar FAQAT shu kanalda. Chat kuniga o'nlab keladi va
      // har biriga gapirsa ilova o'chiriladi — u quyida tizim ovozida
      // qoldirilgan. Kanallar alohida bo'lgani uchun foydalanuvchi
      // ovozni sozlamalardan o'zi ham jimlata oladi.
      sound: RawResourceAndroidNotificationSound(_voiceSound),
      enableVibration: true,
    ),
  );
  await android.createNotificationChannel(
    const AndroidNotificationChannel(
      _channelChat,
      'Chat xabarlari',
      description: 'Hamroh va haydovchidan kelgan xabarlar',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ),
  );
}

/// Telefonda bildirishnomalar YOQILGANMI.
///
/// 🔴 NEGA KERAK: Android 13+ da ruxsat bir marta so'raladi. "Ruxsat
/// bermayman" bosilsa ilova butun umri davomida JIM qoladi — hech qanday
/// xato, hech qanday belgi yo'q. Foydalanuvchi esa "bildirishnoma
/// kelmayapti" deb ilovani ayblaydi, biz esa backendni. Shuning uchun
/// holatni o'qib, ekranda ochiq aytamiz.
///
/// Ruxsatdan tashqari, foydalanuvchi keyinchalik sozlamalardan
/// bildirishnomani butunlay o'chirib qo'yishi ham mumkin — `areNotifications
/// Enabled` ikkala holatni ham qamrab oladi.
///
/// Aniqlab bo'lmasa `true` qaytadi: bilmagan holda ogohlantirish
/// ko'rsatishdan ko'rsatmaslik afzal (yolg'on xavotir eng yomon variant).
Future<bool> notificationsEnabled() async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    if (Platform.isAndroid) {
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? true;
    }
    if (Platform.isIOS) {
      final ios = plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = (await ios?.checkPermissions())?.isEnabled;
      return granted ?? true;
    }
  } catch (_) {
    // Plagin yo'q platforma (test, desktop) — bezovta qilmaymiz.
  }
  return true;
}

/// SUHBAT BILDIRISHNOMASINING RAQAMI — bitta joyda hisoblanadi.
///
/// 🔴 NEGA ALOHIDA (egasi, 2026-09-04: «push keladi, ichiga kiraman,
/// lekin tepada qolib ketyapti»): ko'rsatish va O'CHIRISH bir xil
/// raqamni bilishi shart. Ikki joyda qo'lda hisoblansa, ertaga
/// biri o'zgarib bildirishnoma abadiy osilib qoladi.
int chatNotificationId(String peerId) => peerId.hashCode;

/// Bitta suhbatning bildirishnomasini olib tashlaydi.
///
/// Chat ekrani ochilganda chaqiriladi: odam xabarni O'QIDI, ya'ni
/// status-bardagi eslatmaning vazifasi tugadi. Ilgari u o'sha yerda
/// qolaverardi — bosib kirilgan bo'lsa ham, ichkaridan ochilgan bo'lsa
/// ham (kodda `cancel` chaqiruvining O'ZI yo'q edi).
Future<void> dismissChatNotification(String peerId) async {
  try {
    final plugin = await _localNotifications();
    await plugin.cancel(chatNotificationId(peerId));
  } catch (_) {
    // Plagin yo'q platforma (test, desktop) — bezovta qilmaymiz.
  }
}

/// Hamma bildirishnomani olib tashlaydi.
///
/// Bildirishnomalar ekrani ochilganda yoki «hammasini o'qilgan qil»
/// bosilganda: odam ro'yxatni KO'RDI, status-barda ularni saqlash
/// ma'nosiz.
Future<void> dismissAllNotifications() async {
  try {
    final plugin = await _localNotifications();
    await plugin.cancelAll();
  } catch (_) {
    // Yuqoridagi izoh.
  }
}

/// BILDIRISHNOMANI O'CHIRUVCHI — ekranlar shu orqali so'raydi.
///
/// 🔑 NEGA SINF (2026-09-04): `flutter_local_notifications` plagini
/// FAQAT qurilmada ishlaydi — testda (Linux) `initialize` xato
/// tashlaydi va hech qanday chaqiruv kanalga yetib bormaydi. Ya'ni
/// «bildirishnoma o'chdimi» degan savolni testda o'lchab bo'lmaydi.
///
/// O'LCHASA BO'LADIGAN savol esa boshqa: EKRAN o'chirishni SO'RADIMI?
/// Aynan shu yo'q edi — butun ilovada birorta `cancel` chaqiruvi yo'q
/// edi va bildirishnoma telefon tepasida qolib ketardi. Shu chegara
/// sinf bilan ajratildi, ya'ni qo'riqchi test uni almashtirib
/// so'rovni ko'ra oladi.
class NotificationDismisser {
  const NotificationDismisser();

  /// Bitta suhbatning bildirishnomasi.
  Future<void> chat(String peerId) => dismissChatNotification(peerId);

  /// Hammasi.
  Future<void> all() => dismissAllNotifications();
}

/// Xabar chat xabarimi — kanal va bildirishnoma raqamini shu belgilaydi.
bool _isChat(Map<String, dynamic> data) {
  final type = '${data['type'] ?? data['event'] ?? ''}'.toLowerCase();
  return type.contains('message') || type.contains('chat');
}

/// Xabarni TELEFON bildirishnomasi sifatida ko'rsatadi (ikonka + rang
/// manifestdan olinadi).
Future<void> showLocalNotification(RemoteMessage message) async {
  final data = message.data;
  // Backend matnni HTML kodlab yuboradi — bannerda `so&#39;m` ko'rinmasin.
  // HTTP/WS tomonida buni transport qatlami qiladi, push esa FCM orqali
  // keladi va o'sha qatlamdan o'tmaydi (izohi `format.dart` da).
  final title = unescapeHtml(
    message.notification?.title ?? '${data['title'] ?? ''}',
  );
  final body = unescapeHtml(
    message.notification?.body ?? '${data['body'] ?? ''}',
  );
  if (title.isEmpty && body.isEmpty) return;

  final chat = _isChat(data);
  final plugin = await _localNotifications();

  /* TUGMA YOZUVLARI — saqlangan tildan. Fon isolate'ida `AppStrings`
     yo'q (izohi `push_actions.dart` da), shuning uchun til
     `SharedPreferences` dan o'qiladi. O'qib bo'lmasa — o'zbekcha. */
  final actionLabels = bookingActionLabels(
    isNewBookingPush(data) ? await savedLocaleCode() : null,
  );

  await plugin.show(
    // Chatda BITTA suhbatga BITTA bildirishnoma: 20 ta xabar kelsa status-bar
    // 20 qatorga to'lib ketmasin, oxirgisi eskisini almashtiradi.
    // Qolgan hodisalar (bron, eslatma) esa har biri alohida ko'rinishi kerak.
    chat
        ? chatNotificationId('${data['peer_id'] ?? data['sender_id'] ?? ''}')
        : message.hashCode,
    title.isEmpty ? null : title,
    body.isEmpty ? null : body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        chat ? _channelChat : _channelDefault,
        chat ? 'Chat xabarlari' : 'Bildirishnomalar',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_notification',
        // Bosilgach O'CHSIN. Plaginda bu odatiy holat, lekin uni ATAYIN
        // yozib qo'yamiz: bu qoida bo'lib qolsin, tasodif emas.
        autoCancel: true,
        // Ekran o'chiq bo'lsa ham ovoz + qalqib chiqish (egasi shuni so'radi).
        playSound: true,
        // 🔴 SHART: `show` kanal mavjud bo'lmasa uni O'ZI yaratadi. Ovoz
        // bu yerda ko'rsatilmasa, kanal birinchi marta AYNAN shu yerda
        // ovozsiz yaralib qolishi va keyin tuzatib bo'lmasligi mumkin.
        sound: chat
            ? null
            : const RawResourceAndroidNotificationSound(_voiceSound),
        enableVibration: true,
        // Chat xabarini Android "suhbat" deb tanisin: ovozi va joylashuvi
        // tizimda xabar sifatida ishlanadi.
        category: chat
            ? AndroidNotificationCategory.message
            : AndroidNotificationCategory.event,
        // Uzun matn kesilmasin.
        styleInformation: BigTextStyleInformation(body),
        /*
         * «QABUL QILAMAN / RAD ETAMAN» — bildirishnomaning O'ZIDA.
         *
         * 🔴 NEGA (egasi, 18.09.2026): bron zanjiri besh qadam edi va
         * kutish Yandex Go bilan solishtirganda eng og'ir farqimiz.
         * Qoidalari va cheklovlari `push_actions.dart` da.
         *
         * ⚠️ `showsUserInterface: true` — ILOVA OCHILADI va amal o'sha
         * yerda bajariladi. Fon isolate'ida qilish token yangilash
         * poygasiga olib borardi (`refresh` aylanadi, eskisi darhol
         * o'ladi) va odam login ekraniga uchib chiqishi mumkin edi.
         *
         * ⚠️ `cancelNotification: true` — tugma bosilishi bilan
         * bildirishnoma YO'QOLADI. Ikki variantni o'ylab ko'rdim:
         *
         *   qoldirish  → amal bajarilgach status-barda «Yangi bron»
         *                yozuvi OSILIB QOLADI va haydovchi uni qayta
         *                bosadi. Bu xato loyihada ALLAQACHON bo'lgan
         *                (04.09.2026: «o'qilgan push status-barda
         *                qolardi»);
         *   o'chirish  → ilova ochilmay qolsa so'rov bildirishnomada
         *                yo'qoladi, LEKIN ro'yxatda qoladi — haydovchi
         *                uni «Safarlarim» da baribir ko'radi.
         *
         * Ikkinchisi tanlandi: bildirishnoma — ESLATMA, manba emas.
         */
        actions: isNewBookingPush(data)
            ? <AndroidNotificationAction>[
                AndroidNotificationAction(
                  bookingAcceptAction,
                  // ⚠️ Matn TUGMADA turadi — tilga qarab o'zgarishi kerak,
                  // lekin fon isolate'ida `AppStrings` YO'Q (context yo'q).
                  // Shuning uchun til pushning O'ZIDAN olinadi: backend
                  // matnni allaqachon foydalanuvchi tilida yuboradi.
                  actionLabels.accept,
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
                AndroidNotificationAction(
                  bookingRejectAction,
                  actionLabels.reject,
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // iOS'da «kanal» tushunchasi yo'q — ovoz HAR BILDIRISHNOMADA
        // ko'rsatiladi. Fayl ilova to'plamining ILDIZIDA turishi shart
        // (`ios/Runner/yol_ovoz.wav`, Xcode `Resources` bosqichida), aks
        // holda iOS jimgina standart ovozga qaytadi.
        //
        // ⚠️ Bu FAQAT biz chizadigan bildirishnomaga taalluqli. Ilova
        // yopiq bo'lganda bildirishnomani iOS o'zi chizadi va ovozni
        // APNs yukidagi `aps.sound` dan oladi — ya'ni u yerda backend
        // ham shu nomni yuborishi kerak (xatda so'raldi).
        sound: chat ? null : '$_voiceSound.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    ),
    // Bosilganda qayerga borishni bilish uchun — `pushTargetFor` shu
    // ma'lumotni o'qiydi.
    payload: jsonEncode(data),
  );
}

/// Bildirishnoma bosilgani — ilova ICHIDA. Statik, chunki plagin ham fon
/// isolate'idan, ham asosiy isolate'dan chaqiradi.
void _onTapLocal(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  final data = _decode(payload);
  // QAYSI TUGMA bosilgani ham yuqoriga uzatiladi — usiz «Qabul qilaman»
  // bilan oddiy bosish farq qilmasdi.
  final action = response.actionId;
  if (action != null && action.isNotEmpty) data[pushActionKey] = action;
  _tapController.add(data);
}

/// Fon isolate'ida bosilgan bildirishnoma. U yerda router yo'q va bo'lishi
/// ham mumkin emas — ilova ishga tushganda `PushService.init` bu bosishni
/// `getNotificationAppLaunchDetails()` orqali qayta o'qiydi.
@pragma('vm:entry-point')
void _onTapLocalBackground(NotificationResponse response) {}

Map<String, dynamic> _decode(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (_) {
    // Payload buzilgan bo'lsa ham ilova ochilaverishi kerak.
  }
  return const {};
}

/// Bosilgan bildirishnomalar oqimi (ilova ochiq turganda).
final _tapController = StreamController<Map<String, dynamic>>.broadcast();

/// Push bildirishnomalar (FCM).
///
/// ⚠ `android/app/google-services.json` (va iOS uchun `GoogleService-Info.plist`)
/// LOYIHADA YO'Q — ular Firebase konsolidan olinadi va sirli fayl bo'lgani
/// uchun repozitoriyga qo'shilmagan. Fayl bo'lmasa `Firebase.initializeApp`
/// xato beradi; bu yerda xato YUTILADI va ilova pushsiz, lekin butunlay
/// ishlaydigan holda davom etadi. Push ilovaning asosiy oqimi emas —
/// bildirishnomalar WS orqali ham keladi.
///
/// Fayl qo'shilgach hech qanday kod o'zgarishi kerak emas: `init` o'zi
/// muvaffaqiyatli o'tadi va token backendga yuboriladi.
class PushService {
  PushService({
    required this.onToken,
    required this.onMessage,
    required this.onOpen,
  });

  /// Token olinganda (va yangilanganda) chaqiriladi — backendga yuborish
  /// chaqiruvchining ishi, chunki bu qatlam `ApiClient`ni bilmaydi.
  final Future<void> Function(String token) onToken;

  /// Ilova ochiq turganda kelgan xabar — ilova ichidagi banner ko'rsatiladi
  /// (tizim bildirishnomasi foreground'da chiqmaydi). `data` bannerni
  /// BOSGANDA qayerga o'tishni aniqlash uchun kerak.
  final void Function(String title, String body, Map<String, dynamic> data)
  onMessage;

  /// Foydalanuvchi bildirishnomani BOSDI — tegishli ekranga o'tkazish kerak.
  /// Manzilni `push_routes.dart` hisoblaydi, ochish esa chaqiruvchining ishi
  /// (bu qatlam router'ni bilmaydi).
  final void Function(Map<String, dynamic> data) onOpen;

  bool _available = false;
  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _messages;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<Map<String, dynamic>>? _taps;

  /// Push mavjudmi — profil ekranida holatni ko'rsatish uchun.
  bool get isAvailable => _available;

  /// Ishga tushirish. HECH QACHON xato otmaydi.
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (error) {
      // Odatda: google-services.json yo'q. Ilovani to'xtatmaymiz.
      debugPrint('Push o\'chirilgan (Firebase sozlanmagan): $error');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Android 13+ va iOS'da ruxsat majburiy. Rad etilsa ham davom etamiz.
      await messaging.requestPermission();

      // iOS: ilova OCHIQ turganda tizim banneri KERAK EMAS (ilova ichidagi
      // banner ko'rsatiladi), lekin OVOZ kerak — chat xabari eshitilsin.
      if (!kIsWeb && Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: true,
        );
      }

      // Ilova YOPIQ bo'lganda kelgan ma'lumotli xabar (yuqoridagi izoh).
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

      _messages = FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        // Push FCM orqali keladi va transport interceptor'idan o'tmaydi —
        // HTML kodlarini shu yerda ochamiz (yuqoridagi izoh).
        final title = unescapeHtml(
          notification?.title ?? '${message.data['title'] ?? ''}',
        );
        final body = unescapeHtml(
          notification?.body ?? '${message.data['body'] ?? ''}',
        );
        if (title.isNotEmpty || body.isNotEmpty) {
          onMessage(title, body, message.data);
        }
      });

      // ===== Bosish =====
      // Uch xil yo'l bilan kelishi mumkin, uchalasi ham ushlanishi SHART:
      //   1) FCM `notification` bloki, ilova FONDA edi -> onMessageOpenedApp
      //   2) FCM `notification` bloki, ilova O'CHIQ edi -> getInitialMessage
      //   3) biz o'zimiz chizgan (data-only) bildirishnoma -> plagin javobi
      // Ilgari birortasi ham ulanmagan edi: push bosilsa ilova shunchaki
      // ochilardi va foydalanuvchi kerakli ekranni QO'LDA qidirardi.
      _opened = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => onOpen(message.data),
      );
      _taps = _tapController.stream.listen(onOpen);

      final initial = await messaging.getInitialMessage();
      if (initial != null) onOpen(initial.data);

      final plugin = await _localNotifications();
      final launch = await plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true &&
          payload != null &&
          payload.isNotEmpty) {
        final data = _decode(payload);
        /* ⚠️ ILOVA O'CHIQ turganda bosilgan TUGMA ham shu yo'ldan
           keladi: `actionId` aynan shu yerda o'qilmasa, «Qabul
           qilaman» bosilgan bo'lsa ham ilova shunchaki ochilardi. */
        final action = launch?.notificationResponse?.actionId;
        if (action != null && action.isNotEmpty) data[pushActionKey] = action;
        onOpen(data);
      }

      // ===== Token =====
      // iOS'da FCM tokeni APNs tokenisiz OLINMAYDI — `getToken()` xato beradi.
      // APNs tokeni tizimdan biroz kechikib keladi, shuning uchun kutamiz.
      if (!kIsWeb && Platform.isIOS) {
        for (var i = 0; i < 10; i++) {
          if (await messaging.getAPNSToken() != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }

      // Token qurilma/o'rnatishga bog'liq va vaqti-vaqti bilan yangilanadi —
      // ikkalasini ham backendga yuboramiz (o'chirish endpointi yo'q, eskisini
      // backend o'zi tozalaydi).
      _tokenRefresh = messaging.onTokenRefresh.listen(onToken);

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await onToken(token);

      _available = true;
    } catch (error) {
      debugPrint('Push ishga tushmadi: $error');
    }
  }

  void dispose() {
    _tokenRefresh?.cancel();
    _messages?.cancel();
    _opened?.cancel();
    _taps?.cancel();
  }
}

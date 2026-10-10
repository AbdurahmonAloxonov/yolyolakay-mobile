import 'dart:convert';

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/api/token_storage.dart';
import '../core/api/ws_client.dart';
import '../core/analytics.dart';
import '../core/car_moderation_watch.dart';
import '../core/cities.dart';
import '../core/drafts.dart';
import '../core/local_cache.dart';
import '../core/local_flags.dart';
import '../core/route_watch.dart';
import '../core/route_watcher.dart';
import '../l10n/strings.dart';
import '../core/geo.dart';
import '../core/geocoder.dart';
import '../core/push.dart';
import '../data/models/chat.dart';
import '../data/models/rating.dart';
import '../data/repositories/notifications_repository.dart';
import '../features/rides/live_ping.dart';
import '../features/search/search_filters.dart';
import '../data/models/billing.dart';
import '../data/models/booking.dart';
import '../data/models/parcel.dart';
import '../data/models/support.dart';
import '../data/offer_memory.dart';
import '../data/models/ride.dart';
import '../data/models/auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/trip_reminders.dart';
import '../core/weather.dart';
import '../data/models/user.dart';
import '../core/api/device.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/billing_repository.dart';
import '../data/models/telematics.dart';
import '../data/repositories/parcels_repository.dart';
import '../data/repositories/support_repository.dart';
import '../core/outbox.dart';
import '../data/repositories/telematics_repository.dart';
import '../data/repositories/rating_repository.dart';
import '../data/repositories/rides_repository.dart';
import '../data/repositories/media_repository.dart';
import '../data/repositories/users_repository.dart';
import 'theme.dart';

// ===== Infratuzilma =====

/// `main`da yuklangan nusxa bilan override qilinadi (tokenlar diskdan
/// o'qilishi async, ilova esa sinxron token kerak bo'ladigan interceptor bilan
/// ishlaydi — shuning uchun oldindan yuklab, tayyor holda beramiz).
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => throw UnimplementedError('main.dart da override qilinadi'),
);

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main.dart da override qilinadi'),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(tokens: ref.watch(tokenStorageProvider));
  // Refresh butunlay yiqilganda — login ekraniga qaytarish.
  client.onSessionExpired = () {
    ref.read(authControllerProvider.notifier).sessionExpired();
  };
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(ref.watch(apiClientProvider)),
);

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheProvider),
  ),
);

/// Qoralamalar — yozilgan, lekin yuborilmagan matn (izohi `drafts.dart` da).
final draftsProvider = Provider<Drafts>(
  (ref) => Drafts(ref.watch(sharedPrefsProvider)),
);

/// Mahalliy belgilar — server saqlay olmaydigan holat
/// (izohi `core/local_flags.dart` da: bekor qilish so'rovi, posilka yopilishi).
final localFlagsProvider = Provider<LocalFlags>(
  (ref) => LocalFlags(ref.watch(sharedPrefsProvider)),
);

/// Offline kesh — repozitoriylarga uzatiladi (izohi `local_cache.dart` da).
final localCacheProvider = Provider<LocalCache>(
  (ref) => LocalCache(ref.watch(sharedPrefsProvider)),
);

/// OFFLINE NAVBAT — internetsiz qilingan ish yo'qolmasin (`core/outbox.dart`).
///
/// Yuboruvchilar SHU YERDA ulanadi: navbatning o'zi na HTTP'ni, na
/// WebSocket'ni biladi. Aloqa tiklanganда `flush` o'zi chaqiriladi —
/// `ApiClient.connected` va WS ulanishi ikkalasi ham signal beradi, chunki
/// ular MUSTAQIL uzilishi mumkin (internet bor, WS o'lgan holat ham bor).
final outboxProvider = Provider<Outbox>((ref) {
  final outbox = Outbox(ref.watch(sharedPrefsProvider));

  outbox.register(OutboxKind.chatMessage, (item) async {
    final ws = ref.read(wsClientProvider);
    // `online` — handshake HAQIQATAN tugaganmi (`isConnected` emas, izohi
    // `ws_client.dart` da): aks holda xabar "yuborildi" deb belgilanib,
    // hech qayerga bormasdi.
    if (!ws.online.value) return false;
    return ws.sendMessage(
      recipientId: '${item.payload['recipient_id']}',
      content: '${item.payload['content']}',
      rideId: item.payload['ride_id'] as String?,
    );
  });

  outbox.register(OutboxKind.rating, (item) async {
    final rideId = '${item.payload['ride_id']}';
    final revieweeId = '${item.payload['reviewee_id']}';
    final repository = ref.read(ratingRepositoryProvider);

    // Qurilmada allaqachon "baholangan" deb turgan bo'lsa qayta yubormaymiz:
    // navbat kutgan vaqtда odam boshqa qurilmadan baho bergan bo'lishi mumkin.
    if (repository.hasRated(rideId, revieweeId)) {
      throw const OutboxDrop('allaqachon baholangan');
    }

    try {
      await repository.submit(
        SubmitFeedbackRequest(
          rideId: rideId,
          revieweeId: revieweeId,
          score: (item.payload['score'] as num).toInt(),
          comment: item.payload['comment'] as String?,
        ),
      );
      return true;
    } on ApiException catch (e) {
      // 4xx — qayta urinish tuzatmaydi (safar o'chgan, huquq yo'q, takroriy
      // baho). Navbatда abadiy aylanmasin.
      final code = e.statusCode;
      if (code != null && code >= 400 && code < 500) {
        throw OutboxDrop('server rad etdi ($code)');
      }
      return false;
    }
  });

  // Aloqa tiklandi -> navbatni yuboramiz. IKKALA signal ham kerak: internet
  // bor-u WebSocket o'lgan holat ham, aksi ham bo'ladi.
  void onHttpBack() {
    if (ref.read(apiClientProvider).connected.value) unawaited(outbox.flush());
  }

  void onWsBack() {
    if (ref.read(wsClientProvider).online.value) unawaited(outbox.flush());
  }

  final connected = ref.watch(apiClientProvider).connected;
  connected.addListener(onHttpBack);
  final wsOnline = ref.watch(wsClientProvider).online;
  wsOnline.addListener(onWsBack);
  ref.onDispose(() {
    connected.removeListener(onHttpBack);
    wsOnline.removeListener(onWsBack);
  });

  return outbox;
});

final ridesRepositoryProvider = Provider<RidesRepository>(
  (ref) => RidesRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheProvider),
  ),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheProvider),
  ),
);

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingRepository(ref.watch(apiClientProvider)),
);

/// Geokoder — gateway'ga emas, Nominatim'ga chiqadi. Bitta nusxa: ichida
/// so'rovlar orasidagi eng kam vaqt saqlanadi (Nominatim qoidasi).
final geocoderProvider = Provider<Geocoder>(
  // 🔑 Gateway mijozi ZAXIRA geokoder uchun beriladi: Nominatim yiqilsa
  // manzil qidiruvi o'lmasin (izohi `geocoder.dart` da).
  (ref) => Geocoder(api: ref.watch(apiClientProvider).dio),
);

/// Mening qo'llab-quvvatlash murojaatlarim.
final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>(
  (ref) => ref.watch(supportRepositoryProvider).tickets(),
);

/// Foydalanish statistikasi — `POST /analytics/events`.
///
/// Xato yutiladi va natija kutilmaydi: statistika hech qachon
/// foydalanuvchi oqimini to'xtatmaydi (`core/analytics.dart`).
final analyticsProvider = Provider<Analytics>(
  (ref) => Analytics(ref.watch(apiClientProvider)),
);

/// Qo'llab-quvvatlash — `POST /helpdesk/tickets` (backend qurgan, lekin
/// bizga aytmagan; swagger sverkasida topildi 2026-08-16).
final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(ref.watch(apiClientProvider)),
);

final parcelsRepositoryProvider = Provider<ParcelsRepository>(
  (ref) => ParcelsRepository(ref.watch(apiClientProvider)),
);

/// Reyting — prefs kerak, chunki berilgan baholar qurilmada belgilanadi
/// (gateway'da "kimni baholaganman" endpointi yo'q).
final ratingRepositoryProvider = Provider<RatingRepository>(
  (ref) => RatingRepository(
    ref.watch(apiClientProvider),
    ref.watch(sharedPrefsProvider),
  ),
);

/// Doimiy WS ulanish — sessiya bor bo'lsagina ochiladi va chiqishda yopiladi.
final wsClientProvider = Provider<WsClient>((ref) {
  final client = WsClient(ref.watch(tokenStorageProvider));
  ref.onDispose(client.dispose);

  // Kirish/chiqishga qarab ulanish. Chiqqanda socket yopiladi, aks holda
  // eski token bilan qayta ulanishga urinib turadi.
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (next.isAuthenticated && previous?.isAuthenticated != true) {
      client.connect();
    }
  });
  if (ref.read(authControllerProvider).isAuthenticated) client.connect();

  return client;
});

/// WS hodisalari oqimi — banner va ro'yxatlarni yangilash uchun.
final wsEventsProvider = StreamProvider<WsEvent>(
  (ref) => ref.watch(wsClientProvider).events,
);

/// Push (FCM).
///
/// Sessiya paydo bo'lgandagina ishga tushadi: token backendga `Authorization`
/// bilan yuboriladi, kirmagan foydalanuvchida yuboradigan joy yo'q.
/// Firebase sozlanmagan bo'lsa (google-services.json yo'q) jimgina o'chiq
/// qoladi — `core/push.dart` ga qarang.
final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(
    onToken: (token) async {
      try {
        await ref
            .read(notificationsRepositoryProvider)
            .registerPushToken(
              fcmToken: token,
              language: ref.read(localeProvider).languageCode,
              // Backend platformaga qarab yuborish sarlavhalarini tanlaydi
              // (APNs `apns-priority`, Android `priority: high`) — qattiq
              // yozilgan 'android' iOS tokenini noto'g'ri belgilardi.
              platform: Platform.isIOS ? 'ios' : 'android',
            );
      } catch (_) {
        // Token ro'yxatga olinmasa ilova ishlashda davom etadi.
      }
    },
    onMessage: (title, body, data) {
      /*
       * OBUNA FAOLLASHDI — DARHOL YANGILAYMIZ (14.09.2026).
       *
       * Backend Click to'lovni tasdiqlagach `subscription_activated`
       * pushini yuboradi. Bu ilovaga kelgan YAGONA ishonchli signal:
       * odam brauzerdan qaytmagan bo'lsa ham, ekranda hamon eski
       * paket turgan bo'lsa ham — pul o'tgani SHU yerda ma'lum
       * bo'ladi. Bannerni kutib turmaymiz, provayderni o'sha zahoti
       * bekor qilamiz.
       */
      final type = (data['type'] ?? data['event'] ?? '').toString();
      if (type.contains('subscription') || type.contains('payment')) {
        ref.invalidate(subscriptionProvider);
        ref.invalidate(meProvider);
        ref.read(pendingPaymentProvider.notifier).state = null;
      }

      final text = [title, body].where((s) => s.isNotEmpty).join(' — ');
      if (text.isEmpty) return;
      ref.read(pushMessagesProvider.notifier).state = PushBanner(text, data);
    },
    onOpen: (data) => ref.read(pushOpenProvider.notifier).state = data,
  );
  ref.onDispose(service.dispose);

  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (next.isAuthenticated && previous?.isAuthenticated != true) {
      service.init();
    }
  });
  if (ref.read(authControllerProvider).isAuthenticated) service.init();

  return service;
});

/// Ilova ochiq turganda kelgan push — banner uchun matn VA manzil.
///
/// Ma'lumot matn bilan BIRGA yuriydi: bannerni bosgan odam ham xuddi telefon
/// bildirishnomasini bosgandek kerakli ekranga tushishi kerak, buning uchun
/// esa `type`/`peer_id` kabi maydonlar kerak.
class PushBanner {
  const PushBanner(this.text, this.data);

  final String text;
  final Map<String, dynamic> data;
}

/// Oxirgi push — bannerga uzatiladi (WS hodisalari bilan bir xil yo'l).
final pushMessagesProvider = StateProvider<PushBanner?>((ref) => null);

/// Telefonda bildirishnomalar yoqilganmi — ogohlantirish ko'rsatish uchun.
///
/// `invalidate` bilan qayta o'qiladi: foydalanuvchi sozlamalarga borib
/// yoqib qaytganda ogohlantirish o'zi yo'qolishi kerak.
final notificationsEnabledProvider = FutureProvider<bool>(
  (ref) => notificationsEnabled(),
);

/// BOSILGAN pushning xom ma'lumoti. Manzilga aylantirish va ochish
/// `InAppBanner` da — u router bilan bitta daraxtda turadi, bu qatlam esa
/// navigatsiyani bilmaydi (shu sabab router'ni import qilmaydi ham).
/// Bildirishnomani o'chiruvchi — testda almashtiriladi (izohi
/// `NotificationDismisser` da).
final notificationDismisserProvider = Provider<NotificationDismisser>(
  (ref) => const NotificationDismisser(),
);

final pushOpenProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// ===== Auth =====

enum AuthStatus { authenticated, unauthenticated }

/// Auth holati.
///
/// [needsProfile] — `verify-otp` yangi hisob yaratganda (`is_new_user`) yoqiladi:
/// token bor, lekin ism/jins yo'q. Router shu bayroqqa qarab foydalanuvchini
/// ilova ichiga emas, profil to'ldirish ekraniga oladi. Telefon raqami
/// keyingi qadamda `POST /users` uchun kerak, shuning uchun saqlanadi.
class AuthState {
  const AuthState({
    required this.status,
    this.needsProfile = false,
    this.phoneNumber,
  });

  final AuthStatus status;
  final bool needsProfile;
  final String? phoneNumber;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState(
    status: ref.read(tokenStorageProvider).hasSession
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated,
  );

  Future<void> sendOtp(String phoneNumber) =>
      ref.read(authRepositoryProvider).sendOtp(phoneNumber);

  /// `true` qaytsa — hisob YANGI yaratildi, profil to'ldirish kerak.
  /// [onVerified] — kod TO'G'RI ekani ma'lum bo'lgan, lekin sessiya HALI
  /// yoqilmagan lahza.
  ///
  /// 🔑 NEGA KERAK: sessiya yoqilishi bilan router ekranni DARHOL
  /// almashtiradi. Ya'ni OTP ekrani muvaffaqiyat haqida hech narsa
  /// ko'rsatib ulgurmaydi — ilgari shu sababdan tasdiq animatsiyasi
  /// so'rovdan OLDIN o'ynatilardi, natijada kod NOTO'G'RI bo'lganda ham
  /// «hammasi joyida» ko'rinishi chiqib ketardi. Endi ekran yashil
  /// tasdig'ini aynan shu bo'shliqda ko'rsatadi.
  Future<bool> verifyOtp(
    String phoneNumber,
    String code, {
    Future<void> Function()? onVerified,
  }) async {
    final tokens = await ref
        .read(authRepositoryProvider)
        .verifyOtp(phoneNumber, code);
    if (onVerified != null) await onVerified();
    state = AuthState(
      status: AuthStatus.authenticated,
      needsProfile: tokens.isNewUser,
      phoneNumber: phoneNumber,
    );
    ref.invalidate(meProvider);
    return tokens.isNewUser;
  }

  Future<void> loginWithPassword(String phoneNumber, String password) async {
    await ref
        .read(authRepositoryProvider)
        .loginWithPassword(phoneNumber, password);
    state = AuthState(
      status: AuthStatus.authenticated,
      phoneNumber: phoneNumber,
    );
    ref.invalidate(meProvider);
  }

  /// Profil to'ldirildi — endi ilova ichiga kirish mumkin.
  void profileCompleted() {
    state = AuthState(status: state.status, phoneNumber: state.phoneNumber);
    ref.invalidate(meProvider);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
    ref.invalidate(meProvider);
  }

  /// Interceptor chaqiradi — tokenlar allaqachon tozalangan.
  void sessionExpired() =>
      state = const AuthState(status: AuthStatus.unauthenticated);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

// ===== Til =====

/// Standart til — o'zbekcha.
class LocaleController extends Notifier<Locale> {
  static const _key = 'locale';

  /// Qo'llab-quvvatlanadigan kodlar — `AppStrings.Lang` bilan bir xil.
  ///
  /// 🔑 `uz-Cyrl` — O'ZBEK KIRILI (2026-09-08). U alohida TIL emas,
  /// o'sha o'zbek tilining boshqa yozuvi; shuning uchun `Locale` da
  /// `scriptCode` bilan beriladi, `countryCode` bilan EMAS
  /// (`Locale('uz', 'Cyrl')` — bu «Cyrl mamlakati» degan ma'noni
  /// beradi va tizim uni tanimaydi).
  static const supported = {'uz', 'uz-Cyrl', 'ru', 'en'};

  /// Saqlangan kod → `Locale`.
  static Locale localeOf(String code) => code == 'uz-Cyrl'
      ? const Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl')
      : Locale(code);

  @override
  Locale build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    return localeOf(supported.contains(saved) ? saved! : 'uz');
  }

  Future<void> set(String languageCode) async {
    state = localeOf(languageCode);
    await ref.read(sharedPrefsProvider).setString(_key, languageCode);
    await syncToServer(languageCode);
  }

  /// Tilni serverga ham bildiradi.
  ///
  /// 🔴 NEGA (2026-08-28): push va boshqa server matnlari foydalanuvchining
  /// `locale` maydoniga qarab tanlanadi. Ilova uni yubormagani uchun yangi
  /// hisobda `ru` bo'lib qolar va, masalan, «sinov davri boshlandi» xabari
  /// ruscha kelardi — interfeys o'zbekcha bo'lsa ham.
  ///
  /// Kirmagan foydalanuvchida jim o'tkazib yuboriladi va xato hech qachon
  /// yuqoriga chiqmaydi: til allaqachon almashgan, so'rov esa qulaylik.
  Future<void> syncToServer(String languageCode) async {
    try {
      await ref.read(usersRepositoryProvider).saveLocale(locale: languageCode);
    } catch (_) {
      // Kirilmagan yoki tarmoq yo'q — ziyoni yo'q.
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

/// Widget'lardan qulay tekshiruv uchun.
///
/// ⚠ Uch til qo'shilgach bu bayroq FAQAT "o'zbekchami?" degan savolga javob
/// beradi — matn tanlash uchun `AppStrings` ishlating, aks holda inglizcha
/// interfeysda ruscha matn chiqadi.
/// Joriy til — xato xabarlari va sana formatlash uchun.
///
/// 🔴 2026-08-16 da `isUzProvider` (bool) O'RNIGA keldi: ikkilik bayroq
/// "o'zbek emas = rus" degani edi va ingliz tilini tanlagan foydalanuvchi
/// hamma xatoni ruscha ko'rardi.
final langProvider = Provider<Lang>((ref) {
  final locale = ref.watch(localeProvider);
  // ⚠️ `languageCode` YETMAYDI: kirill va lotin ikkalasi ham `uz`.
  // Farq `scriptCode` da.
  return langFromCode(
    locale.scriptCode == 'Cyrl' ? 'uz-Cyrl' : locale.languageCode,
  );
});

/// Joriy til kodi — huquqiy sahifa havolalari va backend uchun
/// ('uz' | 'uz-Cyrl' | 'ru' | 'en').
///
/// Backend `uz-Cyrl` ni qabul qiladi va saqlaydi (08.09.2026 da jonli
/// o'lchandi).
final langCodeProvider = Provider<String>(
  (ref) => langCode(ref.watch(langProvider)),
);

// ===== Tema =====

/// Yorug'/tungi/tizim — tanlov qurilmada saqlanadi.
///
/// Standart `system`: kechasi telefon o'zi tungi rejimga o'tsa ilova ham
/// o'tadi. Foydalanuvchi aniq tanlasa — uniki ustun.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Interfeys USLUBI — Classic yoki Neon. Yorug'likдан (light/dark) mustaqil.
class ThemeStyleController extends Notifier<ThemeStyle> {
  static const _key = 'theme_style';

  @override
  ThemeStyle build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    return saved == 'neon' ? ThemeStyle.neon : ThemeStyle.classic;
  }

  Future<void> set(ThemeStyle style) async {
    state = style;
    await ref.read(sharedPrefsProvider).setString(_key, style.name);
  }
}

final themeStyleProvider = NotifierProvider<ThemeStyleController, ThemeStyle>(
  ThemeStyleController.new,
);

// ===== Katta matn =====

/// KATTA MATN REJIMI — shrift chegarasini ko'taradi.
///
/// 🔴 NEGA (2026-08-25): shrift `1.3` da chegaralangan (izohi `app.dart`
/// da) va bu TIZIM sozlamasi — uni telefon sozlamalarining ichidan topish
/// kerak. Bizning asosiy foydalanuvchimiz esa aynan shu narsani qila
/// olmaydigan odam: ovozli qidiruvni ham AYNAN shuning uchun qildik —
/// klaviatura ular uchun to'siq.
///
/// Endi ilovaning O'ZIDA tugma bor va u chegarani 1.6 ga ko'taradi.
///
/// ⚠️ 1.6 dan yuqori QILINMADI: undan narisiga layout butun qolmaydi
/// (`layout_narrow_test` shu chegarada tekshiradi). Yolg'on va'da berib
/// keyin buzilgan ekran ko'rsatgandan ko'ra, chegarani halol aytish
/// yaxshi.
class BigTextController extends Notifier<bool> {
  static const _key = 'big_text';

  /// Yoqilgan holatdagi chegara. Standarti — `app.dart` dagi 1.3.
  static const maxScale = 1.6;

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPrefsProvider).setBool(_key, value);
  }
}

final bigTextProvider = NotifierProvider<BigTextController, bool>(
  BigTextController.new,
);

/// OVOZ BILAN O'QISH — sozlamadan yoqiladi.
///
/// 🔴 STANDART: O'CHIQ (egasi, 2026-08-27: «sozlamalardan yoqib qo'yish
/// kerak»). Ovoz — bezovta qiluvchi narsa: so'ramasdan gapira boshlagan
/// ilova darhol o'chiriladi va qaytib yoqilmaydi. Odam o'zi yoqsa esa
/// aynan shuni kutadi.
///
/// Kimga kerak: haydovchi to'rt soat telefonga qaramaydi, lekin yo'l
/// haqidagi gapni eshitishi mumkin.
class ReadAloudController extends Notifier<bool> {
  static const _key = 'read_aloud';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPrefsProvider).setBool(_key, value);
  }
}

final readAloudProvider = NotifierProvider<ReadAloudController, bool>(
  ReadAloudController.new,
);

// ===== Oxirgi yo'nalishlar =====

/// Bitta bosishda qayta qidirish uchun (web bilan bir xil: maks 5, eng yangisi
/// birinchi, takrorlar birlashtiriladi).
///
/// Koordinata ham saqlanadi: joy xaritadan yoki geokoderdan tanlangan bo'lsa
/// `resolvePlace` uni ro'yxatdan TOPOLMAYDI va chip bosilganda hech nima
/// bo'lmasdi. Nom — faqat ko'rsatish uchun.
class RecentRoute {
  const RecentRoute({required this.from, required this.to});

  final Place from;
  final Place to;

  String encode() => '${_encodePlace(from)}|${_encodePlace(to)}';

  static String _encodePlace(Place place) =>
      // Nomda vergul bo'lishi mumkin (geokoder) — sonlar OXIRIDAN olinadi.
      '${place.name},${place.lat},${place.lon}';

  static Place? _decodePlace(String raw) {
    final parts = raw.split(',');
    if (parts.length < 3) return null;
    final lon = double.tryParse(parts.removeLast());
    final lat = double.tryParse(parts.removeLast());
    final name = parts.join(',');
    if (lat == null || lon == null || name.isEmpty) return null;
    return Place(name: name, lat: lat, lon: lon, region: '');
  }

  static RecentRoute? decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return null;

    final from = _decodePlace(parts[0]);
    final to = _decodePlace(parts[1]);
    if (from != null && to != null) return RecentRoute(from: from, to: to);

    // Eski format (faqat nomlar) — ro'yxatdan tiklaymiz, topilmasa tashlaymiz.
    final oldFrom = resolvePlace(parts[0]);
    final oldTo = resolvePlace(parts[1]);
    if (oldFrom == null || oldTo == null) return null;
    return RecentRoute(from: oldFrom, to: oldTo);
  }
}

class RecentRoutesController extends Notifier<List<RecentRoute>> {
  static const _key = 'recent_routes';
  static const _max = 5;

  @override
  List<RecentRoute> build() {
    final saved = ref.read(sharedPrefsProvider).getStringList(_key) ?? const [];
    return saved
        .map(RecentRoute.decode)
        .whereType<RecentRoute>()
        .take(_max)
        .toList();
  }

  Future<void> add(Place from, Place to) async {
    if (from.name.isEmpty || to.name.isEmpty) return;
    final next = [
      RecentRoute(from: from, to: to),
      ...state.where(
        (r) => !(r.from.name == from.name && r.to.name == to.name),
      ),
    ].take(_max).toList();

    state = next;
    await ref
        .read(sharedPrefsProvider)
        .setStringList(_key, next.map((r) => r.encode()).toList());
  }
}

final recentRoutesProvider =
    NotifierProvider<RecentRoutesController, List<RecentRoute>>(
      RecentRoutesController.new,
    );

// ===== So'nggi ko'rilgan safarlar =====

/// SO'NGGI KO'RILGAN SAFARLAR.
///
/// 🔴 NEGA (2026-08-25 auditi): odam safarni ochadi, «o'ylab ko'raman»
/// deb chiqadi — va uni QAYTA TOPA OLMAYDI. Qidiruvni boshidan
/// takrorlashi kerak: shahar, sana, filtr. Ko'pchilik takrorlamaydi.
///
/// So'nggi YO'NALISHLAR allaqachon bor edi, lekin ular boshqa narsa:
/// yo'nalish — «qayerdan qayerga», bu esa AYNAN O'SHA safar (narxi,
/// vaqti, haydovchisi bilan).
///
/// Xom JSON saqlanadi — sabab `LocalCache` izohida (modelda to'liq
/// `toJson` yo'q, uni yozish parser bilan chetga chiqadigan ikkinchi
/// manba yaratardi).
class RecentRidesController extends Notifier<List<Ride>> {
  static const _key = 'recent_rides';

  /// Beshta — bir ekranga sig'adigan va odam eslay oladigan miqdor.
  static const _max = 5;

  @override
  List<Ride> build() {
    final rows = ref.read(localCacheProvider).readList(_key) ?? const [];
    return rows.map(Ride.fromJson).take(_max).toList();
  }

  /// Safar ochilganda chaqiriladi. Takrori TEPAGA ko'chadi.
  Future<void> remember(Ride ride) async {
    if (ride.id.isEmpty) return;
    final rows = ref.read(localCacheProvider).readList(_key) ?? const [];
    final next = [
      _display(ride),
      ...rows.where((r) => '${r['id']}' != ride.id),
    ].take(_max).toList();
    await ref.read(localCacheProvider).writeList(_key, next);
    state = next.map(Ride.fromJson).toList();
  }

  /// Kartochkada KO'RSATILADIGAN maydonlar — to'liq `Ride` emas.
  ///
  /// ⚠️ NEGA to'liq `toJson` yozilmadi: modelda u yo'q va uni yozish
  /// parserga PARALLEL ikkinchi manba yaratardi — ikkalasi vaqt o'tib
  /// bir-biridan chetga chiqadi. Bu yerda esa aniq va tor shartnoma:
  /// ro'yxatdagi karta nimani ko'rsatsa, o'sha saqlanadi.
  ///
  /// Safar OCHILGANDA baribir serverdan qayta o'qiladi, ya'ni bu
  /// yozuv faqat ro'yxat uchun "urug'".
  static Map<String, dynamic> _display(Ride ride) => {
    'id': ride.id,
    'origin_address': ride.originAddress,
    'origin_lat': ride.originLat,
    'origin_lon': ride.originLon,
    'destination_address': ride.destinationAddress,
    'destination_lat': ride.destinationLat,
    'destination_lon': ride.destinationLon,
    'departure_time': ride.departureTime?.toIso8601String(),
    'total_seats': ride.totalSeats,
    'available_seats': ride.availableSeats,
    'price_per_seat': ride.pricePerSeat,
    'status': ride.status,
    if (ride.driver != null)
      'driver': {
        'id': ride.driver!.id,
        'name': ride.driver!.name,
        'rating': ride.driver!.rating,
        'avatar': ride.driver!.avatar,
        'gender': ride.driver!.gender,
      },
  };

  Future<void> clear() async {
    await ref.read(localCacheProvider).clear(_key);
    state = const [];
  }
}

final recentRidesProvider = NotifierProvider<RecentRidesController, List<Ride>>(
  RecentRidesController.new,
);

/// O'TGAN HAYDOVCHI — u bilan bir marta yo'lga chiqilgan.
class PastDriver {
  const PastDriver({required this.driver, required this.ride});

  final DriverProfile driver;

  /// O'sha safar — yo'nalishni qayta qidirish uchun (koordinatalari bilan).
  final Ride ride;
}

/// «YANA O'SHA HAYDOVCHI BILAN» — ilgari birga yurgan haydovchilar.
///
/// 🔴 NEGA KERAK (egasi tanlagan band, 2026-08-25): shaharlararo yo'lda
/// odam bir marta yoqqan haydovchini QIDIRIB topmoqchi bo'ladi — bu
/// O'zbekistonda eng tabiiy xatti-harakat («o'sha akaning raqami bormidi?»).
/// Ilgari ilovada bunga yo'l yo'q edi: tarixni varaqlab, bronni topib,
/// safarga kirib, chatni ochish kerak edi.
///
/// ⚠️ TARMOQQA CHIQMAYDI. Manba — bronlar KESHI (`CacheKeys.myBookings`),
/// ya'ni bu ro'yxat qidiruv ekranini ochganda birorta ham so'rov
/// qo'shmaydi va aloqasiz joyda ham ishlaydi.
///
/// ⚠️ Haydovchi bo'yicha SAFAR QIDIRISH ruchkasi gateway'da YO'Q
/// (`/rides/search` faqat koordinata bilan ishlaydi). Shuning uchun
/// bosilganda haqiqiy ikki ish taklif qilinadi: o'sha YO'NALISHNI
/// qidirish yoki haydovchiga YOZISH. Yolg'on «uning safarlari» ro'yxati
/// ko'rsatilmaydi.
final pastDriversProvider = Provider.autoDispose<List<PastDriver>>((ref) {
  final rows =
      ref.watch(localCacheProvider).readList(CacheKeys.myBookings) ??
      const <Map<String, dynamic>>[];

  final seen = <String>{};
  final result = <PastDriver>[];
  // Kesh ro'yxati eng yangisi birinchi bo'lib keladi (backend tartibi).
  for (final row in rows) {
    final booking = Booking.fromJson(row);
    final ride = booking.ride;
    final driver = ride?.driver;
    final id = driver?.id;
    if (ride == null || driver == null || id == null || id.isEmpty) continue;
    // FAQAT haqiqatan birga yurilgan safar: rad etilgan bron «tanish
    // haydovchi» degani emas.
    if (!booking.isConfirmed) continue;
    if (!seen.add(id)) continue;
    result.add(PastDriver(driver: driver, ride: ride));
    if (result.length >= 5) break;
  }
  return result;
});

/// SEVIMLI YO'NALISHLAR — odam o'zi qadagan (uy<->ish kabi). So'nggilardan
/// farqi: avtomatik EMAS, foydalanuvchi tanlaydi va o'chmaydi. `RecentRoute`
/// kodlashи qayta ishlatilади (izoh o'sha yerда).
class FavoriteRoutesController extends Notifier<List<RecentRoute>> {
  static const _key = 'favorite_routes';
  static const _max = 4;

  @override
  List<RecentRoute> build() {
    final saved = ref.read(sharedPrefsProvider).getStringList(_key) ?? const [];
    return saved
        .map(RecentRoute.decode)
        .whereType<RecentRoute>()
        .take(_max)
        .toList();
  }

  bool contains(Place from, Place to) =>
      state.any((r) => r.from.name == from.name && r.to.name == to.name);

  /// Qadalangan bo'lса — olib tashlaydi, aks holда qo'shади (qaytarish).
  Future<void> toggle(Place from, Place to) async {
    if (from.name.isEmpty || to.name.isEmpty) return;
    final exists = contains(from, to);
    final next = exists
        ? state
              .where((r) => !(r.from.name == from.name && r.to.name == to.name))
              .toList()
        : [RecentRoute(from: from, to: to), ...state].take(_max).toList();
    state = next;
    await ref
        .read(sharedPrefsProvider)
        .setStringList(_key, next.map((r) => r.encode()).toList());
  }
}

final favoriteRoutesProvider =
    NotifierProvider<FavoriteRoutesController, List<RecentRoute>>(
      FavoriteRoutesController.new,
    );

// ===== Qidiruv filtrlari =====

/// Qidiruv filtrlari — QURILMADA saqlanadi (izohi `SearchFilters.toJson`
/// da: narx ataylab saqlanmaydi).
const _filtersKey = 'search_filters';

class SearchFiltersController extends Notifier<SearchFilters> {
  @override
  SearchFilters build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_filtersKey);
    if (raw == null) return const SearchFilters();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SearchFilters.fromJson(decoded);
      }
    } catch (_) {
      // Buzilgan yozuv butun qidiruvni yiqitmasin — bo'sh filtrdan
      // boshlaymiz (odam ko'pi bilan bir marta qayta belgilaydi).
    }
    return const SearchFilters();
  }

  void update(SearchFilters filters) {
    state = filters;
    _save(filters);
  }

  void reset() {
    state = const SearchFilters();
    ref.read(sharedPrefsProvider).remove(_filtersKey);
  }

  void _save(SearchFilters filters) {
    final prefs = ref.read(sharedPrefsProvider);
    if (filters.isEmpty) {
      prefs.remove(_filtersKey);
      return;
    }
    prefs.setString(_filtersKey, jsonEncode(filters.toJson()));
  }
}

final searchFiltersProvider =
    NotifierProvider<SearchFiltersController, SearchFilters>(
      SearchFiltersController.new,
    );

final searchSortProvider = StateProvider<SearchSort>(
  (ref) => SearchSort.distance,
);

// ===== Ma'lumot providerlari =====

final meProvider = FutureProvider<MeResponse>(
  (ref) => ref.watch(usersRepositoryProvider).me(),
);

final myRidesProvider = FutureProvider.autoDispose<List<Ride>>(
  (ref) => ref.watch(ridesRepositoryProvider).myRides(),
);

final myBookingsProvider = FutureProvider.autoDispose<List<Booking>>(
  (ref) => ref.watch(ridesRepositoryProvider).myBookings(),
);

/// BEGONA HAYDOVCHINING ochiq safarlari — uning profilidagi «yo'llari»
/// kartasi uchun (`GET /users/{id}/rides`, 16.09.2026 da ochildi).
///
/// `autoDispose`: profildan chiqilgach keshda saqlanib turmasin —
/// begona odamning safarlari bizga boshqa kerak emas.
final driverRidesProvider = FutureProvider.autoDispose
    .family<List<Ride>, String>(
      (ref, driverId) =>
          ref.watch(ridesRepositoryProvider).driverRides(driverId),
    );

/// Kirilgan qurilmalar — `GET /auth/sessions`.
/// `autoDispose`: xavfsizlik ekranidan chiqilgach keshda saqlanib turmasin.
final sessionsProvider = FutureProvider.autoDispose<List<Session>>(
  (ref) => ref.watch(authRepositoryProvider).sessions(),
);

/// Bloklangan foydalanuvchilar — `GET /users/blocked`.
final blockedUsersProvider = FutureProvider.autoDispose<List<User>>(
  (ref) => ref.watch(usersRepositoryProvider).blockedUsers(),
);

/// Ilova tashqi oqimga (Click to'lovi, MyID tasdig'i) chiqib ketdimi.
///
/// Tashqi sayt tugagach bizni ilovaga QAYTARA olmaydi (qaytish manzili
/// backendda yig'iladi va hozircha ilovaga ishora qilmaydi). Shuning uchun
/// odam qo'lda qaytadi — va o'sha paytda obuna qayta o'qilishi SHART, aks
/// holda pul o'tgan bo'lsa ham eski paket ko'rinib turadi.
///
/// `LifecycleRefresh` shu bayroqni ko'rib, qaytishda `subscriptionProvider`
/// va `meProvider` ni yangilaydi va bayroqni tushiradi.
final awaitingExternalFlowProvider = StateProvider<bool>((ref) => false);

/// Boshlangan, lekin natijasi hali noma'lum TO'LOV id'si (14.09.2026).
///
/// 🔑 NEGA: `POST /billing/pay` endi `transaction_id` qaytaradi va
/// `GET /billing/transactions/{id}` AYNAN o'sha to'lov holatini beradi.
/// Ilgari natijani bilishning yagona yo'li obunani qayta o'qib
/// «o'zgardimi?» deb taxmin qilish edi — to'lov rad etilgan odam
/// hech qanday xabar olmasdi va nima bo'lganini tushunmasdi.
///
/// Id shu yerda turadi: odam Click'ga chiqib ketadi, qaytganda
/// `PaymentResultWatcher` shuni ko'rib holatni so'raydi.
final pendingPaymentProvider = StateProvider<String?>((ref) => null);

/// Yuborgan posilkalarim — `GET /parcels/my?role=sender`.
final myParcelsProvider = FutureProvider.autoDispose<List<Parcel>>(
  (ref) => ref.watch(parcelsRepositoryProvider).mine(),
);

/// Telematika: joylashuv, yaqin haydovchilar, marshrut.
final telematicsRepositoryProvider = Provider<TelematicsRepository>(
  (ref) => TelematicsRepository(ref.watch(apiClientProvider)),
);

/// Safar marshruti (masofa + davomiylik).
///
/// 🔴 Bu ma'lumot serverda ALLAQACHON bor edi (`GET /routing/route`), lekin
/// ilova uni umuman so'ramasdi: yo'lovchi safar necha kilometr va necha
/// soatligini bilmasdan bron qilardi (2026-08-14 o'lchovi).
///
/// `family` kaliti — safar ID'si; `autoDispose` emas, chunki bir safar
/// ekrani ochilib-yopilaverishi mumkin va marshrut o'zgarmaydi.
final rideRouteProvider = FutureProvider.family<RouteInfo?, Ride>((
  ref,
  ride,
) async {
  try {
    return await ref
        .watch(telematicsRepositoryProvider)
        .route(
          originLat: ride.originLat,
          originLon: ride.originLon,
          destLat: ride.destinationLat,
          destLon: ride.destinationLon,
        );
  } catch (_) {
    // Marshrut ikkinchi darajali ma'lumot — u kelmasa ham safar sahifasi
    // to'liq ishlaydi, shuning uchun xato ekranga chiqarilmaydi.
    return null;
  }
});

/// Yo'lovchining o'z narx taklifi (qurilma xotirasi) — izohi
/// `data/offer_memory.dart` da.
final offerMemoryProvider = Provider<OfferMemory>(
  (ref) => OfferMemory(ref.watch(sharedPrefsProvider)),
);

/// Men OLIB KETAYOTGAN posilkalar — `GET /parcels/my?role=driver`.
///
/// Ilgari ilovada bunday ro'yxat yo'q edi: taklif qabul qilingach posilka
/// haydovchi ekranidan butunlay yo'qolardi va u nima olib ketayotganini
/// eslab qolishi kerak edi (saytda bu ro'yxat bor edi).
final carryingParcelsProvider = FutureProvider.autoDispose<List<Parcel>>(
  (ref) => ref.watch(parcelsRepositoryProvider).mine(role: 'driver'),
);

/// Bitta posilkaga kelgan haydovchi takliflari.
///
/// `family`: har posilka o'z so'rovini oladi, ro'yxatdagi kartochka ochilganda
/// YUKLANADI — hamma posilka uchun oldindan emas. Yuboruvchida o'nlab posilka
/// bo'lishi mumkin, ularning har biriga so'rov yuborish bekorga trafik.
final parcelResponsesProvider = FutureProvider.autoDispose
    .family<List<ParcelResponse>, String>(
      (ref, parcelId) =>
          ref.watch(parcelsRepositoryProvider).responses(parcelId),
    );

/// Shu qurilmaning `device_id` si — sessiyalar ro'yxatida "shu qurilma" deb
/// belgilash uchun (o'zini chiqarib yuborish tugmasi ko'rsatilmasin).
final currentDeviceIdProvider = FutureProvider<String>((_) => DeviceInfo.id());

/// Haydovchi daromadi — `GET /rides/earnings`.
final driverEarningsProvider = FutureProvider.autoDispose<DriverStatistics>(
  (ref) => ref.watch(ridesRepositoryProvider).earnings(),
);

/// Tavsiyalar — qidiruv ekranida "Siz uchun" bloki.
final recommendationsProvider = FutureProvider.autoDispose<RideRecommendations>(
  (ref) => ref.watch(ridesRepositoryProvider).recommendations(),
);

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationItem>>(
      (ref) => ref.watch(notificationsRepositoryProvider).list(),
    );

/// Tarif setkasi — narxlar FAQAT shu yerdan, hech qayerda hardcode YO'Q.
/// `autoDispose` emas: setka kamdan-kam o'zgaradi, ekranlar orasida saqlansin.
final billingPlansProvider = FutureProvider<List<BillingPlan>>(
  (ref) => ref.watch(billingRepositoryProvider).plans(),
);

/// Joriy obuna — yo'q bo'lsa `null` (xato emas).
final subscriptionProvider = FutureProvider<Subscription?>(
  (ref) => ref.watch(billingRepositoryProvider).subscription(),
);

/// O'qilmagan bildirishnomalar soni — pastki navigatsiyadagi nishon uchun.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return items.where((n) => !n.isRead).length;
});

/// O'qilmagan CHAT xabarlari soni — pastki navigatsiyadagi nishon uchun.
///
/// 🔴 NEGA ALOHIDA (va nega `conversationsProvider` dan olinmaydi):
/// suhbatlar ro'yxati bronlarni ham, notanish suhbatdoshlarning ismini
/// ham yuklaydi. Pastki panel ILOVA BO'YI ochiq turadi — u shuncha
/// so'rovni doim tirik ushlab turmasligi kerak. Bu yerda esa bitta
/// yengil so'rov: `GET /notifications/chats`.
///
/// Repo xatoni yutadi va bo'sh ro'yxat qaytaradi, ya'ni uzilishda nishon
/// shunchaki ko'rinmaydi — "0 xabar" deb ALDAMAYDI.
final unreadChatsProvider = FutureProvider.autoDispose<int>((ref) async {
  final chats = await ref.watch(notificationsRepositoryProvider).chats();
  return chats.fold<int>(0, (sum, c) => sum + c.unreadCount);
});

/// Suhbatlar — backendda ro'yxat endpointi YO'Q, bronlardan yig'iladi.
///
/// Faqat TASDIQLANGAN bronlar: tasdiqlanmagan so'rov uchun chat ochilmaydi
/// (mahsulot qoidasi — begonalar bir-biriga yozavermasin).
final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((
  ref,
) async {
  final rides = ref.watch(ridesRepositoryProvider);
  final me = await ref.watch(meProvider.future);

  /*
   * DUBLIKATLARNI YIG'MAYMIZ.
   *
   * 🔴 Egasi xabari (2026-08-12): "bitta odamni ikki marta safar e'lonida
   * ko'rib, qayta-qayta chiqsa yangi chat ochib yuboryapti".
   *
   * Sabab: ro'yxat BRONLAR bo'yicha yig'ilardi. Bitta yo'lovchi bitta
   * safarga ikki marta bron qilsa (yoki bron bo'linsa), ikkita bir xil
   * yozuv paydo bo'lardi. Suhbatning o'zi esa (safar, suhbatdosh)
   * juftligi bilan aniqlanadi — `Conversation ==` shunday yozilgan —
   * ya'ni ikkala qator BIR XIL chatni ochardi, lekin ro'yxatda ikkita
   * bo'lib turardi va "yangi chat ochildi" degan taassurot berardi.
   *
   * Kalit — aynan o'sha juftlik.
   */
  //
  // 🔴 2026-08-13: kalit endi FAQAT suhbatdosh. Ilgari (safar + suhbatdosh)
  // edi va bitta haydovchi bilan uch marta yursangiz ro'yxatda uchta bir xil
  // ism turardi. Egasi: "user id bo'yicha ochsin — Telegramda ham shunaqa".
  //
  // `rideId` yozuvda QOLADI: u xabar yuborishda kontekst sifatida ketadi.
  // Oxirgi qo'yilgani saqlanadi.
  final byPeer = <String, Conversation>{};
  void put(Conversation c) {
    if (c.peerId.isEmpty) return;
    byPeer[c.peerId] = c;
  }

  // Haydovchi sifatida: o'z safarlarimdagi tasdiqlangan bronlar.
  for (final ride in await rides.myRides()) {
    for (final booking in ride.bookings) {
      if (!booking.isConfirmed) continue;
      put(
        Conversation(
          rideId: ride.id,
          peerId: booking.passengerId,
          title: '${ride.originAddress} → ${ride.destinationAddress}',
          subtitle: '${booking.seatsBooked}',
          avatarUrl: booking.passenger?.avatar,
        ),
      );
    }
  }

  // Yo'lovchi sifatida: o'z tasdiqlangan bronlarim, suhbatdosh = haydovchi.
  //
  // Haydovchi BRONNING O'ZIDAN olinadi (`booking.ride.driver`) — kontraktda
  // `http.BookingResponse.ride` bor. Ilgari har bron uchun alohida
  // `GET /rides/{id}` yuborilardi; u 404 bersa suhbat BUTUNLAY tushib
  // qolardi. Endi alohida so'rov faqat ZAXIRA sifatida ketadi.
  for (final booking in await rides.myBookings()) {
    if (!booking.isConfirmed) continue;
    if (booking.passengerId != me.user.id) continue;

    var ride = booking.ride;
    if ((ride?.driver?.id ?? '').isEmpty) {
      ride = (await rides.byId(booking.rideId))?.mergedWith(ride) ?? ride;
    }

    final driverId = ride?.driver?.id;
    if (ride == null || driverId == null || driverId.isEmpty) continue;

    put(
      Conversation(
        rideId: ride.id,
        peerId: driverId,
        title: '${ride.originAddress} → ${ride.destinationAddress}',
        subtitle: ride.driver?.name,
        avatarUrl: ride.driver?.avatar,
      ),
    );
  }

  /*
   * OXIRGI XABAR — `GET /notifications/chats` dan (backend 2026-08-16).
   *
   * 🔴 NEGA SHU YERDA: ilgari ro'yxatdagi HAR suhbat uchun butun yozishma
   * tarixi alohida so'rov bilan yuklanardi, faqat oxirgi qatorni chizish
   * uchun — o'nta suhbat o'nta so'rov demak edi. Endi bitta so'rov.
   *
   * Ism va avatar bu javobda YO'Q, shuning uchun u ro'yxatni ALMASHTIRMAYDI:
   * kim bilan yozishayotganimiz bronlardan aniqlanadi, bu esa ustiga
   * "nima yozilgan va qachon" ma'lumotini qo'yadi.
   *
   * So'rov yiqilsa bo'sh ro'yxat qaytadi (repo izohi) — o'shanda ekran
   * ilgarigidek, oxirgi xabarsiz ishlayveradi.
   */
  final summaries = {
    for (final s in await ref.watch(notificationsRepositoryProvider).chats())
      if (s.peerId.isNotEmpty) s.peerId: s,
  };

  // `myUserId` — ro'yxatdagi "Siz:" prefiksi uchun (izohi
  // `Conversation.lastIsMine` da).
  final list = [
    for (final c in byPeer.values)
      summaries[c.peerId] == null
          ? c
          : c.withSummary(summaries[c.peerId]!, myUserId: me.user.id),
  ];

  /*
   * 🔴 SERVER BILADIGAN, BIZ BILMAYDIGAN SUHBATLAR.
   *
   * Ro'yxat BRONLARDAN yig'iladi, ya'ni safar tugab bron ro'yxatdan
   * chiqib ketsa yozishma ham G'OYIB bo'lardi — tarix serverda tursa
   * ham. Odam uchun bu "chatim yo'qoldi" degani.
   *
   * `GET /notifications/chats` esa HAMMA suhbatni biladi. Bronda yo'q
   * suhbatdoshning ismini `GET /users/{id}` dan olamiz — u faqat
   * NOTANISHLAR uchun so'raladi, ya'ni odatda 0-2 ta qo'shimcha so'rov.
   */
  final known = byPeer.keys.toSet();
  final unknown = summaries.keys.where((id) => !known.contains(id)).toList();
  if (unknown.isNotEmpty) {
    final users = ref.watch(usersRepositoryProvider);
    final profiles = await Future.wait(unknown.map(users.byId));
    for (var i = 0; i < unknown.length; i++) {
      final summary = summaries[unknown[i]]!;
      final profile = profiles[i];
      list.add(
        Conversation(
          // Safar noma'lum — xabar yuborishda kontekst sifatida
          // ishlatiladi, bo'sh bo'lsa ham server qabul qiladi.
          rideId: '',
          peerId: summary.peerId,
          title: '',
          subtitle: profile?.displayName,
          avatarUrl: profile?.avatarUrl,
        ).withSummary(summary, myUserId: me.user.id),
      );
    }
  }

  // Eng so'nggi yozishma TEPADA (Telegramdagidek). Xabarsiz suhbatlar
  // pastda qoladi — ular ustida hali hech narsa bo'lmagan.
  list.sort((a, b) {
    final at = a.lastAt;
    final bt = b.lastAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });

  return list;
});

/// Bitta safar — bron kartasi safar holatini va haydovchi ID'sini bilishi uchun
/// (`GET /rides/my?role=passenger` bularni bermaydi, faqat bronni qaytaradi).
final rideByIdProvider = FutureProvider.autoDispose.family<Ride?, String>((
  ref,
  rideId,
) async {
  if (rideId.isEmpty) return null;
  return ref.watch(ridesRepositoryProvider).byId(rideId);
});

/// Mashina — safar javobida `car` kelmagan holat uchun zaxira.
/// Xato bo'lsa `null`, ekran mashina qatorini umuman chizmaydi.
final vehicleByIdProvider = FutureProvider.autoDispose
    .family<RideVehicle?, String>((ref, id) async {
      if (id.isEmpty) return null;
      return ref.watch(ridesRepositoryProvider).vehicleById(id);
    });

/// Bitta suhbat xabarlari.
/// HOZIR OCHIQ turgan suhbat.
///
/// 🔴 Nima uchun kerak (egasi 2026-08-13): odam chatni ochib turib xabar
/// olsa, ekran tepasidan yana o'sha xabar banner bo'lib tushardi — xabar
/// ro'yxatda allaqachon ko'rinib turgan bo'lsa ham. Telegram ham, boshqa
/// ilovalar ham ochiq suhbatga banner ko'rsatmaydi.
///
/// Chat ekrani ochilganda to'ldiriladi, yopilganda tozalanadi.
final openConversationProvider = StateProvider<Conversation?>((ref) => null);

final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, Conversation>((ref, conversation) async {
      final me = await ref.watch(meProvider.future);
      return ref
          .watch(notificationsRepositoryProvider)
          // `rideId` ATAYIN yuborilmaydi: backend uni bersak faqat O'SHA
          // safar yozishmasini qaytaradi (ularning xati 2026-08-13).
          // Bizga esa odam bilan BUTUN yozishma kerak — Telegramdagidek.
          .history(myId: me.user.id, peerId: conversation.peerId);
    });

/// Qidiruv natijalari — oxirgi so'rov saqlanadi (natijalar ekraniga o'tib
/// qaytganda qayta so'rov ketmaydi).
/// ⚠️ NOMI ATAYIN «Ride» BILAN BOSHLANADI (2026-09-02): Flutter'ning
/// `material` kutubxonasida ham `SearchController` bor. Ikkalasi bitta
/// faylga import qilinsa, Dart nomni ANIQLAY OLMAY xato beradi — yoki
/// undan yomoni, notoʻgʻri sinf tanlanadi. Bu bir marta sinov faylida
/// aynan shunday bo'ldi.
class RideSearchController extends AsyncNotifier<List<Ride>?> {
  RideSearchParams? _lastParams;

  RideSearchParams? get lastParams => _lastParams;

  @override
  Future<List<Ride>?> build() async => null;

  Future<void> run(RideSearchParams params) async {
    _lastParams = params;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(ridesRepositoryProvider).search(params),
    );

    /*
     * 🔴 STATISTIKANING ENG QIMMATLI HODISASI shu yerda.
     *
     * Natija SONI bilan birga yuboriladi — shuning uchun egasi "talab bor,
     * taklif yo'q" yo'nalishlarni ko'ra oladi: odamlar qidiryapti, lekin
     * safar chiqmayapti. Bu qayerga haydovchi jalb qilish kerakligini
     * aytadi va boshqa hech qanday manbadan olib bo'lmaydi.
     *
     * Aniq koordinata YUBORILMAYDI — faqat radius va natija soni
     * (maxfiylik: `core/analytics.dart` izohi).
     */
    ref
        .read(analyticsProvider)
        .log(
          AnalyticsEvent.search,
          payload: {
            'results': state.valueOrNull?.length ?? 0,
            'failed': state.hasError,
            'seats': params.minSeats ?? 1,
            'has_date': params.date != null,
            'has_price_filter':
                params.priceMin != null || params.priceMax != null,
            'radius_km': params.radiusKm,
          },
        );
  }

  Future<void> refresh() async {
    final params = _lastParams;
    if (params != null) await run(params);
  }

  /// Narx oralig'ini qo'llash va qidiruvni QAYTA yugurtirish.
  ///
  /// 🔴 NEGA QAYTA SO'ROV: narx SERVER filtri. Klientda kesish yolg'on
  /// natija beradi — odam "50 000 gacha" desa, server qaytargan
  /// bo'lakdan tashqaridagi arzonroq safar telefonga umuman kelmaydi.
  /// Saytda bu 2026-07-31 da aynan shu sabab tuzatilgan.
  Future<void> applyPrice({double? min, double? max}) async {
    final params = _lastParams;
    if (params == null) return;
    final clear = min == null && max == null;
    await run(params.copyWith(priceMin: min, priceMax: max, clearPrice: clear));
  }

  /// «Ayollar uchun» filtri — narx kabi SERVER filtri, ya'ni almashtirilsa
  /// qidiruv QAYTA yugurtiriladi.
  ///
  /// 🔴 Qo'ldagi ro'yxatni qayta saralash YETMAYDI: cheklovli safar
  /// oddiy javobga umuman kirmaydi (08.09.2026 o'lchovi), ya'ni u
  /// telefonga hech qachon kelmagan bo'ladi.
  Future<void> setWomenOnly(bool value) async {
    final params = _lastParams;
    if (params == null || params.womenOnly == value) return;
    await run(params.copyWith(womenOnly: value));
  }
}

final searchControllerProvider =
    AsyncNotifierProvider<RideSearchController, List<Ride>?>(
      RideSearchController.new,
    );

/// «QAYERGA KETSA BO'LADI» — bo'sh natija uchun muqobil manzillar.
///
/// 🔴 NEGA KERAK (egasi, qurilmada 2026-08-19): "Toshkentdan Andijonga
/// qidirdim, chiqmadi; 100 km qo'shdim — Toshkentdan CHORTOQQA chiqardi".
///
/// Ikkita alohida muammo bor edi:
///   1. `radius_km` backendda jo'nash VA manzil nuqtasining IKKALASIGA
///      qo'llanadi. Radiusni oshirish "shu yo'nalishni kengroq qidir"
///      degani EMAS — u BOSHQA MANZILLARNI natijaga qo'shadi. Odam
///      Andijonni so'rab Chortoqni ko'radi va buni xato deb biladi. U haq.
///   2. "Safar topilmadi" — boshi berk javob. Platformada safar BOR,
///      faqat boshqa yo'nalishda; odam buni bilmay chiqib ketadi.
///
/// Yechim: manzillar JIM aralashtirilmaydi, balki OCHIQ taklif qilinadi —
/// nomi va soni bilan. Tanlash odamda qoladi.
///
/// Natija: manzil nomi -> shu yo'nalishdagi safarlar soni (ko'pdan kamga).
final alternativeDestinationsProvider =
    FutureProvider.autoDispose<List<({String name, int count})>>((ref) async {
      final params = ref.watch(searchControllerProvider.notifier).lastParams;
      if (params == null) return const [];

      // Manzil MAJBURIY (usiz backend 400 beradi), shuning uchun o'sha
      // manzilni qoldirib radiusni butun mamlakatga ochamiz.
      final rides = await ref
          .read(ridesRepositoryProvider)
          .search(params.copyWith(radiusKm: _countryRadiusKm));

      final counts = <String, int>{};
      for (final ride in rides) {
        // Katta radius jo'nash nuqtasini ham bo'shatadi — AYNAN shu
        // shahardan chiqadiganlarini o'zimiz qoldiramiz, aks holda
        // "Toshkentdan bor" deb Samarqand-Buxoro safarini ko'rsatardik.
        final fromKm = distanceKm(
          fromLat: params.originLat,
          fromLon: params.originLon,
          toLat: ride.originLat,
          toLon: ride.originLon,
        );
        if (fromKm > _nearOriginKm) continue;
        if (ride.status == RideStatus.completed ||
            ride.status == RideStatus.cancelled) {
          continue;
        }

        // Nom KOORDINATADAN olinadi: `destinationAddress` haydovchi yozgan
        // erkin matn ("Andijon shahri, 3-mavze") va guruhlashga yaramaydi.
        final place = nearestPlace(ride.destinationLat, ride.destinationLon);
        if (place == null) continue;
        counts[place.name] = (counts[place.name] ?? 0) + 1;
      }

      final list =
          counts.entries.map((e) => (name: e.key, count: e.value)).toList()
            ..sort((a, b) => b.count.compareTo(a.count));
      return list.take(6).toList();
    });

/// Bo'sh natijada — SHU yo'nalishda safar BOR kunlar.
///
/// 🔴 NEGA KERAK: bo'sh natijaning eng ko'p uchraydigan sababi — SANA.
/// Odam 20-avgustni tanlaydi, safar esa 21-avgustda bor. Ilgari ilova
/// «safar topilmadi» derdi va odam yo'nalish umuman ishlamaydi deb
/// o'ylardi. Muqobil MANZILLAR taklifi allaqachon bor edi — bu uning
/// sana bo'yicha egizagi.
///
/// ⚠️ FAQAT BITTA qo'shimcha so'rov: `date` serverga `date_from` bo'lib
/// ketadi va YUQORI CHEGARASI YO'Q, ya'ni sanani olib tashlagan bitta
/// so'rov kelajakdagi HAMMA safarni beradi. Kunlar shu javobdan
/// hisoblanadi — har kun uchun alohida so'rov yuborilmaydi.
/// SHU YO'NALISHDA har kunda nechta safar bor.
///
/// Bitta SANASIZ qidiruv (`clearDate`) — natija kunlar bo'yicha sanaladi.
/// Ikki joy shundan oziqlanadi: sana lentasi (`DateStrip`) va bo'sh
/// natijadagi «boshqa kunlar» chiplari.
///
/// 🔴 NEGA BITTA PROVIDER: ilgari «boshqa kunlar» o'z so'rovini yuborardi.
/// Lentaga ikkinchi nusxa yozilsa, bir xil so'rov IKKI marta ketardi va
/// ikkalasi bir-biridan chetga chiqib, ekranning ikki joyida turli son
/// ko'rsatishi mumkin edi.
final ridesPerDayProvider = FutureProvider.autoDispose<Map<DateTime, int>>((
  ref,
) async {
  final params = ref.watch(searchControllerProvider.notifier).lastParams;
  if (params == null) return const {};

  final rides = await ref
      .read(ridesRepositoryProvider)
      .search(params.copyWith(clearDate: true));

  final counts = <DateTime, int>{};
  final now = DateTime.now();
  for (final ride in rides) {
    final at = ride.departureTime;
    if (at == null) continue;
    // O'tgan safarlar sanalmaydi — ularni tanlab bo'lmaydi.
    if (at.isBefore(now)) continue;
    if (ride.status == RideStatus.completed ||
        ride.status == RideStatus.cancelled) {
      continue;
    }
    final day = DateTime(at.year, at.month, at.day);
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return counts;
});

final alternativeDatesProvider =
    FutureProvider.autoDispose<List<({DateTime day, int count})>>((ref) async {
      final params = ref.watch(searchControllerProvider.notifier).lastParams;
      if (params == null) return const [];
      final counts = await ref.watch(ridesPerDayProvider.future);

      final chosen = params.date;
      final list =
          counts.entries
              // Tanlangan kunning O'ZI taklif qilinmaydi: odam allaqachon
              // o'sha kunni ko'rdi va u bo'sh chiqdi.
              .where(
                (e) =>
                    chosen == null ||
                    e.key.year != chosen.year ||
                    e.key.month != chosen.month ||
                    e.key.day != chosen.day,
              )
              .map((e) => (day: e.key, count: e.value))
              .toList()
            ..sort((a, b) => a.day.compareTo(b.day));
      return list.take(4).toList();
    });

/// Taklif so'rovi uchun — butun O'zbekistonni qoplaydi.
const _countryRadiusKm = 700;

/// Taklifga faqat SHU shahardan chiqadigan safarlar kiradi.
const _nearOriginKm = 60.0;

/// BEGONA foydalanuvchi profili — `GET /users/{id}`.
///
/// Alohida provider: bir odam bir necha ekranда ochilishi mumkin (safar
/// kartochkasi, chat sarlavhasi), so'rov esa bir marta ketsin.
final userByIdProvider = FutureProvider.family<User?, String>(
  (ref, userId) => ref.watch(usersRepositoryProvider).byId(userId),
);

/// Foydalanuvchi haqidagi SHARHLAR (`GET /rating?reviewee_id=`).
///
/// ✅ 2026-08-27: endpoint bizning so'rovimizdan keyin ochildi — shu
/// paytgacha izoh yozilardi-yu, hech qayerda ko'rinmasdi.
///
/// 🔑 Mehmonlarga ochiq, ya'ni kirmagan odam ham ko'radi.
final userFeedbackProvider = FutureProvider.family<FeedbackList, String>(
  (ref, userId) => ref.watch(ratingRepositoryProvider).list(userId),
);

/// Safar boshlangach — «qachon yetamiz?» javobi (`GET /telematics/eta`).
///
/// 🔴 NEGA KERAK: safar boshlangach yo'lovchi KO'R bo'lib qolardi.
/// Haydovchi yo'ldami, qancha qoldi — yagona yo'l qo'ng'iroq qilish edi.
///
/// ⚠️ XARITADA MASHINA CHIZILMAYDI va bu ATAYIN: backend `nearby` javobida
/// faqat `distance` bor, KOORDINATA yo'q (jonli o'lchandi 2026-08-21).
/// Ya'ni mashinani xaritaga qo'yish uchun ma'lumot YO'Q — taxminiy nuqta
/// chizish yolg'on bo'lardi. Backend koordinata qo'shsa, shu joyga
/// ulanadi.
///
/// ⚠️ ETA haydovchining OXIRGI ping'iga tayanadi. Haydovchi ilovani yopsa
/// ping to'xtaydi va raqam eskiradi — shuning uchun u «taxminan» deb
/// ko'rsatiladi va safar boshlanmagan bo'lsa umuman so'ralmaydi.
final rideEtaProvider = FutureProvider.autoDispose.family<EtaInfo?, Ride>((
  ref,
  ride,
) async {
  final driverId = ride.driver?.id ?? '';
  if (driverId.isEmpty || ride.status != RideStatus.inProgress) return null;
  try {
    return await ref
        .watch(telematicsRepositoryProvider)
        .eta(
          driverId: driverId,
          targetLat: ride.destinationLat,
          targetLon: ride.destinationLon,
        );
  } catch (_) {
    // ETA ikkinchi darajali — kelmasa safar sahifasi to'liq ishlaydi.
    return null;
  }
});

/// Safar eslatmalari — QURILMADA rejalashtiriladi (izohi `TripReminders` da).
/// Kuzatilayotgan yo'nalishlar (izohi `core/route_watch.dart` da).
final routeWatchStoreProvider = Provider<RouteWatchStore>(
  (ref) => RouteWatchStore(ref.watch(sharedPrefsProvider)),
);

/// Kuzatuvlarni tekshiruvchi — ilova ochilganda/fondan qaytganda ishlaydi.
final routeWatcherProvider = Provider<RouteWatcher>((ref) {
  final t = AppStrings(ref.watch(langProvider));
  return RouteWatcher(
    store: ref.watch(routeWatchStoreProvider),
    rides: ref.watch(ridesRepositoryProvider),
    plugin: FlutterLocalNotificationsPlugin(),
    title: t.routeWatchFoundTitle,
    body: t.routeWatchFoundBody,
  );
});

/// MASHINA MODERATSIYASI kuzatuvchisi — izohi
/// `core/car_moderation_watch.dart` da.
final carModerationWatcherProvider = Provider<CarModerationWatcher>((ref) {
  final t = AppStrings(ref.watch(langProvider));
  return CarModerationWatcher(
    prefs: ref.watch(sharedPrefsProvider),
    users: ref.watch(usersRepositoryProvider),
    // Haqiqiy yuborish `push.dart` da — kanal va ovoz sozlamalari
    // hamma mahalliy bildirishnoma uchun BIR joyda tursin.
    notify: (id, title, body) => showAppNotification(
      FlutterLocalNotificationsPlugin(),
      id: id,
      title: title,
      body: body,
    ),
    approvedTitle: t.carApprovedTitle,
    approvedBody: t.carApprovedBody,
    rejectedTitle: t.carRejectedTitle,
    rejectedBody: t.carRejectedBody,
  );
});

final tripRemindersProvider = Provider<TripReminders>(
  (ref) => TripReminders(FlutterLocalNotificationsPlugin()),
);

/// Yo'nalish bo'yicha marshrut — QIDIRUV KARTOCHKALARI uchun.
///
/// 🔴 NEGA ALOHIDA PROVIDER (`rideRouteProvider` bor-ku): u kalit sifatida
/// SAFARNI oladi, ya'ni har bir e'lon uchun alohida so'rov ketardi —
/// yigirmata natija = yigirmata so'rov. Bu esa YO'NALISH bo'yicha
/// keshlanadi: qidiruv natijalari deyarli har doim BITTA shahar juftligi
/// bo'ladi, shuning uchun amalda bitta so'rov ketadi.
///
/// Koordinatalar 2 xonagacha yaxlitlanadi (~1 km): bitta shahardan
/// chiqadigan e'lonlar bir necha yuz metr farq qilsa ham bitta so'rovga
/// birlashadi. Kartochkadagi «≈4 soat» uchun bu aniqlik yetarli.
final routeBetweenProvider =
    FutureProvider.family<
      RouteInfo?,
      ({double oLat, double oLon, double dLat, double dLon})
    >((ref, key) async {
      try {
        return await ref
            .watch(telematicsRepositoryProvider)
            .route(
              originLat: key.oLat,
              originLon: key.oLon,
              destLat: key.dLat,
              destLon: key.dLon,
            );
      } catch (_) {
        // Marshrut ikkinchi darajali — kelmasa kartochka to'liq ishlaydi.
        return null;
      }
    });

/// Marshrut kaliti — koordinatalarni yaxlitlab keshni birlashtiradi.
({double oLat, double oLon, double dLat, double dLon}) routeKeyFor(Ride ride) {
  double r(double v) => (v * 100).roundToDouble() / 100;
  return (
    oLat: r(ride.originLat),
    oLon: r(ride.originLon),
    dLat: r(ride.destinationLat),
    dLon: r(ride.destinationLon),
  );
}

/// UCHRASHUV NUQTASI koordinatasi — matndan geokodlanadi.
///
/// 🔴 NEGA GEOKOD: backend `pickup_point` ni MATN sifatida saqlaydi,
/// koordinata maydoni YO'Q (xat 2026-08-21 da so'raldi). Haydovchi endi
/// nuqtani xaritadan tanlaydi va teskari geokod aniq manzil yozadi —
/// demak o'sha matnni qayta geokodlab, taxminan o'sha nuqtaga qaytamiz.
///
/// ⚠️ Bu ANIQ koordinata emas, TAXMIN: geokoder matnni boshqa joyga
/// tushirishi mumkin. Shuning uchun natija bo'lmasa yoki matn bo'sh
/// bo'lsa — `null`, va chaqiruvchi safar boshlanish shahriga qaytadi.
/// Backend maydon qo'shsa, bu provider olib tashlanadi.
final pickupCoordProvider = FutureProvider.autoDispose
    .family<({double lat, double lon})?, String>((ref, text) async {
      final query = text.trim();
      if (query.length < 4) return null;
      try {
        final results = await ref.watch(geocoderProvider).search(query);
        if (results.isEmpty) return null;
        return (lat: results.first.lat, lon: results.first.lon);
      } catch (_) {
        return null;
      }
    });

/// Manzildagi ob-havo — safar kunida (izohi `WeatherRepository` da).
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => WeatherRepository(),
);

final rideWeatherProvider = FutureProvider.autoDispose
    .family<DayWeather?, Ride>((ref, ride) async {
      final day = ride.departureTime;
      if (day == null) return null;
      // O'tgan safarga ob-havo prognozi ma'nosiz.
      if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        return null;
      }
      return ref
          .watch(weatherRepositoryProvider)
          .forDay(lat: ride.destinationLat, lon: ride.destinationLon, day: day);
    });

/// Shu ODAM bilan bog'liq ENG SO'NGGI safar — chat sarlavhasi ostidagi
/// kartochka uchun.
///
/// 🔴 NEGA KERAK (egasi, 2026-08-21): chat ODAM bo'yicha ochiladi va bitta
/// bo'lib qoladi — bu to'g'ri. Lekin suhbat ichida QAYSI safar haqida
/// gaplashilayotgani ko'rinmasdi, `Conversation.rideId` esa suhbat
/// yaratilgandagi ESKI safarda qotib qolardi: yangi safar bo'lganda ham
/// tepada eskisi turaverardi.
///
/// 🔴 YANGI CHAT OCHILMAYDI: bu provider faqat KARTOCHKA uchun safarni
/// tanlaydi. Suhbatning kaliti o'sha-o'sha `peerId` bo'lib qoladi, ya'ni
/// bir odam bilan ikkita chat paydo bo'lmaydi.
///
/// Tanlash tartibi: avval TIRIK safar (`active`/`in_progress`), keyin eng
/// yangi jo'nash vaqti. Tugagan safar ham ko'rsatiladi — yozishma safar
/// tugagach ham davom etadi.
final latestRideWithPeerProvider = FutureProvider.autoDispose
    .family<Ride?, String>((ref, peerId) async {
      if (peerId.isEmpty) return null;

      final candidates = <Ride>[];

      // 1) Men YO'LOVCHI bo'lgan safarlar — bronlarim ichidan.
      final bookings = await ref.watch(myBookingsProvider.future);
      final rides = await ref.watch(myRidesProvider.future);
      for (final booking in bookings) {
        for (final ride in rides) {
          if (ride.id != booking.rideId) continue;
          if (ride.driver?.id == peerId) candidates.add(ride);
        }
      }

      // 2) Men HAYDOVCHI bo'lgan safarlar — shu yo'lovchi bron qilganlari.
      for (final ride in rides) {
        final booked = ride.bookings.any((b) => b.passengerId == peerId);
        if (booked) candidates.add(ride);
      }

      if (candidates.isEmpty) return null;

      candidates.sort((a, b) {
        // Tirik safar HAR DOIM tepada: suhbat odatda aynan u haqda.
        bool live(Ride r) =>
            r.status == RideStatus.active || r.status == RideStatus.inProgress;
        if (live(a) != live(b)) return live(a) ? -1 : 1;
        final at = a.departureTime;
        final bt = b.departureTime;
        if (at == null || bt == null) return 0;
        return bt.compareTo(at);
      });
      return candidates.first;
    });

/// SAFAR DAVOMIDA joylashuv yuboradigan YAGONA xizmat.
///
/// 🔴 NEGA PROVIDERDA, EKRANDA EMAS (2026-08-30): ilgari `LivePing`
/// haydovchi safari ekranining ichida yashardi va ekran yopilishi
/// bilan `dispose` uni O'CHIRARDI. Ya'ni haydovchi orqaga bosib
/// ro'yxatga chiqsa yoki chatga o'tsa, kuzatuv to'xtardi va yo'lovchi
/// mashinani yo'qotardi — fon rejimini qo'shishning butun ma'nosi
/// shu yerda yo'qolib ketardi.
///
/// Endi xizmat ilova ildizida yashaydi: uni FAQAT safar holati
/// to'xtatadi (`in_progress` dan chiqqanda), ekran emas.
///
/// `Provider` ATAYIN `autoDispose` EMAS — o'qiydigan ekran yopilsa ham
/// xizmat o'chmasin.
final livePingProvider = Provider<LivePing>((ref) {
  final ping = LivePing(ref.watch(telematicsRepositoryProvider));
  // Ilova yopilganda oldingi plan xizmati ham to'xtasin — aks holda
  // tizim panelida osilib qolgan bildirishnoma qoladi.
  ref.onDispose(ping.stop);
  return ping;
});

/// HAYDOVCHINING JONLI JOYLASHUVI — safar boshlangach xaritada.
///
/// 🔴 MANBA O'ZGARDI (2026-09-04): ilgari `GET /telematics/nearby`
/// dan butun ro'yxat olinib, ichidan `driver_id` bo'yicha izlanardi.
/// Biz backenddan o'sha manzilni YOPISHNI so'ragandik (safarga
/// aloqasi yo'q odam ham istalgan haydovchining koordinatasini
/// olardi) va u yopildi: yo'lovchi endi 403 oladi. Ya'ni eski kod
/// jimgina bo'sh ro'yxat qaytarib, xaritada mashina UMUMAN
/// chizilmay qolardi.
///
/// Endi `GET /rides/{id}/location`: u AYNAN shu safarning
/// haydovchisini beradi va ruxsatni serverning O'ZI tekshiradi —
/// tasdiqlanmagan bron ham, begona odam ham 403 oladi (o'lchandi).
///
/// ⚠️ Haydovchi ilovani yopsa ping to'xtaydi va joylashuv ESKIRADI —
/// shuning uchun bu "jonli kuzatuv" deb ATALMAYDI, "oxirgi ma'lum joy".
///
/// 🔴 O'ZINI QAYTA SO'RAYDI (2026-08-30, egasi: "navigatsiya shunchaki
/// qo'yilgan"). Ilgari bu bir martalik `FutureProvider` edi: ekran
/// ochilganda bitta so'rov ketardi va nuqta boshqa HECH QACHON
/// yangilanmasdi — xaritadagi mashina qimirlamasdi.
///
/// 🔴 ORALIQ 30 → 10 SONIYA (18.09.2026, egasi: «karta ishlashi bo'yicha
/// solishtirish kerak edi» — Yandex Go). Eski izohda «`ping` ham shu
/// chastotada keladi, undan tez so'rash aniqlik qo'shmaydi» deb
/// yozilgandi va bu XATO fikr edi: haydovchi 20 soniyada bir yuboradi
/// (`LivePing._minGap`), ya'ni 30 soniyalik so'rov yangi pingni ekranga
/// o'rtacha 15, eng yomon holatda 30 soniya KECHIKTIRIB berardi — jami
/// eskilik 50 soniyagacha. Tez so'rash yangi nuqta YARATMAYDI, lekin
/// KELGANINI darhol ko'rsatadi.
///
/// ⚠️ So'rov FAQAT provider tinglanayotganda ketadi (`autoDispose`):
/// ekran yopilsa yoki ilova fonga ketsa, taymer o'zi o'chadi.
final driverPositionProvider = FutureProvider.autoDispose
    .family<NearbyDriver?, Ride>((ref, ride) async {
      if (ride.id.isEmpty || ride.status != RideStatus.inProgress) return null;

      // Taymer provider TINGLANAYOTGANDA ishlaydi va oxirgi tinglovchi
      // ketishi bilan `autoDispose` uni o'chiradi — fon rejimida
      // bekorga so'rov ketmaydi.
      final timer = Timer(
        const Duration(seconds: 10),
        () => ref.invalidateSelf(),
      );
      ref.onDispose(timer.cancel);

      try {
        return await ref
            .watch(telematicsRepositoryProvider)
            .rideLocation(ride.id);
      } catch (_) {
        // Joylashuv ikkinchi darajali — kelmasa safar ekrani to'liq ishlaydi.
        return null;
      }
    });

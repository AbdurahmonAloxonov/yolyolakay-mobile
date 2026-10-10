import 'package:yolyolakay/features/shared/screen_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/cities.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../core/voice_ride.dart';
import '../../data/models/billing.dart';
import '../../data/models/ride.dart';
import 'ride_card.dart';
import '../../data/models/user.dart';
import '../../core/analytics.dart';
import '../map/pick_location_screen.dart';
import '../map/route_preview_map.dart';
import '../../l10n/strings.dart';
import '../shared/notification_bell.dart';
import '../shared/settings_button.dart';
import '../search/city_picker.dart';
import '../shared/bottom_action_bar.dart';
import '../shared/city_field.dart';
import '../shared/state_views.dart';
import '../shared/voice_listen_button.dart';
import '../shared/ui.dart';
import 'today_card.dart';
import '../../../app/dimens.dart';
import '../../core/money_input.dart';
import '../shared/brand/loom_loader.dart';
import '../shared/brand/brand_panels.dart';
import '../shared/yol_button.dart';

/// Premium belgilar shu obunada QULFLANGANMI.
///
/// Obuna hali KELMAGAN bo'lsa (yuklanmoqda) yoki so'rov YIQILGAN bo'lsa
/// qulflanmaydi: tarmoq sekin bo'lganda Pro haydovchining belgilari bir zum
/// o'chib turishi, keyin yonishi xatolikdek ko'rinardi. Bunday noaniq holatni
/// backend o'zi 400 bilan tushunarli hal qiladi.
///
/// Ma'lumot kelgan va obuna YO'Q bo'lsa (`value == null`) — QULFLANADI.
/// Ilgari bu holat "qulflanmagan" edi: obunasiz haydovchi belgilarni yoqib,
/// e'lon qilishda 400 olardi (backend xati 2026-08-13: filtrlar faqat Pro va
/// Premium'da).
///
/// Forma ham, yuborish ham AYNAN shu funksiyani ishlatadi — aks holda odam
/// ochiq tumblerni ko'rib, jimgina `false` yuborilgan bo'lardi.
bool _premiumLocked(AsyncValue<Subscription?> subscription) =>
    subscription.hasValue && !(subscription.value?.hasPremiumFilters ?? false);

/// E'lon berish (haydovchi).
///
/// Mashina majburiy — `vehicle_id`siz backend 400 beradi. Shuning uchun
/// mashinasi yo'q foydalanuvchi bu yerga kelsa, avval "haydovchi bo'lish"ga
/// yo'naltiriladi.
class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key, this.returnOf, this.repeatOf});

  /// QAYTISH safari uchun namuna e'lon.
  ///
  /// 🔴 NEGA KERAK: haydovchi Toshkent→Farg'ona e'lon qiladi va ertaga
  /// qaytadi — lekin qaytish uchun butun formani BOSHIDAN to'ldirishi
  /// kerak edi (shaharlar, sana, narx, oltita belgi, mashina). Amalda
  /// ko'pchilik shunchaki e'lon qilmaydi: qaytishda mashina bo'sh ketadi,
  /// yo'lovchi esa "orqaga safar yo'q" deb ko'radi.
  ///
  /// Berilsa: shaharlar ALMASHADI, sana ertangi kunga suriladi, qolgan
  /// hammasi (narx, mashina, belgilar) o'sha-o'sha qoladi.
  final Ride? returnOf;

  /// TAKRORLANADIGAN e'lon uchun namuna.
  ///
  /// 🔴 NEGA ALOHIDA (qaytish safari bor-ku): ko'p haydovchi HAR KUNI
  /// bir xil yo'nalishda yuradi — Toshkent→Farg'ona, ertaga yana
  /// Toshkent→Farg'ona. Qaytish safari yo'nalishni ALMASHTIRADI, bu esa
  /// o'shani QOLDIRADI. Ikkalasi boshqa ehtiyoj.
  final Ride? repeatOf;

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _price = TextEditingController();
  final _pickupPoint = TextEditingController();

  /// Xaritada qo'yilgan uchrashuv nuqtasi va o'sha paytdagi matn.
  ///
  /// 🔴 Koordinata faqat matn O'ZGARMAGAN bo'lsa yuboriladi: haydovchi
  /// xaritadan tanlab, keyin qo'lda boshqa joy yozsa, eski nuqta yangi
  /// yozuv bilan birga ketib, yo'lovchini NOTO'G'RI joyga yuborardi.
  LatLng? _pickupCoord;
  String? _pickupCoordText;

  LatLng? get _pickupCoordIfCurrent =>
      _pickupCoord != null && _pickupPoint.text.trim() == _pickupCoordText
      ? _pickupCoord
      : null;

  Place? _from;
  Place? _to;
  final List<Place> _stops = [];
  DateTime? _date;
  TimeOfDay? _time;
  int _totalSeats = 3;
  Car? _vehicle;

  /// Oxirgi tanlangan mashina — qurilmada saqlanadi.
  static const _lastCarKey = 'last_ride_car';

  Car? _rememberedCar(List<Car> cars) {
    final id = ref.read(sharedPrefsProvider).getString(_lastCarKey);
    if (id == null) return null;
    return cars.where((c) => c.id == id).firstOrNull;
  }

  bool _hasAc = false;
  bool _hasLuggage = false;
  bool _takesParcels = false;
  bool _noSmoking = false;
  bool _noPets = false;
  bool _maxTwoBack = false;
  bool _isNegotiable = false;

  /// `null` — cheklovsiz, `'female'` — faqat ayol yo'lovchilar.
  ///
  /// 🔑 Bu HAYDOVCHINING JINSI EMAS: erkak haydovchi ham «bu safarga
  /// faqat ayol yo'lovchi olaman» deb belgilashi mumkin va aynan shu
  /// holat uchun qaytarildi (egasi, 08.09.2026).
  ///
  /// ⚠️ `'male'` ATAYIN yo'q — 13.08.2026 da olib tashlangan va qayta
  /// tiklanmadi: unga talab yo'q edi.
  String? _genderRestriction;

  DrivingSpeed _drivingSpeed = DrivingSpeed.normal;

  /// YO'LDA MUSIQA — ixtiyoriy, `null` = «farqi yo'q».
  ///
  /// 🔑 27.08.2026 da bu tanlov ATAYIN qoldirilgan edi: o'shanda biz
  /// backendda maydon yo'q deb hisoblardik. 09.09.2026 o'lchovi buni rad
  /// etdi — `music_taste` saqlanadi va `GET /rides/{id}` da qaytadi.
  /// Belgilar (`ride_card`) allaqachon chizilgan edi-yu, hech qachon
  /// ko'rinmasdi: yuboradigan joy yo'q edi.
  ///
  /// ⚠️ `null` yuborilmaydi (`toJson` da shart bor) — «farqi yo'q» ni
  /// saqlash kartada bo'sh belgi chiqarardi.
  String? _musicTaste;

  /// Backenddan kelgan qiymatni formaga tiklashdan OLDIN tekshiradi.
  ///
  /// 🔴 SHART: `music_taste` serverda ERKIN MATN ustuni. 09.09.2026 da
  /// o'lchov paytida u yerga «Sokin fon musiqasi» degan jumla yozib
  /// ko'rdik va u o'sha holicha qaytdi. Bizning tanlagichimizda esa 3 ta
  /// qiymat bor — begona satrni `SegmentedButton` ga bersak, u
  /// «tanlangan qiymat segmentlar orasida yo'q» deb YIQILADI.
  static String? _knownMusic(String? raw) {
    const known = {'quiet', 'loud', 'talk'};
    final v = (raw ?? '').trim().toLowerCase();
    return known.contains(v) ? v : null;
  }

  bool _saving = false;

  /// Formada biror narsa kiritilganmi — chiqishda so'rash SHARTMI.
  ///
  /// Boshlang'ich qiymatlar (`_totalSeats = 3`, `_drivingSpeed`) hisobga
  /// OLINMAYDI: ular odam kiritgan narsa emas.
  bool get _hasInput =>
      _from != null ||
      _to != null ||
      _stops.isNotEmpty ||
      _date != null ||
      _time != null ||
      _price.text.trim().isNotEmpty ||
      _pickupPoint.text.trim().isNotEmpty;

  /// «Chiqasizmi?» — qoralama saqlanishi AYTILADI, aks holda odam
  /// «yo'qotaman» deb qo'rqib qoladi va noto'g'ri tugmani bosadi.
  Future<bool> _confirmLeave(AppStrings t) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.leaveFormTitle),
        content: Text(t.leaveFormBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.leaveFormStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.leaveFormLeave),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    final source = widget.returnOf;
    if (source != null) {
      _prefillReturn(source);
    } else {
      final repeat = widget.repeatOf;
      if (repeat != null) _prefillRepeat(repeat);
    }
  }

  /// Namuna e'londan QAYTISH safarini to'ldiradi.
  ///
  /// ⚠️ Oraliq bekatlar KO'CHIRILMAYDI: qaytishda ular teskari tartibda
  /// bo'lishi kerak, lekin haydovchi qaytishda boshqa yo'ldan yurishi ham
  /// mumkin. Taxmin qilgandan ko'ra bo'sh qoldirgan halolroq.
  void _prefillReturn(Ride source) {
    _from = nearestPlace(source.destinationLat, source.destinationLon);
    _to = nearestPlace(source.originLat, source.originLon);

    // Sana — namunaning ERTASI, vaqti o'sha. Aniq kunni haydovchi
    // baribir o'zi tasdiqlaydi, lekin bo'sh maydondan ko'ra taxmin yaxshi.
    final at = source.departureTime;
    if (at != null) {
      final next = at.add(const Duration(days: 1));
      _date = DateTime(next.year, next.month, next.day);
      _time = TimeOfDay(hour: next.hour, minute: next.minute);
    }

    if (source.pricePerSeat > 0) {
      _price.text = formatPrice(source.pricePerSeat);
    }
    _pickupPoint.text = '';
    _pickupCoord = null;
    _totalSeats = source.totalSeats > 0 ? source.totalSeats : _totalSeats;

    _hasAc = source.hasAc;
    _hasLuggage = source.hasLuggage;
    _takesParcels = source.takesParcels;
    _noSmoking = source.noSmoking;
    _noPets = source.noPets;
    _maxTwoBack = source.maxTwoBack;
    _isNegotiable = source.isNegotiable;
    // Faqat `female` tiklanadi: eski e'londa `male` uchrashi mumkin,
    // lekin formada bunday tanlov yo'q va u jimgina yuborilib ketardi.
    _genderRestriction = source.genderRestriction == 'female' ? 'female' : null;
    _drivingSpeed = source.drivingSpeed ?? _drivingSpeed;
    _musicTaste = _knownMusic(source.musicTaste);
  }

  /// Namuna e'londan AYNAN o'shani ertangi kunga ko'chiradi.
  void _prefillRepeat(Ride source) {
    _from = nearestPlace(source.originLat, source.originLon);
    _to = nearestPlace(source.destinationLat, source.destinationLon);

    final at = source.departureTime;
    if (at != null) {
      final next = at.add(const Duration(days: 1));
      _date = DateTime(next.year, next.month, next.day);
      _time = TimeOfDay(hour: next.hour, minute: next.minute);
    }

    if (source.pricePerSeat > 0) {
      _price.text = formatPrice(source.pricePerSeat);
    }
    // Uchrashuv nuqtasi KO'CHIRILADI (qaytish safaridan farqli): yo'nalish
    // o'sha, demak yig'ilish joyi ham o'sha bo'lishi ehtimoli katta.
    _pickupPoint.text = source.pickupPoint ?? '';
    _pickupCoord = source.hasPickupCoord
        ? LatLng(source.pickupLat!, source.pickupLon!)
        : null;
    _pickupCoordText = source.pickupPoint?.trim();
    _totalSeats = source.totalSeats > 0 ? source.totalSeats : _totalSeats;
    _stops
      ..clear()
      ..addAll([
        for (final stop in source.stops)
          Place(name: stop.address, lat: stop.lat, lon: stop.lon, region: ''),
      ]);

    _hasAc = source.hasAc;
    _hasLuggage = source.hasLuggage;
    _takesParcels = source.takesParcels;
    _noSmoking = source.noSmoking;
    _noPets = source.noPets;
    _maxTwoBack = source.maxTwoBack;
    _isNegotiable = source.isNegotiable;
    // Faqat `female` tiklanadi: eski e'londa `male` uchrashi mumkin,
    // lekin formada bunday tanlov yo'q va u jimgina yuborilib ketardi.
    _genderRestriction = source.genderRestriction == 'female' ? 'female' : null;
    _drivingSpeed = source.drivingSpeed ?? _drivingSpeed;
    _musicTaste = _knownMusic(source.musicTaste);
  }

  @override
  void dispose() {
    _price.dispose();
    _pickupPoint.dispose();
    super.dispose();
  }

  /// Yangi e'lon uchun formani tozalaydi (tab rejimida ekran yopilmaydi).
  void _resetForm() {
    setState(() {
      _from = null;
      _to = null;
      _stops.clear();
      _date = null;
      _time = null;
      _price.clear();
      _pickupPoint.clear();
      _pickupCoord = null;
      _totalSeats = 3;
      _isNegotiable = false;
      _genderRestriction = null;
    });
  }

  DateTime? get _departure {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _date = date;
      _time = time;
    });
  }

  /// Ovoz bilan aytilgan e'lonni formaga qo'yadi.
  ///
  /// 🔴 FAQAT TANILGANI to'ldiriladi (izohi `core/voice_ride.dart` da):
  /// narx eshitilmasa maydon bo'sh qoladi, sana eshitilmasa sana
  /// tanlanmaydi. Yolg'on to'ldirilgan forma e'lon berilgach jonli
  /// xatoga aylanardi — «sakkizda» deb aytgan haydovchi tunda jo'naydigan
  /// e'lon berib qo'yardi.
  ///
  /// Hech nima tanilmasa ham JIM QOLMAYMIZ: eshitilgan matn ekranga
  /// chiqadi, odam nima noto'g'ri ketganini ko'radi.
  void _applyVoiceRide(String text) {
    final t = AppStrings.of(context);
    final heard = parseVoiceRide(text);
    if (heard == null) {
      showMessage(context, text);
      return;
    }

    setState(() {
      if (heard.from != null) _from = heard.from;
      if (heard.to != null) _to = heard.to;
      if (heard.date != null) _date = heard.date;
      if (heard.hour != null) {
        _time = TimeOfDay(hour: heard.hour!, minute: heard.minute ?? 0);
      }
      if (heard.seats != null) _totalSeats = heard.seats!.clamp(1, 8);
      if (heard.price != null) _price.text = formatPrice(heard.price!);
    });

    AppHaptics.success();
    // Nima tushunilgani AYTILADI: jimgina to'ldirish "ilova o'zi nimadir
    // qildi" hissini beradi va odam formani tekshirmay yuboradi.
    final parts = <String>[
      if (heard.from != null && heard.to != null)
        '${heard.from!.name} → ${heard.to!.name}',
      if (heard.hour != null)
        '${heard.hour}:${(heard.minute ?? 0).toString().padLeft(2, '0')}',
      if (heard.seats != null) '${heard.seats} ${t.seats}',
      if (heard.price != null) '${formatPrice(heard.price!)} ${t.sum}',
    ];
    if (parts.isNotEmpty) showMessage(context, parts.join(' · '));
  }

  Future<void> _addStop() async {
    final city = await showPlacePicker(context);
    if (city == null) return;
    // Jo'nash/borish shahri va takror oraliq shahar qo'shilmasin.
    final duplicate =
        city.name == _from?.name ||
        city.name == _to?.name ||
        _stops.any((s) => s.name == city.name);
    if (duplicate) return;
    setState(() => _stops.add(city));
  }

  /// E'londan keyingi taklif. `false` — oddiy yopilish.
  Future<bool> _askReturnTrip(AppStrings t) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.returnTripQuestion),
        content: Text(t.returnTripHint),
        // Tugmalar bitta qatorga sig'masa: asosiy amal TEPADA va ikkalasi
        // ham butun enda (aks holda "Keyinroq" o'ngga qisilib, ostidagi
        // asosiy tugma bilan bog'lanmagandek ko'rinardi).
        actionsOverflowDirection: VerticalDirection.up,
        actionsOverflowButtonSpacing: AppSpace.sm,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.later),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.returnTrip),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  /// Faollashtirishni qayta urinish (e'lon yaratilgan, lekin `activate` yiqilgan).
  Future<void> _retryActivate(String rideId) async {
    final t = AppStrings.of(context);
    try {
      await ref.read(ridesRepositoryProvider).activate(rideId);
      ref.invalidate(myRidesProvider);
      if (mounted) showMessage(context, t.activated);
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, ref.read(langProvider));
    }
  }

  Future<void> _publish(List<Car> cars) async {
    final t = AppStrings.of(context);
    final from = _from;
    final to = _to;
    final departure = _departure;
    final vehicle = _vehicle;

    if (from == null || to == null) {
      showMessage(context, t.pickBothCities);
      return;
    }
    if (from.name == to.name) {
      showMessage(context, t.sameCityError);
      return;
    }
    if (departure == null) {
      showMessage(context, t.pickTime);
      return;
    }
    if (departure.isBefore(DateTime.now())) {
      showMessage(context, t.timeInPast);
      return;
    }
    final price = parseMoney(_price.text);
    if (price == null || price <= 0) {
      showMessage(context, t.priceRequired);
      return;
    }
    if (vehicle == null) {
      showMessage(context, t.pickVehicle);
      return;
    }

    setState(() => _saving = true);
    // Qulflangan belgilar HAR DOIM standart holatda ketadi — UI holatiga
    // ishonmaymiz. Haydovchi belgilarni yoqib qo'yib, keyin tarifi tugashi
    // yoki obuna kech kelishi mumkin; o'sha paytda `_hasAc` eski `true`
    // bo'lib qolardi va backend 400 berardi.
    final locked = _premiumLocked(ref.read(subscriptionProvider));

    try {
      final result = await ref
          .read(ridesRepositoryProvider)
          .createAndActivate(
            PublishRideRequest(
              departureTime: departure,
              originAddress: from.name,
              originLat: from.lat,
              originLon: from.lon,
              destinationAddress: to.name,
              destinationLat: to.lat,
              destinationLon: to.lon,
              pricePerSeat: price,
              totalSeats: _totalSeats,
              vehicleId: vehicle.id,
              hasAc: locked ? false : _hasAc,
              hasLuggage: _hasLuggage,
              takesParcels: _takesParcels,
              noSmoking: locked ? false : _noSmoking,
              noPets: _noPets,
              maxTwoBack: locked ? false : _maxTwoBack,
              isNegotiable: _isNegotiable,
              genderRestriction: _genderRestriction,
              drivingSpeed: locked ? DrivingSpeed.normal : _drivingSpeed,
              musicTaste: _musicTaste,
              pickupPoint: _pickupPoint.text.trim().isEmpty
                  ? null
                  : _pickupPoint.text.trim(),
              pickupLat: _pickupCoordIfCurrent?.latitude,
              pickupLon: _pickupCoordIfCurrent?.longitude,
              stops: _stops
                  .map((c) => RideStop(address: c.name, lat: c.lat, lon: c.lon))
                  .toList(),
            ),
          );

      ref.invalidate(myRidesProvider);
      // Faollashgan e'lon paketdan bitta safar yeydi — qolgan miqdor eskirdi.
      ref.invalidate(subscriptionProvider);

      // Taklif tomonining o'lchovi: haydovchilar e'lon berayaptimi.
      // `activated` ham yuboriladi — faollashmagan e'lon qidiruvda
      // KO'RINMAYDI, ya'ni u haydovchi uchun ham, yo'lovchi uchun ham
      // yo'q hisoblanadi.
      ref
          .read(analyticsProvider)
          .log(
            AnalyticsEvent.ridePublished,
            payload: {'activated': result.activated, 'seats': _totalSeats},
          );
      if (!mounted) return;
      if (result.activated) {
        showMessage(context, t.publishedAndActive);
      } else if (result.isQuotaExceeded) {
        /*
         * 🔴 PAKET TUGADI — sotuv oqimidagi eng muhim lahza.
         *
         * Bu shox 09.09.2026 gacha HECH QACHON ishga tushmagan: backend
         * kvotani sanamasdi. O'sha kuni sanay boshladi va ma'lum bo'ldiki
         * pastdagi `catch` ichidagi paywall kodiga YETIB BO'LMAYDI —
         * `createAndActivate` xatoni otmaydi. Natijada haydovchi
         * «qayta urinib ko'ring» degan YOLG'ON xabar va hech qachon
         * ishlamaydigan tugma olardi.
         *
         * Endi: rost xabar + darhol tariflar (paywall).
         */
        ref
            .read(analyticsProvider)
            .log(
              AnalyticsEvent.paywallShown,
              payload: {'reason': 'quota_exceeded', 'from': 'create_ride'},
            );
        showMessage(context, t.quotaExhaustedPublished);
        context.push(Routes.tariffs, extra: true);
        return;
      } else {
        // 🔴 Faollashmagan e'lon qidiruvda UMUMAN ko'rinmaydi. Ilgari bu yerda
        // faqat xabar chiqardi va haydovchi boshi berk holatga tushardi.
        // Endi o'sha zahoti qayta urinish taklif qilinadi; u ham yiqilsa,
        // safar ekranida "E'lonni faollashtirish" tugmasi qoladi.
        //
        // ⚠️ 400 ISTISNO: backend tarif cheklovini shu kod bilan qaytaradi
        // (Plus'da premium filtrlar). Qayta urinish HECH QACHON yordam
        // bermaydi, shuning uchun tugma ko'rsatilmaydi va serverning o'z
        // matni chiqariladi — odam sababni bilsin.
        final err = result.error;
        final retryable = result.isRetryable;
        // 🔴 MASHINA TASDIQLANMAGAN — eng ko'p uchraydigan sabab (egasi
        // 2026-08-21). Backend inglizcha texnik jumla qaytaradi
        // («driver does not have an approved car»), biz uni o'sha holicha
        // chiqarardik. Odam na tilni, na nima qilish kerakligini
        // tushunmasdi. Qayta urinish yordam BERMAYDI — tugma ham yo'q.
        final backend = (err?.backendMessage ?? '').toLowerCase();
        final carPending = backend.contains('approved car');
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                carPending
                    ? t.carNotApproved
                    : retryable
                    ? t.publishedNotActive
                    : (err?.backendMessage?.trim().isNotEmpty == true
                          ? err!.backendMessage!
                          : t.publishedNotActive),
              ),
              duration: const Duration(seconds: 10),
              action: retryable && !carPending
                  ? SnackBarAction(
                      label: t.retry2,
                      onPressed: () => _retryActivate(result.rideId),
                    )
                  : null,
            ),
          );
      }

      /*
       * QAYTISH SAFARI (CEO 2026-08-04): haydovchi borgan joyidan qaytadi va
       * o'sha qaytishga ham yo'lovchi kerak. Ilgari u butun formani qo'lda
       * qaytadan to'ldirardi. Endi e'londan keyin darhol taklif qilinadi:
       * yo'nalish TESKARI to'ldiriladi, qulaylik belgilari va narx saqlanadi,
       * sana/vaqt esa ATAYIN bo'shatiladi (qaytish vaqti albatta boshqa).
       *
       * 🔴 FAQAT E'LON FAOL BO'LSA so'raladi (qurilmada ko'rildi
       * 2026-08-13): paket tugagach e'lon yaratildi-yu faollashmadi, ekranda
       * xato turardi — ustiga esa quvnoq "qaytish safarini ham e'lon
       * qilasizmi?" oynasi chiqdi. Odam bitta e'lonni joylay olmay turib,
       * ikkinchisi taklif qilinishi mantiqsiz.
       */
      if (!result.activated) {
        if (mounted) context.go(Routes.trips);
        return;
      }

      final wantReturn = await _askReturnTrip(t);
      if (!mounted) return;
      if (wantReturn) {
        setState(() {
          final oldFrom = _from;
          _from = _to;
          _to = oldFrom;
          _stops.clear();
          _date = null;
          _time = null;
          _pickupPoint.clear();
          _pickupCoord = null;
        });
        return;
      }
      if (!mounted) return;

      // 🔴 Bu ekran IKKI xil ochiladi: yo'lovchi/haydovchi uni "Safarlarim"
      // dan surib ochadi (ustiga qo'yiladi), haydovchi rejimida esa u pastki
      // menyuning BIRINCHI bandi — ya'ni qaytadigan ekran YO'Q va `pop()`
      // hech narsa qilmasdi: e'lon joylangach ekran o'sha yerda, to'ldirilgan
      // holida qotib turardi.
      if (context.canPop()) {
        context.pop();
      } else {
        _resetForm();
        context.go(Routes.trips);
      }
    } catch (error) {
      if (!mounted) return;
      // Paket tugagan bo'lsa oddiy xabar foydasiz — haydovchi nima qilishini
      // bilmaydi. Shu sabab to'g'ridan-to'g'ri tariflar (paywall) ochiladi.
      if (ApiException.from(error).isQuotaExceeded) {
        // Paket tugab, tariflar MAJBURAN ochilgani — sotuv oqimidagi eng
        // muhim nuqta. Nechtasi shu yerdan sotib olishga o'tishini bilish
        // uchun yozib qo'yamiz.
        ref
            .read(analyticsProvider)
            .log(
              AnalyticsEvent.paywallShown,
              payload: {'reason': 'quota_exceeded', 'from': 'create_ride'},
            );
        context.push(Routes.tariffs, extra: true);
        return;
      }
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final me = ref.watch(meProvider);

    final cars = me.valueOrNull?.cars ?? const <Car>[];

    /*
     * TASODIFAN YOPISHDAN HIMOYA (2026-08-25).
     *
     * 🔴 Bu forma ilovadagi eng uzuni. Odam uni to'ldiradi, tasodifan
     * «orqaga» bosadi — va HAMMASI yo'qoladi. Sababsiz ikkinchi marta
     * to'ldirmaydi, ketadi. Haydovchi esa bizga eng kerak odam.
     *
     * `PopScope` butun ilovada UMUMAN ishlatilmagan edi. Bonus: Android
     * 14 ning «predictive back» jesti aynan shu orqali ishlaydi.
     *
     * FAQAT biror narsa kiritilgan bo'lsa so'raladi: bo'sh formada
     * savol berish — bezorilik.
     */
    return PopScope(
      canPop: !_hasInput,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave(t);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: ScreenTitle(t.createRideTitle),
          // 🔴 HAYDOVCHI REJIMIDA bu ekran birinchi tabni EGALLAYDI
          // (izohi `router.dart` da). Ya'ni haydovchida na qo'ng'iroqcha,
          // na ⚙️ bor edi — ikkalasi ham yo'lovchi ko'radigan qidiruv
          // ekranida qolib ketgandi.
          actions: const [NotificationBell(), SettingsButton()],
          bottom: const JiyakLine(),
        ),
        body: me.when(
          loading: () => const Center(child: LoomLoader()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(meProvider),
          ),
          data: (data) {
            if (data.cars.isEmpty) {
              return _NoVehicleView();
            }
            // 🔴 HAR E'LONDA BIRINCHI MASHINAGA QAYTARDI (2026-09-05,
            // qulaylik auditining 4-darajasi). Ikki mashinali haydovchi
            // doim ikkinchisida yursa ham, ilova buni hech qachon eslab
            // qolmasdi va u har safar qo'lda tuzatardi.
            //
            // ⚠️ Saqlangan mashina RO'YXATDA BORLIGI tekshiriladi:
            // o'chirilgan mashina id'si qolib ketsa, tanlov bo'sh
            // bo'lardi va «E'lon qilish» sababsiz o'chiq turardi.
            _vehicle ??= _rememberedCar(data.cars) ?? data.cars.first;
            return _form(t, data.cars);
          },
        ),
        // "E'lon qilish" DOIM ko'rinib turadi.
        //
        // 🔴 Ilgari u formaning eng oxirida edi: haydovchi uni ko'rish uchun
        // uch ekran pastga aylantirishi kerak edi va e'lon berish "tugaganini"
        // bilish qiyin edi.
        bottomNavigationBar: cars.isEmpty
            ? null
            // Panel formadan CHIZIQ bilan ajraladi — tor ekranda oxirgi
            // maydonga yopishib qolmasin (izohi `BottomActionBar` da).
            : BottomActionBar(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // «QANDAY KO'RINADI» — haydovchi o'z e'lonini
                    // YO'LOVCHI ko'zi bilan hech qachon ko'rmaydi.
                    // Narx qimmatligi, manzil noaniqligi — hammasi shu
                    // yerda, e'lon berishdan OLDIN bilinadi.
                    if (_from != null && _to != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: OutlinedButton.icon(
                          onPressed: () => _showPreview(cars),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: Text(t.previewListing),
                        ),
                      ),
                    // `YolButton` — izohi `yol_button.dart` da: yuklanishda
                    // yozuv qoladi, bosilganda yo'l izi o'tadi.
                    YolButton(
                      onPressed: _saving ? null : () => _publish(cars),
                      busy: _saving,
                      icon: Icons.campaign_outlined,
                      label: t.publish,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// E'lon YO'LOVCHI ko'zi bilan qanday ko'rinishini ko'rsatadi.
  ///
  /// Aynan `RideCard` ishlatiladi — qidiruvdagi bilan BIR XIL vidjet.
  /// Nusxa yasalsa, u vaqt o'tib haqiqiy kartadan chetga chiqib ketardi
  /// va oldindan ko'rish yolg'on bo'lardi.
  void _showPreview(List<Car> cars) {
    final t = AppStrings.of(context);
    final from = _from;
    final to = _to;
    if (from == null || to == null) return;

    final at = _date == null
        ? null
        : DateTime(
            _date!.year,
            _date!.month,
            _date!.day,
            _time?.hour ?? 0,
            _time?.minute ?? 0,
          );

    // Hali yaratilmagan safar — soxta `id` bilan. `RideHero` bo'sh
    // bo'lmagan id talab qiladi, lekin bu karta hech qayerga bosilmaydi.
    final draft = Ride(
      id: 'preview',
      originAddress: from.name,
      originLat: from.lat,
      originLon: from.lon,
      destinationAddress: to.name,
      destinationLat: to.lat,
      destinationLon: to.lon,
      departureTime: at,
      totalSeats: _totalSeats,
      availableSeats: _totalSeats,
      pricePerSeat:
          double.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      status: RideStatus.active,
      hasAc: _hasAc,
      hasLuggage: _hasLuggage,
      takesParcels: _takesParcels,
      noSmoking: _noSmoking,
      noPets: _noPets,
      maxTwoBack: _maxTwoBack,
      isNegotiable: _isNegotiable,
      genderRestriction: _genderRestriction,
      drivingSpeed: _drivingSpeed,
      musicTaste: _musicTaste,
      stops: [
        for (final s in _stops)
          RideStop(address: s.name, lat: s.lat, lon: s.lon),
      ],
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Qoida (`edge_to_edge_test`): varaq tizim panellari ostiga
      // tushib qolmasin.
      useSafeArea: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          0,
          AppSpace.lg,
          AppSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.previewListing,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              t.previewListingHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSpace.md),

            /*
             * YO'L KO'RIGI — 16.09.2026
             * (egasi: «karta to'liq ishlatilsin»).
             *
             * 🔴 Haydovchi oraliq bekat QO'SHARDI (`_stops`), lekin
             * yo'lini HECH QACHON ko'rmasdi: forma faqat shahar
             * NOMLARINI ko'rsatardi. Ya'ni «Jizzax haqiqatan yo'lim
             * ustidami yoki chekkadami?» degan savolga javob yo'q edi —
             * xato bekat esa e'lon berilgandan keyin, yo'lovchi
             * qo'shilganda ma'lum bo'lardi.
             *
             * ⚠️ FORMANING ICHIGA emas, SHU VARAQQA qo'yildi. Forma
             * allaqachon uzun va xarita uni yana cho'zardi; bu varaq
             * esa ataylab «ishimni tekshiray» deb ochiladi va ochilmasa
             * bitta ham plitka so'ralmaydi.
             */
            RoutePreviewMap(
              waypoints: [
                LatLng(draft.originLat, draft.originLon),
                for (final stop in draft.stops) LatLng(stop.lat, stop.lon),
                LatLng(draft.destinationLat, draft.destinationLon),
              ],
              height: 150,
              originName: draft.originAddress,
              destinationName: draft.destinationAddress,
            ),
            const SizedBox(height: AppSpace.md),
            RideCard(ride: draft),
          ],
        ),
      ),
    );
  }

  /// Yopiq "Qo'shimcha" bo'limida nechta sozlama yoqilgani.
  ///
  /// Bo'lim yopiq turadi, shuning uchun ichida nimadir borligi TASHQARIDAN
  /// ko'rinishi kerak — aks holda haydovchi o'zi yoqqan cheklovni unutadi.
  int get _extrasCount => [
    _hasAc,
    _hasLuggage,
    _takesParcels,
    _noSmoking,
    _noPets,
    _maxTwoBack,
    _genderRestriction != null,
    _drivingSpeed != DrivingSpeed.normal,
    _musicTaste != null,
    _pickupPoint.text.trim().isNotEmpty,
  ].where((on) => on).length;

  Widget _form(AppStrings t, List<Car> cars) {
    final theme = Theme.of(context);

    final premiumLocked = _premiumLocked(ref.watch(subscriptionProvider));

    // 🔴 MASHINA TASDIQLANMAGAN bo'lsa OLDINDAN aytamiz (egasi
    // 2026-08-21: "nega safar yaratishda 400 qaytaryapti"). Backend
    // e'lonni yaratadi-yu FAOLLASHTIRMAYDI, ya'ni odam butun formani
    // to'ldirib bo'lgach xato ko'radi. Sababni boshida aytish kerak.
    //
    // E'lon berish TO'SILMAYDI: qoralama saqlanadi va mashina
    // tasdiqlangach faollashtiriladi — bu haqiqiy va foydali holat.
    final carApproved = cars.any(
      (c) => (c.moderationStatus ?? '').toLowerCase() == 'approved',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        /*
         * «YAQIN SAFAR» — haydovchining birinchi ekrani ham bo'sh forma
         * bilan ochilardi. Bugun jo'naydigan e'loni bo'lsa, u yangi e'lon
         * berishdan MUHIMROQ: unga ariza kelgan bo'lishi mumkin.
         * E'loni bo'lmasa karta chizilmaydi va forma o'sha joyda qoladi.
         */
        const TodayCard(),
        if (!carApproved) ...[
          InfoBox(
            tone: InfoTone.warning,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.hourglass_top,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    t.carPendingWarning,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        // MARSHRUT — jo'nash, manzil va oraliq shaharlar BITTA kartada.
        //
        // Ilgari oraliq shaharlar alohida kartada, alohida sarlavha bilan
        // turardi va bo'sh bo'lsa ham joy egallardi. Ular marshrutning bir
        // qismi, alohida mavzu emas.
        SectionLabel(t.routeSection),

        /*
         * OVOZ BILAN E'LON — butun forma bitta gapdan.
         *
         * 🔴 NEGA AYNAN SHU YERDA (egasi tanlagan band, 2026-08-25):
         * e'lon berish haydovchi tomonidagi eng katta to'siq. U ko'pincha
         * yo'lda yoki bekatда turadi va telefonda yozish qiyin
         * (klaviatura tili, lotin/kirill, apostrof). Natijada u e'lonni
         * Telegram guruhiga bir og'iz gap bilan tashlaydi — biz uni
         * yo'qotamiz.
         *
         * Tugma marshrut kartasidan OLDIN turadi: u bitta maydonga emas,
         * BUTUN formaga tegishli.
         *
         * ⚠️ Faqat TANILGANI to'ldiriladi (`core/voice_ride.dart`) va
         * nima tushunilgani ekranda aytiladi — odam tekshirib, tuzatadi.
         */
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          child: VoiceListenButton(
            hint: t.voiceRideHint,
            onResult: _applyVoiceRide,
          ),
        ),

        Card(
          child: Column(
            children: [
              CityField(
                label: t.from,
                city: _from,
                dot: theme.colorScheme.primary,
                railDown: true,
                onTap: () async {
                  final city = await showPlacePicker(context, exclude: _to);
                  if (city != null) setState(() => _from = city);
                },
              ),
              const Divider(height: 1, indent: 56),
              CityField(
                label: t.to,
                city: _to,
                dot: theme.colorScheme.secondary,
                railUp: true,
                onTap: () async {
                  final city = await showPlacePicker(context, exclude: _from);
                  if (city != null) setState(() => _to = city);
                },
              ),
              for (final stop in _stops)
                ListTile(
                  dense: true,
                  // Oraliq shahar — kichikroq va so'nikroq nuqta:
                  // u yo'lning uchi emas, o'rtasidagi to'xtash.
                  leading: SizedBox(
                    width: 24,
                    child: Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  title: Text(stop.name),
                  trailing: IconButton(
                    tooltip: t.removeItem,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _stops.remove(stop)),
                  ),
                ),
              if (_stops.length < 3)
                Align(
                  alignment: Alignment.centerLeft,
                  // ⚠️ IKKINCHI DARAJALI AMAL — brend rangida emas.
                  // Pushti bu ekranda faqat «E'lon qilish» tugmasiga
                  // tegishli; oraliq shahar esa ixtiyoriy qo'shimcha.
                  child: TextButton.icon(
                    onPressed: _addStop,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('${t.addStop} · ${t.stopsLimit}'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        SectionLabel(t.whenAndPriceSection),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(t.departure),
                subtitle: Text(
                  _departure == null
                      ? t.pickTime
                      : formatDateTime(_departure, t.lang),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDateTime,
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.event_seat_outlined),
                title: Text(t.totalSeatsLabel),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: t.seatDecrease,
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _totalSeats > 1
                          ? () => setState(() => _totalSeats--)
                          : null,
                    ),
                    Text('$_totalSeats', style: theme.textTheme.titleMedium),
                    IconButton(
                      tooltip: t.seatIncrease,
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _totalSeats < 6
                          ? () => setState(() => _totalSeats++)
                          : null,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 56),
              Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [ThousandsInputFormatter()],
                  decoration: InputDecoration(
                    labelText: t.pricePerSeatLabel,
                    suffixText: t.sum,
                  ),
                ),
              ),
              SwitchListTile(
                secondary: Icon(
                  Icons.handshake,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(t.negotiable),
                value: _isNegotiable,
                onChanged: (value) => setState(() => _isNegotiable = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        SectionLabel(t.vehicle),
        Card(
          child: Column(
            children: [
              RadioGroup<Car>(
                groupValue: _vehicle,
                onChanged: (value) => setState(() {
                  _vehicle = value;
                  if (value != null) {
                    ref
                        .read(sharedPrefsProvider)
                        .setString(_lastCarKey, value.id);
                  }
                }),
                child: Column(
                  children: [
                    for (final car in cars)
                      RadioListTile<Car>(
                        value: car,
                        title: Text(car.title),
                        subtitle: Text(
                          car.isApproved
                              ? car.govNumber
                              : '${car.govNumber} · ${t.moderationPending}',
                        ),
                      ),
                  ],
                ),
              ),
              if (_vehicle != null && !_vehicle!.isApproved)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    t.moderationWarning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),

        // QO'SHIMCHA — yopiq holda.
        //
        // 🔴 Ilgari hammasi ochiq turardi: olib ketish nuqtasi, oltita
        // qulaylik tumbleri, haydash uslubi va cheklov — forma cheksiz
        // uzun bo'lib ketardi va "E'lon qilish" tugmasi ekrandan uch ekran
        // pastda qolardi. Haydovchining aksariyati faqat marshrut, vaqt va
        // narxni to'ldiradi; qolgani ixtiyoriy va yopiq turishi kerak.
        // Sarlavhada nechtasi yoqilgani ko'rinadi — yopiq bo'lsa ham
        // "u yerda nimadir bor" degani bilinadi.
        Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            shape: const Border(),
            title: Text(t.extrasSection, style: theme.textTheme.titleSmall),
            subtitle: Text(
              _extrasCount == 0 ? t.extrasHint : t.extrasEnabled(_extrasCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _pickupPoint,
                  decoration: InputDecoration(
                    labelText: t.pickupPoint,
                    hintText: t.pickupPointHint,
                    // 🔴 XARITADAN TANLASH — uchrashuv nuqtasi shu paytgacha
                    // FAQAT erkin matn edi ("Chortoq, 3-mavze"). Bunday
                    // yozuvdan yo'lovchi qayerga borishini bilmaydi va
                    // navigator ham uni topa olmaydi.
                    //
                    // ✅ Xaritadan tanlangan nuqta IKKI ko'rinishda ketadi:
                    // teskari geokod MATNI (odam o'qiydi) va aniq
                    // KOORDINATA (`pickup_lat/lon`, xarita chizadi).
                    // 28.09 gacha bu yerda «koordinata maydoni yo'q»
                    // deyilgan va nuqta tashlab yuborilardi.
                    suffixIcon: IconButton(
                      tooltip: t.pickOnMap,
                      icon: const Icon(Icons.map_outlined),
                      onPressed: () async {
                        final place = await Navigator.of(context).push<Place>(
                          MaterialPageRoute(
                            builder: (_) => PickLocationScreen(
                              initial: _from,
                              title: t.pickupPoint,
                            ),
                          ),
                        );
                        if (place != null) {
                          setState(() {
                            _pickupPoint.text = place.name;
                            _pickupCoord = LatLng(place.lat, place.lon);
                            _pickupCoordText = place.name.trim();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.comfortTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
              // Qulflanadiganlar: konditsioner, chekilmaydi, orqada maks 2.
              // Yuk joyi va posilka Plus'da ham ochiq (backend xati).
              _toggle(
                Icons.ac_unit,
                t.hasAc,
                _hasAc,
                (v) => _hasAc = v,
                locked: premiumLocked,
              ),
              _toggle(
                Icons.luggage,
                t.hasLuggage,
                _hasLuggage,
                (v) => _hasLuggage = v,
              ),
              _toggle(
                Icons.local_shipping,
                t.takesParcels,
                _takesParcels,
                (v) => _takesParcels = v,
              ),
              _toggle(
                Icons.smoke_free,
                t.noSmoking,
                _noSmoking,
                (v) => _noSmoking = v,
                locked: premiumLocked,
              ),
              _toggle(
                Icons.pets,
                t.noPets,
                _noPets,
                (v) => _noPets = v,
                prohibited: true,
              ),
              _toggle(
                Icons.airline_seat_recline_normal,
                t.maxTwoBack,
                _maxTwoBack,
                (v) => _maxTwoBack = v,
                locked: premiumLocked,
              ),
              if (premiumLocked)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.proOnlyFilterHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(Routes.tariffs),
                        child: Text(t.upgradePlan),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.drivingSpeedTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpace.md),
                    SegmentedButton<DrivingSpeed>(
                      segments: [
                        ButtonSegment(
                          value: DrivingSpeed.calm,
                          icon: const Icon(Icons.slow_motion_video, size: 18),
                          label: Text(t.speedCalm),
                          enabled: !premiumLocked,
                        ),
                        ButtonSegment(
                          value: DrivingSpeed.normal,
                          icon: const Icon(Icons.speed, size: 18),
                          label: Text(t.speedNormal),
                        ),
                        ButtonSegment(
                          value: DrivingSpeed.fast,
                          icon: const Icon(Icons.bolt, size: 18),
                          label: Text(t.speedFast),
                          enabled: !premiumLocked,
                        ),
                      ],
                      // Qulflanganda `normal` da qotib turadi — backend aynan
                      // shuni "standart" deb kutadi.
                      selected: {
                        premiumLocked ? DrivingSpeed.normal : _drivingSpeed,
                      },
                      showSelectedIcon: false,
                      onSelectionChanged: premiumLocked
                          ? null
                          : (selection) =>
                                setState(() => _drivingSpeed = selection.first),
                    ),
                    if (premiumLocked) ...[
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        t.proOnlyFilter,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],

                    /*
                     * YO'LDA MUSIQA — ixtiyoriy va HAMMAGA ochiq.
                     *
                     * 🔑 Haydash uslubidan farqli o'laroq QULFLANMAYDI:
                     * bu qulaylik emas, ogohlantirish. Sokin salon
                     * kutgan odam «musiqa baland» ni OLDINDAN bilsin —
                     * buni pulli qilish nizoni safar ichiga suradi.
                     *
                     * «Farqi yo'q» — tanlovni BEKOR qiladi (`null`) va
                     * kartada hech qanday belgi chizilmaydi.
                     */
                    const SizedBox(height: AppSpace.lg),
                    Text(t.musicTasteTitle, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      t.musicTasteHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    // ⚠️ `Wrap` — 320 px li ekranda 4 ta chip bitta qatorga
                    // sig'maydi; `Row` bo'lsa toshib ketardi (loyihada bu
                    // xato ilgari uch marta qaytgan).
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        for (final (String? value, IconData icon, String label)
                            in <(String?, IconData, String)>[
                              (
                                null,
                                Icons.do_not_disturb_on_outlined,
                                t.musicAny,
                              ),
                              (
                                'quiet',
                                Icons.volume_mute_outlined,
                                t.musicQuiet,
                              ),
                              ('loud', Icons.music_note_outlined, t.musicLoud),
                              ('talk', Icons.forum_outlined, t.musicTalk),
                            ])
                          ChoiceChip(
                            selected: _musicTaste == value,
                            avatar: Icon(icon, size: 18),
                            label: Text(label),
                            onSelected: (_) =>
                                setState(() => _musicTaste = value),
                          ),
                      ],
                    ),

                    /*
                     * KIMNI OLASIZ — «faqat ayollar» tanlovi.
                     *
                     * 🔴 13.08.2026 da olib tashlangandi, 08.09.2026 da
                     * egasining talabi bilan qaytarildi. Farqi: bu
                     * haydovchining JINSI haqida emas, SALON haqida —
                     * erkak haydovchi ham «faqat ayol yo'lovchi olaman»
                     * deya oladi.
                     *
                     * ⚠️ TARIFGA BOG'LANMAYDI (`premiumLocked` yo'q):
                     * xavfsizlik pullik funksiya bo'lmasligi kerak.
                     *
                     * ⚠️ Ostidagi izoh MAJBURIY: bunday e'lon oddiy
                     * qidiruvda ko'rinmaydi (08.09.2026 da o'lchandi) va
                     * haydovchi buni BILIB tanlashi kerak — aks holda
                     * «e'lonim yo'qolib qoldi» degan tushunmovchilik
                     * bo'ladi.
                     */
                    const SizedBox(height: AppSpace.xl),
                    Text(t.restrictionTitle, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpace.md),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'none',
                          label: Text(t.noRestriction),
                        ),
                        ButtonSegment(
                          value: 'female',
                          icon: const Icon(Icons.female, size: 18),
                          label: Text(t.forWomen),
                        ),
                      ],
                      selected: {_genderRestriction ?? 'none'},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) => setState(() {
                        final value = selection.first;
                        _genderRestriction = value == 'none' ? null : value;
                      }),
                    ),
                    if (_genderRestriction == 'female') ...[
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        t.womenOnlyDriverHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// [locked] — tarif yetmagani uchun o'chirilgan. Yashirmaymiz, chunki
  /// yashirilgan narsa "yo'q" deb tushuniladi; qulf bilan ko'rsatsak
  /// haydovchi nima uchun tarifni oshirishi kerakligini biladi.
  Widget _toggle(
    IconData icon,
    String label,
    bool value,
    void Function(bool) onChanged, {
    bool locked = false,
    bool prohibited = false,
  }) => SwitchListTile(
    // Qulflangan bo'lsa QULF ikonkasi — belgining o'zi emas: odam nima
    // yoqilmayotganini emas, NEGA yoqilmayotganini bilishi kerak.
    secondary: locked
        ? Icon(
            Icons.lock_outline,
            size: 22,
            color: Theme.of(context).colorScheme.outline,
          )
        : RideBadgeIcon(
            RideBadge(icon, label, prohibited: prohibited),
            size: 22,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    title: Text(label),
    subtitle: locked ? Text(AppStrings.of(context).proOnlyFilter) : null,
    // Qulflangan bo'lsa qiymat DOIM false ko'rsatiladi: haqiqiy holat
    // ham false bo'lib yuboriladi (`_submit`), ikkisi bir-biriga mos
    // bo'lishi shart, aks holda odam yoqilgan deb o'ylaydi.
    value: locked ? false : value,
    onChanged: locked ? null : (next) => setState(() => onChanged(next)),
  );
}

class _NoVehicleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_crash_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpace.lg),
            Text(t.noVehicleWarning, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.xl),
            FilledButton(
              onPressed: () => context.pushReplacement(Routes.becomeDriver),
              child: Text(t.becomeDriverTitle),
            ),
          ],
        ),
      ),
    );
  }
}

import '../../data/models/ride.dart';

/// Qidiruv filtrlari — HAMMASI klient tomonda.
///
/// Backend `/rides/search` faqat koordinata + `radius_km` + `min_seats` ni
/// biladi (jins, sana, qulaylik parametri YO'Q), shuning uchun natijalar
/// kelgandan keyin shu yerda saralanadi. Web'dagi filtr qatori ham shunday.
class SearchFilters {
  const SearchFilters({
    this.womenOnly = false,
    this.takesParcels = false,
    this.hasAc = false,
    this.hasLuggage = false,
    this.noSmoking = false,
    this.noPets = false,
    this.maxTwoBack = false,
    this.negotiable = false,
    this.drivingSpeed,
    this.priceMin,
    this.priceMax,
  });

  /// «Ayollar uchun» — safarni HAYDOVCHI shunday belgilagan
  /// (`gender_restriction == 'female'`).
  ///
  /// 🔑 BU HAYDOVCHINING JINSI EMAS, SALON HAQIDAGI E'LON (egasi,
  /// 2026-09-08): «haydovchi erkak, lekin qolganlari ayol bo'lsa ham
  /// ishlashi kerak». Erkak haydovchi ham "bu safarga faqat ayol
  /// yo'lovchi olaman" deb belgilay oladi — belgi aynan shuni bildiradi.
  ///
  /// 🔴 QOLGAN FILTRLARDAN FARQI — SERVER FILTRI: cheklangan safar
  /// oddiy qidiruv javobiga UMUMAN KIRMAYDI (08.09.2026 da jonli
  /// o'lchandi: 6 ta so'rovning hech birida chiqmadi), ya'ni uni
  /// mijozda "kesib olish" imkonsiz — avval `gender_restriction=female`
  /// bilan qayta so'rash kerak. Shuning uchun bu bayroq
  /// `RideSearchParams` ga ham o'tadi.
  final bool womenOnly;

  final bool takesParcels;
  final bool hasAc;
  final bool hasLuggage;
  final bool noSmoking;
  final bool noPets;
  final bool maxTwoBack;
  final bool negotiable;
  final DrivingSpeed? drivingSpeed;

  /// Narx oralig'i — FAQAT ekran holati.
  ///
  /// 🔴 `matches` da ATAYIN ISHLATILMAYDI: narx SERVERGA yuboriladi
  /// (`RideSearchParams.priceMin/priceMax`). Bu yerda ham kessak, natija
  /// ikki marta filtrlanardi — server allaqachon kesib bergan ro'yxatni
  /// yana kesish faqat zarar keltiradi.
  final double? priceMin;
  final double? priceMax;

  bool get isEmpty =>
      !womenOnly &&
      !takesParcels &&
      !hasAc &&
      !hasLuggage &&
      !noSmoking &&
      !noPets &&
      !maxTwoBack &&
      !negotiable &&
      drivingSpeed == null &&
      priceMin == null &&
      priceMax == null;

  int get activeCount => [
    womenOnly,
    takesParcels,
    hasAc,
    hasLuggage,
    noSmoking,
    noPets,
    maxTwoBack,
    negotiable,
    drivingSpeed != null,
    // Narx oralig'i BITTA filtr deb sanaladi (ikkita maydon bo'lsa ham).
    priceMin != null || priceMax != null,
  ].where((active) => active).length;

  /// JO'NAB KETGAN SAFAR NATIJADA TURMAYDIGAN CHEGARA.
  ///
  /// 🔴 NEGA YOZILDI (10.09.2026, jonli o'lchov): backend jo'nash vaqti
  /// o'tgan safarni HAMON `active` deb qaytaradi, ilovada esa sana
  /// standart bo'yicha BO'SH («Istalgan sana») — ya'ni `date_from`
  /// umuman yuborilmaydi. Natijada Toshkent→Samarqand qidiruvida
  /// 4-sentabrda jo'nagan safar chiqib turardi va kartada
  /// «Kechikmoqda — 139 soat 1 daqiqa» deb YOZILARDI. Ilovani birinchi
  /// marta ochgan odam aynan shuni ko'rardi.
  ///
  /// Nega NOL emas, uch soat: haydovchi kechikadi va bu NORMAL —
  /// `departureStatusLabel` aynan shuning uchun yozilgan («kechikish
  /// shaffofligi», 25.08.2026). 09:00 dagi safar 09:20 da hamon
  /// o'tirsa bo'ladigan safar. Uch soatdan keyin esa u safar emas,
  /// axlat: yo'lovchi unga yeta olmaydi.
  ///
  /// ⚠️ Bu FAQAT QIDIRUVGA tegishli. Odamning O'Z safari («Mening
  /// safarlarim», bron qilingan safar) bu yerdan o'tmaydi va
  /// avvalgidek to'liq ko'rinadi.
  /// 🔴 KANONIK MANBA — [Ride.bookingLateGrace]. Bu yerda faqat qulay
  /// nom (qidiruv kodi shunga murojaat qiladi); qiymat modelda.
  static const Duration lateGrace = Ride.bookingLateGrace;

  bool matches(Ride ride, {DateTime? now}) {
    // Server javobi ARALASH keladi: `gender_restriction=female` so'ralganda
    // ham cheklovsiz safarlar qaytaveradi (08.09.2026: 6 ta javobning
    // 5 tasi cheklovsiz edi). Ya'ni kesish SHU YERDA bo'lishi shart —
    // aks holda "Ayollar uchun" yoqilgani bilan ro'yxat o'zgarmasdi.
    if (womenOnly && ride.genderRestriction != 'female') return false;
    if (takesParcels && !ride.takesParcels) return false;
    if (hasAc && !ride.hasAc) return false;
    if (hasLuggage && !ride.hasLuggage) return false;
    if (noSmoking && !ride.noSmoking) return false;
    if (noPets && !ride.noPets) return false;
    if (maxTwoBack && !ride.maxTwoBack) return false;
    if (negotiable && !ride.isNegotiable) return false;
    if (drivingSpeed != null && ride.drivingSpeed != drivingSpeed) return false;

    // Safar umuman yaroqlimi — bu FOYDALANUVCHI FILTRI EMAS
    // ([isBookable] izohiga qarang).
    return isBookable(ride, now: now);
  }

  /// Safarni qidiruv natijasida KO'RSATISH mumkinmi.
  ///
  /// 🔴 NEGA [matches] DAN AJRATILDI (10.09.2026): natijalar ostida
  /// «N ta safar filtrlar tufayli yashirildi» degan yozuv bor va u
  /// `matches` kesgan hamma narsani sanaydi. Jo'nab ketgan safarni
  /// o'sha yerga qo'shsak, foydalanuvchi HECH QANDAY filtr yoqmagan
  /// holda «3 ta safar filtrlar tufayli yashirildi» degan YOLG'ONNI
  /// o'qirdi va yo'q filtrni qidirib yurardi.
  ///
  /// Endi ikki narsa ajratildi:
  ///   • [isBookable] — safar o'zi yaroqlimi (holat, vaqt). Yaroqsizi
  ///     umuman ro'yxatga kirmaydi va HECH QAYERDA sanalmaydi;
  ///   • [matches] — foydalanuvchi tanlagan filtrlar. Faqat shular
  ///     kesgan safar «yashirildi» deb sanaladi.
  /// 🔴 Mantiq [Ride.isBookable] ga ko'chirildi (12.09.2026) — safar
  /// sahifasidagi «Joy band qilish» tugmasi ham shu qoidaga bo'ysunsin,
  /// qidiruv bilan bir xil bo'lsin. Bu yerda faqat qidiruvga qulay
  /// statik ko'rinishi (`.where(SearchFilters.isBookable)`) saqlanadi.
  static bool isBookable(Ride ride, {DateTime? now}) =>
      ride.isBookable(now: now);

  SearchFilters copyWith({
    bool? womenOnly,
    bool? takesParcels,
    bool? hasAc,
    bool? hasLuggage,
    bool? noSmoking,
    bool? noPets,
    bool? maxTwoBack,
    bool? negotiable,
    DrivingSpeed? drivingSpeed,
    bool clearDrivingSpeed = false,
    double? priceMin,
    double? priceMax,

    /// Narx oralig'ini BUTUNLAY olib tashlash. `null` uzatish yetmaydi:
    /// u "o'zgartirma" degani.
    bool clearPrice = false,
  }) => SearchFilters(
    womenOnly: womenOnly ?? this.womenOnly,
    takesParcels: takesParcels ?? this.takesParcels,
    hasAc: hasAc ?? this.hasAc,
    hasLuggage: hasLuggage ?? this.hasLuggage,
    noSmoking: noSmoking ?? this.noSmoking,
    noPets: noPets ?? this.noPets,
    maxTwoBack: maxTwoBack ?? this.maxTwoBack,
    negotiable: negotiable ?? this.negotiable,
    drivingSpeed: clearDrivingSpeed
        ? null
        : (drivingSpeed ?? this.drivingSpeed),
    priceMin: clearPrice ? null : (priceMin ?? this.priceMin),
    priceMax: clearPrice ? null : (priceMax ?? this.priceMax),
  );

  /*
   * QURILMADA SAQLASH (2026-09-05, qulaylik auditining 4-darajasi:
   * «ilova bir marta aytilgan narsani ikkinchi marta so'raydimi»).
   *
   * 🔴 Filtrlar HAR ISHGA TUSHISHDA nolga qaytardi. Chekmaydigan odam
   * yoki konditsioner shart bo'lgan odam ularni har safar qaytadan
   * belgilardi — ilova uni hech qachon eslab qolmasdi.
   *
   * 🔑 NARX ATAYIN SAQLANMAYDI. Qulaylik xohishi ODAMNIKI («men
   * chekmayman»), narx oralig'i esa YO'NALISHNIKI: «50–100 ming»
   * Toshkent–Samarqandda ma'noli, Toshkent–Andijonda esa hamma
   * safarni jimgina yashirib qo'yadi. Odam buni sezmaydi va «safar
   * yo'q ekan» deb o'ylaydi.
   */
  Map<String, dynamic> toJson() => {
    'womenOnly': womenOnly,
    'takesParcels': takesParcels,
    'hasAc': hasAc,
    'hasLuggage': hasLuggage,
    'noSmoking': noSmoking,
    'noPets': noPets,
    'maxTwoBack': maxTwoBack,
    'negotiable': negotiable,
    'drivingSpeed': drivingSpeed?.name,
  };

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    bool flag(String key) => json[key] == true;
    final speed = json['drivingSpeed'];
    return SearchFilters(
      womenOnly: flag('womenOnly'),
      takesParcels: flag('takesParcels'),
      hasAc: flag('hasAc'),
      hasLuggage: flag('hasLuggage'),
      noSmoking: flag('noSmoking'),
      noPets: flag('noPets'),
      maxTwoBack: flag('maxTwoBack'),
      negotiable: flag('negotiable'),
      // ⚠️ Noma'lum qiymat — `null`, xato EMAS: eski qurilmada
      // saqlangan yozuv yangi ilovada uchrashi mumkin va u butun
      // filtrni yiqitmasligi kerak.
      drivingSpeed: DrivingSpeed.values
          .where((v) => v.name == speed)
          .firstOrNull,
    );
  }
}

/// Natijalarni tartiblash.
enum SearchSort {
  /// Jo'nash nuqtasiga eng yaqini tepada — web'dagi standart.
  distance,
  time,
  price,
}

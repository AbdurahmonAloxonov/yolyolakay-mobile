import 'package:flutter/widgets.dart';

import 'cyrillic.dart';

/// Tarjimalar — ARB/codegen'siz, oddiy sinf.
///
/// Standart til `uz` (`.uz` domenida mehmon o'zbekchada ochilishi kerak);
/// tanlov qurilmada saqlanadi, chunki tilning "aralashib" ketishi asosan
/// saqlanmaslikdan kelib chiqadi.
/// Qo'llab-quvvatlanadigan tillar. Standart — `uz`.
/// Ilova tillari.
///
/// 🔑 [uzCyrl] — O'ZBEK KIRILI (2026-09-08). U alohida matnlar to'plami
/// EMAS: `_()` lotincha matnni o'girib beradi (`l10n/cyrillic.dart`).
/// Sabab u yerda batafsil — qisqasi, 763 ta matnni ikki nusxada
/// saqlash ertaga ikkalasining ajralib ketishiga olib boradi.
enum Lang { uz, uzCyrl, ru, en }

/// Kod → til. Backend `locale` maydonida `uz-Cyrl` ni saqlaydi
/// (08.09.2026 da jonli o'lchandi: yozildi va o'sha holicha qaytdi).
Lang langFromCode(String? code) => switch (code) {
  'ru' => Lang.ru,
  'en' => Lang.en,
  'uz-Cyrl' || 'uz_cyrl' || 'uz-cyrl' => Lang.uzCyrl,
  _ => Lang.uz,
};

/// Til → backendga va sozlamalarga yoziladigan kod.
String langCode(Lang lang) => switch (lang) {
  Lang.uz => 'uz',
  Lang.uzCyrl => 'uz-Cyrl',
  Lang.ru => 'ru',
  Lang.en => 'en',
};

class AppStrings {
  const AppStrings(this.lang);

  final Lang lang;

  /// Kontekstdagi til.
  ///
  /// 🔴 `languageCode` YETMAYDI: o'zbek lotini ham, kirili ham `uz`
  /// beradi va kirill tanlangan bo'lsa ham LOTIN matn chiqardi.
  /// Farq `scriptCode` da (`Locale.fromSubtags(... scriptCode: 'Cyrl')`).
  /// Buni sinov ushladi — 320 px dagi tugma sinovi kirill yozuvini
  /// kutib, lotinchasini topgandi.
  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(
      langFromCode(
        locale.scriptCode == 'Cyrl' ? 'uz-Cyrl' : locale.languageCode,
      ),
    );
  }

  /// Matn tanlash.
  ///
  /// 🔑 KIRILL uchun alohida argument YO'Q: lotincha matn
  /// `toCyrillic` bilan o'giriladi. Aks holda har bir matn ikki
  /// nusxada yozilardi va ertaga tuzatish ikkinchisiga yetib
  /// bormasdi — bu naqsh loyihada allaqachon og'riq bergan.
  String _(String uz, String ru, String en) => switch (lang) {
    Lang.ru => ru,
    Lang.en => en,
    Lang.uzCyrl => toCyrillic(uz),
    Lang.uz => uz,
  };

  // Umumiy
  String get appName => 'YolYolakay';

  /// Ochilish ekranidagi shior — kirish ekranidagisi bilan bir xil ohang.
  String get splashTagline => _(
    "Yo'l-yo'lakay hamroh toping",
    'Найдите попутчиков в дорогу',
    'Find travel companions along the way',
  );

  /// Ovozli qidiruv tugmasining yonidagi ishora.
  ///
  /// Misol ATAYIN to'liq gap: odam "shahar nomini ayting" desa faqat
  /// bittasini aytadi va ikkinchi maydon bo'sh qoladi. Aynan shu xato
  /// saytda bor edi (egasi, 2026-08-24).
  /// «Bugun» kartasining yorlig'i — bosh ekranning tepasidagi yaqin safar.
  ///
  /// Ataylab "Bugun" emas, "Yaqin safar": karta 2 kundan keyingi safarni
  /// ham ko'rsatishi mumkin va "Bugun" u holda YOLG'ON bo'lardi.
  /// Aniq vaqt yonidagi hisoblagichda yozilgan.
  /// Chatdagi safar kartochkasidan safar ekraniga o'tish.
  String get openRide =>
      _('Safarni ochish', 'Открыть поездку', 'Open the ride');

  String get todayCardTitle =>
      _('Yaqin safar', 'Ближайшая поездка', 'Next trip');

  /// Haydovchining o'z e'lonida — band o'rindiqlar.
  String seatsBookedOf(int taken, int total) => switch (lang) {
    Lang.ru => '$taken из $total мест занято',
    Lang.en => '$taken of $total seats booked',
    Lang.uz => '$total o\'rindan $taken tasi band',
    Lang.uzCyrl => toCyrillic('$total o\'rindan $taken tasi band'),
  };

  String get voiceRouteHint => _(
    'Ayting: «Toshkentdan Samarqandga»',
    'Скажите: «из Ташкента в Самарканд»',
    'Say: "from Tashkent to Samarkand"',
  );

  String get voiceListening => _('Tinglayapman…', 'Слушаю…', 'Listening…');

  /// Ovozdan faqat bitta joy tanildi — ikkinchisi qo'lda kiritiladi.
  String get voiceHalfRecognised => _(
    'Bitta shahar tanildi — ikkinchisini kiriting',
    'Распознан один город — введите второй',
    'One city recognised — enter the other',
  );

  // ===== Formadan chiqish =====
  String get leaveFormTitle => _('Chiqasizmi?', 'Выйти?', 'Leave this page?');
  String get leaveFormBody => _(
    "Kiritilgan ma'lumot saqlanmaydi.",
    'Введённые данные не сохранятся.',
    'What you entered will not be saved.',
  );
  String get leaveFormStay => _('Qolish', 'Остаться', 'Stay');
  String get leaveFormLeave => _('Chiqish', 'Выйти', 'Leave');

  String get cancel => _('Bekor qilish', 'Отмена', 'Cancel');
  String get retry => _('Qayta urinish', 'Повторить', 'Try again');

  /// Haydovchi arizani qabul qildi — polling bilan kelgan o'zgarish payqalsin.
  String get driverAcceptedRequest => _(
    'Haydovchi arizangizni qabul qildi!',
    'Водитель принял вашу заявку!',
    'The driver accepted your request!',
  );

  String get driverDeclinedRequest => _(
    'Haydovchi arizangizni rad etdi',
    'Водитель отклонил вашу заявку',
    'The driver declined your request',
  );

  /// Bronlar ro'yxati yuklanmadi — bron tugmasi shu sabab o'chiq (dublikat xavfi).
  String get bookingsUnavailable => _(
    "Arizalaringiz yuklanmadi — bron qilib bo'lmaydi",
    'Ваши заявки не загрузились — забронировать нельзя',
    'Your requests could not be loaded — booking is unavailable',
  );
  String get save => _('Saqlash', 'Сохранить', 'Save');

  /// Ekran o'quvchisi (TalkBack) uchun yorliqlar — ikonkali tugmalarda
  /// KO'RINADIGAN matn yo'q, ya'ni bularsiz ular shunchaki "tugma" deb
  /// o'qiladi va ko'zi ojiz odam ilovadan foydalana olmaydi.
  String get clearDate => _('Sanani tozalash', 'Очистить дату', 'Clear date');

  String get clearSearch =>
      _('Qidiruvni tozalash', 'Очистить поиск', 'Clear search');
  String get seatsDecrease =>
      _('Joyni kamaytirish', 'Уменьшить количество мест', 'Fewer seats');
  String get seatsIncrease =>
      _('Joyni oshirish', 'Увеличить количество мест', 'More seats');
  String get sendMessage =>
      _('Xabarni yuborish', 'Отправить сообщение', 'Send message');
  String get changePhoto =>
      _('Suratni o\'zgartirish', 'Изменить фото', 'Change photo');
  String get viewPhoto =>
      _('Suratni ko\'rish', 'Посмотреть фото', 'View photo');
  String get enterCodeField =>
      _('Tasdiqlash kodi', 'Код подтверждения', 'Verification code');

  String get scrollToTop => _('Yuqoriga', 'Наверх', 'Scroll to top');

  String get close => _('Yopish', 'Закрыть', 'Close');
  String get removeItem => _('Olib tashlash', 'Убрать', 'Remove');
  String get seatIncrease => _('Ko\'proq joy', 'Больше мест', 'More seats');
  String get seatDecrease => _('Kamroq joy', 'Меньше мест', 'Fewer seats');
  String get loading => _('Yuklanmoqda...', 'Загрузка...', 'Loading...');
  String get seats => _('joy', 'мест', 'seats');
  String get sum => _("so'm", 'сум', 'UZS');

  // Auth
  String get loginTitle => _('Kirish', 'Вход', 'Sign in');
  String get phoneLabel => _('Telefon raqam', 'Номер телефона', 'Phone number');
  String get phoneHint =>
      _('Raqamingizni kiriting', 'Введите ваш номер', 'Enter your number');
  String get sendCode => _('Kod yuborish', 'Отправить код', 'Send the code');
  String get otpTitle =>
      _('Tasdiqlash kodi', 'Код подтверждения', 'Verification code');
  String get otpSentTo =>
      _('Kod yuborildi', 'Код отправлен на', 'Code sent to');
  String get otpLabel => _('5 xonali kod', '5-значный код', '5-digit code');
  String get verify => _('Tasdiqlash', 'Подтвердить', 'Confirm');
  // Kod to'g'ri chiqqach kataklar yashil yonadi va shu yozuv chiqadi
  // (`otp_code_field.dart`). Saytdagi yozuv bilan AYNAN bir xil.
  String get otpConfirmed => _('Tasdiqlandi', 'Подтверждено', 'Confirmed');
  String get resendCode =>
      _('Kodni qayta yuborish', 'Отправить код заново', 'Resend code');
  String get resendIn => _('Qayta yuborish', 'Повторно через', 'Resend in');
  String get invalidPhone => _(
    "Raqam to'liq emas",
    'Номер введён не полностью',
    'The number is incomplete',
  );
  String get invalidOtp => _(
    'Kod 5 xonali bo\'lishi kerak',
    'Код должен быть из 5 цифр',
    'The code must be 5 digits',
  );

  /// Yangi hisob yaratilgach — profilni to'ldirishga taklif.
  String get welcomeFillProfile => _(
    "Xush kelibsiz! Profilingizni to'ldiring",
    'Добро пожаловать! Заполните профиль',
    'Welcome! Please fill in your profile',
  );

  /// 403 `new_device` dan keyin kod ekranida ko'rsatiladi.
  String get newDeviceHint => _(
    'Siz yangi qurilmadan kiryapsiz. Hisobingizni himoya qilish uchun SMS kodni kiriting.',
    'Вы входите с нового устройства. Для защиты аккаунта введите код из SMS.',
    'You are signing in from a new device. Enter the SMS code to protect your account.',
  );

  String get swapPlaces => _('Almashtirish', 'Поменять местами', 'Swap');

  String get changeNumber =>
      _('Raqamni o\'zgartirish', 'Изменить номер', 'Change the number');

  // Qidiruv
  String get searchTitle => _('Safar qidirish', 'Поиск поездки', 'Find a ride');

  /// Bosh ekranning BAYONOTI — «Safar qidirish» degan sarlavha o'rniga.
  ///
  /// 🔴 NEGA (2026-09-02): eski sarlavha ekran nomini takrorlardi va
  /// pastdagi «Qidirish» tugmasi bilan bir gapni ikki marta aytardi.
  /// Savol ko'rinishidagi sarlavha esa odamni darhol ishga soladi.
  String get searchHeadline => _('Qayerga boramiz?', 'Куда едем?', 'Where to?');
  String get from => _('Qayerdan', 'Откуда', 'From');
  String get to => _('Qayerga', 'Куда', 'To');
  String get date => _('Sana', 'Дата', 'Date');
  String get anyDate => _('Istalgan sana', 'Любая дата', 'Any date');

  String get passengers => _('Yo\'lovchilar', 'Пассажиры', 'Passengers');
  String get searchButton => _('Qidirish', 'Найти', 'Search rides');

  /// XABAR sifatida — «shaharni tanlamadingiz» deb aytadigan toast.
  String get selectCity => _(
    'Shahar yoki tumanni tanlang',
    'Выберите город или район',
    'Choose a city or district',
  );

  /// MAYDON ICHIDAGI TAKLIF — hali shahar tanlanmaganda.
  ///
  /// 🔴 NEGA [selectCity] DAN AJRATILDI (10.09.2026): maydonda o'sha
  /// buyruq matni turardi va u SIG'MASDI — o'lchandi (haqiqiy shrift
  /// bilan, 320 px, ruscha, matn shkalasi 1.3): maydonga 161 px
  /// beriladi, «Выберите город или район» esa 270 px talab qiladi va
  /// ikki qatorga ham sig'may kesilardi.
  ///
  /// Ustiga u ORTIQCHA edi: maydonning tepasida allaqachon yorliq
  /// turadi («Qayerdan» / «Qayerga»), ya'ni «tanlang» so'zi hech nima
  /// qo'shmasdi. Taklif faqat QANDAY QIYMAT kutilayotganini aytsa
  /// yetadi.
  String get cityOrDistrict =>
      _('Shahar yoki tuman', 'Город или район', 'City or district');
  String get searchPlaceHint => _(
    'Shahar yoki tuman nomi',
    'Название города или района',
    'City or district name',
  );
  String get districtsOnly =>
      _('Faqat tumanlar', 'Только районы', 'Districts only');
  String get citiesSection => _('SHAHARLAR', 'ГОРОДА', 'CITIES');
  String get districtsSection => _('TUMANLAR', 'РАЙОНЫ', 'DISTRICTS');
  String get districtLabel => _('Tuman', 'Район', 'District');
  String get placeNotFound => _(
    'Bunday joy ro\'yxatda yo\'q. Yaqin shaharni tanlang.',
    'Такого места нет в списке. Выберите ближайший город.',
    'That place is not in the list. Pick a nearby city.',
  );
  String get sameCityError => _(
    'Jo\'nash va borish shahri bir xil',
    'Город отправления и назначения совпадают',
    'Departure and destination cities are the same',
  );
  String get pickBothCities => _(
    'Ikkala shaharni ham tanlang',
    'Выберите оба города',
    'Choose both cities',
  );
  String get resultsTitle =>
      _('Topilgan safarlar', 'Найденные поездки', 'Rides found');
  String get recentRoutes =>
      _('Oxirgi yo\'nalishlar', 'Недавние маршруты', 'Recent routes');

  /// So'nggi KO'RILGAN safarlar — yo'nalish emas, aynan o'sha safar.
  // ===== Yo'nalish kuzatuvchisi =====

  /// Bo'sh natijada chiqadigan taklif.
  String get routeWatchAdd => _(
    'Safar chiqsa xabar bering',
    'Сообщить, когда появится поездка',
    'Notify me when a ride appears',
  );
  String get routeWatchOn => _('Kuzatilmoqda', 'Отслеживается', 'Watching');

  /// 🔴 CHEKLOV OCHIQ AYTILADI: bu push emas va push o'rnini bosmaydi.
  String get routeWatchHint => _(
    'Ilovani ochganingizda tekshiramiz',
    'Проверим, когда вы откроете приложение',
    'We check when you open the app',
  );
  String get routeWatchFoundTitle =>
      _('Safar topildi!', 'Появилась поездка!', 'A ride is available');
  String routeWatchFoundBody(String from, String to, int count) =>
      switch (lang) {
        Lang.ru => '$from — $to: $count поездк(и)',
        Lang.en => '$from — $to: $count ride(s)',
        Lang.uz => '$from — $to: $count ta safar',
        Lang.uzCyrl => toCyrillic('$from — $to: $count ta safar'),
      };

  /// MASHINA MODERATSIYASI tugagani haqidagi MAHALLIY bildirishnoma
  /// (`core/car_moderation_watch.dart`). Backend bu holat uchun push
  /// yubormaydi — so'ralgan, javob kutilmoqda.
  String get carApprovedTitle => _(
    'Mashinangiz tasdiqlandi',
    'Автомобиль подтверждён',
    'Your car is approved',
  );
  String carApprovedBody(String plate) => switch (lang) {
    Lang.ru =>
      plate.isEmpty
          ? 'Теперь можно публиковать поездки'
          : '$plate — теперь можно публиковать поездки',
    Lang.en =>
      plate.isEmpty
          ? 'You can publish rides now'
          : '$plate — you can publish rides now',
    Lang.uz =>
      plate.isEmpty
          ? 'Endi e\'lon bera olasiz'
          : '$plate — endi e\'lon bera olasiz',
    Lang.uzCyrl => toCyrillic(
      plate.isEmpty
          ? 'Endi e\'lon bera olasiz'
          : '$plate — endi e\'lon bera olasiz',
    ),
  };

  /// 🔑 Sabab YOZILMAYDI: backend uni bermaydi (xatda so'raldi). O'ylab
  /// topilgan sabab («surat xira») haqiqiysidan battar — odam noto'g'ri
  /// narsani qayta yuklaydi va yana rad javobini oladi.
  String get carRejectedTitle =>
      _('Mashina qaytarildi', 'Автомобиль отклонён', 'Car was rejected');
  String carRejectedBody(String plate) => switch (lang) {
    Lang.ru =>
      plate.isEmpty
          ? 'Откройте профиль — нужно загрузить фото заново'
          : '$plate — откройте профиль, фото нужно загрузить заново',
    Lang.en =>
      plate.isEmpty
          ? 'Open your profile — the photos need to be uploaded again'
          : '$plate — open your profile, the photos need re-uploading',
    Lang.uz =>
      plate.isEmpty
          ? 'Profilni oching — suratlarni qayta yuklash kerak'
          : '$plate — profilni oching, suratlarni qayta yuklash kerak',
    Lang.uzCyrl => toCyrillic(
      plate.isEmpty
          ? 'Profilni oching — suratlarni qayta yuklash kerak'
          : '$plate — profilni oching, suratlarni qayta yuklash kerak',
    ),
  };

  String get recentlyViewed =>
      _('So\'nggi ko\'rilganlar', 'Вы недавно смотрели', 'Recently viewed');

  String get favoriteRoutes =>
      _('Sevimli yo\'nalishlar', 'Избранные маршруты', 'Favorite routes');

  String get replyingLabel => _('Javob', 'Ответ', 'Reply');
  String get addToFavorites =>
      _('Sevimliga qo\'shish', 'В избранное', 'Add to favorites');
  String get removeFromFavorites =>
      _('Sevimlidan olish', 'Убрать из избранного', 'Remove from favorites');

  // Filtrlar
  String get filters => _('Filtrlar', 'Фильтры', 'Filters');

  /// Narx oralig'i — SERVER filtri (saytdagi bilan bir xil).
  String get priceRange => _('Narx oralig\'i', 'Цена', 'Price range');
  String get priceFrom => _('dan', 'от', 'from');
  String get priceTo => _('gacha', 'до', 'to');

  String get resetFilters => _('Tozalash', 'Сбросить', 'Reset');

  /// E'lon berish formasining bo'lim nomlari.
  String get routeSection => _('Marshrut', 'Маршрут', 'Route');
  String get whenAndPriceSection =>
      _('Vaqt va narx', 'Время и цена', 'Time and price');
  String get extrasSection =>
      _('Qo\'shimcha sozlamalar', 'Дополнительно', 'More options');
  String get extrasHint => _(
    'Qulayliklar, haydash uslubi, cheklovlar',
    'Удобства, стиль вождения, ограничения',
    'Comfort, driving style, restrictions',
  );

  /// Yopiq bo'limda nechta sozlama yoqilgani. Yalang'och raqam ("3")
  /// nimani anglatishi bilinmasdi.
  String extrasEnabled(int count) => _(
    '$count ta sozlama yoqilgan',
    'Включено настроек: $count',
    '$count enabled',
  );

  /// Haydovchi ekrani: o'z safarini boshqarish.
  String get myRideTitle => _('Mening safarim', 'Моя поездка', 'My ride');

  /// Bron panelidagi yakuniy summa yorlig'i.
  String get priceTotal => _('Jami', 'Итого', 'Total');

  String get awaitingAnswer =>
      _('javob kutmoqda', 'ждут ответа', 'awaiting reply');

  /// «7 so'rov · 4 o'rin bo'sh» — haydovchi tanlashdan oldin ko'radi.
  String seatBalance(int pending, int free) => switch (lang) {
    Lang.uz => '$pending so\'rov · $free o\'rin bo\'sh',
    Lang.uzCyrl => toCyrillic('$pending so\'rov · $free o\'rin bo\'sh'),
    Lang.ru => '$pending заявок · $free мест свободно',
    Lang.en => '$pending requests · $free seats free',
  };

  /// So'rov o'rindan KO'P bo'lganda — bu xato emas, tanlov.
  String get seatBalanceHint => _(
    "So'rov o'rindan ko'p — kimni olishni o'zingiz tanlaysiz. "
        "O'rin faqat siz qabul qilganingizda band bo'ladi",
    'Заявок больше, чем мест — выбираете вы. Место занимается только '
        'когда вы примете заявку',
    'More requests than seats — you choose. A seat is taken only when '
        'you accept',
  );

  /// SAVDOLASHISH — haydovchi o'z narxini qaytaradi.
  String get counterOffer =>
      _('Narx taklif qilish', 'Предложить цену', 'Offer a price');
  String get counterOfferHint => _(
    'Yo\'lovchiga o\'z narxingizni qaytarasiz. U rozi bo\'lsa bron tasdiqlanadi.',
    'Вы предложите пассажиру свою цену. Если он согласится, бронь подтвердится.',
    'You send the passenger your own price. If they accept, the booking is confirmed.',
  );
  String get yourPrice => _('Sizning narxingiz', 'Ваша цена', 'Your price');
  String get counterOfferSent =>
      _('Narx yuborildi', 'Цена отправлена', 'Price sent');
  String get confirmedLabel => _('Tasdiqlangan', 'Подтверждено', 'Confirmed');

  /// Filtrlar varag'idagi bo'lim nomi va yopish tugmasi.
  String get drivingStyle =>
      _('Haydash uslubi', 'Стиль вождения', 'Driving style');
  String get showResults => _('Ko\'rsatish', 'Показать', 'Show results');

  /// BOSH EKRAN VIDJETI.
  ///
  /// ⚠️ Matn QISQA bo'lishi shart: vidjet 2 ustunli katakda ham
  /// turishi mumkin va uzun jumla u yerda kesilib ketadi.
  String get widgetEmpty => _('Safar qidirish', 'Найти поездку', 'Find a ride');

  /// Plakat nisbati — ulashish varag'idagi tanlov.
  String get posterFeed => _('Lentaga', 'В ленту', 'For the feed');
  String get posterStory => _('Hikoyaga', 'В историю', 'For a story');

  String get widgetTitle => _('Yaqin safar', 'Ближайшая поездка', 'Next ride');

  String get womenOnlyFilter =>
      _('Faqat ayollar', 'Только женщины', 'Women only');

  /// Filtr ostidagi izoh — belgi NIMANI anglatishini aytadi.
  ///
  /// 🔑 «Haydovchi ayol» EMAS: erkak haydovchi ham salonga faqat ayol
  /// yo'lovchi olishi mumkin va belgi aynan shuni bildiradi (egasi,
  /// 08.09.2026).
  String get womenOnlyHint => _(
    'Haydovchi bu safarga faqat ayol yo\'lovchi oladi',
    'Водитель берёт в эту поездку только женщин',
    'The driver takes only female passengers on this ride',
  );

  /// E'lon formasida — haydovchiga ogohlantirish.
  String get womenOnlyDriverHint => _(
    'Bunday safar qidiruvda faqat «Faqat ayollar» filtri yoqilganda ko\'rinadi',
    'Такая поездка видна в поиске только с включённым фильтром «Только женщины»',
    'Such a ride appears in search only with the "Women only" filter on',
  );
  String get parcelFilter => _('Pochta', 'Посылка', 'Parcel');
  String get sortTitle => _('Saralash', 'Сортировка', 'Sort');
  String get sortDistance => _('Yaqinlik', 'По близости', 'Nearest');
  String get sortTime => _('Vaqt', 'По времени', 'Time');
  String get sortPrice => _('Narx', 'По цене', 'Price');
  String hiddenByFilters(int count) => _(
    '$count ta safar filtrlar sabab yashirildi',
    '$count поездок скрыто фильтрами',
    '$count rides hidden by filters',
  );
  String get nothingMatchesFilters => _(
    'Filtrlarga mos safar yo\'q',
    'Нет поездок, подходящих под фильтры',
    'No rides match your filters',
  );
  String get kmAway => _('km', 'км', 'km');
  String get noResults => _(
    'Bu yo\'nalishda safar topilmadi',
    'Поездок по этому маршруту не найдено',
    'No rides found on this route',
  );

  /// Bo'sh natijadan chiqish yo'li — izoh "sanani o'zgartiring" deydi.
  String get changeSearch =>
      _('Qidiruvni o\'zgartirish', 'Изменить поиск', 'Change search');

  /// Bo'sh natijadagi bir bosishlik amallar (izohi
  /// `search_results_screen.dart` da).
  String get clearFilters =>
      _('Filtrlarni tozalash', 'Сбросить фильтры', 'Clear filters');
  String widenSearch(int km) => _(
    'Qidiruvni $km km ga kengaytirish',
    'Расширить поиск до $km км',
    'Widen the search to $km km',
  );
  String searchRadiusNote(int km) => _(
    'Qidiruv $km km atrofida',
    'Поиск в радиусе $km км',
    'Searching within $km km',
  );

  /// Bo'sh natija ekrani — «bu yo'nalishda safar yo'q, lekin bularga bor».
  String get noRidesYet =>
      _('hozircha safar yo\'q', 'поездок пока нет', 'no rides yet');
  String get noDriversYet => _(
    'Bu yo\'nalishda haydovchilar hali e\'lon bermagan.',
    'Водители пока не опубликовали объявления по этому маршруту.',
    'Drivers have not posted any listings for this route yet.',
  );
  String ridesAvailableFrom(String city) => _(
    '$city dan quyidagi shaharlarga safarlar bor',
    'Зато из города $city есть поездки в',
    'But there are rides from $city to',
  );
  String get ridesAvailableTo => _(
    'Quyidagi shaharlarga safarlar bor',
    'Есть поездки в',
    'There are rides to',
  );
  String get tapCityToSearch => _(
    'Shaharni bosing — o\'sha yo\'nalish bo\'yicha qidiramiz.',
    'Нажмите на город — поищем по этому направлению.',
    'Tap a city and we will search that route.',
  );

  String get noResultsHint => _(
    'Sanani o\'zgartiring yoki keyinroq qayta urinib ko\'ring',
    'Измените дату или попробуйте позже',
    'Change the date or try again later',
  );

  // Safar kartasi / detali
  String get freeSeats => _('bo\'sh joy', 'свободных мест', 'seats free');
  String get perSeat => _('bir joy uchun', 'за место', 'per seat');
  String get driver => _('Haydovchi', 'Водитель', 'Driver');
  String get rideDetails =>
      _('Safar tafsilotlari', 'Детали поездки', 'Trip details');
  String get bookButton => _('Joy band qilish', 'Забронировать', 'Book a seat');

  /*
   * O'CHIQ TUGMANING SABABI (2026-09-05, qulaylik auditining
   * 5-darajasi). «Joy band qilish» tugmasi TO'RT xil holatda o'chib
   * qolardi va bironta holda SABABI aytilmasdi — odam uchun bu
   * «tugma ishlamayapti» degani. Aynan shu shikoyat loyihada besh
   * marta qaytgan (izohi `BottomActionBar` da).
   */
  String get seatsSoldOut =>
      _('Bo\'sh joy qolmadi', 'Свободных мест нет', 'No seats left');
  String get bookingClosed => _(
    'Bu safarga endi bron qilib bo\'lmaydi',
    'На эту поездку больше нельзя забронировать',
    'This trip no longer accepts bookings',
  );
  String get booked =>
      _('So\'rov yuborildi', 'Запрос отправлен', 'Request sent');
  // Savdolashish
  String get yourOffer =>
      _('Sizning taklifingiz', 'Ваше предложение', 'Your offer');
  String get agreeWithPrice => _(
    'E\'lon narxiga rozisiz',
    'Вы согласны с ценой объявления',
    'You agree with the listed price',
  );
  String get offerDiffersHint => _(
    'Haydovchi taklifni qabul qilishi yoki rad etishi mumkin',
    'Водитель может принять или отклонить предложение',
    'The driver may accept or decline your offer',
  );
  String get resetOffer => _(
    'E\'lon narxiga qaytarish',
    'Вернуть цену объявления',
    'Reset to the listed price',
  );
  String get sendOffer =>
      _('Taklif yuborish', 'Отправить предложение', 'Send an offer');
  String get buyoutTitle =>
      _('Butun salonni olaman', 'Выкупаю весь салон', 'Book the whole car');
  String get buyoutHint => _(
    'Barcha bo\'sh joylar siznikiga o\'tadi',
    'Все свободные места достанутся вам',
    'All free seats become yours',
  );

  String get bookingPending => _(
    'Haydovchi tasdig\'i kutilmoqda',
    'Ожидается подтверждение водителя',
    'Waiting for the driver to confirm',
  );

  /// Xaritada tanlangan safarning oraliq shaharlari.
  ///
  /// 🔑 «Yo'l ustidan qo'shilish mumkin» — bu yo'lovchining eng ko'p
  /// beradigan savoliga to'g'ridan javob. Shaharlar ro'yxati belgilar
  /// bilan ham ko'rinadi, lekin yozuvsiz odam ular nima ekanini
  /// bilmaydi.
  String joinAlongRoute(String cities) => _(
    'Yo\'l ustidan qo\'shilish mumkin: $cities',
    'Можно присоединиться по пути: $cities',
    'You can join along the way: $cities',
  );

  String get stopsTitle => _('Yo\'l-yo\'lakay', 'По пути', 'Via cities');
  String get pickupPoint =>
      _('Uchrashuv joyi', 'Место встречи', 'Meeting point');
  String get negotiable =>
      _('Narx kelishiladi', 'Цена договорная', 'Price is negotiable');
  String get noSmoking => _('Chekilmaydi', 'Не курят', 'No smoking');
  String get noPets => _('Hayvonsiz', 'Без животных', 'No pets');
  String get hasAc => _('Konditsioner', 'Кондиционер', 'Air conditioning');
  String get hasLuggage =>
      _('Yuk joyi bor', 'Есть место для багажа', 'Luggage space');
  String get takesParcels =>
      _('Pochta oladi', 'Возит посылки', 'Takes parcels');
  String get maxTwoBack => _('Orqada 2 kishi', 'Сзади двое', 'Two in the back');
  String get speedCalm => _('Sekin haydaydi', 'Едет спокойно', 'Drives calmly');
  String get speedNormal =>
      _('O\'rtacha tezlik', 'Средняя скорость', 'Moderate speed');
  String get speedFast => _('Tez haydaydi', 'Едет быстро', 'Drives fast');
  String get fairPrice => _('Adolatli narx', 'Честная цена', 'Fair price');
  String get forWomen => _('Faqat ayollar', 'Только для женщин', 'Women only');
  String get forMen => _('Faqat erkaklar', 'Только для мужчин', 'Men only');

  // Safarlarim
  String get myTripsTitle => _('Safarlarim', 'Мои поездки', 'My trips');
  String get asPassenger => _('Yo\'lovchi', 'Пассажир', 'Passenger');
  String get asDriver => _('Haydovchi', 'Водитель', 'Driver');
  String get noTrips =>
      _('Hali safar yo\'q', 'Поездок пока нет', 'No trips yet');
  String get noBookings =>
      _('Hali bron yo\'q', 'Броней пока нет', 'No bookings yet');

  // Profil to'ldirish (yangi hisob)
  String get completeProfileTitle =>
      _('Profilni to\'ldiring', 'Заполните профиль', 'Complete your profile');
  String get completeProfileHint => _(
    'Hamrohlaringiz sizni ism bilan ko\'rishadi',
    'Попутчики будут видеть вас по имени',
    'Your travel companions will see you by name',
  );

  /// «Hamrohlar» — safar sahifasida BOSHQA tasdiqlangan yo'lovchilar
  /// ro'yxati sarlavhasi (`GET /rides/{id}/passengers`).
  String get coPassengers => _('Hamrohlar', 'Попутчики', 'Fellow passengers');

  /// Ro'yxatda faqat SIZ borsiz — hamroh yo'q (kutamiz).
  String get coPassengersOnlyYou => _(
    'Hozircha boshqa hamroh yo\'q',
    'Пока других попутчиков нет',
    'No other passengers yet',
  );

  String get firstName => _('Ism', 'Имя', 'First name');
  String get lastName => _('Familiya', 'Фамилия', 'Last name');
  String get gender => _('Jins', 'Пол', 'Gender');
  String get male => _('Erkak', 'Мужской', 'Male');
  String get female => _('Ayol', 'Женский', 'Female');
  String get continueButton => _('Davom etish', 'Продолжить', 'Continue');
  String get nameRequired => _(
    'Ism va familiyani kiriting',
    'Введите имя и фамилию',
    'Enter your first and last name',
  );

  // ===== ROL TANLASH — kod tasdiqlangandan KEYIN, ma'lumotdan OLDIN =====
  //
  // 🔴 NEGA SHU YERDA (egasi, 22.09.2026): ilgari yangi odam ro'yxatdan
  // o'tib BIRDAN yo'lovchi qidiruv ekraniga tushardi. Haydovchi esa o'zi
  // uchun mo'ljallangan yo'lni faqat profil ichidan qidirib topishi kerak
  // edi — ya'ni ilova «sen kimsan?» deb HECH QACHON so'ramagan.
  //
  // ⚠️ Rol SERVERDA shu yerda o'zgarmaydi: haydovchilik `POST /users/upgrade`
  // (hujjat + mashina) orqali beriladi va moderatsiyadan o'tadi. Shuning
  // uchun matn «haydovchi bo'lding» demaydi — «keyingi qadam tekshiruv»
  // deydi.
  String get chooseRoleTitle => _('Siz kimsiz?', 'Кто вы?', 'Who are you?');
  String get chooseRoleHint => _(
    'Keyin buni profilda istalgan vaqt o\'zgartirasiz',
    'Позже это можно изменить в профиле в любой момент',
    'You can change this later in your profile at any time',
  );
  String get chooseRolePassengerHint => _(
    'Safar qidiraman va joy bron qilaman',
    'Ищу поездки и бронирую место',
    'I look for rides and book a seat',
  );
  String get chooseRoleDriverHint => _(
    'E\'lon beraman va yo\'lovchi olaman',
    'Публикую поездки и беру пассажиров',
    'I publish rides and take passengers',
  );

  /// Haydovchi tanlaganga — VA'DA EMAS, keyingi qadam.
  /// O'chiq tugmaning SABABI (loyiha qoidasi: jim o'chiq tugma —
  /// boshi berk ko'cha).
  String get chooseRoleRequired => _(
    'Davom etish uchun birini tanlang',
    'Выберите один из вариантов, чтобы продолжить',
    'Choose one to continue',
  );
  String get chooseRoleDriverNote => _(
    'Buning uchun guvohnoma, texpasport va mashina suratlari tekshiruvdan '
        'o\'tadi. Tekshiruvgacha yo\'lovchi sifatida foydalanasiz.',
    'Для этого права, техпаспорт и фото машины пройдут проверку. До '
        'проверки вы пользуетесь приложением как пассажир.',
    'Your licence, vehicle passport and car photos will be checked first. '
        'Until then you use the app as a passenger.',
  );

  // Haydovchi bo'lish
  String get becomeDriverTitle =>
      _('Haydovchi bo\'lish', 'Стать водителем', 'Become a driver');
  String get carBrand => _('Marka', 'Марка', 'Make');
  String get carModel => _('Model', 'Модель', 'Model');
  String get govNumber => _('Davlat raqami', 'Госномер', 'Plate number');
  String get govNumberHint => _('01 A 123 BC', '01 A 123 BC', '01 A 123 BC');
  String get fillAllFields => _(
    'Barcha maydonlarni to\'ldiring',
    'Заполните все поля',
    'Fill in all the fields',
  );
  String get becomeDriverDone => _(
    'Tabriklaymiz! Endi haydovchisiz',
    'Поздравляем! Теперь вы водитель',
    'Congratulations! You are a driver now',
  );
  String get alreadyDriver => _(
    'Siz allaqachon haydovchisiz',
    'Вы уже водитель',
    'You are already a driver',
  );

  // E'lon berish
  String get createRideTitle =>
      _('E\'lon berish', 'Опубликовать поездку', 'Publish a trip');
  String get departure =>
      _('Jo\'nash vaqti', 'Время отправления', 'Departure time');
  String get pickTime => _('Vaqtni tanlang', 'Выберите время', 'Choose a time');
  String get pricePerSeatLabel =>
      _('Bir joy narxi', 'Цена за место', 'Price per seat');
  String get totalSeatsLabel =>
      // 🔴 "Nechta joy bor" 360px ekranda ikki qatorga bo'linib, yonidagi
      // "− 3 +" boshqaruvini pastga surib yuborardi (qurilmada ko'rildi
      // 2026-08-13). Bitta qatorga sig'adigan qisqa nom.
      _('Joylar soni', 'Мест в машине', 'Seats');
  String get vehicle => _('Mashina', 'Машина', 'Car');
  String get pickVehicle =>
      _('Mashinani tanlang', 'Выберите машину', 'Choose a car');
  String get noVehicleWarning => _(
    'E\'lon berish uchun avval haydovchi bo\'lishingiz kerak',
    'Чтобы опубликовать поездку, сначала станьте водителем',
    'You need to become a driver before publishing a trip',
  );
  String get moderationWarning => _(
    'Mashina moderatsiyadan o\'tmagan — e\'lon faollashmasligi mumkin',
    'Машина не прошла модерацию — поездка может не активироваться',
    'Your car is not approved yet — the trip may not go live',
  );
  String get addStop => _(
    'Oraliq shahar qo\'shish',
    'Добавить город по пути',
    'Add a city along the way',
  );
  String get stopsLimit => _('Ko\'pi bilan 3 ta', 'Не более 3', 'Up to 3');
  String get comfortTitle => _('Qulayliklar', 'Удобства', 'Comfort');
  String get restrictionTitle => _('Cheklov', 'Ограничение', 'Restriction');
  String get noRestriction =>
      _('Cheklovsiz', 'Без ограничений', 'No restriction');
  String get drivingSpeedTitle =>
      _('Haydash uslubi', 'Стиль вождения', 'Driving style');
  String get pickupPointHint => _(
    'Masalan: Metro «Chilonzor» yonida',
    'Например: у метро «Чиланзар»',
    'e.g. next to Chilonzor metro',
  );
  String get publish => _('E\'lon qilish', 'Опубликовать', 'Publish');

  /// «E'lonim qanday ko'rinadi» — yo'lovchi ko'zi bilan oldindan ko'rish.
  String get previewListing =>
      _('Qanday ko\'rinadi?', 'Как это выглядит?', 'How does it look?');
  String get previewListingHint => _(
    'Yo\'lovchilar e\'loningizni shunday ko\'radi',
    'Так ваше объявление увидят пассажиры',
    'This is how passengers will see your ride',
  );
  String get publishedAndActive => _(
    'E\'lon berildi va faollashtirildi',
    'Поездка опубликована и активна',
    'The trip is published and active',
  );
  String get publishedNotActive => _(
    'E\'lon yaratildi, lekin faollashmadi — qidiruvda ko\'rinmaydi',
    'Поездка создана, но не активирована — в поиске её не видно',
    'The trip was created but not activated — it will not appear in search',
  );
  String get priceRequired =>
      _('Narxni kiriting', 'Введите цену', 'Enter a price');
  String get timeInPast => _(
    'O\'tgan vaqtni tanlab bo\'lmaydi',
    'Нельзя выбрать прошедшее время',
    'You cannot pick a time in the past',
  );

  // Haydovchi safari
  String get bookingsTitle => _('Bronlar', 'Брони', 'Bookings');
  String get noBookingsYet =>
      _('Hali bron yo\'q', 'Броней пока нет', 'No bookings yet');
  String get accept => _('Qabul qilish', 'Принять', 'Accept');
  String get reject => _('Rad etish', 'Отклонить', 'Decline');
  String get startRide =>
      _('Safarni boshlash', 'Начать поездку', 'Start the trip');
  // ===== Xaritada «mening joyim» =====
  /// «Qancha qoldi» — marshrutning oldinda qolgan qismi.
  ///
  /// ⚠️ Bu MIJOZDA hisoblanadi: serverning `eta` endpointi har doim 0
  /// qaytaradi (izohi `remainingOnRoute` da).
  String get routeLeft => _('Qoldi', 'Осталось', 'Remaining');

  /// ═══ MASHINA NUQTASI TIRIKMI ═══
  ///
  /// 🔴 NEGA (17.09.2026): xaritadagi mashina nuqtasi ping to'xtasa
  /// JOYIDA QOTIB QOLADI va jonli nuqtadan farq qilmaydi. Ya'ni
  /// xarita jim turib yolg'on gapiradi. Saytda bu qator allaqachon
  /// bor edi (`TripLive`), ilovada esa yo'q edi — matn ATAYIN bir xil.
  String locationUpdatedAgo(int minutes) => _(
    'Yangilandi: $minutes daqiqa oldin',
    'Обновлено: $minutes мин назад',
    'Updated $minutes min ago',
  );

  /// Eskirgan ping — SABABI bilan.
  String locationStale(int minutes) => _(
    "Ma'lumot $minutes daqiqa oldingi — haydovchi aloqadan chiqqan bo'lishi mumkin",
    'Данные $minutes мин назад — водитель мог потерять связь',
    'Data is $minutes min old — the driver may have lost connection',
  );

  /// Nuqta umuman yo'q.
  ///
  /// ⚠️ «Hali yubormagan» DEB AYTILMAYDI: server oxirgi pingni
  /// cheklangan vaqt saqlaydi (~40 daqiqa) va undan keyin
  /// `404 driver location not available or offline` qaytaradi — ya'ni
  /// nuqta yo'qligi «yubormadi» degani ham, «aloqadan chiqdi» degani
  /// ham bo'lishi mumkin. Matn ikkalasini ham qamraydi.
  String get locationUnavailable => _(
    "Mashina joyi hozir ko'rinmayapti — haydovchi ilovada bo'lsa qayta paydo bo'ladi",
    'Местоположение сейчас недоступно — появится, когда водитель будет в приложении',
    'The location is unavailable right now — it returns when the driver is in the app',
  );

  /// Hozirgina kelgan ping — raqamsiz, chunki «0 daqiqa oldin» g'alati.
  String get locationJustNow =>
      _('Yangilandi: hozirgina', 'Обновлено: только что', 'Updated just now');

  // ===== Xaritada «mening joyim» (tugma) =====
  // ⚠️ `myLocation` va `locationDenied` ALLAQACHON bor (xaritadan joy
  // tanlash ekranida) — takrorlamaymiz, o'shalar ishlatiladi.
  String get myLocationStop =>
      _('Kuzatishni to\'xtatish', 'Перестать следить', 'Stop following');

  // ===== Joylashuv yuborish (oldingi plan xizmati) =====
  /// Tizim panelidagi DOIMIY bildirishnoma — safar davomida joylashuv
  /// yuborilayotganini odam KO'RIB turishi shart, yashirib bo'lmaydi.
  ///
  /// ⚠️ Bu matnni Android o'zi chizadi, ilova ichida ko'rinmaydi —
  /// shuning uchun u qisqa va o'z-o'zini tushuntiradigan bo'lishi kerak:
  /// odam bildirishnomani ilovani ochmasdan o'qiydi.
  String get livePingTitle =>
      _('Safar davom etmoqda', 'Поездка продолжается', 'Trip in progress');
  String get livePingBody => _(
    "Yo'lovchilar sizni xaritada ko'rib turishadi",
    'Пассажиры видят вас на карте',
    'Your passengers can see you on the map',
  );

  /// Bildirishnoma kanalining tizim sozlamalaridagi nomi.
  String get livePingChannel =>
      _('Safar joylashuvi', 'Местоположение в поездке', 'Trip location');

  // ===== «Yo'lda» rejimi (haydovchi) =====
  String get drivingMode =>
      _('Yo\'lda rejimi', 'Режим «в пути»', 'Driving mode');
  String get drivingModeTo => _('Manzil', 'Пункт назначения', 'Destination');
  String get drivingModeNavigate =>
      _('Yo\'lni ko\'rsatish', 'Показать маршрут', 'Show route');
  String get drivingModeCall =>
      _('Yo\'lovchiga qo\'ng\'iroq', 'Позвонить пассажиру', 'Call passenger');

  String get completeRide =>
      _('Safarni yakunlash', 'Завершить поездку', 'Finish the trip');
  String get cancelRide =>
      _('Safarni bekor qilish', 'Отменить поездку', 'Cancel the trip');
  String get cancelRideConfirm => _(
    'Safar bekor qilinsinmi? Bron qilganlarga xabar boradi.',
    'Отменить поездку? Забронировавшим придёт уведомление.',
    'Cancel this trip? Everyone who booked will be notified.',
  );
  String get noShow =>
      _('Kelmadi deb belgilash', 'Отметить неявку', 'Mark as a no-show');
  String get offeredPriceLabel =>
      _('Taklif qilingan narx', 'Предложенная цена', 'Offered price');
  String get done => _('Bajarildi', 'Готово', 'Done');

  // Chat va bildirishnomalar
  String get chatsTitle => _('Suhbatlar', 'Чаты', 'Chats');

  /// Ismi noma'lum suhbatdosh.
  ///
  /// 🔴 Ilgari bu o'rinda `driver` ("Haydovchi") turardi — ya'ni haydovchi
  /// o'z YO'LOVCHISINI ham "Haydovchi" deb ko'rardi. Rolga bog'liq bo'lmagan
  /// so'z kerak.
  String get chatPartner => _('Suhbatdosh', 'Собеседник', 'Chat partner');
  String get noChats => _('Suhbatlar yo\'q', 'Чатов нет', 'No chats');
  String get noChatsHint => _(
    'Suhbat bron tasdiqlangandan keyin ochiladi',
    'Чат открывается после подтверждения брони',
    'The chat opens once a booking is confirmed',
  );
  String get noMessages => _('Xabarlar yo\'q', 'Сообщений нет', 'No messages');
  String get noMessagesHint =>
      _('Birinchi bo\'lib yozing', 'Напишите первым', 'Be the first to write');
  String get messageHint =>
      _('Xabar yozing...', 'Напишите сообщение...', 'Write a message...');

  /// 🔴 2026-08-25 dan boshlab ISHLATILMAYDI: internetsiz yozilgan xabar
  /// endi rad etilmaydi, offline navbatga tushadi (`core/outbox.dart`).
  /// Matn o'chirilmadi — tarjimalar tayyor turadi, funksiya qaytsa kerak
  /// bo'ladi. Uning o'rniga [messageQueued] ko'rsatiladi.
  String get chatOffline => _(
    'Aloqa yo\'q — xabar yuborilmadi, biroz kuting',
    'Нет связи — сообщение не отправлено, подождите',
    'No connection — the message was not sent, please wait a moment',
  );
  String get notificationsTitle =>
      _('Bildirishnomalar', 'Уведомления', 'Notifications');
  String get noNotifications =>
      _('Bildirishnoma yo\'q', 'Уведомлений нет', 'No notifications');

  /// Telefonda bildirishnomalar o'chirilgan — bu ilovaning aybi emas, lekin
  /// ochiq aytilmasa odam aynan ilovani ayblaydi.
  String get pushDisabledTitle => _(
    'Bildirishnomalar o\'chirilgan',
    'Уведомления отключены',
    'Notifications are turned off',
  );
  String get pushDisabledBody => _(
    'Safaringizga ariza kelganini yoki haydovchi javobini o\'z vaqtida bilmaysiz.',
    'Вы не узнаете вовремя о заявке на поездку и об ответе водителя.',
    'You will not find out in time about a trip request or a driver\'s reply.',
  );
  String get pushEnable => _('Yoqish', 'Включить', 'Turn on');
  String get pushOpenSettingsHint => _(
    'Sozlamalar → Ilovalar → YolYolakay → Bildirishnomalar',
    'Настройки → Приложения → YolYolakay → Уведомления',
    'Settings → Apps → YolYolakay → Notifications',
  );

  // Profil
  String get profileTitle => _('Profil', 'Профиль', 'Profile');
  String get language => _('Til', 'Язык', 'Language');
  String get theme => _('Ko\'rinish', 'Оформление', 'Appearance');
  String get themeSystem => _('Tizim', 'Система', 'System');
  String get themeLight => _('Yorug\'', 'Светлая', 'Light');
  String get themeDark => _('Tungi', 'Тёмная', 'Dark');
  String get logout => _('Chiqish', 'Выход', 'Log out');
  String get logoutConfirm => _(
    'Hisobdan chiqasizmi?',
    'Выйти из аккаунта?',
    'Sign out of your account?',
  );
  String get notVerified =>
      _('Tasdiqlanmagan', 'Не подтверждён', 'Not verified');
  String get becomeDriver =>
      _('Haydovchi bo\'lish', 'Стать водителем', 'Become a driver');
  String get myCars => _('Mashinalarim', 'Мои машины', 'My cars');
  String get noCars =>
      _('Mashina qo\'shilmagan', 'Машины не добавлены', 'No cars added');
  String get moderationPending =>
      _('Moderatsiyada', 'На модерации', 'Under review');

  /// Mashina tekshiruvdan o'tgan.
  ///
  /// 🔴 NEGA MATN KERAK (2026-09-02 ko'rigi): ro'yxatda tasdiqlangan
  /// mashina yonida faqat pushti GALOCHKA turardi, tasdiqlanmaganida esa
  /// yozuvli nishon. Ikki xil til: galochka nima degani — «tekshiruvdan
  /// o'tgan»mi yoki «asosiy mashina»mi? Ekran o'quvchisi esa uni umuman
  /// o'qimasdi (yorlig'i yo'q edi).
  String get moderationApproved => _('Tekshirilgan', 'Проверена', 'Verified');
  String get returnTrip =>
      _('Qaytish safari', 'Обратная поездка', 'Return trip');
  String get returnTripQuestion => _(
    'Qaytish safarini ham e\'lon qilasizmi?',
    'Опубликовать и обратную поездку?',
    'Publish the return trip as well?',
  );
  String get returnTripHint => _(
    'Yo\'nalish teskari to\'ldiriladi — sizga faqat sana va vaqtni tanlash qoladi.',
    'Маршрут заполнится в обратную сторону — останется выбрать дату и время.',
    'The route is filled in reverse — you only need to pick the date and time.',
  );
  String get later => _('Keyinroq', 'Позже', 'Later');

  String get addCar =>
      _('Mashina qo\'shish', 'Добавить автомобиль', 'Add a car');
  String get carAdded =>
      _('Mashina qo\'shildi', 'Автомобиль добавлен', 'Car added');
  String get carPlateTaken => _(
    'Bu davlat raqami allaqachon ro\'yxatdan o\'tgan',
    'Этот гос. номер уже зарегистрирован',
    'This plate number is already registered',
  );

  /// 🔴 Server nosozligida ATAYIN «bu sizning xatongiz emas» deyiladi
  /// (jonli, 27.08.2026: `cars` jadvalida ustun yetishmasdi). Umumiy
  /// «saqlashda xatolik» odamni suratlarni qayta olishga, formani
  /// qayta to'ldirishga majburlaydi — holbuki u nima qilsa ham o'tmaydi.
  // ===== SURAT MANBASI =====

  /// 🔴 NEGA TANLOV (egasi, 2026-08-27): ilovada FAQAT galereya bor edi.
  /// Ya'ni haydovchi hujjatini suratga olish uchun ilovadan CHIQIB,
  /// kamera ilovasini ochib, surat olib, qaytib kelib, galereyadan
  /// tanlashi kerak edi — va buni YETTI marta takrorlashi kerak
  /// (guvohnoma 2 tomon, texpasport 2 tomon, mashina 3 rakurs).
  // ===== HAYDOVCHI BO'LISH: NEGA DAVOM ETIB BO'LMAYDI =====

  /// 🔴 NEGA KERAK (egasi, qurilmada 2026-08-27: «nega keyingisiga o'tish
  /// yo'q»): «Keyingi» tugmasi bor va u suriladigan qismdan tashqarida —
  /// ya'ni ekrandan chiqib ketmaydi. Lekin surat yuklanmagan bo'lsa u
  /// O'CHIQ turadi va SABABINI aytmaydi. Yuklash xatosi esa snackbar
  /// bo'lib bir lahzada yo'qoladi. Natijada odam «tugma yo'q» deb
  /// o'ylaydi va nima qilishni bilmaydi.
  ///
  /// Endi har qadamda nima yetishmayotgani tugma YONIDA yozib turadi.
  String get stepNeedSelfie => _(
    'Davom etish uchun o\'z suratingizni oling',
    'Чтобы продолжить, сделайте своё фото',
    'To continue, take a photo of yourself',
  );

  String get stepNeedLicense => _(
    'Guvohnomaning IKKALA tomonini yuklang — orqasidagi toifalar ham kerak',
    'Загрузите ОБЕ стороны удостоверения — категории с оборота тоже нужны',
    'Upload BOTH sides of the licence — the categories on the back are needed too',
  );

  String get stepNeedTech => _(
    'Texnik pasportning ikkala tomonini yuklang',
    'Загрузите обе стороны техпаспорта',
    'Upload both sides of the vehicle registration',
  );

  String get stepNeedCarPhotos => _(
    'Mashinaning old va orqa suratini yuklang (yon tomon ixtiyoriy)',
    'Загрузите фото автомобиля спереди и сзади (сбоку — необязательно)',
    'Upload the car from the front and the rear (side is optional)',
  );

  String get stepNeedCarDetails => _(
    'Mashina rusumi, modeli va davlat raqamini to\'ldiring',
    'Заполните марку, модель и гос. номер автомобиля',
    'Fill in the car brand, model and plate number',
  );

  /// Ramkada QOLADIGAN xato matni — snackbar yo'qoladi, savol qolib
  /// ketardi («yukladimmi o'zi?»).
  String get photoFailedRetry => _(
    'Yuklanmadi — qayta urinish uchun bosing',
    'Не загрузилось — нажмите, чтобы повторить',
    'Upload failed — tap to try again',
  );

  // ===== OFFLINE SAFAR KARTASI =====

  /// 🔴 NEGA KERAK (egasi, 2026-08-27: «antena chiqmay qolishi»):
  /// shaharlararo yo'lda aloqa uziladi va odam eng kerakli paytda —
  /// uchrashuv nuqtasida — haydovchining raqamini, mashina raqamini,
  /// uchrashuv joyini topolmaydi. Bu zerikish emas, XAVOTIR.
  String get offlineCardTitle =>
      _('Safar kartasi', 'Карточка поездки', 'Trip card');

  /// Eng muhim va'da: bu ekran internetsiz ham ochiladi.
  String get offlineCardWorks => _(
    'Bu ma\'lumot qurilmangizda saqlangan — internetsiz ham ochiladi',
    'Эти данные сохранены на устройстве — откроются и без интернета',
    'This is saved on your device and opens without internet',
  );

  String get offlineCardCar => _('Mashina', 'Автомобиль', 'Car');
  String get offlineCardMeeting =>
      _('Uchrashuv joyi', 'Место встречи', 'Meeting point');

  /// Telefon FAQAT tasdiqlangan bronda ko'rinadi (mavjud qoida).
  String get offlineCardNoPhone => _(
    'Raqam bron tasdiqlangach ko\'rinadi',
    'Номер появится после подтверждения брони',
    'The number appears once the booking is confirmed',
  );

  String offlineCardSaved(String when) => switch (lang) {
    Lang.ru => 'Сохранено: $when',
    Lang.en => 'Saved: $when',
    Lang.uz => 'Saqlangan: $when',
    Lang.uzCyrl => toCyrillic('Saqlangan: $when'),
  };

  // ===== YO'L HAMROHI (zerikish) =====

  /// 🔴 Sarlavha ATAYIN savol shaklida: karta o'zi javob beradi va odam
  /// nima uchun ekanini o'ylab o'tirmaydi.
  String get roadWhereTitle =>
      _('Hozir qayerdan o\'tyapmiz', 'Где мы сейчас', 'Where we are now');

  /// Ovoz bilan o'qish — haydovchi ekranga qaramasligi uchun.
  /// Sozlamadagi yorliq.
  String get readAloudTitle =>
      _('Ovoz bilan o\'qish', 'Читать вслух', 'Read aloud');
  String get readAloudHint => _(
    'Yo\'ldagi kartalar ovoz bilan o\'qiladi — ekranga qaramasdan',
    'Карточки в дороге читаются вслух — не глядя на экран',
    'Road cards are read out loud, so you need not look at the screen',
  );

  String get roadReadAloud => _('Ovoz bilan', 'Вслух', 'Read aloud');

  String get roadStopReading => _('To\'xtatish', 'Остановить', 'Stop');

  // ===== MUSIQA DIDI (safar belgisi) =====

  /// 🔴 IXTIYORIY (egasi, 2026-08-27): belgilanmasa safar kartasida
  /// UMUMAN ko'rsatilmaydi. Majburiy qilish e'lon berishni cho'zadi va
  /// haydovchi «nima desam ekan» deb o'ylab turib qoladi.
  String get musicTasteTitle =>
      _('Yo\'lda musiqa', 'Музыка в дороге', 'Music on the road');

  String get musicTasteHint => _(
    'Ixtiyoriy — yo\'lovchi nima kutishini bilsin',
    'Необязательно — чтобы пассажир знал, чего ожидать',
    'Optional — so passengers know what to expect',
  );

  String get musicQuiet => _('Sokin', 'Тихо', 'Quiet');
  String get musicLoud => _('Musiqa baland', 'Музыка громко', 'Music loud');
  String get musicTalk => _('Suhbatlashamiz', 'Поговорим', 'We chat');
  String get musicAny => _('Farqi yo\'q', 'Без разницы', 'No preference');

  String get photoSourceTitle =>
      _('Surat qanday olinadi?', 'Как добавить фото?', 'How to add a photo?');

  String get photoSourceCamera =>
      _('Kamera bilan olish', 'Снять камерой', 'Take with camera');

  String get photoSourceGallery =>
      _('Galereyadan tanlash', 'Выбрать из галереи', 'Choose from gallery');

  /// Kamera yo'q yoki ruxsat berilmagan qurilmada — jim qolmaymiz.
  String get photoCameraUnavailable => _(
    'Kamera ochilmadi — galereyadan tanlashingiz mumkin',
    'Камера не открылась — можно выбрать из галереи',
    'The camera did not open — you can pick from the gallery',
  );

  /// 🔴 Tugma o'chiq bo'lsa SABABI yozilsin — aks holda odam suratlarni
  /// yuklab bo'lib, nega saqlab bo'lmasligini tushunmaydi.
  String get carNeedBasics => _(
    'Saqlash uchun rusum, model va davlat raqamini to\'ldiring',
    'Для сохранения заполните марку, модель и гос. номер',
    'To save, fill in the brand, model and plate number',
  );

  String get carSaveServerDown => _(
    'Hozir mashina qo\'shib bo\'lmaydi — serverda vaqtincha nosozlik. '
        'Bu sizning xatongiz emas',
    'Сейчас нельзя добавить автомобиль — временный сбой на сервере. '
        'Это не ваша ошибка',
    'Cannot add a car right now — a temporary server problem. '
        'This is not your fault',
  );

  String get carSaveFailed => _(
    'Mashinani saqlashda xatolik',
    'Ошибка сохранения автомобиля',
    'Could not save the car',
  );

  String get techPassport =>
      _('Texpasport surati', 'Фото техпаспорта', 'Vehicle registration photo');
  String get techPassportHint => _(
    'Moderatsiya mashinani shu surat bo\'yicha tasdiqlaydi — raqam va rusum '
        'o\'qilishi kerak. Surat bo\'lmasa tasdiqlash uzoq davom etishi mumkin.',
    'Модерация проверяет автомобиль по этому фото — номер и марка должны '
        'читаться. Без фото проверка может затянуться.',
    'Moderation approves your car from this photo — the plate and make must '
        'be readable. Without a photo the review may take longer.',
  );
  String get photoAdd =>
      _('Suratni yuklash', 'Загрузить фото', 'Upload a photo');
  String get photoUploading => _('Yuklanmoqda...', 'Загрузка...', 'Loading...');
  String get photoFailed => _(
    'Rasmni yuklab bo\'lmadi. Qayta urinib ko\'ring',
    'Не удалось загрузить изображение. Попробуйте ещё раз',
    'Could not upload the image. Please try again',
  );
  String get photoRemove =>
      _('Rasmni olib tashlash', 'Удалить изображение', 'Remove the image');

  String get deleteAccount =>
      _('Hisobni o\'chirish', 'Удалить аккаунт', 'Delete account');
  String get deleteAccountConfirm => _(
    'Hisobingiz o\'chirilsinmi?',
    'Удалить ваш аккаунт?',
    'Delete your account?',
  );
  String get deleteAccountWarning => _(
    'Bu amalni QAYTARIB BO\'LMAYDI. Safarlar tarixi, reyting, sharhlar va '
        'chat xabarlaringiz o\'chiriladi.',
    'Это действие НЕОБРАТИМО. История поездок, рейтинг, отзывы и сообщения '
        'будут удалены.',
    'This action is IRREVERSIBLE. Your trip history, rating, reviews and '
        'chat messages will be deleted.',
  );
  String get deleteAccountDone =>
      _('Hisob o\'chirildi', 'Аккаунт удалён', 'Account deleted');
  String get deleteAccountFailed => _(
    'O\'chirib bo\'lmadi. Birozdan so\'ng qayta urinib ko\'ring.',
    'Не удалось удалить. Попробуйте ещё раз позже.',
    'Could not delete. Please try again later.',
  );
  String get deleteAccountWeb => _(
    'Batafsil: veb-sahifadagi hisobni o\'chirish shartlari',
    'Подробнее: условия удаления аккаунта на сайте',
    'Details: account deletion terms on the website',
  );

  String get tripsActive => _('Faol', 'Активные', 'Active');
  String get tripsFinished => _('Tugagan', 'Завершённые', 'Finished');
  String get noActiveTrips =>
      _('Faol safar yo\'q', 'Нет активных поездок', 'No active trips');

  /// Bron bor, lekin safar detali kelmadi (`GET /rides/{id}` bermadi va bronda
  /// ham safar yo'q). Kartada bo'sh joy qoldirmaymiz — sababini aytamiz.
  String get routeUnavailable => _(
    'Marshrut ma\'lumoti yuklanmadi',
    'Маршрут не загрузился',
    'Route details unavailable',
  );
  String get noFinishedTrips =>
      _('Tugagan safar yo\'q', 'Нет завершённых поездок', 'No finished trips');
  // Parol — SMS'siz kirish (OTP kunlik 5 ta bilan cheklangan)
  String get loginWithPassword =>
      _('Parol bilan kirish', 'Войти по паролю', 'Sign in with a password');
  String get loginWithCode => _(
    'SMS kod bilan kirish',
    'Войти по SMS-коду',
    'Sign in with an SMS code',
  );
  String get passwordLabel => _('Parol', 'Пароль', 'Password');
  String get showPassword =>
      _("Parolni ko'rsatish", 'Показать пароль', 'Show password');
  String get hidePassword =>
      _('Parolni yashirish', 'Скрыть пароль', 'Hide password');
  String get passwordTooShort => _(
    "Parol kamida 6 belgidan iborat bo'lsin",
    'Пароль должен быть не короче 6 символов',
    'The password must be at least 6 characters',
  );
  String get setPassword =>
      _("Parol o'rnatish", 'Установить пароль', 'Set a password');
  String get changePassword =>
      _("Parolni o'zgartirish", 'Изменить пароль', 'Change password');
  String get passwordHint => _(
    "Parol o'rnatsangiz SMS kodsiz ham kira olasiz",
    'С паролем можно входить без SMS-кода',
    'With a password you can sign in without an SMS code',
  );
  String get passwordSaved =>
      _("Parol saqlandi", 'Пароль сохранён', 'Password saved');
  String get passwordRepeat =>
      _('Parolni takrorlang', 'Повторите пароль', 'Repeat the password');
  String get passwordMismatch => _(
    'Parollar mos kelmadi',
    'Пароли не совпадают',
    'The passwords do not match',
  );
  String get avatarUpdated =>
      _('Rasm yangilandi', 'Фото обновлено', 'Photo updated');
  String get nameRequiredForAvatar => _(
    "Avval ism va familiyangizni kiriting",
    'Сначала укажите имя и фамилию',
    'Please enter your first and last name first',
  );

  // Profil guruh sarlavhalari
  String get edit => _('Tahrirlash', 'Изменить', 'Edit');
  String get sectionMyStuff => _('Mening narsalarim', 'Мои данные', 'My stuff');
  String get sectionMyRoads => _('Yo\'llarim', 'Мои поездки', 'My roads');
  String get sectionHelp => _('Yordam', 'Помощь', 'Help');
  String get sectionAccount => _('Hisob', 'Аккаунт', 'Account');
  String get carsCountSuffix => _('ta mashina', 'авто', 'cars');

  String get statRating => _('reyting', 'рейтинг', 'rating');
  String get statReviews => _('sharh', 'отзывов', 'reviews');
  String get statRidesLeft => _('safar qoldi', 'поездок', 'rides left');

  // ===== YO'L XOTIRASI (Wrapped ulashiladigan karta) =====
  String get memoryCardTitle =>
      _('Mening yo\'l xotiram', 'Моя дорожная карта', 'My road card');
  String get memoryShare => _('Ulashish', 'Поделиться', 'Share');

  /// Chatdagi bir bosishlik iboralar.
  ///
  /// Ro'yxat QISQA (4 ta): uzun ro'yxat surishni talab qiladi va "tez"
  /// bo'lmay qoladi. Iboralar ikkala taraf uchun ham mos — haydovchi ham,
  /// yo'lovchi ham shu to'rttasini yozadi.
  List<String> get quickReplies => switch (lang) {
    Lang.uz => _quickRepliesUz,
    Lang.uzCyrl => _quickRepliesUz.map(toCyrillic).toList(),
    Lang.ru => const ['Я в пути', '5 минут', 'Вы где?', 'Я на месте'],
    Lang.en => const ['On my way', '5 minutes', 'Where are you?', "I'm here"],
  };
  String get watchTripIntro => _(
    'Men shu safarga chiqdim:',
    'Я еду этой поездкой:',
    "I'm taking this ride:",
  );
  String get watchTripAction => _(
    'Safarimni yaqinlarimga yuborish',
    'Отправить поездку близким',
    'Send my ride to family',
  );
  String etaApprox(String duration) => _(
    'Taxminan $duration da yetib boradi',
    'Прибытие примерно через $duration',
    'Arriving in about $duration',
  );
  // ===== HAYDOVCHI TEKSHIRUVI (qadamlar) =====

  String stepOf(int current, int total) => _(
    '$current-qadam / $total',
    'Шаг $current из $total',
    'Step $current of $total',
  );
  String get next => _('Keyingisi', 'Далее', 'Next');
  String get back => _('Orqaga', 'Назад', 'Back');
  String get sendForReview =>
      _('Tekshiruvga yuborish', 'Отправить на проверку', 'Send for review');
  String get reviewTitle => _(
    'Yuborishdan oldin tekshiring',
    'Проверьте перед отправкой',
    'Check before sending',
  );
  String get carDetails =>
      _('Mashina ma\'lumotlari', 'Данные автомобиля', 'Car details');
  String get carPlate => _('Davlat raqami', 'Гос. номер', 'Plate number');

  String get docPassport => _('Pasport', 'Паспорт', 'Passport');
  String get docIdCard => _('ID karta', 'ID-карта', 'ID card');

  String get docPassportTitle => _(
    'Pasportning ma\'lumot sahifasi',
    'Страница паспорта с данными',
    'Passport data page',
  );
  String get docIdCardTitle => _(
    'ID kartaning old tomoni',
    'Лицевая сторона ID-карты',
    'Front side of the ID card',
  );
  String get docLicenseTitle => _(
    'Haydovchilik guvohnomasi',
    'Водительское удостоверение',
    "Driver's licence",
  );
  String get docTechPassportTitle =>
      _('Texnik pasport', 'Технический паспорт', 'Vehicle registration');

  /// Talablar — YUKLASHDAN OLDIN. Rad etishlarning aksariyati shu uch
  /// sababdan: xira surat, kesilgan burchak, aks etgan yorug'lik.
  List<String> get docPassportHints => switch (lang) {
    Lang.uz => _docPassportHintsUz,
    Lang.uzCyrl => _docPassportHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Снимите страницу с фотографией и данными',
      'Все четыре угла должны попасть в кадр',
      'Текст должен читаться — без размытия',
      'Без бликов и теней',
    ],
    Lang.en => const [
      'Photograph the page with your photo and details',
      'All four corners must be in the frame',
      'Text must be readable — not blurry',
      'No glare or shadows',
    ],
  };

  List<String> get docIdCardHints => switch (lang) {
    Lang.uz => _docIdCardHintsUz,
    Lang.uzCyrl => _docIdCardHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Снимите сторону с фотографией',
      'Все четыре угла должны попасть в кадр',
      'Номера должны быть чётко видны',
      'Без бликов',
    ],
    Lang.en => const [
      'Photograph the side with your photo',
      'All four corners must be in the frame',
      'The numbers must be clearly visible',
      'No glare',
    ],
  };

  List<String> get docLicenseHints => switch (lang) {
    Lang.uz => _docLicenseHintsUz,
    Lang.uzCyrl => _docLicenseHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Снимите лицевую сторону удостоверения',
      'Категория и срок действия должны быть видны',
      'Текст должен читаться',
      'Срок действия не должен быть истёкшим',
    ],
    Lang.en => const [
      'Photograph the front of the licence',
      'Category and expiry date must be visible',
      'Text must be readable',
      'The licence must not be expired',
    ],
  };

  List<String> get docTechPassportHints => switch (lang) {
    Lang.uz => _docTechPassportHintsUz,
    Lang.uzCyrl => _docTechPassportHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Снимите сторону с данными владельца и автомобиля',
      'Гос. номер должен быть чётко виден',
      'Все четыре угла должны попасть в кадр',
      'Текст не должен быть размытым',
    ],
    Lang.en => const [
      'Photograph the side with owner and vehicle details',
      'The plate number must be clearly visible',
      'All four corners must be in the frame',
      'Text must not be blurry',
    ],
  };

  // ── HUJJATNING IKKI TOMONI (2026-08-27) ────────────────────────────
  // Backend `.com` da `*_front` / `*_back` maydonlari paydo bo'ldi.
  // 🔴 NEGA ORQA TOMON KERAK: guvohnomaning orqasida TOIFALAR (B, C, D)
  // yozilgan — ya'ni odam yo'lovchi tashishga haqlimi yoki yo'qmi aynan
  // o'sha tomonda ko'rinadi. Texpasportning orqasida esa egalik va
  // ishonchnoma yozuvlari bo'ladi. Bir tomonli surat bilan moderatsiya
  // hech qachon ishonch hosil qila olmasdi.

  String get docFrontSide => _('Old tomoni', 'Лицевая сторона', 'Front side');
  String get docBackSide => _('Orqa tomoni', 'Оборотная сторона', 'Back side');

  String get docLicenseBackTitle => _(
    'Guvohnomaning orqa tomoni',
    'Оборотная сторона удостоверения',
    'Back of the licence',
  );
  List<String> get docLicenseBackHints => switch (lang) {
    Lang.uz => _docLicenseBackHintsUz,
    Lang.uzCyrl => _docLicenseBackHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Таблица категорий (B, C, D) должна быть видна полностью',
      'Срок по каждой категории должен читаться',
      'Все четыре угла должны попасть в кадр',
      'Без бликов',
    ],
    Lang.en => const [
      'The category table (B, C, D) must be fully visible',
      'The expiry for each category must be readable',
      'All four corners must be in the frame',
      'No glare',
    ],
  };

  String get docTechPassportBackTitle => _(
    'Texnik pasportning orqa tomoni',
    'Оборотная сторона техпаспорта',
    'Back of the vehicle registration',
  );
  List<String> get docTechPassportBackHints => switch (lang) {
    Lang.uz => _docTechPassportBackHintsUz,
    Lang.uzCyrl => _docTechPassportBackHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Записи о владельце и доверенности должны быть видны',
      'Печати не должны быть обрезаны',
      'Все четыре угла должны попасть в кадр',
      'Текст не должен быть размытым',
    ],
    Lang.en => const [
      'Ownership and proxy entries must be visible',
      'Stamps must not be cut off',
      'All four corners must be in the frame',
      'Text must not be blurry',
    ],
  };

  // ── MASHINA UCH RAKURSDA (2026-08-27) ──────────────────────────────
  // 🔴 NEGA UCHTA: yo'lovchi uchrashuv joyida mashinani TANIY olishi
  // kerak, moderatsiya esa davlat raqami texpasportdagisi bilan bir
  // xilligini tekshiradi. Bitta kadr ikkala vazifaga ham yetmaydi.

  String get docCarPhotos =>
      _('Mashina suratlari', 'Фотографии автомобиля', 'Car photos');
  String get docCarFrontTitle => _('Old tomondan', 'Спереди', 'Front view');
  String get docCarBackTitle => _('Orqa tomondan', 'Сзади', 'Rear view');
  String get docCarSideTitle => _('Yon tomondan', 'Сбоку', 'Side view');

  /// Odamning O'Z surati — pasport/ID o'rniga (egasi, 2026-08-28).
  String get docSelfieTitle =>
      _('Sizning suratingiz', 'Ваше фото', 'Your photo');

  /// Suratlar AYNI PAYTDA olinishini bir marta aytamiz — har hujjatda
  /// takrorlansa qo'llanma o'qilmay qoladi.
  String get docLiveOnlyNote => _(
    'Suratlar shu yerda, ayni paytda olinadi — galereyadan tanlab bo\'lmaydi',
    'Фото делаются здесь и сейчас — выбрать из галереи нельзя',
    'Photos are taken here and now — you cannot pick from the gallery',
  );

  List<String> get docCarFrontHints => switch (lang) {
    Lang.uz => _docCarFrontHintsUz,
    Lang.uzCyrl => _docCarFrontHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Автомобиль должен полностью помещаться в кадр',
      'Передний гос. номер должен читаться',
      'Снимайте днём, при хорошем освещении',
    ],
    Lang.en => const [
      'The whole car must fit in the frame',
      'The front plate must be readable',
      'Shoot in daylight, with good lighting',
    ],
  };
  List<String> get docCarBackHints => switch (lang) {
    Lang.uz => _docCarBackHintsUz,
    Lang.uzCyrl => _docCarBackHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Задний гос. номер должен чётко читаться',
      'Крышка багажника должна быть видна полностью',
      'Другие машины не должны перекрывать обзор',
    ],
    Lang.en => const [
      'The rear plate must be clearly readable',
      'The boot lid must be fully visible',
      'Other cars must not block the view',
    ],
  };
  List<String> get docCarSideHints => switch (lang) {
    Lang.uz => _docCarSideHintsUz,
    Lang.uzCyrl => _docCarSideHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Должна быть видна вся боковая сторона',
      'Все четыре двери должны попасть в кадр',
      'Цвет должен быть передан достоверно',
    ],
    Lang.en => const [
      'The entire side of the car must be visible',
      'All four doors must be in the frame',
      'The colour must look true to life',
    ],
  };

  List<String> get docSelfieHints => switch (lang) {
    Lang.uz => _docSelfieHintsUz,
    Lang.uzCyrl => _docSelfieHintsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Лицо должно быть полностью видно — без головного убора и очков',
      'Встаньте при хорошем свете, источник света не должен быть сзади',
      'Это фото будет в вашем профиле — пассажир вас узнает',
    ],
    Lang.en => const [
      'Your face must be fully visible — no hat or sunglasses',
      'Stand in good light; do not have the light source behind you',
      'This photo appears in your profile — passengers will recognise you',
    ],
  };

  // ── SHAXSNI TASDIQLASH HOLATI (2026-08-27) ─────────────────────────
  // 🔴 `kyc_status` backendda anchadan beri bor edi, lekin ikkala mijoz
  // ham uni UMUMAN o'qimasdi: odam hujjatlarini yuborardi va keyin hech
  // qanday javob ko'rmasdi. Mashinaning holati ko'rsatilardi, odamniki —
  // yo'q. Bu "yubordimmi o'zi?" degan savolni tug'dirardi va qo'llab-
  // quvvatlashga tushadigan murojaatlarning bir qismi shundan edi.

  String get kycTitle => _(
    'Shaxsni tasdiqlash',
    'Подтверждение личности',
    'Identity verification',
  );

  String get kycPending => _(
    'Hujjatlaringiz tekshirilmoqda',
    'Ваши документы на проверке',
    'Your documents are under review',
  );
  String get kycPendingHint => _(
    'Odatda bir ish kuni ichida javob beramiz. Tayyor bo\'lgach xabar qilamiz.',
    'Обычно отвечаем в течение одного рабочего дня. Сообщим, как будет готово.',
    'We usually reply within one business day. We will let you know.',
  );

  String get kycApproved =>
      _('Shaxsingiz tasdiqlandi', 'Личность подтверждена', 'Identity verified');
  String get kycApprovedHint => _(
    'Yo\'lovchilar buni profilingizda ko\'radi.',
    'Пассажиры видят это в вашем профиле.',
    'Passengers can see this on your profile.',
  );

  String get kycRejected => _(
    'Hujjatlar qabul qilinmadi',
    'Документы не приняты',
    'Documents were not accepted',
  );
  String get kycRejectedHint => _(
    'Ko\'pincha sabab — xira surat yoki kesilgan burchak. Qaytadan yuborsangiz bo\'ladi.',
    'Чаще всего причина — размытое фото или обрезанный угол. Можно отправить заново.',
    'Usually the reason is a blurry photo or a cut-off corner. You can submit again.',
  );

  /// Modarator SABAB yozgan bo'lsa — taxmin qilmaymiz, uni ko'rsatamiz.
  String get kycRejectedFix => _(
    'Qaytadan yuborishdan oldin quyidagini tuzating:',
    'Перед повторной отправкой исправьте следующее:',
    'Fix the following before submitting again:',
  );
  String get kycRetry =>
      _('Qaytadan yuborish', 'Отправить заново', 'Submit again');

  /// Paket tugagan: e'lon YO'QOLMAGANINI aytish shart, aks holda odam
  /// uni qaytadan yozadi.
  String get quotaExhaustedPublished => _(
    'Paketingizdagi e\'lonlar tugadi. E\'lon saqlandi, lekin tarif '
        'yangilanmaguncha qidiruvda ko\'rinmaydi.',
    'Объявления в вашем пакете закончились. Объявление сохранено, но не '
        'появится в поиске, пока вы не продлите тариф.',
    'You have no listings left in your plan. The listing is saved but will '
        'not appear in search until you renew.',
  );

  String get carNotApproved => _(
    'E\'lon saqlandi, lekin hali ko\'rinmaydi: mashinangiz tekshiruvdan '
        'o\'tmagan. Tasdiqlangach uni "Safarlarim" dan faollashtirasiz.',
    'Объявление сохранено, но пока не видно: ваш автомобиль не прошёл '
        'проверку. После подтверждения активируйте его в «Мои поездки».',
    'Your listing is saved but not visible yet: your car has not been '
        'approved. Once approved, activate it from "My trips".',
  );

  /// E'lon berishdan OLDINGI ogohlantirish.
  String get carPendingWarning => _(
    'Mashinangiz tekshiruvda. E\'lon berishingiz mumkin, lekin u '
        'tasdiqlangunicha qidiruvda ko\'rinmaydi.',
    'Ваш автомобиль на проверке. Объявление можно создать, но до '
        'подтверждения оно не появится в поиске.',
    'Your car is under review. You can create a listing, but it will not '
        'appear in search until approval.',
  );

  String get uploadPhoto =>
      _('Suratni yuklash', 'Загрузить фото', 'Upload photo');
  String get replacePhoto => _('Almashtirish', 'Заменить', 'Replace');
  String get photoUploaded =>
      _('Surat yuklandi', 'Фото загружено', 'Photo uploaded');
  String get optionalLabel => _('ixtiyoriy', 'необязательно', 'optional');

  /// O'rindiq sxemasidagi ekran o'quvchisi yorliqlari.
  ///
  /// Ikonkaning O'ZIDA yozuv yo'q — bularsiz TalkBack faqat "tugma"
  /// deydi va sxema ko'zi ojiz odam uchun butunlay yopiq qoladi.
  String seatNumberFree(int number) => switch (lang) {
    Lang.ru => '$number-е место, свободно',
    Lang.en => 'Seat $number, free',
    Lang.uz => '$number-o\'rindiq, bo\'sh',
    Lang.uzCyrl => toCyrillic('$number-o\'rindiq, bo\'sh'),
  };

  String seatNumberTaken(int number) => switch (lang) {
    Lang.ru => '$number-е место, занято',
    Lang.en => 'Seat $number, taken',
    Lang.uz => '$number-o\'rindiq, band',
    Lang.uzCyrl => toCyrillic('$number-o\'rindiq, band'),
  };

  // ===== SAFAR PASPORTI (ulashiladigan karta) =====
  String get tripPassportTitle =>
      _('Safar pasporti', 'Паспорт поездки', 'Trip passport');
  String get tripPassportDistance => _('masofa', 'расстояние', 'distance');
  String get tripPassportTime => _('yo\'lda', 'в пути', 'on the road');
  String get tripPassportShare =>
      _('Safarni ulashish', 'Поделиться поездкой', 'Share the trip');
  String get tripPassportTagline => _(
    'Yo\'l-yo\'lakay hamroh topdim',
    'Нашёл попутчика по пути',
    'Found a travel companion along the way',
  );

  // ===== YO'LOVCHI ISHONCHI (haydovchi ekranida) =====

  /// 🔴 ATAYIN «shaxsi tasdiqlangan», «tasdiqlangan yo'lovchi» EMAS.
  /// Bizda yo'lovchi uchun alohida tekshiruv oqimi YO'Q — `kyc_status`
  /// haydovchi bo'lish arizasidan keladi. Ya'ni bu nishon aslida
  /// «bu odam hujjatlarini tekshirtirgan» degani. «Tasdiqlangan
  /// yo'lovchi» deb yozsak, mavjud bo'lmagan tekshiruvni va'da qilardik.
  String get passengerVerified =>
      _('Shaxsi tasdiqlangan', 'Личность подтверждена', 'Identity verified');

  /// Ro'yxatdan o'tgan yili — «kim bu odam» degan savolga eng arzon javob.
  /// ⚠️ `memberSince` (yorliq) ALLAQACHON bor — bu boshqa narsa, shuning
  /// uchun nomi ham boshqa.
  String memberSinceYear(int year) => switch (lang) {
    Lang.ru => 'С $year года',
    Lang.en => 'Since $year',
    Lang.uz => '$year-yildan',
    Lang.uzCyrl => toCyrillic('$year-yildan'),
  };

  // ===== SHARHLAR =====

  /// Muallif ismi kelmaganda — sharh baribir ko'rsatiladi, faqat
  /// muallifsiz. Yozilgan gapni ism yo'qligi uchun yashirish noto'g'ri.
  String get reviewAuthorUnknown =>
      _('Foydalanuvchi', 'Пользователь', 'A user');

  /// 🔴 Bo'sh holat AYBLOV emas: yangi haydovchida sharh bo'lmasligi
  /// tabiiy. «Sharhlar yo'q» quruq gap odamni cho'chitadi, shuning uchun
  /// SABABI ham aytiladi.
  String get reviewsEmpty => _(
    'Hali matnli sharh yo\'q — bu odam yangi bo\'lishi mumkin',
    'Пока нет отзывов с текстом — возможно, человек здесь недавно',
    'No written reviews yet — this person may be new here',
  );

  String get reviewsFailed => _(
    'Sharhlar yuklanmadi',
    'Не удалось загрузить отзывы',
    'Could not load the reviews',
  );

  String reviewsMore(int count) => switch (lang) {
    Lang.ru => 'Ещё $count',
    Lang.en => '$count more',
    Lang.uz => 'Yana $count ta',
    Lang.uzCyrl => toCyrillic('Yana $count ta'),
  };

  String get seatsTitle => _('O\'rindiqlar', 'Места', 'Seats');
  String get seatRowFront => _('Oldinda', 'Впереди', 'Front');
  String get seatRowBack => _('Orqada', 'Сзади', 'Back');
  String get seatDriver => _('Haydovchi', 'Водитель', 'Driver');

  /// Ekran o'quvchisi uchun: qator + holat. Raqam ATAYIN yo'q — backend
  /// o'rindiq POZITSIYASINI saqlamaydi, ya'ni "2-o'rindiq" degan gap
  /// hech narsaga bog'lanmagan raqam edi.
  String seatFreeIn(String row) => switch (lang) {
    Lang.ru => '$row: свободно',
    Lang.en => '$row: free',
    Lang.uz => '$row: bo\'sh',
    Lang.uzCyrl => toCyrillic('$row: bo\'sh'),
  };
  String seatTakenIn(String row) => switch (lang) {
    Lang.ru => '$row: занято',
    Lang.en => '$row: taken',
    Lang.uz => '$row: band',
    Lang.uzCyrl => toCyrillic('$row: band'),
  };
  String seatsFreeOfTotal(int free, int total) => _(
    '$total tadan $free tasi bo\'sh',
    '$free из $total свободно',
    '$free of $total free',
  );
  String get newLabel => _('YANGI', 'НОВОЕ', 'NEW');
  String get whatsNewTitle => _('Nima yangilandi', 'Что нового', "What's new");

  /// Joriy versiyadagi o'zgarishlar — ODAM TILIDA.
  ///
  /// ⚠️ Bu texnik changelog EMAS: "reply_to_id qo'shildi" degan qator
  /// foydalanuvchiga hech nima aytmaydi. Har versiyada QAYTA yoziladi.
  /// ⚠️ HAR RELIZDA YANGILANADI. Ro'yxat versiyaga bog'liq: `Env.appVersion`
  /// o'zgarsa oyna qaytadan chiqadi, lekin matn eski qolsa odam allaqachon
  /// ko'rgan narsasini "yangilik" deb o'qiydi.
  /// 🔴 HAR RELIZDA QAYTA YOZILADI. Ro'yxat versiyaga bog'liq
  /// (`Env.appVersion`): matn eski qolsa odam allaqachon ko'rgan
  /// narsasini "yangilik" deb o'qiydi.
  ///
  /// ⚠️ Bu texnik changelog EMAS — "car_side_photo qo'shildi" degan qator
  /// foydalanuvchiga hech nima aytmaydi. Faqat u SEZADIGAN o'zgarish.
  ///
  /// 1023: haydovchi bo'lish oqimi. 1022 texnik reliz edi (domen
  /// ko'chishi) va ro'yxati atayin bo'sh turgan.
  List<String> get whatsNewItems => switch (lang) {
    Lang.uz => _whatsNewItemsUz,
    Lang.uzCyrl => _whatsNewItemsUz.map(toCyrillic).toList(),
    Lang.ru => const [
      'Главный экран теперь КАРТА: двигайте, приближайте и выбирайте '
          'города прямо на ней',
      'На карте видно ваше местоположение — точка едет вместе с вами',
      'Во время поездки машина движется по карте ПЛАВНО, и указано, '
          'когда данные обновлялись',
      'Водитель может принять бронь ПРЯМО ИЗ уведомления — не открывая '
          'приложение',
      'Поиск адреса больше не обрывается: если один источник недоступен, '
          'отвечает второй',
    ],
    Lang.en => const [
      'The home screen is now a MAP: pan it, zoom it and tap a city to '
          'search for rides',
      'Your own location shows on the map — the dot moves with you',
      'During a ride the car now moves SMOOTHLY on the map, and you can '
          'see when the data was last updated',
      'Drivers can accept a booking RIGHT FROM the notification, without '
          'opening the app',
      'Address search no longer breaks: if one source is down, the other '
          'answers',
    ],
  };

  String seatsLeft(int count) => switch (lang) {
    Lang.uz => count == 1 ? 'Oxirgi joy' : '$count joy qoldi',
    Lang.uzCyrl => toCyrillic(count == 1 ? 'Oxirgi joy' : '$count joy qoldi'),
    Lang.ru => count == 1 ? 'Последнее место' : 'Осталось $count места',
    Lang.en => count == 1 ? 'Last seat' : '$count seats left',
  };
  String get searchInChat =>
      _('Yozishmadan qidirish', 'Поиск по переписке', 'Search in chat');
  String get nothingFound =>
      _('Hech nima topilmadi', 'Ничего не найдено', 'Nothing found');
  String get reminderBeforeTitle =>
      _('Safaringiz yaqinlashdi', 'Скоро ваша поездка', 'Your ride is soon');
  String get reminderBeforeBody =>
      _('1 soat qoldi', 'остался 1 час', '1 hour left');
  String get reminderRateTitle =>
      _('Safar qanday o\'tdi?', 'Как прошла поездка?', 'How was the ride?');
  String get reminderRateBody =>
      _('Haydovchini baholang', 'Оцените водителя', 'Rate the driver');
  String get addToCalendar =>
      _('Kalendarga qo\'shish', 'Добавить в календарь', 'Add to calendar');
  String get openInMaps =>
      _('Navigatorda ochish', 'Открыть в навигаторе', 'Open in maps');
  String get mapsNotOpened => _(
    'Xarita ilovasi topilmadi',
    'Приложение карт не найдено',
    'No maps app found',
  );
  String awayFromYou(String distance) =>
      _('Sizdan $distance', 'От вас $distance', '$distance from you');
  String get pickupTitle => _('Kutib olish', 'Как вас встретят', 'Pickup');
  String get repeatRide => _(
    'Ertaga ham shunday e\'lon',
    'Такое же объявление на завтра',
    'Same listing for tomorrow',
  );
  String get publishReturnRide => _(
    'Qaytish safarini e\'lon qilish',
    'Опубликовать обратную поездку',
    'Publish the return ride',
  );
  String get noMapPoints => _(
    'Bu safarlarning joylashuvi ko\'rsatilmagan',
    'У этих поездок нет координат',
    'These rides have no coordinates',
  );
  String get viewList => _('Ro\'yxat', 'Список', 'List');
  String get viewMap => _('Xarita', 'Карта', 'Map');
  String get ridesOnOtherDays => _(
    'Boshqa kunlarda safar bor',
    'В другие дни поездки есть',
    'Rides on other days',
  );
  String get tapDayToSearch => _(
    'Kunni tanlang — qidiruv qayta yugurtiriladi',
    'Выберите день — поиск повторится',
    'Pick a day — the search will re-run',
  );
  String get profileNotFound =>
      _('Profil topilmadi', 'Профиль не найден', 'Profile not found');

  /// «Yo'llarim» xaritasi ostidagi sanoq (16.09.2026).
  ///
  /// 🔑 FAQAT SON: km ham, CO2 ham yozilmaydi — backend ularni
  /// bermaydi va taxminiy raqam yolg'on bo'lardi (`MemoryCard` dagi
  /// qoida bilan bir xil).
  String myRoadsCount(int n) =>
      _('$n ta safar xaritada', 'Поездок на карте: $n', '$n trips on the map');

  String get memberSince =>
      _('Ro\'yxatdan o\'tgan', 'На платформе с', 'Member since');
  String reviewsCount(int count) =>
      _('$count baho', '$count оценок', '$count ratings');
  String get stepRequested => _('So\'rov', 'Заявка', 'Request');
  String get stepConfirmed => _('Tasdiqlandi', 'Подтверждено', 'Confirmed');
  String get stepOnTheWay => _('Yo\'lda', 'В пути', 'On the way');
  String get stepDone => _('Tugadi', 'Завершено', 'Done');
  String get belowAverage =>
      _("O'rtachadan arzon", 'Дешевле среднего', 'Below average');
  String get aboveAverage =>
      _("O'rtachadan qimmat", 'Дороже среднего', 'Above average');
  String averagePrice(String price) =>
      _('o\'rtacha $price', 'в среднем $price', 'avg $price');
  String get markAllRead =>
      _("Hammasini o'qildi", 'Прочитать все', 'Mark all read');
  String get shareRide =>
      _('Safarni ulashish', 'Поделиться поездкой', 'Share ride');
  String get memoryPassenger => _('Yo\'lovchi', 'Пассажир', 'Passenger');
  String get memoryTagline => _(
    'Yo\'l-yo\'lakay — birga qulay',
    'По пути — вместе удобно',
    'Along the way — better together',
  );

  // ===== ISHONCH BELGILARI (profil) =====
  String get trustTitle => _('Ishonch', 'Доверие', 'Trust');
  // 🔴 2026-08-25 dan ISHLATILMAYDI: tarqoq ishonch chiplari o'rniga
  // ishonch NARVONI keldi (`trustLadderTitle` va `trustStep*`). Matnlar
  // o'chirilmadi — chip ko'rinishi qaytsa tarjimalar tayyor turadi.
  String get trustPhone => _('Telefon', 'Телефон', 'Phone');
  String get trustCar => _('Mashina', 'Авто', 'Car');
  String get trustVerified => _('tasdiqlangan', 'подтверждён', 'verified');
  String get trustNot => _('tasdiqlanmagan', 'не подтверждён', 'not verified');

  // Xavfsizlik — SOS
  String get sosTitle =>
      _('Favqulodda yordam', 'Экстренная помощь', 'Emergency help');
  String get sosCall102 => _("102 ga qo'ng'iroq", 'Позвонить 102', 'Call 102');

  // ===== SOS: «men qayerdaman» (16.09.2026) =====
  String get sosWhereAmI => _('Men qayerdaman', 'Где я нахожусь', 'Where I am');
  String get sosLocating => _(
    'Joylashuv aniqlanmoqda...',
    'Определяем местоположение...',
    'Finding your location...',
  );
  String get sosShareLocation =>
      _('Joyni ulashish', 'Отправить место', 'Share my location');

  // Safar holati amallari
  String get activateRide => _(
    "E'lonni faollashtirish",
    'Активировать объявление',
    'Activate the listing',
  );
  String get activateHint => _(
    "Faollashtirilmaguncha safar qidiruvda ko'rinmaydi",
    'Пока не активировано, поездка не видна в поиске',
    'Until activated, the trip is not visible in search',
  );
  String get activated =>
      _('Safar faollashtirildi', 'Поездка активирована', 'Trip activated');
  String get retry2 => _('Qayta urinish', 'Повторить', 'Retry');
  String get cancelReasonLabel =>
      _('Sabab (ixtiyoriy)', 'Причина (необязательно)', 'Reason (optional)');
  String get cancelInProgressWarning => _(
    "Safar allaqachon boshlangan. Yo'lovchilarga xabar beriladi.",
    'Поездка уже началась. Пассажиры будут уведомлены.',
    'The trip has already started. Passengers will be notified.',
  );
  String get alreadyBooked => _(
    'Siz bu safarni bron qilgansiz',
    'Вы уже забронировали эту поездку',
    'You have already booked this trip',
  );
  String get viewMyBooking => _('Bronimni ko\'rish', 'Моя бронь', 'My booking');

  // Tavsiyalar
  String get forYou => _('Siz uchun', 'Для вас', 'For you');
  String get basedOnYourTrips =>
      _('Tarixingiz asosida', 'На основе ваших поездок', 'Based on your trips');
  String get popularRoutes =>
      _("Ommabop yo'nalishlar", 'Популярные направления', 'Popular routes');
  String get newDirections =>
      _("Yangi yo'nalishlar", 'Новые направления', 'Somewhere new');
  String get tripsCountSuffix => _('safar', 'поездок', 'trips');

  // Haydovchi daromadi
  String get earningsTitle => _('Daromadim', 'Мой доход', 'My earnings');
  String get totalEarnings =>
      _('Umumiy daromad', 'Общий доход', 'Total earnings');
  String get totalRides => _('Jami safarlar', 'Всего поездок', 'Total trips');
  String get completedRides => _('Yakunlangan', 'Завершено', 'Completed');
  String get cancelledRides => _('Bekor qilingan', 'Отменено', 'Cancelled');
  String get allTimePeriod =>
      _('Butun ishlash davri uchun', 'За всё время работы', 'For all time');

  /// ⚠️ MATNDA ICHKI ATAMA BO'LMASIN (2026-09-02 ko'rigi).
  ///
  /// Ilgari bu yerda «Backend hozircha … bermaydi» deb yozilgandi va u
  /// ekranda haydovchiga ko'rinardi. Haydovchi «backend» nima ekanini
  /// bilmaydi — bu bizning ichki tilimiz. Cheklovning O'ZI rost, faqat
  /// uni odam tilida aytish kerak.
  String get earningsNote => _(
    "Naqd pul yo'lovchi bilan to'g'ridan-to'g'ri hisob-kitob qilinadi — "
        "bu raqam faqat statistika. Oy yoki hafta bo'yicha bo'linish "
        "hozircha yo'q.",
    'Наличные рассчитываются напрямую с пассажиром — это только '
        'статистика. Разбивки по месяцам и неделям пока нет.',
    'Cash is settled directly with the passenger — this is statistics '
        'only. A monthly or weekly breakdown is not available yet.',
  );

  // Xavfsizlik — qurilmalar va bloklanganlar
  String get securityTitle => _('Xavfsizlik', 'Безопасность', 'Security');
  String get sessionsTitle =>
      _('Kirilgan qurilmalar', 'Устройства с входом', 'Signed-in devices');
  String get noSessions =>
      _("Boshqa qurilma yo'q", 'Других устройств нет', 'No other devices');
  String get thisDevice => _('shu qurilma', 'это устройство', 'this device');

  /// Seans qachon boshlangani — xavfsizlik ekranida IP dan MUHIMROQ.
  String get sessionStarted => _('Kirilgan', 'Вход', 'Signed in');
  String get unknownDevice =>
      _("Noma'lum qurilma", 'Неизвестное устройство', 'Unknown device');
  String get revokeSession => _('Chiqarish', 'Выйти', 'Sign out');
  String get sessionRevoked =>
      _('Qurilma chiqarildi', 'Устройство отключено', 'Device signed out');
  String get unblockDone =>
      _('Blokdan chiqarildi', 'Разблокирован', 'Unblocked');
  // Moderatsiya — shikoyat va bloklash (Google Play talabi)
  String get moreActions =>
      _("Qo'shimcha amallar", 'Дополнительные действия', 'More actions');
  String get reportUser => _('Shikoyat qilish', 'Пожаловаться', 'Report');
  String get blockUser => _('Bloklash', 'Заблокировать', 'Block');
  String get unblockUser => _('Blokdan chiqarish', 'Разблокировать', 'Unblock');

  /// Bekor qilinadigan amaldan keyingi «Qaytarish» tugmasi (snackbar).
  String get undo => _('Qaytarish', 'Вернуть', 'Undo');

  /// Chat sarlavhasida — suhbatdosh yozayotganда.
  String get peerTyping => _('yozmoqda...', 'печатает...', 'typing...');
  String get resend => _('Qayta yuborish', 'Отправить снова', 'Resend');

  /// Offline navbatdagi xabar ustidagi izoh — «yo'qolmadi» degani.
  // ===== «Yetib keldim» =====
  //
  // 🔴 Safar oldidan «Safarimni kuzat» xabari bor edi, ZANJIRNING OXIRI
  // esa yo'q: yetib kelganini hech kim aytmasdi.
  //
  // ⚠️ SMS ISHLATILMAYDI (egasi aniq aytdi), push esa backenddan hali
  // kelmaydi — shuning uchun xabar TAYYORLANADI, avtomatik yuborilmaydi.

  String get arrivalTitle =>
      _('Yetib keldingiz', 'Вы приехали', 'You have arrived');

  String get arrivalHint => _(
    'Sizni kutayotgan odamga xabar bering — bir tegishда.',
    'Сообщите тому, кто вас ждёт — в одно касание.',
    'Let the person waiting for you know — in one tap.',
  );

  String get arrivalSend =>
      _('Xabar yuborish', 'Отправить сообщение', 'Send a message');

  String get arrivalMessage => _(
    'Yetib keldim, hammasi joyida.',
    'Я доехал(а), всё в порядке.',
    'I have arrived, everything is fine.',
  );

  String arrivalMessageAt(String place) => _(
    '$place ga yetib keldim, hammasi joyida.',
    'Я доехал(а) до $place, всё в порядке.',
    'I have arrived in $place, everything is fine.',
  );

  /// Ovozli e'lon tugmasi yonidagi izoh — odam NIMA aytishni bilsin.
  String get voiceRideHint => _(
    'Aytib bering: «Toshkentdan Samarqandga ertaga sakkizda uch joy sakson ming»',
    'Скажите: «из Ташкента в Самарканд завтра в восемь три места восемьдесят тысяч»',
    'Say it: "from Tashkent to Samarkand tomorrow at eight, three seats, eighty thousand"',
  );

  // ===== Do'stni chaqirish =====
  //
  // ⚠️ Mukofot VA'DA QILINMAYDI va hisoblagich YO'Q: backendda taklif
  // tizimi qurilmagan (izohi `InviteCard` da).

  String get inviteTitle =>
      _('Do\'stni chaqirish', 'Пригласить друга', 'Invite a friend');

  String get inviteHeadline => _(
    'Yo\'lda yolg\'iz ketmang',
    'Не езжайте в одиночку',
    'Don\'t travel alone',
  );

  String get inviteSubline => _(
    'Hamroh toping, xarajatni bo\'ling',
    'Найдите попутчика, разделите расходы',
    'Find a companion, share the cost',
  );

  String get inviteShare =>
      _('Kartani ulashish', 'Поделиться карточкой', 'Share the card');

  String get inviteShareText => _(
    'Shaharlararo yo\'lga hamroh topadigan ilova — YolYolakay:',
    'Приложение для поиска попутчиков между городами — YolYolakay:',
    'An app for finding intercity travel companions — YolYolakay:',
  );

  // ===== E'lon plakati =====
  //
  // 🔴 Telegram guruhida kuniga yuzlab bir xil MATN oqib o'tadi — bizning
  // ulashishimiz ham o'sha oqimning bir qatori edi. Rasm to'xtatadi.

  String get sharePoster =>
      _('Plakat bilan ulashish', 'Поделиться постером', 'Share as a poster');

  String get sharePosterHint => _(
    'Telegram guruhida ko\'zga tashlanadi',
    'Заметно в Telegram-группе',
    'Stands out in a Telegram group',
  );

  // ===== Safar oldi ro'yxati =====
  //
  // 🔴 Shaharlararo safarда unutilgan narsa qaytib olib kelinmaydi.

  String get checklistTitle =>
      _('Safar oldi ro\'yxati', 'Список перед поездкой', 'Pre-trip checklist');

  String get checklistHint => _(
    'Bu maslahat — hech narsa to\'silmaydi.',
    'Это подсказка — ничего не блокируется.',
    'This is a hint — nothing is blocked.',
  );

  String get checklistDocuments =>
      _('Hujjat (pasport / ID)', 'Документ (паспорт / ID)', 'ID document');
  String get checklistCash => _('Naqd pul', 'Наличные', 'Cash');
  String get checklistCharger =>
      _('Telefon zaryadlovchisi', 'Зарядка для телефона', 'Phone charger');
  String get checklistMedicine => _(
    'Dori (kerak bo\'lsa)',
    'Лекарства (если нужны)',
    'Medicine (if needed)',
  );
  String get checklistChildSeat => _(
    'Bolalar kursisi (bola bilan)',
    'Детское кресло (с ребёнком)',
    'Child seat (if with a child)',
  );
  String get checklistFuel =>
      _('Yoqilg\'i to\'ldirildi', 'Заправлен', 'Fuelled up');
  String get checklistSpareWheel =>
      _('Zapaska va domkrat', 'Запаска и домкрат', 'Spare wheel and jack');
  String get checklistChange =>
      _('Qaytim uchun maydalik', 'Мелочь на сдачу', 'Small change');

  // ===== Ishonch narvoni =====
  //
  // 🔴 Ishonch dalillari ilovaga TARQOQ edi: reyting bir joyda, baholar
  // soni boshqa joyda, hisob yoshi uchinchi qatorda. Odam faqat reytingga
  // qarardi, reyting esa BITTA baho bilan ham «5.0» bo'lib turadi.

  String get trustLadderTitle => _('Ishonch', 'Доверие', 'Trust');

  String get trustStepPhone => _(
    'Telefon SMS bilan tasdiqlangan',
    'Телефон подтверждён по SMS',
    'Phone confirmed by SMS',
  );

  String get trustStepTenure => _(
    'Hisob bir oydan ortiq',
    'Аккаунту больше месяца',
    'Account older than a month',
  );

  String get trustStepReviews => _(
    'Yetarlicha odam baho bergan',
    'Достаточно оценок от людей',
    'Enough people have rated them',
  );

  String get trustStepRating =>
      _('Bahosi yuqori', 'Высокая оценка', 'High rating');

  String get trustStepCar => _(
    'Mashina tekshiruvdan o\'tgan',
    'Машина проверена',
    'Car has been verified',
  );

  String get trustLadderHint => _(
    'Ro\'yxatda yo\'q bosqich — ma\'lumot yo\'q degani, «yiqilgan» degani emas.',
    'Отсутствующий пункт означает, что данных нет, а не что он не пройден.',
    'A missing step means we have no data for it — not that it failed.',
  );

  // ===== «Yana o'sha haydovchi bilan» =====
  //
  // 🔴 Haydovchi bo'yicha SAFAR QIDIRISH ruchkasi gateway'da YO'Q —
  // shuning uchun matnlar «uning safarlari» deb va'da bermaydi.

  String get pastDriversTitle => _(
    'Yana o\'sha haydovchi bilan',
    'Снова с тем же водителем',
    'With the same driver again',
  );

  String get pastDriverSearchRoute => _(
    'Shu yo\'nalishni qidirish',
    'Искать этот маршрут',
    'Search this route',
  );

  String get pastDriverMessage =>
      _('Haydovchiga yozish', 'Написать водителю', 'Message the driver');

  String get pastDriverMessageHint => _(
    'Masalan: «Ertaga yo\'l bormi?»',
    'Например: «Завтра едете?»',
    'For example: "Are you driving tomorrow?"',
  );

  // ===== Kassa (naqd yig'ish) =====
  //
  // 🔴 Ilovada onlayn to'lov yo'q — pul naqd, yo'lda. Haydovchi kimdan
  // olganini boshida saqlab, adashadi. Belgi faqat shu telefonda.

  String get cashTitle => _('Kassa', 'Касса', 'Cash');

  String cashCollected(String collected, String total) => _(
    'Yig\'ildi: $collected / $total',
    'Собрано: $collected / $total',
    'Collected: $collected / $total',
  );

  String get cashMarkPaid => _('To\'ladi', 'Оплатил', 'Paid');

  String get cashLocalHint => _(
    'To\'lov belgisi faqat shu telefonda saqlanadi.',
    'Отметка об оплате хранится только на этом телефоне.',
    'The payment mark is stored on this phone only.',
  );

  /// Yo'lovchi tomonda — pul QAYERGA va QANDAY beriladi.
  ///
  /// 🔴 Ilovada onlayn to'lov yo'q va bu hech qayerda YOZILMAGAN edi.
  /// Odam «karta biriktirsammikan?» deb o'ylab turardi.
  String get cashToDriver =>
      _('Naqd — haydovchiga', 'Наличными — водителю', 'Cash — to the driver');

  String cashLeft(String amount) =>
      _('Qolgan: $amount', 'Осталось: $amount', 'Remaining: $amount');

  // ===== Xizmat holati =====
  //
  // 🔴 Uzilish bu ilovada ODATIY hol (shaharlararo yo'l + backend uy
  // mashinasida). Javobsiz uzilish ishonchni yo'qotadi, javobli uzilish
  // esa ishonch qozonadi.

  String get serviceStatusTitle =>
      _('Xizmat holati', 'Состояние сервиса', 'Service status');

  String get serviceStatusIntro => _(
    'Nima ishlayotgani va ekrandagi ma\'lumot qanchalik yangiligi. Bu yerda '
        'taxmin yo\'q — hammasi o\'lchangan.',
    'Что работает и насколько свежие данные на экране. Здесь нет догадок — '
        'всё измерено.',
    'What is working and how fresh the data on screen is. No guesswork here '
        '— everything is measured.',
  );

  String get statusInternet => _('Internet', 'Интернет', 'Internet');
  String get statusLive =>
      _('Jonli aloqa', 'Живое соединение', 'Live connection');
  String get statusNotifications =>
      _('Bildirishnomalar', 'Уведомления', 'Notifications');
  String get statusWorking => _('Ishlayapti', 'Работает', 'Working');
  String get statusDown => _('Yo\'q', 'Нет', 'Down');
  String get statusChecking => _('Tekshirilmoqda', 'Проверяется', 'Checking');
  String get statusAllowed => _('Ruxsat berilgan', 'Разрешены', 'Allowed');
  String get statusBlocked => _('O\'chirilgan', 'Отключены', 'Turned off');

  String get statusLastSync => _(
    'Oxirgi muvaffaqiyatli yangilanish',
    'Последнее успешное обновление',
    'Last successful sync',
  );

  String get statusNeverSynced => _(
    'Hali bir marta ham yangilanmagan',
    'Ещё ни разу не обновлялось',
    'Never synced yet',
  );

  String get statusQueue =>
      _('Yuborilmagan ishlar', 'Неотправленные действия', 'Unsent actions');

  String get statusQueueEmpty =>
      _('Navbat bo\'sh', 'Очередь пуста', 'Queue is empty');

  String get statusRetry => _('Urinib ko\'rish', 'Повторить', 'Retry');

  String get appVersionLabel =>
      _('Ilova versiyasi', 'Версия приложения', 'App version');

  String statusDropped(int n) => _(
    '$n ta yozuv juda eskirgani uchun yuborilmadi. Kech yetkazilgan xabar '
        'foyda emas, chalkashlik keltiradi.',
    '$n записей не отправлено — слишком устарели. Сообщение, доставленное '
        'слишком поздно, только запутывает.',
    '$n entries were not sent because they got too old. A message delivered '
        'too late confuses more than it helps.',
  );

  // ===== «Sizsiz nima bo'ldi» =====
  //
  // 🔴 Backend push YUBORMAYDI — odam yo'q paytida hech qanday belgi
  // kelmaydi. Ilova ochilganda o'zgarishni O'ZI aytadi.

  String get awayTitle =>
      _('Siz yo\'q paytingizda', 'Пока вас не было', 'While you were away');

  String awayNewMessages(int n) =>
      _('$n yangi xabar', '$n новых сообщений', '$n new messages');

  String awayNewNotifications(int n) => _(
    '$n yangi bildirishnoma',
    '$n новых уведомлений',
    '$n new notifications',
  );

  // ===== Posilkani YOPISH (jo'natuvchi tomondan) =====
  //
  // 🔴 Posilka `accepted` da abadiy qotib qolardi: «yetkazildi» ni faqat
  // haydovchi yoza olardi va ko'pincha yozmasdi.

  String get parcelMarkDelivered =>
      _('Yetkazildi deb belgilash', 'Отметить доставленной', 'Mark delivered');

  /// ⚠️ «Avval serverga yozishga urinamiz» olib tashlandi (02.09 ko'rigi):
  /// bu bizning ichki ishimiz, odamga savol beriladigan lahzada esa
  /// faqat SAVOL bo'lishi kerak. Natija baribir keyin aytiladi.
  String get parcelMarkDeliveredConfirm => _(
    'Posilka egasiga topshirildimi?',
    'Посылка передана получателю?',
    'Has the parcel been handed over?',
  );

  String get parcelClosedDone =>
      _('Posilka yopildi', 'Посылка закрыта', 'Parcel closed');

  String get parcelMarkedLocally => _(
    'Faqat shu qurilmada belgilandi',
    'Отмечено только на этом устройстве',
    'Marked on this device only',
  );

  /// ⚠️ «Server qabul qilmadi» → «Bu belgini haydovchi qo'yadi»
  /// (02.09 ko'rigi). Birinchisi nosozlikdek eshitiladi, ikkinchisi esa
  /// haqiqiy sababni aytadi: bu amalni yozish huquqi haydovchida.
  String get parcelMarkedLocallyHint => _(
    'Bu belgini haydovchi qo\'yadi. Sizda u faqat shu telefonda '
        'ko\'rinadi — boshqa qurilmada posilka ochiq turadi.',
    'Эту отметку ставит водитель. У вас она видна только на этом '
        'телефоне — на другом устройстве посылка остаётся открытой.',
    'The driver records this mark. On your side it is visible on this '
        'phone only — on another device the parcel stays open.',
  );

  // ===== Bronni bekor qilish SO'ROVI =====
  //
  // ✅ 2026-08-27: yo'lovchi endi bronni HAQIQATAN bekor qiladi
  // (`POST /rides/{id}/bookings/{booking_id}/cancel`). Shu paytgacha
  // matnlar ATAYIN «so'rov» tilida edi, chunki gateway'da bunday ruchka
  // yo'q edi va «bekor qilindi» deb yozish yolg'on bo'lardi. Endi endpoint
  // bor — matnlar ham to'g'ridan-to'g'ri gapiradi.

  String get cancelBooking =>
      _('Bronni bekor qilish', 'Отменить бронь', 'Cancel booking');

  String get cancelBookingTitle =>
      _('Bronni bekor qilasizmi?', 'Отменить бронь?', 'Cancel this booking?');

  String cancelBookingExplain(int seats) => _(
    'Bron bekor qilinadi va $seats o\'rindiq darhol bo\'shaydi. Buni '
        'qaytarib bo\'lmaydi — fikringiz o\'zgarsa qaytadan bron qilasiz, '
        'lekin o\'rindiqni boshqa birov olib qo\'ygan bo\'lishi mumkin.',
    'Бронь будет отменена, и $seats мест(а) сразу освободятся. Это нельзя '
        'вернуть — если передумаете, придётся бронировать заново, но место '
        'может занять кто-то другой.',
    'The booking will be cancelled and $seats seat(s) freed immediately. '
        'This cannot be undone — if you change your mind you can book again, '
        'but someone else may have taken the seat.',
  );

  String get cancelBookingReason =>
      _('Sabab (ixtiyoriy)', 'Причина (необязательно)', 'Reason (optional)');

  String get cancelBookingReasonHint => _(
    'Masalan: rejalarim o\'zgardi',
    'Например: планы изменились',
    'For example: my plans changed',
  );

  /// 🔴 Tugma matni ATAYIN «ha, bekor qil» — «tasdiqlash» EMAS. Varaqda ikki
  /// tugma turadi va «tasdiqlash» qaysi biri ekanini yashiradi.
  String get cancelBookingConfirm =>
      _('Ha, bekor qilinsin', 'Да, отменить', 'Yes, cancel it');

  String get cancelBookingKeep =>
      _('Yo\'q, qolsin', 'Нет, оставить', 'No, keep it');

  String get cancelBookingDone => _(
    'Bron bekor qilindi — o\'rindiq bo\'shadi',
    'Бронь отменена — место освободилось',
    'Booking cancelled — the seat is free',
  );

  /// Aloqa yo'qda berilgan baho — yo'qolmadi, navbatда.
  String get ratingQueued => _(
    'Baho saqlandi — aloqa tiklanganda yuboriladi',
    'Оценка сохранена — отправится, когда появится связь',
    'Rating saved — it will be sent when the connection is back',
  );

  String get messageQueued => _(
    'Navbatda — aloqa tiklanganda o\'zi yuboriladi',
    'В очереди — отправится, когда появится связь',
    'Queued — it will send itself when the connection is back',
  );

  /// Navbatda nechta ish turganini bildiruvchi qator.
  String queuedCount(int n) => _(
    'Navbatda $n ta yuborilmagan ish',
    'В очереди $n неотправленных действий',
    '$n queued actions not sent yet',
  );
  String get copied => _('Nusxa olindi', 'Скопировано', 'Copied');
  String get shareFailed =>
      _("Ulashib bo'lmadi", 'Не удалось поделиться', "Couldn't share");

  /// Nusxa tugmasining izohi — ekran o'quvchi uchun yagona manba.
  String get copy => _('Nusxa olish', 'Скопировать', 'Copy');
  String ridesFound(int n) =>
      _('$n ta safar topildi', 'Найдено поездок: $n', '$n rides found');

  /// Xaritadagi mashhur yo'nalish ustidagi QISQA yozuv (`HomeMap`).
  ///
  /// 🔴 [ridesFound] bu yerga SIG'MASDI: «12 ta safar topildi» uch tilda
  /// ham 66 px joyda kesilib, faqat «12 ta saf…» ko'rinardi. Ruscha
  /// son shakli bilan — «Найдено поездок: N» qolipidan chiqilgani uchun.
  String mapTripCount(int n) => switch (lang) {
    Lang.ru => '$n ${_ruTrips(n)}',
    Lang.en => n == 1 ? '1 ride' : '$n rides',
    Lang.uz => '$n ta safar',
    Lang.uzCyrl => toCyrillic('$n ta safar'),
  };

  static String _ruTrips(int n) {
    final d = n % 10, h = n % 100;
    if (d == 1 && h != 11) return 'поездка';
    if (d >= 2 && d <= 4 && (h < 12 || h > 14)) return 'поездки';
    return 'поездок';
  }

  // Interfeys uslubi (Classic / Neon)
  // ===== Profil to'liqligi =====
  String get completenessTitle =>
      _('Profilingiz', 'Ваш профиль', 'Your profile');
  String get completenessAvatar =>
      _('Surat qo\'shing', 'Добавьте фото', 'Add a photo');

  /// 🔴 SABAB — bandning o'zidan muhimroq: usiz bu shunchaki buyruq.
  String get completenessAvatarWhy => _(
    'Suratli profilga bron osonroq beriladi',
    'С фото заявку принимают охотнее',
    'Requests with a photo get accepted more often',
  );
  String get completenessName =>
      _('Familiyani kiriting', 'Укажите фамилию', 'Add your last name');
  String get completenessNameWhy => _(
    'Hamroh sizni tanishi uchun',
    'Чтобы попутчик вас узнал',
    'So your companion can recognise you',
  );
  String get completenessCar =>
      _('Mashina qo\'shing', 'Добавьте автомобиль', 'Add your car');
  String get completenessCarWhy => _(
    'Mashinasiz e\'lon faollashmaydi',
    'Без автомобиля объявление не активируется',
    'A ride cannot go live without a car',
  );

  String get bigText => _('Kattaroq matn', 'Крупный текст', 'Larger text');
  String get bigTextHint => _(
    'Butun ilovada yozuvlar kattalashadi',
    'Текст во всём приложении станет крупнее',
    'Text gets bigger across the app',
  );

  String get themeStyle => _('Uslub', 'Стиль', 'Style');
  String get themeStyleClassic => _('Klassik', 'Классический', 'Classic');
  String get themeStyleNeon => _('Neon', 'Неон', 'Neon');

  /// TUNGI HAYDASH — issiq amber, doim qorong'i.
  String get themeStyleAmber =>
      _('Tungi haydash', 'Ночная езда', 'Night driving');

  /// Ekran tepasidagi doimiy "internet yo'q" chizig'i.
  /// Ekrandagi ma'lumot KESHDAN — qachon olingani aytiladi.
  String cachedAt(String time) => switch (lang) {
    Lang.ru => 'Последнее обновление: $time',
    Lang.en => 'Last updated: $time',
    Lang.uz => 'Oxirgi yangilanish: $time',
    Lang.uzCyrl => toCyrillic('Oxirgi yangilanish: $time'),
  };

  String get offlineBanner => _(
    'Internet aloqasi yo\'q',
    'Нет подключения к интернету',
    'No internet connection',
  );

  // ===== Birinchi ochilish tanishtiruvi (intro) =====
  String get introSkip => _('O\'tkazib yuborish', 'Пропустить', 'Skip');
  String get introStart => _('Boshlash', 'Начать', 'Get started');
  String get introFindTitle =>
      _('Hamroh toping', 'Найдите попутчика', 'Find a ride');
  String get introFindBody => _(
    'Yo\'nalish va sanani tanlang — yaqin atrofdagi safarlarni ko\'ring va o\'zingizga mosini tanlang.',
    'Выберите маршрут и дату — смотрите поездки рядом и выбирайте подходящую.',
    'Choose a route and date — see nearby rides and pick the one that fits.',
  );
  String get introDriveTitle =>
      _('Haydovchi bo\'ling', 'Станьте водителем', 'Become a driver');
  String get introDriveBody => _(
    'Bo\'sh o\'rindiqlaringizni e\'lon qiling, yo\'lovchi toping va yo\'l xarajatini bo\'ling.',
    'Публикуйте свободные места, находите пассажиров и делите расходы на дорогу.',
    'Post your free seats, find passengers and split the travel costs.',
  );
  String get introSafeTitle =>
      _('Xavfsiz sayohat', 'Безопасная поездка', 'Safe travel');
  String get introSafeBody => _(
    'Baholashlar, favqulodda tugma va ishonchli hamrohlar — har safar xotirjam bo\'ling.',
    'Оценки, кнопка экстренной помощи и проверенные попутчики — спокойствие в каждой поездке.',
    'Ratings, an emergency button and trusted companions — peace of mind every trip.',
  );

  /// Intro 4-sahifa — yangi funksiyalar bir marta aytiladi.
  String get introVoiceTitle =>
      _('Ovoz bilan qidiring', 'Ищите голосом', 'Search by voice');
  String get introVoiceBody => _(
    'Mikrofonni bosib «Toshkentdan Samarqandga» deng. Safar topilmasa — '
        'kuzatuvga qo\'ying, chiqishi bilan xabar beramiz.',
    'Нажмите микрофон и скажите «из Ташкента в Самарканд». Если поездки '
        'нет — подпишитесь, сообщим когда появится.',
    'Tap the microphone and say "from Tashkent to Samarkand". No ride '
        'yet? Watch the route and we will let you know.',
  );

  /// Suhbatlar ro'yxatida oxirgi xabar mening bo'lsa qo'yiladigan prefiks.
  String get youPrefix => _('Siz:', 'Вы:', 'You:');
  String get reasonHarassment =>
      _('Haqorat yoki tahdid', 'Оскорбления или угрозы', 'Abuse or threats');
  String get reasonSpam =>
      _('Spam yoki reklama', 'Спам или реклама', 'Spam or advertising');
  String get reasonFraud => _('Firibgarlik', 'Мошенничество', 'Fraud');
  String get reasonUnsafe =>
      _('Xavfli xatti-harakat', 'Опасное поведение', 'Dangerous behaviour');
  String get reasonOther => _('Boshqa', 'Другое', 'Other');
  String get reportCommentHint => _(
    "Izoh (ixtiyoriy)",
    'Комментарий (необязательно)',
    'Comment (optional)',
  );
  String get reportSent =>
      _('Shikoyat yuborildi', 'Жалоба отправлена', 'Report sent');
  String get blockWarning => _(
    "Bloklangan foydalanuvchi sizga yoza olmaydi va safarlaringizni ko'rmaydi. Buni keyin bekor qilishingiz mumkin.",
    'Заблокированный пользователь не сможет вам писать и не увидит ваши поездки. Это можно отменить позже.',
    'A blocked user cannot message you and will not see your rides. You can undo this later.',
  );
  String get blockDone =>
      _('Foydalanuvchi bloklandi', 'Пользователь заблокирован', 'User blocked');
  String get blockedUsersTitle =>
      _('Bloklanganlar', 'Заблокированные', 'Blocked users');
  String get noBlockedUsers => _(
    "Bloklangan foydalanuvchi yo'q",
    'Нет заблокированных пользователей',
    'No blocked users',
  );
  String get send => _('Yuborish', 'Отправить', 'Send');
  String get settingsTitle => _('Sozlamalar', 'Настройки', 'Settings');
  String get editProfile =>
      _('Profilni tahrirlash', 'Редактировать профиль', 'Edit profile');
  String get profileSaved =>
      _('Profil saqlandi', 'Профиль сохранён', 'Profile saved');
  String get support =>
      _('Yordam va aloqa', 'Помощь и связь', 'Help & contact');
  String get privacyPolicy =>
      _('Maxfiylik siyosati', 'Политика конфиденциальности', 'Privacy policy');
  String get termsOfUse =>
      _('Foydalanish shartlari', 'Условия использования', 'Terms of use');
  String get linkOpenFailed => _(
    'Havolani ochib bo\'lmadi',
    'Не удалось открыть ссылку',
    'Could not open the link',
  );

  /// CHATDA JOY ULASHISH (16.09.2026) — izohi `core/geo_message.dart` da.
  String get sendLocation =>
      _('Joy yuborish', 'Отправить место', 'Send a location');

  // Xarita
  String get showOnMap =>
      _('Xaritada ko\'rish', 'Показать на карте', 'Show on the map');

  String get pickOnMap =>
      _('Xaritadan tanlash', 'Выбрать на карте', 'Pick on the map');

  String get confirmLocation =>
      _('Shu yerni tanlash', 'Выбрать это место', 'Choose this spot');
  String get myLocation =>
      _('Mening joylashuvim', 'Моё местоположение', 'My location');
  String get placeUnknown =>
      _('Joy aniqlanmadi', 'Место не определено', 'Place not found');
  /* ── PUSH'DAGI TUGMALAR (18.09.2026) ─────────────────────────────
   * Haydovchi bildirishnomaning O'ZIDAN bronni hal qiladi. Matnlar
   * NATIJANI aytadi: tugma bosildi-yu ekranda hech nima o'zgarmasa,
   * odam amal bajarildimi yo'qmi bilmaydi.
   * ⚠️ Tugmalarning O'Z yozuvlari bu yerda EMAS — ular fon
   * isolate'ida chiziladi va `push_actions.dart` da turadi
   * (u yerda `AppStrings` mavjud emas).
   */
  String get pushActionAccepted =>
      _('Bron qabul qilindi', 'Бронь принята', 'Booking accepted');
  String get pushActionRejected =>
      _('Bron rad etildi', 'Бронь отклонена', 'Booking declined');

  /// Bron allaqachon hal bo'lgan (yo'lovchi bekor qildi yoki boshqa
  /// qurilmadan javob berildi) — bu XATO EMAS, shuning uchun tinch matn.
  String get pushActionGone => _(
    'Bu so\'rov allaqachon hal qilingan',
    'Этот запрос уже обработан',
    'This request has already been handled',
  );

  /// Bitta emas, bir nechta so'rov kutyapti — qaysi birini tasdiqlashni
  /// TAXMIN QILMAYMIZ.
  String get pushActionMany => _(
    'Bir nechta so\'rov bor — qaysi birini hal qilishni tanlang',
    'Несколько запросов — выберите, какой обработать',
    'Several requests are waiting — choose which one to handle',
  );

  String get pushActionFailed => _(
    'Bajarilmadi — ro\'yxatdan qayta urinib ko\'ring',
    'Не удалось — попробуйте из списка',
    'It did not go through — try again from the list',
  );

  String get locationDenied => _(
    'Joylashuvga ruxsat berilmadi',
    'Доступ к геолокации не разрешён',
    'Location permission denied',
  );

  /// Joylashuv XIZMATI (GPS) o'chiq — ruxsat bor, lekin telefon
  /// joyni aniqlamaydi. Rad etilgan ruxsatdan FARQLI javob kerak: bu
  /// yerda yechim ilova sozlamasida emas, telefon sozlamasida.
  String get locationServiceOff => _(
    'Telefonda joylashuv o\'chiq',
    'На телефоне выключена геолокация',
    'Location is turned off on your phone',
  );
  String get turnOn => _('Yoqish', 'Включить', 'Turn on');
  String get locationFailed => _(
    'Joylashuvni aniqlab bo\'lmadi',
    'Не удалось определить местоположение',
    'Could not determine your location',
  );
  String get searchingOnMap => _(
    'Xaritadan qidirilmoqda...',
    'Ищем на карте...',
    'Searching on the map...',
  );
  String get mapResults =>
      _('Xaritadan topilgan', 'Найдено на карте', 'Found on the map');

  // Pochta (posilkalar)
  String get parcelsTitle => _('Pochta', 'Посылки', 'Parcel');
  String get sendParcel =>
      _('Pochta yuborish', 'Отправить посылку', 'Send a parcel');
  String get findParcels => _('Pochta topish', 'Найти посылки', 'Find parcels');
  String get parcelPrice =>
      _('Taklif qilingan narx', 'Предлагаемая цена', 'Offered price');
  // 2026-08-12: narx va qabul qiluvchi raqami MAJBURIY bo'ldi. Bu bizning
  // qaror emas — backend `POST /parcels` da ularni `required` qilgan va
  // yubormasak 400 qaytaradi. Matn "ixtiyoriy" deb turgani yolg'on edi:
  // odam bo'sh qoldirsa "Noto'g'ri so'rov yuborildi" xatosini olardi.
  String get parcelPriceHint => _(
    'Haydovchilar shunga qarab tanlaydi',
    'Водители ориентируются на неё',
    'Drivers decide based on this',
  );
  String get receiverPhone =>
      _('Qabul qiluvchi raqami', 'Номер получателя', 'Receiver\'s phone');
  String get receiverPhoneHint => _(
    'Haydovchi bog\'lanishi uchun',
    'Чтобы водитель мог связаться',
    'So the driver can contact you',
  );
  String get phoneRequired => _(
    'Qabul qiluvchi raqamini kiriting',
    'Укажите номер получателя',
    'Enter the receiver\'s phone',
  );
  String get parcelCreated => _(
    'Pochta e\'loni joylandi',
    'Заявка на посылку размещена',
    'Your parcel has been published',
  );
  // "Ro'yxat hozircha imkonsiz" ogohlantirishi OLIB TASHLANDI (2026-08-12):
  // `GET /parcels/my` gateway'da paydo bo'ldi, ro'yxat endi bor.
  String get myParcels => _('Mening pochtalarim', 'Мои посылки', 'My parcels');

  /// Pochta bo'limi yorliqlari — QISQA.
  ///
  /// 🔴 Haydovchida uchta yorliq bor va to'liq nomlar ("Pochta yuborish",
  /// "Mening pochtalarim", "Pochta topish") 360px ekranga sig'masdi:
  /// yorliqlar siljib, birinchisining boshi kesilib turardi (qurilmada
  /// ko'rildi 2026-08-13). Tugmalardagi to'liq nomlar o'z joyida qoladi.
  String get tabSend => _('Yuborish', 'Отправить', 'Send');
  String get tabMyParcels => _('Pochtalarim', 'Мои', 'Mine');
  String get tabFind => _('Topish', 'Найти', 'Find');
  String get noMyParcels => _(
    'Hali pochta joylamagansiz',
    'Вы ещё не размещали посылок',
    'You have not posted any parcels yet',
  );
  String get noMyParcelsHint => _(
    'Yuborilgan pochta shu yerda, haydovchi takliflari bilan ko\'rinadi',
    'Отправленные посылки появятся здесь вместе с откликами водителей',
    'Parcels you send appear here along with driver offers',
  );
  String get parcelOffers =>
      _('Haydovchi takliflari', 'Отклики водителей', 'Driver offers');
  String get noParcelOffers =>
      _('Hali taklif yo\'q', 'Откликов пока нет', 'No offers yet');
  String get offerAccepted =>
      _('Taklif qabul qilindi', 'Отклик принят', 'Offer accepted');
  String get offerRejected =>
      _('Taklif rad etildi', 'Отклик отклонён', 'Offer declined');
  String get proOnlyFilter => _(
    'Pro va yuqori tarifda',
    'На тарифе Pro и выше',
    'Available on Pro and above',
  );
  String get proOnlyFilterHint => _(
    'Bu belgilar Pro tarifidan boshlab ochiladi',
    'Эти опции доступны с тарифа Pro',
    'These options unlock from the Pro plan',
  );
  String get upgradePlan => _('Tarifni oshirish', 'Повысить тариф', 'Upgrade');

  String get parcelSize => _('Hajmi', 'Размер', 'Size');
  String get parcelSizeSmall => _('Kichik', 'Маленькая', 'Small');
  String get parcelSizeMedium => _("O'rta", 'Средняя', 'Medium');
  String get parcelSizeLarge => _('Katta', 'Большая', 'Large');
  String get parcelSizeHint => _(
    'Hujjat · sumka · chamadon',
    'Документы · сумка · чемодан',
    'Documents · bag · suitcase',
  );
  String get parcelDescription =>
      _('Nima yuborilyapti', 'Что отправляете', 'What are you sending');

  /// 🔴 QISQARTIRILDI (10.09.2026, o'lchandi): ruscha variant
  /// «Например: документы, 2 кг фруктов» edi va 320 px ekranda matn
  /// shkalasi 1.3 bo'lganda maydonga 187 px berilib, 303 px talab
  /// qilardi — maslahat KESILARDI (`hintMaxLines: 2` ham yetmasdi).
  /// «Например» so'zi ikki nuqta bilan birga uzun; misolning o'zi
  /// yetarli.
  String get parcelDescriptionHint => _(
    'Masalan: hujjatlar, 2 kg meva',
    'Документы, 2 кг фруктов',
    'Documents, 2 kg of fruit',
  );
  String get parcelDeliverBy =>
      _('Qachongacha yetkazilsin', 'Доставить до', 'Deliver by');
  String get parcelDeliverByAny => _('Muhim emas', 'Не важно', 'No deadline');

  /// `small`/`medium`/`large` -> ko'rsatiladigan nom. Notanish qiymat kelsa
  /// xomini ko'rsatamiz: backend enum emas, kelajakda yangi o'lcham qo'shsa
  /// jim yo'qolib qolmasin.
  String parcelSizeLabel(String size) => switch (size.toLowerCase()) {
    'small' => parcelSizeSmall,
    'medium' => parcelSizeMedium,
    'large' => parcelSizeLarge,
    _ => size,
  };

  String get cancelParcel =>
      _('Pochtani bekor qilish', 'Отменить посылку', 'Cancel parcel');
  String get cancelParcelConfirm => _(
    'Pochta e\'loni bekor qilinsinmi? Haydovchilar uni boshqa ko\'rmaydi.',
    'Отменить заявку на посылку? Водители её больше не увидят.',
    'Cancel this parcel? Drivers will no longer see it.',
  );
  String get parcelCancelled =>
      _('Pochta bekor qilindi', 'Посылка отменена', 'Parcel cancelled');
  String get parcelsNear => _(
    'Qayerdan olib ketasiz',
    'Откуда забираете',
    'Where will you pick it up',
  );
  String get radius => _('Radius', 'Радиус', 'Radius');
  String get acceptParcel => _('Olib ketaman', 'Возьму', 'I will take it');

  // ===== Posilka xaritada (16.09.2026) =====
  String get parcelsOnMap =>
      _('Xaritada ko\'rish', 'Показать на карте', 'Show on the map');
  String parcelsFound(int n) =>
      _('$n ta pochta topildi', 'Найдено посылок: $n', '$n parcels found');

  /// Posilka yaratishda yo'l ko'rigi ustidagi yozuv.
  String get parcelRoutePreview => _(
    'Pochta shu yo\'ldan ketadi',
    'Посылка поедет этим путём',
    'The parcel will travel this way',
  );

  /// Pastki menyu yorlig'i.
  ///
  /// 🔴 BITTA SO'Z bo'lishi shart: "E'lon berish" 360px ekranda ikki qatorga
  /// bo'linib, chap chetga yopishib qolardi (qurilmada ko'rildi 2026-08-13).
  String get createRideShort => _('Yaratish', 'Создать', 'Create');

  /// Haydovchi rejimidagi "Safarlarim" sarlavhasi — o'z E'LONLARI.
  String driverCounterTitle(String price) => _(
    'Haydovchi $price so\'m taklif qildi',
    'Водитель предложил $price сум',
    'The driver offered $price UZS',
  );
  String get driverCounterHint => _(
    'Rozi bo\'lsangiz haydovchi tasdiqlashini kuting. Kelishmasangiz unga yozing.',
    'Если согласны — дождитесь подтверждения водителя. Если нет — напишите ему.',
    'If you agree, wait for the driver to confirm. If not, message them.',
  );

  String get messageDriver =>
      _('Haydovchiga yozish', 'Написать водителю', 'Message the driver');

  String get rideVisible =>
      _('Qidiruvda ko\'rinadi', 'Виден в поиске', 'Visible in search');
  String get rideNotActive => _(
    'Faollashmagan — qidiruvda yo\'q',
    'Не активирована — не видна в поиске',
    'Not activated — not in search',
  );
  String get myRidesTitle => _('E\'lonlarim', 'Мои поездки', 'My rides');
  String get roleSwitchTitle => _('Rejim', 'Режим', 'Mode');
  String get switchToDriver => _(
    'Haydovchi rejimiga o\'tish',
    'Перейти в режим водителя',
    'Switch to driver mode',
  );
  String get switchToPassenger => _(
    'Yo\'lovchi rejimiga o\'tish',
    'Перейти в режим пассажира',
    'Switch to passenger mode',
  );
  String get switchToDriverHint => _(
    'Haydovchi rejimida e\'lon berasiz va arizalarni ko\'rasiz',
    'В режиме водителя вы размещаете поездки и видите заявки',
    'In driver mode you post rides and see requests',
  );
  String get switchToPassengerHint => _(
    'Yo\'lovchi rejimida safar qidirasiz va bron qilasiz',
    'В режиме пассажира вы ищете поездки и бронируете',
    'In passenger mode you search and book rides',
  );
  String get rolePassenger => _('Yo\'lovchi', 'Пассажир', 'Passenger');
  String get roleDriver => _('Haydovchi', 'Водитель', 'Driver');

  String get offerParcel => _('Taklif berish', 'Предложить', 'Make an offer');
  String get offerParcelTitle => _(
    'Qancha narxga olib ketasiz?',
    'За сколько повезёте?',
    'What is your price?',
  );
  String get offerParcelHint => _(
    'Jo\'natuvchi taklifni ko\'radi va tanlaydi',
    'Отправитель увидит предложение и выберет',
    'The sender will see your offer and decide',
  );
  String get offerSent => _(
    'Taklif yuborildi — jo\'natuvchining javobini kuting',
    'Предложение отправлено — ждите ответа отправителя',
    'Offer sent — wait for the sender to reply',
  );
  String get noCarryingParcels => _(
    'Hozircha yuk olmagansiz',
    'Вы пока ничего не везёте',
    'You are not carrying anything yet',
  );
  String get noCarryingParcelsHint => _(
    'Qidiruvdan yuk toping va narx taklif qiling',
    'Найдите груз в поиске и предложите цену',
    'Find a parcel in search and make an offer',
  );
  String get carryingParcels =>
      _('Olib ketayotganlarim', 'Я везу', 'Parcels I am carrying');
  String get parcelTaken => _(
    'Boshqa haydovchi oldi',
    'Взял другой водитель',
    'Another driver has taken it',
  );
  String get parcelAccepted => _(
    'Pochta biriktirildi',
    'Посылка закреплена',
    'The parcel is assigned to you',
  );
  String get noParcels =>
      _('Pochta topilmadi', 'Посылок не найдено', 'No parcels found');
  String get noParcelsHint => _(
    'Radiusni kengaytiring yoki keyinroq urinib ko\'ring',
    'Расширьте радиус или попробуйте позже',
    'Increase the radius or try again later',
  );

  // Sharh va reyting
  String get rateTitle => _('Baho qo\'yish', 'Оценить', 'Rate');
  String get rateDriver =>
      _('Haydovchini baholash', 'Оценить водителя', 'Rate the driver');
  String get ratePassenger =>
      _('Yo\'lovchini baholash', 'Оценить пассажира', 'Rate the passenger');
  String get sendRating => _('Yuborish', 'Отправить', 'Send');
  String get commentOptional => _(
    'Izoh (ixtiyoriy)',
    'Комментарий (необязательно)',
    'Comment (optional)',
  );
  String get commentHint =>
      _('Safar qanday o\'tdi?', 'Как прошла поездка?', 'How was the ride?');
  String get ratingThanks => _(
    'Bahoyingiz uchun rahmat',
    'Спасибо за оценку',
    'Thanks for your rating',
  );
  String get reviewsTitle => _('Sharhlar', 'Отзывы', 'Reviews');
  String get noReviews =>
      _('Hali sharh yo\'q', 'Отзывов пока нет', 'No reviews yet');
  String scoreLabel(int score) => switch (score) {
    1 => _('Yomon', 'Плохо', 'Bad'),
    2 => _('O\'rtacha emas', 'Ниже среднего', 'Below average'),
    3 => _('O\'rtacha', 'Нормально', 'Moderate'),
    4 => _('Yaxshi', 'Хорошо', 'Good'),
    _ => _('Ajoyib', 'Отлично', 'Excellent'),
  };

  // Tariflar va to'lov
  String get tariffsTitle => _('Tariflar', 'Тарифы', 'Plans');
  String get noPlans => _(
    'Tariflar yuklanmadi',
    'Тарифы не загрузились',
    'Could not load the plans',
  );
  String get currentPlan => _('Joriy tarif', 'Текущий тариф', 'Current plan');
  String get noPlanYet =>
      _('Tarif tanlanmagan', 'Тариф не выбран', 'No plan selected');
  String get activePlan => _('Faol', 'Активен', 'Active');
  String get choosePlan => _('Tanlash', 'Выбрать', 'Choose');

  /// Eng foydali tarif nishoni — narx/safar bo'yicha hisoblanadi.
  String get planPopular => _('Eng foydali', 'Выгоднее всего', 'Best value');

  /// Kartadagi qisqa yorliqlar. Uzun jumla o'rniga qisqasi: karta ichida
  /// ikki qatorga chiqib ketgan matn butun setkani uzaytirardi.
  String get featureRides => _('safar', 'поездок', 'rides');
  String get featureParcels => _('posilka', 'посылок', 'parcels');

  /// 🔴 "Premium belgilar" EMAS (egasi, 2026-08-16): o'zbekcha so'z bor va
  /// odam uni tushunadi — yo'lovchi safarni AYNAN shu filtrlar bo'yicha
  /// qidiradi.
  String get featureFilters => _('Filtrlar', 'Фильтры', 'Filters');
  String get featureFiltersHint => _(
    'konditsioner, chekilmaydi, haydash uslubi',
    'кондиционер, не курят, стиль вождения',
    'A/C, no smoking, driving style',
  );

  // ===== Tarif tafsiloti (kartani bosganda ochiladi) =====

  /// Kartada: "Batafsil" — bosish mumkinligini bildiradi.
  // ===== Qo'llab-quvvatlash (ilova ichidagi murojaat) =====

  // ===== SAVOL-JAVOB =====
  String get faqTitle =>
      _('Tez-tez so\'raladigan savollar', 'Частые вопросы', 'Common questions');
  String get faqSearchHint =>
      _('Savolni qidiring', 'Найти вопрос', 'Search questions');
  String get faqNothingFound => _(
    'Topilmadi — pastda bizga yozing',
    'Не найдено — напишите нам ниже',
    'Not found — write to us below',
  );

  /// 🔴 JAVOBLAR HAQIQATNI aytadi, va'da bermaydi. Bekor qilish hozir
  /// MUMKIN EMAS (backendda endpoint yo'q) — buni yashirmaymiz. Yolg'on
  /// javob murojaatni kamaytirmaydi, faqat ishonchni yo'qotadi.
  List<(String, String)> get faqItems => switch (lang) {
    Lang.uz => _faqItemsUz,
    Lang.uzCyrl =>
      _faqItemsUz.map((e) => (toCyrillic(e.$1), toCyrillic(e.$2))).toList(),
    Lang.ru => const [
      (
        'Как забронировать?',
        'Откройте поездку, выберите количество мест и нажмите '
            '«Забронировать». Когда водитель подтвердит, придёт уведомление.',
      ),
      (
        'Водитель не отвечает, что делать?',
        'Если заявка в статусе «Ожидание» — водитель её ещё не видел. '
            'Напишите в чат или выберите другую поездку.',
      ),
      (
        'Не могу отменить бронь',
        'Пока в приложении НЕТ кнопки отмены — мы над этим работаем. '
            'Напишите водителю в чат: он может отменить со своей стороны.',
      ),
      (
        'Кому виден мой номер телефона?',
        'В поиске и посторонним он НЕ виден. Открывается только ПОСЛЕ '
            'подтверждения брони и только второй стороне этой поездки.',
      ),
      (
        'Как происходит оплата?',
        'За поездку вы рассчитываетесь с водителем напрямую. В приложении '
            'есть только оплата тарифа для водителей.',
      ),
      (
        'Почему моё объявление не видно?',
        'Чтобы объявление активировалось, автомобиль должен быть '
            'подтверждён. Профиль → Мои автомобили — там виден статус.',
      ),
      (
        'Не приходят уведомления',
        'Пока уведомления проверяются при открытии приложения. Также '
            'проверьте, разрешены ли уведомления в настройках телефона.',
      ),
      (
        'Как удалить аккаунт?',
        'Профиль → Безопасность → Удалить аккаунт. Данные не хранятся '
            'дольше установленных законом сроков.',
      ),
    ],
    Lang.en => const [
      (
        'How do I book a seat?',
        'Open the ride, choose how many seats you need and tap "Book". '
            'You will be notified once the driver confirms.',
      ),
      (
        'The driver is not responding',
        'If your request still says "Pending", the driver has not seen it '
            'yet. Write in the chat or choose another ride.',
      ),
      (
        'I cannot cancel my booking',
        'There is no cancel button in the app yet — we are working on it. '
            'Please message the driver: they can cancel from their side.',
      ),
      (
        'Who can see my phone number?',
        'It is NOT shown in search or to strangers. It opens only AFTER a '
            'booking is confirmed, and only to the other side of that ride.',
      ),
      (
        'How does payment work?',
        'You pay the driver directly for the ride. The app only handles '
            'subscription payments for drivers.',
      ),
      (
        'Why is my ride not visible?',
        'A ride goes live only once your car is approved. Check the status '
            'in Profile → My cars.',
      ),
      (
        'I am not getting notifications',
        'For now notifications are checked when you open the app. Also '
            'make sure notifications are allowed in your phone settings.',
      ),
      (
        'How do I delete my account?',
        'Profile → Security → Delete account. Data is not kept longer than '
            'the law requires.',
      ),
    ],
  };

  // ===== YORDAM YO'LI — KIRISHDAN OLDIN HAM (22.09.2026) =====
  //
  // 🔴 NEGA KERAK (egasi): yordam faqat ilova ICHIDA, profil ostida bor
  // edi. Ya'ni eng ko'p yordam kerak bo'ladigan odam — kodni ololmagan,
  // umuman kira olmayotgan odam — bizga yozish yo'lini TOPOLMASDI.
  //
  // ⚠️ Kirmagan odamga `POST /helpdesk/tickets` YOPIQ (token yo'q), shuning
  // uchun bu yerda forma emas, TELEGRAM ko'rsatiladi — bugun ishlaydigan
  // yagona kanal (`Env.supportTelegramUrl`).
  String get supportNeedHelp =>
      _('Yordam kerakmi?', 'Нужна помощь?', 'Need help?');
  String get authSupportTitle =>
      _('Kira olmayapsizmi?', 'Не получается войти?', 'Trouble signing in?');
  String get authSupportSmsHint => _(
    'SMS odatda 1–2 daqiqada keladi. Kelmasa: raqamni tekshiring, tarmoq '
        'qoplamasiga chiqing va «Kodni qayta yuborish» ni bosing.',
    'SMS обычно приходит за 1–2 минуты. Если не пришла: проверьте номер, '
        'убедитесь в наличии сети и нажмите «Отправить код повторно».',
    'The SMS usually arrives within 1–2 minutes. If it does not: check the '
        'number, make sure you have signal and tap "Resend code".',
  );
  String get authSupportPasswordHint => _(
    'Kunlik kod limiti tugagan bo\'lsa, parol bilan kirish mumkin.',
    'Если дневной лимит кодов исчерпан, можно войти по паролю.',
    'If the daily code limit is used up, you can sign in with a password.',
  );

  /// Telegramga o'tishdan oldin — operator so'ramasligi uchun.
  String authSupportTech(String version) => _(
    'Yozganingizda shu ma\'lumotni ham qo\'shing: ilova $version',
    'При обращении укажите и это: приложение $version',
    'Include this when you write: app $version',
  );
  String get authSupportWrite => _(
    'Qo\'llab-quvvatlashga yozish',
    'Написать в поддержку',
    'Write to support',
  );

  String get supportTitle => _('Yordam', 'Помощь', 'Help');
  String get supportSubject => _('Mavzu', 'Тема', 'Subject');
  String get supportDescribe =>
      _('Nima bo\'ldi?', 'Что случилось?', 'What happened?');
  String get supportHint => _(
    "Iloji boricha aniq yozing: qachon, qaysi safarda, nima kutgan "
        "edingiz va nima bo'ldi.",
    'Опишите как можно точнее: когда, в какой поездке, чего вы ожидали и '
        'что произошло.',
    'Describe it as precisely as you can: when, on which ride, what you '
        'expected and what happened.',
  );
  String get supportSend => _('Yuborish', 'Отправить', 'Send');

  /// Mavzular — backend tavsifidagi holatlar (жалоба, ДТП, забытые вещи).
  String get supportTopicComplaint => _('Shikoyat', 'Жалоба', 'Complaint');
  String get supportTopicAccident =>
      _('Yo\'l hodisasi', 'ДТП', 'Road accident');
  String get supportTopicLostItem =>
      _('Unutilgan buyum', 'Забытые вещи', 'Lost item');
  String get supportTopicPayment => _('To\'lov', 'Оплата', 'Payment');
  String get supportTopicOther => _('Boshqa', 'Другое', 'Other');

  /// Murojaat yuborilgandan keyingi tasdiq matni.
  ///
  /// ⚠️ 07.09.2026 da tuzatildi: bu yerda «backendda operator javobini
  /// saqlaydigan maydon YO'Q» deb turardi, pastdagi `supportSentHint`
  /// esa «javobni shu yerda ko'rasiz» derdi — ikki izoh BIR-BIRINI
  /// INKOR QILARDI. Haqiqati pastdagisi: backend javob maydonini
  /// 16.08.2026 da qo'shgan va u «Murojaatlarim» da ko'rinadi.
  String get supportSent =>
      _('Murojaat yuborildi', 'Обращение отправлено', 'Your request was sent');

  /// ✅ 2026-08-16 kechqurun: backend operator javobini qo'shdi, ya'ni
  /// javob shu yerda ko'rinadi. Ilgari "Telegram orqali keladi" deyilardi.
  String get supportSentHint => _(
    "Javobni shu yerda, «Murojaatlarim» bo'limida ko'rasiz. Shoshilinch "
        "bo'lsa Telegramda yozing.",
    'Ответ увидите здесь, в разделе «Мои обращения». Если срочно — '
        'напишите в Telegram.',
    'You will see the reply here, in "My requests". If it is urgent, '
        'write on Telegram.',
  );

  // ===== Murojaatlar ro'yxati =====
  String get supportMyTickets =>
      _('Murojaatlarim', 'Мои обращения', 'My requests');
  String get supportNoTickets =>
      _('Murojaat yo\'q', 'Обращений нет', 'No requests yet');
  String get supportAnswer => _('Javob', 'Ответ', 'Reply');
  String get supportWaiting =>
      _('Javob kutilmoqda', 'Ожидает ответа', 'Awaiting a reply');
  String get supportNewTicket =>
      _('Yangi murojaat', 'Новое обращение', 'New request');
  String get supportUrgent => _(
    'Shoshilinch — Telegramda yozish',
    'Срочно — написать в Telegram',
    'Urgent — write on Telegram',
  );
  String get supportEmptyText => _(
    'Nima bo\'lganini yozing',
    'Опишите, что случилось',
    'Describe what happened',
  );

  // ===== Posilka: haydovchi amallari =====

  /// ✅ Backend 2026-08-16 da `pickup`/`deliver` qo'shdi. Ungacha posilka
  /// `accepted` da abadiy qolardi.
  String get parcelPickup => _('Oldim', 'Забрал', 'Picked up');
  String get parcelDeliver => _('Yetkazdim', 'Доставил', 'Delivered');
  String get parcelPickedUpDone =>
      _('Posilka olindi', 'Посылка забрана', 'Parcel picked up');
  String get parcelDeliveredDone =>
      _('Posilka yetkazildi', 'Посылка доставлена', 'Parcel delivered');
  String get parcelDeliverConfirm => _(
    'Posilka qabul qiluvchiga topshirildimi?',
    'Посылка передана получателю?',
    'Has the parcel been handed to the receiver?',
  );

  /// Jo'natuvchiga: nechta taklif kelgani.
  String parcelOffersCount(int count) =>
      _('$count ta taklif', 'Предложений: $count', '$count offers');

  String get planDetails => _('Batafsil', 'Подробнее', 'Details');

  String get planWhatYouGet => _('Nima kiradi', 'Что входит', 'What you get');

  /// Filtrlar bo'limi sarlavhasi va tushuntirishi.
  String get planFiltersTitle =>
      _('Safar filtrlari', 'Фильтры поездки', 'Ride filters');
  String get planFiltersWhy => _(
    "Yo'lovchi qidiruvda aynan shu belgilar bo'yicha tanlaydi. Ular yoqilgan "
        "e'lon ro'yxatda ajralib turadi.",
    'Пассажир выбирает поездку именно по этим меткам. Объявление с ними '
        'заметнее в списке.',
    'Passengers filter rides by exactly these tags. A listing with them '
        'stands out in the results.',
  );
  String get planFiltersOpenHere =>
      _('Shu tarifda ochiq', 'Открыто на этом тарифе', 'Open on this plan');
  String get planFiltersNeedUpgrade => _(
    'Yuqoriroq tarifda ochiladi',
    'Откроется на тарифе выше',
    'Opens on a higher plan',
  );
  String get planFiltersAlways =>
      _('Hamma tarifda bor', 'Есть на всех тарифах', 'Included in every plan');

  /// Safar paketi qanday sarflanishi — eng ko'p so'raladigan savol.
  String planRidesExplain(String count) => _(
    "Bir oyda $count ta e'lon berasiz. Balans e'lon QILGANDA kamayadi, "
        "yo'lovchi qidirganda emas.",
    'В месяц вы публикуете $count объявлений. Баланс уменьшается при '
        'ПУБЛИКАЦИИ, а не при поиске.',
    'You publish $count listings per month. The balance is spent when you '
        'publish, not when someone searches.',
  );
  String get planRidesUnlimited => _(
    "E'lonlar soni cheklanmaydi.",
    'Количество объявлений не ограничено.',
    'The number of listings is not limited.',
  );
  String planParcelsExplain(String count) => _(
    'Oyiga $count ta posilkani bepul olib ketasiz.',
    'В месяц $count посылок бесплатно.',
    '$count parcels per month at no extra cost.',
  );

  /// Tarif muddati — kartadagi eslatmaning batafsil varianti.
  String get planPeriodNote => _(
    "Tarif bir oyga amal qiladi va avtomatik yangilanmaydi — pul o'zidan "
        "yechilmaydi.",
    'Тариф действует месяц и не продлевается автоматически — деньги сами '
        'не спишутся.',
    'The plan lasts one month and does not renew automatically — nothing is '
        'charged by itself.',
  );

  /// Tarif tanlash tugmasi — nomi bilan: "Pro ni tanlash".
  String choosePlanNamed(String plan) =>
      _('$plan ni tanlash', 'Выбрать $plan', 'Choose $plan');

  /// "1 safar ≈ 1 400 so'm" — odam qiymatni RAQAMDA ko'radi.
  String perRidePrice(String price) => _(
    '1 safar ≈ $price so\'m',
    '1 поездка ≈ $price сум',
    '1 ride ≈ $price UZS',
  );

  /// Cheksiz tarif qachondan foydali: "67 safardan boshlab Pro'dan arzon".
  ///
  /// Bu ham reklama, ham ogohlantirish: kam yuradigan odamga bu tarif
  /// kerak emasligini ochiq aytadi. Ishonchni aynan shu qozonadi.
  String unlimitedBreakEven(String rides, String plan) => _(
    "$rides safardan boshlab $plan dan arzon",
    'Выгоднее $plan начиная с $rides поездок',
    'Cheaper than $plan from $rides rides',
  );
  String get planFreeHint =>
      _('Sinab ko\'rish uchun', 'Чтобы попробовать', 'To try it out');
  String get trialUsed => _(
    'Sinov muddati ishlatilgan',
    'Пробный период использован',
    'Trial already used',
  );
  String get free => _('Bepul', 'Бесплатно', 'Free');
  String get perMonth => _('oy', 'мес', 'month');

  /// Tariflar ro'yxatida — tariflar orasidagi ENG KATTA farq.
  String get premiumFiltersFeature => _(
    'Premium belgilar (konditsioner, chekilmaydi, haydash uslubi)',
    'Премиум-метки (кондиционер, не курить, стиль вождения)',
    'Premium tags (air conditioning, no smoking, driving style)',
  );
  String get unlimited => _('Cheksiz', 'Безлимит', 'Unlimited');
  String get ridesPerMonth =>
      _('Oyiga safar', 'Поездок в месяц', 'Rides per month');
  String get parcelsPerMonth => _(
    'Oyiga bepul pochta',
    'Бесплатных посылок в месяц',
    'Free parcels per month',
  );
  String get ridesLeft => _('Qolgan safar', 'Осталось поездок', 'Rides left');
  String get validUntil => _('Amal qiladi', 'Действует до', 'Valid until');
  String get promoCodeTitle =>
      _('Promokod bormi?', 'Есть промокод?', 'Have a promo code?');
  String get promoCodeHint =>
      _('Promokodni kiriting', 'Введите промокод', 'Enter the promo code');
  String get skip => _('O\'tkazib yuborish', 'Пропустить', 'Skip');
  String get paymentDone =>
      _('Tarif faollashtirildi', 'Тариф активирован', 'Plan activated');
  String get paymentMockDone => _(
    'To\'lov qabul qilindi — tarif faollashtirildi (test rejimi)',
    'Оплата принята — тариф активирован (тестовый режим)',
    'Payment accepted — plan activated (test mode)',
  );
  String get paymentRedirecting => _(
    'To\'lov sahifasi brauzerda ochildi',
    'Страница оплаты открыта в браузере',
    'The payment page opened in your browser',
  );
  String get paymentOpenFailed => _(
    'To\'lov sahifasini ochib bo\'lmadi',
    'Не удалось открыть страницу оплаты',
    'Could not open the payment page',
  );
  // 🔴 TO'LOV NATIJASI — TAXMIN EMAS (14.09.2026). Backend
  // `GET /billing/transactions/{id}` berdi, endi rostini aytamiz.
  String get paymentChecking => _(
    'To\'lov tekshirilmoqda...',
    'Проверяем платёж...',
    'Checking the payment...',
  );
  String get paymentFailed => _(
    'To\'lov amalga oshmadi. Pul yechilmagan bo\'lsa, qayta urinib ko\'ring.',
    'Платёж не прошёл. Если деньги не списаны, попробуйте ещё раз.',
    'The payment did not go through. If you were not charged, please try again.',
  );
  String get paymentPending => _(
    'To\'lov hali tasdiqlanmadi. Pul yechilgan bo\'lsa, paket bir necha daqiqada o\'zi faollashadi.',
    'Платёж ещё не подтверждён. Если деньги списаны, пакет активируется через несколько минут.',
    'The payment is not confirmed yet. If you were charged, your plan will activate in a few minutes.',
  );
  String get paywallTitle => _(
    'Safar paketi tugadi',
    'Пакет поездок закончился',
    'Your ride package is used up',
  );
  String get paywallHint => _(
    'E\'lon berishni davom ettirish uchun tarifni yangilang',
    'Обновите тариф, чтобы продолжить публиковать поездки',
    'Renew your plan to keep publishing trips',
  );
  String get tariffsFooter => _(
    'Tarif bir oyga amal qiladi va avtomatik yangilanmaydi',
    'Тариф действует месяц и не продлевается автоматически',
    'The plan lasts one month and does not renew automatically',
  );

  /// Tarif amal qiladi, lekin paket tugagan.
  String get planUnknown => _(
    'Joriy tarifingizni aniqlab bo\'lmadi',
    'Не удалось определить ваш текущий тариф',
    'Could not check your current plan',
  );

  String get quotaFinished =>
      _('Paket tugadi', 'Пакет исчерпан', 'Package used up');

  String planStatus(String status) => switch (status) {
    'active' => _('Faol', 'Активен', 'Active'),
    'past_due' => _('To\'lov kechikkan', 'Просрочен платёж', 'Payment overdue'),
    'canceled' => _('Bekor qilingan', 'Отменён', 'Cancelled'),
    'expired' => _('Muddati tugagan', 'Истёк', 'Expired'),
    _ => status,
  };

  /// Posilka holati. Ikkala imlo ham qamrab olingan: backend `cancelled` va
  /// `canceled` ni turli joyda ishlatadi, biri tarjimasiz o'tib ketmasin.
  String parcelStatus(String status) => switch (status.toLowerCase()) {
    'pending' => _('Kutilmoqda', 'Ожидает', 'Pending'),
    'accepted' => _('Haydovchi topildi', 'Водитель найден', 'Driver assigned'),
    // 🔴 `picked_up` ro'yxatda YO'Q edi va xom qiymat ekranga chiqardi
    // (2026-09-04). Aynan shu holat eng ko'p ko'riladi: haydovchi
    // olgandan yetkazgunicha posilka shunda turadi.
    'picked_up' || 'in_transit' => _('Yo\'lda', 'В пути', 'In transit'),
    'delivered' => _('Yetkazildi', 'Доставлена', 'Delivered'),
    'cancelled' || 'canceled' => _('Bekor qilingan', 'Отменена', 'Cancelled'),
    _ => status,
  };

  // Statuslar
  String bookingStatus(String status) => switch (status) {
    'pending' => _('Kutilmoqda', 'Ожидает', 'Pending'),
    'pending_negotiation' => _(
      'Narx kelishilmoqda',
      'Согласование цены',
      'Price is being negotiated',
    ),
    'confirmed' => _('Tasdiqlangan', 'Подтверждено', 'Confirmed'),
    'rejected' => _('Rad etilgan', 'Отклонено', 'Declined'),
    // 🔴 `cancelled` YETISHMASDI (2026-08-30): yo'lovchi bronini o'zi
    // bekor qilsa ekranda xom `cancelled` so'zi turardi. Status
    // `BookingStatus.cancelled` da bor va kod uni tekshiradi ham,
    // faqat tarjimasi yozilmagan edi.
    'cancelled' => _('Bekor qilingan', 'Отменено', 'Cancelled'),
    'no_show' => _('Kelmadi', 'Не явился', 'No-show'),
    _ => status,
  };

  /// Kelishilgandan keyin aloqa.
  String get contactSection => _('Aloqa', 'Связь', 'Contact');
  String get callButton => _("Qo'ng'iroq", 'Позвонить', 'Call');
  String get phoneAfterConfirm => _(
    "Raqam bron tasdiqlangandan keyin ochiladi",
    'Номер откроется после подтверждения брони',
    'The number opens after the booking is confirmed',
  );
  String get phoneNotProvided => _(
    "Raqam kelmadi — chat orqali bog'laning",
    'Номер не пришёл — свяжитесь через чат',
    'No number available — use the chat',
  );

  /// Haydovchi safarni bekor qildi — yo'lovchi bu haqda BILISHI shart.
  String get rideCancelledTitle =>
      _('Safar bekor qilindi', 'Поездка отменена', 'The trip was cancelled');
  String get rideCancelledHint => _(
    "Haydovchi bu safarni bekor qildi. Boshqa safar tanlashingiz kerak.",
    'Водитель отменил эту поездку. Нужно выбрать другую.',
    'The driver cancelled this trip. You need to choose another one.',
  );

  String rideStatus(String status) => switch (status) {
    'draft' => _('Qoralama', 'Черновик', 'Draft'),
    'active' => _('Faol', 'Активна', 'Active'),
    'in_progress' => _('Yo\'lda', 'В пути', 'On the way'),
    'completed' => _('Tugagan', 'Завершена', 'Completed'),
    'cancelled' => _('Bekor qilingan', 'Отменена', 'Cancelled'),
    _ => status,
  };
}

/*
 * LOTINCHA RO'YXATLAR — bir marta yoziladi.
 *
 * 🔴 NEGA AYRIM (2026-09-08): kirill shoxi avtomatik qo'shilganda
 * ro'yxatlar MANBADA ikki nusxaga aylanib qolgandi. Ertaga birini
 * tuzatib, ikkinchisini unutish — bu loyihada allaqachon bo'lgan
 * xato. Endi ikkala til ham SHU ro'yxatga murojaat qiladi.
 */
const List<String> _quickRepliesUz = [
  'Yo\'ldaman',
  '5 daqiqa',
  'Qayerdasiz?',
  'Yetib keldim',
];
const List<String> _docPassportHintsUz = [
  'Suratingiz va ma\'lumotlaringiz bor sahifani oling',
  'To\'rtala burchagi ham kadrga tushsin',
  'Yozuvlar aniq o\'qilsin — xira bo\'lmasin',
  'Yorug\'lik aks etmasin, soya tushmasin',
];
const List<String> _docIdCardHintsUz = [
  'Kartaning suratli tomonini oling',
  'To\'rtala burchagi ham kadrga tushsin',
  'Raqamlar aniq ko\'rinsin',
  'Yorug\'lik aks etmasin',
];
const List<String> _docLicenseHintsUz = [
  'Guvohnomaning old tomonini oling',
  'Toifa va amal qilish muddati ko\'rinsin',
  'Yozuvlar aniq o\'qilsin',
  'Muddati o\'tmagan bo\'lsin',
];
const List<String> _docTechPassportHintsUz = [
  'Egasi va mashina ma\'lumotlari bor tomonni oling',
  'Davlat raqami aniq ko\'rinsin',
  'To\'rtala burchagi ham kadrga tushsin',
  'Yozuvlar xira bo\'lmasin',
];
const List<String> _docLicenseBackHintsUz = [
  'Toifalar jadvali (B, C, D) to\'liq ko\'rinsin',
  'Har toifaning muddati o\'qilsin',
  'To\'rtala burchagi ham kadrga tushsin',
  'Yorug\'lik aks etmasin',
];
const List<String> _docTechPassportBackHintsUz = [
  'Egalik va ishonchnoma yozuvlari ko\'rinsin',
  'Muhrlar kesilmasin',
  'To\'rtala burchagi ham kadrga tushsin',
  'Yozuvlar xira bo\'lmasin',
];
const List<String> _docCarFrontHintsUz = [
  'Mashina to\'liq kadrga sig\'sin',
  'Old davlat raqami o\'qilsin',
  'Kunduzi, yaxshi yorug\'likda oling',
];
const List<String> _docCarBackHintsUz = [
  'Orqa davlat raqami aniq o\'qilsin',
  'Bagaj qopqog\'i to\'liq ko\'rinsin',
  'Boshqa mashina to\'sib qolmasin',
];
const List<String> _docCarSideHintsUz = [
  'Mashinaning butun yon tomoni ko\'rinsin',
  'To\'rtala eshik ham kadrda bo\'lsin',
  'Rangi asl holidek chiqsin',
];
const List<String> _docSelfieHintsUz = [
  'Yuzingiz to\'liq ko\'rinsin — bosh kiyim va ko\'zoynaksiz',
  'Yorug\' joyda turing, orqangizdan yorug\'lik tushmasin',
  'Bu surat profilingizda ko\'rinadi — yo\'lovchi sizni taniydi',
];
const List<String> _whatsNewItemsUz = [
  'Bosh ekran endi XARITA: uni surib, kattalashtirib, shahar ustiga '
      'bosib safar qidirasiz',
  'Xaritada o\'z joyingiz ko\'rinadi — nuqta siz bilan birga yuradi',
  'Safar ketayotganda mashina xaritada SILLIQ suriladi va ma\'lumot '
      'qachon yangilangani yozib turiladi',
  'Haydovchi bron so\'rovini bildirishnomaning O\'ZIDAN qabul qila '
      'oladi — ilovani ochib o\'tirmasdan',
  'Manzil qidiruvi endi uzilmaydi: bir manba ishlamasa ikkinchisi '
      'javob beradi',
];
const List<(String, String)> _faqItemsUz = [
  (
    'Qanday bron qilaman?',
    'Safarni oching, joy sonini tanlang va «Bron qilish» tugmasini '
        'bosing. Haydovchi tasdiqlagach xabar keladi.',
  ),
  (
    'Haydovchi javob bermayapti, nima qilay?',
    'Arizangiz «Kutilmoqda» holatida tursa, haydovchi hali ko\'rmagan. '
        'Chat orqali yozing yoki boshqa safarni tanlang.',
  ),
  (
    'Bronni bekor qila olmayapman',
    'Hozircha ilovada bekor qilish tugmasi YO\'Q — bu ustimizda '
        'ishlanmoqda. Iltimos, haydovchiga chat orqali yozing: u o\'z '
        'tomonidan bekor qila oladi.',
  ),
  (
    'Telefon raqamim kimga ko\'rinadi?',
    'Qidiruvda va begonalarga KO\'RINMAYDI. U faqat bron '
        'TASDIQLANGANDAN keyin va faqat o\'sha safarning ikkinchi '
        'tarafiga ochiladi.',
  ),
  (
    'Pul qanday to\'lanadi?',
    'Safar haqi haydovchi bilan to\'g\'ridan-to\'g\'ri hisoblashiladi. '
        'Ilovada faqat haydovchilar uchun tarif to\'lovi bor.',
  ),
  (
    'Nega e\'lonim ko\'rinmayapti?',
    'E\'lon faollashishi uchun mashinangiz tasdiqlangan bo\'lishi kerak. '
        'Profil → Mashinalarim bo\'limida holatni ko\'ring.',
  ),
  (
    'Bildirishnoma kelmayapti',
    'Hozircha bildirishnomalar ilova ochilganda tekshiriladi. Telefon '
        'sozlamalarida ilovaga bildirishnoma ruxsati berilganini ham '
        'tekshiring.',
  ),
  (
    'Hisobimni qanday o\'chiraman?',
    'Profil → Xavfsizlik → Hisobni o\'chirish. Ma\'lumotlar qonunda '
        'belgilangan muddatdan tashqari saqlanmaydi.',
  ),
];

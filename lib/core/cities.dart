/// Joylar ma'lumotnomasi — shaharlar VA tumanlar.
///
/// ⚠ ENG MUHIMI: shahar koordinatalari web'dagi `shared/data/uzCities.ts` bilan
/// AYNAN bir xil. Backend qidiruvi nom bo'yicha emas, KOORDINATA RADIUSI
/// bo'yicha ishlaydi — saytda e'lon `41.311081` bilan yaratilib, mobil qidiruv
/// `41.2995` yuborsa, o'sha safar radiusdan chiqib qidiruvda ko'rinmaydi.
/// Yangi joy qo'shilsa IKKALA faylga bir xil qiymat bilan qo'shilsin.
///
/// Tumanlar — OpenStreetMap'dagi `admin_level=6` chegaralarining
/// `admin_centre` nuqtasi (tuman markazi shaharchasi). Chegaraning bbox
/// markazi EMAS: u cho'l yoki tog' o'rtasiga tushib qolishi mumkin, u yerda
/// esa hech kim safarga chiqmaydi. `radius_km` (standart 25) qolgan farqni
/// qoplaydi.
///
/// ⚠ BU FAYL GENERATSIYA QILINADI — qo'lda tahrirlanmaydi:
///   python3 tools/fetch_osm_districts.py   # OSM'dan xom ma'lumot
///   python3 tools/build_districts.py       # tools/districts.json
///   python3 tools/gen_places.py            # shu ro'yxat
library;

import 'geo.dart';

enum PlaceKind { city, district }

class Place {
  const Place({
    required this.name,
    required this.lat,
    required this.lon,
    required this.region,
    this.kind = PlaceKind.city,
    this.aliases = const [],
  });

  /// Kanonik nom (lotin, o'zbekcha) — web bilan bir xil bo'lishi uchun
  /// ikkala tilda ham AYNAN shu ko'rsatiladi.
  final String name;
  final double lat;
  final double lon;

  /// Ro'yxatda guruhlash uchun ("Chilonzor · Toshkent shahri").
  final String region;
  final PlaceKind kind;

  /// Muqobil yozuvlar: apostrofsiz lotin, ruscha kirill, tarqalgan variantlar.
  final List<String> aliases;

  bool get isDistrict => kind == PlaceKind.district;
}

const List<Place> kPlaces = [
  // ===== Shaharlar — koordinatalar web bilan AYNAN bir xil =====
  Place(
    name: 'Toshkent',
    lat: 41.311081,
    lon: 69.240562,
    region: 'Toshkent shahri',
    aliases: ['tashkent', 'ташкент'],
  ),
  Place(
    name: 'Nurafshon',
    lat: 41.0139,
    lon: 69.3608,
    region: 'Toshkent viloyati',
    aliases: ['tuytepa'],
  ),
  Place(
    name: 'Samarqand',
    lat: 39.6542,
    lon: 66.9597,
    region: 'Samarqand',
    aliases: ['samarkand', 'самарканд'],
  ),
  Place(
    name: 'Buxoro',
    lat: 39.7681,
    lon: 64.421,
    region: 'Buxoro',
    aliases: ['bukhara', 'buxara', 'бухара'],
  ),
  Place(
    name: 'Andijon',
    lat: 40.7821,
    lon: 72.3442,
    region: 'Andijon',
    aliases: ['andijan', 'андижан'],
  ),
  Place(
    name: 'Namangan',
    lat: 41.0058,
    lon: 71.6436,
    region: 'Namangan',
    aliases: ['наманган'],
  ),
  Place(
    name: "Farg'ona",
    lat: 40.3894,
    lon: 71.7867,
    region: "Farg'ona",
    aliases: ['fargona', 'fergana', 'фергана'],
  ),
  Place(
    name: "Qo'qon",
    lat: 40.5389,
    lon: 70.9425,
    region: "Farg'ona",
    aliases: ['qoqon', 'kokand', 'коканд'],
  ),
  Place(
    name: "Marg'ilon",
    lat: 40.4711,
    lon: 71.7247,
    region: "Farg'ona",
    aliases: ['margilon', 'margilan'],
  ),
  Place(
    name: 'Navoiy',
    lat: 40.0994,
    lon: 65.3792,
    region: 'Navoiy',
    aliases: ['navoi', 'навои'],
  ),
  Place(
    name: 'Zarafshon',
    lat: 41.5789,
    lon: 64.205,
    region: 'Navoiy',
    aliases: ['zarafshan'],
  ),
  Place(
    name: 'Qarshi',
    lat: 38.8606,
    lon: 65.7989,
    region: 'Qashqadaryo',
    aliases: ['karshi', 'карши'],
  ),
  Place(
    name: 'Shahrisabz',
    lat: 39.0578,
    lon: 66.8342,
    region: 'Qashqadaryo',
    aliases: ['shakhrisabz'],
  ),
  Place(
    name: 'Termiz',
    lat: 37.2242,
    lon: 67.2783,
    region: 'Surxondaryo',
    aliases: ['termez', 'термез'],
  ),
  Place(
    name: 'Denov',
    lat: 38.2669,
    lon: 67.8931,
    region: 'Surxondaryo',
    aliases: ['denau'],
  ),
  Place(
    name: 'Jizzax',
    lat: 40.125,
    lon: 67.8422,
    region: 'Jizzax',
    aliases: ['jizzakh', 'djizak'],
  ),
  Place(
    name: 'Guliston',
    lat: 40.4897,
    lon: 68.7842,
    region: 'Sirdaryo',
    aliases: ['gulistan'],
  ),
  Place(
    name: 'Xiva',
    lat: 41.3775,
    lon: 60.3619,
    region: 'Xorazm',
    aliases: ['khiva', 'хива'],
  ),
  Place(
    name: 'Urganch',
    lat: 41.5506,
    lon: 60.6314,
    region: 'Xorazm',
    aliases: ['urgench', 'ургенч'],
  ),
  Place(
    name: 'Nukus',
    lat: 42.4611,
    lon: 59.6111,
    region: "Qoraqalpog'iston",
    aliases: ['нукус'],
  ),
  Place(
    name: 'Angren',
    lat: 41.0167,
    lon: 70.1436,
    region: 'Toshkent viloyati',
    aliases: ['ангрен'],
  ),
  Place(
    name: 'Chirchiq',
    lat: 41.4689,
    lon: 69.5822,
    region: 'Toshkent viloyati',
    aliases: ['chirchik'],
  ),
  Place(
    name: 'Olmaliq',
    lat: 40.8447,
    lon: 69.5983,
    region: 'Toshkent viloyati',
    aliases: ['almalyk'],
  ),
  Place(
    name: 'Bekobod',
    lat: 40.2206,
    lon: 69.2683,
    region: 'Toshkent viloyati',
    aliases: ['bekabad'],
  ),
  Place(
    name: 'Kogon',
    lat: 39.7228,
    lon: 64.5528,
    region: 'Buxoro',
    aliases: ['kagan'],
  ),
  Place(
    name: "Yangiyo'l",
    lat: 41.1122,
    lon: 69.0483,
    region: 'Toshkent viloyati',
    aliases: ['yangiyol'],
  ),
  Place(
    name: 'Ohangaron',
    lat: 40.9078,
    lon: 69.6386,
    region: 'Toshkent viloyati',
    aliases: ['ahangaran'],
  ),
  Place(
    name: 'Chinoz',
    lat: 40.9369,
    lon: 68.7639,
    region: 'Toshkent viloyati',
    aliases: ['chinaz'],
  ),
  Place(
    name: 'Gazalkent',
    lat: 41.5583,
    lon: 69.7736,
    region: 'Toshkent viloyati',
  ),
  Place(
    name: "Kattaqo'rg'on",
    lat: 39.8994,
    lon: 66.2683,
    region: 'Samarqand',
    aliases: ['kattakurgan'],
  ),
  Place(
    name: 'Urgut',
    lat: 39.4008,
    lon: 67.2439,
    region: 'Samarqand',
    aliases: ['ургут'],
  ),
  Place(
    name: "G'ijduvon",
    lat: 40.1044,
    lon: 64.6797,
    region: 'Buxoro',
    aliases: ['gijduvon'],
  ),
  Place(
    name: 'Beruniy',
    lat: 41.6889,
    lon: 60.7517,
    region: "Qoraqalpog'iston",
    aliases: ['beruni'],
  ),
  Place(
    name: "To'rtko'l",
    lat: 41.55,
    lon: 61.0,
    region: "Qoraqalpog'iston",
    aliases: ['turtkul'],
  ),
  Place(
    name: "Xo'jayli",
    lat: 42.3956,
    lon: 59.4506,
    region: "Qoraqalpog'iston",
    aliases: ['khodjeyli'],
  ),
  Place(
    name: 'Chimboy',
    lat: 42.9389,
    lon: 59.7717,
    region: "Qoraqalpog'iston",
    aliases: ['chimbay'],
  ),
  Place(
    name: "Mo'ynoq",
    lat: 43.7683,
    lon: 59.0219,
    region: "Qoraqalpog'iston",
    aliases: ['muynak'],
  ),
  Place(
    name: 'Uchquduq',
    lat: 42.155,
    lon: 63.5567,
    region: 'Navoiy',
    aliases: ['uchkuduk'],
  ),
  Place(
    name: 'Nurota',
    lat: 40.5636,
    lon: 65.6889,
    region: 'Navoiy',
    aliases: ['nurata'],
  ),
  Place(
    name: 'Kitob',
    lat: 39.13,
    lon: 66.8817,
    region: 'Qashqadaryo',
    aliases: ['kitab'],
  ),
  Place(
    name: 'Koson',
    lat: 39.0403,
    lon: 65.5878,
    region: 'Qashqadaryo',
    aliases: ['kasan'],
  ),
  Place(
    name: 'Boysun',
    lat: 38.2044,
    lon: 67.1994,
    region: 'Surxondaryo',
    aliases: ['baysun'],
  ),
  Place(
    name: 'Zomin',
    lat: 39.9628,
    lon: 68.3956,
    region: 'Jizzax',
    aliases: ['zaamin'],
  ),
  Place(
    name: 'Chust',
    lat: 41.0069,
    lon: 71.2381,
    region: 'Namangan',
    aliases: ['чуст'],
  ),
  Place(
    name: 'Rishton',
    lat: 40.3567,
    lon: 71.2828,
    region: "Farg'ona",
    aliases: ['rishtan'],
  ),
  Place(
    name: 'Quvasoy',
    lat: 40.2989,
    lon: 71.9739,
    region: "Farg'ona",
    aliases: ['kuvasay'],
  ),
  Place(
    name: 'Asaka',
    lat: 40.6417,
    lon: 72.2394,
    region: 'Andijon',
    aliases: ['асака'],
  ),
  Place(
    name: 'Shahrixon',
    lat: 40.7139,
    lon: 72.0561,
    region: 'Andijon',
    aliases: ['shakhrikhan'],
  ),
  Place(name: 'Yangiyer', lat: 40.2683, lon: 68.8256, region: 'Sirdaryo'),

  // ===== Toshkent shahri tumanlari (qo'lda tekshirilgan) =====
  Place(
    name: 'Bektemir',
    lat: 41.2167,
    lon: 69.3333,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
  ),
  Place(
    name: 'Chilonzor',
    lat: 41.2756,
    lon: 69.2044,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['chilanzar', 'чиланзар'],
  ),
  Place(
    name: 'Mirobod',
    lat: 41.29,
    lon: 69.28,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['mirabad', 'мирабад'],
  ),
  Place(
    name: "Mirzo Ulug'bek",
    lat: 41.335,
    lon: 69.335,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['mirzo ulugbek'],
  ),
  Place(
    name: 'Olmazor',
    lat: 41.345,
    lon: 69.205,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['almazar', 'алмазар'],
  ),
  Place(
    name: 'Sergeli',
    lat: 41.22,
    lon: 69.22,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['сергели'],
  ),
  Place(
    name: 'Shayxontohur',
    lat: 41.32,
    lon: 69.22,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['shaykhantakhur'],
  ),
  Place(
    name: 'Uchtepa',
    lat: 41.29,
    lon: 69.17,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['учтепа'],
  ),
  Place(
    name: 'Yakkasaroy',
    lat: 41.2833,
    lon: 69.25,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['яккасарай'],
  ),
  Place(
    name: 'Yashnobod',
    lat: 41.29,
    lon: 69.32,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['yashnabad', 'яшнабад'],
  ),
  Place(
    name: 'Yunusobod',
    lat: 41.37,
    lon: 69.29,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['yunusabad', 'юнусабад'],
  ),
  Place(
    name: 'Yangihayot',
    lat: 41.2,
    lon: 69.25,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
  ),

  // ===== Viloyat tumanlari — OpenStreetMap admin_centre nuqtalari =====
  // tools/districts.json dan generatsiya qilinadi, QO'LDA TAHRIRLANMAYDI.
  Place(
    name: 'Baliqchi',
    lat: 40.9002,
    lon: 71.84139,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['балыкчинский'],
  ),
  Place(
    name: "Bo'ston",
    lat: 40.68903,
    lon: 71.92542,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['бустанский', 'boston'],
  ),
  Place(
    name: 'Buloqboshi',
    lat: 40.62911,
    lon: 72.50152,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['булакбашинский'],
  ),
  Place(
    name: 'Izboskan',
    lat: 40.89864,
    lon: 72.2475,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['избасканский'],
  ),
  Place(
    name: 'Jalaquduq',
    lat: 40.71864,
    lon: 72.6423,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['джалакудукский'],
  ),
  Place(
    name: 'Marhamat',
    lat: 40.51411,
    lon: 72.32132,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['мархаматский'],
  ),
  Place(
    name: "Oltinko'l",
    lat: 40.7833,
    lon: 72.15033,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['алтынкульский', 'oltinkol'],
  ),
  Place(
    name: 'Paxtaobod',
    lat: 40.92753,
    lon: 72.49811,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['пахтаабадский'],
  ),
  Place(
    name: "Qo'rg'ontepa",
    lat: 40.73396,
    lon: 72.76286,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['кургантепинский', 'qorgontepa'],
  ),
  Place(
    name: "Ulug'nor",
    lat: 40.74586,
    lon: 71.703,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['улугнорский', 'ulugnor'],
  ),
  Place(
    name: "Xo'jaobod",
    lat: 40.666,
    lon: 72.56819,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['ходжаабадский', 'xojaobod'],
  ),
  Place(
    name: 'Xonobod',
    lat: 40.80103,
    lon: 72.98665,
    region: 'Andijon',
    kind: PlaceKind.district,
    aliases: ['ханабад'],
  ),
  Place(
    name: 'Jondor',
    lat: 39.74084,
    lon: 64.1818,
    region: 'Buxoro',
    kind: PlaceKind.district,
    aliases: ['джандарский'],
  ),
  Place(
    name: 'Olot',
    lat: 39.41808,
    lon: 63.8071,
    region: 'Buxoro',
    kind: PlaceKind.district,
    aliases: ['алатский'],
  ),
  Place(
    name: 'Peshku',
    lat: 40.03471,
    lon: 64.39009,
    region: 'Buxoro',
    kind: PlaceKind.district,
    aliases: ['пешкунский'],
  ),
  Place(
    name: 'Qiziltepa',
    lat: 40.03611,
    lon: 64.84476,
    region: 'Buxoro',
    kind: PlaceKind.district,
    aliases: ['кызылтепинский'],
  ),
  Place(
    name: "Qorako'l",
    lat: 39.51868,
    lon: 63.84247,
    region: 'Buxoro',
    kind: PlaceKind.district,
    aliases: ['каракульский', 'qorakol'],
  ),
  Place(
    name: 'Qorovulbozor',
    lat: 39.49726,
    lon: 64.78329,
    region: 'Buxoro',
    kind: PlaceKind.district,
    aliases: ['караулбазарский'],
  ),
  Place(
    name: 'Romitan',
    lat: 39.93316,
    lon: 64.38268,
    region: 'Buxoro',
    kind: PlaceKind.district,
    aliases: ['рамитанский'],
  ),
  Place(
    name: 'Shofirkon',
    lat: 40.11862,
    lon: 64.50223,
    region: 'Buxoro',
    kind: PlaceKind.district,
    aliases: ['шафирканский'],
  ),
  Place(
    name: 'Vobkent',
    lat: 40.02118,
    lon: 64.51813,
    region: 'Buxoro',
    kind: PlaceKind.district,
    aliases: ['вабкентский'],
  ),
  Place(
    name: "Bag'dod",
    lat: 40.46103,
    lon: 71.21218,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['багдадский', 'bagdod'],
  ),
  Place(
    name: 'Beshariq',
    lat: 40.43799,
    lon: 70.60395,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['бешарыкский'],
  ),
  Place(
    name: 'Buvayda',
    lat: 40.55661,
    lon: 71.14305,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['бувайдинский'],
  ),
  Place(
    name: "Dang'ara",
    lat: 40.5781,
    lon: 70.92124,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['дангаринский', 'dangara'],
  ),
  Place(
    name: 'Furqat',
    lat: 40.4833,
    lon: 70.77759,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['фуркатский'],
  ),
  Place(
    name: "O'zbekiston",
    lat: 40.37635,
    lon: 70.81454,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['узбекистанский', 'ozbekiston'],
  ),
  Place(
    name: 'Oltiariq',
    lat: 40.3916,
    lon: 71.47541,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['алтыарыкский'],
  ),
  Place(
    name: "Qo'shtepa",
    lat: 40.52342,
    lon: 71.65481,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['куштепинский', 'qoshtepa'],
  ),
  Place(
    name: 'Quva',
    lat: 40.52514,
    lon: 72.07128,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['кувинский'],
  ),
  Place(
    name: "So'x",
    lat: 39.97729,
    lon: 71.12946,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['сохский', 'sox'],
  ),
  Place(
    name: 'Toshloq',
    lat: 40.48567,
    lon: 71.75896,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['ташлакский'],
  ),
  Place(
    name: "Uchko'prik",
    lat: 40.54562,
    lon: 71.05593,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['учкуприкский', 'uchkoprik'],
  ),
  Place(
    name: 'Yozyovon',
    lat: 40.66217,
    lon: 71.73056,
    region: "Farg'ona",
    kind: PlaceKind.district,
    aliases: ['язъяванский'],
  ),
  Place(
    name: 'Arnasoy',
    lat: 40.49426,
    lon: 67.8792,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['арнасайский'],
  ),
  Place(
    name: 'Baxmal',
    lat: 39.74555,
    lon: 67.64838,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['бахмальский'],
  ),
  Place(
    name: "Do'stlik",
    lat: 40.52881,
    lon: 68.03289,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['дустликский', 'dostlik'],
  ),
  Place(
    name: 'Forish',
    lat: 40.41841,
    lon: 67.18134,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['фаришский'],
  ),
  Place(
    name: "G'allaorol",
    lat: 40.02796,
    lon: 67.58929,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['галляаральский', 'gallaorol'],
  ),
  Place(
    name: "Mirzacho'l",
    lat: 40.66312,
    lon: 68.17063,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['мирзачульский', 'mirzachol'],
  ),
  Place(
    name: 'Paxtakor',
    lat: 40.31148,
    lon: 67.96127,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['пахтакорский'],
  ),
  Place(
    name: 'Sharof Rashidov',
    lat: 40.21295,
    lon: 67.91222,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['шараф рашидов'],
  ),
  Place(
    name: 'Yangiobod',
    lat: 39.91203,
    lon: 68.78472,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['янгиабадский'],
  ),
  Place(
    name: 'Zafarobod',
    lat: 40.39186,
    lon: 67.82335,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['зафарабадский'],
  ),
  Place(
    name: 'Zarbdor',
    lat: 40.08969,
    lon: 68.1687,
    region: 'Jizzax',
    kind: PlaceKind.district,
    aliases: ['зарбдарский'],
  ),
  Place(
    name: 'Chortoq',
    lat: 41.07142,
    lon: 71.81898,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['чартакский'],
  ),
  Place(
    name: 'Davlatobod',
    lat: 41.00223,
    lon: 71.60902,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['давлатабадский'],
  ),
  Place(
    name: 'Kosonsoy',
    lat: 41.25287,
    lon: 71.54463,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['касансайский'],
  ),
  Place(
    name: 'Mingbuloq',
    lat: 40.8609,
    lon: 71.45984,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['мингбулакский'],
  ),
  Place(
    name: 'Norin',
    lat: 40.91654,
    lon: 72.11856,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['нарынский'],
  ),
  Place(
    name: 'Pop',
    lat: 40.87437,
    lon: 71.09702,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['папский'],
  ),
  Place(
    name: "To'raqo'rg'on",
    lat: 40.99911,
    lon: 71.50886,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['туракурганский', 'toraqorgon'],
  ),
  Place(
    name: "Uchqo'rg'on",
    lat: 41.11456,
    lon: 72.07763,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['учкурганский', 'uchqorgon'],
  ),
  Place(
    name: 'Uychi',
    lat: 41.03037,
    lon: 71.85138,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['уйчинский'],
  ),
  Place(
    name: 'Yangi Namangan',
    lat: 41.0738,
    lon: 71.67398,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['янгинаманганский'],
  ),
  Place(
    name: "Yangiqo'rg'on",
    lat: 41.18894,
    lon: 71.72574,
    region: 'Namangan',
    kind: PlaceKind.district,
    aliases: ['янгикурганский', 'yangiqorgon'],
  ),
  Place(
    name: "G'ozg'on",
    lat: 40.58344,
    lon: 65.47945,
    region: 'Navoiy',
    kind: PlaceKind.district,
    aliases: ['газган', 'gozgon'],
  ),
  Place(
    name: 'Karmana',
    lat: 40.14106,
    lon: 65.36085,
    region: 'Navoiy',
    kind: PlaceKind.district,
    aliases: ['карманинский'],
  ),
  Place(
    name: 'Konimex',
    lat: 40.27791,
    lon: 65.14274,
    region: 'Navoiy',
    kind: PlaceKind.district,
    aliases: ['канимехский'],
  ),
  Place(
    name: 'Navbahor',
    lat: 40.24335,
    lon: 65.29713,
    region: 'Navoiy',
    kind: PlaceKind.district,
    aliases: ['навбахорский'],
  ),
  Place(
    name: 'Tomdi',
    lat: 41.75368,
    lon: 64.62351,
    region: 'Navoiy',
    kind: PlaceKind.district,
    aliases: ['тамдынский'],
  ),
  Place(
    name: 'Chiroqchi',
    lat: 39.03341,
    lon: 66.5758,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['чиракчинский'],
  ),
  Place(
    name: 'Dehqonobod',
    lat: 38.33953,
    lon: 66.57331,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['дехканабадский'],
  ),
  Place(
    name: "G'uzor",
    lat: 38.62154,
    lon: 66.25254,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['гузарский', 'guzor'],
  ),
  Place(
    name: 'Kasbi',
    lat: 38.92358,
    lon: 65.40261,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['касбийский'],
  ),
  Place(
    name: "Ko'kdala",
    lat: 39.22232,
    lon: 66.16312,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['кокдалинский', 'kokdala'],
  ),
  Place(
    name: 'Mirishkor',
    lat: 38.85021,
    lon: 65.27115,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['миришкорский'],
  ),
  Place(
    name: 'Muborak',
    lat: 39.26155,
    lon: 65.15805,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['мубарекский'],
  ),
  Place(
    name: 'Nishon',
    lat: 38.64773,
    lon: 65.69152,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['нишанский'],
  ),
  Place(
    name: 'Qamashi',
    lat: 38.81565,
    lon: 66.46656,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['камашинский'],
  ),
  Place(
    name: "Yakkabog'",
    lat: 38.97846,
    lon: 66.68309,
    region: 'Qashqadaryo',
    kind: PlaceKind.district,
    aliases: ['яккабагский', 'yakkabog'],
  ),
  Place(
    name: 'Amudaryo',
    lat: 42.11617,
    lon: 60.06251,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['амударьинский'],
  ),
  Place(
    name: 'Bozataw',
    lat: 43.00612,
    lon: 59.35545,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['бозатауский'],
  ),
  Place(
    name: "Ellikqal'a",
    lat: 41.83938,
    lon: 60.91245,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['элликкалинский', 'ellikqala'],
  ),
  Place(
    name: 'Kegeili',
    lat: 42.77465,
    lon: 59.61155,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['кегейлийский'],
  ),
  Place(
    name: 'Moynoq',
    lat: 43.76433,
    lon: 59.02975,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['муйнакский'],
  ),
  Place(
    name: 'Nókis qalası hákimiyatı',
    lat: 42.46002,
    lon: 59.61766,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['нукусский горхокимият', 'nokis qalas hakimiyat'],
  ),
  Place(
    name: "Qo'ng'irot",
    lat: 43.04573,
    lon: 58.84754,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['кунградский', 'qongirot'],
  ),
  Place(
    name: "Qonliko'l",
    lat: 42.83615,
    lon: 59.00647,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['канликульский', 'qonlikol'],
  ),
  Place(
    name: "Qorao'zak",
    lat: 43.02869,
    lon: 60.01601,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['караузякский', 'qoraozak'],
  ),
  Place(
    name: 'Shumanay',
    lat: 42.63723,
    lon: 58.92975,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['шуманайский'],
  ),
  Place(
    name: 'Taxiatosh',
    lat: 42.33466,
    lon: 59.5792,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['тахиаташский'],
  ),
  Place(
    name: "Taxtako'pir",
    lat: 43.02072,
    lon: 60.28933,
    region: "Qoraqalpog'iston",
    kind: PlaceKind.district,
    aliases: ['тахтакупырский', 'taxtakopir'],
  ),
  Place(
    name: "Bulung'ur",
    lat: 39.76003,
    lon: 67.27607,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['булунгурский', 'bulungur'],
  ),
  Place(
    name: 'Ishtixon',
    lat: 39.96522,
    lon: 66.48402,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['иштыханский'],
  ),
  Place(
    name: 'Jomboy',
    lat: 39.6946,
    lon: 67.1012,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['джамбайский'],
  ),
  Place(
    name: 'Narpay',
    lat: 39.92419,
    lon: 65.93023,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['нарпайский'],
  ),
  Place(
    name: 'Nurobod',
    lat: 39.60934,
    lon: 66.29117,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['нурабадский'],
  ),
  Place(
    name: 'Oqdaryo',
    lat: 39.87974,
    lon: 66.75354,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['акдарьинский'],
  ),
  Place(
    name: "Past Darg'om",
    lat: 39.71075,
    lon: 66.6613,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['паст даргамский', 'past dargom'],
  ),
  Place(
    name: 'Paxtachi',
    lat: 40.03044,
    lon: 65.66724,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['пахтачийский'],
  ),
  Place(
    name: 'Payariq',
    lat: 39.99088,
    lon: 66.84995,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['пайарыкский'],
  ),
  Place(
    name: "Qo'shrabot",
    lat: 40.24289,
    lon: 66.65396,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['кошрабатский', 'qoshrabot'],
  ),
  Place(
    name: 'Toyloq',
    lat: 39.60245,
    lon: 67.09169,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['тайлакский'],
  ),
  Place(
    name: 'Ugrut',
    lat: 39.40924,
    lon: 67.24942,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['ургутский'],
  ),
  Place(
    name: 'Xatirchi',
    lat: 40.03097,
    lon: 65.9695,
    region: 'Samarqand',
    kind: PlaceKind.district,
    aliases: ['хатырчинский'],
  ),
  Place(
    name: 'Boyovut',
    lat: 40.2803,
    lon: 69.0261,
    region: 'Sirdaryo',
    kind: PlaceKind.district,
    aliases: ['баяутский'],
  ),
  Place(
    name: 'Mirzaobod',
    lat: 40.49627,
    lon: 68.70101,
    region: 'Sirdaryo',
    kind: PlaceKind.district,
    aliases: ['мирзаабадский'],
  ),
  Place(
    name: 'Oqoltin',
    lat: 40.54337,
    lon: 68.4111,
    region: 'Sirdaryo',
    kind: PlaceKind.district,
    aliases: ['акалтынский'],
  ),
  Place(
    name: 'Sardoba',
    lat: 40.33881,
    lon: 68.18315,
    region: 'Sirdaryo',
    kind: PlaceKind.district,
    aliases: ['сардобинский'],
  ),
  Place(
    name: 'Sayxunobod',
    lat: 40.71025,
    lon: 68.84642,
    region: 'Sirdaryo',
    kind: PlaceKind.district,
    aliases: ['сайхунабадский'],
  ),
  Place(
    name: 'Sirdaryo',
    lat: 40.83091,
    lon: 68.66619,
    region: 'Sirdaryo',
    kind: PlaceKind.district,
    aliases: ['сырдарьинский'],
  ),
  Place(
    name: 'Xovos',
    lat: 40.21441,
    lon: 68.83871,
    region: 'Sirdaryo',
    kind: PlaceKind.district,
    aliases: ['хавастский'],
  ),
  Place(
    name: 'Angor',
    lat: 37.46242,
    lon: 67.15176,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['ангорский'],
  ),
  Place(
    name: 'Bandixon',
    lat: 37.86083,
    lon: 67.38835,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['бандиханский'],
  ),
  Place(
    name: "Jarqo'rg'on",
    lat: 37.50916,
    lon: 67.42065,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['джаркурганский', 'jarqorgon'],
  ),
  Place(
    name: 'Muzrabot',
    lat: 37.46073,
    lon: 66.92612,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['музрабадский'],
  ),
  Place(
    name: 'Oltinsoy',
    lat: 38.19341,
    lon: 67.68381,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['алтынсайский'],
  ),
  Place(
    name: 'Qiziriq',
    lat: 37.6701,
    lon: 67.23578,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['кизирикский'],
  ),
  Place(
    name: "Qumqo'rg'on",
    lat: 37.82932,
    lon: 67.59496,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['кумкурганский', 'qumqorgon'],
  ),
  Place(
    name: 'Sariosiyo',
    lat: 38.41305,
    lon: 67.95694,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['сариасийский'],
  ),
  Place(
    name: 'Sherobod',
    lat: 37.67112,
    lon: 67.01663,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['шерабадский'],
  ),
  Place(
    name: "Sho'rchi",
    lat: 37.99816,
    lon: 67.79085,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['шурчинский', 'shorchi'],
  ),
  Place(
    name: 'Uzun',
    lat: 38.36537,
    lon: 68.00667,
    region: 'Surxondaryo',
    kind: PlaceKind.district,
    aliases: ['узунский'],
  ),
  Place(
    name: 'Shayhontohur',
    lat: 41.32486,
    lon: 69.21738,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['шайхантахурский'],
  ),
  Place(
    name: 'Yangi Toshkent',
    lat: 41.23928,
    lon: 69.40635,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['янгиташкентский'],
  ),
  Place(
    name: 'Yangi hayot',
    lat: 41.20214,
    lon: 69.24065,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['янгихаётский'],
  ),
  Place(
    name: 'Yuqorichirchiq',
    lat: 41.25638,
    lon: 69.52452,
    region: 'Toshkent shahri',
    kind: PlaceKind.district,
    aliases: ['юкарычирчикский'],
  ),
  Place(
    name: "Bo'ka",
    lat: 40.73695,
    lon: 69.16274,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['букинский', 'boka'],
  ),
  Place(
    name: "Bo'stonliq",
    lat: 41.56294,
    lon: 69.77077,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['бостанлыкский', 'bostonliq'],
  ),
  Place(
    name: 'Nurafshon (Toytepa)',
    lat: 41.02808,
    lon: 69.34596,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['нурафшан (тойтепа)'],
  ),
  Place(
    name: "O'rtachirchiq",
    lat: 41.04292,
    lon: 69.35785,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['уртачирчикский', 'ortachirchiq'],
  ),
  Place(
    name: "Oqqo'rg'on",
    lat: 40.83072,
    lon: 69.06413,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['аккурганский', 'oqqorgon'],
  ),
  Place(
    name: 'Parkent',
    lat: 41.29226,
    lon: 69.66903,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['паркентский'],
  ),
  Place(
    name: 'Piskent',
    lat: 40.80889,
    lon: 69.49911,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['пскентский'],
  ),
  Place(
    name: 'Qibray',
    lat: 41.51834,
    lon: 69.51655,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['кибрайский'],
  ),
  Place(
    name: 'Quyichirchiq',
    lat: 40.98026,
    lon: 68.98165,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['куйичирчикский'],
  ),
  Place(
    name: 'Zangiota',
    lat: 41.26285,
    lon: 69.11276,
    region: 'Toshkent viloyati',
    kind: PlaceKind.district,
    aliases: ['зангиатинский'],
  ),
  Place(
    name: "Bog'ot",
    lat: 41.35724,
    lon: 60.81851,
    region: 'Xorazm',
    kind: PlaceKind.district,
    aliases: ['багатский', 'bogot'],
  ),
  Place(
    name: 'Gurlan',
    lat: 41.84472,
    lon: 60.38988,
    region: 'Xorazm',
    kind: PlaceKind.district,
    aliases: ['гурленский'],
  ),
  Place(
    name: 'Hazorasp',
    lat: 41.31122,
    lon: 61.08919,
    region: 'Xorazm',
    kind: PlaceKind.district,
    aliases: ['хазараспский'],
  ),
  Place(
    name: 'Qoshkopir',
    lat: 41.53372,
    lon: 60.35191,
    region: 'Xorazm',
    kind: PlaceKind.district,
    aliases: ['кошкупырский'],
  ),
  Place(
    name: 'Showot',
    lat: 41.66071,
    lon: 60.29237,
    region: 'Xorazm',
    kind: PlaceKind.district,
    aliases: ['шаватский'],
  ),
  Place(
    name: "Tuproqqal'a",
    lat: 41.21597,
    lon: 61.31391,
    region: 'Xorazm',
    kind: PlaceKind.district,
    aliases: ['тупроккалинский', 'tuproqqala'],
  ),
  Place(
    name: 'Xonqa',
    lat: 41.48112,
    lon: 60.80877,
    region: 'Xorazm',
    kind: PlaceKind.district,
    aliases: ['ханкинский'],
  ),
  Place(
    name: 'Yangiariq',
    lat: 41.36677,
    lon: 60.60598,
    region: 'Xorazm',
    kind: PlaceKind.district,
    aliases: ['янгиарыкский'],
  ),
  Place(
    name: 'Yangibozor',
    lat: 41.71096,
    lon: 60.53109,
    region: 'Xorazm',
    kind: PlaceKind.district,
    aliases: ['янгибазарский'],
  ),
];

// O'zbekcha kelishik qo'shimchalari (uzunidan boshlab) — "Toshkentdan" -> "Toshkent".
const _caseSuffixes = [
  'gacha',
  'ning',
  'niki',
  'dan',
  'ga',
  'ka',
  'qa',
  'da',
  'ta',
  'ni',
];

final _adminSuffix = RegExp(
  r'\s+(shahri|shahar|viloyati|viloyat|tumani|tuman|district|region|city|oblast)$',
  caseSensitive: false,
);

final _apostrophes = RegExp(r"[ʻʼ'`ʹ‘’]");

/// Har xil apostrofni BITTA standartga (`'`, U+0027) keltiradi.
///
/// 🔴 NEGA (2026-08-20, egasi qurilmada: "marshrut belgilashda simbollar
/// qo'shib yuboryapti"): OpenStreetMap/Nominatim o'zbekcha nomlarni
/// "modifier letter" apostrofi bilan qaytaradi — `Fargʻona` (U+02BB),
/// `Qoʼqon` (U+02BC), ba'zan `'`/`'` (U+2018/2019). Bu belgilar ko'p
/// qurilmada g'alati simbol yoki bo'sh kvadrat bo'lib ko'rinadi va
/// klaviaturada yo'q. Curated ro'yxatimiz esa oddiy `'` (U+0027)
/// ishlatadi. Geocoder natijasini shu standartga keltirsak: nom
/// tanish ko'rinadi VA curated bilan bir xil bo'ladi.
String normalizeApostrophe(String input) => input.replaceAll(_apostrophes, "'");

/// Ma'muriy qo'shimchani kesadi, REGISTR SAQLANADI:
/// "Chortoq tumani" -> "Chortoq", "Toshkent shahri" -> "Toshkent".
/// `_normalize` dan farqi: bu ko'rsatish uchun (kichik harfga o'tkazmaydi).
String stripAdminSuffix(String input) =>
    input.replaceAll(_adminSuffix, '').trim();

/// Taqqoslash kaliti: kichik harf, apostrofsiz, ma'muriy qo'shimchasiz.
/// "Chilonzor tumani" -> "chilonzor", "Farg'ona" -> "fargona".
String _normalize(String input) {
  var s = input.toLowerCase().trim();
  s = s.split(',').first.trim();
  s = s.replaceAll(_apostrophes, '');
  s = s.replaceAll(_adminSuffix, '').trim();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s;
}

/// O'ZBEK KIRILLIDAN LOTINGA: "Тошкентдан" -> "toshkentdan".
///
/// 🔴 NEGA YOZILDI (egasi, 2026-08-25: «ovozdan olingan natija qidiruvga
/// qo'yilmayapti»): joylar ro'yxatida faqat LOTIN nomlar va RUSCHA nomlar
/// bor edi. O'ZBEK KIRILLI umuman yo'q. O'lchab ko'rildi — quyidagilarning
/// HECH BIRI topilmasdi:
///
///   Тошкент, Бухоро, Андижон, Фарғона, Қўқон, Урганч, Қарши, Термиз,
///   Жиззах, Гулистон, Навоий, Чирчиқ, Олмалиқ, Бекобод, Самарқанд
///
/// Ishlaganlari faqat ruscha yozilishi bilan ustma-ust tushganlari edi
/// (Самарканд, Наманган, Нукус, Хива, Ангрен) — ya'ni ishlagandek
/// KO'RINARDI va shuning uchun xato uzoq payqalmadi.
///
/// Bu ikki joyni birdan buzardi:
///   1. OVOZ — Android nutqni tanish `uz` tilida aynan KIRILL qaytaradi.
///      Ya'ni o'zbekcha aytilgan yo'nalish deyarli har doim tanilmasdi va
///      qidiruvga QO'YILMASDI.
///   2. KLAVIATURA — kirillda yozadigan odam (aynan keksa foydalanuvchi)
///      shaharni umuman topa olmasdi.
///
/// ⚠️ Ruscha nomlarga TEGMAYDI: bu funksiya faqat aniq mos kelish va
/// kelishik kesish MUVAFFAQIYATSIZ bo'lgandan keyin ishlaydi
/// ([resolvePlaceDetailed] ga qarang), ya'ni "Ташкент" avvalgidek
/// alias orqali topiladi.
///
/// ⚠️ Web'dagi juftligi: `src/shared/data/uzCities.ts` dagi `uzLatinise`.
/// Birida o'zgartirsang — ikkinchisida ham.
const _uzCyrillicToLatin = {
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'ғ': 'g',
  'д': 'd',
  'е': 'e',
  'ё': 'yo',
  'ж': 'j',
  'з': 'z',
  'и': 'i',
  'й': 'y',
  'к': 'k',
  'қ': 'q',
  'л': 'l',
  'м': 'm',
  'н': 'n',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'у': 'u',
  'ў': 'o',
  'ф': 'f',
  'х': 'x',
  'ҳ': 'h',
  'ц': 'ts',
  'ч': 'ch',
  'ш': 'sh',
  'щ': 'sh',
  'ъ': '',
  'ы': 'i',
  'ь': '',
  'э': 'e',
  'ю': 'yu',
  'я': 'ya',
};

final _anyCyrillic = RegExp(r'[\u0400-\u04FF]');

/// Kirill harflarni lotinga o'giradi. Kirill yo'q bo'lsa matn O'ZGARMAYDI —
/// lotin yozuv hech qachon bu funksiyadan zarar ko'rmaydi.
String uzLatinise(String input) {
  if (!_anyCyrillic.hasMatch(input)) return input;
  final out = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    out.write(_uzCyrillicToLatin[ch] ?? ch);
  }
  return out.toString();
}

/// Kelishik qo'shimchasini olib tashlaydi: "toshkentga" -> "toshkent".
String _stripCase(String key) {
  for (final suffix in _caseSuffixes) {
    if (key.length > suffix.length + 2 && key.endsWith(suffix)) {
      return key.substring(0, key.length - suffix.length);
    }
  }
  return key;
}

final Map<String, Place> _lookup = {
  for (final place in kPlaces) ...{
    _normalize(place.name): place,
    for (final alias in place.aliases) _normalize(alias): place,
  },
};

/// Nomni (yozilishidan qat'i nazar) barqaror joyga aylantiradi.
/// Topilmasa null — chaqiruvchi foydalanuvchidan ro'yxatdan tanlashni so'raydi.
/// 🔴 [resolvePlaceDetailed] ga TAYANADI (2026-08-25): ilgari bu funksiya
/// o'zining qisqartirilgan mantig'iga ega edi — kirill taxminini ham,
/// kirilldan lotinga o'girishni ham bilmasdi. Natijada bir xil matn
/// qidiruvda topilib, boshqa joyda topilmasdi. Ikki manba = ikki xil javob.
Place? resolvePlace(String name) => resolvePlaceDetailed(name)?.place;

/// Mos kelgan joy VA nom qanday topilgani.
///
/// [caseSuffix] — kesilgan kelishik qo'shimchasi (`dan`, `ga`, ...) yoki
/// `null`. Ovozli yo'nalish tahlili (`core/voice_route.dart`) yo'nalishni
/// aynan shundan biladi: "Toshkent**dan**" — jo'nash, "Samarqand**ga**" —
/// manzil.
class PlaceMatch {
  const PlaceMatch(this.place, this.caseSuffix);

  final Place place;
  final String? caseSuffix;
}

/// [resolvePlace] ning kengaytirilgan varianti — qo'shimchani ham qaytaradi.
///
/// TO'RT bosqich, shu tartibda (aniqdan taxminiyga):
///   1. AYNAN mos kelish — shuning uchun nomning o'zi shu harflar bilan
///      tugasa ("Nuro**ta**") u qo'shimcha deb hisoblanmaydi;
///   2. kelishik qo'shimchasini kesib ko'rish (lotin yozuvi uchun aniq);
///   3. O'ZBEK KIRILLIDAN lotinga o'girib, 1–2 ni qaytadan ([uzLatinise]);
///   4. KIRILL uchun taxminiy o'zak moslash — ruscha kelishiklarni
///      ("Ташкент**а**", "Бухар**у**") ro'yxat bilan sanab bo'lmaydi.
///      Farq ikkala tomonda ham 2 harfdan oshmasa — o'sha joy.
///      Bu FAQAT kirillga tegishli: lotin nomlarda taxmin qilish shart emas
///      va noto'g'ri shahar berishi mumkin.
PlaceMatch? resolvePlaceDetailed(String name) {
  if (name.isEmpty) return null;
  final key = _normalize(name);
  if (key.isEmpty) return null;

  final exact = _lookup[key];
  if (exact != null) return PlaceMatch(exact, null);

  final stripped = _stripCase(key);
  final hit = _lookup[stripped];
  if (hit != null) {
    return PlaceMatch(hit, key.substring(stripped.length));
  }

  // 3. O'ZBEK KIRILLI -> lotin. Taxminiy moslashdan (4-bosqich) OLDIN
  //    turadi: o'girish ANIQ, taxmin esa taxmin. "Тошкентдан" bu yerda
  //    "toshkentdan" bo'ladi va kelishik ham to'g'ri kesiladi — ovozli
  //    yo'nalish yo'nalishni aynan shu qo'shimchadan biladi.
  final latin = _normalize(uzLatinise(key));
  if (latin != key) {
    final latinExact = _lookup[latin];
    if (latinExact != null) return PlaceMatch(latinExact, null);

    final latinStripped = _stripCase(latin);
    final latinHit = _lookup[latinStripped];
    if (latinHit != null) {
      return PlaceMatch(latinHit, latin.substring(latinStripped.length));
    }
  }

  if (!_cyrillicOnly.hasMatch(key)) return null;
  for (final entry in _lookup.entries) {
    if (!_cyrillicOnly.hasMatch(entry.key)) continue;
    var shared = 0;
    while (shared < key.length &&
        shared < entry.key.length &&
        key.codeUnitAt(shared) == entry.key.codeUnitAt(shared)) {
      shared++;
    }
    if (shared >= 5 &&
        entry.key.length - shared <= 2 &&
        key.length - shared <= 2) {
      return PlaceMatch(entry.value, null);
    }
  }
  return null;
}

final _cyrillicOnly = RegExp(r'^[Ѐ-ӿ\s]+$');

/// Koordinataga eng yaqin joy.
///
/// Backend ba'zi obyektlarda (posilka) manzil MATNINI umuman saqlamaydi —
/// faqat lat/lon beradi. Foydalanuvchiga raqam ko'rsatib bo'lmaydi, shuning
/// uchun eng yaqin ma'lum joy nomi bilan taxminlaymiz. [maxKm] dan uzoq
/// bo'lsa `null` — noto'g'ri shahar nomini ko'rsatgandan ko'ra hech nima
/// ko'rsatmagan yaxshi.
Place? nearestPlace(double lat, double lon, {double maxKm = 60}) {
  Place? best;
  var bestKm = double.infinity;
  for (final place in kPlaces) {
    final km = distanceKm(
      fromLat: lat,
      fromLon: lon,
      toLat: place.lat,
      toLon: place.lon,
    );
    if (km < bestKm) {
      bestKm = km;
      best = place;
    }
  }
  return bestKm <= maxKm ? best : null;
}

/// Posilka nuqtasining nomi.
///
/// Jo'natuvchi yozgan MATN ustun: backend 2026-08-07 dan `from_address` /
/// `to_address` ni saqlaydi va odam aynan o'sha nomni kutadi. Matn bo'lmasa
/// (o'sha sanadan oldingi yozuvlar) koordinatadan eng yaqin joy topiladi —
/// bu taxminiy, shuning uchun faqat zaxira.
///
/// Ikkala posilka ekranida ham SHU funksiya ishlatiladi: ilgari har birida
/// o'z nusxasi bor edi va ular bir-biridan chetga chiqib ketishi mumkin edi.
String placeLabel(String? address, double lat, double lon) {
  final text = address?.trim();
  if (text != null && text.isNotEmpty) return text;
  return nearestPlace(lat, lon)?.name ?? '—';
}

/// Qidiruv: avval nomi shu bilan BOSHLANADIGANLAR, keyin ichida uchraydiganlar.
List<Place> searchPlaces(String query, {int limit = 30}) {
  final normalized = _normalize(query);
  if (normalized.isEmpty) return kPlaces.take(limit).toList();

  // Ikki kalit bo'yicha izlaymiz: yozilgani va uning LOTIN o'girmasi.
  // Kirillda yozadigan odam ("тошкент") ilgari HECH NIMA topmasdi —
  // ro'yxatdagi kalitlar lotin, uning so'rovi esa kirill edi.
  final queries = <String>{_stripCase(normalized)};
  final latin = _normalize(uzLatinise(normalized));
  if (latin != normalized) queries.add(_stripCase(latin));
  queries.removeWhere((q) => q.isEmpty);
  if (queries.isEmpty) return kPlaces.take(limit).toList();

  final starts = <Place>[];
  final contains = <Place>[];
  for (final place in kPlaces) {
    final keys = [_normalize(place.name), ...place.aliases.map(_normalize)];
    if (keys.any((k) => queries.any(k.startsWith))) {
      starts.add(place);
    } else if (keys.any((k) => queries.any(k.contains))) {
      contains.add(place);
    }
  }
  return [...starts, ...contains].take(limit).toList();
}

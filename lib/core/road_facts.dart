/// YO'L HAMROHI — «hozir qayerdan o'tyapmiz» va o'sha joy haqida bir gap.
///
/// 🔴 NEGA YOZILDI (egasi, 2026-08-27): Toshkent–Samarqand yo'li to'rt
/// soat, Buxoroga esa oltidan oshadi. Odam zerikadi — lekin ZERIKISH
/// eng kuchli paytda internet ham YO'Q: shaharlararo yo'lda antena
/// chiqmaydi. Ya'ni serverga tayanadigan har qanday ovunchoq aynan
/// kerak paytda ishlamaydi.
///
/// Shuning uchun bu yerdagi hamma narsa QURILMADA: joylar ro'yxati
/// (`cities.dart`, 202 ta yozuv) allaqachon ilova ichida, matnlar ham
/// shu faylda. Tarmoqqa BIRORTA so'rov ketmaydi.
///
/// ⚠️ HAYDOVCHI UCHUN EMAS. Karta faqat yo'lovchi ekranida chiziladi va
/// ovoz bilan o'qilishi mumkin (`ttsEnabled`). Haydovchi to'rt soat
/// telefonga qaramaydi va qaramasligi ham kerak.
///
/// ⚠️ FAQAT ROST GAPLAR. Har yozuv tekshirilishi mumkin bo'lgan, keng
/// ma'lum fakt: nima bilan mashhur, nimasi bor. «Eng go'zal shahar»
/// kabi baholar YO'Q — ular reklama bo'lib eshitiladi va ishonchni
/// yo'qotadi. Joy haqida aytadigan rost gapimiz bo'lmasa — SUKUT.
library;

import 'dart:math' as math;

import '../l10n/strings.dart';
import '../l10n/cyrillic.dart';
import 'cities.dart';

/// Bitta joy haqidagi gap — uch tilda.
class RoadFact {
  const RoadFact(this.uz, this.ru, this.en);

  final String uz;
  final String ru;
  final String en;

  String forLang(Lang lang) => switch (lang) {
    Lang.uz => uz,
    // Yo'l haqidagi gaplar ham kirillda o'qiladi — ular ovoz bilan
    // ham aytiladi, ya'ni matn to'g'ri bo'lishi shart.
    Lang.uzCyrl => toCyrillic(uz),
    Lang.ru => ru,
    Lang.en => en,
  };
}

/// Joy nomi (kanonik, `cities.dart` dagidek) → gap.
///
/// Ro'yxat ATAYIN to'liq emas: 202 joyning hammasi haqida aytadigan rost
/// gapimiz yo'q. Yozuv topilmasa karta umuman chizilmaydi (izohi
/// `factFor` da).
const Map<String, RoadFact> _facts = {
  'Toshkent': RoadFact(
    'Markaziy Osiyodagi yagona metro shu yerda — 1977-yilda ochilgan.',
    'Здесь единственное метро в Центральной Азии — открыто в 1977 году.',
    'Home to Central Asia\'s only metro, opened in 1977.',
  ),
  'Samarqand': RoadFact(
    'Registon maydonidagi uch madrasa uch xil asrda qurilgan.',
    'Три медресе на Регистане построены в разные века.',
    'The three madrasas on Registan were built in different centuries.',
  ),
  'Buxoro': RoadFact(
    'Eski shahar deyarli butunligicha saqlangan — UNESCO ro\'yxatida.',
    'Старый город сохранился почти целиком — в списке ЮНЕСКО.',
    'Its old town survives almost intact and is UNESCO-listed.',
  ),
  'Xiva': RoadFact(
    'Ichan Qal\'a — devor bilan o\'ralgan butun bir shahar ichida shahar.',
    'Ичан-Кала — целый город внутри крепостных стен.',
    'Ichan Qala is an entire walled city within the city.',
  ),
  'Shahrisabz': RoadFact(
    'Amir Temurning tug\'ilgan yeri; Oqsaroy darvozasi shu yerda.',
    'Родина Амира Темура; здесь стоят ворота Аксарая.',
    'Amir Temur\'s birthplace; the Oqsaroy gate stands here.',
  ),
  'Jizzax': RoadFact(
    'Toshkent–Samarqand yo\'lining yarmi — ko\'pchilik shu yerda to\'xtaydi.',
    'Середина пути Ташкент–Самарканд — здесь чаще всего делают остановку.',
    'The midpoint of the Tashkent–Samarkand road, and a common stop.',
  ),
  'Guliston': RoadFact(
    'Sirdaryo viloyati markazi, Mirzacho\'l dashti chekkasida.',
    'Центр Сырдарьинской области, у края Голодной степи.',
    'Capital of Sirdaryo region, at the edge of the Mirzachol steppe.',
  ),
  'Navoiy': RoadFact(
    'Sanoat shahri — 1958-yilda deyarli noldan qurilgan.',
    'Промышленный город, построенный почти с нуля в 1958 году.',
    'An industrial city built almost from scratch in 1958.',
  ),
  'Qarshi': RoadFact(
    'Qashqadaryo markazi; nomi turkiycha «qal\'a» so\'zidan.',
    'Центр Кашкадарьи; название происходит от тюркского «крепость».',
    'Capital of Qashqadaryo; the name comes from a Turkic word for fortress.',
  ),
  'Termiz': RoadFact(
    'Amudaryo bo\'yida, mamlakatning eng janubiy shahri.',
    'На Амударье, самый южный город страны.',
    'On the Amu Darya — the southernmost city in the country.',
  ),
  'Nukus': RoadFact(
    'Savitskiy muzeyida jahonga mashhur avangard to\'plami saqlanadi.',
    'В музее Савицкого хранится всемирно известная коллекция авангарда.',
    'The Savitsky Museum holds a world-famous avant-garde collection.',
  ),
  'Urganch': RoadFact(
    'Xivaga eng yaqin katta shahar — orasi 35 chaqirimcha.',
    'Ближайший крупный город к Хиве — около 35 километров.',
    'The nearest large city to Khiva, about 35 km away.',
  ),
  'Andijon': RoadFact(
    'Bobur shu yerda tug\'ilgan va «Boburnoma»da tug\'ilgan yurtini yozgan.',
    'Здесь родился Бабур, описавший родной край в «Бабур-наме».',
    'Babur was born here and wrote about it in the Baburnama.',
  ),
  'Namangan': RoadFact(
    'Farg\'ona vodiysining eng ko\'p aholili shahri.',
    'Самый населённый город Ферганской долины.',
    'The most populous city in the Fergana Valley.',
  ),
  'Farg\'ona': RoadFact(
    'Vodiyga nom bergan shahar; keng xiyobonlari bilan tanilgan.',
    'Город, давший имя долине; известен широкими аллеями.',
    'The city that gave the valley its name, known for its wide avenues.',
  ),
  'Qo\'qon': RoadFact(
    'Qo\'qon xonligining poytaxti bo\'lgan; Xudoyorxon o\'rdasi saqlangan.',
    'Столица Кокандского ханства; сохранился дворец Худояр-хана.',
    'Capital of the Kokand Khanate; Khudayar Khan\'s palace survives.',
  ),
  'Marg\'ilon': RoadFact(
    'Atlas va adras shu yerda to\'qiladi — hunar asrlar davomida saqlangan.',
    'Здесь ткут атлас и адрас — ремесло сохранялось веками.',
    'Atlas and adras silks are woven here, a craft kept for centuries.',
  ),
  'Rishton': RoadFact(
    'Ko\'k sopol maktabi bilan mashhur — loyi shu yerning o\'zidan.',
    'Славится школой голубой керамики — глина местная.',
    'Famous for its blue ceramics, made from local clay.',
  ),
  'Zomin': RoadFact(
    'Tog\' havosi bilan tanilgan; milliy bog\' shu yerda.',
    'Известен горным воздухом; здесь национальный парк.',
    'Known for its mountain air; the national park is here.',
  ),
  'Angren': RoadFact(
    'Ko\'mir koni ustida o\'sgan shahar; Qamchiq dovoni yo\'li shu yerdan.',
    'Город вырос у угольного разреза; отсюда дорога на перевал Камчик.',
    'Grew around a coal mine; the road to the Qamchiq pass starts here.',
  ),
  'Olmaliq': RoadFact(
    'Mis va rux koni shahri — konchilik markazlaridan biri.',
    'Город медных и цинковых рудников — один из центров горного дела.',
    'A copper and zinc mining town.',
  ),
};

/// Joyni topish uchun eng katta masofa (km).
///
/// 🔑 25 km ATAYIN: yo'l shahar markazidan o'tmaydi, chetlab o'tadi.
/// Kichikroq qilsak katta shaharlar ham «o'tmagan» bo'lib qolardi;
/// kattaroq qilsak esa hali yetib bormagan shahar haqida gapirardik.
const double _maxKm = 25;

/// Ikki nuqta orasidagi masofa (km) — haversine.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Hozirgi nuqtaga eng yaqin JOY — faqat haqida gapimiz bor bo'lganlari.
///
/// ⚠️ Tuman/mahalla darajasidagi yozuvlar CHIQARIB TASHLANADI: yo'lda
/// «Yunusobod tumanidan o'tyapsiz» degan gap ma'nosiz, odam shaharni
/// kutadi.
Place? nearestKnownPlace(double lat, double lon) {
  Place? best;
  var bestKm = _maxKm;
  for (final p in kPlaces) {
    if (p.isDistrict) continue;
    if (!_facts.containsKey(p.name)) continue;
    final km = distanceKm(lat, lon, p.lat, p.lon);
    if (km < bestKm) {
      bestKm = km;
      best = p;
    }
  }
  return best;
}

/// Joy haqidagi gap — bo'lmasa `null`.
///
/// 🔴 `null` bo'lsa chaqiruvchi HECH NIMA chizmasin. «Bu joy haqida
/// ma'lumot yo'q» degan bo'sh karta zerikishni yechmaydi, aksincha
/// ilovani bo'sh ko'rsatadi.
RoadFact? factFor(Place place) => _facts[place.name];

/// Haqida gapimiz bor joylar soni — testlar va sozlamalar uchun.
int get knownFactCount => _facts.length;

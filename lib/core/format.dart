import 'package:intl/intl.dart';

import '../data/models/ride.dart';
import '../l10n/strings.dart';
import '../l10n/cyrillic.dart';

/// Narx: `150000` -> `150 000` (guruh ajratkichi — probel, UZS odati).
String formatPrice(double value) {
  final formatter = NumberFormat.decimalPattern('ru');
  return formatter.format(value.round()).replaceAll(' ', ' ');
}

/// Backend `departure_time` uchun RFC3339 + ANIQ ofset: `2026-07-30T09:00:00+05:00`.
///
/// ⚠ `DateTime.toIso8601String()` lokal vaqtda ofsetni YOZMAYDI
/// (`2026-07-30T09:00:00.000`) — backend uni UTC deb o'qisa safar 5 soat
/// siljib ketadi. Shuning uchun ofsetni o'zimiz qo'shamiz.
String toRfc3339(DateTime dateTime) {
  final local = dateTime.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final base = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(local);
  return '$base$sign$hours:$minutes';
}

/// `30 iyul, 09:00`
///
/// 🔴 2026-08-16: parametr `bool isUz` dan `Lang` ga o'zgardi. Ilova UCH
/// tilni qo'llab-quvvatlaydi (profil sozlamasida "English" ham bor), lekin
/// bu yerdagi ikkilik bayroq "o'zbek emas = rus" degani edi — ingliz
/// tilidagi foydalanuvchi "15 августа" ni ko'rardi. Saytda `isUz` aynan
/// shu sabab butunlay olib tashlangan (2026-08-03).
String formatDateTime(DateTime? dt, Lang lang) {
  if (dt == null) return '—';
  return '${formatDate(dt, lang)}, ${formatTime(dt)}';
}

/// Sana — "9 avgust", boshqa yil bo'lsa "9 avgust 2027".
///
/// 🔴 Nima uchun yil qo'shildi (2026-08-13): tariflar ekranida "Amal qiladi:
/// 9 avgust" turardi va uni O'QIGAN ODAM (men ham) uni O'TGAN sana deb
/// o'yladim — o'sha kuni 13 avgust edi. Aslida sana KEYINGI yilniki edi.
/// Ya'ni yozuv yolg'on emas, lekin ikki xil o'qiladi: "tarifim tugabdi"
/// degan xulosa ham, "hali ko'p vaqt bor" degan xulosa ham chiqadi.
///
/// Joriy yilda yil YOZILMAYDI — kundalik sanalarni ("ertaga, 14 avgust")
/// uzaytirib yuborishning ma'nosi yo'q.
String formatDate(DateTime? dt, Lang lang) {
  if (dt == null) return '—';
  final months = switch (lang) {
    Lang.uz => _monthsUz,
    // ⚠️ AVTOMATIK O'GIRILMAYDI: «sentabr» o'girgichdan «сентабр»
    // bo'lib chiqadi, kirillda esa «сентябр» yoziladi. Oy nomlari —
    // atigi 12 ta so'z, ularni qo'lda yozgan to'g'ri.
    Lang.uzCyrl => _monthsUzCyrl,
    Lang.ru => _monthsRu,
    Lang.en => _monthsEn,
  };
  // Ingliz tilida kun EMAS, oy oldin keladi ("9 August" emas, "August 9").
  final day = lang == Lang.en
      ? '${months[dt.month - 1]} ${dt.day}'
      : '${dt.day} ${months[dt.month - 1]}';
  return dt.year == DateTime.now().year ? day : '$day ${dt.year}';
}

/// Chat sana ajratgichи: bugun -> "Bugun", kecha -> "Kecha", aks holда
/// to'liq sana. Uzun yozishmada xabar qachon yozilganini ajratadi.
String chatDayLabel(DateTime? dt, Lang lang) {
  if (dt == null) return '';
  final now = DateTime.now();
  final d = DateTime(dt.year, dt.month, dt.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) {
    return switch (lang) {
      Lang.uz => 'Bugun',
      Lang.uzCyrl => toCyrillic('Bugun'),
      Lang.ru => 'Сегодня',
      Lang.en => 'Today',
    };
  }
  if (diff == 1) {
    return switch (lang) {
      Lang.uz => 'Kecha',
      Lang.uzCyrl => toCyrillic('Kecha'),
      Lang.ru => 'Вчера',
      Lang.en => 'Yesterday',
    };
  }
  return formatDate(dt, lang);
}

/// Ikki vaqt bir xil KUNDAmi (sana ajratgichi uchun).
bool sameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == b;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatTime(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

const _monthsUz = [
  'yanvar',
  'fevral',
  'mart',
  'aprel',
  'may',
  'iyun',
  'iyul',
  'avgust',
  'sentabr',
  'oktabr',
  'noyabr',
  'dekabr',
];

/// Oy nomlari KIRILLDA — qo'lda yozilgan.
///
/// 🔴 NEGA AVTOMATIK EMAS: o'girgich «sentabr» ni «сентабр» qiladi,
/// kirill imlosida esa «сентябр» yoziladi (shuningdek «октябр»,
/// «ноябр»). Bu — o'girgichning kamchiligi emas, imlo qoidasi: rus
/// tilidan kirgan oy nomlari kirillda o'z ko'rinishini saqlaydi.
/// Atigi 12 so'z, ularni qo'lda yozgan to'g'ri.
const _monthsUzCyrl = [
  'январ',
  'феврал',
  'март',
  'апрел',
  'май',
  'июн',
  'июл',
  'август',
  'сентябр',
  'октябр',
  'ноябр',
  'декабр',
];

const _monthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _monthsRu = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

/// `901234567` -> `+998901234567` (backend shu ko'rinishni kutadi).
String toE164(String localDigits) => '+998$localDigits';

/// `901234567` -> `90 123 45 67`
String formatPhoneDigits(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i == 2 || i == 5 || i == 7) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Ism ko'rsatish uchun — BOSH HARFLAR bilan kelganini yumshatadi.
///
/// 🔴 Nima uchun kerak (egasi qurilmada ko'rdi, 2026-08-13): ism MyID/pasport
/// ma'lumotidan keladi va u yerda hammasi bosh harfda yozilgan —
/// "MUXAMMAD RAXMATILLAYEV". Ilovada bu baqirayotgandek ko'rinadi, ayniqsa
/// suhbatlar ro'yxatida va chat sarlavhasida.
///
/// FAQAT butunlay bosh harfli matn o'zgartiriladi: odam o'zi "Muxammad" deb
/// yozgan bo'lsa yoki ismda ataylab katta harf bo'lsa (masalan "MDH") — unga
/// tegilmaydi, aks holda biz odamning yozganini "tuzatgan" bo'lardik.
String? prettyName(String? raw) {
  final name = raw?.trim();
  if (name == null || name.isEmpty) return raw;
  // Kichik harf BOR bo'lsa — bu odamning o'z yozuvi, tegmaymiz.
  if (name != name.toUpperCase()) return name;

  return name
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        // Apostroflar (O'G'LI) saqlanadi: faqat harflar registri o'zgaradi.
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}

/// JOY TOR BO'LGANDA ism qisqartiriladi: «Abdurahmon Rahmatullayev» →
/// «Abdurahmon R.».
///
/// 🔴 NEGA KERAK (2026-09-02 ko'rigi): yozishma sarlavhasida to'liq ism
/// turardi va u KESILARDI — «Abdurahmon Rahm…». Sarlavhada avatar,
/// ism, qidiruv va menyu bor, ya'ni ismga ~200 piksel qoladi. To'liq
/// familiya u yerga hech qachon sig'maydi.
///
/// Kesilgan familiya hech narsa bermaydi; bosh harf esa BERADI —
/// bir xil ismli ikki odamni ajratishga yetadi.
///
/// ⚠️ Bitta so'zli ism TEGILMAYDI: «Dilnoza» qisqartirilmaydi.
/// ⚠️ Familiya bosh harfi apostrof bilan boshlansa («O'ktam») — u ham
/// saqlanadi, chunki bu harfning bir qismi.
String? shortName(String? raw) {
  final full = prettyName(raw)?.trim();
  if (full == null || full.isEmpty) return full;
  final parts = full.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length < 2) return full;
  final surname = parts[1];
  // Apostrofli harf ikki belgidan iborat: «O'» — bittasi yetmaydi.
  final initial =
      surname.length > 1 && (surname[1] == "'" || surname[1] == '\u02bb')
      ? surname.substring(0, 2)
      : surname[0];
  return '${parts.first} $initial.';
}

/// Serverdan kelgan matndagi HTML belgilarini ASLIGA qaytaradi.
///
/// 🔴 2026-08-13 jonli o'lchov: backend chat matnini HTML sifatida KODLAB
/// saqlaydi. "so'm va "qo'shtirnoq" sinovi" deb yozilgan xabar bazadan
/// `so&#39;m va &#34;qo&#39;shtirnoq&#34; sinovi` bo'lib qaytadi. O'zbek
/// tilida apostrof deyarli har jumlada bor ("so'm", "yo'q", "bo'ladi"),
/// ya'ni odam chatda tinimsiz `&#39;` ko'rardi.
///
/// Tuzatish backendda bo'lishi kerak (xat yozildi), lekin o'shangacha
/// odamga buzuq matn ko'rsatib turolmaymiz.
///
/// XAVFSIZMI: ha. Biz matnni HTML sifatida CHIZMAYMIZ — `Text` vidjeti
/// har qanday belgini oddiy harf sifatida ko'rsatadi.
String unescapeHtml(String input) {
  if (!input.contains('&')) return input;
  var out = input;
  const named = {
    '&quot;': '"',
    '&apos;': "'",
    '&lt;': '<',
    '&gt;': '>',
    '&nbsp;': ' ',
  };
  named.forEach((from, to) => out = out.replaceAll(from, to));
  // Raqamli shakllar: &#39; va &#x27;
  out = out.replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m[2]!, radix: m[1]!.isEmpty ? 10 : 16);
    return code == null ? m[0]! : String.fromCharCode(code);
  });
  // `&amp;` OXIRIDA: aks holda `&amp;#39;` ikki marta ochilib ketardi.
  return out.replaceAll('&amp;', '&');
}

/// Butun JSON javobni (Map/List/String) ochib chiqadi.
///
/// 🔴 APOSTROF («'») MUAMMOSI SHU YERDA YAKUNLANADI. Backend saqlashdan
/// oldin matnni HTML sifatida kodlaydi: "Farg'ona" bazadan `Farg&#39;ona`
/// bo'lib qaytadi, qo'shtirnoq esa `&#34;`. O'zbek tilida apostrof deyarli
/// har jumlada bor, ya'ni ekranda tinimsiz `&#39;` ko'rinardi — ismda,
/// manzilda, mashina modelida, posilka izohida, sharhda, bildirishnomada.
///
/// Ilgari `unescapeHtml` FAQAT chat modelida ikki joyda chaqirilardi.
/// Qolgan o'nlab joyda matn buzuq chiqaverardi va har yangi ekranda
/// chaqiruvni yana unutish mumkin edi.
///
/// Endi tuzatish TRANSPORT qatlamida (`ApiClient` ning `onResponse`
/// interceptor'i): serverdan kelgan har qanday matn bir marta ochiladi va
/// model kodi bu haqda umuman bilmaydi.
///
/// ⚠️ IKKI MARTA OCHMANG: `&amp;#39;` ni ikki marta ochish foydalanuvchi
/// chindan yozgan matnni buzadi. Shu sabab model ichidagi qo'lda
/// chaqiriqlar olib tashlandi.
///
/// Chuqurlik cheklangan — kutilmagan shaklda cheksiz rekursiya bo'lmasin.
dynamic deepUnescape(dynamic value, [int depth = 0]) {
  if (depth > 8) return value;
  if (value is String) return unescapeHtml(value);
  if (value is List) {
    for (var i = 0; i < value.length; i++) {
      value[i] = deepUnescape(value[i], depth + 1);
    }
    return value;
  }
  if (value is Map) {
    for (final key in value.keys.toList()) {
      value[key] = deepUnescape(value[key], depth + 1);
    }
    return value;
  }
  return value;
}

/// Yo'l vaqti: `Duration` -> "4 soat 45 daqiqa" / "35 daqiqa".
///
/// Soniyalar ko'rsatilmaydi: safar davomiyligida ular ma'nosiz va faqat
/// qatorni uzaytiradi.
String formatDuration(Duration duration, Lang lang) {
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);
  final d = switch (lang) {
    Lang.uz => 'kun',
    Lang.uzCyrl => toCyrillic('kun'),
    Lang.ru => 'д',
    Lang.en => 'd',
  };
  final h = switch (lang) {
    Lang.uz => 'soat',
    Lang.uzCyrl => toCyrillic('soat'),
    Lang.ru => 'ч',
    Lang.en => 'h',
  };
  final m = switch (lang) {
    Lang.uz => 'daqiqa',
    Lang.uzCyrl => toCyrillic('daqiqa'),
    Lang.ru => 'мин',
    Lang.en => 'min',
  };
  // 🔴 KUN BIRLIGI (10.09.2026): ilgari eng katta birlik SOAT edi va
  // sutkadan oshgan har qanday oraliq «139 soat 1 daqiqa» bo'lib
  // chiqardi. Bunday raqamni odam o'qiy olmaydi — miyasida 24 ga
  // bo'lishi kerak. Marshrut davomiyligida bu hech qachon sezilmasdi
  // (O'zbekiston bo'ylab eng uzun yo'l ham sutkadan qisqa), lekin
  // «Kechikmoqda — …» yozuvida aynan shu ko'rinardi.
  //
  // Kun bo'lsa DAQIQA tushiriladi: «5 kun 19 soat» yetarli aniq,
  // «5 kun 19 soat 3 daqiqa» esa shunchaki uzun.
  if (days > 0) return hours == 0 ? '$days $d' : '$days $d $hours $h';
  if (hours <= 0) return '$minutes $m';
  if (minutes == 0) return '$hours $h';
  return '$hours $h $minutes $m';
}

/// Jo'nashgacha qancha qolgani — "2 soat 40 daqiqadan keyin", "Ertaga 08:00".
///
/// 🔴 NEGA KERAK: hamma joyda MUTLAQ vaqt turardi ("08:00"). Odam uni har
/// safar boshida hisoblaydi: "hozir soat necha, ulgurmanmi?". Eng ko'p
/// so'raladigan savol — "qancha qoldi", eng qiyin javob esa aynan shu edi.
///
/// Yaqin vaqt uchun nisbiy, uzoq uchun mutlaq: "5 kundan keyin" hech kimga
/// yordam bermaydi, "Ertaga 08:00" esa beradi. Uzoq sanalarda BO'SH qaytadi —
/// chaqiruvchi o'zining odatiy sanasini ko'rsatishda davom etadi.
///
/// `now` ATAYIN parametr: testda vaqtni qotirish uchun (aks holda test
/// soatga bog'liq bo'lib, tunda o'zi yiqilardi).
/// JO'NASH YOZUVI, SAFAR HOLATI bilan — «kechikish shaffofligi».
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): [departureLabel]
/// jo'nash vaqti o'tgan zahoti «Jo'nab ketdi» deb yozardi — HOLATDAN
/// QAT'I NAZAR. Ya'ni haydovchi hali qimirlamagan bo'lsa ham, yo'lovchi
/// «ketib qolibdi» deb o'ylardi. Bu shunchaki noto'g'ri gap edi va
/// aynan eng keskin daqiqada aytilardi: odam uchrashuv nuqtasida turib,
/// kutish kerakmi yoki kech qolganmi — bilmasdi.
///
/// Endi uch xil holat AJRATILADI:
///   • safar boshlangan (`in_progress`) → «Yo'lda»;
///   • vaqt o'tgan, lekin boshlanmagan → «Kechikmoqda — 12 daqiqa»;
///   • qolgan hamma holat → avvalgidek ([departureLabel]).
///
/// ⚠️ HECH QANDAY TAXMIN YO'Q. «Bu haydovchi odatda kechikadi» degan
/// statistika ATAYIN yozilmadi: buning uchun bizda ma'lumot yo'q
/// (backend jo'nash faktini vaqt bilan qaytarmaydi), taxminiy raqam esa
/// odamni noto'g'ri ayblardi.
/// Jo'nash yorlig'i E'TIBOR talab qiladimi — RANG shunga qarab beriladi.
///
/// 🔴 NEGA KERAK (2026-09-02, «YO'L» dizayn tili): safar tafsilotida
/// «Ertaga 09:30» BREND rangida yozilardi. Ya'ni pushti oddiy sana
/// uchun ham, «Kechikmoqda» uchun ham bir xil edi va shoshilinchlikni
/// bildirmay qo'ygandi. Rang holat aytishi kerak, bezak bo'lmasligi.
///
/// `true` — safar YO'LDA yoki KECHIKMOQDA (odam darhol qarashi kerak).
/// `false` — oddiy sana yorlig'i («Ertaga», «Bugun», «5-sentabr»).
bool departureNeedsAttention(DateTime? dt, String status, {DateTime? now}) {
  if (dt == null) return false;
  if (status == RideStatus.inProgress) return true;
  final live = status == RideStatus.active || status == RideStatus.draft;
  final late_ = (now ?? DateTime.now()).difference(dt);
  return live && !late_.isNegative && late_.inMinutes >= 1;
}

String departureStatusLabel(
  DateTime? dt,
  String status,
  Lang lang, {
  DateTime? now,
}) {
  if (dt == null) return '';

  if (status == RideStatus.inProgress) {
    return switch (lang) {
      Lang.uz => 'Yo\'lda',
      Lang.uzCyrl => toCyrillic('Yo\'lda'),
      Lang.ru => 'В пути',
      Lang.en => 'On the way',
    };
  }

  final current = now ?? DateTime.now();
  final late_ = current.difference(dt);
  // Faqat TIRIK safarda kechikish deymiz: tugagan yoki bekor qilingan
  // safarда «kechikmoqda» degan gap ma'nosiz.
  final live = status == RideStatus.active || status == RideStatus.draft;
  if (live && !late_.isNegative && late_.inMinutes >= 1) {
    final d = formatDuration(late_, lang);
    return switch (lang) {
      Lang.uz => 'Kechikmoqda — $d',
      Lang.uzCyrl => toCyrillic('Kechikmoqda — $d'),
      Lang.ru => 'Задерживается — $d',
      Lang.en => 'Running late — $d',
    };
  }

  return departureLabel(dt, lang, now: now);
}

String departureLabel(DateTime? dt, Lang lang, {DateTime? now}) {
  if (dt == null) return '';
  final current = now ?? DateTime.now();
  final diff = dt.difference(current);

  if (diff.isNegative) {
    return switch (lang) {
      Lang.uz => 'Jo\'nab ketdi',
      Lang.uzCyrl => toCyrillic('Jo\'nab ketdi'),
      Lang.ru => 'Отправился',
      Lang.en => 'Departed',
    };
  }
  if (diff.inMinutes < 1) {
    return switch (lang) {
      Lang.uz => 'Hozir jo\'naydi',
      Lang.uzCyrl => toCyrillic('Hozir jo\'naydi'),
      Lang.ru => 'Отправляется',
      Lang.en => 'Departing now',
    };
  }
  if (diff.inHours < 12) {
    // O'zbekchada qo'shimcha OXIRGI so'zga qo'shiladi va ikkala holatda ham
    // to'g'ri chiqadi: "3 soat" + "dan keyin", "2 soat 40 daqiqa" + "dan keyin".
    final d = formatDuration(diff, lang);
    return switch (lang) {
      Lang.uz => '${d}dan keyin',
      Lang.uzCyrl => toCyrillic('${d}dan keyin'),
      Lang.ru => 'через $d',
      Lang.en => 'in $d',
    };
  }

  final day = DateTime(dt.year, dt.month, dt.day);
  final today = DateTime(current.year, current.month, current.day);
  final days = day.difference(today).inDays;
  if (days == 0 || days == 1) {
    final prefix = days == 0
        ? switch (lang) {
            Lang.uz => 'Bugun',
            Lang.uzCyrl => toCyrillic('Bugun'),
            Lang.ru => 'Сегодня',
            Lang.en => 'Today',
          }
        : switch (lang) {
            Lang.uz => 'Ertaga',
            Lang.uzCyrl => toCyrillic('Ertaga'),
            Lang.ru => 'Завтра',
            Lang.en => 'Tomorrow',
          };
    return '$prefix ${formatTime(dt)}';
  }

  // Uzoq sana — chaqiruvchidagi odatiy sana yozuvi yetarli.
  return '';
}

/// Safar allaqachon jo'nab ketganmi — ro'yxatda xiralashtirish uchun.
bool hasDeparted(DateTime? dt, {DateTime? now}) =>
    dt != null && dt.isBefore(now ?? DateTime.now());

/// Masofa — yaqin joyda METR, uzoqda KILOMETR.
///
/// 🔴 NEGA SHUNDAY: "0.7 km" odamga hech nima aytmaydi, "700 m" esa
/// darhol tushunarli — piyoda yurish masofasi. Aksincha, "12 400 m"
/// o'qib bo'lmaydigan raqam.
String formatDistance(double km) {
  if (km < 1) {
    // 50 metrgacha yaxlitlanadi: GPS aniqligi baribir undan yaxshi emas
    // va "687 m" soxta aniqlik berardi.
    final meters = (km * 1000 / 50).round() * 50;
    return '${meters.clamp(50, 950)} m';
  }
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}

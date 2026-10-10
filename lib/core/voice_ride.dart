/// OVOZLI E'LON — bitta gapdan butun safar formasini to'ldirish.
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): e'lon berish
/// HAYDOVCHI tomonidagi eng katta to'siq. Forma uzun: ikki shahar, sana,
/// vaqt, joy soni, narx, mashina. Haydovchi esa ko'pincha yo'lda, rulda
/// yoki bekatда turgan bo'ladi va telefonda yozish unga qiyin (klaviatura
/// tili, lotin/kirill, apostrof). Natijada u e'lonni Telegram guruhiga
/// bir og'iz gap bilan tashlaydi — biz esa uni yo'qotamiz.
///
/// «Toshkentdan Samarqandga ertaga sakkizda uch joy sakson ming» —
/// bitta gap butun formani to'ldiradi.
///
/// ═══ QAT'IY QOIDALAR ═══
///
///  1. **Faqat TANILGANI to'ldiriladi.** Taxmin qilinmaydi: narx
///     eshitilmasa maydon bo'sh qoladi, sana eshitilmasa sana
///     tanlanmaydi. Yolg'on to'ldirilgan forma e'lon berilгач jonli
///     xatoga aylanadi.
///  2. **Natija EKRANDA ko'rsatiladi** va odam uni tuzatishi mumkin —
///     hech narsa jimgina yuborilmaydi.
///  3. Yo'nalish tahlili `voice_route.dart` bilan BIR XIL manbadan
///     (ikki xil qoida ikki xil natija berardi).
library;

import 'cities.dart';
import 'voice_route.dart';

/// Aytilgan gapdan olingan e'lon ma'lumotlari. Har maydon alohida `null`
/// bo'lishi mumkin — eshitilmagani to'ldirilmaydi.
class VoiceRide {
  const VoiceRide({
    this.from,
    this.to,
    this.date,
    this.hour,
    this.minute,
    this.seats,
    this.price,
  });

  final Place? from;
  final Place? to;

  /// Faqat SANA (vaqtsiz) — «bugun»/«ertaga»/«indinga».
  final DateTime? date;

  /// Soat va daqiqa — alohida, chunki gapda vaqt sanasiz ham aytiladi.
  final int? hour;
  final int? minute;

  final int? seats;
  final double? price;

  bool get isEmpty =>
      from == null &&
      to == null &&
      date == null &&
      hour == null &&
      seats == null &&
      price == null;
}

/// Sanani bildiruvchi so'zlar → bugundan necha kun keyin.
const _dayWords = <String, int>{
  'bugun': 0,
  'сегодня': 0,
  'today': 0,
  'ertaga': 1,
  'erta': 1,
  'завтра': 1,
  'tomorrow': 1,
  'indinga': 2,
  'indin': 2,
  'послезавтра': 2,
};

/// Aytilgan sonlar — nutqni tanish ularni SO'Z bilan ham qaytaradi.
///
/// 🔴 NEGA KERAK: «uch joy» degan gap `3 joy` bo'lib kelmaydi. Faqat
/// raqamni qidirsak, o'zbekcha aytilgan e'lonlarning yarmi tushunilmasdi.
const _numberWords = <String, int>{
  'bir': 1,
  'один': 1,
  'one': 1,
  'ikki': 2,
  'два': 2,
  'две': 2,
  'two': 2,
  'uch': 3,
  'три': 3,
  'three': 3,
  'to\'rt': 4,
  'tort': 4,
  'четыре': 4,
  'four': 4,
  'besh': 5,
  'пять': 5,
  'five': 5,
  'olti': 6,
  'шесть': 6,
  'six': 6,
  'yetti': 7,
  'семь': 7,
  'seven': 7,
  'sakkiz': 8,
  'восемь': 8,
  'eight': 8,
  'to\'qqiz': 9,
  'toqqiz': 9,
  'девять': 9,
  'nine': 9,
  'o\'n': 10,
  'on': 10,
  'десять': 10,
  'ten': 10,
  'o\'n bir': 11,
  'on bir': 11,
  'одиннадцать': 11,
  'o\'n ikki': 12,
  'on ikki': 12,
  'двенадцать': 12,
};

/// «Joy» so'zlari — ulardan OLDINGI son o'rindiq soni.
const _seatWords = {
  'joy',
  'joyim',
  'o\'rin',
  'orin',
  'kishi',
  'odam',
  'место',
  'места',
  'мест',
  'человек',
  'seat',
  'seats',
  'place',
  'places',
};

/// «Ming» — narx ko'pincha shunday aytiladi («sakson ming»).
const _thousandWords = {'ming', 'minг', 'тысяч', 'тыс', 'thousand', 'k'};

/// Pul birligi — narx ekanini tasdiqlaydi.
const _moneyWords = {'so\'m', 'som', 'sum', 'сум', 'сўм', 'sum.'};

/// O'nlab sonlar (narx uchun: «sakson ming»).
const _tensWords = <String, int>{
  'yigirma': 20,
  'двадцать': 20,
  'o\'ttiz': 30,
  'ottiz': 30,
  'тридцать': 30,
  'qirq': 40,
  'сорок': 40,
  'ellik': 50,
  'пятьдесят': 50,
  'oltmish': 60,
  'шестьдесят': 60,
  'yetmish': 70,
  'семьдесят': 70,
  'sakson': 80,
  'восемьдесят': 80,
  'to\'qson': 90,
  'toqson': 90,
  'девяносто': 90,
  'yuz': 100,
  'сто': 100,
};

/// Vaqtni bildiruvchi qo'shimchali so'z: «sakkizda», «8 da».
final _timeSuffix = RegExp(r'^(\d{1,2})(da|ta)?$');

final _separator = RegExp(r"[^\p{L}\p{N}ʻʼ'`ʹ‘’:]+", unicode: true);

/// Gapdan e'lon ma'lumotlarini ajratadi. Hech narsa tanilmasa `null`.
VoiceRide? parseVoiceRide(String text, {DateTime? now}) {
  final route = parseVoiceRoute(text);

  final tokens = text
      .toLowerCase()
      .split(_separator)
      .where((w) => w.isNotEmpty)
      .toList();
  if (tokens.isEmpty && route == null) return null;

  final today = now ?? DateTime.now();

  DateTime? date;
  int? hour;
  int? minute;
  int? seats;
  double? price;

  for (var i = 0; i < tokens.length; i++) {
    final word = tokens[i];

    // ── SANA ────────────────────────────────────────────────────────────
    final dayOffset = _dayWords[word];
    if (dayOffset != null) {
      final base = DateTime(today.year, today.month, today.day);
      date = base.add(Duration(days: dayOffset));
      continue;
    }

    // ── VAQT: «8:30» ────────────────────────────────────────────────────
    if (word.contains(':')) {
      final parts = word.split(':');
      final h = int.tryParse(parts.first);
      final m = parts.length > 1 ? int.tryParse(parts[1]) : null;
      if (h != null && h >= 0 && h <= 23) {
        hour = h;
        if (m != null && m >= 0 && m <= 59) minute = m;
      }
      continue;
    }

    // ── O'RINDIQ: «3 joy», «uch kishi» ──────────────────────────────────
    if (_seatWords.contains(word) && i > 0) {
      final value = _numberAt(tokens, i - 1);
      // 1..8 — mashinaga sig'adigan oraliq. Undan tashqarisi boshqa
      // narsa haqida aytilgan bo'lishi mumkin («o'n ming so'm joy»).
      if (value != null && value >= 1 && value <= 8) {
        seats = value;
        continue;
      }
    }

    // ── NARX: «sakson ming», «80000 so'm» ───────────────────────────────
    if (_thousandWords.contains(word) && i > 0) {
      final value = _numberAt(tokens, i - 1);
      if (value != null && value > 0) {
        price = value * 1000;
        continue;
      }
    }
    if (_moneyWords.contains(word) && i > 0) {
      final raw = int.tryParse(tokens[i - 1]);
      // «ming» allaqachon hisoblagan bo'lsa qayta yozmaymiz.
      if (raw != null && raw >= 1000) price ??= raw.toDouble();
      continue;
    }

    // ── VAQT: «sakkizda», «8 da», «soat 8» ──────────────────────────────
    final match = _timeSuffix.firstMatch(word);
    if (match != null && match.group(2) == 'da') {
      final h = int.tryParse(match.group(1)!);
      if (h != null && h >= 0 && h <= 23) hour = h;
      continue;
    }
    if (word == 'soat' && i + 1 < tokens.length) {
      final h = int.tryParse(tokens[i + 1]);
      if (h != null && h >= 0 && h <= 23) hour = h;
      continue;
    }
    // «sakkizda» — son SO'Z bilan aytilgan va `da` qo'shimchasi bor.
    if (word.endsWith('da') && word.length > 4) {
      final stem = word.substring(0, word.length - 2);
      final h = _numberWords[stem];
      if (h != null && h >= 1 && h <= 23) {
        hour = h;
        continue;
      }
    }
  }

  final result = VoiceRide(
    from: route?.from,
    to: route?.to,
    date: date,
    hour: hour,
    minute: minute,
    seats: seats,
    price: price,
  );
  return result.isEmpty ? null : result;
}

/// [index] dagi sonni o'qiydi: raqam ham, so'z ham
/// («80», «sakson», «sakson besh»).
int? _numberAt(List<String> tokens, int index) {
  if (index < 0) return null;
  final word = tokens[index];

  final digits = int.tryParse(word);
  if (digits != null) return digits;

  final simple = _numberWords[word];
  final tens = _tensWords[word];

  // «sakson besh» — o'nlab + birlik. Chapdan o'ngga aytiladi, ya'ni
  // birlik OXIRIDA turadi.
  if (simple != null && index > 0) {
    final beforeTens = _tensWords[tokens[index - 1]];
    if (beforeTens != null) return beforeTens + simple;
  }
  return simple ?? tens;
}

/// OVOZLI (yoki bitta qatorda yozilgan) YO'NALISH TAHLILI — bitta gapdan
/// IKKI joy ajratadi.
///
/// 🔴 NEGA YOZILDI (egasi, 2026-08-24): saytda ovozli qidiruv faqat JO'NASH
/// joyini to'ldirardi. Odam "Toshkentdan Samarqandga" desa, butun gap
/// "qayerdan" maydoniga tushardi va "qayerga" bo'sh qolardi — qidiruv esa
/// ishlamasdi. Ya'ni funksiya bor-u, aytilgan gapning yarmi tashlab
/// ketilardi. Bu fayl o'sha tahlilning ilovadagi nusxasi.
///
/// ⚠️ IKKALA MIJOZDA BIR XIL BO'LSIN: web'dagi juftligi
/// `src/shared/lib/voiceRoute.ts`. Qoidani birida o'zgartirsang —
/// ikkinchisida ham o'zgartir, aks holda bir xil gap ikki xil tushuniladi.
///
/// QOIDA: gapda ikki joy nomi bo'lsa — birinchisi jo'nash, ikkinchisi manzil.
/// Lekin TARTIB emas, GRAMMATIKA ustun turadi: "Samarqandga Toshkentdan
/// boraman" ham to'g'ri tushuniladi.
///
/// Uch tilning ko'rsatkichlari:
///   • o'zbek — kelishik qo'shimchasi: `-dan` (jo'nash), `-ga/-ka/-qa/-gacha`;
///   • rus    — old ko'makchi: `из/от/с` (jo'nash), `в/во/до/на/к` (manzil);
///   • ingliz — `from` (jo'nash), `to` (manzil).
library;

import 'cities.dart';

/// Tahlil natijasi. [from] yoki [to] alohida `null` bo'lishi mumkin —
/// odam bitta shaharni aytgan bo'lsa, ikkinchisini o'zi kiritadi.
class VoiceRoute {
  const VoiceRoute({this.from, this.to, required this.matched});

  final Place? from;
  final Place? to;

  /// Tanilgan joylar soni — chaqiruvchi "yarmi tushunildi" holatini
  /// ajratishi uchun.
  final int matched;

  bool get isEmpty => from == null && to == null;
}

/// Eng ko'p necha so'zli nom izlanadi ("Yangi Bozor" kabi qo'shma nomlar).
const _maxNameWords = 3;

/// Jo'nashni bildiruvchi kelishik qo'shimchasi (chiqish kelishigi).
const _fromSuffixes = {'dan'};

/// Manzilni bildiruvchi kelishik qo'shimchalari (jo'nalish kelishigi).
const _toSuffixes = {'ga', 'ka', 'qa', 'gacha'};

/// Nomdan OLDIN turganda jo'nashni bildiruvchi so'zlar (rus/ingliz).
const _fromWords = {'from', 'iz', 'ot', 'so', 's', 'из', 'от', 'с', 'со'};

/// Nomdan OLDIN turganda manzilni bildiruvchi so'zlar (rus/ingliz).
const _toWords = {'to', 'v', 'vo', 'do', 'na', 'k', 'в', 'во', 'до', 'на', 'к'};

/// Nomdan KEYIN alohida so'z bo'lib turgan kelishik qo'shimchalari.
///
/// 🔴 NEGA (2026-08-25): nutqni tanish qo'shimchani nomdan AJRATIB yozadi —
/// "Toshkent dan Samarqand ga". O'lchab ko'rildi: "Samarqand ga Toshkent dan"
/// TESKARI tushunilardi (Samarqand → Toshkent), chunki hech qanday belgi
/// topilmay AYTILISH TARTIBI qoidasiga tushardi. Odam esa yo'nalishni aniq
/// aytgan edi — ilova uni eshitib turib, aksini qildi.
const _fromSuffixWords = {'dan', 'дан'};
const _toSuffixWords = {
  'ga',
  'ka',
  'qa',
  'gacha',
  'га',
  'ка',
  'қа',
  'гача',
};

/// Ajratgich: harf, raqam va apostrofdan boshqa hamma narsa. Nutqni tanish
/// vergul, nuqta va "→" ham qo'shib beradi. Apostrof SAQLANADI
/// ("Farg'ona"), keyin `resolvePlaceDetailed` uni o'zi tashlaydi.
final _separator = RegExp(r"[^\p{L}\p{N}ʻʼ'`ʹ‘’]+", unicode: true);

enum _Direction { from, to }

class _Candidate {
  const _Candidate(this.place, this.direction);
  final Place place;
  final _Direction? direction;
}

_Direction? _directionFromSuffix(String? caseSuffix) {
  if (caseSuffix == null) return null;
  if (_fromSuffixes.contains(caseSuffix)) return _Direction.from;
  if (_toSuffixes.contains(caseSuffix)) return _Direction.to;
  return null;
}

/// Nomdan KEYINGI so'z yolg'iz kelishik qo'shimchasi bo'lsa.
_Direction? _directionFromNextWord(String? nextWord) {
  if (nextWord == null) return null;
  if (_fromSuffixWords.contains(nextWord)) return _Direction.from;
  if (_toSuffixWords.contains(nextWord)) return _Direction.to;
  return null;
}

_Direction? _directionFromMarker(String? previousWord) {
  if (previousWord == null) return null;
  if (_fromWords.contains(previousWord)) return _Direction.from;
  if (_toWords.contains(previousWord)) return _Direction.to;
  return null;
}

/// Aytilgan gapdan yo'nalishni ajratadi. Bitta ham joy tanilmasa `null`.
///
/// Misollar (hammasi bir xil natija beradi):
///   "Toshkentdan Samarqandga"          → Toshkent → Samarqand
///   "Toshkent dan Samarqand ga"        → Toshkent → Samarqand
///   "Samarqand ga Toshkent dan"        → Toshkent → Samarqand
///   "Тошкентдан Самарқандга"           → Toshkent → Samarqand
///   "Toshkent Samarqand"               → Toshkent → Samarqand
///   "Samarqandga Toshkentdan boraman"  → Toshkent → Samarqand
///   "из Ташкента в Самарканд"          → Toshkent → Samarqand
///   "from Tashkent to Samarkand"       → Toshkent → Samarqand
///   "Samarqandga"                      → (jo'nash bo'sh) → Samarqand
VoiceRoute? parseVoiceRoute(String text) {
  final tokens = text
      .toLowerCase()
      .split(_separator)
      .where((w) => w.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return null;

  final candidates = <_Candidate>[];

  // Chapdan o'ngga yuramiz va eng UZUN mos nomni olamiz: "yangi bozor" ni
  // "yangi" deb kesib tashlamaslik uchun. Topilgan so'zlar iste'mol qilinadi.
  var i = 0;
  while (i < tokens.length) {
    var taken = 0;
    final maxSpan = _maxNameWords < tokens.length - i
        ? _maxNameWords
        : tokens.length - i;
    for (var span = maxSpan; span >= 1; span--) {
      final phrase = tokens.sublist(i, i + span).join(' ');
      final hit = resolvePlaceDetailed(phrase);
      if (hit == null) continue;

      // Yo'nalish dalillari kuchi bo'yicha:
      //   1. nomning O'ZIDAGI qo'shimcha ("Toshkentdan") — eng aniq;
      //   2. nomdan KEYIN alohida turgan qo'shimcha ("Toshkent dan") —
      //      nutqni tanish shunday ajratib yozadi;
      //   3. nomdan OLDINGI old ko'makchi ("из Ташкента", "from Tashkent").
      final direction =
          _directionFromSuffix(hit.caseSuffix) ??
          _directionFromNextWord(
            i + span < tokens.length ? tokens[i + span] : null,
          ) ??
          _directionFromMarker(i > 0 ? tokens[i - 1] : null);
      candidates.add(_Candidate(hit.place, direction));
      taken = span;
      break;
    }
    i += taken > 0 ? taken : 1;
  }

  if (candidates.isEmpty) return null;

  _Candidate? explicitFrom;
  _Candidate? explicitTo;
  for (final c in candidates) {
    if (c.direction == _Direction.from) explicitFrom ??= c;
    if (c.direction == _Direction.to) explicitTo ??= c;
  }

  // Ikkalasi ham aniq aytilgan — tartib ahamiyatsiz.
  if (explicitFrom != null && explicitTo != null && explicitFrom != explicitTo) {
    return VoiceRoute(
      from: explicitFrom.place,
      to: explicitTo.place,
      matched: candidates.length,
    );
  }

  // Faqat bittasi aniq: qolgan (belgisiz) nomlardan ikkinchisini olamiz.
  final known = explicitFrom ?? explicitTo;
  if (known != null) {
    Place? other;
    for (final c in candidates) {
      if (c != known && c.place.name != known.place.name) {
        other = c.place;
        break;
      }
    }
    return explicitFrom != null
        ? VoiceRoute(from: known.place, to: other, matched: candidates.length)
        : VoiceRoute(from: other, to: known.place, matched: candidates.length);
  }

  // Hech qanday belgi yo'q ("Toshkent Samarqand") — AYTILISH TARTIBI.
  // Bu qoida ataylab: odam "qayerdan qayerga" tartibida gapiradi.
  final unique = <Place>[];
  for (final c in candidates) {
    if (!unique.any((p) => p.name == c.place.name)) unique.add(c.place);
  }
  return VoiceRoute(
    from: unique.isNotEmpty ? unique[0] : null,
    to: unique.length > 1 ? unique[1] : null,
    matched: unique.length,
  );
}

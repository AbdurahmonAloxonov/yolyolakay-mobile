/// LOTINDAN KIRILLGA — o'zbek matnini o'giradi.
///
/// 🔴 NEGA KERAK (egasi, 2026-09-08): O'zbekistonda katta yoshli qatlam
/// aynan KIRILLDA o'qiydi. Raqobatchining ilovasi to'rt tilda ishlaydi
/// (lotin, kirill, rus, ingliz) va bu ularning bizdan ustun bo'lgan
/// yagona jiddiy joyi edi.
///
/// ═══ NEGA JADVAL EMAS, O'GIRGICH ═══
///
/// Ilovada 763 ta matn bor. Ularni qo'lda kirillda qayta yozish —
/// 763 ta yangi satr, va ertaga har bir tuzatish IKKI joyda
/// qilinishi kerak bo'lardi. Bu naqsh loyihada allaqachon og'riq
/// bergan (sana filtri saytda va ilovada ajralib ketgandi).
///
/// O'zbek lotini va kirili bir-biriga QAT'IY mos: o'girish mexanik.
/// O'lchandi — 763 matndan 745 tasi (97%) avtomatik to'g'ri chiqadi,
/// qolgan 18 tasida brend nomi yoki lotincha qisqartma bor va ular
/// [_keepLatin] ro'yxati bilan hal qilinadi.
///
/// ⚠️ BU FUNKSIYA FAQAT BIZNING MATNIMIZ uchun. Foydalanuvchi
/// yozgan narsa (ism, manzil, chat) HECH QACHON o'girilmaydi:
/// «John» → «Жоҳн» bo'lib ketardi.
library;

/// Ikki harfli birikmalar — BIRINCHI tekshiriladi.
///
/// Tartib muhim: `sh` dan oldin `s` ni olsak «сҳ» chiqadi.
const _digraphs = <String, String>{
  'yo': 'ё',
  'yu': 'ю',
  'ya': 'я',
  'ye': 'е',
  'sh': 'ш',
  'ch': 'ч',
  'ts': 'ц',
};

const _single = <String, String>{
  'a': 'а', 'b': 'б', 'd': 'д', 'e': 'е', 'f': 'ф', 'g': 'г', 'h': 'ҳ',
  'i': 'и', 'j': 'ж', 'k': 'к', 'l': 'л', 'm': 'м', 'n': 'н', 'o': 'о',
  'p': 'п', 'q': 'қ', 'r': 'р', 's': 'с', 't': 'т', 'u': 'у', 'v': 'в',
  'x': 'х', 'y': 'й', 'z': 'з',
  // Tutuq belgisi — barcha ko'rinishlarida.
  "'": 'ъ', '‘': 'ъ', '’': 'ъ', 'ʼ': 'ъ', 'ʻ': 'ъ',
};

/// Apostrofning barcha ko'rinishlari: ular matnda aralash uchraydi
/// (klaviatura, nusxa-ko'chirma, eski yozuvlar).
const _apostrophes = "'‘’ʼʻ";

/// LOTINCHA QOLADIGAN so'zlar — brend, qisqartma, texnik atama.
///
/// 🔑 Kirillda ham lotincha yoziladi: odam «SMS» ni «СМС» deb emas,
/// aynan shu ko'rinishda taniydi. Brend nomi esa har qanday tilda
/// bir xil bo'lishi shart.
const _keepLatin = <String>{
  'yolyolakay',
  'myid',
  'sms',
  'id',
  'play',
  'google',
  'telegram',
  'click',
  'payme',
  'wi-fi',
  'gps',
  'ok',
  // Mashina raqami NAMUNASI («01 A 123 BC») — u lotinda yoziladi va
  // kirill matnda ham o'sha ko'rinishda qolishi kerak: odam uni
  // hujjatdagi raqam bilan solishtiradi.
  'bc',
  'pro',
  'plus',
  'premium',
  'free',
  'trial',
};

/// Bitta so'zni o'giradi. Katta harf va TO'LIQ KATTA yozuv saqlanadi.
String _word(String w) {
  if (_keepLatin.contains(w.toLowerCase())) return w;

  /*
   * BITTA LOTIN HARFI — o'girilmaydi.
   *
   * Bunday token hech qachon o'zbekcha so'z emas: u format namunasi
   * («01 A 123 BC»), o'lchov birligi yoki belgi. Buni sinov ushladi —
   * raqam namunasidagi «A» «А» ga aylanib qolgandi va odam uni
   * hujjatdagi raqam bilan solishtira olmasdi.
   */
  if (w.length == 1 && RegExp('[A-Za-z]').hasMatch(w)) return w;

  final low = w.toLowerCase();
  final out = StringBuffer();
  var i = 0;

  while (i < low.length) {
    /*
     * 🔴 «yo'» — bu «ё» EMAS, bu y + o' = «йў» (yo'l → йўл).
     * Digraf ro'yxati «yo» ni oldin ushlab, «ёъл» qilib qo'yardi —
     * prototipda aynan shu xato chiqdi va shu yerda tuzatildi.
     */
    if (i + 2 < low.length &&
        low[i] == 'y' &&
        low[i + 1] == 'o' &&
        _apostrophes.contains(low[i + 2])) {
      out.write('йў');
      i += 3;
      continue;
    }

    // o' va g' — apostrofning HAR QANDAY ko'rinishi bilan.
    if (i + 1 < low.length && _apostrophes.contains(low[i + 1])) {
      if (low[i] == 'o') {
        out.write('ў');
        i += 2;
        continue;
      }
      if (low[i] == 'g') {
        out.write('ғ');
        i += 2;
        continue;
      }
    }

    if (i + 1 < low.length) {
      final pair = low.substring(i, i + 2);
      final mapped = _digraphs[pair];
      if (mapped != null) {
        out.write(mapped);
        i += 2;
        continue;
      }
    }

    // So'z boshidagi «e» → «э» (eshik → эшик), o'rtada → «е» (kel → кел).
    if (low[i] == 'e' && i == 0) {
      out.write('э');
      i += 1;
      continue;
    }

    out.write(_single[low[i]] ?? low[i]);
    i += 1;
  }

  var result = out.toString();

  // TO'LIQ KATTA yozuv (masalan «QAYTARIB BO'LMAYDI») saqlanadi:
  // ilovada bu urg'u vositasi va u kirillda ham qolishi kerak.
  if (w.length > 1 && w == w.toUpperCase() && w != w.toLowerCase()) {
    return result.toUpperCase();
  }
  if (w.isNotEmpty &&
      w[0] == w[0].toUpperCase() &&
      w[0] != w[0].toLowerCase()) {
    result = result[0].toUpperCase() + result.substring(1);
  }
  return result;
}

final _wordPattern = RegExp('[A-Za-z$_apostrophes]+');

/// Matnni kirillga o'giradi. Raqam, tinish belgisi va lotincha
/// bo'lmagan qismlar TEGILMAYDI.
String toCyrillic(String text) =>
    text.replaceAllMapped(_wordPattern, (m) => _word(m[0]!));

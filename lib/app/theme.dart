import 'package:flutter/material.dart';

import '../features/shared/brand/atlas.dart';
import '../features/shared/brand/ornament.dart';
import 'dimens.dart';

/// Brend palitrasi — web'dagi tokenlar bilan bir xil qiymatlar
/// (`--wine-ash`, `--turquoise`, `--brand-pink`). Ikkala platformada
/// bir xil ko'rinishi uchun qiymatlar SHU YERDA yagona manba.
class BrandColors {
  const BrandColors._();

  /// To'q fon, sarlavhalar, futer.
  static const wineAsh = Color(0xFF32292F);

  /// Aksent, muvaffaqiyat, faol holat.
  static const turquoise = Color(0xFF99E1D9);
  static const turquoiseLight = Color(0xFFC4EFE9);

  /// REYTING YULDUZI — oltin.
  ///
  /// 🔴 NEGA NOM BERILDI (2026-09-03 ko'rigi): bu qiymat BESHTA
  /// faylda qo'lda yozilgan edi (safar kartochkasi, haydovchi qatori,
  /// baholash oynasi, sharhlar, begona profil). Bittasida bir belgi
  /// xato yozilsa, ilovada ikki xil oltin paydo bo'lardi va buni hech
  /// qanday test tutmasdi.
  ///
  /// ⚠️ Bu rang TEMADAN OLINMAYDI: yulduz — universal belgi va u
  /// tungi rejimda ham, neon uslubida ham oltin bo'lib qoladi.
  static const star = Color(0xFFF5A623);

  /// «BAJARILDI / XAVFSIZ» — yashil.
  ///
  /// Ishonch narvoni va safar oldi ro'yxatida ishlatiladi. Brend
  /// feruzasidan ATAYIN boshqa: feruza «bor» degani, yashil esa
  /// «tekshirildi va joyida» degani.
  static const success = Color(0xFF1FA971);

  /// Barcha asosiy tugmalar, muhim CTA, logo.
  ///
  /// 🔴 2026-09-04 da TO'QLASHTIRILDI (egasi tanladi, sayt bilan BIR
  /// XIL kunda). Eski #E91E8C o'lchovda WCAG AA dan past edi: zaminida
  /// oq yozuv 4.18:1, pushti yozuv oq qog'ozda 3.85:1 (kerak — 4.5:1).
  /// Yangi rang o'ylab topilmadi — u palitradagi eski HOVER rangi.
  static const pink = Color(0xFFC71578);
  static const pinkLight = Color(0xFFFDE8F3);
  static const pinkHover = Color(0xFFA91068);

  /// TO'Q temadagi pushti.
  ///
  /// 🔑 NEGA IKKINCHI PUSHTI KERAK: aksentning ikkita roli bor —
  /// ZAMIN (ustida yozuv turadi) va YOZUVNING O'ZI. Bitta rang
  /// ikkalasini ham bajara olmaydi: oq yozuv sig'ishi uchun rang
  /// TO'Q bo'lishi kerak, o'zi to'q zaminda o'qilishi uchun esa
  /// OCH — bu ikki shart bir vaqtda bajarilmaydi (hisoblab
  /// ko'rilgan, oraliq yo'q). Shuning uchun yorug' temada aksent
  /// to'q + oq yozuv, to'q temada aksent och + qora yozuv.
  ///
  /// 🔴 OCHROQ QILINDI (10.09.2026, o'lchandi). Eski `#F24AA6`
  /// ESKI, to'qroq sirtlar uchun yetarli edi. Qatlamlar joriy
  /// qilingach (izohi [surfaceDark] da) u kartada **4.31 : 1**,
  /// pastki amal panelida esa **3.37 : 1** ga tushdi — AA dan past.
  /// Buni `accessibility_test` tutdi.
  ///
  /// `#F86FB8` uchala zaminda ham yetadi (karta 5.44, panel 4.93,
  /// fon 6.99). Undan ochroq variantlar ham bor edi, lekin bu —
  /// brend pushtisiga eng YAQINI: kerakli minimumdan bir qadam
  /// yuqori, undan ortiq emas.
  ///
  /// ⚠️ Bu FAQAT QORONG'I temaning aksenti. Yorug' temadagi
  /// `#C71578` — egasi tanlagan brend rangi — TEGILMADI.
  static const pinkInk = Color(0xFFF86FB8);

  /// Qorong'i rejimdagi karta sirti. Fon (`#161316`) dan ATAYIN ochroq —
  /// chegara ham, soya ham yo'q, kartaning cheti faqat shu farqdan bilinadi.
  ///
  /// 🔴 OCHROQ QILINDI (10.09.2026, o'lchandi): eski qiymat `#241F23`
  /// fondan atigi **1.14 : 1** farq qilardi. Ya'ni «ochroq» degani
  /// qog'ozda bor edi, ekranda esa karta bilan zamin bir tekislikda
  /// yotardi va butun ilova YASSI ko'rinardi — egasi buni «hunuk»
  /// deb atadi va haq edi.
  ///
  /// Yangi qiymat fondan **1.28 : 1** ajraladi (Apple qorong'i
  /// rejimda qatlamlar orasida odatda 1.25–1.6 beradi,
  /// `materials.md`). Matn zarar ko'rmadi: asosiy matn 12.50 : 1,
  /// ikkilamchi matn 4.89 : 1 — ikkalasi ham AA dan yuqori.
  static const surfaceDark = Color(0xFF2E2830);

  // ===== NEON USLUB (egasi, 2026-08-20: "binafsha + cyan neon") =====
  // Cyberpunk yo'nalishi. Classic brenddан ATAYIN uzoqroq — bu boshqa
  // "kayfiyat", lekin bir xil komponentlar/o'lchamlar (faqat rang + porlash
  // o'zgaradi, tuzilma emas).
  /// Asosiy neon aksent — BREND pushtimizning neon versiyasi.
  /// 🔴 Egasi (2026-08-20): neon "boshqa purple" bo'lmasin, o'z rangimiz
  /// yonsin. Shuning uchun begona binafsha (#B026FF) OLIB TASHLANDI.
  static const neonPink = Color(0xFFFF2BA0);

  /// Neon aksentning YORUG' temadagi ko'rinishi: #FF2BA0 oq qog'ozda
  /// 3.44:1 — na zamin, na yozuv bo'la oladi. Neonlik rangning
  /// issiqligidan emas, PORLASHIDAN keladi (porlash hamon #FF2BA0).
  static const neonPinkDeep = Color(0xFFD6117F);

  /// Ikkinchi neon aksent — BREND turkuazimizning (#99E1D9) neon versiyasi.
  static const neonAqua = Color(0xFF16E7CE);

  /// Neon DARK fon — qop-qora, biroz TURKUAZ tusli (binafsha emas).
  static const neonDarkBg = Color(0xFF050B0C);

  /// Neon DARK sirt — fondan biroz ochroq (chegara o'rniga).
  static const neonDarkSurface = Color(0xFF0E1618);

  /// Neon LIGHT fon — oq, biroz TURKUAZ tusli.
  static const neonLightBg = Color(0xFFF3FBFA);

  /// Neon matn (dark) — sovuq oq.
  static const neonTextDark = Color(0xFFEAFBF7);

  // ===== TUNGI HAYDASH (amber) =====
  // 🔴 NEGA ALOHIDA USLUB: tunda ruldagi odam uchun ko'k yorug'lik eng
  // yomoni — u ko'zni qamashtiradi va qorong'ilikka moslashishni buzadi
  // (avtomobil asboblar paneli o'nlab yillardan beri shu sababdan amber).
  // Oddiy «qorong'i rejim» yetarli emas: unda ham oq matn va ko'k aksent
  // qoladi.
  /// Amber aksent — o'qish uchun eng yumshoq issiq rang.
  static const amberAccent = Color(0xFFFFB74D);

  /// Ikkinchi darajali issiq rang.
  static const amberSecondary = Color(0xFFE59866);

  /// Deyarli qora, biroz issiq tusli fon.
  static const amberBg = Color(0xFF0D0906);

  /// Sirt — fondan biroz ochroq (chegara o'rniga).
  static const amberSurface = Color(0xFF1A1310);

  /// Matn — oq EMAS, issiq qumrang: oq tunda juda yorqin.
  static const amberText = Color(0xFFF0D8B8);
}

/// Interfeys USLUBI — rang tizimini butunlay almashtiradi (tuzilma emas).
/// `light`/`dark` (yorug'lik) dan MUSTAQIL o'lchov: har uslub ikkala
/// yorug'likда ham bor.
enum ThemeStyle {
  classic,
  neon,

  /// TUNGI HAYDASH — issiq amber, past kontrast (izohi `BrandColors` da).
  /// Yorug'likdan MUSTAQIL emas: u doim qorong'i, chunki ma'nosi shu.
  amber,
}

/// 🔴 SERIF SARLAVHA SHRIFTI OLIB TASHLANDI (2026-09-02, «YO'L» dizayn
/// tili; egasi qalin groteskni tanladi).
///
/// Ilgari sarlavhalar Fraunces (serif) bilan chizilardi. Muammo shrift
/// tanlovida emas, QAMROVIDA edi — o'lchandi:
///
///     Fraunces-Regular.ttf → kirill belgilar soni: 0
///     Inter-var.ttf        → kirill belgilar soni: 248
///
/// Ya'ni ruscha va o'zbek kirilidagi HAR QANDAY sarlavha tizim shriftiga
/// tushib ketardi: bitta ekranda ikki xil shrift ko'rinardi va bu
/// «bezaksiz» tuyg'uning bir qismi edi. Ikkinchi til qo'shilganda
/// muammo yana kattalashardi.
///
/// Endi sarlavha ham, matn ham BITTA oilada (Inter), farq esa
/// QALINLIK va ZICHLIKDA — bu mobil ilovada serifdan ko'ra kuchliroq
/// ierarxiya beradi va hech qanday til tuzog'i yo'q.

/// ASOSIY INTERFEYS SHRIFTI — butun ilovada.
///
/// 🔴 NEGA QO'SHILDI (egasi, 2026-08-27: «css tegmagandek yoki css chala
/// bo'lgandek»): ilovada interfeys shrifti UMUMAN belgilanmagan edi —
/// `ThemeData` da na `fontFamily`, na `textTheme` bor edi va matn Android
/// standart shriftida chizilardi. Brend shrifti (Fraunces) esa 92 fayldan
/// atigi 12 tasida, QO'LDA qo'llangan. Ya'ni ilovaning tipografik
/// o'ziga xosligi YO'Q edi — aynan «bezaksiz» tuyg'uning bosh sababi.
///
/// 🔑 NEGA AYNAN INTER (o'lchab tanlandi, shrift cmap jadvalidan):
/// o'zbek kirillining `қ Қ ғ Ғ ҳ Ҳ ў Ў` harflari VA o'zbek apostrofi
/// `ʻ` (U+02BB) unda BOR. Manrope sinovdan O'TMADI — unda `қ ғ ҳ` yo'q
/// va ular so'z o'rtasida boshqa shriftga tushib, matn ARALASH
/// ko'rinardi. Bu shriftsizlikdan ham yomonroq bo'lardi.
const kUiFont = 'Inter';

/// TIPOGRAFIK SHKALA — o'lchamlar va qalinliklar ATAYIN tanlangan.
///
/// 🔴 Ilgari shkala umuman yo'q edi: Material'ning standart qiymatlari
/// ishlatilardi va ekranda hamma matn deyarli BIR XIL og'irlikda
/// ko'rinardi. Ierarxiyasiz ekran «tartibga solinmagan» tuyuladi —
/// odam qayerga qarashni bilmaydi.
///
/// Qoida: sarlavhalar QALIN va ZICH (`letterSpacing` manfiy), asosiy matn
/// oddiy, mayda yorliqlar esa KENG oraliqli — bu uchtasi bir-biridan
/// darhol ajralib turadi.
///
/// 🔴 OG'IRLIK ZINAPOYASI (10.09.2026). Yuqoridagi qoida bajarilgan edi-yu,
/// SARLAVHALARNING O'ZARO ierarxiyasi yo'q edi: `displaySmall` (30),
/// `headlineMedium` (26), `headlineSmall` (24) va `titleLarge` (20) —
/// TO'RTALASI HAM `w800`. Ya'ni ular faqat o'lcham bilan farq qilardi,
/// 30 va 26 orasidagi farqni esa ko'z ilg'amaydi. Natijada ekranda
/// «bu yerda to'rtta daraja bor» degan tuyg'u yo'q edi, hammasi bir
/// tekis qalin bo'lib ko'rinardi.
///
/// Apple shkalasi rollarni O'LCHAM VA OG'IRLIK bilan ajratadi
/// (`typography.md` › iOS type sizes): `Large Title`/`Title 1` — Bold,
/// `Title 3`/`Headline` — Semibold, `Body` — Regular. Ya'ni og'irlik
/// pastga tushib boradi.
///
/// Endi bizda ham shunday: `w800` FAQAT bitta darajada qoldi va u
/// haqiqatan ajralib turadi. O'lchamlarga TEGILMADI — egasi «faqat
/// ierarxiyani aniqlashtir» dedi.
///
/// ⚠️ 14 px da IKKI rol bor: `titleSmall` (kichik sarlavha) va
/// `labelLarge` (tugma yozuvi). Ular endi og'irlik bilan farqlanadi —
/// `w600` va `w700`. Bu Apple'ning `Headline`/`Body` juftligining ayni
/// naqshi: bir o'lcham, boshqa og'irlik.
TextTheme _uiTextTheme(TextTheme base) => base.copyWith(
  // EKRAN SARLAVHASI — «YO'L» tilida ekranning eng katta elementi.
  //
  // 🔴 Ilgari eng kattasi 24 edi (`headlineSmall`) va u ro'yxatdagi
  // karta sarlavhasidan atigi 4 px farq qilardi. Ierarxiya bo'lishi
  // uchun eng katta va eng kichik orasida SEZILARLI masofa kerak:
  // 30 → 24 → 20 → 16 → 15 → 13 → 11.
  displaySmall: base.displaySmall?.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.08,
  ),
  headlineMedium: base.headlineMedium?.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.12,
  ),
  headlineSmall: base.headlineSmall?.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  ),
  titleLarge: base.titleLarge?.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  ),
  titleMedium: base.titleMedium?.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  ),
  titleSmall: base.titleSmall?.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  ),
  // Asosiy matn — o'qish uchun `height` KATTA. Zich qatorlar telefonda
  // charchatadi, ayniqsa katta matn rejimida.
  bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
  bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
  bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, height: 1.4),
  // Yorliqlar — MAYDA, lekin keng oraliq bilan: shunda ular «shivirlaydi»,
  // asosiy matn bilan raqobatlashmaydi.
  labelLarge: base.labelLarge?.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  ),
  labelSmall: base.labelSmall?.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  ),
);

/// BREND SARLAVHASI — logotip, kirish ekrani, bo'sh holat sarlavhasi.
///
/// Shrift oilasi O'ZGARTIRILMAYDI (izohi yuqorida): u interfeys shrifti
/// bo'lib qoladi, sarlavhalik esa QALINLIK (w800) va ZICHLIK (-0.6)
/// bilan beriladi. Shu sababli kirill, lotin va apostrof `ʻ` — hammasi
/// bitta shriftda chiziladi.
///
/// ⚠️ Bu yerga `fontFamily` QAYTARIB QO'YMANG. Ilovada kirilli yo'q
/// sarlavha shrifti bo'lsa, ruscha interfeys jimgina buziladi:
/// `flutter analyze` ham, testlar ham buni ko'rmaydi — faqat ko'z.
TextStyle displayFontStyle(TextStyle? base) => (base ?? const TextStyle())
    .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6);

/// TO'Q SARLAVHA BLOKI — ekranning boshidagi «bayonot» maydoni.
///
/// 🔴 NEGA KERAK (2026-09-02, «YO'L» dizayn tili): ekranlar oddiy
/// `AppBar` bilan ochilardi va ilova birinchi qarashda «forma» bo'lib
/// ko'rinardi — nima qilish kerakligi sarlavhadan emas, tugmadan
/// bilinardi. To'q blok esa ekranning maqsadini AYTADI va brend rangini
/// ushlab turadi.
///
/// ⚠️ RANG QO'LDA YOZILMAYDI. To'rtta tema kombinatsiyasi bor
/// (classic/neon × yorug'/tungi, plus doim tungi amber). Yorug'da
/// blok — matn rangining o'zi (eng to'q sirt), tungida esa ochroq
/// sirt: qora ustidagi qora blok ko'rinmaydi.
Color heroSurface(ThemeData theme) => theme.brightness == Brightness.dark
    ? theme.colorScheme.surfaceContainerHigh
    : theme.colorScheme.onSurface;

/// To'q blok ustidagi matn rangi — `heroSurface` ning jufti.
Color onHeroSurface(ThemeData theme) => theme.brightness == Brightness.dark
    ? theme.colorScheme.onSurface
    : theme.colorScheme.surface;

/// Ilova uslubi — «Aralash» (2026-08-13 da namunalardan tanlangan).
///
/// Qoidasi bitta jumlada: **kartaning chegarasi yo'q, chuqurlik yumshoq soya
/// bilan beriladi; qorong'ida soya o'rniga ochroq sirt ishlaydi.**
///
/// Ikkita shart buzilmasin, aks holda uslub qulaydi:
///
///  1. FON kartadan TO'QROQ bo'lishi shart (`#F7F5F7` va oq). Ikkalasi ham
///     oq bo'lsa chegarasiz karta butunlay yo'qoladi — faqat pastki soyasi
///     ko'rinib qoladi (namunada aynan shunday bo'ldi).
///  2. QORONG'IDA soya chizilmaydi: qora ustidagi qora soya ko'rinmaydi,
///     faqat hisoblash vaqtini yeydi. Chuqurlik `surface` ning fondan
///     ochroqligidan kelib chiqadi.
ThemeData buildTheme({
  required Brightness brightness,
  ThemeStyle style = ThemeStyle.classic,
}) {
  final isDark = brightness == Brightness.dark;
  final neon = style == ThemeStyle.neon;
  // Amber DOIM qorong'i: «tunda yorug' amber» degan narsa yo'q.
  final amber = style == ThemeStyle.amber;

  // ===== USLUBGA BOG'LIQ RANGLAR (yagona manba) =====
  // Neon uslub faqat RANG va PORLASHNI almashtiradi — o'lchamlar, radius,
  // komponentlar bir xil qoladi (egasi: "tuzilmani emas, ko'rinishni").
  // Aksent YORUG'LIKKA qarab almashadi — izohi `BrandColors.pinkInk` da:
  // yorug' temada TO'Q aksent + oq yozuv, to'q temada OCH aksent + qora
  // yozuv. O'lchov (eng yomon holat): 4.87:1 dan past tushmaydi.
  final accent = amber
      ? BrandColors.amberAccent
      : neon
      ? (isDark ? BrandColors.neonPink : BrandColors.neonPinkDeep)
      : (isDark ? BrandColors.pinkInk : BrandColors.pink);
  final accent2 = amber
      ? BrandColors.amberSecondary
      : (neon ? BrandColors.neonAqua : BrandColors.turquoise);
  // OCH aksent ustidagi matn qora bo'lishi shart — amber allaqachon
  // shunday edi, endi to'q temaning pushtisi ham shu qoidaga bo'ysunadi.
  final onAccent = amber
      ? const Color(0xFF231404)
      : neon
      ? (isDark ? const Color(0xFF06100F) : Colors.white)
      : (isDark ? const Color(0xFF241016) : Colors.white);

  final bg = amber
      ? BrandColors.amberBg
      : neon
      ? (isDark ? BrandColors.neonDarkBg : BrandColors.neonLightBg)
      // 🔴 YORUG' ZAMIN CHUQURROQ (10.09.2026, o'lchandi): eski
      // `#F7F5F7` oq kartadan atigi 1.08 : 1 farq qilardi — karta
      // «suzmasdi», sahifaga yopishib turardi. `#EFECEF` da farq
      // 1.17 : 1 bo'ladi va ikkilamchi matn hamon 4.82 : 1
      // (AA dan yuqori). Izohi `surfaceDark` da.
      : (isDark ? const Color(0xFF161316) : const Color(0xFFEFECEF));
  final surface = amber
      ? BrandColors.amberSurface
      : neon
      ? (isDark ? BrandColors.neonDarkSurface : Colors.white)
      : (isDark ? BrandColors.surfaceDark : Colors.white);
  final onSurface = amber
      ? BrandColors.amberText
      : neon
      ? (isDark ? BrandColors.neonTextDark : const Color(0xFF0B0E14))
      : (isDark ? const Color(0xFFF2EEF1) : BrandColors.wineAsh);
  /*
   * 🔴 IKKINCHI DARAJALI MATN RANGI — YORUG' TEMADA JUDA OCH EDI
   * (2026-09-04, o'lchandi).
   *
   * Eski #8A7F86 sahifa zaminida 3.55 : 1, oq kartada 3.85 : 1 —
   * WCAG AA 4.5 : 1 dan past. Bu rang ilovadagi HAMMA tushuntirish
   * matnida ishlatiladi: bo'sh ekrandagi «Bu yo'nalishda haydovchilar
   * hali e'lon bermagan», forma maslahatlari, karta ostidagi izohlar.
   * Ya'ni eng ko'p O'QILADIGAN matn eng yomon ko'rinardi.
   *
   * Yangi qiymat SAYTNIKI bilan bir xil (`--text-secondary` #6B6570):
   * zaminda 5.20 : 1, oq kartada 5.64 : 1. Tungi temadagi #9E949A esa
   * allaqachon yetarli (6.28 / 5.52) — u tegilmadi.
   *
   * Qo'riqchi: `contrast_audit_test.dart` (29 ekran × yorug'/tungi).
   */
  final onSurfaceVariant = amber
      ? const Color(0xFFB89878)
      : neon
      ? (isDark ? const Color(0xFF8B8AA6) : const Color(0xFF6E6C8A))
      // 🔴 TUNGI QIYMAT OCHROQ QILINDI (10.09.2026, o'lchandi).
      //
      // Eski `#9E949A` faqat ESKI, to'qroq sirt (`#241F23`) uchun
      // yetarli edi. Qatlamlar joriy qilingach (izohi `surfaceDark`
      // da) sirtlar ochroq bo'ldi va u pastki amal panelida
      // **3.77 : 1** ga tushdi — AA dan past. Buni kontrast auditi
      // tutdi.
      //
      // `#B0A6AC` to'rtala zaminda ham yetarli:
      //   zamin #161316          7.81 : 1
      //   karta #2E2830          6.08 : 1
      //   panel #3F3941          4.75 : 1
      : (isDark ? const Color(0xFFB0A6AC) : const Color(0xFF6B6570));
  final outlineVariant = amber
      ? const Color(0xFF3A2A1C)
      : neon
      ? (isDark ? const Color(0xFF2A2540) : const Color(0xFFE2DEF3))
      : (isDark ? const Color(0xFF3A3339) : const Color(0xFFE6E0E4));
  // Neon PORLASHI — tugma/karta ostidagi rangли yolqin. Classic'да yo'q
  // (u soyaga tayanadi). Statik: animatsiya YO'Q (spec qoidasi buzilmaydi).
  final glow = accent.withValues(alpha: neon ? 0.55 : 0.0);
  /*
   * O'CHIQ TUGMA RANGLARI — bitta joyda hisoblanadi.
   *
   * Nisbatlar (0.14 / 0.78) O'LCHOVDAN: ular to'rtala tema
   * kombinatsiyasida ham kontrastni 5.47 : 1 dan pastga tushirmaydi
   * (classic yorug' — eng qiyin holat), ya'ni WCAG 4.5 talabidan
   * yuqori. Izohi `filledButtonTheme` da.
   */
  final disabledButtonBg = Color.alphaBlend(
    onSurface.withValues(alpha: 0.14),
    surface,
  );
  final disabledButtonFg = Color.alphaBlend(
    onSurface.withValues(alpha: 0.78),
    disabledButtonBg,
  );

  final borderColor = neon
      ? accent.withValues(alpha: isDark ? 0.35 : 0.25)
      : (isDark ? Colors.white24 : const Color(0xFFE0D9DE));

  final scheme =
      ColorScheme.fromSeed(
        seedColor: accent,
        // Amber uslubi DOIM qorong'i — yorug'lik tanlovidan qat'i nazar.
        brightness: amber ? Brightness.dark : brightness,
      ).copyWith(
        primary: accent,
        onPrimary: onAccent,
        secondary: accent2,
        onSecondary: amber
            ? const Color(0xFF231404)
            : (neon ? const Color(0xFF06121A) : BrandColors.wineAsh),
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        /*
         * 🔴 `outline` NI TEMA O'ZI YASAB BERARDI VA U MATN UCHUN
         * JUDA OCH EDI (2026-09-04, o'lchandi).
         *
         * `ColorScheme.fromSeed` uni SEED rangidan hosil qiladi —
         * bizda seed pushti, ya'ni «kulrang» aslida pushtiga moyil
         * #837377 edi va sahifa zaminida 4.13 : 1 berardi.
         *
         * Nomi «chegara» bo'lsa ham, ilovada u 136 joyda MATN rangi:
         * bo'lim yorliqlari («KIRILGAN QURILMALAR»), bo'sh ekran
         * izohlari, forma maslahatlari. Ya'ni o'qiladigan matn hech
         * kim o'lchamagan avtomatik rangda chizilardi. Endi u ham
         * ikkinchi darajali matn bilan bir xil, o'lchangan rang.
         *
         * ⚠️ Chegaralar uchun alohida `outlineVariant` bor — u
         * o'zgarmadi, ya'ni ramkalar quyuqlashib ketmadi.
         */
        outline: onSurfaceVariant,
        outlineVariant: outlineVariant,
        /*
         * 🔴 NEYTRAL SIRTLAR HAQIQATAN NEYTRAL BO'LSIN (2026-09-02).
         *
         * `ColorScheme.fromSeed` `surfaceContainer*` oilasini SEED
         * rangidan hosil qiladi — bizda seed pushti, ya'ni ilovadagi
         * hamma «neytral» sirt pushtiga bo'yalgan edi. Oqibatlari
         * ko'z bilan ko'rindi:
         *
         *   • band o'rindiq bo'sh o'rindiqdan farq qilmasdi (ikkalasi
         *     ham och pushti);
         *   • mikrofon tugmasi asosiy «Qidirish» tugmasi bilan bir xil
         *     e'tibor tortardi, holbuki u ikkinchi darajali;
         *   • «bitta ekranda bitta pushti» qoidasini saqlab bo'lmasdi:
         *     pushti temaning O'ZIDAN sizib chiqardi.
         *
         * Endi ular matn rangining shaffof qatlamlaridan hosil
         * qilinadi, ya'ni tema qanday bo'lishidan qat'i nazar zamin
         * bilan bir oilada va RANGSIZ bo'ladi.
         */
        surfaceContainerLowest: Color.alphaBlend(
          onSurface.withValues(alpha: 0.02),
          surface,
        ),
        surfaceContainerLow: Color.alphaBlend(
          onSurface.withValues(alpha: 0.04),
          surface,
        ),
        surfaceContainer: Color.alphaBlend(
          onSurface.withValues(alpha: 0.06),
          surface,
        ),
        surfaceContainerHigh: Color.alphaBlend(
          onSurface.withValues(alpha: 0.09),
          surface,
        ),
        surfaceContainerHighest: Color.alphaBlend(
          onSurface.withValues(alpha: 0.12),
          surface,
        ),
      );

  final baseText = (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    // 🔴 BUTUN ILOVA UCHUN — ilgari bu yo'q edi (izohi `kUiFont` da).
    fontFamily: kUiFont,
    // 🔴 `.apply(fontFamily:)` SHART (10.09.2026, o'lchandi): yuqoridagi
    // `fontFamily` YOLG'IZ O'ZI ISHLAMAYDI. `ThemeData` avval uni
    // STANDART shkalaga qo'llaydi, keyin bizning `textTheme` ni ustiga
    // MERGE qiladi — bizniki esa `ThemeData.light().textTheme` dan
    // ko'chirilgan va uning har bir uslubida `fontFamily: 'Roboto'`
    // OSHKORA yozilgan. Ya'ni merge Inter'ni Roboto bilan almashtirib
    // ketardi va 27.08.2026 dagi butun shrift qarori KUCHGA KIRMAGAN
    // edi.
    //
    // Buni ko'z bilan sezish deyarli imkonsiz: Roboto ham kirillni
    // chizadi, ya'ni matn «ishlayotgandek» ko'rinadi — shunchaki
    // biz tanlagan shrift emas. Tekshirish yo'li BITTA:
    //     buildTheme(...).textTheme.bodyMedium?.fontFamily
    // `Inter` qaytarishi kerak (`theme_font_test.dart`).
    textTheme: _uiTextTheme(baseText).apply(fontFamily: kUiFont),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontFamily: kUiFont,
        fontSize: 20,
        // Shkaladagi `titleLarge` bilan bir xil: sarlavha ekran ichidagi
        // sarlavhalardan farq qilmasin.
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      // Classic: chegara yo'q — chuqurlik soyadan (yorug') yoki sirt
      // ochroqligidan (qorong'i). Neon: yengil rangли yolqin (glow) va
      // ingichka neon chegara — kartaning cheti "porlaydi".
      // 🔴 PREMIUM «CRISP CARD» (12.09.2026): ilgari yorug'da faqat
      // Material elevation-2 soyasi bor edi — u qisqa, to'q va biroz
      // «bo'g'iq» (wine-ash 15% da). Karta chetida ANIQ chiziq yo'q
      // edi, shuning uchun u kulrang zaminга «yopishib» turgandek
      // ko'rinardi (egasi: «arzon/xom»). Endi iOS'ning puxta usuli:
      //   • YUMSHOQROQ, kengroq soya (elevation 3, atigi 9% wine-ash)
      //     — karta og'irlashmasdan «suzadi»;
      //   • NOZIK hairline chegara (ink 6%) — chet ANIQ, karta zamindan
      //     toza ajraladi. Ikkisi birga = puxta, tiniq karta.
      elevation: neon ? 6 : (isDark ? 0 : 3),
      shadowColor: neon
          ? glow
          : (isDark ? Colors.transparent : const Color(0x1732292F)),
      // M3 balandlik bilan birga sirtga o'z rangini qo'shadi va oq karta
      // pushtiga bo'yalib ketardi. Brend rangi FAQAT biz qo'ygan joyda.
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: neon
            ? BorderSide(color: accent.withValues(alpha: 0.30))
            : (isDark
                  ? BorderSide.none
                  : BorderSide(color: onSurface.withValues(alpha: 0.06))),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
        // 🔴 O'CHIQ TUGMA — NEYTRAL VA O'QILADIGAN (2026-09-02 ko'rigi).
        //
        // Ilgari u brend rangining 40% i edi, yozuvi esa `white70`.
        // Ikkita xato bir joyda:
        //
        //   1. KO'RINISHI YONIQ. To'q pushti fon «bosiladigan» degan
        //      ma'no beradi — odam bosadi, hech nima bo'lmaydi va
        //      ilova buzuq deb o'ylaydi;
        //   2. YOZUVI O'QILMAYDI. O'lchandi (WCAG kontrast nisbati):
        //        classic yorug' → 1.62 : 1
        //        neon yorug'    → 1.54 : 1
        //        amber          → 1.21 : 1
        //      Talab — 4.5 : 1. Ya'ni tugmada nima yozilgani ko'rinmasdi.
        //
        // Endi fon zamin rangidan biroz to'qroq (neytral), yozuv esa
        // o'sha zaminga nisbatan 5.5–8.2 : 1 — to'rtala temada ham.
        // Qo'riqchisi: `accessibility_test.dart`.
        disabledBackgroundColor: disabledButtonBg,
        disabledForegroundColor: disabledButtonFg,
        minimumSize: const Size.fromHeight(AppSize.buttonHeight),
        // Neonда tugma ostidan rangли yolqin chiqadi (porlash).
        elevation: neon ? 10 : 0,
        shadowColor: neon ? glow : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        // 🔴 `fontFamily` SHART (10.09.2026, ko'z bilan ko'rildi):
        // `styleFrom` ga berilgan YALANG'OCH `TextStyle` merosni
        // ALMASHTIRADI, ya'ni tugma matni tema shriftidan tushib,
        // TIZIM shriftiga o'tib ketardi. Ekranda bu shunday ko'rinardi:
        // butun ilova Inter'da, tugma esa boshqa shriftda — «bitta
        // ilovada ikki xil harf». Xuddi shu `snackBarTheme` va
        // `chipTheme` da ham bor edi. Qo'riqchi: `theme_font_test.dart`.
        textStyle: const TextStyle(
          fontFamily: kUiFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: const Size.fromHeight(AppSize.buttonHeight),
        side: BorderSide(
          color: neon ? accent : borderColor,
          width: neon ? 1.4 : 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      /*
       * 🔴 MASLAHAT VA IZOH MATNI IKKI QATORGA SIG'ADI (2026-09-04).
       *
       * Flutter standarti — bitta qator: uzun matn jimgina kesiladi.
       * O'lchandi: posilka yaratishda «Например: документы, 2 кг
       * фруктов» 187/289 px, «Водители ориентируются на неё» 248/259,
       * «Чтобы водитель мог связаться» 206/250 — ya'ni maydon nima
       * kutayotganini AYTA OLMASDI.
       *
       * ⚠️ Bu xatoni toshish auditi tutmaydi: `ellipsis` toshishni
       * yutadi. Bitta joyda tuzatilsa — hamma forma tuzaladi.
       */
      // ⚠️ IKKI qator, ko'p emas: to'rt qatorda telefon ekranidagi
      // maydon 320 px va 1.3 shkalada 34 px pastga toshib ketdi
      // (o'lchandi). Uzunroq maslahat kerak bo'lsa, u AYNAN o'sha
      // maydonda beriladi (`support_sheet.dart` ga qarang).
      hintMaxLines: 2,
      helperMaxLines: 2,
      errorMaxLines: 2,
      filled: true,
      fillColor: neon
          ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white)
          : (isDark ? Colors.white10 : Colors.white),
      contentPadding: const EdgeInsets.all(AppSpace.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: borderColor),
      ),
      // Neonда fokus cyan bilan porlaydi (pushti-cyan juftlik).
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: neon ? accent2 : accent, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: neon
          ? accent.withValues(alpha: 0.22)
          : (isDark ? BrandColors.pinkHover : BrandColors.pinkLight),
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    /*
     * VARAQ TUTQICHI — BUTUN ILOVAGA, BIR JOYDAN.
     *
     * 🔴 NEGA (10.09.2026, o'lchandi): ilovada `showModalBottomSheet`
     * YIGIRMA joyda chaqiriladi. `useSafeArea: true` yigirmatasida ham
     * bor edi (bu yaxshi), lekin `showDragHandle: true` — atigi
     * IKKITASIDA. Ya'ni o'n sakkizta varaqda «meni pastga surib
     * yopsa bo'ladi» degan KO'RINADIGAN belgi yo'q edi.
     *
     * Apple buni majburiy deb yozadi: «Modal oynani yopishning ANIQ
     * yo'lini har doim bering — iOS'da odam yuqoridagi tugmani yoki
     * PASTGA SURISHNI kutadi» (`modality.md` › Best practices).
     * Tutqich aynan o'sha kutilgan belgidir.
     *
     * ⚠️ Bu 18 ta chaqiruvni qo'lda tahrirlash o'rniga TEMADA
     * qilindi: aks holda yangi varaq yozgan odam yana unutardi va
     * ro'yxat yana ikkiga bo'linardi.
     *
     * ⚠️ Tutqich `SheetDragToClose` dan BOSHQA narsa: u ko'rinadigan
     * BELGI, o'sha esa suriladigan mazmun ustida imo-ishorani
     * qaytaradigan mexanizm. Ikkalasi bir-birini almashtirmaydi —
     * izohi `sheet_drag_to_close.dart` da.
     */
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      dragHandleColor: scheme.outlineVariant,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.hero),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: neon ? const Color(0xFF1C1730) : BrandColors.wineAsh,
      // `fontFamily` — izohi `filledButtonTheme` da.
      contentTextStyle: const TextStyle(
        fontFamily: kUiFont,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
    ),
    /*
     * SLAYDER — KATAKCHALARSIZ.
     *
     * 🔴 O'LCHAB TOPILDI (2026-09-03 ko'rigi): «Radius» slayderida
     * `divisions: 19` bor va Material har bo'linma uchun yo'lakda
     * NUQTA chizadi — natijada ekranda yigirmata mayda dog' qatori
     * turardi. Ular hech qanday ma'no bermaydi: aniq qiymat
     * slayderning USTIDA matn bilan yozilgan («Radius: 25 km»).
     * Qadamlash saqlanadi, ko'rinish esa tozalanadi.
     */
    sliderTheme: SliderThemeData(tickMarkShape: SliderTickMarkShape.noTickMark),
    chipTheme: ChipThemeData(
      backgroundColor: neon
          ? accent2.withValues(alpha: isDark ? 0.14 : 0.12)
          : (isDark ? Colors.white10 : BrandColors.turquoiseLight),
      side: neon
          ? BorderSide(color: accent2.withValues(alpha: 0.4))
          : BorderSide.none,
      labelStyle: TextStyle(
        // `fontFamily` — izohi `filledButtonTheme` da.
        fontFamily: kUiFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: neon ? onSurface : (isDark ? Colors.white : BrandColors.wineAsh),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
    ),
  );

  /*
   * NAQSH RANGLARI — TEMANING BIR QISMI.
   *
   * 🔴 Nega kengaytma sifatida (saytda o'lchab topilgan xato): relyef
   * ranglari vidjetda QOTIRIB yozilganda tungi rejimda butun sahifa oq
   * to'r bilan qoplanib, matn o'qilmay qolgandi. Ilovada tema BESHTA
   * kombinatsiyada bo'ladi (classic/neon × yorug'/tungi, plus amber) —
   * ya'ni xato ehtimoli besh barobar. Endi naqsh rangi bitta joyda,
   * tema ranglaridan hosil bo'ladi.
   */
  return base.copyWith(
    extensions: [
      OrnamentTokens.forTheme(base).copyWith(
        // TO'QUV TERMASI USLUBGA QARAB: tungi haydashda sovuq rang
        // BO'LMASLIGI shart (izohi `AtlasPalette.amber` da).
        threads: switch (style) {
          ThemeStyle.classic => AtlasPalette.all,
          ThemeStyle.amber => AtlasPalette.amber,
          ThemeStyle.neon => AtlasPalette.neon,
        },
      ),
    ],
  );
}

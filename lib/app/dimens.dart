/// O'lchov tizimi — bo'shliq va radius uchun YAGONA manba.
///
/// NEGA KERAK BO'LDI (2026-08-13 o'lchov): ekranlarda vertikal bo'shliqning
/// 15 xil qiymati (2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 48, 64),
/// `EdgeInsets.all` ning 7 xil qiymati va temadan tashqarida qo'lda yozilgan
/// 7 xil radius ishlatilardi. Har biri alohida to'g'ri ko'rinardi, lekin
/// yonma-yon turganda ilova yig'ma bo'lib ko'rinardi: bitta ekranda bir xil
/// ma'nodagi quti 6, 14 va 16 radius bilan chizilgan edi.
///
/// QOIDA: bu yerdagi qiymatlardan tashqari son ISHLATILMAYDI. Yangi qiymat
/// kerak bo'lsa — avval shu faylga qo'shiladi va nomi bilan asoslanadi.
/// Buni `test/design_system_test.dart` tekshiradi.
library;

/// Bo'shliq shkalasi. Oraliq qiymat YO'Q: 10 yoki 18 kerak bo'lsa, demak
/// tanlov 8 va 12 (yoki 16 va 24) orasida — ikkisidan biri tanlanadi.
abstract final class AppSpace {
  /*
   * ═══════════════════════════════════════════════════════════════
   *  SEMANTIK ORALIQLAR — «qancha» emas, «NIMA orasida»
   * ═══════════════════════════════════════════════════════════════
   *
   * 🔴 NEGA QO'SHILDI (10.09.2026). Quyidagi shkala to'g'ri edi-yu,
   * u faqat O'LCHAMNI aytardi. Amalda esa kartalar ichida deyarli
   * hamma joyda `lg` (16) ishlatilgan: bir guruh ichidagi ikki qator
   * orasida ham, ikki GURUH orasida ham. Ya'ni «bular birga» va
   * «bular alohida» degan farq ko'rinmasdi va karta ichida ierarxiya
   * yo'q edi — hamma narsa bir tekis oqim bo'lib turardi.
   *
   * Apple qoidasi (`layout.md`): «Bog'liq narsalarni guruhlang —
   * BO'SH JOY, shakl, rang yoki material bilan» va «Muhim ma'lumotga
   * YETARLI JOY bering».
   *
   * Yangi raqam qo'shilmadi — borlariga NOM berildi. Endi kod
   * o'lchamni emas, NIYATNI aytadi.
   */

  /// BIR GURUH ICHIDA — o'zaro bog'liq qatorlar orasida.
  /// («Jo'nash sanasi» va uning qiymati, ikkita qulaylik belgisi.)
  static const betweenItems = sm;

  /// GURUHLAR ORASIDA — mustaqil bo'limlar orasida.
  /// («Yo'nalish» bloki tugadi, «Haydovchi» bloki boshlandi.)
  ///
  /// ⚠️ `lg` (16) EMAS: aynan shu farq guruhni guruh qiladi. Agar
  /// ikkalasi ham 16 bo'lsa, karta bitta uzun ro'yxatga aylanadi.
  static const betweenGroups = xl;

  /// Bir-biriga tegishli ikki satr orasida (yorliq va qiymat).
  static const xxs = 2.0;
  static const xs = 4.0;

  /// Bitta blok ichidagi elementlar orasida.
  static const sm = 8.0;

  /// Ro'yxat elementlari orasida.
  static const md = 12.0;

  /// Standart chekka va bloklar orasi.
  static const lg = 16.0;

  /// EKRAN CHEKKASI — 2026-09-02, «YO'L» dizayn tili.
  ///
  /// 🔴 NEGA `lg` DAN AJRATILDI: ekran chekkasi ham 16 edi, ya'ni matn
  /// telefon qirrasiga karta ichidagi elementlar bilan BIR XIL yaqinlikda
  /// turardi. Natijada sahifada «havo» yo'q edi va ilova zich, arzon
  /// ko'rinardi. 20 — o'lchangan eng kichik qiymat: 320 px ekranda ham
  /// matnga yetarli joy qoldiradi, 360+ da esa sezilarli yengillik beradi.
  ///
  /// ⚠️ FAQAT ekranning tashqi chekkasi uchun. Karta ichida `lg` qoladi —
  /// aks holda kartalar shishib ketadi.
  static const screen = 20.0;

  /// Bo'limlar orasi.
  static const xl = 24.0;

  /// Katta ajratish — forma oxiri, bo'sh holat.
  static const xxl = 32.0;

  /// Bo'sh ekranning markazidagi katta bo'shliq.
  static const huge = 48.0;
}

/// Qat'iy o'lchamlar — bo'shliq ham, radius ham emas.
abstract final class AppSize {
  /// Asosiy tugma balandligi. Barmoq uchun eng kichik qulay o'lcham 48;
  /// 52 — undan bir oz kattaroq, chunki tugmalar ko'pincha ekran pastida,
  /// bosh barmoq yetadigan chekkada turadi.
  static const buttonHeight = 52.0;

  /// Joyi CHEKLANGAN yerdagi tugma (profil sarlavhasidagi "Tahrirlash").
  ///
  /// Sarlavha balandligi mazmunga qarab hisoblanadi va standart 52 unga
  /// sig'maydi. Bu YAGONA istisno — boshqa joyda ishlatilmaydi.
  static const buttonHeightCompact = 40.0;

  /// Natijalar ekranidagi ikki qatorli sarlavha uchun panel balandligi.
  /// Standart 56 ga yo'nalish va uning ostidagi sana qatori sig'maydi.
  static const resultsToolbar = 68.0;

  /// Surat yuklash tugmasi — ichida ikonka va ikki qatorli yozuv turadi,
  /// shuning uchun oddiy tugmadan baland.
  ///
  /// 🔴 Ilgari ikki joyda ikki xil edi (88 va 96) — bir xil vazifadagi
  /// tugma ikki xil ko'rinardi (egasi qurilmada aytdi, 2026-08-13).
  static const photoButtonHeight = 96.0;

  /// Yuklangan suratning ko'rinish balandligi. Bu ham ikki xil edi (140/160).
  static const photoPreviewHeight = 160.0;
}

/// Radius. To'rttasining har biri boshqa ROLGA tegishli — o'zaro
/// almashtirilmaydi.
abstract final class AppRadius {
  /// Kartalar va ma'lumot qutilari (`cardTheme` bilan bir xil).
  ///
  /// 16 → 20 (2026-09-02): 16 «tizimli» ko'rinardi-yu, iliqlik bermasdi.
  /// 20 da karta qo'lga olsa bo'ladigan buyumga o'xshaydi — bu ishonch
  /// talab qiladigan mahsulotda muhim.
  static const card = 20.0;

  /// Bosiladigan boshqaruvlar: tugma, maydon (`filledButtonTheme` bilan
  /// bir xil). 14 → 16 (2026-09-02): karta radiusi bilan bir oilada
  /// bo'lsin, aks holda tugma karta ichida begona ko'rinadi.
  static const control = 16.0;

  /// Kichik yorliq — davlat raqami, holat belgisi. Katta radius kichik
  /// elementda ovalga aylanib ketadi.
  static const badge = 8.0;

  /// TO'Q SARLAVHA BLOKI — ekran tepasidagi «bayonot» maydonining
  /// pastki burchaklari. Kartadan KATTA: blok ekran kengligida va
  /// unda 20 radius deyarli sezilmaydi, 28 esa blokni ekranga
  /// «qo'yilgan» qilib ko'rsatadi.
  static const hero = 28.0;

  /// To'liq dumaloq: avatar o'rni, "tabletka" tugma.
  static const pill = 999.0;

  /// SALON KONTURI — o'rindiq sxemasidagi «mashina» shakli
  /// (`seat_map.dart`). Ikkita qiymat, chunki shakl SIMMETRIK EMAS:
  /// tepasi keng yumaloq (old oyna), pasti tor. Bu tepadan qaralgan
  /// salon — shuning uchun u boshqa hech qayerda ishlatilmaydi.
  ///
  /// ⚠️ Tepa radiusi karta radiusidan (20) KATTA: aks holda kontur
  /// kartaning ichidagi yana bitta karta bo'lib ko'rinadi, mashina
  /// bo'lib emas.
  static const salonTop = 26.0;
  static const salonBottom = 12.0;

  /// KATTA sirt: profil sarlavhasi, pastdan chiqadigan varaq. Kartadan
  /// kattaroq, chunki u butun ekran kengligida — kartaning radiusi bunday
  /// yuzada ko'rinmay qoladi.
  static const sheet = 28.0;

  /// Chat pufagining "dumi" — jo'natuvchi tomonidagi burchak. Qolgan uchtasi
  /// [card] bo'ladi, shu bittasi kichik: pufak kimdan kelganini shu burchak
  /// bildiradi.
  static const bubbleTail = 4.0;
}

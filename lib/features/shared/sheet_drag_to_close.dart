import 'package:flutter/material.dart';

import '../../core/haptics.dart';

/// VARAQ MAZMUNINI PASTGA SURIB YOPISH.
///
/// 🔴 NEGA YOZILDI (egasi, 2026-08-26: «tarif tafsiloti varag'ini ham
/// qara»): o'lchab ko'rilganda ma'lum bo'ldiki, mazmuni SURILADIGAN
/// varaqni pastga surib yopib bo'lmaydi. Test raqami: varaq ochildi,
/// 500 px pastga surildi — varaq HALI OCHIQ.
///
/// Sabab Flutter'ning imo-ishora maydonchasida: mazmun surilishi mumkin
/// bo'lsa, ichki `Scrollable` imo-ishorani O'ZIGA oladi va `BottomSheet`
/// ning «pastga surib yopish» harakati umuman ishga tushmaydi. Odam esa
/// tepada turib pastga suradi — ro'yxat qimirlamaydi (u allaqachon
/// tepada), varaq ham yopilmaydi. **Barmoq ostida hech nima bo'lmaydi**,
/// va bu aynan «qotish» tuyg'usini beradi.
///
/// ═══ NEGA `DraggableScrollableSheet` EMAS ═══
///
/// U shu muammoning odatiy yechimi (loyihada shahar tanlashда ishlatilgan)
/// va TO'G'RI yechim — lekin varaqni ekran balandligining QAT'IY ULUSHI
/// bilan ochadi. Bizdagi varaqlar esa mazmuniga qarab qisqaradi: qisqa
/// tarif kartasi kichkina varaqda ochiladi. Qat'iy ulushga o'tsak, qisqa
/// mazmun yarim bo'sh varaqda osilib turardi — bitta xatoni tuzatib,
/// ko'rinishni buzgan bo'lardik.
///
/// Shuning uchun boshqa yo'l: ro'yxat TEPASIDA turib pastga surilganda
/// `OverscrollNotification` keladi (chekkadan nariga tortilgan masofa).
/// O'shani yig'amiz va chegaradan oshsa varaqni yopamiz.
///
/// ═══ IKKI QAT'IY SHART — ular bo'lmasa varaq O'ZIDAN O'ZI yopiladi ═══
///
///  1. **`dragDetails != null`** — ya'ni bu BARMOQ tortishi. Inersiya
///     bilan uchib kelib chekkaga urilgan ro'yxat ham overscroll beradi;
///     usiz tez surib yuborilganда varaq o'zi yopilardi.
///  2. **Har tortishda hisob NOLDAN** (`ScrollStartNotification`). Aks
///     holda kun bo'yi to'plangan mayda overscroll'lar qo'shilib, odam
///     kutmagan payt varaq yopilardi.
///
/// ═══ QAYERDA ISHLATILMAYDI ═══
///
/// 🔴 SAQLANMAGAN KIRITMASI BOR varaqqa QO'YILMAYDI. Ilovada surilаdigan
/// varaqlar to'rtta, lekin uchtasida odamning yozgani turadi:
///
///   • `filter_bar` — narx maydonlari faqat «Qo'llash» bosilganda
///     yoziladi (`_apply`), ya'ni surib yopilsa terilgan narx yo'qoladi;
///   • `add_car_sheet` — mashina formasi;
///   • `support_sheet` — murojaat matni.
///
/// Ularda «tasodifan yopilib, yozganim yo'qoldi» — «biroz qotgandek»
/// tuyg'usidan ANCHA yomon. U yerda yopish tutqich va tashqariga bosish
/// orqali qoladi. Bu ataylab, unutilgani uchun emas.
class SheetDragToClose extends StatefulWidget {
  const SheetDragToClose({super.key, required this.child});

  final Widget child;

  @override
  State<SheetDragToClose> createState() => _SheetDragToCloseState();
}

class _SheetDragToCloseState extends State<SheetDragToClose> {
  /// Shu tortishда chekkadan nariga tortilgan masofa.
  double _pulled = 0;

  /// Yopish chegarasi.
  ///
  /// 90 px — tasodifiy tegishdan uzoq, lekin qo'lni cho'zishni ham talab
  /// qilmaydi. Material varaqlarining yopilish masofasi ham shu atrofda.
  static const _threshold = 90.0;

  bool _onNotification(ScrollNotification notification) {
    // Yangi tortish — hisob noldan.
    if (notification is ScrollStartNotification ||
        notification is ScrollEndNotification) {
      _pulled = 0;
      return false;
    }

    if (notification is! OverscrollNotification) return false;
    // Barmoq tortmayapti (inersiya) — tegmaymiz.
    if (notification.dragDetails == null) return false;
    // Musbat overscroll — ro'yxat OXIRIDA. Bizga faqat tepasi kerak.
    if (notification.overscroll >= 0) return false;

    _pulled += -notification.overscroll;
    if (_pulled < _threshold) return false;

    _pulled = 0;
    AppHaptics.select();
    // `maybePop` — varaq allaqachon yopilgan bo'lsa ham xavfsiz.
    Navigator.of(context).maybePop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // `false` qaytaramiz — xabarni YUTMAYMIZ: undan yuqorida turgan
    // `RefreshIndicator`/`Scrollbar` kabi vidjetlar ham shu xabarlarni
    // eshitadi va ular buzilmasligi kerak.
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}

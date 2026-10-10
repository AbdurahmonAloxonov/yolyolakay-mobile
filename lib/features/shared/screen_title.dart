import 'package:flutter/material.dart';

/// EKRAN SARLAVHASI — sarlavha panelida hech qachon kesilmaydi.
///
/// 🔴 NEGA YOZILDI (2026-09-04, o'lchandi): sarlavha paneli sarlavhani
/// jimgina kesadi. 320 px va 1.3 shkalada ruscha ekranlarda shunday
/// chiqdi:
///
///     «Опубликовать поездку»    288 / 302 px
///     «Редактировать профиль»   288 / 321 px
///     «Детали поездки»          192 / 213 px
///     «Найденные поездки»       240 / 266 px
///
/// Ya'ni odam ochgan ekran O'Z NOMINI ayta olmasdi.
///
/// 🔑 Yechim — QISQARTIRISH emas, KICHRAYTIRISH: `FittedBox` matnni
/// joyga sig'adigan qilib bir oz kichraytiradi. Ikki qatorga o'tkazish
/// mumkin emas — sarlavha panelining balandligi qat'iy; uch nuqta esa
/// nomni yo'q qiladi.
///
/// ⚠️ `scaleDown`: matn faqat KERAK BO'LSA kichrayadi, kattalashmaydi —
/// keng ekranda ko'rinish o'zgarmaydi.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    /*
     * ⚠️ BU YERDA `Semantics(header: true)` YO'Q — ATAYIN (o'lchandi,
     * 2026-09-04). Oddiy `AppBar` sarlavhani O'ZI «header» qilib
     * belgilaydi; bu yerda yana belgilansa, ichma-ich ikkita tugun
     * hosil bo'lib, tashqarisi BO'SH NOMLI sarlavhaga aylanadi va
     * ekran o'qigich «sarlavha» deb bo'sh joyni e'lon qiladi.
     * Belgi faqat u BUZILGAN joyda qo'yiladi — `CollapsingScaffold`.
     */
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, style: style, maxLines: 1, softWrap: false),
    );
  }
}

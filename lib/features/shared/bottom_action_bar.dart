import 'package:flutter/material.dart';


/// ASOSIY AMAL PANELI — suriladigan formaning tagida QOTIB turadi.
///
/// 🔴 NEGA ALOHIDA VIDJET (egasi, 2026-09-02: «hamma telefonlarni
/// o'ylab qilish kerak, ko'rinmay qolgandir»):
///
/// «Keyingisi tugmasi yo'q» degan shikoyat TO'RT marta keldi (12, 27,
/// 28, 30-avgust) va har safar sabab BOSHQA edi — tugma o'chiq va
/// sababsiz, tugma suriladigan qismning ichida, tugma ekran chekkasidan
/// tashqarida. Har safar bitta ekranda tuzatildi, keyingi safar boshqa
/// ekranda qaytdi. Sabab: qoida KODDA emas, boshda edi.
///
/// Beshinchi ko'rinishi — tugma joyida turadi, lekin ro'yxatning oxirgi
/// elementiga YOPISHIB qoladi: 320 px ekranda ruscha matn 1.3 kattalikda
/// bo'lsa, surat ramkasi tugmaning tagidan kesiladi va ikkisi bitta
/// bo'lakdek ko'rinadi. Odam uni alohida amal deb emas, kartaning bir
/// qismi deb o'qiydi.
///
/// Panel shuning uchun:
///   • o'z zamini bor — ro'yxat uning OSTIDAN suriladi;
///   • tepasida chiziq bor — chegara ko'rinib turadi;
///   • `SafeArea` bilan — jest chizig'i tugmani yopmaydi.
///
/// ⚠️ SOYA EMAS, CHIZIQ: qorong'i temada soya chizilmaydi (loyiha
/// qoidasi, `design_system_test.dart` shuni talab qiladi), chiziq esa
/// ikkala temada ham to'g'ri ko'rinadi.
///
/// 🔴 O'Z SIRTI BOR (10.09.2026). Ilgari panel `scaffoldBackgroundColor`
/// bilan bo'yalardi — ya'ni sahifa bilan AYNAN BIR XIL rangda edi va
/// uni faqat ustidagi ip ajratib turardi. Natijada u alohida qatlam
/// emas, sahifaning davomi bo'lib ko'rinardi.
///
/// Apple buni «material» deb ataydi: material «**chuqurlik, qatlamlanish
/// va ierarxiya**» yaratadi va boshqaruv elementlari kontentning USTIDA
/// suzadigan alohida qatlam bo'ladi (`materials.md`, Foundations).
/// Bizda mazmun panel ostidan SURILMAYDI (`Scaffold.bottomNavigationBar`
/// unga joy ajratadi), shuning uchun shaffof «Liquid Glass» emas —
/// HIG aynan shu holat uchun STANDART materialni tavsiya qiladi.
///
/// Ya'ni panel endi: o'z toni (`surfaceContainerHigh`) + yuqori qirrada
/// ingichka chiziq. Ikat ipi esa OLIB TASHLANDI — sababi pastda.
///
/// ⚠️ Tugmani BUTUN ENGDA bering (`CrossAxisAlignment.stretch` yoki
/// `SizedBox(width: double.infinity)`). `Row` + `Spacer` bu loyihada
/// ikki marta toshish bergan.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    /*
     * 🔴 ATLAS IPI OLIB TASHLANDI (10.09.2026).
     *
     * U bu yerda «hal qiluvchi amaldan oldingi ostona» sifatida
     * turgan edi va niyat to'g'ri edi. Lekin ip AYNI PAYTDA
     * `AppBar.bottom` da ham turadi — o'n yettita ekranda
     * (`JiyakLine`). Natijada bitta ekranda ip IKKI MARTA chiqardi
     * va ekranni tasma-tasma qilib kesardi; safar tafsiloti ekranida
     * bu ochiq ko'rinadi.
     *
     * Ostona vazifasini endi MATERIALNING O'ZI bajaradi: panelning
     * boshqa toni va qirrasidagi chiziq. HIG ham guruhlashni faqat
     * ajratgich chiziq bilan emas, «bo'sh joy, shakl, rang va
     * material» bilan qilishni aytadi (`layout.md`).
     *
     * Ip endi ilovaning YAGONA tikuv chizig'i — sarlavha panellari
     * ostida. Bir ekranda bir marta.
     */
    return DecoratedBox(
      decoration: BoxDecoration(
        // ⚠️ `High` EMAS, `Low` — o'lchab tanlandi. Ochroq tonda
        // panel ko'proq «suzardi», lekin ustidagi pushti yozuv
        // («Qayta urinish») AA dan pastga tushardi. `Low` da panel
        // hamon fondan 1.42 : 1 ajraladi va matn ham, aksent ham
        // o'qiladi.
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: child,
        ),
      ),
    );
  }
}

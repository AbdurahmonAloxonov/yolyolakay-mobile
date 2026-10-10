import 'package:flutter/material.dart';
import 'haptics.dart';

/// HARAKAT QULAYLIGI — tizimda "animatsiyani kamaytir" yoqilganda hurmat.
///
/// 🔴 Egasi (2026-08-20): kirish qulayligi (accessibility). Ba'zi odamларда
/// harakat bosh aylantiradi (vestibulyar); iOS/Android'да "Reduce Motion"
/// bor. Bizning dekorativ animatsiyalar (ikat to'quv, neon kometa, bosish
/// masshtabи) shuni HURMAT qilishi kerak — aks holда Play sifat balли ham
/// tushади.
///
/// FAQAT DEKORATIV harakatга taalluqли. Foydаланувчи BOSHQARADIGAN harakat
/// (hold-to-confirm to'lиши, varaq siljиши) o'chирилмайди — u ma'lumot.
abstract final class AppMotion {
  /// Dekorativ animatsiya ruxsat etilганми (tizim "kamaytir" demaган).
  static bool on(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context);

  /*
   * DAVOMIYLIK TOKENLARI (10.09.2026).
   *
   * 🔴 NEGA: ilovada `Duration(milliseconds: …)` O'TTIZ BESH joyda
   * qotirib yozilgan va qiymatlar tarqoq edi — 180, 200, 220, 260,
   * 280, 350, 400. Bular bir-biridan farq qilishi uchun emas,
   * shunchaki har safar boshqa raqam tanlangani uchun har xil edi.
   * Natijada ilova ichida harakat BIR TILDA gapirmasdi.
   *
   * Apple qoidasi (`motion.md`): «qisqalik va aniqlikka intiling» va
   * «tez-tez takrorlanadigan o'zaro ta'sirga animatsiya qo'shmang».
   * Ya'ni davomiylik ROLGA qarab tanlanadi, didga qarab emas.
   *
   * Uchta rol yetarli:
   */

  /// BOSISHGA JAVOB — barmoq ostidagi o'zgarish. Odam buni kutmasligi
  /// kerak, shuning uchun eng qisqasi.
  static const quick = Duration(milliseconds: 150);

  /// EKRAN ICHIDAGI O'ZGARISH — ro'yxat yangilandi, blok ochildi,
  /// holat almashdi. Ko'zga tashlanadi, lekin ushlab turmaydi.
  static const standard = Duration(milliseconds: 250);

  /// KIRISH — varaq yoki ekran birinchi marta paydo bo'lishi. Bu
  /// yerda biroz uzunroq bo'lishi mumkin: harakat «qayerdan kelgani»
  /// ni tushuntiradi.
  static const enter = Duration(milliseconds: 350);

  /// Chiqish egri chizig'i — element JOYIGA keladi (tez boshlanib,
  /// yumshoq to'xtaydi). Kirish va paydo bo'lish uchun.
  static const easeOut = Curves.easeOutCubic;

  /// O'zgarish egri chizig'i — element bir holatdan ikkinchisiga
  /// o'tadi (ikki chekkasi ham yumshoq).
  static const easeInOut = Curves.easeInOut;

  /*
   * ⚠️ UZUN DAVOMIYLIKLAR BU TOKENLARGA KIRMAYDI — ular animatsiya
   * emas: `skeleton` (900) va `loom_loader` (1300) — yuklanish
   * halqasi; `hold_to_confirm` (1400) — odam barmog'ini ushlab
   * turadigan vaqt; `route_map_sheet` (2600) — xarita kamerasi;
   * `geocoder` (1100) — so'rov chegarasi. 10.09.2026 da hammasi
   * ko'rib chiqildi: qisqartiradigani yo'q.
   */
}

/// BOSISH HISSI — bosilганда yengil masshtab + tebranish, butun ilова bir xil.
///
/// 🔴 Egasi (2026-08-20): tugma/karта bosilганда "javob" bo'lсин. Material
/// `InkWell` to'lqinи bor-u, karта/avatar kabi maxsus vidjetларда yo'q. Bu
/// o'ram bosilганда 0.96 ga qisqаради (spring) va yengil "select" tebranishi
/// beради. Reduce-motion'да masshtab o'chади (tebranish qolади — u harakat
/// emas).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.haptic = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool haptic;

  /// Ekran o'quvchisi uchun yorliq.
  ///
  /// Odatda KERAK EMAS: ichidagi matn o'zi o'qiladi (safar kartochkasi,
  /// ro'yxat elementi). Faqat ichida matn BO'LMAGANDA beriladi — masalan
  /// avatar yoki yolg'iz ikonka.
  final String? semanticLabel;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final animate = AppMotion.on(context);
    // `MergeSemantics` SHART: usiz ekran o'quvchisi ikkita alohida
    // tugun o'qiydi — avval "tugma", keyin karta matni. Odam ular bir
    // narsa ekanini tushunmaydi. Birlashtirilgach: "Toshkent —
    // Samarqand, tugma" deb BIR marta o'qiladi.
    return MergeSemantics(
      child: Semantics(
        /*
       * 🔴 BUTUN ILOVA UCHUN BITTA JOYDA (2026-08-25 auditi).
       *
       * `GestureDetector` ekran o'quvchisiga HECH NIMA aytmaydi: TalkBack
       * karta ichidagi matnni o'qiydi-yu, uni BOSISH mumkinligini
       * bildirmaydi. Ya'ni ko'zi ojiz odam safar kartochkasini eshitadi,
       * lekin uni ochish mumkinligini bilmaydi.
       *
       * `PressableScale` ilovadagi deyarli hamma bosiladigan karta va
       * avatarni o'raydi — shuning uchun tuzatish shu yerda: bitta qator
       * o'nlab ekranni yopadi.
       */
        button: true,
        label: widget.semanticLabel,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: () {
            if (widget.haptic) AppHaptics.select();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: (animate && _down) ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../core/cities.dart';
import '../../l10n/strings.dart';

/// SHAHAR MAYDONI — «qayerdan / qayerga» ni tanlash qatori.
///
/// 🔴 NEGA UMUMIY VIDJET (2026-09-02 ko'rigi): bu qator UCH faylda
/// alohida-alohida yozilgan edi — qidiruv, e'lon berish va posilka
/// yuborish. Uchalasida ham AYNAN BIR XIL ikkita nuqson bor edi:
///
///   1. BO'SH MAYDON «TO'LDIRILGAN»DEK KO'RINARDI. Tanlanmagan shahar
///      `titleMedium` (w700) bilan chizilardi — ya'ni ekrandagi eng
///      qalin matn «Shahar yoki tumanni tanlang» degan BO'SH JOY
///      yozuvi edi. Rang so'nik bo'lsa ham, qalinlik uni haqiqiy
///      qiymatdek ko'rsatardi.
///
///   2. IKONKALAR ILOVANING IMZOSIGA ZID EDI (`trip_origin` doirasi va
///      `place` nishoni). Ilovada yo'nalish hamma joyda ikkita NUQTA
///      va bog'lovchi chiziq bilan ko'rsatiladi (`JourneyLine`).
///
/// Men ularni bittalab tuzatib borardim va uchinchisini rasmda ko'rib
/// tushundim: bu tasodif emas, NUSXA. Shuning uchun endi bitta vidjet —
/// to'rtinchi nusxa paydo bo'lmaydi.
class CityField extends StatelessWidget {
  const CityField({
    super.key,
    required this.label,
    required this.city,
    required this.dot,
    required this.onTap,
    this.dense = false,
    this.railDown = false,
    this.railUp = false,
  });

  final String label;
  final Place? city;

  /// Nuqta rangi: jo'nash — `primary`, manzil — `secondary`.
  /// Rang ATAYIN tashqaridan beriladi: qator ikkala vazifada ham
  /// ishlatiladi va o'zi qaysi biri ekanini bilmasligi kerak.
  final Color dot;

  final VoidCallback onTap;

  /// Ixcham holat — panel ichida (qidiruv) `ListTile` chekkalari ortiqcha.
  final bool dense;

  /// YO'L CHIZIG'I — nuqtadan pastga / tepadan nuqtaga ketadigan
  /// bog'lovchi.
  ///
  /// 🔴 NEGA VIDJET ICHIDA (2026-09-03 ko'rigi): chiziq qidiruv
  /// ekranida ALOHIDA vidjet bo'lib, qat'iy balandlik bilan
  /// chizilardi — natijada nuqtalar maydonlarga tegishli bo'lmay
  /// qolgandi. E'lon berish va posilka formalarida esa chiziq
  /// UMUMAN yo'q edi va nuqtalar yorliq bilan qiymat ORASIDA
  /// osilib turardi (`ListTile.leading` butun katak bo'yicha
  /// markazlashadi). Ya'ni bitta vidjet uch ekranda uch xil
  /// ko'rinardi.
  ///
  /// Endi nuqta ham, chiziq ham SHU YERDA: nuqta doim QIYMAT
  /// qatorining markazida, chiziq esa qo'shni maydon tomon uzayadi.
  /// Ikkita maydon yonma-yon turganda ular bitta uzluksiz yo'l
  /// bo'lib qo'shiladi.
  final bool railDown;
  final bool railUp;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final chosen = city != null;

    final value = Text(
      city?.name ?? t.cityOrDistrict,
      /*
       * ⚠️ Shahar TANLANMAGANDA ikki qatorga ruxsat beriladi
       * (o'lchandi 2026-09-04): «Shahar yoki tumanni tanlang» 320 px da
       * 170/196 px, ruschada 1.3 shkalada 165/257 — ya'ni maydon nima
       * qilish kerakligini AYTA OLMASDI.
       *
       * Tanlangan shahar esa BITTA qatorda qoladi: uzun nom («Toshkent,
       * Chilonzor tumani») ikki qatorga cho'zilsa, yonma-yon turgan
       * ikki maydon har xil balandlikda bo'lib, yo'l chizig'i uziladi.
       */
      maxLines: chosen ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        // Bo'sh holatda ODDIY qalinlik — bu qiymat emas, taklif.
        fontWeight: chosen ? FontWeight.w700 : FontWeight.w400,
        color: chosen ? theme.colorScheme.onSurface : theme.colorScheme.outline,
      ),
    );
    final title = Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.outline,
      ),
    );

    /*
     * NUQTA — AYNAN QIYMAT QATORINING MARKAZIDA.
     *
     * Balandliklar ko'rinmas «soya» matnlardan olinadi, ya'ni katta
     * matn rejimida chiziq ham, nuqta ham o'zi moslashadi. Qo'lda
     * yozilgan piksel yo'q — aks holda shkala o'zgarishi bilan
     * hammasi siljib ketadi.
     */
    Widget line([double? height]) => Container(
      width: 2,
      height: height,
      color: theme.colorScheme.outlineVariant,
    );
    Widget ghost(TextStyle? style) =>
        Opacity(opacity: 0, child: Text('Xx', style: style));

    // Nuqta ustuni MAYDONNING BUTUN balandligini egallaydi — ya'ni
    // tepa va past chekkalarni ham. Aks holda chiziq matn blokida
    // tugab, ikkita maydon orasida uzilib qolardi.
    final rail = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        railUp ? line(AppSpace.md) : const SizedBox(height: AppSpace.md),
        // Sarlavha balandligi.
        Stack(
          alignment: Alignment.center,
          children: [
            ghost(theme.textTheme.labelSmall),
            if (railUp) Positioned.fill(child: Center(child: line())),
          ],
        ),
        railUp ? line(AppSpace.xxs) : const SizedBox(height: AppSpace.xxs),
        // Qiymat qatori: markazida nuqta.
        Stack(
          alignment: Alignment.center,
          children: [
            ghost(theme.textTheme.titleMedium),
            Positioned.fill(
              child: Column(
                children: [
                  // ⚠️ `Expanded` bolaga QAT'IY balandlik beradi —
                  // «nol balandlikdagi chiziq» baribir chiziladi va
                  // nuqta ustida keraksiz dumcha qoladi (o'lchandi).
                  Expanded(
                    child: railUp ? Center(child: line()) : const SizedBox(),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: railDown ? Center(child: line()) : const SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ),
        railDown ? line(AppSpace.md) : const SizedBox(height: AppSpace.md),
      ],
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        // Ixcham holatda panelning o'z chekkasi bor.
        padding: EdgeInsets.symmetric(horizontal: dense ? 0 : AppSpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            rail,
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: AppSpace.xxs),
                    value,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

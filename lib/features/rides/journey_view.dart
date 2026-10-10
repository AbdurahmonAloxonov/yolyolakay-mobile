import 'package:flutter/material.dart';

import '../../core/format.dart';

import '../../core/motion.dart';
import '../../l10n/strings.dart';
import '../../app/dimens.dart';
import '../shared/ui.dart';
import '../../app/theme.dart';

/// Safar ko'rinishining UMUMIY tili: marshrut chizig'i va holat belgisi.
///
/// NEGA ALOHIDA FAYL: bir xil safar uchta joyda chiziladi — qidiruv natijasi,
/// "Safarlarim" ro'yxati va safar tafsiloti. Ilgari har biri o'zicha yasalgan
/// edi: qidiruvda chiroyli marshrut chizig'i bor, bron kartasida esa marshrut
/// UMUMAN yo'q (faqat "2 joy" va sana), tafsilotda esa uchta bir-biriga
/// ulanmagan ikonka. Bir ekrandan ikkinchisiga o'tganda odam o'zini boshqa
/// ilovada his qilardi.
///
/// Endi manba bitta: shu yerni o'zgartirsang, uchalasi ham o'zgaradi.

/// Marshrut nuqtasining turi — belgisi va rangi shunga qarab tanlanadi.
enum JourneyNodeKind { origin, via, destination }

/// Marshrut chizig'i: jo'nash → (oraliq shaharlar) → manzil.
///
/// Chiziq UZLUKSIZ: manzil matni ikki qatorga chiqsa ham nuqtalar orasidagi
/// chiziq cho'ziladi (`IntrinsicHeight` + `Expanded`). Ilgari chiziq QAT'IY
/// balandlikda edi va uzun manzilda nuqtadan uzilib qolardi.
class JourneyLine extends StatelessWidget {
  const JourneyLine({
    super.key,
    required this.origin,
    required this.destination,
    this.stops = const [],
    this.originTime,
    this.compact = false,
    this.progress,
  });

  final String origin;
  final String destination;
  final List<String> stops;

  /// Jo'nash vaqti — bo'lsa, jo'nash nuqtasi yonida ko'rsatiladi.
  final String? originTime;

  /// SAFAR QANCHA BOSIB O'TILGANI — `0` dan `1` gacha, yoki `null`.
  ///
  /// 🔴 NEGA QO'SHILDI (2026-08-25): safar boshlangach yo'lovchi KO'R
  /// bo'lib qolardi. ETA raqami bor edi-yu, «qayerda ekanmiz» degan
  /// savolga marshrut chizig'i javob bermasdi — u safar boshlanishidan
  /// oldin ham, o'rtasida ham AYNAN bir xil ko'rinardi.
  ///
  /// Endi bosib o'tilgan qism BREND rangida to'ladi.
  ///
  /// ⚠️ QIYMAT TO'QIB CHIQARILMAYDI. U faqat ikki ROST raqamdan
  /// hisoblanadi: yo'lning to'liq davomiyligi (`/routing/route`) va
  /// qolgan vaqt (`/telematics/eta`). Ikkalasidan biri yo'q bo'lsa
  /// `null` beriladi va chiziq avvalgidek bir xil qoladi — «yarmini
  /// bosib o'tdik» deb taxmin qilmaymiz.
  final double? progress;

  /// Ixcham rejim (ro'yxat kartalari uchun): kichikroq matn va oraliq.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Node(
          kind: JourneyNodeKind.origin,
          text: origin,
          trailing: originTime,
          isFirst: true,
          isLast: false,
          compact: compact,
          // Bosib o'tilgan qism jo'nash nuqtasining PASTKI chizig'ida
          // ko'rsatiladi — safar aynan o'sha yerdan boshlanadi.
          progress: progress,
        ),
        for (final stop in stops)
          _Node(
            kind: JourneyNodeKind.via,
            text: stop,
            isFirst: false,
            isLast: false,
            compact: compact,
          ),
        _Node(
          kind: JourneyNodeKind.destination,
          text: destination,
          isFirst: false,
          isLast: true,
          compact: compact,
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.kind,
    required this.text,
    required this.isFirst,
    required this.isLast,
    required this.compact,
    this.trailing,
    this.progress,
  });

  final JourneyNodeKind kind;
  final String text;
  final bool isFirst;
  final bool isLast;
  final bool compact;
  final String? trailing;

  /// Pastki chiziqning qancha qismi TO'LGAN (`0`..`1`). `null` — to'lmaydi.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    /*
     * 🔴 JO'NASH NUQTASI PUSHTI EMAS (10.09.2026).
     *
     * Ilgari u brend pushtisida edi. Ya'ni pushti bitta ekranda
     * bir vaqtda: asosiy tugma, narx, bo'sh o'rindiq VA jo'nash
     * nuqtasi degani edi — to'rt xil ma'no, bitta rang. HIG buni
     * ochiq taqiqlaydi: «bir xil rangni har xil ma'noda
     * ishlatmang» (`color.md`, Best practices).
     *
     * «Qayerdan → qayerga» ma'nosi yo'qolmaydi: boshlanish
     * NEYTRAL (turgan joyingiz), manzil esa feruza (borayotgan
     * joyingiz) bo'lib qoladi. Pushti endi faqat AMAL va NARXda —
     * ya'ni u haqiqatan ko'zga tashlanadi.
     */
    final dotColor = switch (kind) {
      JourneyNodeKind.origin => scheme.onSurfaceVariant,
      JourneyNodeKind.via => scheme.outlineVariant,
      JourneyNodeKind.destination => scheme.secondary,
    };
    final dotSize = kind == JourneyNodeKind.via ? 7.0 : 11.0;
    final gap = compact ? 10.0 : 20.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                // Yuqoridagi chiziq bo'lagi — birinchi nuqtada yo'q.
                SizedBox(height: 6, child: isFirst ? null : _line(scheme)),
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kind == JourneyNodeKind.via
                        ? scheme.surface
                        : dotColor,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                ),
                // Pastdagi chiziq — qolgan BUTUN balandlikni oladi, shuning
                // uchun manzil ikki qatorga chiqsa ham uzilmaydi.
                Expanded(
                  child: isLast
                      ? const SizedBox()
                      : _line(scheme, progress: progress),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : gap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kind == JourneyNodeKind.via
                          ? theme.textTheme.bodySmall?.copyWith(
                              color: scheme.outline,
                            )
                          : (compact
                                    ? theme.textTheme.bodyMedium
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      trailing!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ulovchi chiziq. [progress] berilsa yuqoridan pastga BREND rangida
  /// to'ladi — «shu yergacha yetib keldik».
  Widget _line(ColorScheme scheme, {double? progress}) {
    final base = Container(width: 2, color: scheme.outlineVariant);
    if (progress == null) return Center(child: base);

    final value = progress.clamp(0.0, 1.0);
    return Center(
      child: SizedBox(
        width: 2,
        child: Stack(
          children: [
            Positioned.fill(child: base),
            // `FractionallySizedBox` balandlikni FOIZ bilan oladi —
            // chiziq uzunligi matnga qarab o'zgargani uchun qat'iy
            // piksel bu yerda ishlamaydi.
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.topCenter,
                heightFactor: value,
                child: ColoredBox(color: scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Holat belgisining rangi va ikonkasi.
///
/// Ilgari holat oddiy kulrang `Chip` edi — "Tasdiqlangan" ham, "Rad etilgan"
/// ham bir xil ko'rinardi va ro'yxatga qaragan odam holatni O'QIB chiqishi
/// kerak edi. Rang bilan u bir qarashda ajraladi.
///
/// Ranglar QAT'IY yozilmaydi, temadan olinadi — tungi rejimda ham to'g'ri
/// chiqishi uchun.
class StatusTone {
  const StatusTone({required this.bg, required this.fg, required this.icon});

  final Color bg;
  final Color fg;
  final IconData icon;

  static StatusTone forBooking(ColorScheme scheme, String status) =>
      switch (status) {
        'confirmed' => StatusTone(
          bg: scheme.secondaryContainer,
          fg: scheme.onSecondaryContainer,
          icon: Icons.check_circle_outline,
        ),
        'pending_negotiation' => StatusTone(
          bg: scheme.tertiaryContainer,
          fg: scheme.onTertiaryContainer,
          icon: Icons.forum_outlined,
        ),
        'rejected' => StatusTone(
          bg: scheme.errorContainer,
          fg: scheme.onErrorContainer,
          icon: Icons.cancel_outlined,
        ),
        'no_show' => StatusTone(
          bg: scheme.errorContainer,
          fg: scheme.onErrorContainer,
          icon: Icons.person_off_outlined,
        ),
        _ => StatusTone(
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurfaceVariant,
          icon: Icons.schedule,
        ),
      };

  static StatusTone forRide(ColorScheme scheme, String status) =>
      switch (status) {
        'in_progress' => StatusTone(
          bg: scheme.primaryContainer,
          fg: scheme.onPrimaryContainer,
          icon: Icons.directions_car_filled,
        ),
        'active' => StatusTone(
          bg: scheme.secondaryContainer,
          fg: scheme.onSecondaryContainer,
          icon: Icons.check_circle_outline,
        ),
        'cancelled' => StatusTone(
          bg: scheme.errorContainer,
          fg: scheme.onErrorContainer,
          icon: Icons.cancel_outlined,
        ),
        // 🔴 "Qoralama" yonida NAYZA emas, ✓ turardi (qurilmada ko'rildi
        // 2026-08-13): belgisi "tayyor" deb o'qilardi, holbuki bu safar
        // hali qidiruvda ham yo'q. Faollashmagan safar — ko'z yumilgan.
        'draft' => StatusTone(
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurfaceVariant,
          icon: Icons.visibility_off_outlined,
        ),
        _ => StatusTone(
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurfaceVariant,
          icon: Icons.check,
        ),
      };
}

/// Holat belgisi — Material `Chip` o'rniga ixcham "tabletka".
///
/// `Chip` bu yerda ikki sababga ko'ra yaramaydi: u kartada haddan tashqari
/// baland (ro'yxatni siyraklashtiradi) va rangini temadan olmaydi.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.tone, required this.label});

  final StatusTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tone.icon, size: 14, color: tone.fg),
          const SizedBox(width: AppSpace.xs),
          // `Flexible` + ellipsis: belgi tor joyga tushib qolsa qator
          // ekrandan chiqib ketmasin (ruscha matnlar uzunroq).
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: tone.fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Haydovchi qatori — avatar + ism + reyting. Uchala ekranda bir xil.
///
/// Ism kelmasa "Haydovchi" deb turadi, lekin blok JOYIDA qoladi: bo'sh joy
/// "ma'lumot yo'q" degandan ko'ra "ilova buzuq" degandek ko'rinadi.
class DriverRow extends StatelessWidget {
  const DriverRow({
    super.key,
    required this.name,
    this.rating,
    this.avatarRadius = 18,
    this.trailing,
    this.inlineRating = false,
    this.gender,
    this.avatarUrl,
    this.seed,
    this.onTap,
  });

  final String? name;
  final double? rating;

  /// Haydovchi surati.
  ///
  /// 🔴 Egasi (2026-08-16): "rasm qo'yilyapti, lekin hech qayerda
  /// ko'rinmayapti". Sabab shu yerda edi — bu qator DOIM jinsga qarab
  /// ikonka chizardi, suratni umuman so'ramasdi ham. Endi surat bo'lsa
  /// surat, bo'lmasa (yoki ochilmasa) o'sha ikonka qaytadi.
  final String? avatarUrl;

  /// SHAXSIY MUHR uchun urug' — odamning id'si.
  ///
  /// 🔴 NEGA QO'SHILDI (2026-09-03): bu qator `PersonAvatar` ga urug'
  /// BERMASDI, ya'ni surati yo'q haydovchi HAMMA safar kartochkasida
  /// och pushti doiradagi bir xil kulrang odamcha bo'lib ko'rinardi.
  /// Ayni paytda suhbatlar ro'yxatida o'sha odam o'zining xonatlas
  /// muhri bilan turardi — bitta ilovada bitta odam ikki xil.
  ///
  /// Surat bo'lsa surat, bo'lmasa MUHR, urug' ham bo'lmasa — ikonka.
  final String? seed;

  /// `male` | `female` — avatar ikonkasi shunga qarab tanlanadi.
  ///
  /// 🔴 Egasi (2026-08-14): jins bo'yicha cheklov olib tashlandi, lekin
  /// yo'lovchi KIM bilan ketayotganini bilishi kerak. Shuning uchun jins
  /// MA'LUMOT sifatida qoladi — ortiqcha yozuvsiz, avatar ikonkasida.
  final String? gender;

  /// Haydovchi qatoriga BOSISH — profilini ochadi.
  ///
  /// 🔴 NEGA KERAK: haydovchi o'lik nuqta edi — ism va yulduzcha ko'rinardi,
  /// lekin "bu kim?" degan savolga javob beradigan joy yo'q edi. `null`
  /// bo'lsa qator avvalgidek bosilmaydigan qoladi (yo'lovchilar ro'yxatida
  /// profil ma'lumoti yo'q).
  final VoidCallback? onTap;

  final double avatarRadius;
  final Widget? trailing;

  /// Reyting ismning ostida emas, YONIDA. Ro'yxat kartalarida shu ishlatiladi:
  /// ikki qatorli blok kartani ~16 piksel cho'zadi, o'nta safarda bu butun
  /// bir ekran demakdir.
  final bool inlineRating;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    // 🔴 Backend ismlarni BOSH HARFDA yuboradi ("MUXAMMAD RAXMATILLAYEV").
    // Chatda biz uni allaqachon odam o'qiydigan holga keltirardik, safar
    // kartochkasi va tafsilotlarida esa u baqirib turardi — ustiga, bosh
    // harflar kengroq bo'lgani uchun ism ertaroq kesilardi
    // ("MUXAMMAD RAXMAT…"). Endi hamma joyda bir xil.
    final shown = prettyName(name)?.trim() ?? '';

    final row = Row(
      children: [
        PersonAvatar(
          url: avatarUrl,
          radius: avatarRadius,
          gender: gender,
          seed: seed,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: inlineRating
              ? Row(
                  children: [
                    Flexible(
                      child: Text(
                        shown.isEmpty ? t.driver : shown,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if ((rating ?? 0) > 0) ...[
                      const SizedBox(width: AppSpace.sm),
                      const Icon(Icons.star, size: 13, color: BrandColors.star),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        rating!.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shown.isEmpty ? t.driver : shown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    // `> 0` — baholanmagan haydovchida "0.0" chiqib qolmasin.
                    if ((rating ?? 0) > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 13,
                            color: BrandColors.star,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpace.sm),
          trailing!,
        ],
      ],
    );

    final tap = onTap;
    if (tap == null) return row;
    // `trailing` (masalan holat nishoni) BOSILMAYDI qolishi kerak — u
    // amal emas, ma'lumot. Shuning uchun butun qator emas, faqat chap
    // qismi bosiladi... lekin amalda odam ISMGA bosadi va `trailing`
    // ham qatorning bir qismi. Soddaligi uchun butun qator bosiladi:
    // holat nishoni bosilganda ham profil ochilishi zarar qilmaydi.
    return PressableScale(onTap: tap, child: row);
  }
}

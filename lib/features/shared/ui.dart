/// Ekran qurish uchun umumiy g'ishtlar.
///
/// NEGA KERAK BO'LDI (2026-08-13 o'lchov): bo'lim sarlavhasi ekranlarda uch
/// xil yozilardi (`titleSmall` 20 joyda, `labelLarge` 11 joyda va bitta
/// yopiq `_SectionLabel`), ma'lumot qutisi esa har joyda o'z `BoxDecoration`i
/// bilan — bitta ekranda 6, 14 va 16 radius yonma-yon turardi.
///
/// Bu yerdagilar yagona manba: ko'rinish o'zgarishi kerak bo'lsa BITTA joyda
/// o'zgaradi.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/dimens.dart';
import '../../core/media_url.dart';
import 'image_viewer.dart';
import 'brand/ornament.dart';
import 'brand/suzani_avatar.dart';
import '../../core/motion.dart';

/// Kartalar ustidagi kichik bo'lim sarlavhasi.
///
/// Kartaning O'Z sarlavhasi emas — u karta ichida `titleSmall` bilan
/// yoziladi. Bu esa bir necha kartani birlashtirib turadigan yorliq
/// («MARSHRUT», «VAQT VA NARX»).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;

  /// O'ng chekkadagi ikkinchi darajali amal («Hammasi», «Tahrirlash»).
  /// Berilsa, chiziq undan OLDIN tugaydi.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          // ⚠️ `Flexible`: uzun sarlavha (ruscha «УСЛОВИЯ ПОЕЗДКИ») tor
          // ekranda qatorni toshirib yuborardi.
          Flexible(
            /*
             * 🔴 EKRAN O'QIGICH UCHUN — BU BO'LIM SARLAVHASI
             * (2026-09-04, o'lchandi).
             *
             * Ilovada `header` belgisi NOLTA joyda edi: TalkBack butun
             * ekranni ketma-ket o'qib chiqishdan boshqa yo'l
             * qoldirmasdi. Uzun ekranlarda (profil, sozlamalar,
             * tariflar) bu «kerakli bo'limga o'tish» degan narsani
             * umuman yo'q qiladi.
             *
             * Belgi shu YAGONA komponentda — u sayt bo'ylab o'nlab
             * joyda ishlatiladi, ya'ni bitta o'zgarish hammasini
             * qamrab oladi.
             */
            child: Semantics(
              header: true,
              child: Text(
                text.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          /*
           * ISLIMI — bo'lim yorlig'ining chizig'i o'rniga NOVDA.
           *
           * 🔴 Nega aynan shu joyda (2026-09-03, milliylashtirish):
           * bu ilovaning eng KO'P TAKRORLANADIGAN tuzilmaviy elementi —
           * formalar, sozlamalar, haydovchi ekranlari, hammasi shu
           * yorliq bilan bo'linadi. Ya'ni bitta joyni o'zgartirish
           * o'nlab ekranga tegadi, hech qayerda naqsh «sepilmaydi».
           *
           * 🔑 Islimi — o'zi CHIZIQ naqshi: uni bu balandlikda
           * ishlatish kichraytirish emas, o'z o'lchamida ishlatish
           * (girihni bunday joyga qo'yib bo'lmaydi — u maydon naqshi).
           * Girih GEOMETRIYA, islimi TIRIKLIK; an'anada ikkalasi
           * yonma-yon turadi.
           */
          Expanded(
            child: IslimiBand(
              height: 14,
              color: theme.colorScheme.outlineVariant,
              opacity: 1,
              repeatWidth: 104,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Ma'lumot qutisi — kartadan farqli, RANG bilan ajratilgan blok.
///
/// Ishlatiladi: "bron tasdiqlandi", "moderatsiyada", narx taklifi, ogohlantirish.
/// Karta emas: karta — ro'yxatning bir elementi, bu esa holat haqidagi xabar.
///
/// [tone] rangni tanlaydi. Qo'lda rang berish ATAYIN mumkin emas — aks holda
/// yana har ekranda o'z rangi paydo bo'ladi.
enum InfoTone {
  /// Neytral eslatma.
  neutral,

  /// Ijobiy: tasdiqlandi, muvaffaqiyat.
  positive,

  /// Diqqat talab qiladi: moderatsiya, kutilmoqda.
  warning,

  /// Xato yoki bekor qilingan holat.
  danger,
}

class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.child,
    this.tone = InfoTone.neutral,
    this.padding = const EdgeInsets.all(AppSpace.lg),
  });

  final Widget child;
  final InfoTone tone;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Qorong'ida ranglar TO'Q va past to'yingan bo'lishi kerak: yorug'
    // rejimdagi och feruza qora fonda ko'zni qamashtiradi.
    final background = switch (tone) {
      InfoTone.neutral =>
        isDark ? const Color(0xFF221E21) : const Color(0xFFF2F0F1),
      InfoTone.positive =>
        isDark ? const Color(0xFF1F2624) : const Color(0xFFF2F9F8),
      InfoTone.warning =>
        isDark ? const Color(0xFF2A2418) : const Color(0xFFFDF6E7),
      InfoTone.danger =>
        isDark ? const Color(0xFF2B1D20) : const Color(0xFFFCEEF0),
    };

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onSurface),
        child: child,
      ),
    );
  }
}

/// Kichik yorliq — davlat raqami, holat belgisi kabi qisqa matn uchun.
///
/// Karta yoki quti EMAS: shuning uchun radiusi ham boshqa (`AppRadius.pill`).
class AppBadge extends StatelessWidget {
  const AppBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}

/// Suratli avatar — surat yo'q/ochilmasa jins ikonkasiga qaytadi.
///
/// Zaxira YO'Q holat bo'lmasligi kerak: bo'sh doira "ilova buzuq" degandek
/// ko'rinadi. Shu qoida profil ekranida ham (`_Avatar`) qo'llangan.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.url,
    required this.radius,
    this.gender,
    this.tapToView = false,
    this.seed,
  });

  final String? url;
  final double radius;
  final String? gender;

  /// Rasm YO'Q bo'lса — SHU seed'dan (id/ism) noyob suzani muhri chiziladi
  /// (izoh `SuzaniAvatar` da). Bo'sh bo'lса — oddiy ikonka.
  final String? seed;

  /// Bosilганда rasmни to'liq ekранда ochish (chat sarlavhasi, profil).
  final bool tapToView;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget fallback() {
      final s = seed?.trim() ?? '';
      if (s.isNotEmpty) return SuzaniAvatar(seed: s, size: radius * 2);
      return Icon(
        switch ((gender ?? '').toLowerCase()) {
          'male' => Icons.man,
          'female' => Icons.woman,
          _ => Icons.person,
        },
        size: radius + 2,
        color: scheme.onPrimaryContainer,
      );
    }

    final resolved = mediaUrl(url);
    if (resolved == null) {
      final s = seed?.trim() ?? '';
      // Suzani muhri o'zи doira — CircleAvatar foni kerak emas (aks holда
      // muhr fonи ustidan ikkinchi doira chiqardi).
      //
      // 🔴 `_wrapVerified` bu ikki tarmoqда ham SHART: ilgari halqa faqat
      // RASM bor bo'lganда chizilardi. Rasm esa ko'pincha yo'q (backend
      // media 404, xat 2026-08-20) — ya'ni tasdiqlanган haydovchi aynan eng
      // ko'p uchraydigan holатда belgisiz qolardi. Ishonch belgisi suratга
      // emas, ODAMga tegishli.
      if (s.isNotEmpty) {
        return ClipOval(
          child: SuzaniAvatar(seed: s, size: radius * 2),
        );
      }
      return CircleAvatar(
        radius: radius,
        // 🔴 PUSHTI EMAS, NEYTRAL (10.09.2026). Avatar zamini och
        // pushti edi va u hech nima anglatmasdi — shunchaki bezak.
        // Ayni paytda ro'yxatdagi har bir kartada bittadan pushti
        // doira paydo bo'lardi va narx bilan tugma o'sha pushtilar
        // ichida yo'qolardi. HIG: rangni faqat haqiqatan urg'u kerak
        // bo'lgan elementga bering (`color.md`).
        backgroundColor: scheme.surfaceContainerHighest,
        child: fallback(),
      );
    }

    final avatar = CircleAvatar(
      radius: radius,
      // Neytral — izohi yuqorida.
      backgroundColor: scheme.surfaceContainerHighest,
      child: ClipOval(
        child: Image.network(
          resolved,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Yuklanayotganda ham bo'sh qolmasin.
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : fallback(),
          errorBuilder: (_, _, _) => fallback(),
        ),
      ),
    );

    // Bosilса rasmни to'liq ekранда ochamiz (faqat rasm bor va tapToView).
    if (!tapToView) return avatar;
    return PressableScale(
      onTap: () => showImageViewer(context, url),
      child: avatar,
    );
  }
}

/// Kelishilgandan keyingi ALOQA qatori: raqam + "Qo'ng'iroq" tugmasi.
///
/// 🔴 NEGA KERAK (egasi, 2026-08-16): "kelishuvga erishganlar bir-birining
/// nomerini topolmayapti". Bron tasdiqlangach ikki taraf uchrashish joyini
/// aniqlashi kerak; chat bunga har doim ham yetmaydi (internet yo'q, odam
/// ilovani ochmagan). Telefon — eng ishonchli yo'l.
///
/// ⚠️ Raqam kelmasa blok BO'SH QOLMAYDI, sababini aytadi: backend safar/bron
/// javobida telefon maydonini hozircha YUBORMAYDI (xat 2026-08-16). Shu
/// sababli "raqam yo'q" holati vaqtincha ODATIY hisoblanadi.
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.phone,
    required this.label,
    required this.callLabel,
    required this.emptyHint,
  });

  final String? phone;
  final String label;
  final String callLabel;

  /// Raqam bo'lmaganda ko'rsatiladigan izoh.
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = phone?.trim();
    final hasPhone = number != null && number.isNotEmpty;

    return InfoBox(
      tone: InfoTone.neutral,
      child: Row(
        children: [
          Icon(
            Icons.phone_outlined,
            size: 20,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                // Raqam BELGILAB NUSXALANADI (egasi 2026-08-20) — odam uni
                // boshqa ilovaga (kontakt, xarita) ko'chirishi mumkin.
                // Bo'sh holatда oddiy Text (nusxalanadigan narsa yo'q).
                hasPhone
                    ? SelectableText(number, style: theme.textTheme.titleSmall)
                    : Text(
                        emptyHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
              ],
            ),
          ),
          if (hasPhone)
            FilledButton.tonalIcon(
              onPressed: () => launchUrl(Uri.parse('tel:$number')),
              icon: const Icon(Icons.call, size: 18),
              label: Text(callLabel),
            ),
        ],
      ),
    );
  }
}

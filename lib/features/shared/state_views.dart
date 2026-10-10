import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

import 'brand/brand_panels.dart';
import 'brand/ornament.dart';
import 'brand/suzani_icons.dart';

import '../support/support_entry.dart';

import '../../core/api/api_exception.dart';
import '../../l10n/strings.dart';
import '../../../app/dimens.dart';

/// Xato holati — [ApiException] bo'lsa aniq sabab, aks holda umumiy matn.
///
/// 502/503/504 alohida matn oladi: bu vaqtinchalik uzilish, foydalanuvchi
/// "men noto'g'ri qildim" deb o'ylamasligi kerak.
class ErrorView extends ConsumerWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final api = error is ApiException
        ? error as ApiException
        : ApiException.from(error);
    final message = api.localized(t.lang);
    // 🔴 "Sessiya tugadi, qayta kiring" deyilardi-yu, KIRISH YO'LI yo'q edi:
    // ekranda faqat "Qayta urinish" turardi va u har safar o'sha xatoni
    // qaytarardi (qurilmada ko'rildi 2026-08-14). Sessiya tugagan bo'lsa
    // odamga aynan kirish tugmasi kerak.
    final expired = api.kind == ApiErrorKind.unauthorized;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikonka xato TURIGA qarab. Ilgari hammasiga "bulut o'chiq"
            // chizilardi — 400 yoki sessiya tugashida ham. Odam o'z
            // internetini ayblab qolardi (egasi qurilmada aytdi).
            /*
             * 🔴 XATO HOLATI BO'SH HOLAT BILAN BIR TILDA (2026-09-02).
             *
             * Bo'sh holat puxta ishlangan edi — yumshoq doira ichida
             * brend ikonkasi, sarlavha, tushuntirish va chiqish yo'li.
             * Xato esa yalang'och kulrang undov belgisi va bitta jumla
             * bo'lib qolgandi: ikkalasi yonma-yon turganda ilova
             * yarim tugallangandek ko'rinardi.
             *
             * Endi ikkalasi ham bir xil shaklda. Ikonka xato TURIGA
             * qarab tanlanadi (izohi pastda) va doira ham o'sha ma'noni
             * kuchaytiradi.
             */
            // 🔴 Xato ekrani BO'SH ekran bilan bir shaklda bo'lishi
            // KERAK edi, lekin amalda ikkalasi ikki xil chizilgandi:
            // bo'sh holat ravoqqa o'tganda xato yalang'och kulrang
            // doira bo'lib qolgandi. Endi ikkalasi ham PESHTOQ.
            //
            // Ikonka xato TURIGA qarab. Ilgari hammasiga «bulut
            // o'chiq» chizilardi — 400 yoki sessiya tugashida ham.
            // Odam o'z internetini ayblab qolardi (egasi qurilmada
            // aytdi).
            PeshtoqMedallion(
              width: 96,
              child: Icon(switch (api.kind) {
                ApiErrorKind.network ||
                ApiErrorKind.serverUnavailable => Icons.cloud_off_outlined,
                ApiErrorKind.unauthorized => Icons.lock_outline,
                _ => Icons.error_outline,
              }, size: 38),
            ),
            const SizedBox(height: AppSpace.lg),
            // Xabar — SARLAVHA og'irligida. Ilgari oddiy matn edi va
            // ekranning yagona mazmuni bo'la turib izohdek ko'rinardi.
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (expired) ...[
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).sessionExpired(),
                child: Text(t.loginTitle),
              ),
            ] else if (onRetry != null) ...[
              const SizedBox(height: AppSpace.xl),
              OutlinedButton(onPressed: onRetry, child: Text(t.retry)),
            ],
            /*
             * YORDAM — XATO EKRANIDAN (egasi, 22.09.2026: «xatolik bo'lsa
             * ham supportga yozish uchun»).
             *
             * «Qayta urinish» hamma xatoni yechmaydi: server 500 qaytarsa
             * yoki ma'lumot buzuq bo'lsa tugma har safar o'sha xatoni
             * qaytaradi va odamning qo'lida boshqa hech narsa qolmaydi.
             * Endi shu yerdan bizga yozish mumkin — kirgan bo'lsa forma
             * bilan, kirmagan bo'lsa Telegram orqali (izohi
             * `support_entry.dart` da).
             */
            const SizedBox(height: AppSpace.sm),
            const SupportLink(),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.suzani,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// SUZANI ikonkasi — stok Material o'rniga (izohi `suzani_icons.dart`
  /// da). Berilsa [icon] e'tiborsiz qoladi.
  ///
  /// Bo'sh ekran — brendning eng ko'p ko'riladigan joyi: bazada safar kam
  /// bo'lgani uchun odam uni tez-tez ko'radi. Shu sabab aynan shu yerda
  /// stok ikonka turishi achinarli edi.
  final SuzaniIcon? suzani;

  /// Bo'sh ekrandan CHIQISH yo'li.
  ///
  /// 🔴 Nima uchun qo'shildi (egasi qurilmada, 2026-08-13): "Hali bron yo'q"
  /// deyilardi-yu, qidiruvga o'tish yo'li berilmasdi — ekran boshi berk
  /// bo'lib qolardi. Bo'sh holat "hech narsa yo'q" degani emas, "birinchi
  /// qadamni qil" degani bo'lishi kerak.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Ikkinchi, KUCHSIZROQ chiqish yo'li (matnli tugma).
  ///
  /// Bo'sh natijada ko'pincha ikkita ma'noli amal bo'ladi: "qidiruvni
  /// kengaytirish" (asosiy — natijani SHU YERDA beradi) va "qidiruvni
  /// o'zgartirish" (orqaga). Ikkalasini bir xil og'irlikda ko'rsatish
  /// tanlovni qiyinlashtiradi, shuning uchun ikkinchisi matnli tugma.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*
             * PESHTOQ MEDALYONI — bo'sh ekranning belgisi.
             *
             * 🔴 Ilgari bu yerda `SuzaniAvatar` turardi: sarlavha
             * matnidan hosil qilinadigan GENERATIV gul, ustida oq
             * doiradagi ikonka. Ya'ni har bo'sh ekranda boshqacha
             * tasodifiy shakl chiqardi — brend belgisi tanib
             * olinmaydigan bo'lsa, u brend belgisi emas.
             *
             * Endi hamma bo'sh ekranda BIR XIL ravoq turadi va odam
             * uni tanishtiruv ekranlaridan allaqachon biladi.
             */
            // ⚠️ ENI 96 DAN OSHMASIN: ravoq eniga nisbatan 1.24 baravar
            // baland, ya'ni har qo'shilgan piksel ekranda ikki barobar
            // joy oladi. 108 da bo'sh holat tor ekranda pastdan
            // toshardi (o'lchandi: 2.9 px).
            PeshtoqMedallion(
              width: 96,
              child: suzani != null
                  ? SuzaniIconWidget(suzani!, size: 38)
                  : Icon(icon ?? Icons.inbox_outlined, size: 38),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            // Bo'sh ekran butunlay "o'lik" ko'rinmasin — brend motivi bilan
            // yumshatamiz. Statik, bitta rangda (web spec qoidasi).
            //
            // 🔴 Ilgari bezak SARLAVHA bilan izoh ORASIDA turardi va
            // ajratgichdan keyin hech narsa yo'qdek ko'rinardi (egasi
            // qurilmada aytdi). Endi u eng oxirida — matnni bo'lib
            // yubormaydi, tugma bo'lsa undan ham keyin turadi.
            /*
             * 🔴 AJRATGICH HECH NIMANI AJRATMASIN (2026-09-02 ko'rigi).
             *
             * Suzani ajratgichi HAR DOIM chizilardi — hatto ostida
             * tugma bo'lmaganda ham. «Profil topilmadi» ekranida u
             * shunday ko'rinardi: matn, keyin bezakli chiziq, keyin
             * bo'sh joy. Ajratgich pastda nimadir borligini VA'DA
             * qiladi va odam nimanidir kutib qoladi.
             *
             * Endi u faqat ostida amal bo'lganda chiziladi.
             */
            if (onAction != null && actionLabel != null ||
                onSecondary != null && secondaryLabel != null) ...[
              const SizedBox(height: AppSpace.xl),
              const SizedBox(width: 220, child: OrnamentMark()),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpace.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
            if (onSecondary != null && secondaryLabel != null) ...[
              const SizedBox(height: AppSpace.xs),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Xato/xabarni bir xil ko'rinishda ko'rsatish.
void showMessage(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        // «Qaytarish» — FAQAT haqiqatan qaytariladigan amalda beriladi
        // (masalan bloklash: `unblockUser` bor). Qaytarib bo'lmaydigan
        // amalda tasdiq oynasi ishlatiladi, chunki u yerda "qaytaraman"
        // deb yolg'on aytib bo'lmaydi.
        duration: onAction == null
            ? const Duration(seconds: 4)
            : const Duration(seconds: 8),
        action: onAction == null || actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
}

void showApiError(BuildContext context, Object error, Lang lang) {
  showMessage(context, ApiException.from(error).localized(lang));
}

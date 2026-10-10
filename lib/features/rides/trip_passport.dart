import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/share_safely.dart';

import '../../app/dimens.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../shared/brand/atlas.dart';
import '../shared/brand/ornament.dart';
import '../shared/brand/suzani_avatar.dart';

/// SAFAR PASPORTI — tugagan safardan qoladigan ulashiladigan karta.
///
/// 🔴 NEGA (2026-08-25): safar tugaydi va IZSIZ yo'qoladi. Odam uni
/// eslab qoladigan, do'stiga ko'rsatadigan hech narsa qolmaydi. Ayni
/// paytda safar — hikoya: kim bilan, qayerdan qayerga, qancha yo'l.
///
/// Karta Stories o'lchamiga yaqin (9:16 ga moyil) — Telegram va
/// Instagram'ga qirqilmasdan tushadi. Ilova o'zini shu orqali tarqatadi:
/// pastda sayt manzili turadi.
///
/// 🔴 HALOL MA'LUMOT (loyiha qoidasi: «o'lchama, ishonma»):
///   • masofa va yo'l vaqti — `GET /routing/route` dan, ROST;
///   • ular kelmasa qator UMUMAN chizilmaydi;
///   • CO₂ yoki «tejalgan pul» YOZILMAYDI — bizda bunday ma'lumot yo'q va
///     uni chiroyli ko'rinsin deb to'qib chiqarish mumkin emas.
///
/// Ya'ni karta kam narsa aytadi, lekin aytgani ROST.
class TripPassport extends StatelessWidget {
  const TripPassport({
    super.key,
    required this.ride,
    this.distanceKm,
    this.duration,
  });

  final Ride ride;

  /// `/routing/route` dan. `null` bo'lsa qator chizilmaydi.
  final double? distanceKm;
  final Duration? duration;

  static final _boundaryKey = GlobalKey();

  /// Kartani rasmga olib ulashadi.
  static Future<void> share(BuildContext context) async {
    final t = AppStrings.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return shareFallback(messenger, t, null);
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return shareFallback(messenger, t, null);
      AppHaptics.select();
      // `fromData` — vaqtinchalik faylsiz (path_provider kerak emas).
      final xfile = XFile.fromData(
        bytes.buffer.asUint8List(),
        mimeType: 'image/png',
        name: 'safar_pasporti.png',
      );
      if (!context.mounted) return;
      await shareSafely(
        context,
        ShareParams(files: [xfile], text: t.tripPassportTagline),
      );
    } catch (_) {
      // Rasm tayyorlanmadi — jim qolmaymiz (izohi `shareSafely` da).
      await shareFallback(messenger, t, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return RepaintBoundary(
      key: _boundaryKey,
      /*
       * 🔴 KARTA TIZIM SHRIFTIGA ERGASHMAYDI (2026-08-25, sinovda topildi).
       *
       * Bu karta RASMGA aylanadi va uni BOSHQA odamlar ko'radi. Yuboruvchi
       * telefonida «kattaroq matn» yoqilgan bo'lsa, matn kartadan toshib
       * ketardi va ulashilgan rasmda buzuq ko'rinardi — qabul qiluvchining
       * sozlamasiga esa bu umuman aloqador emas.
       *
       * Ya'ni bu istisno ATAYIN: qolgan hamma joyda tizim shrifti hurmat
       * qilinadi, ulashiladigan rasmda esa u ma'noga ega emas.
       */
      child: MediaQuery.withNoTextScaling(
        /*
         * 🔴 EKRANDA KICHIKROQ (egasi, 2026-08-28: «safar pasporti juda
         * katta bo'lib ketgan»).
         *
         * Karta to'liq kenglikda va 4:5 nisbatda chizilardi — 390 px li
         * telefonda bu 487 px balandlik, ya'ni deyarli butun ekran.
         * Safar tugagach odam avval qiladigan ish (baholash, tarixga
         * qaytish) uning ostida qolib ketardi.
         *
         * ⚠️ NISBAT O'ZGARMADI: 4:5 — Stories ham, lenta ham
         * qirqmaydigan nisbat va ulashiladigan rasm aynan shunday
         * bo'lishi kerak. Faqat EKRANDAGI kengligi cheklandi.
         */
        child: FractionallySizedBox(
          widthFactor: 0.72,
          child: AspectRatio(
            // 4:5 — Stories ham, lenta ham qirqmaydigan eng xavfsiz nisbat.
            // To'liq 9:16 da matn juda kichkina bo'lib qolardi.
            aspectRatio: 4 / 5,
            /*
             * 🔑 KARTA YAXLIT MASSHTABLANADI. Bu hiyla emas, mazmuniy
             * tanlov: pasport — ULASHILADIGAN PLAKAT, uning ichki
             * nisbatlari (shrift, bo'shliq, ikonka) bir-biriga
             * bog'langan va ekran kengligiga qarab ALOHIDA
             * o'zgarmasligi kerak.
             *
             * ⚠️ Busiz kartani toraytirish TOSHISHGA olib keldi
             * (`big_text_test`: 1.6 da 5,1 px). Endi mazmun DOIM
             * 400x500 da joylashadi va faqat butun karta kichrayadi —
             * toshish sinfi butunlay yo'qoladi.
             *
             * 🔑 Ulashish sifati tushmaydi: rasm `pixelRatio: 3` bilan
             * olinadi, ya'ni 400x500 dan 1200x1500 px chiqadi.
             */
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 400,
                height: 500,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: BrandColors.wineAsh),
                  child: Stack(
                    children: [
                      // Girih — profil sarlavhasi bilan bir xil naqsh.
                      Positioned.fill(
                        child: GirihPattern(
                          cell: 124,
                          color: BrandColors.turquoise.withValues(alpha: 0.085),
                          cut: BrandColors.wineAsh,
                        ),
                      ),
                      // ETAK — atlas jiyagi. Ulashiladigan rasm ilovadan
                      // TASHQARIDA ko'riladi: unda ilovaning tikuv chizig'i
                      // bo'lishi kerak, aks holda u begona rasm bo'lib qoladi.
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        // ⚠️ `themed: false` — ranglar TEMADAN OLINMAYDI: bu rasm
                        // boshqa odamning telefonida ochiladi va u yerda bizning
                        // temamiz yo'q. Doim klassik xonatlas.
                        child: AtlasEdge(height: 12, themed: false),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpace.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.tripPassportTitle.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: BrandColors.turquoise.withValues(
                                  alpha: 0.16,
                                ),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            // Yo'nalish MARKAZDA turadi: u kartaning bosh mavzusi.
                            // Ilgari u tepaga yopishib, o'rtada katta bo'sh joy
                            // qolardi va karta "tugallanmagan" ko'rinardi.
                            const Spacer(),
                            // Brend sarlavha shriftida va eng katta.
                            Text(
                              ride.originAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: displayFontStyle(
                                theme.textTheme.headlineSmall,
                              ).copyWith(color: Colors.white),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpace.xs,
                              ),
                              child: Icon(
                                Icons.south,
                                size: 20,
                                color: BrandColors.turquoise.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            Text(
                              ride.destinationAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: displayFontStyle(
                                theme.textTheme.headlineSmall,
                              ).copyWith(color: Colors.white),
                            ),
                            const Spacer(),
                            // ROST raqamlar — kelmasa umuman chizilmaydi.
                            if (distanceKm != null || duration != null)
                              // 🔴 `Flexible` SHART: uzun yo'nalishda «14 soat 35
                              // daqiqa» + «1281 km» tor kartaga sig'masdi
                              // (sinovda topildi). Karta RASMGA aylanadi —
                              // toshgan joydagi sariq-qora chiziqlar ULASHILGAN
                              // rasmda ko'rinardi.
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (distanceKm != null)
                                    Flexible(
                                      child: _Fact(
                                        value: formatDistance(distanceKm!),
                                        label: t.tripPassportDistance,
                                      ),
                                    ),
                                  if (distanceKm != null && duration != null)
                                    const SizedBox(width: AppSpace.lg),
                                  if (duration != null)
                                    Flexible(
                                      child: _Fact(
                                        value: formatDuration(
                                          duration!,
                                          t.lang,
                                        ),
                                        label: t.tripPassportTime,
                                      ),
                                    ),
                                ],
                              ),
                            const SizedBox(height: AppSpace.lg),
                            Row(
                              children: [
                                // Hamrohning shaxsiy suzani muhri — har odamda
                                // noyob (izohi `SuzaniAvatar` da).
                                if ((ride.driver?.id ?? '').isNotEmpty)
                                  ClipOval(
                                    child: SuzaniAvatar(
                                      seed: ride.driver!.id!,
                                      size: 40,
                                    ),
                                  ),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if ((prettyName(ride.driver?.name) ?? '')
                                          .isNotEmpty)
                                        Text(
                                          prettyName(ride.driver?.name)!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(color: Colors.white),
                                        ),
                                      Text(
                                        formatDate(ride.departureTime, t.lang),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.lg),
                            // 🔴 `Flexible` SHART: brend nomi va manzil tor kartada
                            // qatorni toshirib yuborardi (sinovda topildi). Karta
                            // rasmga olinadi — toshgan joyda sariq-qora chiziqlar
                            // ULASHILGAN RASMDA ko'rinib qolardi.
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    t.appName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: displayFontStyle(
                                      theme.textTheme.titleMedium,
                                    ).copyWith(color: BrandColors.pink),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Flexible(
                                  child: Text(
                                    'yolyolakay.co.uz',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bitta raqam va uning nomi.
class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: theme.textTheme.titleLarge?.copyWith(
              color: BrandColors.turquoise,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

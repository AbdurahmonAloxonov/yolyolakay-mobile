import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/share_safely.dart';

import '../../app/dimens.dart';
import '../../app/theme.dart';
import '../../core/env.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';
import '../shared/brand/atlas.dart';
import '../shared/brand/ornament.dart';
import 'ride_share.dart';

/// E'LON PLAKATI — Telegram guruhiga tashlanadigan brend kartasi.
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): O'zbekistonda safar
/// e'loni Telegram guruhlarida tarqaladi va u yerda kuniga yuzlab bir xil
/// ko'rinishdagi MATN oqib o'tadi. Bizning ulashishimiz ham o'sha oqimning
/// bir qatori edi — hech kim to'xtab qaramasdi.
///
/// Rasm esa lentada TO'XTATADI va uni ko'rgan odam havolani bosadi. Bu
/// bizning eng arzon o'sish kanalimiz: har ulashilgan e'lon — bepul
/// reklama.
///
/// ⚠️ Karta faqat ROST ma'lumotni ko'rsatadi (`TripPassport` dagi qoida
/// bilan bir xil): yo'nalish, vaqt, narx, bo'sh joy. To'qilgan bezak
/// yozuv yo'q.
///
/// ⚠️ Rasm bilan BIRGA matn ham yuboriladi — havola rasmda emas, matnda
/// bo'lishi kerak: rasmdagi manzilni hech kim qo'lda ko'chirmaydi.
class RidePoster extends StatelessWidget {
  const RidePoster({super.key, required this.ride, this.story = false});

  final Ride ride;

  /// HIKOYA formati (9:16) — Status/Stories uchun.
  ///
  /// 🔴 NEGA IKKI NISBAT (egasi, 2026-09-08): 4:5 lentaga yaxshi, lekin
  /// O'zbekistonda ulashishning katta qismi Status/Stories orqali
  /// ketadi va u yerda 4:5 rasm kichkina bo'lib, tepasi-pasti bo'sh
  /// qolib ketadi. 9:16 esa butun ekranni egallaydi.
  ///
  /// Ikkita ALOHIDA plakat yozilmadi: bir mahsulotdan ikki xil kartochka
  /// chiqmasin. Farq faqat nisbat va o'lchamlarda.
  final bool story;

  /// ⚠️ Har nisbat uchun ALOHIDA kalit: bitta `GlobalKey` ikkita
  /// daraxtda bo'lsa Flutter «Duplicate GlobalKey» bilan yiqiladi
  /// (varaqda ikkala variant ham quriladi).
  static final _feedKey = GlobalKey();
  static final _storyKey = GlobalKey();

  /// Sayt manzili — protokolsiz («https://» rasmda shovqin qiladi).
  static String get _shortSite =>
      Env.siteUrl.replaceFirst(RegExp(r'^https?://'), '');

  /// Plakatni rasmga olib ulashadi (matn va havola bilan birga).
  static Future<void> share(
    BuildContext context,
    Ride ride, {
    bool story = false,
  }) async {
    final t = AppStrings.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final shareText = rideShareText(ride, t);
    try {
      final boundary =
          (story ? _storyKey : _feedKey).currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return shareFallback(messenger, t, shareText);
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return shareFallback(messenger, t, shareText);
      AppHaptics.select();
      if (!context.mounted) return;
      await shareSafely(
        context,
        ShareParams(
          files: [
            // `fromData` — vaqtinchalik faylsiz (path_provider kerak emas).
            XFile.fromData(
              bytes.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'yolyolakay_elon.png',
            ),
          ],
          text: shareText,
        ),
      );
    } catch (_) {
      // Rasm tayyorlanmadi — jim qolmaymiz (izohi `shareSafely` da).
      await shareFallback(messenger, t, shareText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final when = formatDateTime(ride.departureTime, t.lang);

    return RepaintBoundary(
      key: story ? _storyKey : _feedKey,
      // Tizim shrifti kattalashtirilgan telefonda matn kartadan toshib
      // ketardi va ULASHILGAN rasmda buzuq ko'rinardi — qabul qiluvchining
      // sozlamasiga esa bu aloqador emas (izohi `TripPassport` da).
      child: MediaQuery.withNoTextScaling(
        child: AspectRatio(
          // 4:5 — lentada (Telegram, kanal) eng katta ko'rinadigan
          // nisbat. 9:16 — Status/Stories uchun: u yerda butun ekranni
          // egallaydi.
          aspectRatio: story ? 9 / 16 : 4 / 5,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: BrandColors.wineAsh),
            child: Stack(
              children: [
                // Girih — ulashiladigan rasmning zamini. Rang temadan
                // EMAS, plakatning o'z rangidan: rasm boshqa odamning
                // telefonida ochiladi.
                Positioned.fill(
                  child: GirihPattern(
                    cell: 132,
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
                        t.appName.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: BrandColors.turquoise,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),

                      Text(
                        ride.originAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: displayFontStyle(
                          theme.textTheme.headlineSmall,
                        ).copyWith(color: Colors.white),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
                        child: OrnamentMark(color: BrandColors.turquoise),
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

                      // Vaqt bo'lmasa qator umuman chizilmaydi: "—" belgisi
                      // ulashilgan rasmda "ma'lumot buzuq" degandek ko'rinadi.
                      if (when.isNotEmpty && when != '—')
                        Text(
                          when,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 🔴 NARX 16% SHAFFOFLIKDA EDI — ya'ni ko'zga
                          // umuman ilinmasdi (2026-09-08 da rasm chizib
                          // ko'rilganda topildi). Ulashiladigan
                          // plakatda odam birinchi qidiradigan raqam
                          // aynan shu; uni «suv belgisi» qilib qo'yish
                          // butun plakatni ma'nosiz qilardi.
                          Text(
                            '${formatPrice(ride.pricePerSeat)} ${t.sum}',
                            style:
                                displayFontStyle(
                                  theme.textTheme.headlineMedium,
                                ).copyWith(
                                  color: BrandColors.turquoise,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${ride.availableSeats} ${t.seats}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      // Sayt manzili — rasmni skrinshot qilib tarqatgan
                      // odamда ham brend qoladi.
                      Text(
                        _shortSite,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plakatni varaqда ko'rsatadi va ulashish tugmasini beradi.
///
/// 🔴 NEGA VARAQ, ekranga o'rnatilgan emas: plakat 4:5 — u safar ekranida
/// yarim ekranni yeb qo'yardi va har ochilganda chizilardi. Varaqda esa u
/// FAQAT so'ralganda quriladi.
///
/// ⚠️ Plakat rasmga olinishi uchun EKRANDA turishi shart (`RepaintBoundary`
/// faqat chizilgan narsani beradi) — shuning uchun avval ko'rsatiladi,
/// keyin ulashiladi. Bu ayni paytda foydali: odam nima yuborayotganini
/// oldindan ko'radi.
Future<void> showRidePoster(BuildContext context, Ride ride) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _PosterSheet(ride: ride),
  );
}

/// Ulashish varag'i — nisbat tanlovi bilan.
///
/// 🔴 NEGA TANLOV (egasi, 2026-09-08): O'zbekistonda ulashishning katta
/// qismi Status/Stories orqali ketadi, u yerda esa 4:5 rasm kichkina
/// bo'lib qoladi. Ikkalasini ham beramiz va odam O'ZI tanlaydi —
/// biz uning qayerga tashlashini bilmaymiz.
///
/// ⚠️ FAQAT TANLANGANI quriladi: ikkalasi bir vaqtda daraxtda bo'lsa
/// rasmga olish paytida qaysi biri olinayotgani chalkashardi va
/// varaq bekorga ikki barobar ko'p chizardi.
class _PosterSheet extends StatefulWidget {
  const _PosterSheet({required this.ride});

  final Ride ride;

  @override
  State<_PosterSheet> createState() => _PosterSheetState();
}

class _PosterSheetState extends State<_PosterSheet> {
  bool _story = false;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(t.posterFeed)),
                ButtonSegment(value: true, label: Text(t.posterStory)),
              ],
              selected: {_story},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _story = v.first),
            ),
            const SizedBox(height: AppSpace.md),
            Flexible(
              child: RidePoster(ride: widget.ride, story: _story),
            ),
            const SizedBox(height: AppSpace.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    RidePoster.share(context, widget.ride, story: _story),
                icon: const Icon(Icons.ios_share, size: 18),
                label: Text(t.sharePoster),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

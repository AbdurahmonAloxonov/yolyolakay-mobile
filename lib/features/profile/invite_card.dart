import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/share_safely.dart';

import '../../app/dimens.dart';
import '../../app/theme.dart';
import '../../core/env.dart';
import '../../core/haptics.dart';
import '../../l10n/strings.dart';
import '../shared/brand/atlas.dart';
import '../shared/brand/ornament.dart';

/// DO'STNI CHAQIRISH — ulashiladigan taklif kartasi.
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): bugungi eng katta
/// muammo texnik emas — bazada odam kam. Yangi foydalanuvchi bo'sh qidiruv
/// natijasini ko'radi va qaytmaydi. O'sishning eng arzon kanali esa
/// mavjud foydalanuvchining o'zi: u tanishlariga aytadi.
///
/// Ilgari ilovada «do'stingga ayt» degan yo'l UMUMAN yo'q edi — odam
/// ilova nomini eslab, qo'lda yozib berishi kerak edi.
///
/// ═══ HALOL CHEKLOV — HECH QANDAY YOLG'ON RAQAM ═══
///
/// ⚠️ Bu yerda «5 do'st chaqirdingiz» degan hisoblagich ATAYIN YO'Q.
/// Backendda taklif (referral) tizimi umuman qurilmagan: kim kimni
/// chaqirganini bilishning YO'LI YO'Q. Mahalliy hisoblagich esa faqat
/// «ulashish tugmasi necha marta bosilgani»ni bilardi — bu esa
/// «chaqirilgan do'stlar» degan yolg'on bo'lardi.
///
/// ⚠️ Mukofot ham va'da qilinmaydi: uni berish uchun ham backend kerak.
/// Va'da qilib bermaslik — ishonchni yo'qotishning eng tez yo'li.
class InviteCard extends StatelessWidget {
  const InviteCard({super.key});

  static final _boundaryKey = GlobalKey();

  static String get _shortSite =>
      Env.siteUrl.replaceFirst(RegExp(r'^https?://'), '');

  /// Kartani rasmga olib, havola bilan birga ulashadi.
  static Future<void> share(BuildContext context) async {
    final t = AppStrings.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final shareText = '${t.inviteShareText}\n${Env.siteUrl}';
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
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
            XFile.fromData(
              bytes.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'yolyolakay_taklif.png',
            ),
          ],
          // Havola MATNDA — rasmdagi manzilni hech kim qo'lda ko'chirmaydi.
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

    return RepaintBoundary(
      key: _boundaryKey,
      // Ulashiladigan rasm tizim shriftiga ergashmaydi (izohi
      // `TripPassport` da): qabul qiluvchining sozlamasiga aloqador emas.
      child: MediaQuery.withNoTextScaling(
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: BrandColors.wineAsh),
            child: Stack(
              children: [
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
                        t.inviteHeadline,
                        style: displayFontStyle(
                          theme.textTheme.headlineSmall,
                        ).copyWith(color: Colors.white),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                        child: OrnamentMark(color: BrandColors.turquoise),
                      ),
                      Text(
                        t.inviteSubline,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _shortSite,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: BrandColors.turquoise,
                          fontWeight: FontWeight.w800,
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

/// Taklif kartasini varaqда ko'rsatadi va ulashish tugmasini beradi.
Future<void> showInviteCard(BuildContext context) {
  final t = AppStrings.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(child: InviteCard()),
            const SizedBox(height: AppSpace.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => InviteCard.share(sheetContext),
                icon: const Icon(Icons.ios_share, size: 18),
                label: Text(t.inviteShare),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

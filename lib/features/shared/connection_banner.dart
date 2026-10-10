import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/dimens.dart';
import '../../core/outbox.dart';
import '../../l10n/strings.dart';

/// INTERNET YO'Q — ekran tepasida doimiy chiziq.
///
/// 🔴 NEGA KERAK (egasi, 2026-08-20): saytda offline holat allaqachon
/// ko'rsatiladi, ilovada esa YO'Q edi — so'rov yiqilsagina bir martalik
/// xabar chiqardi va yo'qolardi. Odam nega ro'yxat bo'sh yoki eskiligini
/// tushunmasdi.
///
/// Holat manbai — `ApiClient.connected` (`ValueNotifier`), u SO'ROV
/// backendga yetgan-yetmaganiga qarab yangilanadi. `connectivity_plus`
/// PAKETI ATAYIN ishlatilmadi: u "Wi-Fi ulangan" deydi-yu, o'sha Wi-Fi'da
/// internet bo'lmasa yoki backend 502 bo'lsa bilmaydi. Bu yerdagi manba —
/// haqiqat: javob keldimi.
///
/// SnackBar/banner EMAS, doimiy chiziq: uzilish o'tkinchi emas, u
/// TUZALGUNCHA turishi kerak. Javob kelishi bilan o'zi yo'qoladi.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key, required this.child});

  /// Chiziq balandligi — kontentni AYNAN shu qadar pastga suramiz.
  ///
  /// 🔑 Hisob: vertikal padding 8+8 = 16, ichidagi ikonka/matn 16 →
  /// jami 32. Qat'iy raqam ATAYIN: matn shkalasi kattalashsa chiziq
  /// ham o'sadi, lekin kontent ostiga tushib ketmasligi uchun bu yerda
  /// kafolatlangan minimum kerak (matn KESILMAYDI — `maxLines: 1` +
  /// ellipsis, izohi pastda).
  static const double _bannerHeight = 32;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(apiClientProvider).connected;
    final t = AppStrings.of(context);
    final mq = MediaQuery.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: connected,
      builder: (context, isOnline, _) => Stack(
        children: [
          /*
           * 🔴 07.09.2026, JONLI O'LCHOVDA TOPILDI: chiziq kontent
           * USTIDAN chizilardi va ko'ringanda ekran tepasini —
           * AppBar'ning yuqori qismini — qoplab qo'yardi. Orqaga
           * tugmasining bosish maydoni 56 px balandlikda markazlashgan,
           * chiziq esa ~32 px: ya'ni ORQAGA BOSGAN ODAM chiziqni
           * bosardi. Uzilish paytida — aynan odam orqaga qaytmoqchi
           * bo'lgan paytda — ilova «qotib qolgandek» tuyulardi.
           *
           * Endi chiziq ko'ringanda kontent o'sha balandlikka PASTGA
           * suriladi: chiziq hech narsani qoplamaydi.
           */
          Padding(
            padding: EdgeInsets.only(top: isOnline ? 0 : _bannerHeight),
            child: child,
          ),
          // Status bar OSTIDA — kontent bilan qoplanmasin (edge-to-edge).
          Positioned(
            top: mq.padding.top,
            left: 0,
            right: 0,
            child: Builder(
              builder: (context) {
                // Kirish/chiqish silliq: uzilish "chaqnab" ketmasin.
                return AnimatedSlide(
                offset: isOnline ? const Offset(0, -1) : Offset.zero,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: isOnline ? 0 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: IgnorePointer(
                    ignoring: isOnline,
                    // 🔴 CHIZIQ ENDI BOSILADI (2026-08-25): odamning
                    // uzilishdan keyingi savoli doim bir xil — «ilova
                    // buzuqmi, internetmi?». Javob «Xizmat holati»
                    // ekranida va unga eng qisqa yo'l aynan shu chiziq.
                    child: Material(
                      color: const Color(
                        0xFF3A3238,
                      ), // neytral to'q — xato emas, holat
                      child: InkWell(
                        // 🔴 07.09.2026, JONLI O'LCHOVDA TOPILDI:
                        // bu yerda `context.push(...)` turardi va u
                        // «No GoRouter found in context» bilan
                        // YIQILARDI. Sabab: bu vidjet
                        // `MaterialApp.router` ning `builder` ida,
                        // ya'ni router'dan YUQORIDA joylashgan —
                        // uning konteksti GoRouter'ni ko'rmaydi.
                        // Ya'ni «eng qisqa yo'l» deb qo'yilgan chiziq
                        // 25-avgustdan buyon HECH QACHON ishlamagan.
                        // Yechim: router'ni provayderdan olamiz.
                        onTap: () =>
                            ref.read(routerProvider).push(Routes.serviceStatus),
                        child: SafeArea(
                          top: false,
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.lg,
                              vertical: AppSpace.sm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_off,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: AppSpace.sm),
                                /*
                               * NAVBAT SONI — «yozganim yo'qolmadimi?»
                               * degan savolga javob AYNAN shu yerda
                               * kerak (2026-08-25).
                               *
                               * Chiziq allaqachon «internet yo'q» deb
                               * turibdi; navbatда ish bo'lsa uning
                               * o'rniga «2 ta yuborilmagan ish» deymiz —
                               * ya'ni uzilish haqidagi xabar ustiga
                               * KAFOLAT qo'shiladi, ikkinchi chiziq
                               * emas.
                               */
                                Flexible(
                                  child:
                                      ValueListenableBuilder<List<OutboxItem>>(
                                        valueListenable: ref
                                            .watch(outboxProvider)
                                            .items,
                                        builder: (context, queued, _) => Text(
                                          queued.isEmpty
                                              ? t.offlineBanner
                                              : t.queuedCount(queued.length),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

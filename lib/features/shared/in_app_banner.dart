import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/dimens.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/push_actions.dart';
import '../../core/push_routes.dart';
import '../../l10n/strings.dart';

/// Ekran TEPASIDAN tushadigan bildirishnoma.
///
/// SnackBar pastda chiqadi va tugmalarni to'sadi; real-time xabar esa
/// foydalanuvchi nima qilayotgan bo'lsa ham darhol ko'rinishi kerak, lekin
/// ishiga xalaqit bermasligi ham kerak — shuning uchun tepadan, 4 soniya.
///
/// Ilova butun umri davomida WS'ni tinglaydi va tegishli ro'yxatlarni
/// yangilaydi, shu sabab u `MaterialApp` ustida joylashadi.
class InAppBanner extends ConsumerStatefulWidget {
  const InAppBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends ConsumerState<InAppBanner> {
  String? _text;
  bool _isMessage = false;

  /// Bannerni BOSGANDA qayerga o'tish — push ma'lumoti (`type`, `peer_id`...).
  Map<String, dynamic>? _data;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _show(
    String text, {
    bool isMessage = false,
    Map<String, dynamic>? data,
  }) {
    _hideTimer?.cancel();
    setState(() {
      _text = text;
      _isMessage = isMessage;
      _data = data;
    });
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _text = null);
    });
  }

  /*
   * ═══════════════════════════════════════════════════════════════
   *  PUSH'DAGI TUGMA — «Qabul qilaman» / «Rad etaman»
   * ═══════════════════════════════════════════════════════════════
   *
   * 🔴 NEGA AYNAN SHU YERDA: amal `ApiClient` ni talab qiladi (token,
   * yangilash, xato ishlovi), bular esa faqat ASOSIY isolate'da bor.
   * Tugma shuning uchun ilovani ochadi va ish shu yerda tugaydi —
   * haydovchi uchun bu baribir BITTA bosish (ilgari besh qadam edi).
   *
   * 🔑 QAYSI BRON ekanini push AYTMAYDI (`ride_id`/`booking_id` yo'q —
   * 16.09.2026 da o'lchangan). Shuning uchun ro'yxat qayta o'qiladi va
   * kutayotgan bron BITTA bo'lsagina amal bajariladi. Ikkitasi bo'lsa
   * HECH NIMA qilinmaydi: noto'g'ri yo'lovchini qabul qilgandan ko'ra
   * odamdan so'ragan yaxshi.
   */
  Future<void> _runBookingAction(Map<String, dynamic> data) async {
    final t = AppStrings.of(context);
    final accept = data[pushActionKey] == bookingAcceptAction;
    try {
      final rides = await ref.read(ridesRepositoryProvider).myRides();
      // ⚠️ Har `await` dan keyin TEKSHIRILADI: so'rov ketayotganda odam
      // ilovadan chiqib ketsa, `setState` o'chirilgan vidjetda
      // chaqirilib xato tashlanardi.
      if (!mounted) return;
      final target = resolveSinglePending(rides);
      if (target == null) {
        // Sababi AYTILADI: tugma bosildi-yu hech nima bo'lmasa, odam
        // ilovani buzuq deb o'ylaydi.
        _show(
          pendingBookings(rides).isEmpty
              ? t.pushActionGone
              : t.pushActionMany,
          data: data,
        );
        return;
      }
      final repo = ref.read(ridesRepositoryProvider);
      if (accept) {
        await repo.acceptBooking(target.rideId, target.bookingId);
      } else {
        await repo.rejectBooking(target.rideId, target.bookingId);
      }
      if (!mounted) return;
      // Ro'yxatlar darhol yangilansin — haydovchi natijani KO'RSIN.
      ref.invalidate(myRidesProvider);
      ref.invalidate(notificationsProvider);
      _show(accept ? t.pushActionAccepted : t.pushActionRejected, data: data);
    } catch (_) {
      if (!mounted) return;
      // Tarmoq yo'q yoki server rad etdi — bron JOYIDA qoladi va
      // haydovchi uni ro'yxatdan qo'lda hal qiladi.
      _show(t.pushActionFailed, data: data);
    }
  }

  /// Push/banner ma'lumotidan kerakli ekranni ochadi.
  ///
  /// Navigatsiya build ichida EMAS, keyingi kadrda: `go` chaqiruvi widget
  /// qurilayotgan paytda daraxtni o'zgartirsa Flutter xato beradi.
  void _open(Map<String, dynamic> data) {
    // TUGMA bosilgan bo'lsa — avval AMAL, keyin ro'yxat ochiladi.
    if (isBookingAction(data)) {
      unawaited(_runBookingAction(data));
    }
    final target = pushTargetFor(data);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = ref.read(routerProvider);
      // 🔴 Egasi (2026-08-20): "bildirishnomaga kirib ORQAGA bossa ilovadan
      // chiqib ketyapti". Sabab — hamma joyга `.go()` ishlatilardi, u
      // STEKNI ALMASHTIRADI: detail ekranда (chat) orqага poplaydigan narsa
      // qolmasdi va Android orqага tugmasi ilovани yopardi.
      //
      // Yechim: TAB manzillari (`.go` — ular shell shoxlari), DETAIL
      // manzillari esa ota-tab ustiga `.push` — orqага bossa tabга qaytadi,
      // ilovадан CHIQMAYDI.
      const tabs = {
        Routes.search,
        Routes.trips,
        Routes.parcels,
        Routes.chats,
        Routes.profile,
      };
      if (tabs.contains(target.location)) {
        router.go(target.location, extra: target.extra);
        return;
      }
      final parent = _parentTab(target.location);
      if (parent != null) router.go(parent);
      router.push(target.location, extra: target.extra);
    });
  }

  /// Detail ekran uchun mos ota-tab (orqага shu yerga qaytsin). Mos tab
  /// bo'lmasa `null` — shunчаки joriy ekran ustiga push bo'ladi.
  String? _parentTab(String location) {
    if (location == Routes.chat) return Routes.chats;
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Push xizmatini shu yerda uyg'otamiz — u sessiyaga o'zi ergashadi.
    // `build` ichida `read` qilinsa har qayta chizishda takrorlanardi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pushServiceProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ilova ochiq turganda kelgan push — tizim bildirishnomasi ko'rinmaydi,
    // shuning uchun WS hodisalari bilan bir xil bannerda ko'rsatiladi.
    ref.listen(pushMessagesProvider, (previous, next) {
      if (next != null && next.text.isNotEmpty) {
        _show(next.text, data: next.data);
      }
    });

    // Foydalanuvchi telefon bildirishnomasini BOSDI — kerakli ekranga
    // o'tkazamiz. Ilova o'chiq bo'lsa ham shu yo'l ishlaydi: `PushService`
    // ishga tushganda "ilovani ochgan" pushni qayta o'qiydi.
    ref.listen(pushOpenProvider, (previous, next) {
      if (next == null) return;
      ref.read(pushOpenProvider.notifier).state = null;
      _open(next);
    });

    ref.listen(wsEventsProvider, (previous, next) {
      final event = next.value;
      if (event == null) return;

      // Hodisa turiga qarab tegishli ro'yxatlarni yangilaymiz — UI qo'l bilan
      // yangilanishini kutmasin.
      if (event.isNewMessage) {
        ref.invalidate(conversationsProvider);
      } else {
        ref.invalidate(notificationsProvider);
        ref.invalidate(myRidesProvider);
        ref.invalidate(myBookingsProvider);
      }

      // O'Z xabarimizning aks-sadosiga bildirishnoma chiqarilmaydi.
      // Ro'yxat YUQORIDA baribir yangilanadi — suhbat tartibi to'g'ri qoladi,
      // faqat ortiqcha banner ko'rinmaydi.
      final myId = ref.read(meProvider).valueOrNull?.user.id;
      if (event.isEchoOf(myId)) return;

      // OCHIQ turgan suhbatga ham banner chiqarilmaydi: xabar ekranda
      // allaqachon ko'rinadi, banner esa uni yopib turadi.
      final open = ref.read(openConversationProvider);
      if (event.isNewMessage &&
          open != null &&
          event.senderId != null &&
          event.senderId == open.peerId) {
        return;
      }

      _show(
        event.displayText,
        isMessage: event.isNewMessage,
        data: event.pushData,
      );
    });

    final text = _text;

    return Stack(
      children: [
        widget.child,
        if (text != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Banner(
              text: text,
              isMessage: _isMessage,
              onDismiss: () {
                _hideTimer?.cancel();
                setState(() => _text = null);
              },
              // 🔴 Ilgari banner FAQAT ko'rsatardi: "sizga yangi xabar"
              // yozuvini bosgan odam hech qayerga bormasdi va yozishmani
              // qo'lda qidirardi — telefon bildirishnomasidagi bilan
              // AYNI muammo. Endi ikkalasi bitta yo'ldan boradi.
              onTap: () {
                final data = _data;
                _hideTimer?.cancel();
                setState(() => _text = null);
                if (data != null) _open(data);
              },
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.onDismiss,
    required this.onTap,
    this.isMessage = false,
  });

  final String text;
  final VoidCallback onDismiss;

  /// Bosilganda — hodisaga tegishli ekran ochiladi.
  final VoidCallback onTap;

  /// Chat xabari — boshqa ikonka va boshqa aksent rang.
  final bool isMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: ValueKey(text),
            direction: DismissDirection.up,
            onDismissed: (_) => onDismiss(),
            // Bosish YUQORIGA SURISHNI to'smaydi: `Dismissible` ishorani
            // birinchi bo'lib oladi, `InkWell` esa faqat toza bosishga javob
            // beradi — banner ham ochiladi, ham surib yuboriladi.
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.lg,
                ),
                decoration: BoxDecoration(
                  color: BrandColors.wineAsh,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  // Banner MAZMUN USTIDA suzadi — chegara emas, soya kerak,
                  // aks holda u sahifaning bir qismidek ko'rinadi.
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3332292F),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isMessage
                          ? Icons.chat_bubble_rounded
                          : Icons.notifications_active,
                      size: 20,
                      color: BrandColors.turquoise,
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.of(context).close,
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white70,
                      ),
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

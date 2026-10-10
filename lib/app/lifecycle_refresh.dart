import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/away_digest.dart';
import 'providers.dart';

/// Ilova fondan qaytganda ma'lumotni yangilaydi. Hech narsa chizmaydi.
///
/// MUAMMO: telefonda odam ilovadan doim chiqib turadi — qo'ng'iroq, xabar,
/// ekran qulfi. Qaytib kelganda esa ekranda ESKI ma'lumot turardi: haydovchi
/// safarni boshlagan bo'lsa ham "boshlanmagan", yangi ariza kelgan bo'lsa ham
/// ko'rinmasdi. Odam buni "ilova jonli ishlamayapti" deb his qiladi.
///
/// Vebda aynan shu xato bor edi (`refetchOnWindowFocus: false`) va 2026-08-10
/// da tuzatildi — bu o'sha tuzatishning Flutter tomoni.
///
/// NEGA HAMMA PROVAYDER EMAS: backend har chaqiruvga ~0.7 s sarflaydi va uy
/// mashinasida ishlaydi. Ilovaga har qaytganda o'nlab so'rov yuborish uni
/// bo'g'adi. Shuning uchun faqat VAQTGA BOG'LIQ ro'yxatlar yangilanadi:
/// safarlar, bronlar, bildirishnomalar. Profil, tariflar, shaharlar ro'yxati
/// — bular sekin o'zgaradi va o'z-o'zidan yangilanaveradi.
///
/// `autoDispose` provayderlar ekran yopiq bo'lsa allaqachon o'chgan bo'ladi va
/// `invalidate` ularga ta'sir qilmaydi — ya'ni ortiqcha so'rov ketmaydi.
class LifecycleRefresh extends ConsumerStatefulWidget {
  const LifecycleRefresh({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LifecycleRefresh> createState() => _LifecycleRefreshState();
}

class _LifecycleRefreshState extends ConsumerState<LifecycleRefresh>
    with WidgetsBindingObserver {
  /// Oxirgi yangilash vaqti — juda tez-tez qaytishda so'rov bo'roni bo'lmasin.
  /// Vebdagi `staleTime: 30s` bilan bir xil mantiq.
  DateTime? _lastRefresh;
  static const _minInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // OFFLINE NAVBAT diskdan o'qiladi va darhol yuborishga urinadi
    // (`core/outbox.dart`). SHU YERDA, chunki bu vidjet ilova umri
    // davomida bir marta quriladi va allaqachon hayot siklini kuzatadi.
    //
    // Xato JIM yutiladi: navbat qo'shimcha kafolat, uning yiqilishi
    // ilovani ochishga to'sqinlik qilmasligi kerak.
    unawaited(
      ref.read(outboxProvider).load().then(
        (_) => ref.read(outboxProvider).flush(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /*
     * ILOVADAN CHIQISH — «sizsiz nima bo'ldi» uchun BAZA yozib qo'yiladi
     * (`core/away_digest.dart`).
     *
     * 🔴 Aynan CHIQISHDA, qaytishда emas: qaytганда o'lchansa, taqqoslash
     * uchun manba bo'lmasdi va birinchi qaytish har doim «yangilik yo'q»
     * berardi.
     */
    if (state == AppLifecycleState.paused) {
      final chats = ref.read(unreadChatsProvider).valueOrNull;
      // Chat soni hali kelmagan bo'lsa bazani BUZMAYMIZ: 0 yozib qo'ysak,
      // qaytганда butun o'qilmagan ro'yxat «yangi» bo'lib ko'rinardi.
      if (chats != null) {
        unawaited(
          AwayDigest(ref.read(sharedPrefsProvider)).remember(
            unreadNotifications: ref.read(unreadCountProvider),
            unreadChats: chats,
          ),
        );
      }
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    /*
     * TASHQI OQIMDAN QAYTISH (to'lov) — chastota chekloviga BO'YSUNMAYDI
     * va u tekshiruvdan OLDIN turadi.
     *
     * MUAMMO (2026-08-12, egasi xabari): odam Click'da to'lovni tugatib
     * ilovaga qaytadi-yu, tarif ekranida hamon ESKI paket turadi. Ya'ni pul
     * o'tgan, ilova esa "o'tmadi" deb ko'rsatadi. Sababi ikkitasi:
     *   1. Click bizni ilovaga qaytara olmaydi (qaytish manzili yo'q —
     *      backenddan so'ralgan), shuning uchun odam QO'LDA qaytadi;
     *   2. qo'lda qaytganda esa obuna qayta o'qilmasdi — quyidagi ro'yxatda
     *      `subscriptionProvider` yo'q edi.
     *
     * 30 soniyalik gard bu yerda ZARARLI bo'lardi: to'lov ko'pincha undan
     * tez tugaydi va aynan o'sha qaytishda yangilash kerak.
     */
    if (ref.read(awaitingExternalFlowProvider)) {
      ref.read(awaitingExternalFlowProvider.notifier).state = false;
      ref.invalidate(subscriptionProvider);
      ref.invalidate(meProvider);
    }

    /*
     * OFFLINE NAVBAT — 30 soniyalik gardDAN OLDIN.
     *
     * Odam ko'pincha aynan "aloqa keldimi?" deb ilovaga qaytadi. Navbat
     * bo'sh bo'lsa `flush` hech nima qilmaydi (bir necha mikrosoniya),
     * ya'ni gard ostiga qo'yishning ma'nosi yo'q — u faqat yozilgan
     * xabarni yana yarim daqiqa ushlab turardi.
     */
    unawaited(ref.read(outboxProvider).flush());

    final now = DateTime.now();
    final last = _lastRefresh;
    if (last != null && now.difference(last) < _minInterval) return;
    _lastRefresh = now;

    ref.invalidate(myRidesProvider);
    ref.invalidate(myBookingsProvider);
    ref.invalidate(notificationsProvider);

    // KUZATILAYOTGAN YO'NALISHLAR — ilovaga qaytilganda tekshiriladi
    // (izohi `core/route_watch.dart` da). Alohida taymer ATAYIN yo'q:
    // u batareyani yeydi va Android baribir uni fon rejimda to'xtatadi,
    // ya'ni yolg'on va'da bo'lardi.
    //
    // Xato JIM yutiladi: kuzatuv qo'shimcha funksiya, uning yiqilishi
    // yangilanishni to'xtatmasligi kerak.
    unawaited(ref.read(routeWatcherProvider).checkAll());

    /*
     * MASHINA MODERATSIYASI — tasdiqlangani (yoki qaytarilgani) aytiladi.
     *
     * 🔴 NEGA: haydovchi mashina qo'shib, «Moderatsiyada» nishonini
     * ko'rib qoladi va QACHON tugashini bilmaydi; tasdiqlanmaguncha esa
     * e'lon bera olmaydi. Backenddan push so'ralgan (xat, 07.09) —
     * javob kelguncha mijozda yopamiz.
     *
     * 🔑 Avval EKRANDA KO'RINGAN holat yozib qo'yiladi, keyin server
     * bilan solishtiriladi: «odam nimani ko'rgan» va «hozir nima» —
     * xabar faqat SHU IKKISI farq qilganda beriladi.
     *
     * 🔑 Tarmoqqa chiqish faqat kutilayotgan mashina bo'lsa (`hasPending`
     * ichkarida tekshiriladi) — qolgan hammaga qo'shimcha so'rov ketmaydi.
     */
    unawaited(_checkCarModeration());
  }

  Future<void> _checkCarModeration() async {
    try {
      final watcher = ref.read(carModerationWatcherProvider);
      final me = ref.read(meProvider).valueOrNull;
      if (me != null) await watcher.remember(me.cars);
      final changed = await watcher.check();
      // `await` dan keyin vidjet o'lgan bo'lishi mumkin — `ref` ga
      // tegishdan oldin tekshiramiz (aks holda `dispose` dan keyin
      // `invalidate` istisno beradi).
      if (changed && mounted) ref.invalidate(meProvider);
    } catch (_) {
      /* qo'shimcha funksiya — yiqilsa ilovaga qaytish buzilmasin */
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

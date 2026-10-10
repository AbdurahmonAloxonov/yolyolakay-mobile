import 'package:flutter/material.dart';

import '../../core/haptics.dart';

/// Tortib-yangilash — brend rangidagi ISHONCHLI indikator.
///
/// 🔴 QAYTA ISHLANDI (egasi, 2026-08-20: "refresh notogri ishlayapti —
/// pastga tortilganda tortilgancha qolib ketyapti, qaytmayapti joyiga va
/// boshqa qismlari pastga tushib ketyapti"). Ilgari bu maxsus, overscroll
/// hodisalarini QO'LDA sanaydigan vidjet edi — u ba'zi ekranlarda (ayniqsa
/// qisqa ro'yxatlarда) qotib qolar, offset o'z holiga qaytmasdi.
///
/// Endi Flutter'ning O'Z `RefreshIndicator`i ustiga qurilgan: pull/qaytish
/// mexanikasi sinovdan o'tgan va HAMMA platformada to'g'ri ishlaydi — hech
/// qachon qotib qolmaydi, kontent siljib ketmaydi. Brend hissi rang orqali
/// (`colorScheme.primary`) va tortishда yengil tebranish orqali beriladi.
///
/// API o'zgarmadi (`YolRefresh(onRefresh:, child:)`) — 11 chaqiruv joyi
/// tegilmadi.
///
/// `ScrollConfiguration` + `AlwaysScrollableScrollPhysics` SHART: Android'ning
/// default `ClampingScrollPhysics`i ekranga sig'adigan KALTA ro'yxatда
/// overscroll'ni umuman tug'dirmaydi — usiz bo'sh/qisqa ro'yxatni tortib
/// bo'lmasdi.
class YolRefresh extends StatefulWidget {
  const YolRefresh({super.key, required this.onRefresh, required this.child});

  /// `RefreshIndicator.onRefresh` bilan bir xil shartnoma: future tugaguncha
  /// indikator aylanadi.
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<YolRefresh> createState() => _YolRefreshState();
}

class _YolRefreshState extends State<YolRefresh> {
  /// Ichkaridagi ro'yxatning holati — TEPAGA qaytarish uchun.
  ///
  /// 🔴 Egasi (2026-08-21): «refresh qilinganda cardlar tepaga
  /// qaytmayapti». Yangilangach ro'yxat almashadi, lekin siljish o'sha
  /// joyda qolardi — odam yangi ro'yxatning O'RTASIDAN chiqib qolardi va
  /// birinchi (eng mos) natijalarni ko'rmasdi.
  ///
  /// Holat `ScrollNotification` orqali olinadi: `YolRefresh` ni 11 joyda
  /// chaqiramiz va ularning hammasiga `ScrollController` qo'shish —
  /// o'n bitta joyni o'zgartirish va o'n bitta yangi xato ehtimoli.
  ScrollPosition? _position;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async {
        AppHaptics.success(); // "yangilash boshlandi" — barmoq javob oladi
        /*
         * 🔴 YANGILASH YIQILSA HAM ILOVA YIQILMASIN (2026-09-04).
         *
         * `ref.refresh(provider.future)` tarmoq yo'q bo'lsa xato
         * TASHLAYDI. `RefreshIndicator` uni ushlamaydi va xato
         * hech kim kutmagan joyga chiqib ketadi — testda bu darhol
         * ko'rindi, qurilmada esa u Sentry'ga «unhandled» bo'lib
         * tushadi.
         *
         * Odam uchun esa hech nima o'zgarmaydi: xato holati
         * ekranning O'ZIDA ko'rsatiladi (`AsyncValue.error` →
         * `ErrorView`), aylanma esa to'xtashi kerak — aynan shu
         * yerda to'xtaydi.
         */
        try {
          await widget.onRefresh();
        } catch (_) {
          // Xato ekranda ko'rinadi; bu yerda qayta tashlashning
          // ma'nosi yo'q.
        }
        _backToTop();
      },
      color: scheme.primary,
      backgroundColor: scheme.surface,
      displacement: 44,
      strokeWidth: 2.6,
      child: NotificationListener<ScrollNotification>(
        // `false` — xabarni YUTMAYMIZ: `RefreshIndicator`ning o'zi ham shu
        // xabarlarni eshitadi, yutsak tortish umuman ishlamay qolardi.
        onNotification: (notification) {
          final ctx = notification.context;
          if (ctx != null) _position = Scrollable.maybeOf(ctx)?.position;
          return false;
        },
        child: ScrollConfiguration(
          behavior: const _AlwaysScrollBehavior(),
          child: widget.child,
        ),
      ),
    );
  }

  /// Ro'yxatni boshiga qaytaradi.
  ///
  /// Sakrash EMAS, silliq: ro'yxat to'satdan almashsa odam nima
  /// bo'lganini tushunmaydi. Ekran yopilgan bo'lsa hech nima qilinmaydi.
  void _backToTop() {
    final position = _position;
    if (!mounted || position == null || !position.hasContentDimensions) return;
    // Allaqachon tepada bo'lsa animatsiya ham kerak emas.
    if (position.pixels <= position.minScrollExtent + 1) return;
    position.animateTo(
      position.minScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
}

/// Ro'yxatni DOIM scroll qilinadigan qiladi — qisqa ro'yxat ham tortilsin.
/// Ro'yxatning O'Z `physics`i berilgan bo'lsa, u ustun (odatiy Flutter
/// qoidasi), shuning uchun maxsus ekranlar buzilmaydi.
///
/// 🔴 ENG MUHIMI — `applyTo` (egasi qurilmada: «slide qilishda qotish bor»,
/// 2026-08-26). Ilgari bu yerda `const AlwaysScrollableScrollPhysics()`
/// turardi, ya'ni PARENT'SIZ. Manba tekshirildi: bu sinf atigi IKKI narsani
/// override qiladi — `applyTo` va `shouldAcceptUserOffset`. Qolgan hamma
/// narsa `ScrollPhysics` bazasiga tushadi, baza esa hammasini `parent` ga
/// uzatadi. Parent null bo'lsa:
///
///   • `createBallisticSimulation` -> **null** = INERSIYA YO'Q. Barmoq
///     uzilishi bilan ro'yxat SHU YERDA to'xtaydi. Odam buni aynan
///     «qotish» deb his qiladi: surasan, u ergashmaydi;
///   • `applyBoundaryConditions` -> 0.0 = chekka USHLAB TURILMAYDI, ro'yxat
///     oxiridan nariga surilib ketaveradi;
///   • `RangeMaintainingScrollPhysics` yo'qoladi — ro'yxat bo'yi
///     o'zgarganda joy sakraydi.
///
/// `MaterialScrollBehavior` dan meros olinadi (oddiy `ScrollBehavior` emas):
/// u `getPlatform` ni mavzudan oladi va Android'da M3 «cho'ziluvchi»
/// overscroll effektini beradi. Bazadan meros olinganda u ham yo'qolgan edi.
///
/// ⚠️ Bu 12 ta ekranga tegadi — `YolRefresh` shuncha joyda chaqiriladi.
class _AlwaysScrollBehavior extends MaterialScrollBehavior {
  const _AlwaysScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      // `applyTo` platformaning O'Z fizikasini (Android: Clamping +
      // RangeMaintaining) PARENT qilib biriktiradi.
      const AlwaysScrollableScrollPhysics().applyTo(
        super.getScrollPhysics(context),
      );
}

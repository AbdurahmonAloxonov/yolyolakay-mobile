import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dimens.dart';
import 'state_views.dart';
import 'yol_refresh.dart';

/// TORTIB-YANGILASH — YUKLANISH VA XATO HOLATIDA HAM.
///
/// 🔴 NEGA YOZILDI (egasi, 2026-08-30: «nega ilovada hamma joyda
/// refresh ishlamayapti»).
///
/// O'lchandi (`test/refresh_everywhere_test.dart`): `YolRefresh` o'zi
/// benuqson, lekin u ekranlarda `async.when(...)` ning FAQAT `data:`
/// shoxiga o'ralgan edi. Ya'ni:
///
///   ro'yxat yuklandi   → tortish ishlaydi
///   ro'yxat YUKLANMADI → tortadigan narsaning O'ZI yo'q
///
/// Bu teskari mantiq. Odam tortib-yangilashni AYNAN ma'lumot
/// kelmaganda qiladi — bu uning birinchi refleksi. Biz esa aynan
/// o'sha lahzada uni olib qo'yganmiz va odam «refresh ishlamayapti»
/// degan xulosaga keladi. Butunlay haqli.
///
/// 🔑 IKKINCHI SHART: yuklanish va xato ko'rinishlari ham SURILADIGAN
/// bo'lishi kerak. `RefreshIndicator` tortishni faqat `Scrollable` dan
/// eshitadi — oddiy `Center(child: ...)` ni tortib bo'lmaydi. Shuning
/// uchun ular `ListView` ichiga solinadi.
///
/// Ishlatish:
/// ```dart
/// YolRefreshable<List<Item>>(
///   value: ref.watch(itemsProvider),
///   // ⚠️ `invalidate` EMAS: u yangi ma'lumotni KUTMAYDI va
///   //    aylanma darhol to'xtaydi (`test/refresh_awaits_test.dart`).
///   onRefresh: () => ref.refresh(itemsProvider.future),
///   builder: (items) => ListView(...),
/// )
/// ```
class YolRefreshable<T> extends StatelessWidget {
  const YolRefreshable({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.builder,
    this.loading,
  });

  final AsyncValue<T> value;

  /// Odatda `ref.refresh(provider.future)` — u yangi ma'lumot
  /// KELGUNCHA kutadi, ya'ni aylanma o'z vaqtida to'xtaydi.
  final Future<void> Function() onRefresh;

  final Widget Function(T data) builder;

  /// Yuklanish ko'rinishi (odatda skelet). Berilmasa oddiy aylanma.
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return YolRefresh(
      onRefresh: onRefresh,
      child: value.when(
        data: builder,
        loading: () => _scrollable(
          loading ??
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.huge),
                child: Center(child: CircularProgressIndicator()),
              ),
        ),
        // Xatoda `onRetry` HAM qoladi: tortish — refleks, tugma esa
        // ochiq yo'l. Ikkalasi bir ishni qiladi, lekin odamlar har xil.
        error: (error, _) =>
            _scrollable(ErrorView(error: error, onRetry: () => onRefresh())),
      ),
    );
  }

  /// Tortish ishlashi uchun mazmun SURILADIGAN bo'lishi shart.
  ///
  /// 🔴 `ListView(children: [child])` EMAS (2026-08-30 da o'lchandi):
  /// yuklanish ko'rinishi ko'pincha `ListSkeleton` — u ham `ListView`.
  /// Ro'yxat ichiga ro'yxat solinsa Flutter «Vertical viewport was
  /// given unbounded height» deb yiqiladi va butun ekran oq qoladi.
  ///
  /// `SliverFillRemaining(hasScrollBody: false)` bolaga ekran
  /// balandligini CHEGARA qilib beradi — ichida ro'yxat bo'lsa ham
  /// to'g'ri joylashadi. Suriladigan qism esa bitta, ya'ni
  /// `RefreshIndicator` tortishni aniq eshitadi.
  /// ⚠️ `CustomScrollView` + `SliverFillRemaining` EMAS: u ba'zi
  /// ekranlarda (`CollapsingScaffold`) ichki o'lchov so'raladigan
  /// joyga tushib qoladi va `RenderViewport does not support
  /// returning intrinsic dimensions` beradi. Oddiy `ListView` esa
  /// hamma joyda ishlaydi — sharti bitta: ichidagi vidjet o'zi
  /// viewport bo'lmasin (`ListSkeleton` shuning uchun `shrinkWrap`).
  Widget _scrollable(Widget child) =>
      refreshableState(onRefresh: onRefresh, child: child);
}

/// Yuklanish yoki xato ko'rinishini TORTILADIGAN qiladi.
///
/// 🔴 NEGA ALOHIDA FUNKSIYA (egasi, 2026-09-04: «profilda ham yo'q,
/// asosiy qidirish qismida ham yo'q — har bir joyda bo'lishi kerak»).
///
/// `YolRefreshable` bu ishni allaqachon qiladi, lekin unga o'tish
/// ekranning butun `when(...)` tuzilishini qayta yozishni talab
/// qiladi. Ba'zi ekranlarda `data:` shoxi uzun va murakkab
/// (`tariffs`, `my_trips`), ya'ni qayta yozish yangi xato ehtimoli.
/// Bu yordamchi esa FAQAT ikkita qatorni almashtiradi:
///
/// ```dart
/// loading: () => refreshableState(onRefresh: r, child: const ListSkeleton()),
/// error: (e, _) => refreshableState(onRefresh: r, child: ErrorView(error: e, onRetry: r)),
/// ```
///
/// ⚠️ Ichidagi vidjet O'ZI viewport bo'lmasin (`ListSkeleton` shuning
/// uchun `shrinkWrap`) — izohi yuqorida, `_scrollable` da.
Widget refreshableState({
  required Future<void> Function() onRefresh,
  required Widget child,
}) => YolRefresh(
  onRefresh: onRefresh,
  child: ListView(
    padding: const EdgeInsets.all(AppSpace.lg),
    children: [child],
  ),
);

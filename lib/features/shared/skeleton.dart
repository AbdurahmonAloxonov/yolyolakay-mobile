import 'package:flutter/material.dart';

import '../../app/dimens.dart';

/// Yuklanish skeleti — aylanma indikator O'RNIGA.
///
/// 🔴 NEGA (egasi tasdiqladi, 2026-08-19): ekran o'rtasidagi
/// `CircularProgressIndicator` ikki narsani qilmaydi. Birinchisi — u nima
/// kelayotganini AYTMAYDI: bo'sh ekran bir xil ko'rinadi, ro'yxat kelayaptimi
/// yoki bitta karta kelayaptimi bilinmaydi. Ikkinchisi — ma'lumot kelganda
/// joylashuv birdan o'zgaradi va sahifa SAKRAYDI (odam bosmoqchi bo'lgan joyi
/// ostidan surilib ketadi).
///
/// Skelet ikkalasini ham hal qiladi: kelayotgan joylashuvni OLDINDAN chizadi,
/// shuning uchun kutish qisqaroq tuyuladi va ma'lumot kelganda hech narsa
/// siljimaydi.
///
/// Pulsatsiya CHEKSIZ, lekin faqat yuklanish davomida: vidjet daraxtdan
/// olingan zahoti kontroller ham to'xtaydi. Bezak sifatida cheksiz
/// animatsiya yo'q (web'dagi qoida bilan bir xil).
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.height = 14,
    this.width,
    this.radius = AppRadius.badge,
  });

  final double height;

  /// `null` — bor kenglikni egallaydi.
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    /*
     * 🔴 «SUYAK» RANGI (2026-09-02, «YO'L» dizayn tili).
     *
     * Ilgari bu yerda `theme.dividerColor` turardi — u AJRATGICH uchun
     * mo'ljallangan va shuning uchun sezilarli darajada to'q. Natijada
     * yuklanish skeleti MAZMUNDEK ko'rinardi: ekranda to'q kulrang
     * bloklar turardi va odam ular yuklanayotgan joy emas, haqiqiy
     * (o'qib bo'lmaydigan) matn deb o'ylashi mumkin edi.
     *
     * Skelet «bu yerda nimadir bo'ladi» deb SHIVIRLASHI kerak.
     * `surfaceContainerHighest` — aynan shu uchun: zaminidan bir oz
     * to'qroq, lekin matndan ancha ochroq. (U 2026-09-02 da neytral
     * qilingan — ilgari pushtiga bo'yalgan edi.)
     */
    final base = theme.colorScheme.surfaceContainerHighest;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Karta ro'yxati shaklidagi skelet — safarlar, posilkalar, suhbatlar,
/// bildirishnomalar kabi bir xil tuzilishdagi ro'yxatlar uchun.
///
/// Har karta: sarlavha + ikkita kalta qator. Aniq nusxa bo'lishi shart emas —
/// ko'z uchun "shu yerda kartalar bo'ladi" degan ishora yetarli.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 3, this.padding});

  final int count;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      // Skelet SURILMAYDI: u vaqtinchalik va uni aylantirishning ma'nosi yo'q,
      // aylantirilgan holat esa haqiqiy ro'yxat kelganda yo'qoladi.
      physics: const NeverScrollableScrollPhysics(),
      // 🔴 `shrinkWrap` (2026-08-30): skelet endi TORTIB-YANGILANADIGAN
      // ro'yxat ICHIDA ham chiziladi (`YolRefreshable`). Usiz Flutter
      // «Vertical viewport was given unbounded height» deb yiqilardi va
      // ekran butunlay oq qolardi. Atigi 3 element — narxi yo'q.
      shrinkWrap: true,
      padding: padding ?? const EdgeInsets.all(AppSpace.lg),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
      itemBuilder: (context, _) => Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(height: 18, width: 180),
            SizedBox(height: AppSpace.md),
            Skeleton(height: 12, width: 120),
            SizedBox(height: AppSpace.sm),
            Skeleton(height: 12, width: 90),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'my_roads_map.dart';
import 'reviews_section.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../data/models/user.dart';
import '../../l10n/strings.dart';
import '../moderation/report_block_sheet.dart';
import '../shared/refreshable.dart';
import '../shared/yol_refresh.dart';
import '../shared/brand/suzani_icons.dart';
import '../shared/state_views.dart';
import '../shared/trust_ladder.dart';
import '../shared/ui.dart';
import '../shared/brand/brand_panels.dart';
import '../../app/theme.dart';

/// BEGONA foydalanuvchi profili — odatda haydovchi.
///
/// 🔴 NEGA KERAK: haydovchi ilovada O'LIK NUQTA edi. Yo'lovchi safar
/// kartochkasida ism va yulduzchani ko'rardi, lekin ustiga bosolmasdi —
/// "bu kim?" degan savolga javob beradigan joy umuman yo'q edi. Bron
/// qilish esa aynan shu savolga tayanadi.
///
/// Ma'lumot `GET /users/{id}` dan (jonli o'lchandi 2026-08-20): ism,
/// Reyting va baholar soni, ro'yxatdan o'tgan sana.
///
/// ⚠️ BU YERDA HECH NIMA TO'QIB CHIQARILMAYDI. Backend "safarlar soni",
/// "javob berish tezligi" kabi ma'lumotlarni BERMAYDI — ular ishonchni
/// oshirsa ham, yo'q raqamni chizib qo'yish yolg'on bo'lardi. Maydon
/// kelmasa, qator umuman ko'rsatilmaydi.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId, this.fallbackName});

  final String userId;

  /// Safar kartochkasidan kelgan ism — so'rov yuklanayotganda sarlavha
  /// bo'sh turmasin. Bo'sh sarlavha "ilova buzuq" degandek ko'rinadi.
  final String? fallbackName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final profile = ref.watch(userByIdProvider(userId));

    return Scaffold(
      appBar: AppBar(
        bottom: const JiyakLine(),
        title: Text(prettyName(fallbackName) ?? t.driver),
        actions: [
          ReportBlockMenu(targetUserId: userId, targetName: fallbackName),
        ],
      ),
      body: profile.when(
        // 🔴 Tortish yuklanish va xatoda ham — izohi `refreshableState` da.
        loading: () => refreshableState(
          onRefresh: () => ref.refresh(userByIdProvider(userId).future),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.huge),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (error, _) => refreshableState(
          onRefresh: () => ref.refresh(userByIdProvider(userId).future),
          child: ErrorView(
            error: error,
            onRetry: () => ref.refresh(userByIdProvider(userId).future),
          ),
        ),
        // ⚠️ BO'SH holat ham tortiladigan: «profil topilmadi» ko'pincha
        // vaqtinchalik (server javob bermadi yoki id hali yozilmagan),
        // odam esa aynan shunda tortadi.
        data: (user) => user == null
            ? refreshableState(
                onRefresh: () => ref.refresh(userByIdProvider(userId).future),
                // qulaylik: chiqish yo'li SHART EMAS — bu ekran har
                // doim PUSH bilan ochiladi, ya'ni sarlavhada orqaga
                // tugmasi bor va ekran tortib-yangilanadi.
                child: EmptyView(
                  suzani: SuzaniIcon.person,
                  title: t.profileNotFound,
                ),
              )
            : _Body(user: user),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // TORTIB-YANGILASH — reyting va sharhlar o'zgaradi, odam esa
    // ularni ko'rish uchun ekrandan chiqib qaytishga majbur edi.
    return YolRefresh(
      // ⚠️ `invalidate` EMAS, `refresh(...future)`: `invalidate` sinxron
      // qaytadi va indikator ma'lumot kelmasdan yo'qolardi
      // (`refresh_awaits_test` shu qoidani qotiradi).
      onRefresh: () async {
        await Future.wait([
          ref.refresh(userByIdProvider(user.id).future),
          ref.refresh(userFeedbackProvider(user.id).future),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          const SizedBox(height: AppSpace.md),
          Center(
            child: PersonAvatar(
              url: user.avatarUrl,
              radius: 48,
              gender: user.gender,
              // Rasm yo'q bo'lsa — o'sha odam uchun DOIM bir xil suzani muhri
              // (saytdagi bilan ham bir xil hash).
              seed: user.id,
              tapToView: true,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            prettyName(user.displayName) ?? t.driver,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpace.xs),
          const SizedBox(height: AppSpace.xl),

          // ISHONCH NARVONI — tarqoq dalillar o'rniga bitta javob
          // (izohi `core/trust.dart` da). Mashina bosqichi bu yerda
          // KO'RSATILMAYDI: `/users/{id}` mashinalarni qaytarmaydi va
          // «tasdiqlanmagan» deb yozish yolg'on bo'lardi.
          TrustLadder(user: user),
          const SizedBox(height: AppSpace.md),

          Card(
            child: Column(
              children: [
                // Reyting — baholar SONI bilan. Son bo'lmasa reyting yolg'on
                // ishonch beradi: bitta besh ballik baho "5.0" bo'lib ko'rinadi.
                if ((user.rating ?? 0) > 0)
                  ListTile(
                    leading: const Icon(Icons.star, color: BrandColors.star),
                    title: Text(user.rating!.toStringAsFixed(1)),
                    subtitle: Text(t.reviewsCount(user.ratingCount ?? 0)),
                  ),
                if (user.createdAt != null)
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(formatDate(user.createdAt, t.lang)),
                    subtitle: Text(t.memberSince),
                  ),
                if (user.isDriver)
                  ListTile(
                    leading: const Icon(Icons.directions_car_outlined),
                    title: Text(t.roleDriver),
                  ),
              ],
            ),
          ),

          /*
           * ODATDAGI YO'LLARI — 16.09.2026.
           *
           * 🔴 Yo'lovchi haydovchi profilini ochganda «bu odam bu
           * yo'lni muntazam yuradimi?» degan savolga javob yo'q edi:
           * reyting bor, sharh bor, YO'L yo'q. Bu ishonch uchun
           * sharhdan kam emas — muntazam yuradigan odam tasodifiy
           * haydovchi emas.
           *
           * ✅ Ruchka 16.09.2026 da ochildi va o'lchandi: javobda faqat
           * marshrut/vaqt/narx/holat — yo'lovchi, telefon va bron YO'Q.
           * Safari bo'lmasa karta umuman chizilmaydi.
           */
          const SizedBox(height: AppSpace.md),
          MyRoadsMap(driverId: user.id),

          // SHARHLAR — reyting raqamining ORTIDA nima turgani.
          //
          // 🔴 Shu paytgacha bu yerda faqat «4.9» va baholar soni turardi.
          // Odam izoh yozardi va u hech qayerda ko'rinmasdi (kontraktda
          // `GET /rating` yo'q edi). Izohi `ReviewsSection` da.
          const SizedBox(height: AppSpace.md),
          ReviewsSection(userId: user.id),
        ],
      ),
    );
  }
}

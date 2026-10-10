import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/shared/brand/suzani_icons.dart';
import '../l10n/strings.dart';
import 'active_role.dart';
import 'providers.dart';
import 'theme.dart';

/// Pastki navigatsiya — har bo'lim o'z stack'ini saqlaydi (indexedStack).
///
/// Birinchi band ROLGA qarab o'zgaradi: yo'lovchiga "Qidirish", haydovchiga
/// "E'lon berish". Ilgari haydovchi ham qidiruvdan boshlardi — ya'ni ilova
/// unga yo'lovchining ishini birinchi qilib ko'rsatardi (izohi
/// `app/active_role.dart` da).
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final isDriverMode = ref.watch(isDriverModeProvider);
    final neon = ref.watch(themeStyleProvider) == ThemeStyle.neon;

    /*
     * 🔴 O'QILMAGAN XABAR NISHONI.
     *
     * Server o'qilmaganlar sonini beryapti (`unread_count`), lekin u
     * HECH QAYERDA ko'rsatilmasdi: odam "Suhbatlar" bo'limiga o'zi
     * kirib ko'rmaguncha yangi xabar borligini bilmasdi. Push kelmasa
     * (fonda WS o'ladi — `push_oqimi` xati) xabar butunlay e'tibordan
     * chetda qolardi.
     *
     * Uzilishda nishon shunchaki ko'rinmaydi — "0 xabar" deb aldamaydi.
     */
    final unreadChats = ref.watch(unreadChatsProvider).valueOrNull ?? 0;

    // Yangi xabar kelsa nishon DARHOL yangilansin: 15 soniya kutish
    // "keldimi-kelmadimi" degan ikkilanish tug'diradi.
    ref.listen(wsEventsProvider, (previous, next) {
      // `valueOrNull`: WS oqimi xato bersa `value` uni QAYTA
      // TASHLAYDI va ilovaning ILDIZ ekrani qulardi.
      if (next.valueOrNull?.isNewMessage ?? false) {
        ref.invalidate(unreadChatsProvider);
      }
    });

    return Scaffold(
      body: shell,
      bottomNavigationBar: _neonWrap(
        neon,
        NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          /*
           * 🔑 SUZANI IKONKALARI (2026-08-24).
           *
           * Pastki menyu — ilovaning ENG KO'P ko'riladigan yuzasi va aynan
           * u har qanday boshqa Flutter ilovasidagidek ko'rinardi (stok
           * Material ikonkalari). Brendimizda suzani muhri, ikat to'quvi
           * va o'z palitramiz bor edi-yu, skrinshotdan ilovani tanib
           * bo'lmasdi.
           *
           * Silueti tanish qoladi (lupa lupa, mashina mashina), naqsh esa
           * CHEKKADA — izohi `suzani_icons.dart` da.
           */
          if (isDriverMode)
            NavigationDestination(
              icon: const SuzaniIconWidget(SuzaniIcon.create),
              selectedIcon: const SuzaniIconWidget(
                SuzaniIcon.create,
                filled: true,
              ),
              label: t.createRideShort,
            )
          else
            NavigationDestination(
              icon: const SuzaniIconWidget(SuzaniIcon.search),
              selectedIcon: const SuzaniIconWidget(
                SuzaniIcon.search,
                filled: true,
              ),
              label: t.searchButton,
            ),
          NavigationDestination(
            icon: const SuzaniIconWidget(SuzaniIcon.car),
            selectedIcon: const SuzaniIconWidget(SuzaniIcon.car, filled: true),
            // Ekran sarlavhasi bilan BIR XIL bo'lsin: haydovchi rejimida u
            // "E'lonlarim" deb ochiladi, yorliq esa "Safarlarim" deb turardi.
            label: isDriverMode ? t.myRidesTitle : t.myTripsTitle,
          ),
          // Pochta 1-darajaga chiqarildi (2026-08-08): ilgari u profil ichida
          // ko'milgan edi (2 bosish) va deyarli topilmasdi. Web'da esa u
          // boshidan pastki menyuda.
          NavigationDestination(
            icon: const SuzaniIconWidget(SuzaniIcon.parcel),
            selectedIcon: const SuzaniIconWidget(
              SuzaniIcon.parcel,
              filled: true,
            ),
            label: t.parcelsTitle,
          ),
          NavigationDestination(
            icon: Badge.count(
              count: unreadChats,
              isLabelVisible: unreadChats > 0,
              child: const SuzaniIconWidget(SuzaniIcon.chat),
            ),
            selectedIcon: Badge.count(
              count: unreadChats,
              isLabelVisible: unreadChats > 0,
              child: const SuzaniIconWidget(SuzaniIcon.chat, filled: true),
            ),
            label: t.chatsTitle,
          ),
          NavigationDestination(
            icon: const SuzaniIconWidget(SuzaniIcon.person),
            selectedIcon: const SuzaniIconWidget(
              SuzaniIcon.person,
              filled: true,
            ),
            label: t.profileTitle,
          ),
        ],
      )),
    );
  }

  /// Neon uslubда pastki navigatsiya USTIDAN cyan porlash chizig'i — "jonli"
  /// his. Klassikда o' zini qaytаради (hech qanday qo'shimcha qatlam).
  Widget _neonWrap(bool neon, Widget bar) {
    if (!neon) return bar;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: BrandColors.neonAqua.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: bar,
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'active_role.dart';
import '../data/models/chat.dart';
import '../data/models/ride.dart';
import '../features/auth/otp_screen.dart';
import '../features/billing/tariffs_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/chats_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/support/service_status_screen.dart';
import '../features/parcels/parcels_screen.dart';
import '../features/auth/phone_screen.dart';
import '../features/profile/driver_verification_screen.dart';
import '../features/profile/complete_profile_screen.dart';
import '../features/profile/security_screen.dart';
import '../features/profile/cars_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/profile/earnings_screen.dart';
import '../features/profile/user_profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/memory_card.dart';
import '../features/rides/create_ride_screen.dart';
import '../features/rides/driver_ride_screen.dart';
import '../features/rides/ride_details_screen.dart';
import '../features/search/search_results_screen.dart';
import '../features/search/search_screen.dart';
import '../features/trips/my_trips_screen.dart';
import '../features/intro/intro_screen.dart';
import 'home_shell.dart';
import 'providers.dart';
import '../core/motion.dart';

class Routes {
  static const intro = '/intro';
  static const login = '/login';
  static const otp = '/login/otp';

  /// Yangi hisob — ism/jins to'ldirilmaguncha ilova ichiga o'tkazilmaydi.
  static const onboarding = '/onboarding';
  static const search = '/search';
  static const searchResults = '/search/results';
  static const trips = '/trips';
  static const chats = '/chats';
  static const chat = '/chats/one';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const becomeDriver = '/profile/become-driver';
  static const editProfile = '/profile/edit';
  static const security = '/profile/security';
  static const cars = '/profile/cars';

  /// SOZLAMALAR — profildan ajratilgan (2026-09-02). Profil endi faqat
  /// kimligi haqida, boshqaruv esa shu yerda.
  static const settings = '/profile/settings';
  static const earnings = '/profile/earnings';
  static const memoryCard = '/profile/memory';

  /// Begona foydalanuvchi profili — `extra` orqali `(id, name)` uzatiladi.
  static const userProfile = '/profile/user';
  static const ride = '/ride';
  static const createRide = '/ride/create';
  static const driverRide = '/ride/driver';
  static const tariffs = '/tariffs';

  /// Xizmat holati — «nima ishlayapti» (izohi ekranning o'zida).
  static const serviceStatus = '/service-status';
  static const parcels = '/parcels';
}

/// Push ekranlar uchun BIR XIL brend o'tishi — o'ngdan yengil surilish +
/// fade. Reduce-motion'да o'tish YO'Q (izoh `AppMotion`). Tab (shell)
/// ekranlarига TEGILMAYDI — ular almashada, "kelmaydi".
CustomTransitionPage<void> _appPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondary, child) {
      if (!AppMotion.on(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    child: child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter Riverpod'ni bilmaydi — auth o'zgarganda redirect qayta hisoblanishi
  // uchun oddiy Listenable orqali turtki beramiz.
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.search,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final atLogin = location.startsWith(Routes.login);
      final atOnboarding = location == Routes.onboarding;
      final atIntro = location == Routes.intro;

      // BIRINCHI OCHILISH: tanishtiruv ko'rilmagan bo'lsa — faqat unga ruxsat.
      // Auth'dan OLDIN, chunki intro login'ni ham tanishtiradi. Bir marta
      // ko'rilib `intro_seen` saqlangach bu shart o'tib ketadi.
      final introSeen =
          ref.read(sharedPrefsProvider).getBool(IntroScreen.seenKey) ?? false;
      if (!introSeen) return atIntro ? null : Routes.intro;
      // Ko'rib bo'lgan odam intro'ga qaytmasin.
      if (atIntro) return auth.isAuthenticated ? Routes.search : Routes.login;

      if (!auth.isAuthenticated) return atLogin ? null : Routes.login;

      // Token bor, lekin profil bo'sh — faqat onboarding'ga ruxsat.
      if (auth.needsProfile) return atOnboarding ? null : Routes.onboarding;

      if (atLogin || atOnboarding) return Routes.search;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.editProfile,
        pageBuilder: (c, s) => _appPage(c, s, const EditProfileScreen()),
      ),
      GoRoute(
        path: Routes.security,
        pageBuilder: (c, s) => _appPage(c, s, const SecurityScreen()),
      ),
      GoRoute(
        path: Routes.cars,
        pageBuilder: (c, s) => _appPage(c, s, const CarsScreen()),
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (c, s) => _appPage(c, s, const SettingsScreen()),
      ),
      GoRoute(
        path: Routes.earnings,
        pageBuilder: (c, s) => _appPage(c, s, const EarningsScreen()),
      ),
      GoRoute(
        path: Routes.memoryCard,
        pageBuilder: (c, s) => _appPage(c, s, const MemoryScreen()),
      ),
      GoRoute(
        path: Routes.userProfile,
        pageBuilder: (c, s) {
          // `extra` — Map: id MAJBURIY, ism ixtiyoriy (sarlavha bo'sh
          // turmasin deb kartochkadan olib kelinadi).
          final extra = s.extra;
          final data = extra is Map<String, String?>
              ? extra
              : const <String, String?>{};
          return _appPage(
            c,
            s,
            UserProfileScreen(
              userId: data['id'] ?? '',
              fallbackName: data['name'],
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.intro,
        pageBuilder: (c, s) => _appPage(c, s, const IntroScreen()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (c, s) => _appPage(c, s, const PhoneScreen()),
      ),
      GoRoute(
        path: Routes.otp,
        // `new_device=1` — parol bilan kirishda backend qurilmani tanimay SMS
        // yuborgan holat (403 new_device). Ekran buni aytib berishi kerak, aks
        // holda odam kutilmagan SMS so'roviga tushunmaydi.
        pageBuilder: (c, state) => _appPage(
          c,
          state,
          OtpScreen(
            phoneNumber: state.extra as String? ?? '',
            newDevice: state.uri.queryParameters['new_device'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (c, s) => _appPage(c, s, const CompleteProfileScreen()),
      ),
      GoRoute(
        path: Routes.searchResults,
        pageBuilder: (c, s) => _appPage(c, s, const SearchResultsScreen()),
      ),
      GoRoute(
        path: Routes.becomeDriver,
        // 🔴 Eski BITTA SAHIFALI ekran o'rniga QADAMLI panel (egasi,
        // 2026-08-21): uchta hujjat, mashina va tasdiq bitta ekranga
        // tiqilsa u cheksiz uzun bo'lardi. Izohi
        // `DriverVerificationScreen` da.
        pageBuilder: (c, s) => _appPage(c, s, const DriverVerificationScreen()),
      ),
      GoRoute(
        path: Routes.createRide,
        // `extra` — namuna e'lon (ixtiyoriy):
        //   Ride                       -> QAYTISH safari (yo'nalish almashadi)
        //   {'repeat': Ride}           -> TAKRORLASH (yo'nalish o'sha qoladi)
        pageBuilder: (c, s) {
          final extra = s.extra;
          final repeat = extra is Map && extra['repeat'] is Ride
              ? extra['repeat'] as Ride
              : null;
          return _appPage(
            c,
            s,
            CreateRideScreen(
              returnOf: extra is Ride ? extra : null,
              repeatOf: repeat,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.driverRide,
        pageBuilder: (c, state) =>
            _appPage(c, state, DriverRideScreen(ride: state.extra as Ride)),
      ),
      GoRoute(
        path: Routes.ride,
        pageBuilder: (c, state) =>
            _appPage(c, state, RideDetailsScreen(ride: state.extra as Ride)),
      ),
      GoRoute(
        path: Routes.chat,
        pageBuilder: (c, state) => _appPage(
          c,
          state,
          ChatScreen(conversation: state.extra as Conversation),
        ),
      ),
      GoRoute(
        path: Routes.notifications,
        pageBuilder: (c, s) => _appPage(c, s, const NotificationsScreen()),
      ),
      GoRoute(
        path: Routes.serviceStatus,
        pageBuilder: (c, s) => _appPage(c, s, const ServiceStatusScreen()),
      ),
      GoRoute(
        // `extra: true` — paket tugagani sabab ochilgan paywall (sotib olingach
        // foydalanuvchi uzilgan ishiga qaytadi).
        path: Routes.tariffs,
        pageBuilder: (c, state) =>
            _appPage(c, state, TariffsScreen(paywall: state.extra == true)),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search,
                // Haydovchi rejimida bu band "E'lon berish" bo'ladi
                // (izohi `home_shell.dart` da).
                builder: (_, _) => Consumer(
                  builder: (_, ref, _) => ref.watch(isDriverModeProvider)
                      ? const CreateRideScreen()
                      : const SearchScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.trips,
                builder: (_, _) => const MyTripsScreen(),
              ),
            ],
          ),
          // ⚠️ TARTIB `home_shell.dart` dagi NavigationDestination tartibi bilan
          // AYNAN mos bo'lishi shart — `shell.currentIndex` shunga tayanadi.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.parcels,
                builder: (_, _) => const ParcelsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.chats,
                builder: (_, _) => const ChatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

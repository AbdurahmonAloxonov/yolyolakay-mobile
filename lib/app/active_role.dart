import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';

/// Foydalanuvchi HOZIR qaysi rolda ishlayapti.
///
/// Bitta odam ham yo'lovchi, ham haydovchi bo'lishi mumkin va ularning
/// ekranlari butunlay boshqacha. Saytda bu allaqachon bor edi
/// (`uiStore.activeRole`), ilovada esa YO'Q edi va natijada:
///
///   • haydovchi ilovani ochsa birinchi ekran "Safar qidirish" bo'lardi —
///     ya'ni unga yo'lovchining ishi ko'rsatilardi;
///   • "Safarlarim" doim "Yo'lovchi" yorlig'idan ochilardi, haydovchi har
///     safar qo'lda "Haydovchi" ga bosishi kerak edi.
///
/// Egasi qurilmada ko'rib aytdi (2026-08-13): «safar qidirish nima qilyapti
/// haydovchi bo'lsa? nega Safarlarimda yo'lovchi ko'rinadi? saytda qanday
/// bo'lsa ilovada ham shunday qil».
enum AppRole { passenger, driver }

/// Tanlov qurilmada saqlanadi — ilova qayta ochilganda esda qoladi.
const _prefsKey = 'active_role';

class ActiveRoleNotifier extends StateNotifier<AppRole> {
  ActiveRoleNotifier(this._prefs, AppRole initial) : super(initial);

  final SharedPreferences _prefs;

  void set(AppRole role) {
    state = role;
    _prefs.setString(_prefsKey, role.name);
  }
}

/// Joriy rol.
///
/// Boshlang'ich qiymat: saqlangani bo'lsa — o'sha, aks holda haydovchiga
/// `driver`, qolganlarga `passenger`. Saytda standart qiymat doim
/// `passenger` edi, lekin aynan shu narsa haydovchini yo'lovchi ekraniga
/// olib tushardi — ilovada haydovchi O'Z ishidan boshlaydi.
final activeRoleProvider = StateNotifierProvider<ActiveRoleNotifier, AppRole>((
  ref,
) {
  final prefs = ref.watch(sharedPrefsProvider);
  final saved = prefs.getString(_prefsKey);

  // Haydovchi emasligi aniq bo'lsa saqlangan `driver` ni ham e'tiborsiz
  // qoldiramiz: haydovchilikdan chiqarilgan odam bo'sh ekranlarda qolmasin.
  final isDriver = ref.watch(meProvider).valueOrNull?.user.isDriver ?? false;
  if (!isDriver) return ActiveRoleNotifier(prefs, AppRole.passenger);

  final initial = switch (saved) {
    'passenger' => AppRole.passenger,
    'driver' => AppRole.driver,
    _ => AppRole.driver,
  };
  return ActiveRoleNotifier(prefs, initial);
});

/// Qisqartma — `ref.watch(activeRoleProvider) == AppRole.driver` o'rniga.
final isDriverModeProvider = Provider<bool>(
  (ref) => ref.watch(activeRoleProvider) == AppRole.driver,
);

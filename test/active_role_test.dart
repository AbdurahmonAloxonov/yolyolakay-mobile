import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/app/active_role.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/user.dart';

/// ROL — ilova kimning ishini ko'rsatadi.
///
/// Egasi qurilmada ko'rdi (2026-08-13): «safar qidirish nima qilyapti
/// haydovchi bo'lsa? nega Safarlarimda yo'lovchi ko'rinadi?». Saytda rol
/// tushunchasi bor edi (`uiStore.activeRole`), ilovada esa yo'q — haydovchi
/// doim yo'lovchi ekranlaridan boshlardi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> boot({
    required bool isDriver,
    String? saved,
  }) async {
    SharedPreferences.setMockInitialValues(
      saved == null ? {} : {'active_role': saved},
    );
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        meProvider.overrideWith(
          (ref) async => MeResponse(
            user: User(
              id: 'u-1',
              phoneNumber: '+998900000000',
              firstName: 'Aziz',
              role: isDriver ? 'driver' : 'passenger',
            ),
            cars: const [],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // `meProvider` — asinxron, rol undan aniqlanadi.
    await container.read(meProvider.future);
    return container;
  }

  test('haydovchi O\'Z rejimidan boshlaydi', () async {
    final c = await boot(isDriver: true);
    expect(c.read(activeRoleProvider), AppRole.driver);
    expect(c.read(isDriverModeProvider), isTrue);
  });

  test('yo\'lovchi — yo\'lovchi rejimida', () async {
    final c = await boot(isDriver: false);
    expect(c.read(activeRoleProvider), AppRole.passenger);
  });

  test(
    'haydovchi yo\'lovchi rejimiga o\'ta oladi va tanlov SAQLANADI',
    () async {
      final c = await boot(isDriver: true);
      c.read(activeRoleProvider.notifier).set(AppRole.passenger);
      expect(c.read(activeRoleProvider), AppRole.passenger);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('active_role'), 'passenger');

      // Ilova qayta ochilganda o'sha rol tiklanadi.
      final again = await boot(isDriver: true, saved: 'passenger');
      expect(again.read(activeRoleProvider), AppRole.passenger);
    },
  );

  /// 🔴 QOIDA (egasi, 2026-08-13: «rolni almashtirsam faqat qidirish va
  /// e'lon berish almashyapti, qolgan narsalar ko'rinib turibdi — logika
  /// jihatdan bu katta xato»).
  ///
  /// Rol EKRAN MAZMUNINI belgilaydi. Bu sinov manba kodini tekshiradi:
  /// haydovchiga tegishli bo'limlar rolga bog'lanmay qolsa, darhol
  /// bilinadi.
  test('haydovchining bo\'limlari ROLGA bog\'langan', () {
    // ⚠️ BO'LIM IKKI MARTA KO'CHDI, QOIDA esa O'ZGARMADI:
    //   • 2026-09-02: profildan SOZLAMALARGA («profilga hamma narsa
    //     tiqilib ketgan»);
    //   • 2026-09-18: sozlamalardan yana PROFILGA, o'z faylida
    //     (`my_stuff_section.dart`) — egasi: «sozlamalarda turishi
    //     g'alati ekan».
    // Sinov shu sabab EKRANGA emas, BO'LIMNING o'ziga qaraydi.
    final profile = File(
      'lib/features/profile/my_stuff_section.dart',
    ).readAsStringSync();
    // Mashina va daromad `driverMode` shartida turishi kerak.
    expect(
      profile.contains('if (driverMode) ...['),
      isTrue,
      reason: 'profil bo\'limlari rolga bog\'lanmagan',
    );
    // Tariflar HAMMAGA ko'rinishi `profile_sections_test.dart` da
    // vidjet darajasida tekshiriladi (manba matnini o'qish bu yerda
    // mo'rt bo'lib chiqdi).

    final trips = File(
      'lib/features/trips/my_trips_screen.dart',
    ).readAsStringSync();
    // Yo'lovchi rejimida haydovchi ro'yxati ham, e'lon tugmasi ham yo'q.
    expect(
      trips.contains('floatingActionButton:'),
      isFalse,
      reason: 'e\'lon berish tugmasi yo\'lovchi ekranida qaytib paydo bo\'ldi',
    );
    expect(trips.contains('driverMode ? const _DriverRidesTab()'), isTrue);

    final parcels = File(
      'lib/features/parcels/parcels_screen.dart',
    ).readAsStringSync();
    expect(parcels.contains('driverMode'), isTrue);
  });

  test('haydovchi EMASGA saqlangan "driver" ta\'sir qilmaydi', () async {
    // Haydovchilikdan chiqarilgan odam bo'sh haydovchi ekranlarida qolmasin.
    final c = await boot(isDriver: false, saved: 'driver');
    expect(c.read(activeRoleProvider), AppRole.passenger);
  });
}

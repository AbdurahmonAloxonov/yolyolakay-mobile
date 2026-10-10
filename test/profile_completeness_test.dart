import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/features/profile/profile_completeness.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// PROFIL TO'LIQLIGI.
///
/// 🔴 NEGA TEST: karta odamni ISHGA chorlaydi. Ikkita xato uni zararga
/// aylantiradi:
///   • to'liq profilda ham ko'rinishi — har kuni bajarilgan ishni
///     ko'rsatib turish shovqin va odam kartani butunlay o'qimay
///     qo'yadi;
///   • yo'lovchidan MASHINA so'rashi — u haydovchi emas, bu bandni
///     hech qachon bajara olmaydi va foiz abadiy to'lmaydi.
void main() {
  const t = AppStrings(Lang.uz);

  User user({
    String? avatar,
    String? lastName = 'Karimov',
    String role = 'passenger',
  }) => User(
    id: 'u-1',
    phoneNumber: '+998900000000',
    firstName: 'Aziz',
    lastName: lastName,
    role: role,
    avatarUrl: avatar,
  );

  Widget boot(User u, {bool hasCar = false}) => MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: ProfileCompleteness(
        user: u,
        hasCar: hasCar,
        onAvatar: () {},
        onName: () {},
        onCar: () {},
      ),
    ),
  );

  testWidgets('surat yo\'q — taklif chiqadi, SABABI bilan', (tester) async {
    await tester.pumpWidget(boot(user()));
    await tester.pumpAndSettle();

    expect(find.text(t.completenessAvatar), findsOneWidget);
    // Sabab bandning o'zidan muhimroq: usiz bu shunchaki buyruq.
    expect(find.text(t.completenessAvatarWhy), findsOneWidget);
  });

  testWidgets('to\'liq profilda karta UMUMAN chizilmaydi', (tester) async {
    await tester.pumpWidget(boot(user(avatar: 'https://x/a.png')));
    await tester.pumpAndSettle();

    expect(find.text(t.completenessTitle), findsNothing);
  });

  /// Yo'lovchi mashina qo'sha olmaydi — bu bandni ko'rsatish uni
  /// abadiy «to'liqmas» qilib qo'yardi.
  testWidgets('yo\'lovchidan MASHINA so\'ralmaydi', (tester) async {
    await tester.pumpWidget(boot(user()));
    await tester.pumpAndSettle();

    expect(find.text(t.completenessCar), findsNothing);
  });

  testWidgets('haydovchida mashina bandi bor', (tester) async {
    await tester.pumpWidget(boot(user(role: 'driver')));
    await tester.pumpAndSettle();

    expect(find.text(t.completenessCar), findsOneWidget);
  });

  testWidgets('haydovchida mashina bo\'lsa — o\'sha band yo\'q', (
    tester,
  ) async {
    await tester.pumpWidget(
      boot(user(role: 'driver', avatar: 'https://x/a.png'), hasCar: true),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.completenessTitle), findsNothing);
  });

  testWidgets('hisob to\'g\'ri: yo\'lovchida 2 tadan', (tester) async {
    await tester.pumpWidget(boot(user(lastName: '')));
    await tester.pumpAndSettle();

    // Surat ham, familiya ham yo'q -> 0/2.
    expect(find.text('0/2'), findsOneWidget);
  });
}

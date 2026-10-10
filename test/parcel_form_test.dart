import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/parcels/create_parcel_screen.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// Posilka berish formasi — "Yuborish" tugmasining joyi.
void main() {
  const t = AppStrings(Lang.uz);

  /// Haqiqiy telefon o'lchami (Galaxy M13 ≈ 360x780 mantiqiy piksel).
  /// Standart 800x600 sinov ekrani bu muammoni YASHIRARDI.
  Future<void> pumpForm(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: CreateParcelView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('"Yuborish" AYLANTIRMASDAN ko\'rinadi', (tester) async {
    await pumpForm(tester);

    // Ilgari tugma formaning eng oxirida — narx va qabul qiluvchi raqamidan
    // keyin — turardi va telefon ekraniga umuman sig'masdi.
    expect(find.text(t.sendParcel), findsOneWidget);
    expect(tester.getBottomLeft(find.text(t.sendParcel)).dy, lessThan(780));
  });

  testWidgets('forma aylantirilganda ham tugma joyida qoladi', (tester) async {
    await pumpForm(tester);

    final before = tester.getTopLeft(find.text(t.sendParcel));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text(t.sendParcel)), before);
  });
}

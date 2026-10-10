import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/features/rides/journey_view.dart';

/// JONLI YO'L TASMASI — bosib o'tilgan qism.
///
/// 🔴 NEGA TEST: tasma «qayerda ekanmiz» degan savolga javob beradi va
/// odam unga ISHONADI. Noto'g'ri to'lgan chiziq yolg'on ma'lumot — u
/// «yetib qolyapmiz» deb ko'rsatib, aslida yo'lning boshida bo'lishi
/// mumkin. Shu sabab chegaralar qat'iy tekshiriladi.
void main() {
  Widget boot({double? progress}) => MaterialApp(
    home: Scaffold(
      body: JourneyLine(
        origin: 'Toshkent',
        destination: 'Samarqand',
        progress: progress,
      ),
    ),
  );

  testWidgets('progress berilmasa chiziq to\'lmaydi', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pumpAndSettle();

    expect(find.byType(FractionallySizedBox), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress berilsa chiziq to\'ladi', (tester) async {
    await tester.pumpWidget(boot(progress: 0.5));
    await tester.pumpAndSettle();

    final box = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(box.heightFactor, 0.5);
    // Yuqoridan pastga — safar jo'nash nuqtasidan boshlanadi.
    expect(box.alignment, Alignment.topCenter);
  });

  /// Chegaradan tashqaridagi qiymat `FractionallySizedBox` ni tashlaydi
  /// (`heightFactor` manfiy bo'lolmaydi) — ya'ni bu ilova yiqilishi.
  testWidgets('chegaradan tashqari qiymat qirqiladi', (tester) async {
    for (final value in [-0.5, 1.8, 42.0]) {
      await tester.pumpWidget(boot(progress: value));
      await tester.pumpAndSettle();

      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(box.heightFactor, inInclusiveRange(0.0, 1.0));
      expect(tester.takeException(), isNull);
    }
  });
}

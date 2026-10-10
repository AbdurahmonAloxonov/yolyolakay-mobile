import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/providers.dart';
import 'package:yolyolakay/data/models/rating.dart';
import 'package:yolyolakay/features/profile/reviews_section.dart';
import 'package:yolyolakay/l10n/strings.dart';

/// SHARHLAR RO'YXATI.
///
/// 🔴 NEGA TEST: bu ro'yxat boshqa odam haqida YOZILGAN GAPNI ko'rsatadi.
/// Noto'g'ri muallif yoki noto'g'ri yulduz — birovga tegishli fikrni
/// boshqasiga yopishtirish demak.
void main() {
  const t = AppStrings(Lang.uz);

  FeedbackItem item({
    String id = 'f-1',
    int score = 5,
    String? comment = 'Vaqtida keldi',
    String? name = 'Ali',
  }) => FeedbackItem(
    id: id,
    score: score,
    comment: comment,
    reviewerName: name,
    createdAt: DateTime(2026, 8, 20),
  );

  Future<void> pump(
    WidgetTester tester,
    FeedbackList? list, {
    Object? error,
    int limit = 3,
  }) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userFeedbackProvider.overrideWith((ref, id) async {
            if (error != null) throw error;
            return list ?? const FeedbackList();
          }),
        ],
        child: MaterialApp(
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReviewsSection(userId: 'u-1', limit: limit),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sharh matni va muallifi ko\'rinadi', (tester) async {
    await pump(
      tester,
      FeedbackList(items: [item()], total: 1, average: 5),
    );
    expect(find.text('Vaqtida keldi'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
  });

  /// 🔴 Yulduzlar SONI baholash bilan mos kelishi shart — 3 ball 5 ta
  /// to'la yulduz bo'lib chizilsa, bu boshqa odamning fikrini
  /// BUZIB ko'rsatish bo'ladi.
  testWidgets('yulduzlar bahoga MOS chiziladi', (tester) async {
    await pump(
      tester,
      FeedbackList(items: [item(score: 3)], total: 1, average: 3),
    );
    final icons = tester
        .widgetList<Icon>(find.byType(Icon))
        .where((i) => i.icon == Icons.star || i.icon == Icons.star_border)
        .toList();
    expect(icons.where((i) => i.icon == Icons.star).length, 3);
    expect(icons.where((i) => i.icon == Icons.star_border).length, 2);
  });

  /// 🔴 Bo'sh holat AYBLOV emas: yangi odamda sharh bo'lmasligi tabiiy.
  testWidgets('sharh yo\'q bo\'lsa SABABI aytiladi', (tester) async {
    await pump(tester, const FeedbackList());
    expect(find.text(t.reviewsEmpty), findsOneWidget);
  });

  /// Matnsiz baholar ro'yxatni suyultiradi — odam bu yerga GAPNI
  /// o'qigani keladi, raqamni emas.
  testWidgets('matnsiz baho ro\'yxatga TUSHMAYDI', (tester) async {
    await pump(
      tester,
      FeedbackList(
        items: [item(comment: null), item(id: 'f-2', comment: '')],
        total: 2,
        average: 5,
      ),
    );
    expect(find.text(t.reviewsEmpty), findsOneWidget);
  });

  testWidgets('limitdan ortig\'i «Yana N ta» ostida', (tester) async {
    await pump(
      tester,
      FeedbackList(
        items: [
          item(id: 'a'),
          item(id: 'b'),
          item(id: 'c'),
          item(id: 'd'),
          item(id: 'e'),
        ],
        total: 5,
        average: 5,
      ),
      limit: 2,
    );
    expect(find.text(t.reviewsMore(3)), findsOneWidget);
  });

  /// ⚠️ Sharhlar uzilsa profilning QOLGAN qismi ishlashi kerak —
  /// butun ekranni xato holatiga o'tkazish nomutanosib bo'lardi.
  testWidgets('uzilishda JIM qoladi, xato ko\'rsatmaydi', (tester) async {
    await pump(tester, null, error: Exception('tarmoq'));
    expect(find.text(t.reviewsTitle), findsNothing);
    expect(find.textContaining('rror'), findsNothing);
  });

  testWidgets('muallif ismsiz bo\'lsa sharh baribir ko\'rinadi', (
    tester,
  ) async {
    await pump(
      tester,
      FeedbackList(items: [item(name: null)], total: 1, average: 5),
    );
    expect(find.text('Vaqtida keldi'), findsOneWidget);
    expect(find.text(t.reviewAuthorUnknown), findsOneWidget);
  });

  testWidgets('bo\'sh id bilan hech nima chizilmaydi', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('uz'),
          supportedLocales: [Locale('uz')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: ReviewsSection(userId: '')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.reviewsTitle), findsNothing);
  });
}

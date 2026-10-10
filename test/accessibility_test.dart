import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/core/motion.dart';

/// EKRAN O'QUVCHISI (TalkBack / VoiceOver) QO'RIQCHISI.
///
/// 🔴 NEGA YOZILDI (2026-08-25 auditi): butun ilovada `Semantics` atigi
/// BIR marta ishlatilgan edi. Ikkita oqibati bor edi:
///
///   1. ikonkali tugmalar (yozuvsiz) shunchaki "tugma" deb o'qilardi —
///      qaysi tugma ekani noma'lum;
///   2. bosiladigan kartalar `GestureDetector` ichida edi va TalkBack
///      ularni BOSILADIGAN deb bildirmasdi — odam safar kartochkasini
///      eshitadi-yu, uni ochish mumkinligini bilmaydi.
///
/// Bu testlar ikkalasini ham qaytib kelishidan saqlaydi. Ular UI ni
/// "chiroyli" qilmaydi — ular ilovadan foydalana oladigan odamlar sonini
/// belgilaydi.
void main() {
  /// Chaqiruvning qavs ichidagi to'liq matnini qaytaradi.
  String callBody(String src, int openParenIndex) {
    var depth = 0;
    for (var i = openParenIndex; i < src.length; i++) {
      if (src[i] == '(') depth++;
      if (src[i] == ')') {
        depth--;
        if (depth == 0) return src.substring(openParenIndex + 1, i);
      }
    }
    return '';
  }

  test('har bir IconButton da tooltip bor', () {
    final violations = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final src = file.readAsStringSync();
      // ⚠️ `IconButton.styleFrom(` — TUGMA EMAS, uslub yasagich.
      // U ham `IconButton.` bilan boshlanadi va qorovul uni tugma deb
      // o'ylab, yolg'on xato berardi (2026-09-02 da ushlandi).
      for (final m in RegExp(
        r'\bIconButton(?:\.(?!styleFrom\b)\w+)?\(',
      ).allMatches(src)) {
        final body = callBody(src, m.end - 1);
        if (body.contains('tooltip:')) continue;
        final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
        violations.add('${file.path}:$line');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Ikonkali tugmada KO\'RINADIGAN yozuv yo\'q. `tooltip:` bo\'lmasa '
          'TalkBack uni shunchaki "tugma" deb o\'qiydi va ko\'zi ojiz odam '
          'nima bosayotganini bilmaydi. Qo\'shing:\n${violations.join('\n')}',
    );
  });

  /// `PressableScale` ilovadagi deyarli hamma bosiladigan karta va
  /// avatarni o'raydi. Undagi bitta qator o'nlab ekranni yopadi —
  /// shuning uchun uni alohida qo'riqlaymiz.
  testWidgets('PressableScale TUGMA deb e\'lon qilinadi', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PressableScale(
            onTap: () {},
            child: const Text('Toshkent — Samarqand'),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('Toshkent — Samarqand')),
      matchesSemantics(
        label: 'Toshkent — Samarqand',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('matnsiz PressableScale yorliq oladi', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PressableScale(
            onTap: () {},
            semanticLabel: 'Suratni o\'zgartirish',
            child: const Icon(Icons.photo_camera),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Suratni o\'zgartirish'),
      findsOneWidget,
      reason:
          'Ichida matn bo\'lmagan bosiladigan element yorliqsiz qolsa, '
          'ekran o\'quvchisi faqat "tugma" deydi.',
    );
    handle.dispose();
  });

  /// O'CHIQ TUGMADAGI YOZUV O'QILSIN.
  ///
  /// 🔴 NEGA (2026-09-02 ko'rigi): o'chiq tugma brend rangining 40% i
  /// bo'lib, yozuvi `white70` edi. O'lchandi:
  ///     classic yorug' 1.62 : 1 · neon yorug' 1.54 : 1 · amber 1.21 : 1
  /// WCAG talabi — 4.5 : 1. Ya'ni tugmada nima yozilgani KO'RINMASDI,
  /// ustiga-ustak to'q pushti fon uni YONIQ ko'rsatardi va odam bosardi.
  ///
  /// 🔑 Bu xatoni ko'z bilan ham, `flutter analyze` bilan ham topib
  /// bo'lmaydi — faqat o'lchov ko'rsatadi.
  group('o\'chiq tugma o\'qiladi', () {
    double luminance(Color c) => c.computeLuminance();
    double contrast(Color a, Color b) {
      final la = luminance(a);
      final lb = luminance(b);
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final style in ThemeStyle.values) {
      for (final brightness in Brightness.values) {
        test('${style.name} · ${brightness.name}', () {
          final theme = buildTheme(brightness: brightness, style: style);
          final button = theme.filledButtonTheme.style!;
          final bg = button.backgroundColor!.resolve({WidgetState.disabled})!;
          final fg = button.foregroundColor!.resolve({WidgetState.disabled})!;

          expect(
            contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason:
                'o\'chiq tugmadagi yozuv o\'qilmaydi: '
                '${contrast(fg, bg).toStringAsFixed(2)} : 1',
          );

          // Fon BREND rangida bo'lmasin — aks holda tugma yoniqdek
          // ko'rinadi va odam uni bosaveradi.
          final accent = theme.colorScheme.primary;
          expect(
            contrast(bg, accent),
            greaterThan(1.5),
            reason: 'o\'chiq tugma brend rangiga juda yaqin — yoniqdek',
          );
        });
      }
    }
  });

  /// YONIQ TUGMA VA AKSENT YOZUV HAM O'QILSIN.
  ///
  /// 🔴 NEGA QO'SHILDI (2026-09-04): saytda o'sha kuni o'lchov qilindi va
  /// brend pushtisining O'ZI chegaradan past chiqdi — zaminida oq yozuv
  /// 4.18 : 1, pushti yozuv oq qog'ozda 3.85 : 1. Ya'ni nuqson o'chiq
  /// tugmada emas, ENG KO'P ISHLATILADIGAN holatda edi va uni hech qanday
  /// test tutmasdi: yuqoridagi guruh faqat O'CHIQ tugmani o'lchardi.
  ///
  /// 🔑 AKSENTNING IKKI ROLI: zamin (ustida `onPrimary`) va yozuvning
  /// o'zi (sirt/fon ustida). Bitta rang ikkalasini ham bajara olmaydi —
  /// shuning uchun yorug' temada aksent to'q + oq yozuv, to'q temada
  /// aksent och + qora yozuv (`BrandColors.pinkInk`).
  group('yoniq tugma va aksent yozuv o\'qiladi', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final style in ThemeStyle.values) {
      for (final brightness in Brightness.values) {
        test('${style.name} · ${brightness.name}', () {
          final theme = buildTheme(brightness: brightness, style: style);
          final cs = theme.colorScheme;

          void check(String what, Color fg, Color bg) {
            expect(
              contrast(fg, bg),
              greaterThanOrEqualTo(4.5),
              reason:
                  '$what: ${contrast(fg, bg).toStringAsFixed(2)} : 1 '
                  '(WCAG AA — 4.5 : 1)',
            );
          }

          check('tugmadagi yozuv', cs.onPrimary, cs.primary);
          check('aksent yozuv kartada', cs.primary, cs.surface);
          check('aksent yozuv fonda', cs.primary, theme.scaffoldBackgroundColor);
        });
      }
    }
  });
}

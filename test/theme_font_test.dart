import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';

/// TEMADAGI SHRIFT HAQIQATAN INTER'MI.
///
/// 🔴 NEGA YOZILDI (10.09.2026): `ThemeData(fontFamily: kUiFont, ...)`
/// yozilgan edi va hamma ishonardiki ilova Inter'da chiziladi. Aslida
/// EMAS: yonidagi `textTheme` `ThemeData.light().textTheme` dan
/// ko'chirilgan va uning har bir uslubida `fontFamily: 'Roboto'`
/// oshkora turgan; `ThemeData` esa foydalanuvchi `textTheme` sini
/// `fontFamily` QO'LLANGANDAN KEYIN merge qiladi. Natijada Inter
/// jimgina Roboto bilan almashardi.
///
/// Buni na `flutter analyze`, na ko'rinish testlari tutadi: Roboto ham
/// kirillni chizadi, ekran «to'g'ridek» ko'rinadi. Yagona ishonchli
/// tekshiruv — shu yerdagidek, oilaning NOMINI so'rash.
void main() {
  for (final brightness in Brightness.values) {
    test('${brightness.name} tema — hamma uslub $kUiFont da', () {
      final theme = buildTheme(brightness: brightness);
      final styles = <String, TextStyle?>{
        'displayLarge': theme.textTheme.displayLarge,
        'displaySmall': theme.textTheme.displaySmall,
        'headlineMedium': theme.textTheme.headlineMedium,
        'headlineSmall': theme.textTheme.headlineSmall,
        'titleLarge': theme.textTheme.titleLarge,
        'titleMedium': theme.textTheme.titleMedium,
        'titleSmall': theme.textTheme.titleSmall,
        'bodyLarge': theme.textTheme.bodyLarge,
        'bodyMedium': theme.textTheme.bodyMedium,
        'bodySmall': theme.textTheme.bodySmall,
        'labelLarge': theme.textTheme.labelLarge,
        'labelMedium': theme.textTheme.labelMedium,
        'labelSmall': theme.textTheme.labelSmall,
      };
      final wrong = styles.entries
          .where((e) => e.value != null && e.value!.fontFamily != kUiFont)
          .map((e) => '${e.key} → ${e.value!.fontFamily}')
          .toList();
      expect(
        wrong,
        isEmpty,
        reason:
            'Bu uslublar $kUiFont da EMAS. Sabab odatda bitta: `textTheme` '
            'ga berilgan shkala `ThemeData.light()/dark()` dan ko\'chirilgan '
            'va Roboto\'ni o\'zi bilan olib kelgan. Yechim — shkalaga '
            '`.apply(fontFamily: kUiFont)`.',
      );
    });
  }

  /// 🔴 KOMPONENT TEMALARI HAM (10.09.2026, ko'z bilan ko'rildi).
  ///
  /// `styleFrom` ga yoki komponent temasiga berilgan YALANG'OCH
  /// `TextStyle` merosni ALMASHTIRADI — `textTheme` to'g'ri bo'lsa ham
  /// o'sha komponent TIZIM shriftiga tushib ketadi. Kirish ekranining
  /// suratida bu ochiq ko'rindi: butun ekran bir shriftda, «Kod
  /// yuborish» tugmasi esa boshqa shriftda edi.
  test('komponent temalari ham $kUiFont da', () {
    for (final brightness in Brightness.values) {
      final theme = buildTheme(brightness: brightness);
      final styles = <String, TextStyle?>{
        'appBar.title': theme.appBarTheme.titleTextStyle,
        'filledButton': theme.filledButtonTheme.style?.textStyle
            ?.resolve(<WidgetState>{}),
        'snackBar.content': theme.snackBarTheme.contentTextStyle,
        'chip.label': theme.chipTheme.labelStyle,
      };
      final wrong = styles.entries
          .where((e) => e.value != null && e.value!.fontFamily != kUiFont)
          .map((e) => '${brightness.name}/${e.key} → ${e.value!.fontFamily}')
          .toList();
      expect(
        wrong,
        isEmpty,
        reason:
            'Bu komponentlar $kUiFont da EMAS — ekranda ular ilovaning '
            'qolgan qismidan BOSHQA shriftda chiziladi.',
      );
    }
  });
}

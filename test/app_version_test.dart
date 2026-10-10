import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/core/env.dart';

/// `Env.appVersion` `pubspec.yaml` bilan mos turadimi.
///
/// 🔴 NEGA: versiya qo'llab-quvvatlash murojaatiga qo'shiladi — operator
/// "qaysi versiyada shunday bo'ldi?" degan savolga javob topishi kerak.
/// Qo'lda yozilgan satr esa eskirishi ANIQ: reliz oldidan `pubspec` da
/// raqam oshiriladi, bu yer esa esdan chiqadi. Natijada murojaatlarda
/// eski versiya ko'rinib, xato noto'g'ri joyda qidiriladi.
void main() {
  test('Env.appVersion pubspec bilan bir xil', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final line = pubspec.firstWhere((l) => l.startsWith('version:'));
    final version = line.split(':')[1].trim();

    expect(
      Env.appVersion,
      version,
      reason:
          'pubspec.yaml da versiya $version, `Env.appVersion` da esa '
          '${Env.appVersion}. Ikkalasini birga yangilang.',
    );
  });
}

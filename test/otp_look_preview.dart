// VAQTINCHALIK — yangi OTP maydonini KO'Z BILAN ko'rish uchun.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolyolakay/app/theme.dart';
import 'package:yolyolakay/features/auth/otp_code_field.dart';

import 'support/preview_fonts.dart';

void main() {
  setUpAll(loadPreviewFonts);

  Future<void> shoot(
    WidgetTester t,
    String name, {
    required String code,
    bool error = false,
    bool confirmed = false,
    Brightness brightness = Brightness.light,
  }) async {
    final c = TextEditingController(text: code);
    await t.pumpWidget(
      MaterialApp(
        theme: withPreviewFont(buildTheme(brightness: brightness)),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: OtpCodeField(
                controller: c,
                error: error,
                confirmed: confirmed,
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 25; i++) {
      await t.pump(const Duration(milliseconds: 120));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../style_preview/otp/$name.png'),
    );
  }

  testWidgets('bo\'sh', (t) => shoot(t, 'otp_1_bosh', code: ''));
  testWidgets('yarim', (t) => shoot(t, 'otp_2_yarim', code: '123'));
  testWidgets('to\'liq', (t) => shoot(t, 'otp_3_toliq', code: '12345'));
  testWidgets(
    'tasdiq — yashil',
    (t) => shoot(t, 'otp_4_yashil', code: '12345', confirmed: true),
  );
  testWidgets(
    'xato',
    (t) => shoot(t, 'otp_5_xato', code: '12345', error: true),
  );
  testWidgets(
    'tasdiq — tungi',
    (t) => shoot(
      t,
      'otp_6_yashil_tungi',
      code: '12345',
      confirmed: true,
      brightness: Brightness.dark,
    ),
  );
}

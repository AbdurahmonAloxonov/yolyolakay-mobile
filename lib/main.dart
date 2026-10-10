import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/api/token_storage.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tokenlar va sozlamalar birinchi kadrdan OLDIN yuklanadi — aks holda ilova
  // bir lahza login ekranini ko'rsatib, keyin ichkariga sakraydi.
  final tokens = TokenStorage();
  await tokens.load();
  final prefs = await SharedPreferences.getInstance();

  final app = ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(tokens),
      sharedPrefsProvider.overrideWithValue(prefs),
    ],
    child: const YolYolakayApp(),
  );

  /*
   * SENTRY — qurilmadagi yiqilishlarni ko'rish (izohi `Env.sentryDsn` da).
   *
   * DSN berilmagan bo'lsa ilova ODDIY ishga tushadi: monitoring
   * IXTIYORIY, uning yo'qligi ilovani to'xtatmasligi kerak (lokal
   * yig'ishda ham `--dart-define` yozib o'tirmaymiz).
   */
  if (Env.sentryDsn.isEmpty) {
    runApp(app);
    return;
  }

  await SentryFlutter.init((options) {
    options.dsn = Env.sentryDsn;
    // Versiya bo'yicha ajratish: "qaysi relizda paydo bo'ldi?" degan
    // savol eng birinchi so'raladi.
    options.release = 'uz.yolyolakay.mobile@${Env.appVersion}';
    // 🔴 Tracing YOQILMAYDI (`tracesSampleRate` 0): u har ekran o'tishida
    // tarmoqqa ma'lumot yuboradi va O'zbekistonda trafik qimmat. Bizga
    // kerak bo'lgani — YIQILISHLAR, tezlik o'lchovi emas.
    options.tracesSampleRate = 0;
    // Ekran suratlari ham, ekran nomlari ham YUBORILMAYDI: ularda chat
    // matni va telefon raqami bo'lishi mumkin.
    options.attachScreenshot = false;
    options.sendDefaultPii = false;
  }, appRunner: () => runApp(app));
}

import 'package:flutter/material.dart';

import '../../../app/dimens.dart';
import '../../../app/theme.dart';
import '../../../l10n/strings.dart';
import 'ornament.dart';

/// Ilova ochilishidagi yuklanish ekrani — BREND NOMI bilan.
///
/// NEGA KERAK: tizim splash'i (`flutter_native_splash`) faqat logotipni
/// ko'rsatadi va Flutter dvigateli tayyor bo'lishi bilan YO'QOLADI. Undan
/// keyin ilova ma'lumot yuklayotgan bo'lsa, odam bo'sh yoki yarim to'lgan
/// ekranga tushib qolardi — ilova "sekin" emas, "buzuq" bo'lib tuyulardi.
///
/// Bu ekran o'sha oraliqni to'ldiradi va brendni ko'rsatadi: tizim splash'i
/// bilan bir xil fon, bir xil markaz — ya'ni ikkalasi bitta ekranning davomi
/// bo'lib ko'rinadi, "sakrash" sezilmaydi.
class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Tizim splash'idagi ranglar bilan AYNAN bir xil (`pubspec.yaml` dagi
      // `flutter_native_splash.color` / `color_dark`) — aks holda o'tish
      // paytida fon "chaqnab" ketadi.
      backgroundColor: isDark ? const Color(0xFF141114) : Colors.white,
      body: Stack(
        children: [
          // Ochilish ekrani — GANCH relyefi: rangsiz, faqat yorug'lik
          // o'yini. Bu yerda naqsh ko'zga tashlanmasligi kerak, chunki
          // ekran bir soniya ko'rinadi va undan keyin login keladi.
          const Positioned.fill(child: GanchPattern(cell: 118, depth: 0.5)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brend nomi LOTIN — Fraunces (kirill unda yo'q, theme.dart).
                Text(
                  t.appName,
                  style: displayFontStyle(theme.textTheme.displaySmall)
                      .copyWith(
                        fontWeight: FontWeight.w700,
                        color: BrandColors.pink,
                      ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  t.splashTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
                const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: BrandColors.pink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

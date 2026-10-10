import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/env.dart';
import '../../l10n/strings.dart';

/// «NIMA YANGILANDI?» — yangilanishdan keyin bir marta ko'rsatiladi.
///
/// 🔴 NEGA KERAK: ilova ichida yangilanish (`in_app_update`) allaqachon bor,
/// ya'ni odam yangi versiyani oladi — lekin NIMA o'zgarganini bilmaydi.
/// Biz oylab funksiya qo'shamiz, foydalanuvchi esa ularni tasodifan
/// topadi yoki umuman topmaydi.
///
/// ⚠️ FAQAT BIR MARTA: ko'rilgan versiya xotirada saqlanadi. Har ochilishda
/// chiqadigan oyna — reklama, funksiya emas.
///
/// ⚠️ Birinchi o'rnatishda CHIQMAYDI: yangi odamga "nima yangilandi"
/// degan ro'yxat hech nima aytmaydi, u hali eskisini ko'rmagan.
class WhatsNew {
  const WhatsNew(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'whats_new_seen_version';

  /// Shu versiya uchun oyna ko'rsatilishi kerakmi.
  bool shouldShow() {
    final seen = _prefs.getString(_key);
    // Birinchi ishga tushirish — belgilab qo'yamiz va ko'rsatmaymiz.
    if (seen == null) {
      _prefs.setString(_key, Env.appVersion);
      return false;
    }
    return seen != Env.appVersion;
  }

  Future<void> markSeen() => _prefs.setString(_key, Env.appVersion);
}

final whatsNewProvider = Provider<WhatsNew>(
  (ref) => WhatsNew(ref.watch(sharedPrefsProvider)),
);

/// Yangiliklar varag'i — ro'yxat `AppStrings.whatsNewItems` da.
Future<void> showWhatsNew(BuildContext context, WidgetRef ref) async {
  final t = AppStrings.of(context);
  final items = t.whatsNewItems;
  if (items.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            0,
            AppSpace.xl,
            AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // «YANGI» nishoni — sarlavhaning o'zida, brend rangida.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      t.newLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      t.whatsNewTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(item, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(t.close),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  await ref.read(whatsNewProvider).markSeen();
}

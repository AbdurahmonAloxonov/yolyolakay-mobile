import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/strings.dart';
import '../shared/password_field.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';

/// Parol o'rnatish / almashtirish — `POST /auth/setup-password`.
///
/// NEGA KERAK: OTP kunlik 5 ta bilan cheklangan va har SMS pul turadi.
/// Parolsiz odam limitga urilsa yoki SMS kelmasa ilovaga UMUMAN kira olmaydi.
/// Repozitoriyda `setupPassword` allaqachon bor edi — faqat uni chaqiradigan
/// ekran yo'q edi (o'lik kod).
///
/// Endpoint joriy tokenga tayanadi, ya'ni ESKI parolni so'ramaydi — shuning
/// uchun "o'rnatish" va "almashtirish" bitta oqim.
class PasswordSheet extends ConsumerStatefulWidget {
  const PasswordSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    // `useSafeArea` SHART (Android 15+ / targetSdk 36): tizim
    // "edge-to-edge" ni MAJBURIY qiladi va opt-out endi ishlamaydi.
    // Usiz varaqning eng pastki tugmasi imo-ishora paneli ostida
    // qolib, bosib bo'lmaydigan bo'lardi.
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => const PasswordSheet(),
  );

  @override
  ConsumerState<PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends ConsumerState<PasswordSheet> {
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppStrings.of(context);
    if (_password.text.length < 6) {
      showMessage(context, t.passwordTooShort);
      return;
    }
    if (_password.text != _repeat.text) {
      showMessage(context, t.passwordMismatch);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).setupPassword(_password.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, t.passwordSaved);
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    return Padding(
      // Klaviatura maydonlarni yopib qo'ymasin.
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              t.setPassword,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            t.passwordHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          PasswordField(
            // Klaviaturada «Keyingi» — fokus keyingi maydonga o'zi o'tadi.
            // Busiz odam har maydondan keyin klaviaturani yopib, keyingisini
            // qo'li bilan izlardi (`textInputAction` butun ilovada UMUMAN
            // yo'q edi — 2026-08-25 auditi).
            controller: _password,
            textInputAction: TextInputAction.next,
            labelText: t.passwordLabel,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpace.md),
          PasswordField(
            controller: _repeat,
            textInputAction: TextInputAction.done,
            labelText: t.passwordRepeat,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpace.xl),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.save),
          ),
        ],
      ),
    );
  }
}

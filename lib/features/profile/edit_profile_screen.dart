import 'package:yolyolakay/features/shared/screen_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';
import '../shared/brand/loom_loader.dart';
import '../shared/brand/brand_panels.dart';

/// Profilni tahrirlash — ism, familiya, jins.
///
/// Ilgari bunday ekran YO'Q edi: odam ro'yxatdan o'tishda kiritgan ismini keyin
/// o'zgartira olmasdi (xato yozgan bo'lsa ham). `CompleteProfileScreen` bor edi,
/// lekin u faqat onboarding uchun — orqaga qaytish tugmasi yo'q va maydonlar
/// bo'sh boshlanadi.
///
/// Bu yerda maydonlar joriy qiymat bilan TO'LDIRILADI va `PUT /users/profile`
/// chaqiriladi (onboarding bilan bir xil endpoint).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  String? _gender;
  bool _saving = false;
  bool _filled = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  /// Joriy qiymatlarni bir marta to'ldiramiz. `meProvider` qayta yuklanganda
  /// odam yozayotgan matnni ezib yubormasligi uchun `_filled` bayrog'i bor.
  void _prefill(String? first, String? last, String? gender) {
    if (_filled) return;
    _filled = true;
    _firstName.text = first ?? '';
    _lastName.text = last ?? '';
    _gender = gender;
  }

  bool get _isValid =>
      _firstName.text.trim().length >= 2 && _lastName.text.trim().length >= 2;

  Future<void> _submit() async {
    final t = AppStrings.of(context);
    if (!_isValid) {
      showMessage(context, t.nameRequired);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(usersRepositoryProvider)
          .updateProfile(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            gender: _gender,
          );
      // Profil kartasi darhol yangilansin.
      ref.invalidate(meProvider);
      if (!mounted) return;
      showMessage(context, t.profileSaved);
      Navigator.of(context).pop();
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
    final me = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(
        title: ScreenTitle(t.editProfile),
        bottom: const JiyakLine(),
      ),
      body: me.when(
        loading: () => const Center(child: LoomLoader()),
        error: (error, _) =>
            ErrorView(error: error, onRetry: () => ref.invalidate(meProvider)),
        data: (data) {
          final user = data.user;
          _prefill(user.firstName, user.lastName, user.gender);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                TextField(
                  // Klaviaturada «Keyingi» — fokus keyingi maydonga o'zi o'tadi.
                  // Busiz odam har maydondan keyin klaviaturani yopib, keyingisini
                  // qo'li bilan izlardi (`textInputAction` butun ilovada UMUMAN
                  // yo'q edi — 2026-08-25 auditi).
                  controller: _firstName,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: t.firstName),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpace.lg),
                TextField(
                  controller: _lastName,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: t.lastName),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpace.xl),
                Text(t.gender, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpace.sm),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'male', label: Text(t.male)),
                    ButtonSegment(value: 'female', label: Text(t.female)),
                  ],
                  selected: _gender == null ? <String>{} : {_gender!},
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => setState(
                    () => _gender = selection.isEmpty ? null : selection.first,
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
                FilledButton(
                  onPressed: _saving || !_isValid ? null : _submit,
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
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// PAROL MAYDONI — ko'z tugmasi bilan.
///
/// 🔴 NEGA (2026-09-29, egasi): parol yulduzchalar ostida terilardi va
/// ko'rish yo'li yo'q edi. Telefon klaviaturasida xato bosish oson —
/// odam noto'g'ri parolni «to'g'ri» deb o'ylab, qayta-qayta rad olardi
/// yoki o'rnatishda xato parolni saqlab, keyin kira olmasdi.
///
/// Ilovadagi BARCHA parol maydonlari shu vidjetdan: biri o'zgarsa
/// qolganlari ortda qolmasin.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String labelText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return TextField(
      controller: widget.controller,
      obscureText: !_revealed,
      // Ochiq parolga klaviatura taklif/tuzatish qo'shmasin.
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.labelText,
        suffixIcon: IconButton(
          tooltip: _revealed ? t.hidePassword : t.showPassword,
          icon: Icon(
            _revealed
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => _revealed = !_revealed),
        ),
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}

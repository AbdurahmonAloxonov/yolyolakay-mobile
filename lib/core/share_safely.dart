import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';

/// Tizim ulashish oynasi — yiqilsa matnni NUSXALAYDI va aytadi.
///
/// 🔴 NEGA (2026-09-29, egasi: «share tugmasi ishlamayapti»): ilovadagi
/// ulashish joylari xatoni `catch (_) {}` bilan yutardi yoki umuman
/// ushlamasdi. Oyna ochilmasa (ba'zi Android qobiqlari, planshet —
/// `sharePositionOrigin` yo'q edi) odam tugmani bosar, hech nima
/// bo'lmasdi — na oyna, na xabar. Endi:
///   • oyna ochilsa — jim (tizim oynasining o'zi javob);
///   • yiqilsa va matn bo'lsa — nusxa + «Nusxa olindi»;
///   • matn ham bo'lmasa — «Ulashib bo'lmadi».
///
/// `context` await'dan OLDIN o'qiladi — keyin vidjet yopilgan bo'lishi mumkin.
Future<void> shareSafely(BuildContext context, ShareParams params) async {
  final t = AppStrings.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  // iPad/planshetda oyna qayerdan chiqishini bilmasa share_plus xato beradi.
  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: params.text,
        subject: params.subject,
        title: params.title,
        uri: params.uri,
        files: params.files,
        fileNameOverrides: params.fileNameOverrides,
        sharePositionOrigin: params.sharePositionOrigin ?? origin,
      ),
    );
  } catch (_) {
    await shareFallback(messenger, t, params.text);
  }
}

/// Ulashib bo'lmaganda: matnni nusxalaydi yoki sababini aytadi.
/// Rasm tayyorlanmay qolgan joylar ham shuni chaqiradi.
Future<void> shareFallback(
  ScaffoldMessengerState? messenger,
  AppStrings t,
  String? text,
) async {
  var copied = false;
  if (text != null && text.trim().isNotEmpty) {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      copied = true;
    } catch (_) {}
  }
  messenger?.showSnackBar(
    SnackBar(content: Text(copied ? t.copied : t.shareFailed)),
  );
}

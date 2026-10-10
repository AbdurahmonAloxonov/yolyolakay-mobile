import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/dimens.dart';
import '../../l10n/strings.dart';

/// SURAT MANBASINI TANLASH — kamera yoki galereya.
///
/// 🔴 NEGA YOZILDI (egasi, 2026-08-27): ilovada FAQAT `ImageSource.gallery`
/// ishlatilardi. Ya'ni hujjatini suratga olmoqchi bo'lgan haydovchi
/// ilovadan CHIQIB, kamera ilovasini ochib, surat olib, qaytib kelib,
/// galereyadan tanlashi kerak edi. Bu YETTI marta takrorlanadi:
/// guvohnoma old/orqa, texpasport old/orqa, mashina uch rakursda.
///
/// Har chiqib-kirish — voz kechish uchun yana bir imkoniyat. Onboarding
/// qoralamasi shu sababdan yozilgandi; endi sababning o'zi kamayadi.
///
/// ⚠️ Oddiy suratlar uchun kamera MAJBURIY EMAS: odamda tayyor surat
/// bo'lishi mumkin. Shuning uchun bu TANLOV varag'i, kamera esa birinchi
/// va asosiy variant sifatida turadi.
///
/// 🔴 `liveOnly: true` — TEKSHIRUV suratlari uchun (egasi, 2026-08-28):
/// hujjat va mashina AYNI PAYTDA olinishi shart. Galereya ochiq qolsa,
/// odam internetdan olingan yoki boshqa odamning hujjatini yuklashi
/// mumkin va moderatsiya buni surat sifatidan ajrata olmaydi. Bunda
/// varaq umuman ko'rsatilmaydi — kamera TO'G'RIDAN-TO'G'RI ochiladi,
/// ya'ni ortiqcha bosish ham yo'qoladi.
///
/// Bekor qilinsa `null` qaytaradi.
Future<XFile?> pickPhotoSource(
  BuildContext context, {
  double maxWidth = 1600,
  int imageQuality = 85,
  bool liveOnly = false,
  CameraDevice camera = CameraDevice.rear,
}) async {
  if (liveOnly) {
    return _capture(
      context,
      ImageSource.camera,
      maxWidth,
      imageQuality,
      camera,
    );
  }
  final t = AppStrings.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.sm,
              ),
              child: Text(
                t.photoSourceTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Kamera BIRINCHI: hujjat suratga olinadi, galereyadan
            // tanlanmaydi — ro'yxat tartibi shu haqiqatga mos bo'lsin.
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t.photoSourceCamera),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.photoSourceGallery),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ),
      );
    },
  );
  if (source == null) return null;
  // Varaq yopilgunicha ekran yopilgan bo'lishi mumkin.
  if (!context.mounted) return null;
  return _capture(context, source, maxWidth, imageQuality, CameraDevice.rear);
}

Future<XFile?> _capture(
  BuildContext context,
  ImageSource source,
  double maxWidth,
  int imageQuality,
  CameraDevice camera,
) async {
  try {
    return await ImagePicker().pickImage(
      source: source,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
      // Hujjat va mashina uchun orqa kamera; selfi uchun chaqiruvchi
      // `camera: CameraDevice.front` beradi.
      preferredCameraDevice: camera,
    );
  } catch (_) {
    // 🔴 Kamerasiz qurilma yoki rad etilgan ruxsat — JIM QOLMAYMIZ.
    // Ilgari bunday holatda hech nima bo'lmasdi va odam tugmani
    // qayta-qayta bosardi.
    if (source == ImageSource.camera && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).photoCameraUnavailable)),
      );
    }
    return null;
  }
}

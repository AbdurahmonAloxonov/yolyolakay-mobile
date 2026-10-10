import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show CameraDevice;

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/media_url.dart';
import '../../l10n/strings.dart';
import '../shared/photo_source_sheet.dart';
import '../shared/state_views.dart';

/// BITTA HUJJAT — qo'llanma + yuklash joyi + ko'rib tekshirish.
///
/// 🔴 NEGA ALOHIDA KOMPONENT: to'rtta hujjat (shaxs, guvohnoma, texpasport)
/// bir xil ishlaydi — farqi faqat sarlavha va qo'llanmada. Har birini
/// alohida yozish uchta joyda uchta xil xatti-harakat degani bo'lardi.
///
/// 🔴 QO'LLANMA MAJBURIY QISM: eng ko'p uchraydigan sabab — rasm xira,
/// burchagi kesilgan yoki yorug'lik aks etgan. Tekshiruvchi uni rad
/// etadi, odam esa NEGA rad etilganini bilmaydi va yana o'shanday
/// yuboradi. Talabni OLDINDAN aytish rad etishlar sonini kamaytiradi.
///
/// Kamera ATAYIN ishlatilmaydi — GALEREYA: kamera ruxsati Play'da alohida
/// asoslash talab qiladi, galereya esa Android 13+ da tizim "Photo Picker"
/// orqali RUXSATSIZ ishlaydi (bu qoida `become_driver_screen` da ham).
class DocumentUpload extends ConsumerStatefulWidget {
  const DocumentUpload({
    super.key,
    required this.title,
    required this.hints,
    required this.url,
    required this.onChanged,
    this.optional = false,
    this.liveOnly = false,
    this.frontCamera = false,
  });

  final String title;

  /// Qanday suratga olish kerak — qisqa talablar ro'yxati.
  final List<String> hints;

  /// Yuklangan surat manzili (`media/upload` javobi) yoki `null`.
  final String? url;
  final ValueChanged<String?> onChanged;

  final bool optional;

  /// Surat AYNI PAYTDA olinsin — galereya taklif qilinmaydi.
  /// Izohi `pickPhotoSource` da: tekshiruv suratlari uchun shart.
  final bool liveOnly;

  /// Selfi uchun old kamera. Hujjat va mashinada orqasi kerak.
  final bool frontCamera;

  @override
  ConsumerState<DocumentUpload> createState() => _DocumentUploadState();
}

class _DocumentUploadState extends ConsumerState<DocumentUpload> {
  bool _uploading = false;

  /// Oxirgi yuklash MUVAFFAQIYATSIZ tugadimi.
  ///
  /// 🔴 NEGA KERAK (2026-08-27): xato faqat snackbar bo'lib chiqardi va
  /// bir lahzada yo'qolardi, ramka esa BO'SH qolaverardi. Ya'ni «hali
  /// yuklamadim» bilan «yuklanmadi» bir xil ko'rinardi — odam suratni
  /// qo'ygan deb o'ylab, «Keyingi» tugmasi nega o'chiqligini tushunmasdi.
  bool _failed = false;

  Future<void> _pick() async {
    final t = AppStrings.of(context);
    // Kamera yoki galereya — tanlov odamda (izohi `pickPhotoSource` da).
    // Ilgari faqat galereya bor edi va hujjatni suratga olish uchun
    // ilovadan chiqib-kirish kerak bo'lardi.
    final picked = await pickPhotoSource(
      context,
      liveOnly: widget.liveOnly,
      camera: widget.frontCamera ? CameraDevice.front : CameraDevice.rear,
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() {
      _uploading = true;
      _failed = false;
    });
    try {
      final url = await ref
          .read(mediaRepositoryProvider)
          .upload(picked.path, fileName: picked.name);
      if (!mounted) return;
      if (url == null) {
        setState(() => _failed = true);
        showMessage(context, t.photoFailed);
      } else {
        widget.onChanged(url);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
        showMessage(context, t.photoFailed);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final uploaded = (widget.url ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.title, style: theme.textTheme.titleMedium),
            ),
            if (widget.optional)
              Text(
                t.optionalLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),

        // Talablar — yuklashdan OLDIN, keyin emas: rad etilgach o'qish kech.
        for (final hint in widget.hints)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔴 BELGILAR PUSHTI EDI (2026-09-03 ko'rigi): bir
                // ekranda uchta pushti «bajarildi» belgisi va pushti
                // qadam chizig'i turardi. Bular esa bajarilgan ish
                // emas, TALAB — ya'ni pushti (asosiy amal) ularniki
                // emas. Ilovaning qoidasi bo'yicha «yaxshi/bor» rangi
                // feruza; talab ham shu oiladan.
                Icon(Icons.check, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(hint, style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.lg),

        // Yuklash maydoni — bosiladigan ramka. Yuklangach SURAT ko'rinadi:
        // odam nimani yuborganini ko'rishi kerak, "yuklandi" degan yozuv
        // yetarli emas (noto'g'ri fayl tanlangani shunda bilinadi).
        AspectRatio(
          aspectRatio: 16 / 10,
          child: InkWell(
            onTap: _uploading ? null : _pick,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: uploaded
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: uploaded ? 2 : 1,
                ),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: _uploading
                  ? const Center(child: CircularProgressIndicator())
                  : uploaded
                  ? _Preview(url: widget.url!)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _failed
                              ? Icons.error_outline
                              : Icons.add_photo_alternate_outlined,
                          size: 34,
                          color: _failed
                              ? theme.colorScheme.error
                              : theme.colorScheme.outline,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.lg,
                          ),
                          child: Text(
                            // Xato holati RAMKADA qoladi: snackbar
                            // yo'qoladi, savol esa qolib ketardi.
                            _failed ? t.photoFailedRetry : t.uploadPhoto,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _failed
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        if (uploaded) ...[
          const SizedBox(height: AppSpace.sm),
          /*
           * 🔴 `Row` EMAS, `Wrap` (2026-08-30, egasi: «rasm joylangandan
           * keyin keyingisi tugmasi yo'q»).
           *
           * «Almashtirish» va «O'chirish» ikonkali tugmalari o'zbekcha va
           * ruscha matn bilan 360 pikselli ekranga SIG'MASDI: qator
           * o'ngdan 133 piksel (320 px ekranda 173) toshib ketardi.
           * `flutter analyze` buni KO'RMAYDI, reliz build'da esa sariq
           * chiziqlar chizilmaydi — qator jimgina KESILADI.
           *
           * Ya'ni surat yuklangan zahoti ekranning o'ng chekkasidan
           * tugmalar chiqib ketar edi va odam «tugmalar yo'q» degan
           * xulosaga kelardi.
           *
           * `Wrap` tor ekranda ularni pastki qatorga tushiradi.
           */
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              TextButton.icon(
                onPressed: _uploading ? null : _pick,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(t.replacePhoto),
              ),
              TextButton.icon(
                onPressed: _uploading ? null : () => widget.onChanged(null),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(t.removeItem),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Yuklangan hujjat suratining ko'rinishi.
///
/// ⚠️ Rasm OCHILMASLIGI mumkin: backend `media/upload` dan qaytgan manzil
/// hozir 404 beradi (xat 2026-08-20 §6). Shunda bo'sh joy emas, ochiq
/// yozuv ko'rsatiladi — odam "yuklandi, lekin ko'rinmayapti" degan
/// holatni tushunishi kerak.
class _Preview extends StatelessWidget {
  const _Preview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final resolved = mediaUrl(url);
    if (resolved == null) return const SizedBox.shrink();

    return Image.network(
      resolved,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 30, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpace.xs),
          Text(t.photoUploaded, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_exception.dart';

import '../../app/providers.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../../app/dimens.dart';
import 'document_upload.dart';

/// "Mashina qo'shish" — `POST /users/me/cars`.
///
/// 🔴 Nima yetishmasdi: repozitoriyda `addCar` yozilgan edi, lekin uni
/// chaqiradigan ekran YO'Q edi. Ya'ni haydovchi FAQAT birinchi mashinasini
/// (haydovchi bo'lish oqimida) qo'sha olardi; ikkinchisini qo'shishning
/// umuman iloji yo'q edi.
///
/// ✅ 2026-08-27: hujjatlar `DocumentUpload` orqali — haydovchi bo'lish
/// oqimidagi AYNI komponent. Ilgari bu varaqda o'ziga xos, qo'lda
/// yozilgan bitta surat yuklagich turardi: qo'llanmasiz va bitta kadr
/// bilan. Endi texpasport IKKI TOMONDAN va mashina UCH RAKURSDA
/// so'raladi — backend `.com` da shu maydonlar paydo bo'ldi
/// (`http.CreateCarRequest`), moderatsiya esa bitta kadrdan mashinani
/// tasdiqlay olmasdi.
class AddCarSheet extends ConsumerStatefulWidget {
  const AddCarSheet({super.key});

  static Future<bool?> show(BuildContext context) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const AddCarSheet(),
  );

  @override
  ConsumerState<AddCarSheet> createState() => _AddCarSheetState();
}

class _AddCarSheetState extends ConsumerState<AddCarSheet> {
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _plate = TextEditingController();

  String? _techFrontUrl;
  String? _techBackUrl;
  String? _carFrontUrl;
  String? _carBackUrl;
  String? _carSideUrl;
  bool _saving = false;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _plate.dispose();
    super.dispose();
  }

  /// 🔴 HUJJATLAR BU YERDA MAJBURIY EMAS — ATAYIN.
  ///
  /// Bir vaqt ular majburiy qilingan edi, lekin bu ESKI xatti-harakatni
  /// qattiqlashtirib qo'yardi: ilgari mavjud haydovchi ikkinchi
  /// mashinasini faqat marka/model/raqam bilan qo'sha olardi. Bundan
  /// tashqari saytda (`VehiclesSection`) shart hamon yumshoq — ikki
  /// mijoz BOSHQACHA ishlagan bo'lardi, bu esa shu loyihada allaqachon
  /// bir necha marta chiqqan xato turi.
  ///
  /// Hujjatlar baribir SO'RALADI (ko'rinib turadi va nega kerakligi
  /// yozilgan) — faqat tugmani to'smaydi.
  bool get _isValid =>
      _brand.text.trim().length >= 2 &&
      _model.text.trim().isNotEmpty &&
      _plate.text.trim().length >= 6;

  /// Saqlash uchun nima yetishmayapti — `null` bo'lsa hammasi joyida.
  ///
  /// 🔴 NEGA KERAK (egasi, 2026-08-28): tugma o'chiq turardi va SABABINI
  /// aytmasdi. Odam uchta suratni yuklab bo'lib, tugma ishlamasligini
  /// ko'radi va nima qilishni bilmaydi — «keyingisi yo'q» bo'lib
  /// tuyuladi. Ayni tuzatish `driver_verification_screen` da ham
  /// qilingan.
  String? _missing(AppStrings t) {
    if (_isValid) return null;
    return t.carNeedBasics;
  }

  Future<void> _save() async {
    final t = AppStrings.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(usersRepositoryProvider)
          .addCar(
            brand: _brand.text.trim(),
            model: _model.text.trim(),
            govNumber: _plate.text.replaceAll(' ', '').toUpperCase(),
            techPassportFront: _techFrontUrl,
            techPassportBack: _techBackUrl,
            carFrontPhoto: _carFrontUrl,
            carBackPhoto: _carBackUrl,
            carSidePhoto: _carSideUrl,
          );
      ref.invalidate(meProvider);
      if (!mounted) return;
      showMessage(context, t.carAdded);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final text = error.toString().toLowerCase();
      showMessage(
        context,
        text.contains('duplicate') || text.contains('already exists')
            ? t.carPlateTaken
            // Server nosozligida ayb odamda emasligi AYTILADI — aks holda
            // u suratlarni qayta olib, formani qayta to'ldiraveradi.
            : ApiException.from(error).isInternalError
            ? t.carSaveServerDown
            : t.carSaveFailed,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      /*
       * 🔴 TUGMA SURILADIGAN QISMDAN TASHQARIDA (2026-08-28).
       *
       * Egasi: «keyingisi tugmasi yo'q». Aslida tugma BOR edi, lekin
       * `SingleChildScrollView` ICHIDA, uchta surat ramkasidan KEYIN
       * turardi. Telefonda unga yetib borish uchun uzoq surish kerak
       * edi va odam uni umuman ko'rmasdi.
       *
       * Loyihada bu xatoning tarixi bor («asosiy tugma ro'yxat oxirida
       * turmasin», 2026-08-12). Endi forma suriladi, tugma esa pastda
       * QOTIB turadi.
       *
       * `ConstrainedBox` SHART: `Expanded` cheksiz balandlikda ishlamaydi,
       * modal varaq esa balandligini o'zi belgilaydi.
       */
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(t.addCar, style: theme.textTheme.titleLarge),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    TextField(
                      // Klaviaturada «Keyingi» — fokus keyingi maydonga o'zi
                      // o'tadi. Busiz odam har maydondan keyin klaviaturani yopib,
                      // keyingisini qo'li bilan izlardi (butun ilovada
                      // `textInputAction` UMUMAN yo'q edi, 2026-08-25 auditi).
                      controller: _brand,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: t.carBrand),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpace.md),
                    TextField(
                      controller: _model,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: t.carModel),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpace.md),
                    TextField(
                      controller: _plate,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: t.govNumber,
                        hintText: '01 A 123 BC',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    DocumentUpload(
                      title: '${t.docTechPassportTitle} — ${t.docFrontSide}',
                      hints: t.docTechPassportHints,
                      url: _techFrontUrl,
                      onChanged: (url) => setState(() => _techFrontUrl = url),
                      optional: true,
                      liveOnly: true,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    DocumentUpload(
                      title: t.docTechPassportBackTitle,
                      hints: t.docTechPassportBackHints,
                      url: _techBackUrl,
                      onChanged: (url) => setState(() => _techBackUrl = url),
                      optional: true,
                      liveOnly: true,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Text(t.docCarPhotos, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      t.docLiveOnlyNote,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    DocumentUpload(
                      title: t.docCarFrontTitle,
                      hints: t.docCarFrontHints,
                      url: _carFrontUrl,
                      onChanged: (url) => setState(() => _carFrontUrl = url),
                      optional: true,
                      liveOnly: true,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    DocumentUpload(
                      title: t.docCarBackTitle,
                      hints: t.docCarBackHints,
                      url: _carBackUrl,
                      onChanged: (url) => setState(() => _carBackUrl = url),
                      optional: true,
                      liveOnly: true,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    DocumentUpload(
                      title: t.docCarSideTitle,
                      hints: t.docCarSideHints,
                      url: _carSideUrl,
                      onChanged: (url) => setState(() => _carSideUrl = url),
                      optional: true,
                      liveOnly: true,
                    ),
                  ],
                ),
              ),
            ),

            // PASTDA QOTIB TURADIGAN QISM — suriladigan formadan tashqarida.
            const SizedBox(height: AppSpace.lg),
            // Nima yetishmayotgani tugmaning O'ZI yonida (izohi `_missing` da).
            if (_missing(t) != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      _missing(t)!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            FilledButton(
              onPressed: _isValid && !_saving ? _save : null,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}

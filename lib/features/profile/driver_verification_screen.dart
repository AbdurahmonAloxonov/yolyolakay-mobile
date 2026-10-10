import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/drafts.dart';
import '../../l10n/strings.dart';
import '../shared/bottom_action_bar.dart';
import '../shared/state_views.dart';
import '../shared/brand/brand_panels.dart';
import 'document_upload.dart';

/// HAYDOVCHI BO'LISH — hujjatlar QADAMMA-QADAM.
///
/// 🔴 NEGA BITTA SAHIFA EMAS (egasi, 2026-08-21): uchta hujjat, mashina
/// ma'lumotlari va tasdiq bitta ekranga tiqilsa, u cheksiz uzun bo'ladi
/// va odam qayerda qolganini bilmaydi. Yarim to'ldirib tashlab ketish
/// eng ko'p uchraydigan holat. Qadamlarda esa har safar BITTA ish
/// bo'ladi va oldinga siljish ko'rinib turadi.
///
/// 🔴 HAR HUJJATDA QO'LLANMA: rad etishlarning aksariyati sabab — xira
/// surat, kesilgan burchak, aks etgan yorug'lik. Talabni OLDINDAN aytish
/// qayta yuborishlar sonini kamaytiradi (izohi `DocumentUpload` da).
///
/// ✅ MyID BUTUNLAY OLIB TASHLANDI (2026-08-22): backend `myid_code` ni
/// endi talab qilmaydi (jonli o'lchandi — bo'sh tana validatsiyasi faqat
/// marka/model/davlat raqamini so'raydi). Egasining qarori: MyID ortiqcha
/// chiqim, ~6 oydan keyin kerak bo'lsa qaytariladi.
///
/// ✅ 2026-08-28 — PASPORT VA ID KARTA OLIB TASHLANDI (egasi). Ular
/// backendga hech qachon yetib bormagan (maydonning o'zi yo'q edi), ya'ni
/// odamdan hech qayerga bormaydigan hujjat so'ralardi. O'rniga odamning
/// O'Z SURATI olinadi va u `avatar_url` ga ketadi — bu maydon
/// `UpgradeToDriverRequest` da ALLAQACHON bor.
///
/// 🔴 HAMMA SURAT AYNI PAYTDA OLINADI (`liveOnly`). Galereya ochiq
/// qolsa, odam internetdan olingan yoki boshqa odamning hujjatini
/// yuklashi mumkin — moderatsiya buni surat sifatidan ajrata olmaydi.
///
/// ✅ 2026-08-27 — HUJJAT IKKI TOMONDAN, MASHINA UCH RAKURSDA. Backend
/// `.com` da `*_front`/`*_back` va `car_front/back/side_photo` maydonlari
/// paydo bo'ldi. Ilgari har hujjatdan bitta kadr ketardi, ya'ni
/// guvohnomaning orqasidagi TOIFALAR (odam yo'lovchi tashishga haqlimi)
/// va texpasportning orqasidagi egalik yozuvlari moderatsiyaga umuman
/// yetib bormasdi.
///
/// Qadamlar: 0 surat · 1 guvohnoma · 2 texpasport · 3 mashina suratlari ·
/// 4 mashina ma'lumotlari · 5 ko'rib chiqish.
class DriverVerificationScreen extends ConsumerStatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  ConsumerState<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState
    extends ConsumerState<DriverVerificationScreen> {
  int _step = 0;

  /// Odamning o'z surati — pasport/ID o'rniga (egasi, 2026-08-28).
  /// Serverda `avatar_url` bo'lib ketadi.
  String? _selfieUrl;

  // Hujjatlar IKKI TOMONDAN (backend `.com`, 2026-08-27): guvohnomaning
  // orqasida toifalar, texpasportning orqasida egalik yozuvlari.
  String? _licenseFrontUrl;
  String? _licenseBackUrl;
  String? _techFrontUrl;
  String? _techBackUrl;

  // Mashina UCH rakursda: old, orqa, yon (egasi 2026-08-28 da aniqladi
  // — chap/o'ng ajratish KERAK EMAS, bitta yon tomon yetadi).
  String? _carFrontUrl;
  String? _carBackUrl;
  String? _carSideUrl;

  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _govNumber = TextEditingController();

  bool _saving = false;

  /// Qoralama havolasi — `dispose` da provider o'qib bo'lmaydi, shuning
  /// uchun saqlab qo'yiladi (chat ekranidagi ayni naqsh).
  Drafts? _drafts;

  @override
  void initState() {
    super.initState();
    // 🔴 QORALAMA TIKLANADI. Oqim sakkizta suratga o'sgach, uni bir
    // o'tirishda tugatish har doim ham iloji bo'lmay qoldi: telefon
    // jiringlashi, tizim ilovani o'chirishi yoki odam boshqa ilovaga
    // o'tishi mumkin. Suratlar allaqachon SERVERDA — biz faqat
    // manzillarni qaytaramiz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ⚠️ Qoralama — QULAYLIK, shart emas. Xotira mavjud bo'lmasa
      // (testda override qilinmagan, qurilmada disk to'lgan) oqim
      // BARIBIR ishlashi kerak: hujjat yuborishni saqlash mexanizmi
      // to'sib qo'ymasin.
      try {
        _drafts = ref.read(draftsProvider);
      } catch (_) {
        return;
      }
      final saved = _drafts?.readMap(Drafts.driverVerification);
      if (saved == null) return;
      setState(() {
        _selfieUrl = saved['selfie'] as String?;
        _licenseFrontUrl = saved['license_front'] as String?;
        _licenseBackUrl = saved['license_back'] as String?;
        _techFrontUrl = saved['tech_front'] as String?;
        _techBackUrl = saved['tech_back'] as String?;
        _carFrontUrl = saved['car_front'] as String?;
        _carBackUrl = saved['car_back'] as String?;
        _carSideUrl = saved['car_side'] as String?;
        _brand.text = (saved['brand'] as String?) ?? '';
        _model.text = (saved['model'] as String?) ?? '';
        _govNumber.text = (saved['gov_number'] as String?) ?? '';
        // Qadam ham tiklanadi, lekin oshirib yuborilmaydi: qoralama eski
        // ko'rinishdan qolgan bo'lsa (masalan qadamlar soni o'zgargan
        // versiyadan) odam mavjud bo'lmagan qadamga tushib qolmasin.
        final step = saved['step'];
        if (step is int && step >= 0 && step < _stepCount) _step = step;
      });
    });
  }

  /// `setState` + qoralamani saqlash — ikkalasi HAR DOIM birga bo'lsin.
  /// Alohida chaqirilsa, kimdir yangi maydon qo'shib saqlashni unutadi.
  void _update(VoidCallback change) {
    setState(change);
    _saveDraft();
  }

  /// Har o'zgarishda chaqiriladi — ilova qachon o'chishini bilmaymiz.
  void _saveDraft() {
    _drafts?.writeMap(Drafts.driverVerification, {
      'step': _step,
      'selfie': _selfieUrl,
      'license_front': _licenseFrontUrl,
      'license_back': _licenseBackUrl,
      'tech_front': _techFrontUrl,
      'tech_back': _techBackUrl,
      'car_front': _carFrontUrl,
      'car_back': _carBackUrl,
      'car_side': _carSideUrl,
      'brand': _brand.text.trim(),
      'model': _model.text.trim(),
      'gov_number': _govNumber.text.trim(),
    });
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _govNumber.dispose();
    super.dispose();
  }

  bool get _carValid =>
      _brand.text.trim().isNotEmpty &&
      _model.text.trim().isNotEmpty &&
      _govNumber.text.trim().isNotEmpty;

  /// Joriy qadamdan keyingisiga o'tish MUMKINMI.
  ///
  /// Hujjat qadamlari MAJBURIY: hujjatsiz ariza baribir rad etiladi,
  /// ya'ni odamni oldinga o'tkazish faqat vaqtini oldiradi.
  static bool _has(String? url) => (url ?? '').isNotEmpty;

  bool get _canContinue => switch (_step) {
    0 => _has(_selfieUrl),
    1 => _has(_licenseFrontUrl) && _has(_licenseBackUrl),
    2 => _has(_techFrontUrl) && _has(_techBackUrl),
    // UCHALASI HAM MAJBURIY (egasi, 2026-08-28). Ilgari yon tomon
    // ixtiyoriy edi — ya'ni amalda hech kim yubormasdi.
    3 => _has(_carFrontUrl) && _has(_carBackUrl) && _has(_carSideUrl),
    4 => _carValid,
    _ => true,
  };

  /// Shu qadamda NIMA yetishmayotgani — `null` bo'lsa davom etish mumkin.
  ///
  /// 🔴 NEGA KERAK (egasi, qurilmada 2026-08-27: «nega keyingisiga o'tish
  /// yo'q»): «Keyingi» tugmasi bor va u suriladigan qismdan TASHQARIDA,
  /// ya'ni ekrandan chiqib ketmaydi. Lekin surat yuklanmagan bo'lsa u
  /// O'CHIQ turadi va sababini AYTMAYDI. Yuklash xatosi esa snackbar
  /// bo'lib bir lahzada yo'qoladi. Natijada odam «tugma yo'q» deb
  /// o'ylaydi — u yerda turgan bo'lsa ham.
  String? _missing(AppStrings t) => _canContinue
      ? null
      : switch (_step) {
          0 => t.stepNeedSelfie,
          1 => t.stepNeedLicense,
          2 => t.stepNeedTech,
          3 => t.stepNeedCarPhotos,
          4 => t.stepNeedCarDetails,
          _ => null,
        };

  /// 0 surat · 1 guvohnoma · 2 texpasport · 3 mashina suratlari ·
  /// 4 mashina ma'lumotlari · 5 ko'rib chiqish.
  ///
  /// 🔴 Ilgari bu 4 edi va OXIRGI qadam (`_ReviewStep`) hech qachon
  /// ko'rsatilmasdi: `_step < _stepCount - 1` sharti 3-qadamdayoq
  /// yuborishga o'tardi. Ekran yozilgan-u, ulanmagan edi.
  int get _stepCount => 6;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.becomeDriver), bottom: const JiyakLine()),
      body: Column(
        children: [
          // Oldinga siljish — qadam raqami VA chiziq. Raqamsiz chiziq
          // "qancha qoldi" degan savolga javob bermaydi.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.stepOf(_step + 1, _stepCount),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / _stepCount,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.lg),
              children: [_stepBody(t)],
            ),
          ),

          /*
           * 🔴 PASTKI PANEL RO'YXATDAN AJRALIB TURSIN (2026-09-02, egasi:
           * «ko'rinmay qolgandir»).
           *
           * Tugma joyida turgan bo'lsa ham KO'RINMASLIGI mumkin: tor
           * ekranda katta matn bilan (320 px · ruscha · 1.3) ro'yxatning
           * oxirgi elementi tugmaga YOPISHIB qolardi — surat ramkasi
           * tugmaning tagidan kesilib, ikkisi bitta bo'lakdek ko'rinardi.
           * Odam uni alohida amal deb emas, kartaning bir qismi deb
           * o'qiydi.
           *
           * Yechim — panelga o'z zamini va TEPA CHIZIG'I: ro'yxat uning
           * ostidan surilib o'tayotgani ko'rinib turadi.
           *
           * ⚠️ SOYA EMAS, CHIZIQ: qorong'i temada soya chizilmaydi
           * (`design_system_test.dart` shuni talab qiladi), chiziq esa
           * ikkala temada ham ishlaydi.
           */
          BottomActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NIMA YETISHMAYAPTI — tugmaning O'ZI yonida. Snackbar
                // yo'qoladi, bu esa turadi (izohi `_missing` da).
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
                /*
                   * 🔴 ASOSIY TUGMA BUTUN ENGDA (2026-08-30, egasi:
                   * «hech kim haydovchi bo'lolmaydi»).
                   *
                   * Ilgari bu `Row([Orqaga, Spacer, Tugma])` edi va
                   * OXIRGI qadamda — aynan ariza yuboriladigan joyda —
                   * «Ko'rib chiqishga yuborish» yozuvi sig'masdi:
                   * 360 pikselli ekranda tugma o'ng chekkadan 94
                   * piksel TASHQARIDA chizilardi (320 px da 134).
                   * Ya'ni odam hamma suratini yuklab kelib, oxirgi
                   * tugmani BOSA OLMASDI.
                   *
                   * `Row` + `Spacer` bu loyihada ikkinchi marta shu
                   * xatoni beryapti (2026-08-26 surish auditi ham shu
                   * naqshni topgan). Butun engdagi tugma esa matn
                   * qanchalik uzun bo'lishidan QAT'I NAZAR toshmaydi —
                   * shuning uchun naqshning o'zi almashtirildi.
                   *
                   * «Orqaga» pastda: u ikkinchi darajali amal va
                   * asosiy tugmaning yo'lini to'smasligi kerak.
                   */
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving || !_canContinue
                        ? null
                        : () {
                            if (_step < _stepCount - 1) {
                              _update(() => _step += 1);
                            } else {
                              _submit();
                            }
                          },
                    child: Text(
                      _step < _stepCount - 1 ? t.next : t.sendForReview,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (_step > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => _update(() => _step -= 1),
                      child: Text(t.back),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody(AppStrings t) => switch (_step) {
    // Pasport va ID karta OLIB TASHLANDI (izohi ekran sarlavhasida).
    // O'rniga odamning o'z surati — u profilga tushadi va yo'lovchi
    // uchrashuv joyida haydovchini taniydi.
    0 => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LiveOnlyNote(text: t.docLiveOnlyNote),
        const SizedBox(height: AppSpace.lg),
        DocumentUpload(
          title: t.docSelfieTitle,
          hints: t.docSelfieHints,
          url: _selfieUrl,
          onChanged: (url) => _update(() => _selfieUrl = url),
          liveOnly: true,
          // Selfi uchun OLD kamera — odam o'zini ko'rib turishi kerak.
          frontCamera: true,
        ),
      ],
    ),
    // Guvohnoma — IKKI tomondan. Orqa tomonda TOIFALAR (B, C, D) bor:
    // odam yo'lovchi tashishga haqlimi yoki yo'qmi aynan o'sha yerda
    // ko'rinadi, ya'ni faqat old tomon moderatsiyaga yetmaydi.
    1 => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentUpload(
          title: '${t.docLicenseTitle} — ${t.docFrontSide}',
          hints: t.docLicenseHints,
          url: _licenseFrontUrl,
          onChanged: (url) => _update(() => _licenseFrontUrl = url),
          liveOnly: true,
        ),
        const SizedBox(height: AppSpace.xl),
        DocumentUpload(
          title: t.docLicenseBackTitle,
          hints: t.docLicenseBackHints,
          url: _licenseBackUrl,
          onChanged: (url) => _update(() => _licenseBackUrl = url),
          liveOnly: true,
        ),
      ],
    ),
    2 => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentUpload(
          title: '${t.docTechPassportTitle} — ${t.docFrontSide}',
          hints: t.docTechPassportHints,
          url: _techFrontUrl,
          onChanged: (url) => _update(() => _techFrontUrl = url),
          liveOnly: true,
        ),
        const SizedBox(height: AppSpace.xl),
        DocumentUpload(
          title: t.docTechPassportBackTitle,
          hints: t.docTechPassportBackHints,
          url: _techBackUrl,
          onChanged: (url) => _update(() => _techBackUrl = url),
          liveOnly: true,
        ),
      ],
    ),
    // Mashina UCH rakursda — yo'lovchi uchrashuv joyida taniy olishi va
    // moderatsiya davlat raqamini texpasportdagisi bilan solishtira
    // olishi uchun. Bitta kadr ikkala vazifaga ham yetmaydi.
    3 => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.docCarPhotos, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.sm),
        _LiveOnlyNote(text: t.docLiveOnlyNote),
        const SizedBox(height: AppSpace.lg),
        DocumentUpload(
          title: t.docCarFrontTitle,
          hints: t.docCarFrontHints,
          url: _carFrontUrl,
          onChanged: (url) => _update(() => _carFrontUrl = url),
          liveOnly: true,
        ),
        const SizedBox(height: AppSpace.xl),
        DocumentUpload(
          title: t.docCarBackTitle,
          hints: t.docCarBackHints,
          url: _carBackUrl,
          onChanged: (url) => _update(() => _carBackUrl = url),
          liveOnly: true,
        ),
        const SizedBox(height: AppSpace.xl),
        DocumentUpload(
          title: t.docCarSideTitle,
          hints: t.docCarSideHints,
          url: _carSideUrl,
          onChanged: (url) => _update(() => _carSideUrl = url),
          liveOnly: true,
        ),
      ],
    ),
    4 => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.carDetails, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.lg),
        TextField(
          // Klaviaturada «Keyingi» — fokus keyingi maydonga o'zi o'tadi.
          // Busiz odam har maydondan keyin klaviaturani yopib, keyingisini
          // qo'li bilan izlardi (`textInputAction` butun ilovada UMUMAN
          // yo'q edi — 2026-08-25 auditi).
          controller: _brand,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: t.carBrand),
          onChanged: (_) => _update(() {}),
        ),
        const SizedBox(height: AppSpace.md),
        TextField(
          controller: _model,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: t.carModel),
          onChanged: (_) => _update(() {}),
        ),
        const SizedBox(height: AppSpace.md),
        TextField(
          controller: _govNumber,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [UpperCaseFormatter()],
          decoration: InputDecoration(
            labelText: t.carPlate,
            hintText: '01 A 123 AA',
          ),
          onChanged: (_) => _update(() {}),
        ),
      ],
    ),
    _ => _ReviewStep(
      selfieDone: _has(_selfieUrl),
      licenseDone: _has(_licenseFrontUrl) && _has(_licenseBackUrl),
      techDone: _has(_techFrontUrl) && _has(_techBackUrl),
      carPhotosDone:
          _has(_carFrontUrl) && _has(_carBackUrl) && _has(_carSideUrl),
      car:
          '${_brand.text.trim()} ${_model.text.trim()} · ${_govNumber.text.trim()}',
    ),
  };

  Future<void> _submit() async {
    final t = AppStrings.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(usersRepositoryProvider)
          .upgradeToDriver(
            brand: _brand.text.trim(),
            model: _model.text.trim(),
            govNumber: _govNumber.text.trim(),
            techPassportFront: _techFrontUrl,
            techPassportBack: _techBackUrl,
            driverLicenseFront: _licenseFrontUrl,
            driverLicenseBack: _licenseBackUrl,
            carFrontPhoto: _carFrontUrl,
            carBackPhoto: _carBackUrl,
            carSidePhoto: _carSideUrl,
            avatarUrl: _selfieUrl,
          );
      // Ariza ketdi — qoralama endi keraksiz. Tozalanmasa, odam keyingi
      // safar ekranni ochganda allaqachon yuborilgan hujjatlarni qaytadan
      // ko'rib, ikkinchi marta yuborardi.
      await _drafts?.clear(Drafts.driverVerification);
      ref.invalidate(meProvider);
      if (!mounted) return;
      showMessage(context, t.becomeDriverDone);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Oxirgi qadam — nima yuborilayotganini KO'RSATADI.
///
/// 🔴 NEGA KERAK: uzun formadan keyin odam nima to'ldirganini eslamaydi.
/// Yuborishdan oldin ro'yxatni ko'rish xatoni shu yerda tuzatish imkonini
/// beradi — rad etilgach emas.
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.selfieDone,
    required this.licenseDone,
    required this.techDone,
    required this.carPhotosDone,
    required this.car,
  });

  final bool selfieDone;
  final bool licenseDone;
  final bool techDone;
  final bool carPhotosDone;
  final String car;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    Widget row(String label, bool done) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            // «Bajarildi» — feruza (ilovaning qoidasi: feruza =
            // «bor/yaxshi», pushti = asosiy amal).
            color: done
                ? theme.colorScheme.secondary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.reviewTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpace.lg),
        row(t.docSelfieTitle, selfieDone),
        row(t.docLicenseTitle, licenseDone),
        row(t.docTechPassportTitle, techDone),
        row(t.docCarPhotos, carPhotosDone),
        row(car.trim().isEmpty ? t.carDetails : car, car.trim().length > 3),
      ],
    );
  }
}

/// «Suratlar ayni paytda olinadi» eslatmasi.
///
/// 🔴 NEGA KERAK: galereya tugmasi yo'qolgani odamga TUSHUNTIRILMASA, u
/// buni nosozlik deb o'ylaydi — «tayyor suratim bor edi, nega qo'shib
/// bo'lmayapti». Sababni oldindan aytish murojaatni kamaytiradi.
class _LiveOnlyNote extends StatelessWidget {
  const _LiveOnlyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.photo_camera_outlined,
          size: 15,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

/// Davlat raqamini BOSH HARFGA aylantiradi.
///
/// `become_driver_screen.dart` dan ko'chirildi — o'sha ekran MyID bilan
/// birga o'chirildi (2026-08-22), formatter esa hamon kerak.
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

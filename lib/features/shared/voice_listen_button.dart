import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app/dimens.dart';
import '../../core/haptics.dart';
import '../../core/motion.dart';
import '../../l10n/strings.dart';
import '../../l10n/cyrillic.dart';

/// OVOZ TUGMASI — nutqni matnga aylantiradi, tahlil qilmaydi.
///
/// 🔴 NEGA AJRATILDI (2026-08-25): nutqni tanish mantiqiga faqat qidiruv
/// emas, E'LON BERISH ham muhtoj bo'ldi (`core/voice_ride.dart`). Uni
/// ikkinchi marta ko'chirish ikkita manba yaratardi: ruxsat so'rash
/// qoidasi, til tanlash, to'xtash shartlari — hammasi ikki joyda
/// ajralib ketardi.
///
/// ⚠️ HALOL CHEKLOV: nutqni tanish QURILMANING ishi, biznikida emas.
///   • xizmat yo'q yoki ruxsat berilmagan bo'lsa — tugma UMUMAN
///     chizilmaydi (bosilganda hech nima qilmaydigan tugma eng yomon
///     holat);
///   • xato bo'lsa jimgina to'xtaydi — forma buzilmaydi, kiritilgan matn
///     yo'qolmaydi;
///   • tanilgan gap EKRANDA ko'rsatiladi — odam nima tushunilganini
///     ko'radi va kerak bo'lsa tuzatadi.
class VoiceListenButton extends StatefulWidget {
  const VoiceListenButton({
    super.key,
    required this.onResult,
    required this.hint,
  });

  /// Yakuniy matn tanilganda.
  final void Function(String text) onResult;

  /// Tugma yonidagi izoh — odam NIMA aytishni bilishi kerak.
  final String hint;

  @override
  State<VoiceListenButton> createState() => _VoiceListenButtonState();
}

class _VoiceListenButtonState extends State<VoiceListenButton> {
  final _speech = SpeechToText();

  /// Nutqni tanish ishlayaptimi. `false` — xizmat yo'q yoki ruxsat
  /// berilmadi: tugma boshqa chizilmaydi.
  bool _available = true;

  /// `initialize` allaqachon muvaffaqiyatli o'tganmi.
  bool _ready = false;
  bool _listening = false;

  /// Oxirgi eshitilgan matn — tugma tagida ko'rsatiladi.
  String _heard = '';

  /// Shu tinglash seansida matn chaqiruvchiga BERILDIMI.
  ///
  /// 🔴 NEGA KERAK (egasi, qurilmada 2026-08-27: «ovoz eshitib matnga
  /// o'tkazyapti, lekin qidiruvga bermayapti»): natija FAQAT
  /// `result.finalResult` kelganda uzatilardi. Android nutq xizmati esa
  /// ko'p qurilmada yakuniy natijani YUBORMAYDI — jimlikni payqab
  /// `onStatus('done')` bilan to'xtaydi, xolos. Bunda `_heard` da matn
  /// TURARDI (odam uni ekranda ko'rardi ham), lekin u hech qayerga
  /// ketmasdi: qidiruv ishga tushmasdi va odam nima qilishini bilmasdi.
  ///
  /// Endi tinglash qanday tugashidan qat'i nazar matn uzatiladi, bu
  /// bayroq esa IKKI MARTA uzatilishini to'sadi (yakuniy natija kelgan
  /// holatda `onResult` ham, `onStatus` ham ishlaydi).
  bool _delivered = false;

  /// Jimlik payqalgach yakuniy natijani KUTADIGAN qisqa muhlat.
  ///
  /// ⚠️ NEGA DARHOL UZATMAYMIZ: `onStatus('notListening')` odatda yakuniy
  /// natijadan OLDIN keladi. Darhol uzatsak, yakuniy natija yuboradigan
  /// qurilmalarda ham doim ORALIQ matn ketardi — ya'ni bitta xatoni
  /// tuzatib, aniqlikni pasaytirgan bo'lardik. Yakuniy natija kelsa u
  /// darhol uzatiladi va bu taymer ortiqcha bo'lib qoladi.
  Timer? _deliverTimer;

  @override
  void dispose() {
    _deliverTimer?.cancel();
    // Ekrandan chiqilganda mikrofon ochiq qolmasin.
    if (_listening) _speech.cancel();
    super.dispose();
  }

  /// Nutqni tanish xizmatini tayyorlaydi. Ruxsat AYNAN SHU YERDA so'raladi.
  ///
  /// 🔴 NEGA `initState` DA EMAS (2026-08-24 da tuzatildi): `initialize`
  /// mikrofon ruxsatini DARHOL so'raydi (paket manbasida tekshirildi:
  /// `initializeIfPermitted` → `ActivityCompat.requestPermissions`). U ekran
  /// qurilganda chaqirilsa, odam ilovani ochishi bilan — hech qanday
  /// izohsiz — "mikrofonga ruxsat berasizmi?" oynasini ko'rardi. Bu
  /// cho'chitadi va Play ham bunday naqshni yoqtirmaydi.
  Future<bool> _prepare() async {
    if (_ready) return true;
    try {
      final ok = await _speech.initialize(
        onError: (_) => _stop(),
        onStatus: (status) {
          // Qurilma jimlikni o'zi payqab to'xtaydi — tugma "tinglayapti"
          // holatida qotib qolmasin.
          if (status == 'done' || status == 'notListening') _stop();
        },
        // Bluetooth mikrofoni bizga KERAK EMAS. Busiz paket
        // `BLUETOOTH_CONNECT` ruxsatini ham so'raydi — biz uni manifestda
        // e'lon qilmaganmiz va u shahar nomini aytishga aloqasi yo'q.
        options: [SpeechToText.androidNoBluetooth],
      );
      if (!mounted) return false;
      setState(() {
        _ready = ok;
        // Rad etilsa tugma boshqa ko'rinmaydi: har bosishda ruxsat oynasini
        // qayta chiqarish bezorilik.
        _available = ok;
      });
      return ok;
    } catch (_) {
      if (mounted) setState(() => _available = false);
      return false;
    }
  }

  void _stop() {
    if (mounted && _listening) setState(() => _listening = false);
    // Yakuniy natijaga qisqa imkoniyat beramiz (izohi `_deliverTimer` da).
    _deliverTimer?.cancel();
    _deliverTimer = Timer(const Duration(milliseconds: 700), _deliver);
  }

  /// Eshitilgani chaqiruvchiga beriladi — bir marta.
  ///
  /// Tinglash uch xil tugaydi: yakuniy natija, qurilma jimlikni payqashi
  /// (`onStatus`), yoki odam tugmani qayta bosishi. UCHALASIDA HAM odam
  /// gapirgan va natijani kutadi — shuning uchun uzatish shu yerda,
  /// bitta joyda turadi.
  void _deliver() {
    _deliverTimer?.cancel();
    if (_delivered) return;
    final trimmed = _heard.trim();
    if (trimmed.isEmpty) return;
    _delivered = true;
    widget.onResult(trimmed);
  }

  /// Interfeys tiliga eng mos qurilma tilini tanlaydi.
  ///
  /// Aniq mos kelmasa `null` — bu holda qurilma O'Z standart tilini oladi.
  /// Mavjud bo'lmagan til kodini majburlash tanishni butunlay yiqitadi.
  Future<String?> _localeId(Lang lang) async {
    final wanted = switch (lang) {
      Lang.ru => 'ru',
      Lang.en => 'en',
      Lang.uz => 'uz',
      Lang.uzCyrl => toCyrillic('uz'),
    };
    try {
      final locales = await _speech.locales();
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith(wanted)) return l.localeId;
      }
    } catch (_) {
      /* ro'yxat olinmasa — standart til */
    }
    return null;
  }

  Future<void> _toggle() async {
    if (_listening) {
      // Odam tugmani ATAYIN bosdi — ya'ni gapirib bo'ldi. Eshitilgani
      // tashlab yuborilmaydi (`_stop` uzatadi).
      await _speech.stop();
      _stop();
      return;
    }

    // Ruxsat shu yerda so'raladi — odam tugmani ATAYIN bosgan payt.
    if (!await _prepare()) return;
    if (!mounted) return;

    final lang = AppStrings.of(context).lang;
    final localeId = await _localeId(lang);
    if (!mounted) return;

    AppHaptics.select();
    setState(() {
      _listening = true;
      _heard = '';
      _delivered = false;
    });

    await _speech.listen(
      // Oraliq natija — odam gapirayotib matn paydo bo'lganini ko'radi.
      // Busiz tugma "tinglayapti" deb turadi-yu, hech nima o'zgarmaydi va
      // odam qayta bosadi (natijada tanish uziladi).
      onResult: (result) {
        if (!mounted) return;
        setState(() => _heard = result.recognizedWords);
        // Yakuniy natija kelsa DARHOL uzatamiz — muhlatni kutmaymiz.
        // Kelmasa `_stop` dagi taymer o'sha ishni bajaradi.
        if (result.finalResult) {
          if (mounted && _listening) setState(() => _listening = false);
          _deliver();
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        // Nutq qisqa (yo'nalish yoki e'lon) — diktovka rejimi kerak emas.
        listenMode: ListenMode.search,
        cancelOnError: true,
        // Jim turgandan 3 soniya keyin to'xtaydi — odam gapini tugatib
        // tugmani qayta bosishi shart emas. 12 soniya — yuqori chegara.
        autoPunctuation: false,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Xizmat yo'q yoki ruxsat berilmagan — o'lik tugma chizmaymiz.
    //
    // Boshida tugma KO'RINADI: xizmat borligini `initialize`siz bilib
    // bo'lmaydi, `initialize` esa ruxsat so'raydi. Ya'ni tanlov shunday
    // edi — yo ekran ochilishida ruxsat oynasi, yo bir marta bosilib
    // "ishlamadi" degan javob. Ikkinchisi kamroq zarar qiladi va bir
    // martadan keyin tugma butunlay yo'qoladi.
    if (!_available) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final label = _listening ? t.voiceListening : widget.hint;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Row(
        children: [
          /*
           * 🔴 RANG HOLATNI AYTADI, BEZAK EMAS (2026-09-02, «YO'L»).
           *
           * `IconButton.filledTonal` standart holda `secondaryContainer`
           * ni oladi — bu bizning temada PUSHTI tusli. Natijada mikrofon
           * tugmasi qidiruv ekranida asosiy «Qidirish» tugmasi bilan
           * bir xil e'tibor tortardi, holbuki u ikkinchi darajali yo'l.
           *
           * Endi: JIM turganda neytral, ESHITAYOTGANDA brend rangida.
           * Ya'ni pushti «hozir yozib olinyapti» degan ma'noni bildiradi.
           */
          IconButton.filledTonal(
            onPressed: _toggle,
            tooltip: widget.hint,
            isSelected: _listening,
            style: IconButton.styleFrom(
              backgroundColor: _listening
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: _listening
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            icon: Icon(_listening ? Icons.mic : Icons.mic_none),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: AnimatedSwitcher(
              // Reduce-motion'da almashinuv oniy: matn "suzib" o'tishi bu
              // yerda ma'no tashimaydi, faqat bezak.
              duration: AppMotion.on(context)
                  ? const Duration(milliseconds: 180)
                  : Duration.zero,
              child: Text(
                // Eshitilgan matn ustun: odam nima tushunilganini KO'RSIN.
                _heard.isNotEmpty ? _heard : label,
                key: ValueKey(_heard.isNotEmpty ? _heard : label),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _listening
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

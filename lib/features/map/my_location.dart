import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/dimens.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';

/// «MEN SHU YERDAMAN» — XARITADAGI JONLI NUQTA.
///
/// 🔴 NEGA UMUMIY FAYLGA CHIQDI (18.09.2026): bu mantiq safar marshruti
/// varag'ida ALLAQACHON bor edi (uch holatli tugma, GPS oqimi, kamera
/// ergashishi) — lekin FAQAT o'sha bitta ekranda. Bosh ekrandagi
/// xarita-birinchi ko'rinishda esa joylashuv BIR MARTA olinib, undan
/// faqat eng yaqin shahar nomi chiqarilardi: xaritada odamning O'ZI
/// yo'q edi.
///
/// Ikkinchi nusxa yozish o'rniga mantiq shu yerga ko'chirildi. Loyihada
/// bu xato takrorlangan: belgilar beshta xaritada beshta joyda
/// yasalardi va o'lchamlari har xil edi (`mapIcons` — saytda).
///
/// 🔑 UCH HOLAT (Yandex Go va umuman xaritalarning qoidasi):
///
///   o'chiq       → nuqta yo'q, GPS ishlamaydi
///   ergashmoqda  → nuqta bor, kamera uning ortidan yuradi
///   qo'yib yuborilgan → nuqta bor, kamera qimirlamaydi
///
/// Uchinchi holat SHART: xaritani qo'li bilan surgan odamni kamera
/// darhol orqaga tortib kelsa, xaritani ko'rib bo'lmaydi. Lekin nuqta
/// QOLADI — aks holda odam o'z joyini yo'qotib, GPS'ni qaytadan
/// yoqishga majbur bo'lardi.
///
/// 🔑 SAYTDAGI JUFTLIGI: `shared/ui/MyLocationLayer.tsx` — holatlar,
/// chegaralar va matnlar AYNAN bir xil.
class MyLocationController extends ChangeNotifier {
  MyLocationController({this.onPosition});

  /// Har yangi joyda chaqiriladi — ekranga xos hisob uchun (masalan
  /// «marshrutdan qancha qoldi»).
  final void Function(Position position)? onPosition;

  LatLng? _point;
  double? _heading;
  double? _accuracyM;
  bool _tracking = false;
  bool _following = false;
  StreamSubscription<Position>? _sub;

  /// Ruxsat so'rovi ketayotganini bildiradi.
  ///
  /// 🔴 NEGA KERAK (o'z kodimni ko'rib topdim, 18.09.2026): ruxsat
  /// oynasi ochilib turganda tugma yana bosilsa, [toggle] ikkinchi marta
  /// boshidan ketardi va IKKITA GPS oqimi ochilardi — ikkalasi ham
  /// kamerani surib, nuqta titrab turardi va batareya ikki barobar
  /// yeyilardi. Birinchi so'rov tugamaguncha ikkinchisi e'tiborsiz
  /// qoldiriladi.
  bool _starting = false;

  LatLng? get point => _point;

  /// Belgi yo'nalishi — kompas bermasa `null` (noto'g'ri yo'nalishdan
  /// ko'ra yo'qligi yaxshi).
  double? get heading => _heading;

  /// GPS aniqligi (metr) — nuqta atrofidagi doira radiusi.
  double? get accuracyM => _accuracyM;

  bool get tracking => _tracking;
  bool get following => _following;

  /// Tugma bosildi: o'chiq → ergashish → (surилgach) qaytarish → o'chiq.
  ///
  /// Ruxsat AYNAN SHU YERDA so'raladi — odam tugmani o'zi bosgan, ya'ni
  /// tizim oynasi kutilgan. Xarita ochilishi bilan so'rash bosqinchilik
  /// bo'lardi.
  Future<void> toggle(BuildContext context, {required MapController map}) async {
    if (_tracking && _following) {
      await stop();
      return;
    }
    if (_tracking && !_following) {
      _following = true;
      final p = _point;
      if (p != null) map.move(p, math.max(map.camera.zoom, 15));
      notifyListeners();
      return;
    }

    if (_starting) return;
    _starting = true;
    try {
      await _start(context, map);
    } finally {
      _starting = false;
    }
  }

  Future<void> _start(BuildContext context, MapController map) async {
    /*
     * 🔴 GPS O'CHIQ BO'LSA JIM QOLARDI (28.09.2026, egasi qurilmasida).
     * Ruxsat bor, lekin xizmat o'chiq — oqim darhol xato berardi va
     * pastdagi `onError: (_) {}` uni YUTARDI: tugma «kuzatyapman»
     * holatiga o'tardi-yu, nuqta hech qachon chiqmasdi.
     */
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!context.mounted) return;
      final t = AppStrings.of(context);
      showMessage(
        context,
        t.locationServiceOff,
        actionLabel: t.turnOn,
        onAction: Geolocator.openLocationSettings,
      );
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!context.mounted) return;
      // Rad etilsa JIM QOLMAYMIZ: tugma bosildi-yu hech nima bo'lmasa,
      // odam ilovani buzuq deb o'ylaydi (javob esa tizim sozlamasida).
      final t = AppStrings.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.locationDenied)));
      return;
    }

    _tracking = true;
    _following = true;
    notifyListeners();

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        // 10 metr: nuqta silliq siljisin, lekin turgan mashinada
        // bekorga yangilanmasin.
        distanceFilter: 10,
      ),
    ).listen(
      (p) => _onPosition(p, map),
      // Oqim yiqilsa (GPS yo'lda o'chirildi) — «kuzatyapman» holati
      // yolg'on qolmasin: tugma oddiy holatga qaytadi.
      onError: (_) {
        _tracking = false;
        _following = false;
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  void _onPosition(Position position, MapController map) {
    _point = LatLng(position.latitude, position.longitude);
    // Android kompas bermasa `-1` qaytaradi.
    _heading = (position.heading >= 0 && position.heading <= 360)
        ? position.heading
        : null;
    // Nol yoki manfiy aniqlik — fizik ma'nosiz qiymat: doira chizilmaydi.
    _accuracyM = position.accuracy > 0 ? position.accuracy : null;
    onPosition?.call(position);
    notifyListeners();
    if (_following) {
      /* Zum SAQLANADI: odam ko'chani ko'rish uchun yaqinlashtirgan
         bo'lsa, har GPS javobida uni orqaga tortib olish — qo'lidan
         xaritani tortib olish bilan barobar. */
      map.move(_point!, math.max(map.camera.zoom, 15));
    }
  }

  /// Xarita QO'L bilan surildi — ergashish to'xtaydi, nuqta QOLADI.
  ///
  /// ⚠️ Chaqiruvchi `hasGesture` ni tekshirishi SHART: `map.move` ning
  /// o'zi ham xarita hodisasini qo'zg'atadi va usiz ergashish birinchi
  /// nuqtadayoq o'zini o'chirib qo'yardi.
  void releaseCamera() {
    if (!_following) return;
    _following = false;
    notifyListeners();
  }

  /// GPS'ni QO'YIB YUBORADI — ekran yopilganda shart.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _tracking = false;
    _following = false;
    _point = null;
    _heading = null;
    _accuracyM = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Xarita qatlamlari: ANIQLIK DOIRASI + ko'k nuqta.
///
/// 🔑 DOIRA METRDA (piksel emas) — zum bilan birga o'sadi va YOLG'ONNI
/// TO'SADI: GPS binolar orasida 50 metrgacha xato qiladi, doirasiz nuqta
/// esa «men AYNAN shu yerdaman» deb turadi.
///
/// Ro'yxat bo'lib qaytadi: doira belgilarning OSTIDA, nuqta esa ENG
/// USTIDA turishi kerak — chaqiruvchi ularni kerakli joyga qo'yadi.
List<Widget> myLocationLayers(BuildContext context, MyLocationController ctl) {
  final p = ctl.point;
  if (!ctl.tracking || p == null) return const [];
  final scheme = Theme.of(context).colorScheme;
  final accuracy = ctl.accuracyM;
  return [
    if (accuracy != null)
      CircleLayer(
        circles: [
          CircleMarker(
            point: p,
            radius: accuracy,
            useRadiusInMeter: true,
            color: scheme.primary.withValues(alpha: 0.12),
            borderColor: scheme.primary.withValues(alpha: 0.40),
            borderStrokeWidth: 1,
          ),
        ],
      ),
    MarkerLayer(
      markers: [
        Marker(
          point: p,
          width: 40,
          height: 40,
          // ⚠️ Buriladigan belgi nuqtaning O'ZIDA turadi (pastki uchida
          // emas): u yo'nalish ko'rsatadi, joy belgisi emas.
          alignment: Alignment.center,
          child: _MeDot(heading: ctl.heading),
        ),
      ],
    ),
  ];
}

/// Belgi — marshrut nuqtalaridan SHAKLI bilan ajraladi (rang yetarli
/// emas: xarita foni har xil bo'ladi).
class _MeDot extends StatelessWidget {
  const _MeDot({this.heading});

  final double? heading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glyph = Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.onPrimary, width: 2),
      ),
      child: Icon(Icons.navigation, color: scheme.onPrimary, size: 16),
    );
    if (heading == null) return Center(child: glyph);
    return Center(
      child: Transform.rotate(angle: heading! * math.pi / 180, child: glyph),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../core/cities.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import 'map_tiles.dart';
import '../../../app/dimens.dart';

/// Xaritadan aniq nuqta tanlash.
///
/// `core/cities.dart` ro'yxati (shahar + tuman) shaharlararo qidiruv uchun
/// yetadi, lekin uchrashuv joyi ("metro yonida") kabi aniq nuqtalar uchun
/// yetmaydi — bu ekran shuning uchun.
///
/// Natija — `Place`: nomi teskari geokoderdan olinadi, topilmasa eng yaqin
/// ma'lum joy nomi ishlatiladi.
Future<Place?> showLocationPicker(
  BuildContext context, {
  Place? initial,
  String? title,
}) {
  // `rootNavigator: true` — aks holda ekran pastki navigatsiya SHELLI ichida
  // ochiladi va xarita ustida "Qidirish/Safarlarim/..." tugmalari qolib
  // ketadi: foydalanuvchi joy tanlash yarmida boshqa bo'limga o'tib,
  // oqim osilib qolardi (jonli tekshiruvda ko'rilgan).
  return Navigator.of(context, rootNavigator: true).push<Place>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PickLocationScreen(initial: initial, title: title),
    ),
  );
}

class PickLocationScreen extends ConsumerStatefulWidget {
  const PickLocationScreen({super.key, this.initial, this.title});

  final Place? initial;
  final String? title;

  @override
  ConsumerState<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends ConsumerState<PickLocationScreen> {
  final _map = MapController();

  /// Markaz — Toshkent (ro'yxatdagi birinchi joy), boshlang'ich berilmasa.
  late LatLng _target = widget.initial != null
      ? LatLng(widget.initial!.lat, widget.initial!.lon)
      : LatLng(kPlaces.first.lat, kPlaces.first.lon);

  String? _label;
  bool _resolving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _label = widget.initial?.name;
    if (widget.initial == null) _resolveLabel();
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  /// Xarita to'xtagach markazdagi nuqtaning nomini aniqlaymiz.
  ///
  /// Teskari geokoder tarmoqqa chiqadi va sekin — har kadrga emas, FAQAT
  /// harakat tugagach chaqiriladi (`onMapEvent` + `hasGesture` tekshiruvi).
  Future<void> _resolveLabel() async {
    setState(() => _resolving = true);
    final name = await ref
        .read(geocoderProvider)
        .reverse(_target.latitude, _target.longitude);
    if (!mounted) return;
    setState(() {
      _label = name;
      _resolving = false;
    });
  }

  Future<void> _goToMyLocation() async {
    final t = AppStrings.of(context);
    setState(() => _locating = true);
    try {
      /*
       * 🔴 GPS O'CHIQ BO'LSA JIM QOLARDI (28.09.2026, egasi qurilmasida).
       * Tizim «joylashuvni yoqing» oynasini ko'rsatardi; «Kerak emas»
       * bosilgach tugma hech narsa demasdi. Endi sabab va bir bosishli
       * yechim aytiladi.
       */
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
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
        if (!mounted) return;
        showMessage(context, t.locationDenied);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      _target = LatLng(position.latitude, position.longitude);
      _map.move(_target, 15);
      await _resolveLabel();
    } catch (_) {
      if (!mounted) return;
      showMessage(context, t.locationFailed);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final name = _label;
    if (name == null || name.isEmpty) return;
    Navigator.of(context).pop(
      Place(
        name: name,
        lat: _target.latitude,
        lon: _target.longitude,
        region: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? t.pickOnMap)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _target,
                    initialZoom: widget.initial != null ? 13 : 11,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapEvent: (event) {
                      // Faqat foydalanuvchi harakati tugaganda — dastur o'zi
                      // qilgan `move` (masalan "mening joylashuvim") teskari
                      // geokoderni ikkinchi marta chaqirmasin.
                      if (event is MapEventMoveEnd &&
                          event.source != MapEventSource.mapController) {
                        _target = event.camera.center;
                        _resolveLabel();
                      }
                    },
                  ),
                  children: const [MapTiles()],
                ),
                // Nishon xarita markazida turadi — marker sudralmaydi, xarita
                // suriladi (mobil xaritalarda odatiy va barmoq bilan qulayroq).
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Icon(
                      Icons.place,
                      size: 44,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'my-location',
                    onPressed: _locating ? null : _goToMyLocation,
                    tooltip: t.myLocation,
                    child: _locating
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          const OsmAttribution(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _resolving ? t.loading : (_label ?? t.placeUnknown),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.md),
                  FilledButton(
                    onPressed: (_resolving || _label == null) ? null : _confirm,
                    child: Text(t.confirmLocation),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

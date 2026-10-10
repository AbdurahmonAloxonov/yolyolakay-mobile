import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/dimens.dart';
import 'map_tiles.dart';

/// BITTA NUQTA xaritada — chatda ulashilgan joy uchun.
///
/// `RoutePreviewMap` dan farqi: u YO'LNI ko'rsatadi (ikki va undan ko'p
/// nuqta), bu esa BITTA joyni. Shakli ham boshqacha: yo'l chizig'i emas,
/// nishon (`place`) — bu «shu yerga kel» degani, «shu yo'ldan boramiz»
/// emas.
///
/// Tinch: barmoq harakatini o'ziga olmaydi, chunki chat ro'yxati ichida
/// turadi va suhbatni sudrab bo'lmay qolardi.
class PointPreviewMap extends StatelessWidget {
  const PointPreviewMap({
    super.key,
    required this.point,
    this.height = 130,
    this.onTap,
    this.semanticLabel,
  });

  final LatLng point;
  final double height;
  final VoidCallback? onTap;

  /// Ekran o'qigich uchun nom. Xarita — rasm, TalkBack uning ichidan
  /// o'qiydigan hech nima topa olmaydi va `onTap` bo'lsa u «nomsiz
  /// tugma» bo'lib qolardi (qo'riqchi sinov buni tutadi).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final map = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                const MapTiles(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.place,
                        size: 34,
                        color: scheme.error,
                        shadows: const [
                          Shadow(color: Colors.white, blurRadius: 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // OSM litsenziyasi (ODbL) attributsiyani TALAB qiladi.
            Positioned(
              right: AppSpace.xs,
              bottom: AppSpace.xxs,
              child: const MapAttributionBadge(),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return map;
    return Semantics(
      button: true,
      label: semanticLabel,
      // Ichki tafsilotlar yashiriladi: aks holda o'qigich o'nlab
      // ma'nosiz tugunni sanab chiqardi.
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: map,
        ),
      ),
    );
  }
}

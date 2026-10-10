import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:yolyolakay/features/map/road_route.dart';
import 'package:yolyolakay/features/map/route_line.dart';

/// 🔴 NEGA (28.09.2026, egasi: «xaritada to'g'ri chiziqlarmi, rasvo»).
///
/// Backend yo'lni to'g'ri berardi (jonli: Toshkent–Samarqand 3398 nuqta,
/// 2.4 s), lekin ilova:
///   • har ochilishda qayta so'rardi va shu soniyalarda TO'G'RI CHIZIQ
///     turardi (kichik karta + varaq = bir safarga ikki so'rov);
///   • bekatli marshrut bo'laklarini KETMA-KET so'rardi;
///   • to'g'ri chiziqni haqiqiy yo'l bilan BIR XIL uslubda chizardi.
void main() {
  const tashkent = LatLng(41.2995, 69.2401);
  const jizzax = LatLng(40.1158, 67.8422);
  const samarqand = LatLng(39.6542, 66.9597);

  setUp(clearRoadRouteCache);

  Map<String, dynamic> road(double lat1, double lon1, double lat2, double lon2) => {
    'geometry': [
      {'latitude': lat1, 'longitude': lon1},
      {'latitude': (lat1 + lat2) / 2 + 0.1, 'longitude': (lon1 + lon2) / 2},
      {'latitude': lat2, 'longitude': lon2},
    ],
    'distance': 100000,
    'duration': 3600,
  };

  test('bir yo\'nalish BIR MARTA so\'raladi — hatto bir vaqtda ham', () async {
    final adapter = _Adapter((q) => road(
      q['origin_lat'], q['origin_lon'], q['dest_lat'], q['dest_lon']));
    final dio = Dio()..httpClientAdapter = adapter;

    final both = await Future.wait([
      fetchRoadRoute([tashkent, samarqand], dio: dio),
      fetchRoadRoute([tashkent, samarqand], dio: dio),
    ]);
    await fetchRoadRoute([tashkent, samarqand], dio: dio);

    expect(adapter.calls, 1);
    expect(both.every((r) => r.isRealRoad), isTrue);
    // Keyingi ochilishda KUTMASDAN.
    expect(cachedRoadRoute([tashkent, samarqand])?.isRealRoad, isTrue);
  });

  test('bekat bo\'laklari PARALLEL so\'raladi va ulanadi', () async {
    final adapter = _Adapter(
      (q) => road(q['origin_lat'], q['origin_lon'], q['dest_lat'], q['dest_lon']),
      delay: const Duration(milliseconds: 200),
    );
    final dio = Dio()..httpClientAdapter = adapter;

    final watch = Stopwatch()..start();
    final r = await fetchRoadRoute([tashkent, jizzax, samarqand], dio: dio);
    watch.stop();

    expect(adapter.calls, 2);
    expect(adapter.maxInFlight, 2, reason: 'ketma-ket emas, birga');
    expect(r.isRealRoad, isTrue);
    // 3 + 3 nuqta, ulanishdagi takror olib tashlanadi.
    expect(r.points.length, 5);
    expect(r.distanceMeters, 200000);
  });

  test('yiqilgan so\'rov KESHLANMAYDI — keyingi safar qayta uriniladi', () async {
    var fail = true;
    final adapter = _Adapter((q) => fail
        ? null
        : road(q['origin_lat'], q['origin_lon'], q['dest_lat'], q['dest_lon']));
    final dio = Dio()..httpClientAdapter = adapter;

    final first = await fetchRoadRoute([tashkent, samarqand], dio: dio);
    expect(first.isRealRoad, isFalse);
    expect(cachedRoadRoute([tashkent, samarqand]), isNull);

    fail = false;
    final second = await fetchRoadRoute([tashkent, samarqand], dio: dio);
    expect(second.isRealRoad, isTrue);
    expect(adapter.calls, 2);
  });

  test('bir bo\'lak yiqilsa marshrut HAQIQIY deb ko\'rsatilmaydi', () async {
    final adapter = _Adapter((q) => q['dest_lat'] == jizzax.latitude
        ? road(q['origin_lat'], q['origin_lon'], q['dest_lat'], q['dest_lon'])
        : null);
    final dio = Dio()..httpClientAdapter = adapter;

    final r = await fetchRoadRoute([tashkent, jizzax, samarqand], dio: dio);
    expect(r.isRealRoad, isFalse);
  });

  group('chiziq uslubi', () {
    const straight = [tashkent, samarqand];

    test('yo\'l yo\'q — UZUQ va xira', () {
      final lines = routePolylines(
        straight: straight,
        route: null,
        color: Colors.pink,
      );
      expect(lines, hasLength(1));
      expect(lines.single.pattern.segments, isNotNull);
      expect(lines.single.color.a, lessThan(1));
    });

    test('taxminiy javob (yiqilgan) ham UZUQ', () {
      final lines = routePolylines(
        straight: straight,
        route: const RoadRoute(points: straight),
        color: Colors.pink,
      );
      expect(lines.single.pattern.segments, isNotNull);
    });

    test('haqiqiy yo\'l — YAXLIT', () {
      final lines = routePolylines(
        straight: straight,
        route: const RoadRoute(
          points: [tashkent, jizzax, samarqand],
          distanceMeters: 300000,
        ),
        color: Colors.pink,
      );
      expect(lines.single.pattern, const StrokePattern.solid());
      expect(lines.single.points, hasLength(3));
    });
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond, {this.delay = Duration.zero});

  final Map<String, dynamic>? Function(Map<String, dynamic> query) respond;
  final Duration delay;
  int calls = 0;
  int _inFlight = 0;
  int maxInFlight = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    _inFlight++;
    if (_inFlight > maxInFlight) maxInFlight = _inFlight;
    await Future<void>.delayed(delay);
    _inFlight--;
    final body = respond(options.queryParameters);
    if (body == null) {
      return ResponseBody.fromString('{"error":"no route"}', 500,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
    }
    return ResponseBody.fromString(jsonEncode(body), 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
}

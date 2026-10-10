import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolyolakay/core/api/api_client.dart';
import 'package:yolyolakay/core/api/token_storage.dart';
import 'package:yolyolakay/core/car_moderation_watch.dart';
import 'package:yolyolakay/data/models/user.dart';
import 'package:yolyolakay/data/repositories/users_repository.dart';

/// MASHINA MODERATSIYASI KUZATUVCHISI.
///
/// 🔴 NEGA TEST: bu funksiya BILDIRISHNOMA yuboradi — `route_watch_test`
/// dagi bilan bir xil sabab. Noto'g'ri xabar bergan ilova o'chiriladi va
/// keyin biz odamni HECH QACHON chaqira olmaymiz. Shuning uchun eng
/// muhim tekshiruv «xabar keldimi» emas, **KELMASLIGI kerak bo'lganda
/// kelmadimi**.
///
/// Ikkita eng xavfli holat:
///   1. birinchi ko'rish — mashina ALLAQACHON tasdiqlangan bo'lsa ham
///      «tasdiqlandi» deb xabar berish (o'zgarish yo'q joyda xabar);
///   2. kutilayotgan mashina yo'q bo'lsa ham serverga so'rov yuborish
///      (har qaytishda ortiqcha chaqiruv — backend har biriga ~0.7 s).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Yuborilgan xabarlar — kuzatuvchiga PLAGIN emas, AMAL beriladi
  /// (izohi `CarModerationWatcher.notify` da), shuning uchun uni shu
  /// yerda ushlab qolish yetadi: platforma kanali umuman chaqirilmaydi.
  final shown = <({String title, String body})>[];

  /// `GET /users/me` javobini beradigan soxta adapter. So'rovlar SANALADI:
  /// «kerak bo'lmasa tarmoqqa chiqmaydi» qoidasini shu bilan o'lchaymiz.
  late int requests;
  late List<Map<String, dynamic>> cars;

  UsersRepository repo() {
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _FakeAdapter(
      onFetch: () => requests++,
      body: () => {
        'data': {
          'user': {'id': 'u1', 'phone_number': '+998900000000'},
          'cars': cars,
        },
      },
    );
    return UsersRepository(client);
  }

  CarModerationWatcher watcher(SharedPreferences prefs) => CarModerationWatcher(
    prefs: prefs,
    users: repo(),
    notify: (id, title, body) async => shown.add((title: title, body: body)),
    approvedTitle: 'Tasdiqlandi',
    approvedBody: (p) => '$p — endi e\'lon bera olasiz',
    rejectedTitle: 'Qaytarildi',
    rejectedBody: (p) => '$p — qayta yuklang',
  );

  Map<String, dynamic> car(String id, String status) => {
    'id': id,
    'brand': 'Chevrolet',
    'model': 'Cobalt',
    'gov_number': '01 A 123 BC',
    'moderation_status': status,
  };

  Car model(String id, String status) => Car(
    id: id,
    brand: 'Chevrolet',
    model: 'Cobalt',
    govNumber: '01 A 123 BC',
    moderationStatus: status,
  );

  setUp(() async {
    shown.clear();
    requests = 0;
    cars = [];
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('kutilayotgan mashina YO\'Q — serverga umuman chiqmaydi', () async {
    final prefs = await SharedPreferences.getInstance();
    final w = watcher(prefs);
    await w.remember([model('c1', 'approved')]);

    expect(await w.check(), isFalse);
    expect(requests, 0, reason: 'ortiqcha so\'rov ketmasligi kerak');
    expect(shown, isEmpty);
  });

  test('BIRINCHI ko\'rishda xabar bermaydi (tasdiqlangan mashina ham)',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final w = watcher(prefs);
    // Hech narsa eslanmagan, lekin ro'yxatda kutilayotgani bor deb
    // o'ylaymiz: avval `pending` yozamiz, keyin BOSHQA mashina qo'shilgan
    // holatni serverdan olamiz.
    await w.remember([model('c1', 'pending')]);
    cars = [car('c1', 'pending'), car('c2', 'approved')];

    expect(await w.check(), isFalse);
    expect(shown, isEmpty, reason: 'yangi mashina uchun xabar berilmaydi');
  });

  test('pending → approved: BITTA xabar, matnida davlat raqami', () async {
    final prefs = await SharedPreferences.getInstance();
    final w = watcher(prefs);
    await w.remember([model('c1', 'pending')]);
    cars = [car('c1', 'approved')];

    expect(await w.check(), isTrue);
    expect(shown, hasLength(1));
    expect(shown.first.title, 'Tasdiqlandi');
    expect(shown.first.body, contains('01 A 123 BC'));
  });

  test('xabar IKKINCHI marta takrorlanmaydi', () async {
    final prefs = await SharedPreferences.getInstance();
    final w = watcher(prefs);
    await w.remember([model('c1', 'pending')]);
    cars = [car('c1', 'approved')];

    await w.check();
    shown.clear();
    // Ikkinchi qaytishda holat allaqachon `approved` — na so'rov, na xabar.
    expect(await w.check(), isFalse);
    expect(shown, isEmpty);
    expect(requests, 1);
  });

  test('pending → rejected ham aytiladi', () async {
    final prefs = await SharedPreferences.getInstance();
    final w = watcher(prefs);
    await w.remember([model('c1', 'pending')]);
    cars = [car('c1', 'rejected')];

    expect(await w.check(), isTrue);
    expect(shown.single.title, 'Qaytarildi');
  });

  test('server javob bermasa JIM o\'tadi', () async {
    final prefs = await SharedPreferences.getInstance();
    final client = ApiClient(tokens: TokenStorage());
    client.dio.httpClientAdapter = _FakeAdapter(
      onFetch: () => requests++,
      body: () => throw const SocketExceptionLike(),
    );
    final w = CarModerationWatcher(
      prefs: prefs,
      users: UsersRepository(client),
      notify: (id, title, body) async => shown.add((title: title, body: body)),
      approvedTitle: 'Tasdiqlandi',
      approvedBody: (p) => p,
      rejectedTitle: 'Qaytarildi',
      rejectedBody: (p) => p,
    );
    await w.remember([model('c1', 'pending')]);

    expect(await w.check(), isFalse);
    expect(shown, isEmpty);
  });
}

/// Tarmoqqa chiqmaydigan adapter.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.onFetch, required this.body});

  final void Function() onFetch;
  final Map<String, dynamic> Function() body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onFetch();
    return ResponseBody.fromString(
      jsonEncode(body()),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// «Server javob bermadi» ni taqlid qiladi — haqiqiy `SocketException`
/// import qilmaslik uchun (`dart:io` testda ortiqcha bog'liqlik).
class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}

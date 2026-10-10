import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../format.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../env.dart';
import 'token_storage.dart';

/// WS'dan kelgan hodisa.
///
/// Jonli backend (monolit) BARCHA real-time xabarlarni bitta shaklda yuboradi:
/// `{type: "notification", title, body}`. Boy strukturali hodisalar
/// (NEW_BOOKING, COUNTER_OFFER...) Centrifugo orqali rejalashtirilgan, u hali
/// deploy qilinmagan — YETIB KELMAYDI. Shu sabab noma'lum `type` ham
/// yiqilmasdan, umumiy ko'rinishda ishlanadi.
class WsEvent {
  const WsEvent({
    required this.type,
    this.title,
    this.body,
    this.raw = const {},
  });

  final String type;
  final String? title;
  final String? body;
  final Map<String, dynamic> raw;

  /// Yangi chat xabari.
  ///
  /// Backend ikki xil shaklda yuboradi (chat swaggerda yo'q, shakl faqat jonli
  /// kuzatishdan ma'lum): eskisi `{type: "NEW_MESSAGE", payload: {...}}`,
  /// 2026-08-12 dan esa `{event: "new_message", data: {...}}` — endi jo'natuvchining
  /// O'ZIGA ham qaytariladi (yetkazilgani tasdig'i sifatida). Registrni ham
  /// solishtirmaymiz: ikkalasi ham qabul qilinadi.
  bool get isNewMessage => type.toUpperCase() == 'NEW_MESSAGE';

  /// "Suhbatdosh yozmoqda" hodisasi. Server bu kadrni retranslatsiya qilса
  /// ishlaydi; qilmаса — hech qachon kelmaydi va "yozmoqda" ko'rinmaydi
  /// (zararsiz). Xat 2026-08-21 da shu shakl so'ralgan.
  bool get isTyping => type.toUpperCase() == 'TYPING';

  /// Suhbatdosh MENING xabarларимни o'qiди — jo'natuvchiга keladi. Ikki
  /// galochкани darhol chizish uchun (backend xati 2026-08-20 qo'shди).
  bool get isMessagesRead => type.toUpperCase() == 'MESSAGES_READ';

  /// `messages_read` dagi o'qilган xabar id'lari.
  List<String> get readMessageIds {
    final raw = _payload['message_ids'];
    if (raw is! List) return const [];
    return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
  }

  /// Hodisa tanasi: `payload` (eski shakl) yoki `data` (yangi shakl).
  Map<String, dynamic> get _payload {
    final message = raw['payload'] ?? raw['data'];
    return message is Map ? message.cast<String, dynamic>() : const {};
  }

  /// Xabarni KIM yubordi.
  ///
  /// Backend xati 2026-08-13 tasdiqladi: `sender_id` doim keladi — o'z
  /// xabarimizning aks-sadosida ham. Bu bizga kerak, chunki o'zimiz yozgan
  /// xabar uchun bildirishnoma chiqarish mantiqsiz.
  String? get senderId {
    final value = _payload['sender_id'];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Xabar shu foydalanuvchining O'ZIDAN kelganmi (server aks-sadosi).
  ///
  /// 🔴 Egasi qurilmada topdi (2026-08-13): xabar YOZGANDA ham tepadan
  /// bildirishnoma tushardi. Sabab — server jo'natuvchiga xabarni yetkazilgani
  /// tasdig'i sifatida qaytaradi, biz esa uni "yangi xabar keldi" deb
  /// ko'rsatardik. Bildirishnoma faqat SUHBATDOSHDAN kelgan xabarga chiqadi.
  bool isEchoOf(String? myUserId) =>
      isNewMessage &&
      myUserId != null &&
      myUserId.isNotEmpty &&
      senderId == myUserId;

  /// Ko'rsatish uchun matn — qaysi maydon kelganiga qarab.
  ///
  /// Matn ALLAQACHON toza: kadr `tryParse` da bir marta ochib olinadi
  /// (`deepUnescape`). Bu yerda IKKINCHI marta ochish mumkin emas —
  /// foydalanuvchi chindan yozgan `&amp;` buziladi.
  String get displayText {
    if (title != null && title!.isNotEmpty) return title!;
    if (body != null && body!.isNotEmpty) return body!;
    // `payload` (eski shakl) yoki `data` (yangi shakl).
    final message = raw['payload'] ?? raw['data'];
    if (message is Map) {
      for (final key in ['message', 'content', 'body']) {
        final value = message[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return type;
  }

  /// Hodisani PUSH ma'lumoti shakliga keltiradi — bannerni bosganda qayerga
  /// o'tishni `pushTargetFor` shu ko'rinishdan hisoblaydi.
  ///
  /// Ikkala kanal (WS va push) bitta manzil jadvaliga tayanishi kerak, aks
  /// holda bitta hodisa ochiq ilovada bir joyga, yopiq ilovada boshqa joyga
  /// olib borardi.
  Map<String, dynamic> get pushData => {
    'type': type,
    if (senderId != null) 'peer_id': senderId,
    for (final key in ['ride_id', 'booking_id', 'parcel_id'])
      if (_payload[key] != null) key: '${_payload[key]}',
  };

  static WsEvent? tryParse(dynamic frame) {
    try {
      // HTTP javoblari kabi WS kadri ham apostrof/qo'shtirnoqni HTML
      // kodida olib keladi (`so&#39;m`). Ochish SHU YERDA — ko'rsatishda
      // emas: aks holda har yangi ko'rsatish joyida yana unutilardi.
      final decoded = deepUnescape(jsonDecode(frame as String));
      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      // `type` (eski shakl) yoki `event` (yangi shakl). Ilgari faqat `type`
      // o'qilardi va yangi shakldagi kadr JIM tashlab yuborilardi — ochiq
      // turgan suhbatga kelgan xabar ekranda umuman ko'rinmasdi.
      final rawType = map['type'] ?? map['event'];
      if (rawType is! String || rawType.isEmpty) return null;
      return WsEvent(
        type: rawType,
        title: map['title'] as String?,
        body: map['body'] as String?,
        raw: map,
      );
    } catch (_) {
      return null; // yaroqsiz kadr — e'tiborsiz
    }
  }
}

/// Doimiy WS ulanish: uzilsa 5 soniyadan keyin qayta ulanadi.
///
/// Token HAR ulanishda qaytadan o'qiladi — refresh'dan keyin reconnect eski
/// token bilan cheksiz aylanmasligi uchun.
class WsClient {
  WsClient(this._tokens);

  final TokenStorage _tokens;

  final _events = StreamController<WsEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;

  Stream<WsEvent> get events => _events.stream;

  bool get isConnected => _channel != null;

  /// Ulanish HAQIQATAN ochilganmi.
  ///
  /// 🔴 [isConnected] dan farqi: u `_channel != null` ni tekshiradi, ya'ni
  /// handshake hali tugamagan (yoki yiqilgan) kanalni ham "ulangan" deb
  /// ko'rsatadi. Offline navbat aynan shu farqда yanglishardi: xabar
  /// "yuborildi" deb belgilanib, aslida hech qayerga bormasdi.
  ///
  /// `ValueNotifier` — `ApiClient.connected` bilan bir uslub: tinglovchi
  /// (offline navbat) Riverpod'siz ulanadi.
  final ValueNotifier<bool> online = ValueNotifier<bool>(false);

  void connect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    final token = _tokens.access;
    if (token == null || token.isEmpty) {
      _scheduleReconnect();
      return;
    }

    try {
      final separator = Env.wsUrl.contains('?') ? '&' : '?';
      final uri = Uri.parse('${Env.wsUrl}${separator}token=$token');
      _channel = WebSocketChannel.connect(uri);

      // 🔴 2026-08-07, JONLI QURILMADA TOPILDI: `connect()` SINXRON qaytadi va
      // handshake xatosi `ready` future'ida chiqadi. U kuzatilmagani uchun Dart
      // uni "Unhandled Exception" deb har qayta ulanishda logga tashlardi —
      // telefonda har ~5.5 soniyada, cheksiz (batareya + shovqin).
      //
      // Xatoni SHU YERDA yutamiz: qayta ulanishni `stream.listen(onError:)`
      // allaqachon boshqaradi, bizga faqat "unhandled" bo'lmasligi kerak.
      unawaited(
        _channel!.ready
            .then((_) {
              if (!_disposed) online.value = true;
            })
            .catchError((Object _) {
              online.value = false;
            }),
      );
    } catch (_) {
      _scheduleReconnect();
      return;
    }

    _subscription = _channel!.stream.listen(
      (frame) {
        final event = WsEvent.tryParse(frame);
        if (event != null) _events.add(event);
      },
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
      cancelOnError: true,
    );
  }

  /// Xabar yuborish — chat uchun REST endpoint YO'Q, faqat shu yo'l.
  ///
  /// 🔴 2026-08-12, backend logi bilan topildi: server `receiver_id` ni o'qiydi,
  /// biz esa `recipient_id` yuborardik. Ya'ni ID YO'QOLMAGAN — kalit nomi boshqa
  /// edi. Server bo'sh satrni ko'rib (`invalid UUID length: 0`) xabarni RAD
  /// ETARDI: u navbatga ham, bazaga ham tushmasdi. Shuning uchun chatga qayta
  /// kirilganda yozishma "yo'qolib" qolardi — u hech qachon saqlanmagan edi.
  ///
  /// IKKALA kalit ham yuboriladi: chat swaggerda UMUMAN yo'q (xat №7), ya'ni
  /// eski gateway hali qayerdadir `recipient_id` kutayotgan bo'lsa ham buzilmaydi.
  /// Ortiqcha kalit Go'da e'tiborsiz qoldiriladi.
  ///
  /// `false` qaytsa xabar KETMAGAN — chaqiruvchi buni odamga aytishi shart.
  bool sendMessage({
    required String recipientId,
    required String content,
    String? rideId,
  }) {
    final channel = _channel;
    if (channel == null) return false;
    // Bo'sh ID bilan yuborishning ma'nosi yo'q: server baribir rad etadi, biz esa
    // ekranda "ketdi" deb ko'rsatib, odamni aldab qo'yardik.
    if (recipientId.isEmpty) return false;
    channel.sink.add(
      jsonEncode(
        buildSendMessagePayload(
          recipientId: recipientId,
          content: content,
          rideId: rideId,
        ),
      ),
    );
    return true;
  }

  /// Xabarlarni "o'qildi" deb belgilaydi (WS orqali).
  ///
  /// 🔴 Backend xati 2026-08-19 aniq shaklni berdi:
  ///   {"event":"mark_as_read","data":{"message_ids":["uuid", ...]}}
  /// Ack QAYTMAYDI (server jim belgilaydi), chet/mavjud bo'lmagan id jim
  /// e'tiborsiz qoldiriladi — shuning uchun javob kutmaymiz, natijani
  /// darhol lokal yangilaymiz. Bo'sh ro'yxatda kadr YUBORILMAYDI.
  bool markAsRead(List<String> messageIds) {
    final channel = _channel;
    if (channel == null || messageIds.isEmpty) return false;
    channel.sink.add(jsonEncode(buildMarkAsReadPayload(messageIds)));
    return true;
  }

  /// "Yozmoqda" signalини yuboradi (WS orqali, bazaga yozilmaydi).
  ///
  /// Server bu kadrni suhbatdoshга retranslatsiya qilса — u "yozmoqda"
  /// ko'radi. Qilmаса hech nima buzilmaydi. Chaqiruvchi buni CHEKLAB
  /// (masalan 3 soniyada bir marta) yuborishi kerak — har harfда emas.
  bool sendTyping(String recipientId) {
    final channel = _channel;
    if (channel == null || recipientId.isEmpty) return false;
    channel.sink.add(jsonEncode(buildTypingPayload(recipientId)));
    return true;
  }

  static Map<String, dynamic> buildTypingPayload(String recipientId) => {
    'event': 'typing',
    'data': {'receiver_id': recipientId, 'recipient_id': recipientId},
  };

  /// Kadr shakli — `send_message` bilan bir xil sabab: xato kalit nomida
  /// bo'lishi mumkin, shuning uchun test bilan mahkamlanadi.
  static Map<String, dynamic> buildMarkAsReadPayload(List<String> ids) => {
    'event': 'mark_as_read',
    'data': {'message_ids': ids},
  };

  /// Yuboriladigan kadr — soketdan AJRATILGAN, chunki xato aynan shu yerda
  /// (kalit nomida) bo'lgan edi va uni test bilan mahkamlash kerak.
  static Map<String, dynamic> buildSendMessagePayload({
    required String recipientId,
    required String content,
    String? rideId,
  }) => {
    'event': 'send_message',
    'data': {
      'receiver_id': recipientId,
      'recipient_id': recipientId,
      'content': content,
      'ride_id': ?rideId,
    },
  };

  void _scheduleReconnect() {
    online.value = false;
    _cleanupSocket();
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  void _cleanupSocket() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {
      // allaqachon yopilgan
    }
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _cleanupSocket();
    _events.close();
    online.dispose();
  }
}

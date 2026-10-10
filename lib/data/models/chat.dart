import '../../core/api/api_client.dart' show asMap;
import '../../core/json.dart';

/// ⚠ Nomlanish chalkash (backend shunday):
///   GET /notifications         -> TIZIM bildirishnomalari (NotificationItem)
///   GET /notifications/history -> CHAT tarixi (ChatMessage)
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.type,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? type;
  final DateTime? createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: asString(json['id']),
        title: asString(json['title']),
        body: asString(json['body']),
        isRead: asBool(json['is_read']),
        type: asStringOrNull(json['type']),
        createdAt: asDate(json['created_at']),
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.rideId,
    this.createdAt,
    this.isRead = false,
    this.failed = false,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? rideId;
  final DateTime? createdAt;

  /// Xabar YUBORILMADI (soket yopiq edi) — ro'yxatда qizil "!" bilan
  /// turadi, bosilса qayta yuboriladi. Faqat lokal echo'да ma'noli.
  final bool failed;

  /// Suhbatdosh xabarni o'qiganmi — o'z xabarim ostidagi IKKI galochka uchun.
  ///
  /// 🔴 Backend qaysi nomда qaytarishi NOMA'LUM (chat swaggerda yo'q, xat
  /// 2026-08-21 javobsiz), shu sabab bir necha ehtimolni tekshiramiz.
  /// Hech qaysisi bo'lmasa `false` — o'sha holда faqat "yuborildi" (bitta
  /// galochka) ko'rsatiladi, "o'qildi" chizilmaydi. Ya'ni backend qo'llаса
  /// avtomatik ishlaydi, qo'llаmаса hech nima buzilmaydi.
  final bool isRead;

  bool isMine(String myId) => senderId == myId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: asString(json['id']),
    senderId: asString(json['sender_id']),
    receiverId: asString(json['receiver_id']),
    // HTML kodlari transport qatlamida ochiladi (`ApiClient._onResponse`
    // va WS uchun `WsEvent.tryParse`) — bu yerda matn allaqachon toza.
    content: asString(json['content']),
    rideId: asStringOrNull(json['ride_id']),
    createdAt: asDate(json['created_at']),
    isRead:
        asBool(json['is_read']) ||
        asBool(json['read']) ||
        json['read_at'] != null,
  );
}

/// Xabarlarni ESKIDAN YANGIGA tartiblaydi.
///
/// 🔴 Egasi qurilmada ko'rdi (2026-08-13): «chatdan chiqib qaytib kirsam
/// aralashib, oxirgi xabar 1-chisiga chiqib qolyapti». Sabab — oddiy
/// `sort` teng vaqtli xabarlar tartibini SAQLAMAYDI (Dart'da `sort`
/// barqaror emas), yozishmada esa bir daqiqada yozilgan xabarlar ko'p:
/// har yuklashda ular boshqacha joylashardi.
///
/// Shu sabab tartib TO'LIQ aniqlangan bo'lishi kerak:
///   * vaqtlar har xil bo'lsa — vaqt bo'yicha;
///   * vaqtlar TENG bo'lsa — serverdan kelgan tartib saqlanadi;
///   * vaqti yo'q xabar qo'shnisining vaqtini oladi, ya'ni serverdagi
///     joyida qoladi (ilgari bunday xabar ro'yxatning istalgan yeriga
///     otilib chiqishi mumkin edi — taqqoslash `0` qaytarardi).
List<ChatMessage> orderChatMessages(List<ChatMessage> raw) {
  if (raw.length < 2) return raw;

  // Server ro'yxatni yangidan eskiga bergan bo'lsa, teng vaqtlar uchun
  // "server tartibi" ham teskari o'qilishi kerak.
  DateTime? first;
  DateTime? last;
  for (final m in raw) {
    final t = m.createdAt;
    if (t != null) {
      first ??= t;
      last = t;
    }
  }
  final serverDesc = first != null && last != null && first.isAfter(last);

  // Vaqtsiz xabarga qo'shnisining vaqti beriladi (avval oldingisi, bo'lmasa
  // keyingisi) — shunda u o'z joyidan siljimaydi.
  final effective = List<DateTime?>.filled(raw.length, null);
  DateTime? carry;
  for (var i = 0; i < raw.length; i++) {
    carry = raw[i].createdAt ?? carry;
    effective[i] = carry;
  }
  DateTime? back;
  for (var i = raw.length - 1; i >= 0; i--) {
    back = raw[i].createdAt ?? back;
    effective[i] ??= back;
  }

  final order = [for (var i = 0; i < raw.length; i++) i];
  order.sort((a, b) {
    final at = effective[a];
    final bt = effective[b];
    if (at != null && bt != null) {
      final c = at.compareTo(bt);
      if (c != 0) return c;
    }
    return serverDesc ? b.compareTo(a) : a.compareTo(b);
  });
  return [for (final i in order) raw[i]];
}

/// Suhbat — ro'yxat BRONLARDAN yig'iladi.
///
/// ⚠️ 07.09.2026 da aniqlashtirildi: ilgari bu yerda «alohida
/// "conversations" endpointi backendda YO'Q» deb yozilgandi va bu
/// noto'g'ri edi. `GET /chats` (va uning aynan nusxasi
/// `GET /notifications/chats`) BOR, lekin u atigi uchta maydon
/// beradi: `partner_id`, `last_message`, `unread_count` — jonli
/// o'lchandi. SAFAR ham, odamning ISMI/AVATARI ham yo'q, ya'ni
/// undan ro'yxat chizib bo'lmaydi. Shuning uchun ro'yxat baribir
/// bronlardan quriladi, o'sha endpoint esa uni o'qilmagan xabar
/// soni va oxirgi xabar bilan TO'LDIRADI.
///
/// Suhbat = (safar, suhbatdosh) juftligi va u bronlardan yig'iladi:
///   haydovchi  — o'z safarlaridagi TASDIQLANGAN bronlar, suhbatdosh = yo'lovchi;
///   yo'lovchi  — o'z tasdiqlangan bronlari, suhbatdosh = haydovchi.
/// Chat faqat `confirmed` bron uchun ochiladi (mahsulot qoidasi).
class Conversation {
  const Conversation({
    required this.rideId,
    required this.peerId,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.lastMessage,
    this.lastAt,
    this.lastIsMine = false,
    this.unreadCount = 0,
  });

  Conversation withSummary(ChatSummary summary, {String? myUserId}) => Conversation(
    rideId: rideId,
    peerId: peerId,
    title: title,
    subtitle: subtitle,
    avatarUrl: avatarUrl,
    lastMessage: summary.lastMessage,
    lastAt: summary.lastAt,
    lastIsMine:
        myUserId != null &&
        myUserId.isNotEmpty &&
        summary.lastSenderId != null &&
        summary.lastSenderId == myUserId,
    unreadCount: summary.unreadCount,
  );

  /// OXIRGI safar — xabar yuborishda kontekst sifatida ketadi.
  ///
  /// ⚠️ Suhbatni ANIQLAMAYDI: bitta odam bilan bir nechta safar bo'lishi
  /// mumkin, suhbat esa BITTA (pastdagi tenglikka qarang).
  final String rideId;

  /// Suhbatdosh UUID — WS `recipient_id` va tarix `user_id_2` uchun.
  /// Suhbatning YAGONA kaliti shu.
  final String peerId;
  final String title;
  final String? subtitle;

  /// Suhbatdoshning surati.
  ///
  /// 🔴 Egasi (2026-08-16): "chatlarda ham gaplashayotganda rasm
  /// ko'rinmaydi". Ro'yxatda doim bir xil kulrang ikonka turardi — o'nta
  /// suhbat bir xil ko'rinardi va odam kim bilan yozishayotganini faqat
  /// matndan ajratardi.
  final String? avatarUrl;


  /// Oxirgi xabar matni va vaqti — `GET /notifications/chats` dan.
  ///
  /// 🔴 NEGA MUHIM (2026-08-16): ilgari ro'yxatdagi har bir suhbat uchun
  /// BUTUN yozishma tarixi alohida so'rov bilan yuklanardi — faqat oxirgi
  /// qatorni ko'rsatish uchun. O'nta suhbat = o'nta so'rov, har biri
  /// to'liq tarix bilan. Endi bitta so'rov hammasini beradi.
  final String? lastMessage;
  final DateTime? lastAt;

  /// Oxirgi xabarni MEN yozganmanmi — ro'yxatdagi "Siz:" prefiksi uchun.
  ///
  /// 🔴 NEGA KERAK (egasi tasdiqladi, 2026-08-19): ro'yxatda faqat matn
  /// turardi va kim yozgani bilinmasdi. "Xo'p, kelishdik" degan qatorni
  /// ko'rgan odam suhbatdosh javob berdi deb o'ylab chatni ochardi — u
  /// yerda esa o'zining xabari turardi. Telegram bu muammoni "Siz:"
  /// prefiksi bilan yechgan; saytda ham xuddi shu qo'shildi.
  ///
  /// Foydalanuvchi ID noma'lum bo'lsa `false` — noto'g'ri "Siz:" YOZILMAYDI.
  final bool lastIsMine;

  /// O'qilmagan xabarlar soni.
  ///
  /// ⚠️ HOZIRCHA KO'RSATILMAYDI: backendda xabarni "o'qildi" deb
  /// belgilaydigan yo'l yo'q (`PUT /notifications/{id}/read` —
  /// bildirishnoma uchun, chat xabari uchun emas; so'ralgan, xat
  /// 2026-08-16c). Belgini yoqib qo'ysak u o'qigandan keyin ham
  /// o'chmaydi — bu umuman belgisiz turgandan YOMONROQ.
  final int unreadCount;

  /// `family` provider kaliti sifatida ishlatiladi — tenglik SHART, aks holda
  /// har build'da yangi provider yaratilib, chat qayta-qayta yuklanadi.
  ///
  /// 🔴 2026-08-13 O'ZGARDI: ilgari tenglik (safar + suhbatdosh) juftligi
  /// edi va bitta haydovchi bilan uch marta yursangiz ro'yxatda UCHTA bir
  /// xil ism turardi — ularni faqat yo'nalishdan ajratish mumkin edi.
  /// Egasi: "yo'nalish bo'yicha chat ochilmasin, user id bo'yicha ochsin —
  /// Telegramda ham shunaqa". Endi kalit — FAQAT suhbatdosh.
  @override
  bool operator ==(Object other) =>
      other is Conversation && other.peerId == peerId;

  @override
  int get hashCode => peerId.hashCode;
}

/// `GET /notifications/chats` elementi.
///
/// Backend 2026-08-16 da qo'shdi (biz so'ragan edik — `chats_screen`
/// izohiga qarang). Ism va avatar bu javobda YO'Q, shuning uchun u
/// suhbatlar ro'yxatini ALMASHTIRMAYDI: ro'yxat bronlardan yig'ilaveradi,
/// bu esa ustiga "oxirgi xabar" ma'lumotini qo'yadi.
class ChatSummary {
  const ChatSummary({
    required this.peerId,
    this.lastMessage,
    this.lastAt,
    this.lastSenderId,
    this.unreadCount = 0,
  });

  final String peerId;
  final String? lastMessage;
  final DateTime? lastAt;

  /// Oxirgi xabarni KIM yozgan. "Siz:" prefiksi shundan hisoblanadi
  /// (izohi `Conversation.lastIsMine` da).
  final String? lastSenderId;

  final int unreadCount;

  factory ChatSummary.fromJson(Map<String, dynamic> json) {
    final last = asMap(json['last_message']);
    return ChatSummary(
      peerId: asString(pick(json, ['partner_id', 'peer_id'])),
      lastMessage: last == null ? null : asString(last['content']),
      lastAt: last == null ? null : asDate(last['created_at']),
      lastSenderId: last == null ? null : asStringOrNull(last['sender_id']),
      unreadCount: json['unread_count'] == null
          ? 0
          : asInt(json['unread_count']),
    );
  }
}

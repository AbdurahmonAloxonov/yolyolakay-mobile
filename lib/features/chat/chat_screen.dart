import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/drafts.dart';
import '../../core/format.dart';
import '../../data/models/chat.dart';
import '../../core/cities.dart';
import '../../core/geo_message.dart';
import '../../l10n/strings.dart';
import '../map/pick_location_screen.dart';
import '../map/point_preview_map.dart';
import '../shared/brand/atlas.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../moderation/report_block_sheet.dart';
import '../../../app/dimens.dart';
import '../../core/haptics.dart';
import '../../core/outbox.dart';
import '../shared/brand/loom_loader.dart';
import 'trip_context_card.dart';

/// Bitta suhbat.
///
/// Xabar YUBORISH faqat WS orqali (REST endpointi yo'q). Yuborilgan xabar
/// darhol ro'yxatga qo'shiladi (optimistik) — server tasdig'ini kutib turish
/// chatni sekin ko'rsatadi; keyingi yangilashda tarixdan qayta o'qiladi.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();

  /// Yozishma ichidan QIDIRUV so'zi (bo'sh — qidiruv yopiq).
  ///
  /// 🔴 NEGA KERAK: uzun yozishmada kelishilgan manzil yoki telefon
  /// raqamini topish uchun odam o'nlab xabarni qo'lda surib chiqardi.
  /// Qidiruv YUKLANGAN xabarlar ustidan ishlaydi — serverga so'rov
  /// yubormaydi, ya'ni internetsiz ham ishlaydi.
  String _query = '';
  bool _searching = false;

  /// Yiqilgan xabarlarni ALOQA TIKLANGANDA o'zi yuborish uchun taymer.
  ///
  /// 🔴 NEGA KERAK: yiqilgan xabar ro'yxatda qizil "!" bilan qolardi va
  /// odam uni QO'LDA bosishi kerak edi. Shaharlararo yo'lda aloqa
  /// tinimsiz uzilib turadi — ya'ni odam har safar ekranga qarab, "!"
  /// ni topib, bosishi kerak bo'lardi. Endi navbat o'zi ketadi.
  ///
  /// Taymer FAQAT navbatda xabar bo'lganda ishlaydi va bo'shaganda
  /// to'xtaydi: doimiy ishlaydigan taymer batareyani bekorga yeydi.
  ///
  /// 🔴 2026-08-25: navbatning O'ZI endi bu ekranда emas, DISKDA
  /// (`core/outbox.dart`). Ilgari yuborilmagan xabar `_pending` — ekran
  /// holatiда yotardi: ekrandan chiqilsa yoki ilova o'chsa yo'qolardi.
  /// Bu taymer endi shunchaki turtki beradi, xabarni o'zi saqlamaydi.
  Timer? _queueTimer;

  /// Navbatni tekshirish oralig'i — soket qayta ulanishi (5 s) bilan
  /// mos: undan tez tekshirish hech nima bermaydi.
  static const _queueInterval = Duration(seconds: 5);

  /// Javob berilayotган xabar (surib javob). 🔴 Backend chat reply-threadни
  /// SAQLAMAYDI (swaggerда chat yo'q) — shuning uchun javob matn ICHIGA
  /// qisqa iqtibos bo'lib qo'shiladi (halol: bu shunчаки matn).
  ChatMessage? _replyTo;

  /// Suhbatdosh "yozmoqda" ekanini ko'rsatish holati va uni o'chiradigan
  /// taymer (kadr kelmay qolса, "yozmoqda" abadiy qolmasin).
  bool _peerTyping = false;
  Timer? _peerTypingTimer;

  /// O'z "yozmoqda" signalimni CHEKLAB yuborish: har harfда emas, 3s da
  /// bir marta (aks holda soket har bosishда bombardimon qilinadi).
  DateTime? _lastTypingSent;
  final _scroll = ScrollController();
  final List<ChatMessage> _pending = [];

  /// Offline navbat ro'yxati — `dispose` da tinglovchini uzish uchun havola
  /// oldindan olinadi (Riverpod `dispose` da o'qishni taqiqlaydi).
  ValueListenable<List<OutboxItem>>? _outboxItems;
  // Allaqachon "o'qildi" deb belgilangan xabar id'lari — ikki marta
  // yubormaslik uchun (backend ack qaytarmaydi, o'zimiz kuzatamiz).
  final Set<String> _marked = {};

  /// Suhbatdosh o'qigan MENING xabar id'larim — ikki galochka uchun.
  /// (`messages_read` WS eventидан; tarix qayta yuklаnмасдан darhol chiziladi.)
  final Set<String> _readIds = {};

  @override
  void initState() {
    super.initState();
    // Banner shu suhbatga chiqmasin — xabar ekranda allaqachon ko'rinadi.
    // `addPostFrameCallback`: `initState` ichida provider O'ZGARTIRIB
    // bo'lmaydi (build davomida holat o'zgarishi xatosi).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(openConversationProvider.notifier).state = widget.conversation;
        /*
         * 🔴 STATUS-BARDAGI BILDIRISHNOMA SHU YERDA O'CHADI (egasi,
         * 2026-09-04: «push keladi, ichiga kiraman, lekin tepada
         * qolib ketyapti»).
         *
         * Android bosilgan bildirishnomani o'zi olib tashlaydi, lekin
         * BOSHQA yo'l bilan kirilgan bo'lsa — chatlar ro'yxatidan,
         * yoki ilova allaqachon ochiq bo'lsa — hech kim uni
         * olib tashlamasdi. Kodda `cancel` chaqiruvining O'ZI yo'q edi.
         *
         * Endi suhbat ochilishi bilan AYNAN o'sha suhbatning
         * bildirishnomasi olib tashlanadi (raqam `chatNotificationId`
         * bilan hisoblanadi — ko'rsatish bilan bir xil manba).
         */
        ref
            .read(notificationDismisserProvider)
            .chat(widget.conversation.peerId);
        // QORALAMA — yozib bo'lib chiqib ketilgan matn qaytariladi
        // (izohi `core/drafts.dart` da). Telegramda ham shunday va odam
        // shunga o'rgangan.
        _drafts = ref.read(draftsProvider);
        final saved = _drafts?.read(Drafts.chat(widget.conversation.peerId));
        if (saved != null && _input.text.isEmpty) {
          setState(() => _input.text = saved);
        }

        // OFFLINE NAVBAT — yuborilmagan xabarlar ro'yxatga qaytadi va
        // navbat holati kuzatiladi (izohi `core/outbox.dart` da).
        // ⚠️ Havola SAQLANADI: `dispose` da provider o'qib bo'lmaydi.
        final outbox = ref.read(outboxProvider);
        _outboxItems = outbox.items;
        _outboxItems?.addListener(_onOutboxChanged);
        final me = ref.read(meProvider).valueOrNull;
        if (me != null) _restoreQueued(me.user.id);
      }
    });

    // 🔴 SERVER TURTKISIGA TAYANIB BO'LMAYDI (2026-08-13 jonli o'lchov).
    //
    // Bitta odamdan haydovchiga uchta xabar yuborildi va soketlar kuzatildi:
    // xabar QABUL QILUVCHIGA emas, YUBORUVCHINING soketlariga tushdi (har
    // safar boshqasiga), bittasi esa umuman ko'rinmadi. Ya'ni WS yetkazishi
    // qabul qiluvchi bo'yicha ishlamayapti — odam suhbatni ochib turib
    // xabarni ko'rmay qolishi mumkin. Xabarning O'ZI bazada saqlanadi
    // (`status: sent`), ya'ni tarixni qayta so'rasak ko'rinadi.
    //
    // Shu sabab suhbat ochiq turganda tarix har 5 soniyada qayta o'qiladi.
    // Server yetkazishni tuzatgach buni olib tashlash mumkin (xat: chat
    // yetkazish, 2026-08-13).
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) ref.invalidate(chatMessagesProvider(widget.conversation));
    });

    /*
     * Suhbat o'qilgach pastki nishon yangilansin.
     *
     * Server o'qilmaganlar hisobini tarix so'ralganda nolga tushiradi,
     * shuning uchun nishonni aynan tarix KELGANDA qayta so'raymiz —
     * aks holda odam xabarni o'qib chiqqan bo'lsa ham pastda "1"
     * turaverardi.
     *
     * ⚠️ Bu `dispose()` da qilinmaydi: Riverpod'da ekran o'chayotganda
     * `ref` bilan ishlash xatoga olib keladi.
     */
    ref.listenManual(chatMessagesProvider(widget.conversation), (
      previous,
      next,
    ) {
      if (next.hasValue) {
        // `valueOrNull`: `value` xato holatida TASHLAYDI va bu
        // tinglovchi ichida ushlanmagan xatoga aylanardi.
        _markRead(next.valueOrNull ?? const []);
        if (previous?.hasValue != true) {
          ref.invalidate(unreadChatsProvider);
        }
      }
    });

    // Ochiq turgan suhbatga yangi xabar kelsa tarixni qayta o'qiymiz.
    ref.listenManual(wsEventsProvider, (previous, next) {
      final event = next.value;
      if (event == null) return;

      // "Yozmoqda" — faqat SHU suhbatdoshдан. 3 soniya ko'rsatamiz va yangi
      // kadr kelса taymer qayta boshlanadi. Xabar kelса — darrov o'chadi
      // (odam yozib bo'ldi).
      if (event.isMessagesRead) {
        final ids = event.readMessageIds;
        if (ids.isNotEmpty) setState(() => _readIds.addAll(ids));
        return;
      }

      if (event.isTyping) {
        if (event.senderId == widget.conversation.peerId) {
          _peerTypingTimer?.cancel();
          setState(() => _peerTyping = true);
          _peerTypingTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _peerTyping = false);
          });
        }
        return;
      }

      if (!event.isNewMessage) return;
      // Suhbat OCHIQ turganda kelgan xabar uchun status-barda eslatma
      // saqlanmasin: odam uni shu zahoti o'qiyapti. (Ilova fonga
      // tushib qaytgan bo'lsa `initState` allaqachon ishlagan, ya'ni
      // faqat shu yer qoladi.)
      ref.read(notificationDismisserProvider).chat(widget.conversation.peerId);
      // Yangi xabar keldi — "yozmoqda" o'chadi.
      _peerTypingTimer?.cancel();
      if (_peerTyping) setState(() => _peerTyping = false);
      ref.invalidate(chatMessagesProvider(widget.conversation));
      // Kelgan xabar ko'rinishi uchun pastga tushamiz — aks holda odam
      // yangi xabar kelganini bilmay, eski joyda qolib ketadi.
      _scrollToBottom();
    });
  }

  /// Tarixni so'rab turuvchi taymer — server turtkisi ishonchsiz.
  Timer? _poll;

  /// Suhbatdoshning xabarlarini "o'qildi" deb belgilaydi (WS orqali).
  ///
  /// Faqat SUHBATDOSHNING xabarlari va faqat BIR MARTA: o'z xabaringni
  /// belgilashning ma'nosi yo'q, ack esa kelmaydi (backend jim belgilaydi),
  /// shuning uchun yuborilganlarni `_marked` da o'zimiz kuzatamiz.
  void _markRead(List<ChatMessage> messages) {
    final me = ref.read(meProvider).valueOrNull;
    if (me == null) return;

    final ids = <String>[];
    for (final m in messages) {
      if (m.id.isEmpty) continue;
      if (m.isMine(me.user.id)) continue; // o'z xabarim emas
      if (_marked.add(m.id)) ids.add(m.id); // `add` false = allaqachon bor
    }
    if (ids.isEmpty) return;

    final sent = ref.read(wsClientProvider).markAsRead(ids);
    // Soket yopiq bo'lsa yuborilmadi — keyingi tarix kelishida `_marked`
    // da yo'q id'lar qayta urinadi (ularni to'plamdan olib tashlaymiz).
    if (!sent) _marked.removeAll(ids);
  }

  @override
  void dispose() {
    _poll?.cancel();
    // Ekran yopilgach banner yana ishlashi kerak.
    //
    // ⚠️ `ref.read` bu yerda XAVFSIZ emas (widget o'chirilyapti), shuning
    // uchun konteyner orqali: Riverpod `dispose` da o'qishni taqiqlaydi.
    _openConversation?.state = null;
    _peerTypingTimer?.cancel();
    _queueTimer?.cancel();
    _outboxItems?.removeListener(_onOutboxChanged);
    // Yozilgan, lekin yuborilmagan matn SAQLANADI. `dispose` da provider
    // o'qib bo'lmaydi — shuning uchun havola oldindan olingan.
    unawaited(
      _drafts?.write(Drafts.chat(widget.conversation.peerId), _input.text) ??
          Future<void>.value(),
    );
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// `dispose` da provider'ga murojaat qilish uchun saqlangan havola.
  StateController<Conversation?>? _openConversation;

  /// Qoralamalar — shu ham `dispose` da kerak, shuning uchun oldindan.
  Drafts? _drafts;

  /// Tarix birinchi marta kelgach bir marta pastga tushamiz.
  ///
  /// 🔴 Egasi qurilmada ko'rdi (2026-08-13): suhbat ochilganda ekranda ENG
  /// ESKI xabarlar turardi va odam oxirgi xabarni ko'rish uchun qo'lda pastga
  /// surishi kerak edi. Telegramda suhbat DOIM oxirgi xabardan ochiladi.
  bool _didInitialScroll = false;

  /// Yozayotgan bo'lsam suhbatdoshга "yozmoqda" signalини yuboraman.
  /// 3 soniyada bir marta — har harfда soketни urmaslik uchun.
  void _onTyping() {
    final now = DateTime.now();
    if (_lastTypingSent != null &&
        now.difference(_lastTypingSent!) < const Duration(seconds: 3)) {
      return;
    }
    _lastTypingSent = now;
    ref.read(wsClientProvider).sendTyping(widget.conversation.peerId);
  }

  Future<void> _send() => _sendText(_input.text);

  /// JOY YUBORISH — xaritadan nuqta tanlanadi va `geo:` xabari ketadi.
  ///
  /// 🔑 Xabar oddiy MATN sifatida ketadi (`_sendText`), ya'ni offline
  /// navbat, qayta yuborish, «o'qildi» — hammasi o'zi ishlaydi. Format
  /// izohi `core/geo_message.dart` da.
  Future<void> _sendLocation() async {
    final place = await showLocationPicker(
      context,
      title: AppStrings.of(context).sendLocation,
    );
    if (place == null) return;
    await _sendText(
      GeoMessage(lat: place.lat, lon: place.lon, label: place.name).encode(),
    );
  }

  /// Matnni yuborish — yozuv maydonidan ham, tez javob chipidan ham.
  Future<void> _sendText(String source) async {
    final raw = source.trim();
    if (raw.isEmpty) return;
    // Javob bo'lса — oldiga qisqa iqtibos (bir qatorли, 80 belgiгача).
    final reply = _replyTo;
    final text = reply == null ? raw : '↩ «${_snippet(reply.content)}»\n$raw';

    final me = ref.read(meProvider).valueOrNull;
    if (me == null) return;

    /*
     * 🔴 INTERNETSIZ HAM QABUL QILAMIZ (egasi tanlagan band, 2026-08-25).
     *
     * Ilgari bu yerda `if (!ws.isConnected)` turardi: ekranга «aloqa yo'q»
     * chiqib, xabar HECH QAYERGA yozilmasdi. Odam tunnelда yozganini
     * yo'qotardi. Holbuki ilova aynan YO'LDA ishlatiladi.
     *
     * Endi xabar OFFLINE NAVBATGA tushadi (`core/outbox.dart`): diskda
     * saqlanadi, ilova o'chib qayta ochilsa ham joyida turadi va aloqa
     * tiklanganda o'zi ketadi. Ekranда esa soat belgisi bilan turadi —
     * jimgina "yuborildi" deb ko'rsatish yolg'on bo'lardi.
     */
    final outbox = ref.read(outboxProvider);
    final item = await outbox.add(
      kind: OutboxKind.chatMessage,
      payload: {
        'recipient_id': widget.conversation.peerId,
        'content': text,
        'ride_id': widget.conversation.rideId,
      },
    );
    if (!mounted) return;

    // `add` darhol yuborishga urinadi. Navbatда qolmagan bo'lsa — ketdi.
    final sent = !outbox.items.value.any((i) => i.id == item.id);
    if (sent) {
      AppHaptics.success();
    } else {
      AppHaptics.heavy();
    }
    setState(() {
      _pending.add(
        ChatMessage(
          // ID navbatniki: navbat yozuvni o'chirganда qaysi pufak
          // tasdiqlanganini aynan shu orqali topamiz.
          id: item.id,
          senderId: me.user.id,
          receiverId: widget.conversation.peerId,
          content: text,
          rideId: widget.conversation.rideId,
          createdAt: DateTime.now(),
          failed: !sent,
        ),
      );
      _input.clear();
      _replyTo = null;
    });
    // Yuborildi — qoralama endi kerak emas. Qolsa, keyingi ochilishda
    // "men buni allaqachon yubordim shekilli" degan chalkashlik berardi.
    unawaited(
      _drafts?.clear(Drafts.chat(widget.conversation.peerId)) ??
          Future<void>.value(),
    );
    _syncQueue();
    _scrollToBottom();
  }

  void _startReply(ChatMessage msg) {
    AppHaptics.select();
    setState(() => _replyTo = msg);
  }

  /// Iqtibos uchun qisqa bir qatorli parcha.
  static String _snippet(String s) {
    final one = s.replaceAll('\n', ' ').trim();
    return one.length <= 80 ? one : '${one.substring(0, 80)}…';
  }

  /// Navbatda yiqilgan xabar bo'lsa taymerni yoqadi, bo'lmasa o'chiradi.
  void _syncQueue() {
    final hasFailed = _pending.any((m) => m.failed);
    if (hasFailed) {
      _queueTimer ??= Timer.periodic(_queueInterval, (_) => _flushQueue());
    } else {
      _queueTimer?.cancel();
      _queueTimer = null;
    }
  }

  /// Navbatga turtki beradi. Yuborishning O'ZI navbatда
  /// (`core/outbox.dart`) — u tartibni ham, diskka yozishni ham biladi.
  void _flushQueue() {
    if (!mounted) return;
    unawaited(ref.read(outboxProvider).flush());
  }

  /// Yiqilgan xabar bosilganda — navbatni darhol qo'zg'atamiz.
  ///
  /// 🔴 Bitta xabarni ALOHIDA yuborish ATAYIN yo'q: navbat tartibni
  /// saqlaydi, uchinchi xabarni ikkinchisidan oldin yuborish esa suhbatni
  /// chalkashtirardi.
  void _resend(ChatMessage msg) {
    AppHaptics.select();
    _flushQueue();
  }

  /// Navbatdagi holatni ekranga ko'chiradi: yuborilgan xabar soat
  /// belgisini yo'qotadi, qolganlari kutishда turaveradi.
  void _onOutboxChanged() {
    if (!mounted) return;
    final queued = ref
        .read(outboxProvider)
        .items
        .value
        .map((i) => i.id)
        .toSet();
    var changed = false;
    for (var i = 0; i < _pending.length; i++) {
      final msg = _pending[i];
      final stillQueued = queued.contains(msg.id);
      if (msg.failed == stillQueued) continue;
      _pending[i] = ChatMessage(
        id: msg.id,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        content: msg.content,
        rideId: msg.rideId,
        createdAt: msg.createdAt,
        failed: stillQueued,
      );
      changed = true;
    }
    if (changed) setState(_syncQueue);
  }

  /// Ekran ochilganда navbatда SHU suhbatning yuborilmagan xabarlari
  /// bo'lsa, ularni ro'yxatga qaytaramiz.
  ///
  /// 🔴 NEGA KERAK: ilgari yuborilmagan xabar faqat ekran holatida edi —
  /// suhbatdan chiqib qaytilsa "men buni yubordimmi?" degan savol qolardi,
  /// javob esa hech qayerda yo'q edi.
  void _restoreQueued(String myId) {
    final queued = ref
        .read(outboxProvider)
        .items
        .value
        .where(
          (i) =>
              i.kind == OutboxKind.chatMessage &&
              '${i.payload['recipient_id']}' == widget.conversation.peerId,
        )
        .toList();
    if (queued.isEmpty) return;
    setState(() {
      for (final item in queued) {
        if (_pending.any((m) => m.id == item.id)) continue;
        _pending.add(
          ChatMessage(
            id: item.id,
            senderId: myId,
            receiverId: widget.conversation.peerId,
            content: '${item.payload['content']}',
            rideId: item.payload['ride_id'] as String?,
            createdAt: item.createdAt,
            failed: true,
          ),
        );
      }
      // Vaqti noma'lum xabar (eski yozuv) oxirida tursin — tartibsizlik
      // suhbatning boshiga tushgandan yaxshi.
      _pending.sort((a, b) {
        final left = a.createdAt;
        final right = b.createdAt;
        if (left == null || right == null) return 0;
        return left.compareTo(right);
      });
    });
    _syncQueue();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final messages = ref.watch(chatMessagesProvider(widget.conversation));

    // Sarlavha ostidagi yo'nalish — ENG SO'NGGI safarniki (izohi
    // `latestRideWithPeerProvider` da). Kelmasa suhbat yaratilgandagi
    // sarlavha zaxira bo'lib qoladi.
    final latestRide = ref
        .watch(latestRideWithPeerProvider(widget.conversation.peerId))
        .valueOrNull;
    final latestRoute = latestRide == null
        ? null
        : '${latestRide.originAddress} → ${latestRide.destinationAddress}';
    final me = ref.watch(meProvider).valueOrNull;
    _openConversation = ref.read(openConversationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        // Sarlavhada surat + ism: yozishayotgan odam KIM ekani ko'rinib
        // tursin (ilgari faqat matn edi).
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: t.searchInChat,
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _query = value),
              )
            : InkWell(
                // 🔴 «U KIM?» degan savol chatda javobsiz edi (2026-09-05
                // qulaylik auditi): begona profil ilovada FAQAT safar
                // sahifasidan ochilardi. Ya'ni notanish odam bilan
                // yozishayotgan yo'lovchi uning bahosini, sharhlarini va
                // safarlarini ko'rmoqchi bo'lsa — yo'l yo'q edi.
                //
                // ⚠️ Avatarning `tapToView` i shu yerda O'CHIRILDI: aks
                // holda bitta qatorda ikki xil bosish bo'lardi (surat
                // ochish va profil ochish) va odam qaysi biri bo'lishini
                // oldindan bila olmasdi. Profil ekranining O'ZIDA surat
                // kattalashtiriladi.
                onTap: () => context.push(
                  Routes.userProfile,
                  extra: <String, String?>{
                    'id': widget.conversation.peerId,
                    'name': widget.conversation.subtitle,
                  },
                ),
                child: Row(
                  children: [
                    PersonAvatar(
                      url: widget.conversation.avatarUrl,
                      radius: 16,
                      seed: widget.conversation.peerId,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        // Ism kelmasa "Suhbatlar" degan BO'LIM nomi turardi —
                        // go'yo sarlavha odamniki emas, ro'yxatniki.
                        //
                        // ⚠️ QISQARTIRILGAN shakl: sarlavhada avatar, ism,
                        // qidiruv va menyu bor — to'liq familiya u yerga
                        // sig'maydi va «Abdurahmon Rahm…» bo'lib kesilardi
                        // (izohi `shortName` da).
                        shortName(widget.conversation.subtitle) ??
                            t.chatPartner,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
        // 🔴 Google Play talabi: xabar yozish mumkin bo'lgan joyda shikoyat va
        // bloklash yo'li BO'LISHI SHART. Ilgari ilovada umuman yo'q edi.
        // Bloklangach chatdan chiqamiz — suhbat endi ma'nosiz.
        actions: [
          // Yozishma ichidan qidiruv — YUKLANGAN xabarlar ustidan,
          // serversiz (internetsiz ham ishlaydi).
          IconButton(
            tooltip: _searching ? t.close : t.searchInChat,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              // Yopilganda so'z ham TOZALANADI: aks holda keyingi
              // ochilishda ro'yxat sababsiz filtrlangan bo'lib qolardi.
              if (!_searching) _query = '';
            }),
          ),
          ReportBlockMenu(
            targetUserId: widget.conversation.peerId,
            targetName: widget.conversation.subtitle,
            rideId: widget.conversation.rideId,
            onBlocked: () {
              if (context.mounted) Navigator.of(context).maybePop();
            },
          ),
        ],
        // SAFAR KARTOCHKASI — qaysi safar haqida gaplashilayotgani.
        //
        // 🔴 Har doim ENG SO'NGGI safar (izohi `latestRideWithPeerProvider`
        // da): `conversation.rideId` suhbat yaratilgandagi ESKI safarda
        // qotib qolardi. Chat esa BITTA bo'lib qoladi — kartochka
        // almashadi, suhbat emas.
        bottom: PreferredSize(
          // 20 → 23: pastdagi atlas ipi uchun uch piksel. Ip boshqa
          // ekranlardagidek panelning eng ostida turadi.
          preferredSize: const Size.fromHeight(23),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  // "Yozmoqda" — bo'lса yo'nalish o'rniga ko'rsatiladi (Telegram
                  // uslubi), turquoise bilan urg'ulanadi. Aks holда yo'nalish
                  // ("Toshkent → Samarqand") turadi.
                  child: _peerTyping
                      ? Text(
                          t.peerTyping,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          // Eng SO'NGGI safar yo'nalishi; kelmasa —
                          // suhbat yaratilgandagi sarlavha (zaxira).
                          latestRoute ?? widget.conversation.title,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
              const AtlasEdge(height: 3, scale: 0.55),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          /*
           * SUHBAT KONTEKSTI — yopiq holatda bitta qator (vaqt · joy ·
           * narx), bosilsa marshrut va "Safarni ochish" chiqadi.
           *
           * 🔴 Ilgari chatda safar haqida faqat yo'nalish qatori bor edi.
           * Yozishmadagi savollarning ko'pi esa tafsilotga tegishli
           * ("soat nechada?", "narx qancha edi?") va odam javob berish
           * uchun chatdan CHIQIB, safarni topib, qaytishi kerak edi.
           */
          if (latestRide != null) TripContextCard(ride: latestRide),
          Expanded(
            child: messages.when(
              loading: () => const Center(child: LoomLoader()),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () =>
                    ref.invalidate(chatMessagesProvider(widget.conversation)),
              ),
              data: (history) {
                // Serverdan kelgan tarix + hali tasdiqlanmagan lokal xabarlar.
                //
                // 🔴 Ilgari dublikat MAZMUN bo'yicha tekshirilardi
                // (`history.map((m) => m.content).toSet()`). Natijada bir xil
                // matnni IKKI MARTA yozsangiz, ikkinchisi ro'yxatdan
                // yo'qolardi — "ha" ni ikki marta yuborib, bittasini
                // ko'rardingiz. Telegramda bunday emas.
                //
                // Endi SONI solishtiriladi: tarixda o'sha matndan nechta bor
                // bo'lsa, shuncha kutayotgan nusxa "tasdiqlangan" deb
                // hisoblanadi, ortig'i ro'yxatda qoladi.
                final confirmed = <String, int>{};
                for (final m in history) {
                  final key = '${m.senderId}|${m.content}';
                  confirmed[key] = (confirmed[key] ?? 0) + 1;
                }
                final waiting = <ChatMessage>[];
                for (final p in _pending) {
                  final key = '${p.senderId}|${p.content}';
                  final left = confirmed[key] ?? 0;
                  if (left > 0) {
                    confirmed[key] = left - 1;
                  } else {
                    waiting.add(p);
                  }
                }
                final everything = [...history, ...waiting];
                // Qidiruv FAQAT ko'rinishni cheklaydi — xabarlar
                // o'chirilmaydi va so'z tozalanganda hammasi qaytadi.
                final query = _query.trim().toLowerCase();
                final all = query.isEmpty
                    ? everything
                    : everything
                          .where((m) => m.content.toLowerCase().contains(query))
                          .toList();

                // Birinchi chizishda oxirgi xabarga tushamiz. Keyin
                // tegmaymiz — odam yuqoriga surib eski xabarni o'qiyotgan
                // bo'lsa, uni pastga tortib yuborish yomon bo'lardi.
                if (!_didInitialScroll && all.isNotEmpty) {
                  _didInitialScroll = true;
                  _scrollToBottom();
                }

                if (all.isEmpty) {
                  // Qidiruvda bo'sh natija BOSHQA gap: yozishma bor,
                  // shunchaki mos xabar yo'q.
                  // qulaylik: chiqish yo'li SHART EMAS — xabar yozish
                  // maydoni AYNAN shu ekranning pastida turibdi. Tugma
                  // qo'shsak, u o'sha maydonga fokus berardi, xolos.
                  return EmptyView(
                    icon: query.isEmpty
                        ? Icons.chat_bubble_outline
                        : Icons.search_off,
                    title: query.isEmpty ? t.noMessages : t.nothingFound,
                    subtitle: query.isEmpty ? t.noMessagesHint : null,
                  );
                }

                final lang = ref.read(langProvider);
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpace.lg),
                  itemCount: all.length,
                  itemBuilder: (context, index) {
                    final msg = all[index];
                    // Sana ajratgichи: birinchi xabar oldiда yoki kun
                    // o'zgarganда — "Bugun"/"Kecha"/to'liq sana.
                    final showDate =
                        index == 0 ||
                        !sameDay(all[index - 1].createdAt, msg.createdAt);
                    final bubble = _SwipeToReply(
                      onReply: () => _startReply(msg),
                      child: _Bubble(
                        message: msg,
                        isMine: me != null && msg.isMine(me.user.id),
                        onRetry: msg.failed ? () => _resend(msg) : null,
                        // `messages_read` WS orqali kelган o'qish — model
                        // `is_read` bilan birlashtiriladi (tarix qayta
                        // yuklаnмаса ham darhol ikki galochka).
                        readOverride: _readIds.contains(msg.id),
                      ),
                    );
                    if (!showDate) return bubble;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DateChip(label: chatDayLabel(msg.createdAt, lang)),
                        bubble,
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_replyTo != null)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.of(context).replyingLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            _snippet(_replyTo!.content),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: AppStrings.of(context).cancel,
                      onPressed: () => setState(() => _replyTo = null),
                    ),
                  ],
                ),
              ),
            ),
          // TEZ JAVOBLAR — bir bosishlik iboralar.
          //
          // 🔴 NEGA KERAK: haydovchi RULDA matn yozolmaydi (yozsa ham
          // yozmasligi kerak). Yo'lovchi esa ko'chada, sovuqda telefon
          // tepishini xohlamaydi. Chatdagi xabarlarning katta qismi
          // aslida shu to'rt iboradan iborat.
          //
          // Faqat yozuv maydoni BO'SH bo'lganda ko'rinadi: odam matn
          // yozayotgan bo'lsa, chiplar ekranni band qilib turishi
          // shunchaki xalaqit.
          if (_input.text.trim().isEmpty)
            SafeArea(
              top: false,
              bottom: false,
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final phrase in t.quickReplies)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpace.sm),
                        child: ActionChip(
                          label: Text(phrase),
                          // DARHOL yuboriladi, maydonga qo'yilmaydi: bir
                          // bosish — bitta amal. Aks holda odam yana
                          // "yuborish"ni bosishi kerak bo'lardi.
                          onPressed: () => _sendText(phrase),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  /*
                   * JOY YUBORISH — 16.09.2026.
                   *
                   * 🔴 Uchrashuv nuqtasi AYNAN shu yerda kelishiladi va
                   * ilgari uni faqat MATN bilan aytish mumkin edi
                   * («Chortoq bozor yonida»). Notanish shaharda bu
                   * foydasiz: kelgan odam bozorni topa olmaydi.
                   *
                   * Tugma yozuv maydonidan CHAPDA: messenjerlardagi
                   * odat shu va odam uni izlamaydi.
                   */
                  IconButton(
                    tooltip: t.sendLocation,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    onPressed: _sendLocation,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onChanged: (_) {
                        _onTyping();
                        // Chiplar faqat maydon BO'SH bo'lganda ko'rinadi —
                        // shuning uchun har o'zgarishda qayta chizamiz.
                        setState(() {});
                      },
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(hintText: t.messageHint),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  IconButton.filled(
                    tooltip: t.sendMessage,
                    icon: const Icon(Icons.send),
                    onPressed: _send,
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

/// Xabarlar orasidagi sana ajratgichи — markazда, yumshoq fon.
class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// SURIB JAVOB BERISH — xabarni o'ngga surib "javob" rejimini yoqadi.
/// `Dismissible` ishlatiladi, lekin HECH NARSA o'chirilmaydi: `confirmDismiss`
/// javobni yoqib `false` qaytaradi (bubble joyiga qaytadi) — messenjerlardagi
/// klassik surib-javob naqshi. Chapdagi javob ikonkasi surилганда ochilади.
class _SwipeToReply extends StatelessWidget {
  const _SwipeToReply({required this.child, required this.onReply});

  final Widget child;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.22},
      confirmDismiss: (_) async {
        onReply();
        return false; // o'chirmaydi — faqat javobni yoqadi
      },
      background: Padding(
        padding: const EdgeInsets.only(left: AppSpace.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(Icons.reply, color: scheme.primary),
        ),
      ),
      child: child,
    );
  }
}

/// ULASHILGAN JOY pufagi — xarita + nomi.
///
/// 🔑 Oddiy pufakdan KENGROQ va ichida xarita bor, shuning uchun u
/// alohida vidjet: matn pufagiga xarita qo'shsak, `Wrap` ichidagi
/// vaqt belgisi xaritani qisib qo'yardi.
///
/// Bosilsa — xaritadan joy tanlash ekrani O'SHA nuqtada ochiladi:
/// odam uni kattalashtirib ko'radi, atrofini o'rganadi va xohlasa
/// o'z joyini javob qilib yuboradi.
class _GeoBubble extends StatelessWidget {
  const _GeoBubble({
    required this.geo,
    required this.isMine,
    required this.time,
    required this.openLabel,
  });

  final GeoMessage geo;
  final bool isMine;
  final DateTime? time;
  final String openLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width * 0.75;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpace.xs),
      constraints: BoxConstraints(maxWidth: width),
      decoration: BoxDecoration(
        color: isMine ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.card),
          topRight: const Radius.circular(AppRadius.card),
          bottomLeft: Radius.circular(
            isMine ? AppRadius.card : AppRadius.bubbleTail,
          ),
          bottomRight: Radius.circular(
            isMine ? AppRadius.bubbleTail : AppRadius.card,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PointPreviewMap(
            point: LatLng(geo.lat, geo.lon),
            height: 130,
            semanticLabel: openLabel,
            onTap: () => showLocationPicker(
              context,
              initial: Place(
                name: geo.label ?? '',
                lat: geo.lat,
                lon: geo.lon,
                region: '',
              ),
              title: openLabel,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.sm,
              AppSpace.sm,
              AppSpace.sm,
              AppSpace.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 15,
                  color: isMine ? Colors.white : scheme.onSurface,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    // Nom kelmagan bo'lsa koordinata ko'rsatiladi: bo'sh
                    // qator "xarita nimaniki?" degan savol qoldirardi.
                    geo.label ??
                        '${geo.lat.toStringAsFixed(5)}, ${geo.lon.toStringAsFixed(5)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isMine ? Colors.white : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  formatTime(time),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isMine ? Colors.white70 : scheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    this.onRetry,
    this.readOverride = false,
  });

  final ChatMessage message;
  final bool isMine;

  /// WS `messages_read` dan kelган o'qish (model `is_read` bilan yoki).
  final bool readOverride;

  /// Yiqilgan xabar bosilганда qayta yuborish (faqat `failed` da).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppStrings.of(context);

    /*
     * ULASHILGAN JOY — 16.09.2026.
     *
     * 🔴 Uchrashuv nuqtasi AYNAN chatda kelishiladi, lekin ilgari uni
     * faqat MATN bilan aytish mumkin edi («3-mavze yonida»). Notanish
     * shaharda bu foydasiz. Endi joy `geo:` xabari bo'lib keladi va
     * pufakda XARITA chiziladi (format izohi `core/geo_message.dart`
     * da — backend o'zgarmagan, bu oddiy matnli xabar).
     */
    final geo = parseGeoMessage(message.content);

    final bubble = geo != null
        ? _GeoBubble(
            geo: geo,
            isMine: isMine,
            time: message.createdAt,
            openLabel: t.showOnMap,
          )
        : Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.sm,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMine
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.card),
                topRight: const Radius.circular(AppRadius.card),
                bottomLeft: Radius.circular(
                  isMine ? AppRadius.card : AppRadius.bubbleTail,
                ),
                bottomRight: Radius.circular(
                  isMine ? AppRadius.bubbleTail : AppRadius.card,
                ),
              ),
            ),
            // 🔴 Ilgari matn va vaqt ustma-ust (`Column`) turardi. Vaqt ("01:46")
            // qisqa xabardan ("lgx") KENGROQ bo'lgani uchun pufakning enini
            // VAQT belgilardi va natijada matn markazga tortilgan kvadratcha
            // paydo bo'lardi (egasi qurilmada ko'rdi, 2026-08-13).
            //
            // `Wrap` — yechim: vaqt matn bilan BIR QATORDA turadi va joy
            // yetmasa o'zi pastga tushadi. Uzun xabar ham, "lgx" ham to'g'ri
            // chiqadi. `spacing` matn bilan vaqt orasidagi masofa.
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: AppSpace.sm,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMine ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatTime(message.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isMine
                            ? Colors.white70
                            : theme.colorScheme.outline,
                      ),
                    ),
                    // 🔴 O'QILDI BELGISI — faqat O'Z xabarimда (egasi 2026-08-20).
                    // Bitta galochka = yuborildi (xabar id'si bor, backendда
                    // saqlangan); ikki galochka = suhbatdosh o'qigan (`isRead`).
                    // Backend `is_read` qaytармаса doim bitta galochka —
                    // "o'qildi" YOLG'ON ko'rsatilmaydi.
                    //
                    // 🔴 NAVBATDAGI xabarда galochka CHIZILMAYDI (2026-08-25):
                    // u hali yuborilmagan. Galochka qo'yish "ketdi" degan
                    // yolg'on bo'lardi — odam javob kutib o'tirardi.
                    if (isMine) ...[
                      const SizedBox(width: AppSpace.xs),
                      Icon(
                        message.failed
                            ? Icons.schedule
                            : (message.isRead || readOverride)
                            ? Icons.done_all
                            : Icons.done,
                        size: 14,
                        color: message.failed
                            ? Colors.white70
                            : (message.isRead || readOverride)
                            ? theme.colorScheme.secondary
                            : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );

    // NAVBATDAGI xabar — pufak yonida soat belgisi; bosilsa navbat darhol
    // qo'zg'atiladi. Faqat O'Z xabarimда.
    //
    // 🔴 QIZIL "!" EMAS (2026-08-25): xabar endi diskda saqlanadi va aloqa
    // tiklanганда o'zi ketadi. Qizil xato belgisi "yo'qoldi, o'zing bir
    // nima qil" degan ma'no berardi — bu endi to'g'ri emas va odamni
    // bekorga xavotirga solardi.
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (message.failed && isMine)
            IconButton(
              icon: Icon(
                Icons.schedule_send_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              tooltip: AppStrings.of(context).messageQueued,
              onPressed: onRetry,
            ),
          Flexible(
            // Xabarни bosиб ushlаб NUSXA olish (egasi, 2026-08-20): manzil/
            // raqam yuborilса qo'лда qayta yozишга hojат qolмасин.
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.content));
                AppHaptics.select();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.of(context).copied),
                      duration: const Duration(seconds: 2),
                    ),
                  );
              },
              child: bubble,
            ),
          ),
        ],
      ),
    );
  }
}

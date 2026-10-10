import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../l10n/strings.dart';
import '../../core/local_cache.dart';
import '../shared/brand/suzani_icons.dart';
import '../shared/cached_note.dart';
import '../shared/collapsing_scaffold.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../shared/notification_bell.dart';
import '../shared/settings_button.dart';
import '../../core/format.dart';
import '../../data/models/chat.dart';
import '../shared/refreshable.dart';
import '../shared/skeleton.dart';

/// Suhbatlar ro'yxati.
///
/// Backendda "conversations" endpointi yo'q — ro'yxat tasdiqlangan bronlardan
/// yig'iladi (`conversationsProvider`).
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  /// Ro'yxatni so'rab turuvchi taymer.
  ///
  /// 🔴 Serverning WS turtkisi qabul qiluvchiga yetib bormaydi (2026-08-13
  /// jonli o'lchov, chat ekranidagi izohga qarang) — ya'ni yangi xabar
  /// kelganini bilishning yagona ishonchli yo'li qayta so'rash.
  /// Ro'yxat chat ekranidan siyrakroq yangilanadi: bu yerda "kim yozdi"
  /// muhim, har soniyani kuzatish shart emas.
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      ref.invalidate(conversationsProvider);
      // Nishon ro'yxat bilan BIR VAQTDA yangilansin — aks holda ro'yxatda
      // o'qilmagan yo'q, nishonda esa bor bo'lib turardi.
      ref.invalidate(unreadChatsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final conversations = ref.watch(conversationsProvider);

    return CollapsingScaffold(
      title: t.chatsTitle,
      actions: const [NotificationBell(), SettingsButton()],
      // Tortib-yangilash YUKLANISH va XATO holatida ham ishlaydi
      // (izohi `YolRefreshable` da).
      body: YolRefreshable<List<Conversation>>(
        value: conversations,
        onRefresh: () => ref.refresh(conversationsProvider.future),
        loading: const ListSkeleton(),
        builder: (items) {
          if (items.isEmpty) {
            // 🔴 BOSHI BERK EDI (2026-09-05): yozishma o'z-o'zidan
            // paydo bo'lmaydi — u SAFARdan boshlanadi. «Suhbat yo'q»
            // deb yozib, safar qidirishni taklif qilmaslik odamni
            // bo'sh ekranda qoldirardi.
            return EmptyView(
              suzani: SuzaniIcon.chat,
              title: t.noChats,
              subtitle: t.noChatsHint,
              actionLabel: t.searchButton,
              onAction: () => context.go(Routes.search),
            );
          }
          return Column(
            children: [
              // Ma'lumot keshdan kelgan bo'lsa — qachonligi AYTILADI
              // (izohi `CachedNote` da).
              const CachedNote(cacheKey: CacheKeys.conversations),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final conversation = items[index];
                    return _ConversationTile(conversation: conversation);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ro'yxatdagi bitta suhbat.
///
/// 🔴 Nima yetishmasdi (egasi qurilmada, 2026-08-13): qatorda faqat ism va
/// yo'nalish bor edi — OXIRGI XABAR ham, uning VAQTI ham yo'q. Ya'ni odam
/// yangi xabar bor-yo'qligini bilish uchun har bir suhbatni ochib chiqishi
/// kerak edi. Chat ro'yxatining butun ma'nosi shu ikki narsada.
///
/// ⚠ NARXI: backendda "conversations" endpointi YO'Q (ro'yxat bronlardan
/// yig'iladi), shuning uchun oxirgi xabar HAR suhbat uchun alohida so'rov
/// bilan olinadi. Suhbatlar soni odatda bir nechta, lekin bu vaqtinchalik
/// yechim — backenddan oxirgi xabarni ro'yxat bilan birga berish so'ralgan.
class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    // 🔴 2026-08-16: ilgari bu yerda HAR suhbat uchun butun yozishma
    // tarixi so'ralardi (`chatMessagesProvider`) — faqat oxirgi qatorni
    // chizish uchun. O'nta suhbat = o'nta so'rov, har biri to'liq tarix
    // bilan. Endi oxirgi xabar ro'yxat bilan BIRGA keladi
    // (`GET /notifications/chats`, `conversationsProvider` da qo'shiladi).
    final lastText = conversation.lastMessage;
    // "Siz:" — oxirgi xabarni o'zim yozgan bo'lsam (izohi
    // `Conversation.lastIsMine` da). Prefiks kulrang, matn o'z rangida
    // qoladi, ya'ni ko'z avval MATNNI o'qiydi.
    final lastPrefix = conversation.lastIsMine ? '${t.youPrefix} ' : '';
    final lastAt = conversation.lastAt;

    /*
     * O'QILMAGAN XABARLAR SONI.
     *
     * 🔴 Server buni `GET /notifications/chats` da BERADI (`unread_count`)
     * va model uni o'qiydi ham edi — lekin ekranda hech qayerda
     * ko'rsatilmasdi. Ya'ni ro'yxatga qarab qaysi suhbatda yangi xabar
     * borligini bilishning YO'LI YO'Q edi: odam har bittasini ochib
     * ko'rishi kerak edi.
     *
     * Ochilgan suhbatning soni server tomonda nolga tushadi (tarix
     * so'ralganda), shuning uchun bu yerda qo'lda hisob yuritilmaydi.
     */
    final unread = conversation.unreadCount;
    final hasUnread = unread > 0;

    return ListTile(
      leading: PersonAvatar(
        url: conversation.avatarUrl,
        radius: 20,
        seed: conversation.peerId,
      ),
      title: Text(
        // Ism pasport ma'lumotidan keladi va BOSH HARFLARDA bo'lishi mumkin
        // ("MUXAMMAD RAXMATILLAYEV") — ro'yxatda u baqirayotgandek ko'rinadi.
        // Rolga bog'liq bo'lmagan zaxira: haydovchi o'z yo'lovchisini
        // "Haydovchi" deb ko'rmasin.
        prettyName(conversation.subtitle) ?? t.chatPartner,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // O'qilmagan suhbat qalinroq — ro'yxatga bir qarashda ko'rinadi.
        style: hasUnread
            ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
            : null,
      ),
      // Xabar bo'lsa — O'SHA ko'rinadi; yo'q bo'lsa yo'nalish qoladi,
      // chunki bo'sh qator qatorni "yuklanmagan"dek ko'rsatardi.
      // Uchinchi zaxira: safar noma'lum (bron yo'q, suhbat serverdan
      // kelgan) va xabar ham bo'sh — qator bo'sh qolmasin.
      subtitle: (lastText != null && lastText.isNotEmpty)
          ? Text.rich(
              TextSpan(
                children: [
                  if (lastPrefix.isNotEmpty)
                    TextSpan(
                      text: lastPrefix,
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  TextSpan(text: lastText),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                // O'qilmagan xabar so'nik EMAS: aynan u e'tibor tortishi kerak.
                color: hasUnread
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: hasUnread ? FontWeight.w700 : null,
              ),
            )
          : Text(
              conversation.title.isNotEmpty ? conversation.title : t.noMessages,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: (lastAt == null && !hasUnread)
          ? const Icon(Icons.chevron_right)
          : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastAt != null)
                  Text(
                    formatTime(lastAt),
                    // 🔴 VAQT PUSHTI EMAS (2026-09-03 ko'rigi).
                    //
                    // O'qilmagan suhbatda vaqt ham, uning ostidagi
                    // nishon ham pushti edi: bitta ustunda ikkita
                    // pushti element ustma-ust turardi va «yangi
                    // xabar» degan signal ikkiga bo'linardi.
                    // Signal — NISHON; vaqt esa faqat ma'lumot,
                    // shuning uchun u sokin qoladi va yangilikni
                    // atigi QALINLIK bilan bildiradi.
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: hasUnread ? FontWeight.w800 : null,
                    ),
                  ),
                if (hasUnread) ...[
                  const SizedBox(height: AppSpace.xs),
                  _UnreadBadge(count: unread),
                ],
              ],
            ),
      onTap: () => context.push(Routes.chat, extra: conversation),
    );
  }
}

/// O'qilmagan xabarlar soni — Telegramdagidek yumaloq nishon.
///
/// 99 dan oshsa "99+": uch xonali son qatorni surib yuboradi va ismga
/// joy qolmaydi.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

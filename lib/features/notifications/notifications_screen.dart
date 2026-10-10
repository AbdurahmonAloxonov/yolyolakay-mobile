import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/app_settings.dart';
import '../../core/format.dart';
import '../../data/models/chat.dart';
import '../../l10n/strings.dart';
import '../shared/collapsing_scaffold.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../../../app/dimens.dart';
import '../shared/refreshable.dart';
import '../shared/skeleton.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final notifications = ref.watch(notificationsProvider);

    // "Hammasini o'qildi" — saytda ancha oldindan bor edi, ilovada YO'Q edi:
    // o'nta o'qilmagan bildirishnomani birma-bir bosish kerak edi.
    final unread = notifications.valueOrNull
        ?.where((item) => !item.isRead)
        .toList(growable: false);

    return CollapsingScaffold(
      title: t.notificationsTitle,
      actions: [
        if (unread != null && unread.isNotEmpty)
          TextButton(
            onPressed: () async {
              // Xatolar YUTILADI: o'qilgan belgisi kritik emas va bitta
              // yiqilgan so'rov qolganlarini to'xtatmasligi kerak.
              for (final item in unread) {
                try {
                  await ref
                      .read(notificationsRepositoryProvider)
                      .markRead(item.id);
                } catch (_) {
                  // jim
                }
              }
              ref.invalidate(notificationsProvider);
              // Status-bardagi eslatmalar ham ketadi: odam ro'yxatni
              // KO'RDI va hammasini o'qilgan deb belgiladi. Ilgari ular
              // telefonning tepasida qolib ketardi (egasi, 2026-09-04).
              await ref.read(notificationDismisserProvider).all();
            },
            child: Text(t.markAllRead),
          ),
      ],
      body: Column(
        children: [
          const PushDisabledWarning(),
          Expanded(child: _list(context, ref, t, theme, notifications)),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    AppStrings t,
    ThemeData theme,
    AsyncValue<List<NotificationItem>> notifications,
  ) {
    // 🔴 TORTIB-YANGILASH YUKLANISH VA XATODA HAM ISHLAYDI
    // (egasi, 2026-08-30). Ilgari `YolRefresh` faqat `data:` shoxida
    // edi — ya'ni ro'yxat kelmagan paytda, odam AYNAN tortmoqchi
    // bo'lganda, tortadigan narsa yo'q edi. Izohi `Refreshable` da.
    return YolRefreshable<List<NotificationItem>>(
      value: notifications,
      onRefresh: () => ref.refresh(notificationsProvider.future),
      loading: const ListSkeleton(),
      builder: (items) {
        if (items.isEmpty) {
          // qulaylik: chiqish yo'li SHART EMAS — bildirishnoma
          // odamning ishi emas, u KELADI. «Bildirishnoma yarat» degan
          // amal yo'q, sun'iy tugma esa yolg'on va'da bo'lardi.
          return EmptyView(
            icon: Icons.notifications_none,
            title: t.noNotifications,
          );
        }
        // KUNLAR bo'yicha guruhlash — chatdagi ajratgichlar bilan bir xil
        // qoida (`chatDayLabel`). Ilgari o'nta bildirishnoma ketma-ket
        // turardi va qaysi biri bugungi ekani faqat kichkina sanadan
        // bilinardi.
        //
        // Ro'yxat YASSI qoladi (ichma-ich ListView emas): sarlavha ham
        // oddiy element, shuning uchun uzun ro'yxat ham lozim darajada
        // tejamkor chiziladi.
        final rows = <Object>[];
        String? lastLabel;
        for (final item in items) {
          final label = chatDayLabel(item.createdAt, t.lang);
          if (label != lastLabel) {
            lastLabel = label;
            // Sanasi yo'q element sarlavhasiz qoladi — uni TASHLAB
            // yubormaymiz, yo'qotgandan ko'ra sarlavhasiz ko'rsatgan yaxshi.
            if (label.isNotEmpty) rows.add(_DayHeader(label));
          }
          rows.add(item);
        }

        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (context, index) =>
              rows[index] is _DayHeader || rows[index + 1] is _DayHeader
              ? const SizedBox.shrink()
              : const Divider(height: 1),
          itemBuilder: (context, index) {
            final row = rows[index];
            if (row is _DayHeader) return row;
            final item = row as NotificationItem;
            return ListTile(
              leading: Icon(
                item.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: item.isRead
                    ? theme.colorScheme.outline
                    : theme.colorScheme.primary,
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.body.isNotEmpty) Text(item.body),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    // Endi faqat VAQT: sana guruh sarlavhasiga chiqdi.
                    // Ikkalasini takrorlash sarlavhani ma'nosiz qilardi.
                    formatTime(item.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              isThreeLine: item.body.isNotEmpty,
              onTap: item.isRead
                  ? null
                  : () async {
                      // Xato bo'lsa ham ro'yxatni yangilaymiz — o'qilgan
                      // belgisi kritik emas, foydalanuvchini to'xtatmaymiz.
                      try {
                        await ref
                            .read(notificationsRepositoryProvider)
                            .markRead(item.id);
                      } catch (_) {
                        // jim
                      }
                      ref.invalidate(notificationsProvider);
                    },
            );
          },
        );
      },
    );
  }
}

/// "Bildirishnomalar o'chirilgan" ogohlantirishi.
///
/// 🔴 NEGA KERAK: Android 13+ da ruxsat bir marta so'raladi va rad etilsa
/// ilova butun umri davomida JIM qoladi. Odam esa "push kelmayapti" deb
/// ilovani (yoki serverni) ayblaydi — sababi telefonining o'zida bo'lsa ham.
/// Bu holat ochiq aytilmasa, uni topib bo'lmaydi.
class PushDisabledWarning extends ConsumerStatefulWidget {
  const PushDisabledWarning({super.key});

  @override
  ConsumerState<PushDisabledWarning> createState() =>
      _PushDisabledWarningState();
}

class _PushDisabledWarningState extends ConsumerState<PushDisabledWarning> {
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // Foydalanuvchi sozlamalarga borib yoqib qaytadi — ogohlantirish O'ZI
    // yo'qolishi kerak, aks holda u yolg'on gapirib turaveradi.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationsEnabledProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    // Holat noma'lum (yuklanmoqda/xato) bo'lsa hech nima ko'rsatilmaydi —
    // yolg'on xavotir eng yomon variant.
    final enabled = ref.watch(notificationsEnabledProvider).valueOrNull ?? true;
    if (enabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: InfoBox(
        tone: InfoTone.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_off, size: 20),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    t.pushDisabledTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(t.pushDisabledBody),
            const SizedBox(height: AppSpace.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () async {
                  final opened = await openNotificationSettings();
                  if (!context.mounted) return;
                  // Sozlamalar ochilmasa (ba'zi qobiqlarda bunday sahifa
                  // yo'q) — hech bo'lmasa yo'lni aytamiz.
                  if (!opened) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(t.pushOpenSettingsHint)),
                      );
                  }
                },
                child: Text(t.pushEnable),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              t.pushOpenSettingsHint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kun ajratgichi — "Bugun" / "Kecha" / to'liq sana.
class _DayHeader extends StatelessWidget {
  const _DayHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

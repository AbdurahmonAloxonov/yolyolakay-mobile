import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/away_digest.dart';
import '../../core/haptics.dart';
import '../../l10n/strings.dart';
import 'brand/suzani_icons.dart';

/// «SIZSIZ NIMA BO'LDI» kartasi — bosh ekranning tepasida.
///
/// Izohi va sababi `core/away_digest.dart` da: backend push yubormaydi,
/// shuning uchun o'zgarish odamning O'ZIGA aytiladi.
///
/// ⚠️ Karta HECH NIMA yangi bo'lmasa umuman chizilmaydi. «0 ta yangilik»
/// deb turadigan bo'sh karta — ekranда joy egallagan shovqin.
class AwayCard extends ConsumerStatefulWidget {
  const AwayCard({super.key});

  @override
  ConsumerState<AwayCard> createState() => _AwayCardState();
}

class _AwayCardState extends ConsumerState<AwayCard> {
  /// Ekran qayta chizilganda karta ko'z oldida yo'qolmasin: xulosa
  /// BIR MARTA hisoblanadi va shu ekran umriga qoladi.
  AwayChanges? _changes;
  bool _computed = false;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    final notifications = ref.watch(unreadCountProvider);
    final chats = ref.watch(unreadChatsProvider).valueOrNull;

    // Chat soni hali kelmagan bo'lsa kutamiz: yarim ma'lumot bilan
    // hisoblasak, «1 ta yangi xabar» o'rniga «yangilik yo'q» deyilardi.
    if (!_computed && chats != null) {
      _computed = true;
      final digest = AwayDigest(ref.read(sharedPrefsProvider));
      _changes = digest.changesSince(
        unreadNotifications: notifications,
        unreadChats: chats,
      );
      // Ko'rsatildi — baza yangilanadi, ikkinchi marta chiqmaydi.
      if (_changes != null) {
        digest.acknowledge(
          unreadNotifications: notifications,
          unreadChats: chats,
        );
      }
    }

    final changes = _changes;
    if (changes == null || _dismissed) return const SizedBox.shrink();

    final parts = <String>[
      if (changes.newMessages > 0) t.awayNewMessages(changes.newMessages),
      if (changes.newNotifications > 0)
        t.awayNewNotifications(changes.newNotifications),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      color: theme.colorScheme.secondaryContainer,
      child: ListTile(
        leading: SuzaniIconWidget(
          SuzaniIcon.chat,
          size: 22,
          color: theme.colorScheme.onSecondaryContainer,
        ),
        title: Text(
          t.awayTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        subtitle: Text(
          parts.join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        trailing: IconButton(
          tooltip: t.close,
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => setState(() => _dismissed = true),
        ),
        // Bosilganda — eng muhim joyga. Xabar bo'lsa suhbatlarga, aks
        // holda bildirishnomalarga: odam kartani bosganda "nima bo'ldi?"
        // degan savoliga JAVOB ko'rishi kerak, yana bir ro'yxatni emas.
        onTap: () {
          AppHaptics.select();
          setState(() => _dismissed = true);
          context.push(
            changes.newMessages > 0 ? Routes.chats : Routes.notifications,
          );
        },
      ),
    );
  }
}

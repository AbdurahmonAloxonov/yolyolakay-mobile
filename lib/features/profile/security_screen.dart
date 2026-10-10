import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../data/models/auth.dart';
import '../../data/models/user.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import '../../../app/dimens.dart';
import '../shared/yol_refresh.dart';
import '../shared/brand/loom_loader.dart';
import '../shared/brand/brand_panels.dart';

/// Xavfsizlik — kirilgan qurilmalar va bloklangan foydalanuvchilar.
///
/// Ikkalasi ham web'da bor edi, ilovada YO'Q edi. Sessiyalar uchun repozitoriya
/// metodi ham allaqachon yozilgan-u (`/auth/sessions`), hech qayerdan
/// chaqirilmasdi — o'lik kod bo'lib turgan.
///
/// NEGA BITTA EKRAN: ikkalasi ham "kim mening hisobimga tegishi mumkin"
/// savoliga javob beradi. Alohida ikkita band sozlamalarni yana cho'zardi.
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.securityTitle), bottom: const JiyakLine()),
      body: YolRefresh(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(sessionsProvider.future),
            ref.refresh(blockedUsersProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            SectionLabel(t.sessionsTitle),
            const _SessionsCard(),
            const SizedBox(height: AppSpace.xl),
            SectionLabel(t.blockedUsersTitle),
            const _BlockedCard(),
          ],
        ),
      ),
    );
  }
}

class _SessionsCard extends ConsumerWidget {
  const _SessionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final sessions = ref.watch(sessionsProvider);
    final currentDeviceId = ref.watch(currentDeviceIdProvider).valueOrNull;

    return Card(
      child: sessions.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpace.xl),
          child: Center(child: LoomLoader()),
        ),
        // 2026-08-13 dan repozitoriy xatoni TASHLAYDI (ilgari bo'sh ro'yxat
        // qaytarardi va "qurilma yo'q" degan yolg'on ko'rinardi).
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(sessionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyRow(text: t.noSessions);
          }
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                _SessionRow(
                  session: items[i],
                  isCurrent: items[i].deviceId == currentDeviceId,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session, required this.isCurrent});

  final Session session;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // Qurilma nomini foydalanuvchi tushunadigan qilib ko'rsatamiz: `user_agent`
    // uzun texnik satr, `os_type` esa qisqa va yetarli.
    final title = session.osType?.trim().isNotEmpty == true
        ? session.osType!
        : t.unknownDevice;

    return ListTile(
      leading: Icon(
        isCurrent ? Icons.smartphone : Icons.devices_other,
        color: isCurrent ? theme.colorScheme.primary : null,
      ),
      title: Text(isCurrent ? '$title · ${t.thisDevice}' : title),
      // 🔴 Ilgari bu yerda FAQAT IP turardi (egasi qurilmada aytdi,
      // 2026-08-13). Xavfsizlik ekranida odam bitta savolga javob izlaydi:
      // "bu men edimmi?" — unga IP emas, QACHON kirilgani kerak. Ikkita
      // "web" qatori bir-biridan faqat IP bilan farq qilardi va tanlash
      // mumkin emas edi.
      //
      // Sana MODELDA allaqachon bor edi (`created_at`), shunchaki
      // ko'rsatilmasdi — backenddan hech narsa so'ralmadi.
      subtitle: Text(
        [
          if (session.createdAt != null)
            '${t.sessionStarted}: ${formatDateTime(session.createdAt, t.lang)}',
          if (session.deviceIp?.trim().isNotEmpty == true) session.deviceIp!,
        ].join('\n'),
      ),
      isThreeLine: session.createdAt != null && session.deviceIp != null,
      // Joriy qurilmani bu yerdan chiqarib bo'lmaydi — buning uchun
      // sozlamalardagi "Hisobdan chiqish" bor va u tokenlarni ham tozalaydi.
      trailing: isCurrent
          ? null
          : IconButton(
              icon: Icon(Icons.logout, color: theme.colorScheme.error),
              tooltip: t.revokeSession,
              onPressed: () => _revoke(context, ref),
            ),
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final t = AppStrings.of(context);
    try {
      await ref.read(authRepositoryProvider).revokeSession(session.deviceId);
      ref.invalidate(sessionsProvider);
      if (context.mounted) showMessage(context, t.sessionRevoked);
    } catch (error) {
      if (!context.mounted) return;
      showApiError(context, error, ref.read(langProvider));
    }
  }
}

class _BlockedCard extends ConsumerWidget {
  const _BlockedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final blocked = ref.watch(blockedUsersProvider);

    return Card(
      child: blocked.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpace.xl),
          child: Center(child: LoomLoader()),
        ),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(blockedUsersProvider),
        ),
        data: (items) {
          if (items.isEmpty) return _EmptyRow(text: t.noBlockedUsers);
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                _BlockedRow(user: items[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BlockedRow extends ConsumerWidget {
  const _BlockedRow({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);

    // Backend eski shaklda faqat ID qaytarsa ism bo'lmaydi — ID ko'rsatamiz,
    // "Foydalanuvchi" deb yozsak ro'yxat bir xil qatorlardan iborat bo'lardi.
    final label = user.hasName ? user.displayName : user.id;

    return ListTile(
      // Bloklangan odam ham o'z suzani muhri bilan — ro'yxat "jonli" ko'rinади.
      leading: PersonAvatar(url: user.avatarUrl, radius: 18, seed: user.id),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: TextButton(
        onPressed: () => _unblock(context, ref),
        child: Text(t.unblockUser),
      ),
    );
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final t = AppStrings.of(context);
    try {
      await ref.read(usersRepositoryProvider).unblockUser(user.id);
      ref.invalidate(blockedUsersProvider);
      if (context.mounted) showMessage(context, t.unblockDone);
    } catch (error) {
      if (!context.mounted) return;
      showApiError(context, error, ref.read(langProvider));
    }
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpace.xl),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.outline,
      ),
    ),
  );
}

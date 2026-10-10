import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/env.dart';
import '../../core/format.dart';
import '../../core/local_cache.dart';
import '../../core/outbox.dart';
import '../../core/push.dart';
import '../../l10n/strings.dart';
import '../shared/yol_refresh.dart';
import '../shared/ui.dart';
import '../shared/brand/brand_panels.dart';

/// XIZMAT HOLATI — «nima ishlayapti, nima yo'q» degan savolga bitta javob.
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): uzilish bu ilovada
/// ODATIY hol — u shaharlararo yo'lda ishlatiladi va backend uy
/// mashinasida turadi (502 ham bo'lib turadi). Ilgari uzilish paytida
/// odam FAQAT bo'sh ro'yxat va tepadagi qora chiziqni ko'rardi. Undan
/// keyingi savol doim bir xil: «ilova buzuqmi, telefonimmi, internetmi?»
/// — va javob hech qayerda yo'q edi. Javobsiz uzilish esa ishonchni
/// yo'qotadi.
///
/// Bu ekran uzilishni ISHONCH nuqtasiga aylantiradi: nima ishlamayotgani
/// ochiq aytiladi, oxirgi muvaffaqiyatli sinxron vaqti ko'rsatiladi va
/// yuborilmagan ishlar soni yashirilmaydi.
///
/// ⚠️ BU YERDA HECH QANDAY TAXMIN YO'Q. Har qator — o'lchangan haqiqat:
///   • internet — `ApiClient.connected` (so'rov javob oldimi, `connectivity`
///     paketining «Wi-Fi ulangan» degan taxmini EMAS);
///   • jonli aloqa — WebSocket handshake haqiqatan ochilganmi;
///   • bildirishnoma — tizim ruxsati;
///   • oxirgi sinxron — keshning O'Z vaqt tamg'asi.
class ServiceStatusScreen extends ConsumerStatefulWidget {
  const ServiceStatusScreen({super.key});

  @override
  ConsumerState<ServiceStatusScreen> createState() =>
      _ServiceStatusScreenState();
}

class _ServiceStatusScreenState extends ConsumerState<ServiceStatusScreen> {
  bool? _pushAllowed;

  @override
  void initState() {
    super.initState();
    _readPush();
  }

  Future<void> _readPush() async {
    final allowed = await notificationsEnabled();
    if (mounted) setState(() => _pushAllowed = allowed);
  }

  /// Keshdagi eng SO'NGGI muvaffaqiyatli javob vaqti.
  ///
  /// Bitta ro'yxatniki emas, hammasining eng yangisi: odam uchun savol
  /// «ma'lumot qachonlik?» — qaysi ro'yxat ekani ikkinchi darajali.
  DateTime? _lastSync() {
    final cache = ref.read(localCacheProvider);
    DateTime? newest;
    for (final key in const [
      CacheKeys.myRides,
      CacheKeys.myBookings,
      CacheKeys.conversations,
      CacheKeys.notifications,
    ]) {
      final at = cache.cachedAt(key);
      if (at == null) continue;
      if (newest == null || at.isAfter(newest)) newest = at;
    }
    return newest;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final api = ref.watch(apiClientProvider);
    final ws = ref.watch(wsClientProvider);
    final outbox = ref.watch(outboxProvider);
    final lastSync = _lastSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.serviceStatusTitle),
        bottom: const JiyakLine(),
      ),
      // 🔴 TORTIB-YANGILASH (2026-08-30): bu ekranning butun ma'nosi
      // «hozir nima ishlayapti» degan savolda, ya'ni odam bu yerda
      // ALBATTA yangilamoqchi bo'ladi — lekin tortish ishlamasdi va
      // ekranni yopib-ochishdan boshqa yo'l yo'q edi.
      body: YolRefresh(
        onRefresh: () async {
          await _readPush();
          if (mounted) setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            Text(t.serviceStatusIntro, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpace.lg),

            ValueListenableBuilder<bool>(
              valueListenable: api.connected,
              builder: (context, online, _) => _StatusRow(
                icon: online ? Icons.cloud_done_outlined : Icons.cloud_off,
                label: t.statusInternet,
                value: online ? t.statusWorking : t.statusDown,
                ok: online,
              ),
            ),

            ValueListenableBuilder<bool>(
              valueListenable: ws.online,
              builder: (context, live, _) => _StatusRow(
                icon: live ? Icons.bolt : Icons.bolt_outlined,
                label: t.statusLive,
                value: live ? t.statusWorking : t.statusDown,
                ok: live,
                // 🔴 Jonli aloqa uzilishi FALOKAT EMAS: chat tarixi baribir
                // so'raladi, xabar esa navbatda saqlanadi. Shuning uchun
                // qizil emas, kutish rangida.
                warnOnly: true,
              ),
            ),

            _StatusRow(
              icon: _pushAllowed == false
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined,
              label: t.statusNotifications,
              value: switch (_pushAllowed) {
                null => t.statusChecking,
                true => t.statusAllowed,
                false => t.statusBlocked,
              },
              ok: _pushAllowed != false,
              warnOnly: true,
            ),

            const SizedBox(height: AppSpace.lg),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: AppSpace.md),

            // OXIRGI SINXRON — «ekrandagi ma'lumot qanchalik yangi?»
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: Text(t.statusLastSync),
              subtitle: Text(
                lastSync == null
                    ? t.statusNeverSynced
                    : formatDateTime(lastSync, t.lang),
              ),
            ),

            // NAVBAT — yuborilmagan ishlar YASHIRILMAYDI.
            ValueListenableBuilder<List<OutboxItem>>(
              valueListenable: outbox.items,
              builder: (context, queued, _) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_send_outlined),
                title: Text(t.statusQueue),
                subtitle: Text(
                  queued.isEmpty
                      ? t.statusQueueEmpty
                      : t.queuedCount(queued.length),
                ),
                trailing: queued.isEmpty
                    ? null
                    : TextButton(
                        onPressed: () => outbox.flush(),
                        child: Text(t.statusRetry),
                      ),
              ),
            ),

            // TASHLANGAN — jim yo'qotmaymiz (`core/outbox.dart` qoidasi).
            ValueListenableBuilder<int>(
              valueListenable: outbox.dropped,
              builder: (context, dropped, _) => dropped == 0
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpace.sm),
                      child: InfoBox(
                        tone: InfoTone.warning,
                        child: Text(
                          t.statusDropped(dropped),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: AppSpace.lg),
            Text(
              '${t.appVersionLabel}: ${Env.appVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ok,
    this.warnOnly = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ok;

  /// Nosozlik JIDDIY emas — sariq, qizil emas.
  final bool warnOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ok
        ? scheme.primary
        : warnOnly
        ? scheme.tertiary
        : scheme.error;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

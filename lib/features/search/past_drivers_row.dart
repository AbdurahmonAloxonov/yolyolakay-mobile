import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/cities.dart';
import '../../core/haptics.dart';
import '../../data/models/chat.dart';
import '../../l10n/strings.dart';
import '../shared/ui.dart';

/// «YANA O'SHA HAYDOVCHI BILAN» — qidiruv ekranidagi qator.
///
/// Sabab va halol cheklovlar `pastDriversProvider` izohida
/// (`app/providers.dart`): tarmoqqa chiqmaydi, haydovchi bo'yicha qidiruv
/// ruchkasi esa umuman yo'q.
class PastDriversRow extends ConsumerWidget {
  const PastDriversRow({super.key, required this.onRoute});

  /// Yo'nalish tanlanganda — qidiruv formasini to'ldiradi va qidiradi.
  final void Function(Place from, Place to) onRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(pastDriversProvider);
    if (drivers.isEmpty) return const SizedBox.shrink();

    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.xl),
        Text(
          t.pastDriversTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: drivers.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
            itemBuilder: (context, index) {
              final past = drivers[index];
              return _DriverChip(
                past: past,
                onTap: () => _open(context, ref, past),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    PastDriver past,
  ) async {
    AppHaptics.select();
    final t = AppStrings.of(context);
    final ride = past.ride;

    // Yo'nalish nomlari koordinata bilan birga — qidiruv AYNAN o'sha
    // nuqtalardan boradi (nom bo'yicha qayta yechish boshqa joyga tushishi
    // mumkin, radius esa mos kelmay qolardi).
    final from = Place(
      name: ride.originAddress,
      lat: ride.originLat,
      lon: ride.originLon,
      region: '',
    );
    final to = Place(
      name: ride.destinationAddress,
      lat: ride.destinationLat,
      lon: ride.destinationLon,
      region: '',
    );

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PersonAvatar(
                url: past.driver.avatar,
                radius: 20,
                gender: past.driver.gender,
                seed: past.driver.id ?? past.driver.name,
              ),
              title: Text(past.driver.name ?? t.driver),
              subtitle: Text('${from.name} → ${to.name}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(t.pastDriverSearchRoute),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onRoute(from, to);
              },
            ),
            // 🔴 «Uning safarlari» degan bo'lim ATAYIN YO'Q: gateway'da
            // haydovchi bo'yicha qidiruv ruchkasi yo'q va bo'sh ro'yxat
            // ko'rsatish «u endi yurmaydi» degan yolg'on taassurot
            // berardi. Yozish esa BUGUN ishlaydi.
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(t.pastDriverMessage),
              subtitle: Text(t.pastDriverMessageHint),
              onTap: () {
                Navigator.of(sheetContext).pop();
                final id = past.driver.id;
                if (id == null || id.isEmpty) return;
                context.push(
                  Routes.chat,
                  extra: Conversation(
                    rideId: ride.id,
                    peerId: id,
                    title: past.driver.name ?? t.driver,
                    avatarUrl: past.driver.avatar,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverChip extends StatelessWidget {
  const _DriverChip({required this.past, required this.onTap});

  final PastDriver past;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = past.driver.name ?? AppStrings.of(context).driver;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            PersonAvatar(
              url: past.driver.avatar,
              radius: 26,
              gender: past.driver.gender,
              seed: past.driver.id ?? name,
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

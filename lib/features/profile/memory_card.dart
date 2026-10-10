import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/share_safely.dart';

import '../../app/dimens.dart';
import '../../app/theme.dart';
import '../../core/haptics.dart';
import '../../data/models/user.dart';
import '../../app/providers.dart';
import '../../l10n/strings.dart';
import '../shared/brand/ornament.dart';
import '../shared/brand/loom_loader.dart';
import '../shared/brand/suzani_avatar.dart';

/// YO'L XOTIRASI — ulashiладиган brend kartаsи.
///
/// 🔴 Egasi (2026-08-20): "boshqa carpooling ilovaларида yo'q" — Spotify
/// Wrapped uslubида, lekin milliy. Odam o'z "yo'l muhrини" do'stlarига
/// ulashса — ilова o'zини tarqаtади.
///
/// 🔴 HALOL MA'LUMOT (loyiha qoidаси: "o'lchама, ishonма"): backendда safar
/// KILOMETRи, shahar soni yoki CO2 uchun ISHONCHLI endpoint YO'Q. Shuning
/// uchun kartа FAQAT rost maydonlардан quriladi — reyting, sharhlар soni,
/// Rol va odamning shaxsiy suzani muhrи. Soxta "1000 km"
/// yozилмайди. Backend safar-xulоса endpointи chiqса, shu yerга qo'shilади.
class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.memoryCardTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _CardBody(user: user, capture: _boundaryKey),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: AppSize.buttonHeight,
              child: FilledButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.ios_share),
                label: Text(t.memoryShare),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _boundaryKey = GlobalKey();

  /// Kartани PNG'ga aylantirib tizim "ulashish" oynasига beradi.
  Future<void> _share(BuildContext context) async {
    final t = AppStrings.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return shareFallback(messenger, t, null);
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return shareFallback(messenger, t, null);
      AppHaptics.select();
      // `fromData` — vaqtinchalik faylсиз (path_provider kerak emas).
      final xfile = XFile.fromData(
        bytes.buffer.asUint8List(),
        mimeType: 'image/png',
        name: 'yol_xotira.png',
      );
      if (!context.mounted) return;
      await shareSafely(
        context,
        ShareParams(files: [xfile], text: t.memoryTagline),
      );
    } catch (_) {
      // Rasm tayyorlanmadi — jim qolmaymiz (izohi `shareSafely` da).
      await shareFallback(messenger, t, null);
    }
  }
}

/// Odamning muhr rangi (suzani_avatar.dart bilan bir xil hash+hue) — Wrapped
/// fon ohangი shaxsiy bo'lsin uchun.
Color _sealHue(String seed) {
  var h = 2166136261;
  for (final c in seed.codeUnits) {
    h = (h ^ c) * 16777619 & 0x7fffffff;
  }
  final hue = 175 + (h % 110);
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.55).toColor();
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.user, required this.capture});

  final User user;
  final GlobalKey capture;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final showRating = user.showRating;
    // Karта DOIM to'q neon fonда — ulashilганда qaysи mavzuда bo'lса ham
    // bir xil, "porloq" ko'rinади.
    return RepaintBoundary(
      key: capture,
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: BrandColors.neonDarkBg),
          child: Stack(
            children: [
              Positioned.fill(
                // Har odamga NOYOB girih fon — muhri bilan bir xil
                // ohangda (id'dan hue, suzani muhri bilan bir manba).
                child: GirihPattern(
                  cell: 104,
                  color: _sealHue(user.id).withValues(alpha: 0.18),
                  cut: BrandColors.neonDarkBg,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpace.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t.appName,
                      style: TextStyle(
                        color: BrandColors.neonAqua,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    // Shaxsiy suzani muhrи — porloq halqа ичida.
                    Container(
                      padding: const EdgeInsets.all(AppSpace.sm),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.neonPink.withValues(alpha: 0.6),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SuzaniAvatar(seed: user.id, size: 120),
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Text(
                      user.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      user.isDriver ? t.driver : t.memoryPassenger,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showRating) ...[
                          _Stat(
                            value: user.rating!.toStringAsFixed(1),
                            label: t.statRating,
                          ),
                          const SizedBox(width: AppSpace.xxl),
                          _Stat(
                            value: '${user.ratingCount ?? 0}',
                            label: t.statReviews,
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      t.memoryTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: BrandColors.neonPink,
            fontWeight: FontWeight.w800,
            fontSize: 30,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Route o'rami — joriy foydalanuvchini `meProvider`dan oladi.
class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return me.when(
      loading: () => const Scaffold(body: Center(child: LoomLoader())),
      error: (_, _) => const Scaffold(body: SizedBox.shrink()),
      data: (data) => MemoryCard(user: data.user),
    );
  }
}

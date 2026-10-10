import 'package:flutter/material.dart';

import '../../core/media_url.dart';
import '../../l10n/strings.dart';

/// Rasmни TO'LIQ EKRANДА ko'rsatadi — zoom (barmoq bilan kattalashtirish) va
/// surish bilan.
///
/// 🔴 Egasi (2026-08-20): avatar/hujjat/safar rasm bosilса to'liq ochilsin.
/// Ilgari ular kichkinada qolardi va batafsil ko'rib bo'lmasdi (masalan
/// texnik pasport raqamини o'qish).
///
/// URL bo'sh yoki noto'g'ri bo'lса — OCHILMAYDI (bo'sh oyna chiqmasin).
Future<void> showImageViewer(BuildContext context, String? url) {
  final resolved = mediaUrl(url);
  if (resolved == null) return Future<void>.value();

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (context) => _ImageViewer(url: resolved),
  );
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Stack(
      children: [
        // Fon bosilса yopiladi.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
          ),
        ),
        Center(
          // Zoom 1x..4x, surish bilan.
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              // Yuklanаётганда aylanма; xato bo'lса — belgi.
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
              errorBuilder: (context, error, stack) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        // Yopish tugmasi — tepа o'ngда.
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: IconButton(
              tooltip: t.close,
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ],
    );
  }
}

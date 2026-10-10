import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// "Yuqoriga" tugmasi — uzun ro'yxatда pastга tushgач ko'rinadi.
///
/// 🔴 Egasi (2026-08-20): uzun ro'yxatда (safarlar, chat, tarix) pastга
/// tushgач yuqoriга qaytish tugмаsi. Ilgari faqat qo'lда uzoq surish
/// kerak edi.
///
/// ISHLASHI: berilgаn `controller`ни tinglaydi, ro'yxat bir ekrandan
/// KO'PROQ tushgаndagina ko'rinadi (aks holда u ortiqcha). Bosilsa yuqoriга
/// silliq qaytaradi. Ro'yxatли ekranда `Stack` ostiga qo'yiladi.
class ScrollTopFab extends StatefulWidget {
  const ScrollTopFab({super.key, required this.controller});

  final ScrollController controller;

  @override
  State<ScrollTopFab> createState() => _ScrollTopFabState();
}

class _ScrollTopFabState extends State<ScrollTopFab> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    // Bir ekran balandligidan ko'proq tushilgаndagina.
    final show =
        widget.controller.hasClients &&
        widget.controller.offset > MediaQuery.sizeOf(context).height;
    if (show != _show) setState(() => _show = show);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _show ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: FloatingActionButton.small(
        // 🔴 NOMI BO'LSIN (2026-09-04, o'lchandi): faqat ikonkali tugma
        // ekran o'qigichga «tugma» bo'lib eshitilardi. `tooltip` ayni
        // paytda ekran o'qigich yorlig'i ham bo'ladi.
        tooltip: AppStrings.of(context).scrollToTop,
        onPressed: () => widget.controller.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 3,
        child: const Icon(Icons.keyboard_arrow_up),
      ),
    );
  }
}

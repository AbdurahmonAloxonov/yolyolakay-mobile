import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/active_role.dart';
import '../../app/providers.dart';
import '../../l10n/strings.dart';
import '../../app/dimens.dart';
import '../shared/refreshable.dart';
import '../shared/notification_bell.dart';
import '../shared/settings_button.dart';
import '../shared/state_views.dart';
import 'create_parcel_screen.dart';
import 'find_parcels_screen.dart';
import 'my_parcels_screen.dart';
import '../shared/brand/loom_loader.dart';

/// Pochta bo'limi.
///
/// Tablar rolga qarab yig'iladi:
///   • "Yuborish" va "Mening pochtalarim" — HAMMAGA;
///   • "Pochta topish" — faqat haydovchiga, chunki backend qidiruvi
///     `driver_id` talab qiladi va u haydovchi bo'lmaganda mavjud emas.
///
/// "Mening pochtalarim" 2026-08-12 da qo'shildi: `GET /parcels/my` gateway'da
/// paydo bo'lgani aniqlandi. Undan oldin yuboruvchi o'z posilkasini e'lon
/// qilgach BOSHQA KO'RA OLMASDI va kelgan taklifni qabul qila olmasdi.
class ParcelsScreen extends ConsumerWidget {
  const ParcelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final me = ref.watch(meProvider);

    // Profil yuklanmaguncha kutamiz: `?? false` bilan boshlansa yo'lovchi
    // ko'rinishi chizilib, keyin tabli ko'rinishga sakrardi.
    if (me.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.parcelsTitle),
          actions: const [NotificationBell(), SettingsButton()],
        ),
        // Yuklanish paytida ham tortib bo'lsin: profil kelmasa butun
        // pochta ekrani shu holatda qoladi va odam aynan shunda
        // tortadi (izohi `refreshableState` da).
        body: refreshableState(
          onRefresh: () => ref.refresh(meProvider.future),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.huge),
            child: Center(child: LoomLoader()),
          ),
        ),
      );
    }

    /*
     * 🔴 `me.value` EMAS, `me.valueOrNull` (2026-08-30 auditi).
     *
     * Riverpod'da `AsyncValue.value` xato holatida qiymat qaytarmaydi —
     * XATONI QAYTA TASHLAYDI. Ya'ni `/users/me` yiqilsa (tarmoq uzildi,
     * token eskirdi, backend 502) butun POCHTA EKRANI qulab tushardi va
     * odam bo'sh/qizil ekran ko'rardi. Auditda aynan shu ushlandi:
     *     ApiException(badRequest, status: 400) @ parcels_screen.dart:43
     *
     * `valueOrNull` esa `null` beradi va ekran quyidagi xato holatiga
     * o'tadi — odam nima bo'lganini ko'radi va qayta urina oladi.
     */
    if (me.hasError && !me.hasValue) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.parcelsTitle),
          actions: const [NotificationBell(), SettingsButton()],
        ),
        // Xatoda ham tortib bo'lsin — odamning birinchi refleksi shu
        // (izohi `refreshableState` da).
        body: refreshableState(
          onRefresh: () => ref.refresh(meProvider.future),
          child: ErrorView(
            error: me.error!,
            onRetry: () => ref.refresh(meProvider.future),
          ),
        ),
      );
    }

    final isDriver = me.valueOrNull?.user.isDriver == true;
    final driverMode = isDriver && ref.watch(isDriverModeProvider);

    // 🔴 ROL = MAZMUN. Ilgari haydovchida uchala yorliq birdan turardi
    // (yuborish + meniki + topish) va rol faqat qaysi biri ochilishini
    // hal qilardi. Endi ekran faqat joriy rolning ishini ko'rsatadi:
    //   haydovchi — yuk topish va o'zi olib ketayotganlari;
    //   yo'lovchi — pochta yuborish va o'z jo'natmalari.
    // Ikkinchi tomonga o'tish — sarlavhadagi almashtirgich.
    final tabs = driverMode
        ? <Tab>[Tab(text: t.tabFind), Tab(text: t.carryingParcels)]
        : <Tab>[Tab(text: t.tabSend), Tab(text: t.tabMyParcels)];

    final views = driverMode
        ? const <Widget>[FindParcelsView(), CarryingParcelsView()]
        : const <Widget>[CreateParcelView(), MyParcelsView()];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.parcelsTitle),
          actions: const [NotificationBell(), SettingsButton()],
          bottom: TabBar(tabs: tabs),
        ),
        body: TabBarView(children: views),
      ),
    );
  }
}

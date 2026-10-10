import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../core/cities.dart';
import '../../core/format.dart';
import '../../data/models/parcel.dart';
import '../../l10n/strings.dart';
import '../map/route_preview_map.dart';
import '../search/city_picker.dart';
import '../shared/bottom_action_bar.dart';
import '../shared/city_field.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';
import '../shared/yol_button.dart';

/// Pochta yuborish.
///
/// Yuborilgach posilka «Mening pochtalarim» tabida ko'rinadi (`/parcels/my`).
class CreateParcelView extends ConsumerStatefulWidget {
  const CreateParcelView({super.key});

  @override
  ConsumerState<CreateParcelView> createState() => _CreateParcelViewState();
}

class _CreateParcelViewState extends ConsumerState<CreateParcelView> {
  final _price = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _description = TextEditingController();

  Place? _from;
  Place? _to;
  String? _size;
  DateTime? _deliverBy;
  bool _saving = false;

  @override
  void dispose() {
    _price.dispose();
    _receiverPhone.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppStrings.of(context);
    final from = _from;
    final to = _to;

    if (from == null || to == null) {
      showMessage(context, t.pickBothCities);
      return;
    }
    if (from.name == to.name) {
      showMessage(context, t.sameCityError);
      return;
    }

    // Narx va raqam MAJBURIY — backend `POST /parcels` da ikkalasini
    // `required` qilgan. Ilgari bo'sh yuborilardi va odam nima
    // xato qilganini tushunmaydigan 400 olardi.
    final price = double.tryParse(_price.text.replaceAll(' ', ''));
    if (price == null || price <= 0) {
      showMessage(context, t.priceRequired);
      return;
    }

    final phoneDigits = _receiverPhone.text.trim();
    if (phoneDigits.isEmpty) {
      showMessage(context, t.phoneRequired);
      return;
    }
    if (phoneDigits.length != 9) {
      showMessage(context, t.invalidPhone);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(parcelsRepositoryProvider)
          .create(
            CreateParcelRequest(
              originLat: from.lat,
              originLon: from.lon,
              destinationLat: to.lat,
              destinationLon: to.lon,
              // Manzil MATNI ham majburiy. Tanlangan joy nomi yuboriladi —
              // shu bilan ro'yxatda koordinatadan taxmin qilish o'rniga
              // haqiqiy nom ko'rinadi.
              fromAddress: from.name,
              toAddress: to.name,
              price: price,
              receiverPhone: toE164(phoneDigits),
              size: _size,
              description: _description.text,
              deliverBy: _deliverBy,
            ),
          );
      if (!mounted) return;
      showMessage(context, t.parcelCreated);
      // "Mening pochtalarim" YONMA-YON tab: `TabBarView` uni ekrandan
      // chiqqanda ham tirik saqlaydi, ya'ni `autoDispose` ishga tushmaydi va
      // eski (bo'sh) natija keshda qolib ketardi — odam posilkasini
      // joylab, qo'shni tabga o'tib "hali pochta joylamagansiz" ko'rardi.
      ref.invalidate(myParcelsProvider);
      setState(() {
        _from = null;
        _to = null;
        _size = null;
        _deliverBy = null;
      });
      _price.clear();
      _receiverPhone.clear();
      _description.clear();
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, t.lang);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    // Tab ichidagi o'z `Scaffold`i: "Yuborish" tugmasi pastda qotib turishi
    // uchun. Tashqi `ParcelsScreen` ning `bottomNavigationBar`iga qo'yib
    // bo'lmaydi — u uchala tabga umumiy bo'lib qolardi.
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          Card(
            child: Column(
              children: [
                CityField(
                  label: t.from,
                  city: _from,
                  dot: Theme.of(context).colorScheme.primary,
                  railDown: true,
                  onTap: () async {
                    final place = await showPlacePicker(context, exclude: _to);
                    if (place != null) setState(() => _from = place);
                  },
                ),
                const Divider(height: 1, indent: 56),
                CityField(
                  label: t.to,
                  city: _to,
                  dot: Theme.of(context).colorScheme.secondary,
                  railUp: true,
                  onTap: () async {
                    final place = await showPlacePicker(
                      context,
                      exclude: _from,
                    );
                    if (place != null) setState(() => _to = place);
                  },
                ),
              ],
            ),
          ),
          /*
           * YO'L KO'RIGI — 16.09.2026.
           *
           * 🔴 Jo'natuvchi ikkita NOM tanlardi ("Chortoq", "Namangan") va
           * shu bilan tugardi: pochta qayerdan qayerga, qanchalik uzoq
           * ketishini ko'rmasdi. Xaritadan aniq nuqta tanlash (masalan
           * "metro yonida") allaqachon mumkin edi-yu, tanlangandan keyin
           * uni TEKSHIRIB bo'lmasdi — noto'g'ri nuqta faqat haydovchi
           * qo'ng'iroq qilganda ma'lum bo'lardi.
           *
           * Ko'rik faqat IKKALASI tanlanganda chiqadi va tinch turadi:
           * u bilan o'ynab bo'lmaydi, forma surilishini buzmaydi.
           */
          if (_from != null && _to != null) ...[
            const SizedBox(height: AppSpace.md),
            RoutePreviewMap(
              waypoints: [
                LatLng(_from!.lat, _from!.lon),
                LatLng(_to!.lat, _to!.lon),
              ],
              height: 140,
              originName: _from!.name,
              destinationName: _to!.name,
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              t.parcelRoutePreview,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],

          const SizedBox(height: AppSpace.lg),

          // HAJM — haydovchi uchun eng muhim savol: mashinaga sig'adimi.
          // Narxdan OLDIN turadi, chunki odam avval nima yuborayotganini
          // o'ylaydi, keyin necha pul turishini.
          Text(t.parcelSize, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpace.sm),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'small', label: Text(t.parcelSizeSmall)),
              ButtonSegment(value: 'medium', label: Text(t.parcelSizeMedium)),
              ButtonSegment(value: 'large', label: Text(t.parcelSizeLarge)),
            ],
            selected: _size == null ? const <String>{} : {_size!},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: (sel) =>
                setState(() => _size = sel.isEmpty ? null : sel.first),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            t.parcelSizeHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),

          const SizedBox(height: AppSpace.md),
          TextField(
            // Klaviaturada «Keyingi» — fokus keyingi maydonga o'zi o'tadi.
            // Busiz odam har maydondan keyin klaviaturani yopib, keyingisini
            // qo'li bilan izlardi (`textInputAction` butun ilovada UMUMAN
            // yo'q edi — 2026-08-25 auditi).
            controller: _description,
            textInputAction: TextInputAction.next,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: t.parcelDescription,
              helperText: t.parcelDescriptionHint,
            ),
          ),

          const SizedBox(height: AppSpace.xs),
          // Muddat IXTIYORIY: bo'sh qolsa "muhim emas" deb ko'rsatiladi.
          // Majburiy qilish yuboruvchini o'ylab topilgan sana yozishga
          // majburlardi va haydovchini aldardi.
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(t.parcelDeliverBy),
            subtitle: Text(
              _deliverBy == null
                  ? t.parcelDeliverByAny
                  : formatDate(_deliverBy, t.lang),
            ),
            trailing: _deliverBy == null
                ? const Icon(Icons.chevron_right)
                : IconButton(
                    tooltip: t.removeItem,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _deliverBy = null),
                  ),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _deliverBy ?? now.add(const Duration(days: 1)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _deliverBy = picked);
            },
          ),

          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _price,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: t.parcelPrice,
              helperText: t.parcelPriceHint,
              suffixText: t.sum,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _receiverPhone,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.phone,
            maxLength: 9,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: t.receiverPhone,
              helperText: t.receiverPhoneHint,
              prefixText: '+998 ',
            ),
          ),
        ],
      ),
      // "Yuborish" DOIM ko'rinadi. Ilgari u formaning oxirida edi: narx va
      // qabul qiluvchi raqami eng pastdagi maydonlar, ular to'ldirilayotganda
      // klaviatura tugmani butunlay yopib qo'yardi.
      // Panel ro'yxatdan CHIZIQ bilan ajraladi — aks holda tor ekranda
      // oxirgi maydonga yopishib, forma davomidek ko'rinadi
      // (izohi `BottomActionBar` da).
      bottomNavigationBar: BottomActionBar(
        // `YolButton` — yuklanishda YOZUV QOLADI (ilgari matn spinnerga
        // almashardi va tugma sakrab kichrayardi). Izohi `yol_button.dart` da.
        child: YolButton(
          onPressed: _saving ? null : _submit,
          busy: _saving,
          icon: Icons.local_shipping_outlined,
          label: t.sendParcel,
        ),
      ),
    );
  }
}

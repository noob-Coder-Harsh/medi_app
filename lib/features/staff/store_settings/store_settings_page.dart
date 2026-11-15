import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_store.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import '../ui/staff_ui.dart';
import 'store_settings_controller.dart';

enum _EditSectionId {
  status,
  profile,
  orders,
  location,
  licenses,
  timings,
  product,
  payments,
  branding,
}

const Color _kMint = Color(0xFFE6F4F1);
const Color _kMintSoft = Color(0xFFF0FDFA);
const Color _kMintBorder = Color(0xFFCCFBF1);
const Color _kLabel = Color(0xFF64748B);
const Color _kValue = Color(0xFF0F172A);
const double _kFieldGap = 10;
const EdgeInsets _kDensePad = EdgeInsets.symmetric(horizontal: 12, vertical: 12);

class StoreSettingsPage extends ConsumerStatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  ConsumerState<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends ConsumerState<StoreSettingsPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _gst = TextEditingController();
  final _drugLicense = TextEditingController();
  final _pharmacist = TextEditingController();
  final _pharmacistReg = TextEditingController();
  final _opens = TextEditingController();
  final _closes = TextEditingController();
  final _logoUrl = TextEditingController();
  final _bannerUrl = TextEditingController();
  final _upiId = TextEditingController();
  final _upiQrUrl = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _radius = TextEditingController();
  final _minOrder = TextEditingController();
  final _deliveryFee = TextEditingController();
  final _freeAbove = TextEditingController();

  bool _modulePickup = false;
  bool _moduleDelivery = false;
  bool _allowCod = false;
  bool _allowManualUpi = false;
  bool _allowPrescription = false;
  bool _isOpen = true;
  bool _isActive = true;
  bool _trackStock = true;
  String _salePolicy = 'loose_allowed';
  String? _boundStoreId;
  _EditSectionId? _expanded = _EditSectionId.status;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _description.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _gst.dispose();
    _drugLicense.dispose();
    _pharmacist.dispose();
    _pharmacistReg.dispose();
    _opens.dispose();
    _closes.dispose();
    _logoUrl.dispose();
    _bannerUrl.dispose();
    _upiId.dispose();
    _upiQrUrl.dispose();
    _lat.dispose();
    _lng.dispose();
    _radius.dispose();
    _minOrder.dispose();
    _deliveryFee.dispose();
    _freeAbove.dispose();
    super.dispose();
  }

  void _bind(StaffStore store, {bool force = false}) {
    if (!force && _boundStoreId == store.id) return;
    _boundStoreId = store.id;
    _name.text = store.name;
    _phone.text = store.phone ?? '';
    _whatsapp.text = store.whatsappNumber ?? '';
    _email.text = store.email ?? '';
    _description.text = store.description ?? '';
    _address.text = store.address ?? '';
    _city.text = store.city ?? '';
    _state.text = store.state ?? '';
    _pincode.text = store.pincode ?? '';
    _gst.text = store.gstNumber ?? '';
    _drugLicense.text = store.drugLicenseNumber ?? '';
    _pharmacist.text = store.pharmacistName ?? '';
    _pharmacistReg.text = store.pharmacistRegistrationNo ?? '';
    _opens.text = store.openingTime ?? '';
    _closes.text = store.closingTime ?? '';
    _logoUrl.text = store.logoUrl ?? '';
    _bannerUrl.text = store.bannerUrl ?? '';
    _upiId.text = store.upiId ?? '';
    _upiQrUrl.text = store.upiQrUrl ?? '';
    _lat.text = store.latitude?.toString() ?? '';
    _lng.text = store.longitude?.toString() ?? '';
    _radius.text = store.serviceRadiusKm.toString();
    _minOrder.text = store.minimumOrderAmount.toString();
    _deliveryFee.text = store.deliveryCharge.toString();
    _freeAbove.text = store.freeDeliveryAbove?.toString() ?? '';
    _modulePickup = store.modulePickup;
    _moduleDelivery = store.moduleDelivery;
    _allowCod = store.allowCod;
    _allowManualUpi = store.allowManualUpi;
    _allowPrescription = store.allowPrescriptionUpload;
    _isOpen = store.isOpen;
    _isActive = store.isActive;
    _trackStock = store.trackStock;
    _salePolicy = store.salePolicy;
  }

  UpdateStoreInput _input() {
    double? parseNum(String raw) => double.tryParse(raw.trim());
    String? emptyToNull(String raw) {
      final t = raw.trim();
      return t.isEmpty ? null : t;
    }

    return UpdateStoreInput(
      name: _name.text.trim(),
      phone: emptyToNull(_phone.text),
      email: emptyToNull(_email.text),
      description: emptyToNull(_description.text),
      gstNumber: emptyToNull(_gst.text),
      drugLicenseNumber: emptyToNull(_drugLicense.text),
      pharmacistName: emptyToNull(_pharmacist.text),
      pharmacistRegistrationNo: emptyToNull(_pharmacistReg.text),
      address: emptyToNull(_address.text),
      city: emptyToNull(_city.text),
      state: emptyToNull(_state.text),
      pincode: emptyToNull(_pincode.text),
      latitude: parseNum(_lat.text),
      longitude: parseNum(_lng.text),
      logoUrl: emptyToNull(_logoUrl.text),
      bannerUrl: emptyToNull(_bannerUrl.text),
      whatsappNumber: emptyToNull(_whatsapp.text),
      openingTime: emptyToNull(_opens.text),
      closingTime: emptyToNull(_closes.text),
      serviceRadiusKm: parseNum(_radius.text),
      minimumOrderAmount: parseNum(_minOrder.text),
      deliveryCharge: parseNum(_deliveryFee.text),
      freeDeliveryAbove: parseNum(_freeAbove.text),
      allowCod: _allowCod,
      allowManualUpi: _allowManualUpi,
      allowPrescriptionUpload: _allowPrescription,
      modulePickup: _modulePickup,
      moduleDelivery: _moduleDelivery,
      upiId: emptyToNull(_upiId.text),
      upiQrUrl: emptyToNull(_upiQrUrl.text),
      isOpen: _isOpen,
      isActive: _isActive,
      salePolicy: _salePolicy,
      trackStock: _trackStock,
    );
  }

  Future<void> _save() async {
    final error =
        await ref.read(storeSettingsProvider.notifier).save(_input());
    if (!mounted) return;
    final store = ref.read(storeSettingsProvider).store;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (store != null && store.acceptsOnlineOrders
                  ? '${t('WRITE_LOADING_SAVE')} · online'
                  : t('WRITE_LOADING_SAVE')),
        ),
      ),
    );
    if (error == null && store != null) {
      setState(() => _bind(store, force: true));
      if (!mounted) return;
      staffBack(context, fallback: Routes.staffStore);
    }
  }

  void _onSectionTap(_EditSectionId id) {
    setState(() {
      _expanded = _expanded == id ? null : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(storeSettingsProvider);
    final theme = Theme.of(context);
    final store = state.store;
    final busy = state.busy;

    if (store != null && _boundStoreId != store.id) {
      _bind(store);
    }

    return Scaffold(
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context, fallback: Routes.staffStore),
        ),
        title: t('MORE.EDIT_STORE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            enabled: !busy,
            onPressed: () =>
                ref.read(storeSettingsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.loading && store == null
          ? const Center(child: CircularProgressIndicator())
          : store == null
              ? Center(child: Text(state.error ?? t('ERROR_GENERIC')))
              : UnfocusOnTap(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: <Widget>[
                      Text(
                        t('STORE_FORM.EDIT_STORE_SUBTITLE'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _kLabel,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            state.error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      _StoreSummaryCard(
                        storeName: _name.text.trim().isEmpty
                            ? store.name
                            : _name.text.trim(),
                        city: _city.text.trim().isEmpty
                            ? store.city
                            : _city.text.trim(),
                        stateName: _state.text.trim().isEmpty
                            ? store.state
                            : _state.text.trim(),
                        isActive: _isActive,
                        onViewStore: () =>
                            staffBack(context, fallback: Routes.staffStore),
                      ),
                      const SizedBox(height: 14),
                      _AccordionSection(
                        icon: Icons.storefront_outlined,
                        title: t('STORE_FORM.SECTION_STATUS'),
                        subtitle: t('STORE_FORM.SECTION_STATUS_DESC'),
                        expanded: _expanded == _EditSectionId.status,
                        onTap: () => _onSectionTap(_EditSectionId.status),
                        children: <Widget>[
                          _SettingToggle(
                            icon: Icons.shopping_bag_outlined,
                            title: t('STORE_FORM.ACCEPT_ORDERS'),
                            badge: _isOpen
                                ? t('TODAY.OPEN')
                                : t('TODAY.CLOSED'),
                            value: _isOpen,
                            onChanged: busy
                                ? null
                                : (bool v) => setState(() => _isOpen = v),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _SettingToggle(
                            icon: Icons.visibility_outlined,
                            title: t('STORE_FORM.SHOW_ON_APP'),
                            subtitle: t('STORE_FORM.SHOW_ON_APP_HINT'),
                            value: _isActive,
                            onChanged: busy
                                ? null
                                : (bool v) => setState(() => _isActive = v),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _SettingToggle(
                            icon: Icons.inventory_2_outlined,
                            title: t('STORE_FORM.TRACK_STOCK'),
                            subtitle: t('STORE_FORM.TRACK_STOCK_SHORT_HINT'),
                            value: _trackStock,
                            onChanged: busy
                                ? null
                                : (bool v) =>
                                    setState(() => _trackStock = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AccordionSection(
                        icon: Icons.badge_outlined,
                        title: t('STORE_FORM.SECTION_PROFILE'),
                        subtitle: t('STORE_FORM.SECTION_PROFILE_SHORT_DESC'),
                        expanded: _expanded == _EditSectionId.profile,
                        onTap: () => _onSectionTap(_EditSectionId.profile),
                        badge: _SummaryBadge(
                          icon: Icons.store_outlined,
                          label: _name.text.trim().isEmpty
                              ? '—'
                              : _name.text.trim(),
                        ),
                        children: <Widget>[
                          _field(
                            _name,
                            t('STAFF.PHARMACY_NAME'),
                            icon: Icons.storefront_outlined,
                            hint: t('STAFF.PHARMACY_NAME'),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _TwoCol(
                            left: _field(
                              _phone,
                              t('STAFF.PHONE'),
                              icon: Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                            ),
                            right: _field(
                              _whatsapp,
                              t('STAFF.WHATSAPP'),
                              icon: Icons.chat_outlined,
                              keyboard: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _field(
                            _email,
                            'Email',
                            icon: Icons.mail_outline,
                            keyboard: TextInputType.emailAddress,
                            hint: 'shop@email.com',
                          ),
                          const SizedBox(height: _kFieldGap),
                          _field(
                            _description,
                            'Description',
                            icon: Icons.notes_outlined,
                            maxLines: 3,
                            hint: t('STORE_FORM.SECTION_PROFILE_SHORT_DESC'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AccordionSection(
                        icon: Icons.local_shipping_outlined,
                        title: t('STORE_FORM.SECTION_ORDERS_DELIVERY'),
                        subtitle:
                            t('STORE_FORM.SECTION_ORDERS_DELIVERY_DESC'),
                        expanded: _expanded == _EditSectionId.orders,
                        onTap: () => _onSectionTap(_EditSectionId.orders),
                        badge: _SummaryBadge(
                          icon: Icons.local_shipping_outlined,
                          label: (_modulePickup || _moduleDelivery)
                              ? t('STORE_FORM.BADGE_ENABLED')
                              : t('STORE_FORM.BADGE_DISABLED'),
                        ),
                        children: <Widget>[
                          _SettingToggle(
                            icon: Icons.store_mall_directory_outlined,
                            title: t('STORE_FORM.MODULE_PICKUP'),
                            value: _modulePickup,
                            onChanged: busy
                                ? null
                                : (bool v) =>
                                    setState(() => _modulePickup = v),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _SettingToggle(
                            icon: Icons.delivery_dining_outlined,
                            title: t('STORE_FORM.MODULE_DELIVERY'),
                            subtitle: _modulePickup || _moduleDelivery
                                ? t('STORE_FORM.ENABLE_ONLINE_ORDERS')
                                : t('STORE_FORM.ONLINE_ORDERS_DISABLED'),
                            value: _moduleDelivery,
                            onChanged: busy
                                ? null
                                : (bool v) =>
                                    setState(() => _moduleDelivery = v),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _SettingToggle(
                            icon: Icons.description_outlined,
                            title: t('STORE_FORM.PRESCRIPTION'),
                            value: _allowPrescription,
                            onChanged: busy
                                ? null
                                : (bool v) => setState(
                                      () => _allowPrescription = v,
                                    ),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _TwoCol(
                            left: _field(
                              _minOrder,
                              t('STORE_FORM.MIN_ORDER'),
                              icon: Icons.currency_rupee,
                              keyboard:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              hint: '0',
                            ),
                            right: _field(
                              _deliveryFee,
                              t('STORE_FORM.STANDARD_DELIVERY_FEE'),
                              icon: Icons.local_shipping_outlined,
                              keyboard:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              hint: '0',
                            ),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _field(
                            _freeAbove,
                            t('STORE_FORM.FREE_DELIVERY_ABOVE'),
                            icon: Icons.card_giftcard_outlined,
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            hint: '0',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AccordionSection(
                        icon: Icons.my_location_outlined,
                        title: t('STORE_FORM.SECTION_LOCATION'),
                        subtitle: t('STORE_FORM.SECTION_LOCATION_DESC'),
                        expanded: _expanded == _EditSectionId.location,
                        onTap: () => _onSectionTap(_EditSectionId.location),
                        badge: _SummaryBadge(
                          icon: Icons.radar_outlined,
                          label: _radiusBadge(),
                        ),
                        children: <Widget>[
                          _field(
                            _address,
                            t('STORE_FORM.ADDRESS'),
                            icon: Icons.home_outlined,
                          ),
                          const SizedBox(height: _kFieldGap),
                          _TwoCol(
                            left: _field(
                              _city,
                              'City',
                              icon: Icons.location_city_outlined,
                            ),
                            right: _field(
                              _state,
                              'State',
                              icon: Icons.map_outlined,
                            ),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _field(
                            _pincode,
                            'Pincode',
                            icon: Icons.pin_drop_outlined,
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: _kFieldGap),
                          _TwoCol(
                            left: _field(
                              _lat,
                              'Latitude',
                              icon: Icons.explore_outlined,
                              keyboard:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                            ),
                            right: _field(
                              _lng,
                              'Longitude',
                              icon: Icons.explore_outlined,
                              keyboard:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _field(
                            _radius,
                            t('STORE_FORM.SERVICE_RADIUS'),
                            icon: Icons.radar_outlined,
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            hint: '5',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AccordionSection(
                        icon: Icons.verified_outlined,
                        title: t('STORE_FORM.SECTION_LICENSES'),
                        subtitle: t('STORE_FORM.SECTION_LICENSES_DESC'),
                        expanded: _expanded == _EditSectionId.licenses,
                        onTap: () => _onSectionTap(_EditSectionId.licenses),
                        badge: _SummaryBadge(
                          icon: Icons.check_circle_outline,
                          label: _licensesBadge(),
                        ),
                        children: <Widget>[
                          _field(
                            _gst,
                            t('STORE_FORM.GST_UDYAM_NUMBER'),
                            icon: Icons.receipt_long_outlined,
                          ),
                          const SizedBox(height: _kFieldGap),
                          _field(
                            _drugLicense,
                            t('STORE_FORM.DRUG_LICENSE_NUMBER'),
                            icon: Icons.workspace_premium_outlined,
                          ),
                          const SizedBox(height: _kFieldGap),
                          _TwoCol(
                            left: _field(
                              _pharmacist,
                              'Pharmacist name',
                              icon: Icons.person_outline,
                            ),
                            right: _field(
                              _pharmacistReg,
                              'Registration no.',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AccordionSection(
                        icon: Icons.schedule_outlined,
                        title: t('STORE_FORM.SUB_STORE_TIMINGS'),
                        subtitle: t('STORE_FORM.SHOP_HOURS_DESC'),
                        expanded: _expanded == _EditSectionId.timings,
                        onTap: () => _onSectionTap(_EditSectionId.timings),
                        badge: _SummaryBadge(
                          icon: Icons.access_time,
                          label: _timingsBadge(),
                        ),
                        children: <Widget>[
                          _InfoHint(text: t('STORE_FORM.SHOP_HOURS_DESC')),
                          const SizedBox(height: _kFieldGap),
                          _TwoCol(
                            left: _field(
                              _opens,
                              t('STORE_FORM.SHOP_OPENS'),
                              icon: Icons.wb_sunny_outlined,
                              hint: '09:00',
                            ),
                            right: _field(
                              _closes,
                              t('STORE_FORM.SHOP_CLOSES'),
                              icon: Icons.nights_stay_outlined,
                              hint: '21:00',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AccordionSection(
                        icon: Icons.layers_outlined,
                        title: t('STORE_FORM.SECTION_PRODUCT_OPTIONS'),
                        subtitle:
                            t('STORE_FORM.SECTION_PRODUCT_OPTIONS_DESC'),
                        expanded: _expanded == _EditSectionId.product,
                        onTap: () => _onSectionTap(_EditSectionId.product),
                        badge: _SummaryBadge(
                          icon: Icons.layers_outlined,
                          label: _salePolicyLabel(),
                        ),
                        children: <Widget>[
                          _InfoHint(text: t('STORE_FORM.SALE_POLICY_DESC')),
                          const SizedBox(height: _kFieldGap),
                          _LabeledField(
                            label: t('STORE_FORM.SALE_POLICY'),
                            child: StaffSheetSelectField(
                              value: _salePolicy,
                              enabled: !busy,
                              options: <StaffSelectOption>[
                                StaffSelectOption(
                                  value: 'loose_allowed',
                                  label: t('STORE_FORM.SALE_POLICY_LOOSE'),
                                ),
                                StaffSelectOption(
                                  value: 'pack_only',
                                  label: t('STORE_FORM.SALE_POLICY_PACK'),
                                ),
                                StaffSelectOption(
                                  value: 'whole_only',
                                  label: t('STORE_FORM.SALE_POLICY_WHOLE'),
                                ),
                              ],
                              decoration: _deco(
                                hint: t('STORE_FORM.SALE_POLICY'),
                                prefixIcon: const Icon(
                                  Icons.shopping_bag_outlined,
                                ),
                              ),
                              title: t('STORE_FORM.SALE_POLICY'),
                              subtitle: t('STORE_FORM.SALE_POLICY_DESC'),
                              headerIcon: Icons.shopping_bag_outlined,
                              onChanged: (String value) =>
                                  setState(() => _salePolicy = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AccordionSection(
                        icon: Icons.payments_outlined,
                        title: t('STORE_FORM.SECTION_PAYMENTS'),
                        subtitle: t('STORE_FORM.SECTION_PAYMENTS_DESC'),
                        expanded: _expanded == _EditSectionId.payments,
                        onTap: () => _onSectionTap(_EditSectionId.payments),
                        badge: _SummaryBadge(
                          icon: Icons.account_balance_wallet_outlined,
                          label: _paymentsBadge(),
                        ),
                        children: <Widget>[
                          _SettingToggle(
                            icon: Icons.payments_outlined,
                            title: t('STORE_FORM.COD'),
                            value: _allowCod,
                            onChanged: busy
                                ? null
                                : (bool v) => setState(() => _allowCod = v),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _SettingToggle(
                            icon: Icons.qr_code_2_outlined,
                            title: t('STORE_FORM.MANUAL_UPI'),
                            value: _allowManualUpi,
                            onChanged: busy
                                ? null
                                : (bool v) =>
                                    setState(() => _allowManualUpi = v),
                          ),
                          const SizedBox(height: _kFieldGap),
                          _field(
                            _upiId,
                            t('STORE_FORM.UPI_ID_LABEL'),
                            icon: Icons.account_balance_outlined,
                            hint: 'shop@paytm',
                          ),
                          const SizedBox(height: _kFieldGap),
                          _field(
                            _upiQrUrl,
                            t('STORE_FORM.UPI_QR_LABEL'),
                            icon: Icons.qr_code_outlined,
                            hint: 'https://...',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AccordionSection(
                        icon: Icons.image_outlined,
                        title: t('STORE_FORM.SUB_STORE_BRANDING'),
                        subtitle: t('STORE_FORM.SECTION_BRANDING_DESC'),
                        expanded: _expanded == _EditSectionId.branding,
                        onTap: () => _onSectionTap(_EditSectionId.branding),
                        badge: _BrandingBadge(
                          logoUrl: _logoUrl.text.trim(),
                          bannerUrl: _bannerUrl.text.trim(),
                        ),
                        children: <Widget>[
                          _field(
                            _logoUrl,
                            'Logo URL',
                            icon: Icons.add_photo_alternate_outlined,
                            hint: 'https://...',
                          ),
                          const SizedBox(height: _kFieldGap),
                          _field(
                            _bannerUrl,
                            'Banner URL',
                            icon: Icons.image_outlined,
                            hint: 'https://...',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: store == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: AppTheme.touchTarget,
                  child: FilledButton.icon(
                    onPressed: busy ? null : _save,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 20),
                    label: Text(
                      busy
                          ? t('WRITE_LOADING_SAVE')
                          : t('STORE_FORM.SAVE_PRODUCT'),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String _radiusBadge() {
    final raw = _radius.text.trim();
    if (raw.isEmpty) return '—';
    return '$raw km';
  }

  String _licensesBadge() {
    final hasLicense = _drugLicense.text.trim().isNotEmpty ||
        _gst.text.trim().isNotEmpty;
    return hasLicense
        ? t('STORE_FORM.BADGE_VERIFIED')
        : t('STORE_FORM.BADGE_INCOMPLETE');
  }

  String _timingsBadge() {
    final opens = _opens.text.trim();
    final closes = _closes.text.trim();
    if (opens.isEmpty && closes.isEmpty) return '—';
    if (opens.isEmpty) return closes;
    if (closes.isEmpty) return opens;
    return '$opens - $closes';
  }

  String _salePolicyLabel() {
    switch (_salePolicy) {
      case 'pack_only':
        return t('STORE_FORM.SALE_POLICY_PACK');
      case 'whole_only':
        return t('STORE_FORM.SALE_POLICY_WHOLE');
      default:
        return t('STORE_FORM.SALE_POLICY_LOOSE');
    }
  }

  String _paymentsBadge() {
    final parts = <String>[];
    if (_allowManualUpi || _upiId.text.trim().isNotEmpty) {
      parts.add('UPI');
    }
    if (_allowCod) parts.add('COD');
    if (parts.isEmpty) return t('STORE_FORM.BADGE_DISABLED');
    return parts.join(' + ');
  }

  InputDecoration _deco({
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: _kDensePad,
      hintStyle: TextStyle(
        fontSize: 13,
        color: AppTheme.ink.withValues(alpha: 0.38),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return _LabeledField(
      label: label,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        onChanged: (_) => setState(() {}),
        inputFormatters: keyboard == TextInputType.number ||
                keyboard?.toString().contains('number') == true
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
              ]
            : null,
        decoration: _deco(
          hint: hint ?? label,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
      ),
    );
  }
}

class _StoreSummaryCard extends StatelessWidget {
  const _StoreSummaryCard({
    required this.storeName,
    required this.city,
    required this.stateName,
    required this.isActive,
    required this.onViewStore,
  });

  final String storeName;
  final String? city;
  final String? stateName;
  final bool isActive;
  final VoidCallback onViewStore;

  @override
  Widget build(BuildContext context) {
    final location = <String>[
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((stateName ?? '').trim().isNotEmpty) stateName!.trim(),
    ].join(', ');

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: Brand.themeColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          storeName,
                          style: const TextStyle(
                            color: _kValue,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Pill(
                        label: isActive
                            ? t('STORE_FORM.SUPPLIER_STATUS_ACTIVE')
                            : t('STORE_FORM.SUPPLIER_STATUS_INACTIVE'),
                        emphasis: isActive,
                      ),
                    ],
                  ),
                  if (location.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: _kLabel,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: _kLabel,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: onViewStore,
              style: TextButton.styleFrom(
                foregroundColor: Brand.themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    t('STORE_FORM.VIEW_STORE'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onTap,
    required this.children,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onTap;
  final List<Widget> children;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: Brand.themeColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            color: _kValue,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _kLabel,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!expanded && badge != null) ...<Widget>[
                    const SizedBox(width: 8),
                    badge!,
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: _kLabel,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.ink.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TwoCol extends StatelessWidget {
  const _TwoCol({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

class _InfoHint extends StatelessWidget {
  const _InfoHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kMintSoft,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: _kMintBorder, width: AppTheme.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  const _SettingToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: _kMintSoft,
      borderRadius: AppTheme.borderRadius,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        dense: true,
        secondary: Icon(icon, color: Brand.themeColor),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Brand.themeColor,
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kValue,
                ),
              ),
            ),
            if (badge != null) ...<Widget>[
              const SizedBox(width: 8),
              _Pill(label: badge!, emphasis: true),
            ],
          ],
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _kMint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: Brand.themeColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Brand.themeColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandingBadge extends StatelessWidget {
  const _BrandingBadge({required this.logoUrl, required this.bannerUrl});

  final String logoUrl;
  final String bannerUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Thumb(label: 'Logo', url: logoUrl, fallback: Icons.add_photo_alternate_outlined),
        const SizedBox(width: 6),
        _Thumb(label: 'Banner', url: bannerUrl, fallback: Icons.image_outlined),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.label,
    required this.url,
    required this.fallback,
  });

  final String label;
  final String url;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 36,
            height: 28,
            child: url.isEmpty
                ? ColoredBox(
                    color: _kMint,
                    child: Icon(fallback, size: 14, color: Brand.themeColor),
                  )
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (BuildContext _, String __, Object ___) {
                      return ColoredBox(
                        color: _kMint,
                        child: Icon(
                          fallback,
                          size: 14,
                          color: Brand.themeColor,
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: _kLabel,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.emphasis});

  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: emphasis ? _kMint : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: emphasis
            ? null
            : Border.all(
                color: AppTheme.hairlineColor,
                width: AppTheme.hairline,
              ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasis ? Brand.themeColor : _kLabel,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_store.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'store_settings_controller.dart';

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
  String _salePolicy = 'loose_allowed';
  String? _boundStoreId;

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

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(storeSettingsProvider);
    final theme = Theme.of(context);
    final store = state.store;

    if (store != null && _boundStoreId != store.id) {
      _bind(store);
    }

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context, fallback: Routes.staffStore),
        ),
        title: t('MORE.EDIT_STORE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            enabled: !state.busy,
            onPressed: () =>
                ref.read(storeSettingsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.loading && store == null
          ? const Center(child: CircularProgressIndicator())
          : store == null
              ? Center(child: Text(state.error ?? t('ERROR_GENERIC')))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: <Widget>[
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          state.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    _section(
                      theme,
                      t('STORE_FORM.SECTION_PROFILE'),
                      t('STORE_FORM.SECTION_PROFILE_DESC'),
                    ),
                    _field(_name, t('STORE_FORM.SUB_STORE_DETAILS')),
                    _field(_phone, t('STORE_FORM.SUB_CONTACT_DETAILS')),
                    _field(_whatsapp, 'WhatsApp'),
                    _field(_email, 'Email'),
                    _field(_description, 'Description', maxLines: 3),
                    _field(_address, 'Address'),
                    _field(_city, 'City'),
                    _field(_state, 'State'),
                    _field(_pincode, 'Pincode'),
                    _field(_gst, t('STORE_FORM.GST_UDYAM_NUMBER')),
                    _field(_drugLicense, 'Drug license'),
                    _field(_pharmacist, 'Pharmacist name'),
                    _field(_pharmacistReg, 'Pharmacist registration'),
                    const SizedBox(height: 8),
                    Text(
                      t('STORE_FORM.SUB_STORE_TIMINGS'),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      t('STORE_FORM.SHOP_HOURS_DESC'),
                      style: theme.textTheme.bodySmall,
                    ),
                    _field(_opens, t('STORE_FORM.SHOP_OPENS')),
                    _field(_closes, t('STORE_FORM.SHOP_CLOSES')),
                    const SizedBox(height: 8),
                    Text(
                      t('STORE_FORM.SUB_STORE_BRANDING'),
                      style: theme.textTheme.titleSmall,
                    ),
                    _field(_logoUrl, 'Logo URL'),
                    _field(_bannerUrl, 'Banner URL'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('STORE_FORM.STORE_OPEN')),
                      value: _isOpen,
                      onChanged: state.busy
                          ? null
                          : (bool value) => setState(() => _isOpen = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('STORE_FORM.STORE_VISIBLE')),
                      value: _isActive,
                      onChanged: state.busy
                          ? null
                          : (bool value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      theme,
                      t('STORE_FORM.SECTION_ONLINE_ORDERS'),
                      t('STORE_FORM.SECTION_ONLINE_ORDERS_DESC'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('STORE_FORM.MODULE_PICKUP')),
                      value: _modulePickup,
                      onChanged: state.busy
                          ? null
                          : (bool value) =>
                              setState(() => _modulePickup = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('STORE_FORM.MODULE_DELIVERY')),
                      subtitle: Text(
                        store.acceptsOnlineOrders ||
                                _modulePickup ||
                                _moduleDelivery
                            ? t('STORE_FORM.ENABLE_ONLINE_ORDERS')
                            : t('STORE_FORM.ONLINE_ORDERS_DISABLED'),
                      ),
                      value: _moduleDelivery,
                      onChanged: state.busy
                          ? null
                          : (bool value) =>
                              setState(() => _moduleDelivery = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('STORE_FORM.PRESCRIPTION')),
                      value: _allowPrescription,
                      onChanged: state.busy
                          ? null
                          : (bool value) =>
                              setState(() => _allowPrescription = value),
                    ),
                    Text(
                      t('STORE_FORM.SUB_LOCATION'),
                      style: theme.textTheme.titleSmall,
                    ),
                    _field(
                      _lat,
                      'Latitude',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                    _field(
                      _lng,
                      'Longitude',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                    _field(
                      _radius,
                      t('STORE_FORM.SERVICE_RADIUS'),
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _field(
                      _minOrder,
                      t('STORE_FORM.MIN_ORDER'),
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _field(
                      _deliveryFee,
                      t('STORE_FORM.STANDARD_DELIVERY_FEE'),
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _field(
                      _freeAbove,
                      t('STORE_FORM.FREE_DELIVERY_ABOVE'),
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('STORE_FORM.SALE_POLICY'),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      t('STORE_FORM.SALE_POLICY_DESC'),
                      style: theme.textTheme.bodySmall,
                    ),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _salePolicy,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'loose_allowed',
                          child: Text('Loose + pack'),
                        ),
                        DropdownMenuItem(
                          value: 'pack_only',
                          child: Text('Pack only'),
                        ),
                        DropdownMenuItem(
                          value: 'whole_only',
                          child: Text('Whole container'),
                        ),
                      ],
                      onChanged: state.busy
                          ? null
                          : (String? value) {
                              if (value == null) return;
                              setState(() => _salePolicy = value);
                            },
                    ),
                    const SizedBox(height: 16),
                    _section(
                      theme,
                      t('STORE_FORM.SECTION_PAYMENTS'),
                      t('STORE_FORM.SECTION_PAYMENTS_DESC'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('STORE_FORM.COD')),
                      value: _allowCod,
                      onChanged: state.busy
                          ? null
                          : (bool value) => setState(() => _allowCod = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('STORE_FORM.MANUAL_UPI')),
                      value: _allowManualUpi,
                      onChanged: state.busy
                          ? null
                          : (bool value) =>
                              setState(() => _allowManualUpi = value),
                    ),
                    _field(_upiId, t('STORE_FORM.UPI_ID_LABEL')),
                    _field(_upiQrUrl, t('STORE_FORM.UPI_QR_LABEL')),
                    const SizedBox(height: 16),
                    if (store.acceptsOnlineOrders)
                      Text(
                        '${t('STORE_FORM.ENABLE_ONLINE_ORDERS')}: yes',
                        style: theme.textTheme.labelLarge,
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: state.busy ? null : _save,
                      child: state.busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t('WRITE_LOADING_SAVE')),
                    ),
                  ],
                ),
    );
  }

  Widget _section(ThemeData theme, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          Text(desc, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: keyboard == TextInputType.number ||
                keyboard?.toString().contains('number') == true
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
              ]
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

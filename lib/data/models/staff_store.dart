import 'listing.dart';

class StaffStore {
  const StaffStore({
    required this.id,
    required this.name,
    required this.slug,
    this.phone,
    this.email,
    this.description,
    this.gstNumber,
    this.drugLicenseNumber,
    this.pharmacistName,
    this.pharmacistRegistrationNo,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.logoUrl,
    this.bannerUrl,
    this.whatsappNumber,
    this.openingTime,
    this.closingTime,
    this.serviceRadiusKm = 5,
    this.minimumOrderAmount = 0,
    this.deliveryCharge = 0,
    this.freeDeliveryAbove,
    this.allowCod = false,
    this.allowManualUpi = false,
    this.allowPrescriptionUpload = false,
    this.modulePos = true,
    this.modulePickup = false,
    this.moduleDelivery = false,
    this.upiId,
    this.upiQrUrl,
    this.isOpen = true,
    this.isActive = true,
    this.acceptsOnlineOrders = false,
    this.salePolicy = 'loose_allowed',
    this.onboardingCompleted = false,
  });

  final String id;
  final String name;
  final String slug;
  final String? phone;
  final String? email;
  final String? description;
  final String? gstNumber;
  final String? drugLicenseNumber;
  final String? pharmacistName;
  final String? pharmacistRegistrationNo;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;
  final String? bannerUrl;
  final String? whatsappNumber;
  final String? openingTime;
  final String? closingTime;
  final double serviceRadiusKm;
  final double minimumOrderAmount;
  final double deliveryCharge;
  final double? freeDeliveryAbove;
  final bool allowCod;
  final bool allowManualUpi;
  final bool allowPrescriptionUpload;
  final bool modulePos;
  final bool modulePickup;
  final bool moduleDelivery;
  final String? upiId;
  final String? upiQrUrl;
  final bool isOpen;
  final bool isActive;
  final bool acceptsOnlineOrders;
  final String salePolicy;
  final bool onboardingCompleted;

  factory StaffStore.fromJson(Map<String, Object?> row) {
    return StaffStore(
      id: asString(row['id']),
      name: asString(row['name']),
      slug: asString(row['slug']),
      phone: asNullableString(row['phone']),
      email: asNullableString(row['email']),
      description: asNullableString(row['description']),
      gstNumber: asNullableString(row['gst_number']),
      drugLicenseNumber: asNullableString(row['drug_license_number']),
      pharmacistName: asNullableString(row['pharmacist_name']),
      pharmacistRegistrationNo:
          asNullableString(row['pharmacist_registration_no']),
      address: asNullableString(row['address']),
      city: asNullableString(row['city']),
      state: asNullableString(row['state']),
      pincode: asNullableString(row['pincode']),
      latitude: asNullableNumber(row['latitude']),
      longitude: asNullableNumber(row['longitude']),
      logoUrl: asNullableString(row['logo_url']),
      bannerUrl: asNullableString(row['banner_url']),
      whatsappNumber: asNullableString(row['whatsapp_number']),
      openingTime: asNullableString(row['opening_time']),
      closingTime: asNullableString(row['closing_time']),
      serviceRadiusKm: asNumber(row['service_radius_km'], 5),
      minimumOrderAmount: asNumber(row['minimum_order_amount']),
      deliveryCharge: asNumber(row['delivery_charge']),
      freeDeliveryAbove: asNullableNumber(row['free_delivery_above']),
      allowCod: asBoolean(row['allow_cod']),
      allowManualUpi: asBoolean(row['allow_manual_upi']),
      allowPrescriptionUpload: asBoolean(row['allow_prescription_upload']),
      modulePos: asBoolean(row['module_pos'], true),
      modulePickup: asBoolean(row['module_pickup']),
      moduleDelivery: asBoolean(row['module_delivery']),
      upiId: asNullableString(row['upi_id']),
      upiQrUrl: asNullableString(row['upi_qr_url']),
      isOpen: asBoolean(row['is_open'], true),
      isActive: asBoolean(row['is_active'], true),
      acceptsOnlineOrders: asBoolean(row['accepts_online_orders']),
      salePolicy: asString(row['sale_policy'], 'loose_allowed'),
      onboardingCompleted: asBoolean(row['onboarding_completed']),
    );
  }

  factory StaffStore.fromApi(Map<Object?, Object?> map) {
    final nested = map['store'];
    final source = nested is Map
        ? nested.map((Object? k, Object? v) => MapEntry('$k', v))
        : map.map((Object? k, Object? v) => MapEntry('$k', v));
    return StaffStore.fromJson(source);
  }
}

class UpdateStoreInput {
  const UpdateStoreInput({
    this.name,
    this.phone,
    this.email,
    this.description,
    this.gstNumber,
    this.drugLicenseNumber,
    this.pharmacistName,
    this.pharmacistRegistrationNo,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.logoUrl,
    this.bannerUrl,
    this.whatsappNumber,
    this.openingTime,
    this.closingTime,
    this.serviceRadiusKm,
    this.minimumOrderAmount,
    this.deliveryCharge,
    this.freeDeliveryAbove,
    this.allowCod,
    this.allowManualUpi,
    this.allowPrescriptionUpload,
    this.modulePickup,
    this.moduleDelivery,
    this.upiId,
    this.upiQrUrl,
    this.isOpen,
    this.isActive,
    this.salePolicy,
  });

  final String? name;
  final String? phone;
  final String? email;
  final String? description;
  final String? gstNumber;
  final String? drugLicenseNumber;
  final String? pharmacistName;
  final String? pharmacistRegistrationNo;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;
  final String? bannerUrl;
  final String? whatsappNumber;
  final String? openingTime;
  final String? closingTime;
  final double? serviceRadiusKm;
  final double? minimumOrderAmount;
  final double? deliveryCharge;
  final double? freeDeliveryAbove;
  final bool? allowCod;
  final bool? allowManualUpi;
  final bool? allowPrescriptionUpload;
  final bool? modulePickup;
  final bool? moduleDelivery;
  final String? upiId;
  final String? upiQrUrl;
  final bool? isOpen;
  final bool? isActive;
  final String? salePolicy;

  Map<String, Object?> toJson() {
    final out = <String, Object?>{};
    void put(String key, Object? value) {
      if (value != null) out[key] = value;
    }

    put('name', name);
    put('phone', phone);
    put('email', email);
    put('description', description);
    put('gst_number', gstNumber);
    put('drug_license_number', drugLicenseNumber);
    put('pharmacist_name', pharmacistName);
    put('pharmacist_registration_no', pharmacistRegistrationNo);
    put('address', address);
    put('city', city);
    put('state', state);
    put('pincode', pincode);
    put('latitude', latitude);
    put('longitude', longitude);
    put('logo_url', logoUrl);
    put('banner_url', bannerUrl);
    put('whatsapp_number', whatsappNumber);
    put('opening_time', openingTime);
    put('closing_time', closingTime);
    put('service_radius_km', serviceRadiusKm);
    put('minimum_order_amount', minimumOrderAmount);
    put('delivery_charge', deliveryCharge);
    put('free_delivery_above', freeDeliveryAbove);
    put('allow_cod', allowCod);
    put('allow_manual_upi', allowManualUpi);
    put('allow_prescription_upload', allowPrescriptionUpload);
    put('module_pickup', modulePickup);
    put('module_delivery', moduleDelivery);
    put('upi_id', upiId);
    put('upi_qr_url', upiQrUrl);
    put('is_open', isOpen);
    put('is_active', isActive);
    put('sale_policy', salePolicy);
    return out;
  }
}

class UpdateProfileInput {
  const UpdateProfileInput({this.fullName, this.phone});

  final String? fullName;
  final String? phone;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
    };
  }
}

class StoreImageUploadResult {
  const StoreImageUploadResult({required this.url, this.kind});

  final String url;
  final String? kind;

  factory StoreImageUploadResult.fromJson(Map<Object?, Object?> map) {
    return StoreImageUploadResult(
      url: '${map['url'] ?? map['public_url'] ?? ''}',
      kind: map['kind']?.toString(),
    );
  }
}

class StaffCategory {
  const StaffCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.isSystem,
    required this.isActive,
    this.iconUrl,
    this.sortOrder = 0,
    this.attached = false,
  });

  final String id;
  final String name;
  final String slug;
  final bool isSystem;
  final bool isActive;
  final String? iconUrl;
  final double sortOrder;
  final bool attached;

  StaffCategory copyWith({bool? attached, bool? isActive, String? name}) {
    return StaffCategory(
      id: id,
      name: name ?? this.name,
      slug: slug,
      isSystem: isSystem,
      isActive: isActive ?? this.isActive,
      iconUrl: iconUrl,
      sortOrder: sortOrder,
      attached: attached ?? this.attached,
    );
  }

  factory StaffCategory.fromCategory(Category category, {bool attached = false}) {
    return StaffCategory(
      id: category.id,
      name: category.name,
      slug: category.slug,
      isSystem: category.isSystem,
      isActive: category.isActive,
      iconUrl: category.iconUrl,
      sortOrder: category.sortOrder,
      attached: attached,
    );
  }

  factory StaffCategory.fromJson(Map<String, Object?> row) {
    return StaffCategory(
      id: asString(row['id']),
      name: asString(row['name']),
      slug: asString(row['slug']),
      isSystem: asBoolean(row['is_system']),
      isActive: asBoolean(row['is_active'], true),
      iconUrl: asNullableString(row['icon_url']),
      sortOrder: asNumber(row['sort_order']),
      attached: asBoolean(row['attached']),
    );
  }

  factory StaffCategory.fromApi(Map<Object?, Object?> map) {
    final nested = map['category'];
    final source = nested is Map
        ? nested.map((Object? k, Object? v) => MapEntry('$k', v))
        : map.map((Object? k, Object? v) => MapEntry('$k', v));
    return StaffCategory.fromJson(source);
  }
}

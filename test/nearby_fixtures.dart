import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/data/rpc/listing_rpc.dart';

NearbyStore nearbyShop({
  required String id,
  required String slug,
  required String name,
  double km = 1,
  bool accepts = true,
  String? phone,
  String? address,
  String? city,
  String? whatsappNumber,
  String? openingTime,
  String? closingTime,
}) {
  return NearbyStore(
    store: PublicStore(
      id: id,
      name: name,
      slug: slug,
      phone: phone,
      description: null,
      address: address,
      city: city,
      state: null,
      pincode: null,
      latitude: 28.6,
      longitude: 77.2,
      logoUrl: null,
      bannerUrl: null,
      whatsappNumber: whatsappNumber,
      openingTime: openingTime,
      closingTime: closingTime,
      serviceRadiusKm: 5,
      minimumOrderAmount: 0,
      deliveryCharge: 0,
      freeDeliveryAbove: null,
      allowCod: true,
      allowManualUpi: true,
      allowPrescriptionUpload: true,
      modulePickup: false,
      moduleDelivery: true,
      upiId: null,
      upiQrUrl: null,
      isOpen: true,
      acceptsOnlineOrders: accepts,
      salePolicy: 'loose_allowed',
    ),
    distanceKm: km,
  );
}

class FakeNearbySource implements NearbyStoreSource {
  FakeNearbySource([this.stores = const <NearbyStore>[]]);

  List<NearbyStore> stores;

  @override
  Future<List<NearbyStore>> listNearbyStores({
    required double lat,
    required double lng,
    int limit = 20,
  }) async {
    return stores;
  }
}

import 'package:flutter_test/flutter_test.dart';

import 'package:medi_app/data/models/listing.dart';

void main() {
  test('parseListingCard maps web JSON', () {
    final card = parseListingCard(<String, Object?>{
      'id': 'sp-1',
      'store_id': 'store-1',
      'product_id': 'p-1',
      'slug': 'dolo-650',
      'name': 'Dolo 650',
      'generic_name': 'Paracetamol',
      'image_url': 'https://example.com/dolo.jpg',
      'available_quantity': 12,
      'schedule': 'h',
      'selling_price': '34.5',
      'mrp': 40,
    });

    expect(card, isNotNull);
    expect(card!.id, 'sp-1');
    expect(card.name, 'Dolo 650');
    expect(card.thumb, 'https://example.com/dolo.jpg');
    expect(card.imageUrl, 'https://example.com/dolo.jpg');
    expect(card.packLabel, 'Unit');
    expect(card.availableQuantity, 12);
    expect(card.onHandQuantity, 12);
    expect(card.inStock, isTrue);
    expect(card.requiresPrescription, isTrue);
    expect(card.kind, 'tablet_capsule');
    expect(card.salePolicy, 'inherit');
    expect(card.storage, 'ambient');
    expect(card.sellingPrice, 34.5);
    expect(card.mrp, 40);
  });

  test('parseListingCard returns null without id', () {
    expect(parseListingCard(<String, Object?>{'name': 'Dolo'}), isNull);
    expect(parseListingCards('nope'), isEmpty);
  });

  test('parseStoreHome and nearby stores', () {
    final home = parseStoreHome(<String, Object?>{
      'status': 'ok',
      'store': <String, Object?>{
        'id': 'store-1',
        'name': 'Ram Medical',
        'slug': 'ram-medical',
      },
      'categories': <Object?>[
        <String, Object?>{'id': 'c1', 'name': 'Tablets', 'slug': 'tablets'},
      ],
      'featured': <Object?>[
        <String, Object?>{'id': 'sp-1', 'name': 'Dolo 650'},
      ],
      'products': <Object?>[],
    });

    expect(home.status, StoreShellStatus.ok);
    expect(home.store!.slug, 'ram-medical');
    expect(home.categories.single.slug, 'tablets');
    expect(home.featured.single.name, 'Dolo 650');
    expect(home.products, isEmpty);

    final nearby = parseNearbyStores(<Object?>[
      <String, Object?>{
        'id': 'store-1',
        'name': 'Ram Medical',
        'slug': 'ram-medical',
        'distance_km': 1.25,
      },
    ]);
    expect(nearby.single.store.slug, 'ram-medical');
    expect(nearby.single.distanceKm, 1.25);
  });
}

import '../../data/models/listing.dart';

String? clockLabel(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (value.length >= 5 && value[2] == ':') return value.substring(0, 5);
  return value;
}

String? storeHoursLabel(PublicStore? store) {
  final open = clockLabel(store?.openingTime);
  final close = clockLabel(store?.closingTime);
  if (open == null && close == null) return null;
  if (open != null && close != null) return '$open–$close';
  return open ?? close;
}

String storeAddressLabel(PublicStore store) {
  return <String?>[store.address, store.city, store.state, store.pincode]
      .whereType<String>()
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .join(', ');
}

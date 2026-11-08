import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/staff/pos/pos_product.dart';
import '../models/listing.dart';
import '../supabase_client.dart';

/// Staff POS listing RPCs (`get_pos_home` / `search_pos_catalog`).
class PosRpc {
  PosRpc(this._client);

  final SupabaseClient _client;

  Future<List<PosProduct>> getPosHome({int limit = 50}) async {
    final raw = await _client.rpc(
      'get_pos_home',
      params: <String, dynamic>{'p_limit': limit},
    );
    return _parseProducts(raw);
  }

  Future<List<PosProduct>> searchPosCatalog({
    required String query,
    int limit = 30,
  }) async {
    final raw = await _client.rpc(
      'search_pos_catalog',
      params: <String, dynamic>{
        'p_query': query,
        'p_limit': limit,
      },
    );
    return _parseProducts(raw);
  }

  List<PosProduct> _parseProducts(Object? raw) {
    Object? products = raw;
    if (raw is Map) {
      products = raw['products'];
    }
    return parseListingCards(products)
        .map(PosProduct.fromListingCard)
        .toList(growable: false);
  }
}

final posRpcProvider = Provider<PosRpc>((Ref ref) {
  return PosRpc(AppSupabase.client);
});

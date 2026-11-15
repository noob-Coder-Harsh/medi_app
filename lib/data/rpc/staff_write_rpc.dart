import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog_product.dart';
import '../models/inventory_batch.dart';
import '../models/listing.dart';
import '../models/pos_checkout.dart';
import '../models/staff_store.dart';
import '../supabase_client.dart';

/// Owner JWT write RPCs — see docs/WRITE_RPCS.md.
class StaffWriteRpc {
  StaffWriteRpc(this._client);

  final SupabaseClient _client;

  Future<CatalogWriteResult> createCustomProduct(
    CreateCustomProductInput input,
  ) async {
    final raw = await _rpc('create_custom_product', <String, dynamic>{
      'p': _jsonObject(input.toJson()),
    });
    return CatalogWriteResult.fromJson(_map(raw));
  }

  Future<CatalogWriteResult> addSystemProductToStore(String productId) async {
    final raw = await _rpc('add_system_product_to_store', <String, dynamic>{
      'p_product_id': productId,
    });
    return CatalogWriteResult.fromJson(_map(raw));
  }

  Future<void> updateStoreListing({
    required String storeProductId,
    required UpdateStoreProductInput input,
  }) async {
    await _rpc('update_store_listing', <String, dynamic>{
      'p_store_product_id': storeProductId,
      'p': _jsonObject(input.toJson()),
    });
  }

  Future<Map<String, Object?>> adjustStock({
    required String storeProductId,
    required AdjustStockInput input,
  }) async {
    final raw = await _rpc('adjust_stock', <String, dynamic>{
      'p_store_product_id': storeProductId,
      'p': _jsonObject(input.toJson()),
    });
    return asRecord(raw) ?? <String, Object?>{};
  }

  Future<StaffStore> updateStore(UpdateStoreInput input) async {
    final raw = await _rpc('update_store', <String, dynamic>{
      'p': _jsonObject(input.toJson()),
    });
    final row = asRecord(raw);
    if (row == null) {
      throw StateError('update_store returned empty');
    }
    return StaffStore.fromJson(row);
  }

  Future<PosCustomerCard> ensurePosCustomer(String phone) async {
    final raw = await _rpc('ensure_pos_customer', <String, dynamic>{
      'p_phone': phone,
    });
    return PosCustomerCard.fromJson(_map(raw));
  }

  Future<PosCheckoutResult> posCheckout(PosCheckoutInput input) async {
    final raw = await _rpc('pos_checkout', <String, dynamic>{
      'p': _jsonObject(input.toJson()),
    });
    return PosCheckoutResult.fromJson(_map(raw));
  }

  /// Product catalog image → `med-images/{storeId}/products/…` (public URL).
  ///
  /// Next `POST …/store/images` only accepts kind `logo|banner|upi_qr`, so
  /// product photos upload here under staff JWT + storage RLS.
  Future<String> uploadProductImage({
    required String storeId,
    required List<int> bytes,
    required String filename,
  }) async {
    final safeStore = storeId.trim();
    if (safeStore.isEmpty) {
      throw StaffWriteRpcException('STORE_REQUIRED');
    }
    final safeName = filename.trim().isEmpty ? 'product.webp' : filename.trim();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$safeStore/products/${stamp}_$safeName';
    final contentType = safeName.toLowerCase().endsWith('.png')
        ? 'image/png'
        : safeName.toLowerCase().endsWith('.webp')
            ? 'image/webp'
            : safeName.toLowerCase().endsWith('.gif')
                ? 'image/gif'
                : 'image/jpeg';
    try {
      await _client.storage.from('med-images').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
      return _client.storage.from('med-images').getPublicUrl(path);
    } on StorageException catch (error) {
      debugPrint(
        'StaffWriteRpc.uploadProductImage failed: '
        '${error.statusCode} ${error.message} ${error.error}',
      );
      throw StaffWriteRpcException(
        error.message.trim().isEmpty ? 'IMAGE_UPLOAD_FAILED' : error.message,
      );
    }
  }

  Future<dynamic> _rpc(String name, Map<String, dynamic> params) async {
    try {
      return await _client.rpc(name, params: params);
    } on PostgrestException catch (error) {
      final message = _rpcMessage(name, error);
      debugPrint(
        'StaffWriteRpc.$name failed: code=${error.code} '
        'message=${error.message} details=${error.details} hint=${error.hint}',
      );
      throw StaffWriteRpcException(message);
    } catch (error, stack) {
      debugPrint('StaffWriteRpc.$name failed: $error\n$stack');
      rethrow;
    }
  }

  /// Ensures nested maps/lists are plain JSON types PostgREST accepts for jsonb.
  static dynamic _jsonObject(Object? value) {
    return jsonDecode(jsonEncode(value));
  }

  static Map<Object?, Object?> _map(Object? raw) {
    if (raw is Map) return Map<Object?, Object?>.from(raw);
    throw StateError('Expected JSON object from write RPC');
  }

  static String _rpcMessage(String name, PostgrestException error) {
    final code = (error.code ?? '').trim();
    final message = error.message.trim();
    final details = error.details?.toString().trim() ?? '';
    final hint = error.hint?.toString().trim() ?? '';

    for (final known in const <String>[
      'STORE_REQUIRED',
      'VALIDATION_ERROR',
      'INSUFFICIENT_STOCK',
      'NOT_FOUND',
      'SYSTEM_PRODUCT_READONLY',
    ]) {
      if (message.contains(known) || details.contains(known)) return known;
    }

    if (code == 'PGRST202' ||
        message.toLowerCase().contains('could not find the function')) {
      return 'RPC_MISSING:$name — apply WRITE RPCs to Supabase (docs/WRITE_RPCS.md)';
    }

    if (message.toLowerCase().contains('track_stock') ||
        details.toLowerCase().contains('track_stock')) {
      return 'DB_MISSING_COLUMN:track_stock — run ALTER in docs/WRITE_RPCS.md';
    }

    final parts = <String>[
      if (code.isNotEmpty) code,
      if (message.isNotEmpty && message.toLowerCase() != 'bad request') message,
      if (details.isNotEmpty) details,
      if (hint.isNotEmpty) hint,
    ];
    if (parts.isEmpty) {
      return message.isNotEmpty ? message : 'WRITE_FAILED:$name';
    }
    return parts.join(' | ');
  }
}

class StaffWriteRpcException implements Exception {
  StaffWriteRpcException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AdjustStockInput {
  const AdjustStockInput({
    required this.direction,
    required this.quantity,
    required this.reason,
    this.batchNo,
    this.mrp,
    this.sellingPrice,
    this.purchasePrice,
    this.manufacturedAt,
    this.expiresAt,
    this.notes,
  });

  final String direction; // add | reduce
  final int quantity;
  final String reason;
  final String? batchNo;
  final double? mrp;
  final double? sellingPrice;
  final double? purchasePrice;
  final String? manufacturedAt;
  final String? expiresAt;
  final String? notes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'direction': direction,
      'quantity': quantity,
      'reason': reason,
      'batch_no': _emptyToNull(batchNo),
      'mrp': mrp,
      'selling_price': sellingPrice,
      'purchase_price': purchasePrice,
      'manufactured_at': _emptyToNull(manufacturedAt),
      'expires_at': _emptyToNull(expiresAt),
      'notes': _emptyToNull(notes),
    };
  }

  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

final staffWriteRpcProvider = Provider<StaffWriteRpc?>((Ref ref) {
  if (!AppSupabase.isReady) return null;
  return StaffWriteRpc(AppSupabase.client);
});

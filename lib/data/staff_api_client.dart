import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import 'api_client.dart';
import 'models/catalog_product.dart';
import 'models/inventory_batch.dart';
import 'models/pos_checkout.dart';
import 'models/purchase.dart';
import 'models/staff_books.dart';
import 'models/staff_order.dart';
import 'models/staff_return.dart';
import 'models/staff_store.dart';

/// Next `/api/app/staff/*` writes. Bearer = Supabase access token.
abstract class StaffWriteApi {
  Future<PosCustomerCard?> lookupCustomer({
    required String accessToken,
    required String phone,
  });

  Future<PosCustomerCard> ensureCustomer({
    required String accessToken,
    required String phone,
  });

  Future<PosCheckoutResult> checkout({
    required String accessToken,
    required PosCheckoutInput input,
  });

  Future<List<PosRecentSale>> recentSales({required String accessToken});

  Future<CatalogWriteResult> addCatalogProduct({
    required String accessToken,
    required String productId,
  });

  Future<CatalogWriteResult> createCustomCatalogProduct({
    required String accessToken,
    required CreateCustomProductInput input,
  });

  Future<void> updateStoreProduct({
    required String accessToken,
    required String storeProductId,
    required UpdateStoreProductInput input,
  });

  Future<InventoryBatch> addProductBatch({
    required String accessToken,
    required String storeProductId,
    required OpeningBatchInput input,
  });

  Future<InventoryBatch> updateProductBatch({
    required String accessToken,
    required String storeProductId,
    required String batchId,
    required Map<String, Object?> patch,
  });

  Future<SupplierOption> createSupplier({
    required String accessToken,
    required String name,
    String? phone,
    String? contactPerson,
    String? notes,
    double? openingBalance,
  });

  Future<StaffSupplier> updateSupplier({
    required String accessToken,
    required String supplierId,
    required SaveSupplierInput input,
  });

  Future<StaffSupplier> setSupplierActive({
    required String accessToken,
    required String supplierId,
    required bool isActive,
  });

  Future<PurchaseDetail> createPurchase({
    required String accessToken,
    required SavePurchaseInput input,
  });

  Future<StaffCustomer> ensureStoreCustomer({
    required String accessToken,
    required String phone,
  });

  Future<StaffCustomer> updateStoreCustomer({
    required String accessToken,
    required String storeCustomerId,
    String? notes,
    int? loyaltyPoints,
  });

  Future<StaffPayment> settleCustomerPayment({
    required String accessToken,
    required CustomerSettlementInput input,
  });

  Future<StaffPayment> settleSupplierPayment({
    required String accessToken,
    required SupplierSettlementInput input,
  });

  Future<StaffOrderDetail> updateOrderStatus({
    required String accessToken,
    required String orderId,
    required String toStatus,
    String? notes,
  });

  Future<StaffReturnDetail> createReturn({
    required String accessToken,
    required CreateReturnInput input,
  });

  Future<StaffReturnDetail> approveReturn({
    required String accessToken,
    required String returnId,
    String? notes,
  });

  Future<StaffReturnDetail> rejectReturn({
    required String accessToken,
    required String returnId,
    String? notes,
  });

  Future<StaffStore> updateStore({
    required String accessToken,
    required UpdateStoreInput input,
  });

  Future<StoreImageUploadResult> uploadStoreImage({
    required String accessToken,
    required String kind,
    required List<int> bytes,
    required String filename,
  });

  Future<void> updateProfile({
    required String accessToken,
    required UpdateProfileInput input,
  });

  Future<void> attachCategories({
    required String accessToken,
    required List<String> categoryIds,
  });

  Future<void> detachCategories({
    required String accessToken,
    required List<String> categoryIds,
  });

  Future<StaffCategory> createCategory({
    required String accessToken,
    required String name,
    String? slug,
  });

  Future<StaffCategory> updateCategory({
    required String accessToken,
    required String categoryId,
    String? name,
    bool? isActive,
  });
}

class DioStaffWriteApi implements StaffWriteApi {
  DioStaffWriteApi({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _normalizeBase(baseUrl ?? Env.apiBaseUrl),
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              headers: const <String, Object?>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

  final Dio _dio;

  static String _normalizeBase(String raw) {
    if (raw.isEmpty) return '';
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  void _requireBase() {
    if (_dio.options.baseUrl.isEmpty) {
      throw AppApiException('API_BASE_URL is not configured');
    }
  }

  Options _auth(String accessToken) {
    return Options(
      headers: <String, Object?>{'Authorization': 'Bearer $accessToken'},
    );
  }

  Map<Object?, Object?> _map(Response<dynamic> response) =>
      requireJsonMap(response);

  Never _throwDio(DioException error) {
    throw AppApiException(
      dioErrorMessage(error),
      statusCode: error.response?.statusCode,
    );
  }

  @override
  Future<PosCustomerCard?> lookupCustomer({
    required String accessToken,
    required String phone,
  }) async {
    _requireBase();
    try {
      final response = await _dio.get<dynamic>(
        '/api/app/staff/pos/customers',
        queryParameters: <String, Object?>{'phone': phone},
        options: _auth(accessToken),
      );
      final data = response.data;
      if (data == null) return null;
      if (data is Map && data.isEmpty) return null;
      if (data is Map && data['customer'] is Map) {
        return PosCustomerCard.fromJson(
          Map<Object?, Object?>.from(data['customer'] as Map),
        );
      }
      if (data is Map) {
        return PosCustomerCard.fromJson(Map<Object?, Object?>.from(data));
      }
      return null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      _throwDio(error);
    }
  }

  @override
  Future<PosCustomerCard> ensureCustomer({
    required String accessToken,
    required String phone,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/pos/customers',
        data: <String, Object?>{'phone': phone},
        options: _auth(accessToken),
      );
      final map = _map(response);
      if (map['customer'] is Map) {
        return PosCustomerCard.fromJson(
          Map<Object?, Object?>.from(map['customer'] as Map),
        );
      }
      return PosCustomerCard.fromJson(map);
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<PosCheckoutResult> checkout({
    required String accessToken,
    required PosCheckoutInput input,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/pos/checkout',
        data: input.toJson(),
        options: _auth(accessToken),
      );
      return PosCheckoutResult.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<List<PosRecentSale>> recentSales({required String accessToken}) async {
    _requireBase();
    try {
      final response = await _dio.get<dynamic>(
        '/api/app/staff/pos/recent',
        options: _auth(accessToken),
      );
      return parsePosRecentSales(response.data);
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<CatalogWriteResult> addCatalogProduct({
    required String accessToken,
    required String productId,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/catalog/products',
        data: <String, Object?>{'productId': productId},
        options: _auth(accessToken),
      );
      return CatalogWriteResult.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<CatalogWriteResult> createCustomCatalogProduct({
    required String accessToken,
    required CreateCustomProductInput input,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/catalog/custom',
        data: input.toJson(),
        options: _auth(accessToken),
      );
      return CatalogWriteResult.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<void> updateStoreProduct({
    required String accessToken,
    required String storeProductId,
    required UpdateStoreProductInput input,
  }) async {
    _requireBase();
    try {
      await _dio.patch<dynamic>(
        '/api/app/staff/inventory/products/$storeProductId',
        data: input.toJson(),
        options: _auth(accessToken),
      );
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<InventoryBatch> addProductBatch({
    required String accessToken,
    required String storeProductId,
    required OpeningBatchInput input,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/inventory/products/$storeProductId/batches',
        data: input.toJson(),
        options: _auth(accessToken),
      );
      return _parseBatch(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<InventoryBatch> updateProductBatch({
    required String accessToken,
    required String storeProductId,
    required String batchId,
    required Map<String, Object?> patch,
  }) async {
    _requireBase();
    try {
      final response = await _dio.patch<dynamic>(
        '/api/app/staff/inventory/products/$storeProductId/batches/$batchId',
        data: patch,
        options: _auth(accessToken),
      );
      return _parseBatch(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  InventoryBatch _parseBatch(Map<Object?, Object?> map) {
    final nested = map['batch'];
    final source = nested is Map ? Map<Object?, Object?>.from(nested) : map;
    return InventoryBatch.fromJson(
      source.map((Object? key, Object? value) => MapEntry('$key', value)),
    );
  }

  @override
  Future<SupplierOption> createSupplier({
    required String accessToken,
    required String name,
    String? phone,
    String? contactPerson,
    String? notes,
    double? openingBalance,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/suppliers',
        data: SaveSupplierInput(
          name: name,
          phone: phone,
          contactPerson: contactPerson,
          notes: notes,
          openingBalance: openingBalance,
        ).toJson(),
        options: _auth(accessToken),
      );
      final supplier = _parseStaffSupplier(_map(response));
      return SupplierOption(
        id: supplier.id,
        name: supplier.name,
        phone: supplier.phone,
        isActive: supplier.isActive,
      );
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffSupplier> updateSupplier({
    required String accessToken,
    required String supplierId,
    required SaveSupplierInput input,
  }) async {
    _requireBase();
    try {
      final response = await _dio.patch<dynamic>(
        '/api/app/staff/suppliers/$supplierId',
        data: input.toJson(),
        options: _auth(accessToken),
      );
      return _parseStaffSupplier(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffSupplier> setSupplierActive({
    required String accessToken,
    required String supplierId,
    required bool isActive,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/suppliers/$supplierId/active',
        data: <String, Object?>{'is_active': isActive},
        options: _auth(accessToken),
      );
      return _parseStaffSupplier(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<PurchaseDetail> createPurchase({
    required String accessToken,
    required SavePurchaseInput input,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/purchases',
        data: input.toJson(),
        options: _auth(accessToken),
      );
      return _parsePurchaseDetail(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffCustomer> ensureStoreCustomer({
    required String accessToken,
    required String phone,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/customers',
        data: <String, Object?>{'phone': phone},
        options: _auth(accessToken),
      );
      return StaffCustomer.fromDetailJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffCustomer> updateStoreCustomer({
    required String accessToken,
    required String storeCustomerId,
    String? notes,
    int? loyaltyPoints,
  }) async {
    _requireBase();
    try {
      final response = await _dio.patch<dynamic>(
        '/api/app/staff/customers/$storeCustomerId',
        data: <String, Object?>{
          if (notes != null) 'notes': notes,
          if (loyaltyPoints != null) 'loyalty_points': loyaltyPoints,
        },
        options: _auth(accessToken),
      );
      return StaffCustomer.fromDetailJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffPayment> settleCustomerPayment({
    required String accessToken,
    required CustomerSettlementInput input,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/payments/customer-settlement',
        data: input.toJson(),
        options: _auth(accessToken),
      );
      return StaffPayment.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffPayment> settleSupplierPayment({
    required String accessToken,
    required SupplierSettlementInput input,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/payments/supplier-settlement',
        data: input.toJson(),
        options: _auth(accessToken),
      );
      return StaffPayment.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffOrderDetail> updateOrderStatus({
    required String accessToken,
    required String orderId,
    required String toStatus,
    String? notes,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/orders/$orderId/status',
        data: <String, Object?>{
          'to_status': toStatus,
          'notes': notes,
        },
        options: _auth(accessToken),
      );
      return StaffOrderDetail.fromApi(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffReturnDetail> createReturn({
    required String accessToken,
    required CreateReturnInput input,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/returns',
        data: input.toJson(),
        options: _auth(accessToken),
      );
      return StaffReturnDetail.fromApi(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffReturnDetail> approveReturn({
    required String accessToken,
    required String returnId,
    String? notes,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/returns/$returnId/approve',
        data: <String, Object?>{'notes': notes},
        options: _auth(accessToken),
      );
      return StaffReturnDetail.fromApi(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffReturnDetail> rejectReturn({
    required String accessToken,
    required String returnId,
    String? notes,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/returns/$returnId/reject',
        data: <String, Object?>{'notes': notes},
        options: _auth(accessToken),
      );
      return StaffReturnDetail.fromApi(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffStore> updateStore({
    required String accessToken,
    required UpdateStoreInput input,
  }) async {
    _requireBase();
    try {
      final response = await _dio.patch<dynamic>(
        '/api/app/staff/store',
        data: input.toJson(),
        options: _auth(accessToken),
      );
      return StaffStore.fromApi(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StoreImageUploadResult> uploadStoreImage({
    required String accessToken,
    required String kind,
    required List<int> bytes,
    required String filename,
  }) async {
    _requireBase();
    try {
      final form = FormData.fromMap(<String, Object?>{
        'kind': kind,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post<dynamic>(
        '/api/app/staff/store/images',
        data: form,
        options: _auth(accessToken),
      );
      return StoreImageUploadResult.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<void> updateProfile({
    required String accessToken,
    required UpdateProfileInput input,
  }) async {
    _requireBase();
    try {
      await _dio.patch<dynamic>(
        '/api/app/staff/profile',
        data: input.toJson(),
        options: _auth(accessToken),
      );
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<void> attachCategories({
    required String accessToken,
    required List<String> categoryIds,
  }) async {
    _requireBase();
    try {
      await _dio.post<dynamic>(
        '/api/app/staff/categories/attach',
        data: <String, Object?>{'category_ids': categoryIds},
        options: _auth(accessToken),
      );
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<void> detachCategories({
    required String accessToken,
    required List<String> categoryIds,
  }) async {
    _requireBase();
    try {
      await _dio.post<dynamic>(
        '/api/app/staff/categories/detach',
        data: <String, Object?>{'category_ids': categoryIds},
        options: _auth(accessToken),
      );
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffCategory> createCategory({
    required String accessToken,
    required String name,
    String? slug,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/categories',
        data: <String, Object?>{
          'name': name,
          if (slug != null && slug.isNotEmpty) 'slug': slug,
        },
        options: _auth(accessToken),
      );
      return StaffCategory.fromApi(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<StaffCategory> updateCategory({
    required String accessToken,
    required String categoryId,
    String? name,
    bool? isActive,
  }) async {
    _requireBase();
    try {
      final response = await _dio.patch<dynamic>(
        '/api/app/staff/categories/$categoryId',
        data: <String, Object?>{
          if (name != null) 'name': name,
          if (isActive != null) 'is_active': isActive,
        },
        options: _auth(accessToken),
      );
      return StaffCategory.fromApi(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  StaffSupplier _parseStaffSupplier(Map<Object?, Object?> map) {
    final nested = map['supplier'];
    final source = nested is Map ? Map<Object?, Object?>.from(nested) : map;
    return StaffSupplier.fromJson(
      source.map((Object? key, Object? value) => MapEntry('$key', value)),
    );
  }

  PurchaseDetail _parsePurchaseDetail(Map<Object?, Object?> map) {
    final orderRaw = map['order'];
    final order = orderRaw is Map
        ? Map<Object?, Object?>.from(orderRaw)
        : map;
    final itemsRaw = map['items'];
    final items = <PurchaseLineItem>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is! Map) continue;
        items.add(
          PurchaseLineItem.fromJson(
            item.map((Object? k, Object? v) => MapEntry('$k', v)),
          ),
        );
      }
    }
    String asStr(Object? value, [String fallback = '']) {
      if (value == null) return fallback;
      final text = '$value';
      return text.isEmpty ? fallback : text;
    }

    double asNum(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    return PurchaseDetail(
      id: asStr(order['id']),
      supplierId: asStr(order['supplier_id']),
      supplierName: asStr(map['supplier_name'], '—'),
      invoiceNumber: asStr(order['invoice_number']),
      invoiceDate: asStr(order['invoice_date']),
      subtotal: asNum(order['subtotal']),
      discountAmount: asNum(order['discount_amount']),
      taxAmount: asNum(order['tax_amount']),
      otherCharges: asNum(order['other_charges']),
      roundOffAmount: asNum(order['round_off_amount']),
      grandTotal: asNum(order['grand_total']),
      paymentStatus: asStr(order['payment_status'], 'pending'),
      paymentMethod: order['payment_method']?.toString(),
      paidAmount: asNum(order['paid_amount']),
      dueAmount: asNum(order['due_amount']),
      status: asStr(order['status'], 'draft'),
      notes: order['notes']?.toString(),
      items: items,
    );
  }
}

final staffWriteApiProvider = Provider<StaffWriteApi>(
  (Ref ref) => DioStaffWriteApi(),
);

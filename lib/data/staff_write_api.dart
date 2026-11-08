import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import '../features/staff/pos/pos_product.dart';
import 'api_client.dart';
import 'models/pos_checkout.dart';
import 'supabase_client.dart';

/// Next `/api/app/staff/*` writes. Bearer = Supabase access_token.
abstract class StaffWriteApi {
  Future<PosCustomerCard> ensurePosCustomer({
    required String accessToken,
    required String phone,
  });

  Future<PosCheckoutResult> checkoutPos({
    required String accessToken,
    required String customerId,
    required List<PosCartItem> items,
    required PosPaymentMethod paymentMethod,
    required double paidAmount,
    required String discountType,
    required double discountValue,
  });

  Future<List<PosRecentSale>> recentPosSales({required String accessToken});
}

class DioStaffWriteApi implements StaffWriteApi {
  DioStaffWriteApi({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _normalizeBase(baseUrl ?? Env.apiBaseUrl),
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 45),
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

  Options _auth(String accessToken) {
    return Options(
      headers: <String, Object?>{'Authorization': 'Bearer $accessToken'},
    );
  }

  void _requireBase() {
    if (_dio.options.baseUrl.isEmpty) {
      throw AppApiException('API_BASE_URL is not configured');
    }
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
  Future<PosCustomerCard> ensurePosCustomer({
    required String accessToken,
    required String phone,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/pos/customer',
        data: <String, Object?>{'phone': phone},
        options: _auth(accessToken),
      );
      return PosCustomerCard.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<PosCheckoutResult> checkoutPos({
    required String accessToken,
    required String customerId,
    required List<PosCartItem> items,
    required PosPaymentMethod paymentMethod,
    required double paidAmount,
    required String discountType,
    required double discountValue,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/staff/pos/checkout',
        data: <String, Object?>{
          'customer_id': customerId,
          'items': items
              .map(
                (PosCartItem item) => <String, Object?>{
                  'store_product_id': item.storeProductId,
                  'quantity': item.quantity.floor(),
                  'unit_price': item.product.unitPrice,
                  'unit_mrp': item.product.mrp,
                },
              )
              .toList(),
          'payment_method': paymentMethod.apiValue,
          'paid_amount': paidAmount,
          'discount_type': discountType,
          'discount_value': discountValue,
          'tax_amount': 0,
        },
        options: _auth(accessToken),
      );
      return PosCheckoutResult.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<List<PosRecentSale>> recentPosSales({
    required String accessToken,
  }) async {
    _requireBase();
    try {
      final response = await _dio.get<dynamic>(
        '/api/app/staff/pos/recent-sales',
        options: _auth(accessToken),
      );
      return parsePosRecentSales(response.data);
    } on DioException catch (error) {
      _throwDio(error);
    }
  }
}

final staffWriteApiProvider = Provider<StaffWriteApi>(
  (Ref ref) => DioStaffWriteApi(),
);

String? currentStaffAccessToken() {
  if (!AppSupabase.isReady) return null;
  return AppSupabase.client.auth.currentSession?.accessToken;
}

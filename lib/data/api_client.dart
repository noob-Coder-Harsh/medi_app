import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import 'models/checkout.dart';
import 'models/customer_order.dart';

/// Next `/api/app/*` customer writes. Bearer = Firebase idToken.
abstract class AppWriteApi {
  Future<CustomerProfile> ensureSession({required String idToken});

  Future<RevalidateCartResult> revalidateCart({
    required String idToken,
    required String storeId,
    required List<RevalidateCartLineInput> items,
  });

  Future<PlaceOnlineOrderResult> placeOrder({
    required String idToken,
    required PlaceOnlineOrderInput input,
  });

  Future<List<CustomerOrderListItem>> listOrders({required String idToken});

  Future<CustomerOrderDetail> getOrder({
    required String idToken,
    required String orderId,
  });

  Future<CustomerOrderDetail> cancelOrder({
    required String idToken,
    required String orderId,
  });
}

class AppApiException implements Exception {
  AppApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Parses a JSON object body. Next soft-404s often return HTML with HTTP 200.
Map<Object?, Object?> requireJsonMap(Response<dynamic> response) {
  final data = response.data;
  if (data is Map) return Map<Object?, Object?>.from(data);

  final status = response.statusCode;
  final raw = data is String ? data.trimLeft() : '';
  if (raw.startsWith('<!DOCTYPE') ||
      raw.startsWith('<html') ||
      raw.startsWith('<HTML')) {
    throw AppApiException(
      'API route missing on server (got HTML ${status ?? '?'}). '
      'Set API_BASE_URL to the deployed host and ensure /api/app routes exist.',
      statusCode: status,
    );
  }

  throw AppApiException(
    'Unexpected response${status != null ? ' ($status)' : ''}',
    statusCode: status,
  );
}

String dioErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['error'] != null) {
    final err = data['error'];
    if (err is Map) {
      final message = err['message'] ?? err['error'] ?? err['code'];
      if (message != null && '$message'.isNotEmpty) return '$message';
    }
    return '${data['error']}';
  }
  return error.message ?? 'Request failed';
}

class DioAppWriteApi implements AppWriteApi {
  DioAppWriteApi({Dio? dio, String? baseUrl})
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

  Options _auth(String idToken) {
    return Options(
      headers: <String, Object?>{'Authorization': 'Bearer $idToken'},
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
  Future<CustomerProfile> ensureSession({required String idToken}) async {
    if (_dio.options.baseUrl.isEmpty) {
      throw AppApiException('API_BASE_URL is not configured');
    }
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/session',
        data: <String, Object?>{'idToken': idToken},
        options: _auth(idToken),
      );
      return CustomerProfile.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<RevalidateCartResult> revalidateCart({
    required String idToken,
    required String storeId,
    required List<RevalidateCartLineInput> items,
  }) async {
    if (_dio.options.baseUrl.isEmpty) {
      throw AppApiException('API_BASE_URL is not configured');
    }
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/cart/revalidate',
        data: <String, Object?>{
          'storeId': storeId,
          'items': items.map((RevalidateCartLineInput i) => i.toJson()).toList(),
        },
        options: _auth(idToken),
      );
      return RevalidateCartResult.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<PlaceOnlineOrderResult> placeOrder({
    required String idToken,
    required PlaceOnlineOrderInput input,
  }) async {
    if (_dio.options.baseUrl.isEmpty) {
      throw AppApiException('API_BASE_URL is not configured');
    }
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/orders',
        data: input.toJson(),
        options: _auth(idToken),
      );
      return PlaceOnlineOrderResult.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  void _requireBase() {
    if (_dio.options.baseUrl.isEmpty) {
      throw AppApiException('API_BASE_URL is not configured');
    }
  }

  @override
  Future<List<CustomerOrderListItem>> listOrders({
    required String idToken,
  }) async {
    _requireBase();
    try {
      final response = await _dio.get<dynamic>(
        '/api/app/orders',
        options: _auth(idToken),
      );
      return parseCustomerOrderList(response.data);
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<CustomerOrderDetail> getOrder({
    required String idToken,
    required String orderId,
  }) async {
    _requireBase();
    try {
      final response = await _dio.get<dynamic>(
        '/api/app/orders/$orderId',
        options: _auth(idToken),
      );
      return CustomerOrderDetail.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }

  @override
  Future<CustomerOrderDetail> cancelOrder({
    required String idToken,
    required String orderId,
  }) async {
    _requireBase();
    try {
      final response = await _dio.post<dynamic>(
        '/api/app/orders/$orderId/cancel',
        data: <String, Object?>{},
        options: _auth(idToken),
      );
      return CustomerOrderDetail.fromJson(_map(response));
    } on DioException catch (error) {
      _throwDio(error);
    }
  }
}

final appWriteApiProvider = Provider<AppWriteApi>(
  (Ref ref) => DioAppWriteApi(),
);

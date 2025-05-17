import 'package:flutter/foundation.dart';

import '../../../core/network/api_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/app_exception.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final ApiService _apiService;

  PaymentRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get available payment methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/payments/methods',
      );

      final List<dynamic> methodsJson = response['payment_methods'];
      return methodsJson.map((json) => PaymentMethod.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching payment methods: $e');
      }
      throw AppException(
        'Failed to load payment methods. Please try again.',
        e.toString(),
      );
    }
  }

  /// Process a payment
  Future<Payment> processPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.apiBaseUrl}/api/payments/process',
        body: {
          'booking_id': bookingId,
          'user_id': userId,
          'amount': amount,
          'payment_method': paymentMethod,
          if (additionalInfo != null) ...additionalInfo,
        },
      );

      return Payment.fromJson(response['payment']);
    } catch (e) {
      if (kDebugMode) {
        print('Error processing payment: $e');
      }
      throw AppException(
        'Failed to process payment. Please try again.',
        e.toString(),
      );
    }
  }

  /// Verify payment status
  Future<Payment> verifyPayment(String paymentId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/payments/$paymentId/verify',
      );

      return Payment.fromJson(response['payment']);
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying payment: $e');
      }
      throw AppException(
        'Failed to verify payment. Please try again.',
        e.toString(),
      );
    }
  }

  /// Get payment history for a user
  Future<List<Payment>> getPaymentHistory(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/payments/history?user_id=$userId',
      );

      final List<dynamic> paymentsJson = response['payments'];
      return paymentsJson.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching payment history: $e');
      }
      throw AppException(
        'Failed to load payment history. Please try again.',
        e.toString(),
      );
    }
  }

  /// Cancel a payment
  Future<bool> cancelPayment(String paymentId, String reason) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/payments/$paymentId/cancel',
        body: {
          'reason': reason,
        },
      );

      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling payment: $e');
      }
      throw AppException(
        'Failed to cancel payment. Please try again.',
        e.toString(),
      );
    }
  }
} 
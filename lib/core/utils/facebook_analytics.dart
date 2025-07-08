import 'dart:io';
import 'package:flutter/services.dart';

class FacebookAnalytics {
  static const MethodChannel _channel = MethodChannel('facebook_analytics');

  // Log app open event
  static Future<void> logAppOpen() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('logAppOpen');
      } catch (e) {
        print('Error logging app open: $e');
      }
    }
  }

  // Log user registration event
  static Future<void> logRegistration({
    required String method,
    Map<String, dynamic>? parameters,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('logRegistration', {
          'method': method,
          'parameters': parameters ?? {},
        });
      } catch (e) {
        print('Error logging registration: $e');
      }
    }
  }

  // Log booking/purchase event
  static Future<void> logBooking({
    required double amount,
    required String currency,
    required String carType,
    Map<String, dynamic>? parameters,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('logBooking', {
          'amount': amount,
          'currency': currency,
          'carType': carType,
          'parameters': parameters ?? {},
        });
      } catch (e) {
        print('Error logging booking: $e');
      }
    }
  }

  // Log payment event
  static Future<void> logPayment({
    required double amount,
    required String currency,
    required String paymentMethod,
    Map<String, dynamic>? parameters,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('logPayment', {
          'amount': amount,
          'currency': currency,
          'paymentMethod': paymentMethod,
          'parameters': parameters ?? {},
        });
      } catch (e) {
        print('Error logging payment: $e');
      }
    }
  }

  // Log search event
  static Future<void> logSearch({
    required String searchTerm,
    Map<String, dynamic>? parameters,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('logSearch', {
          'searchTerm': searchTerm,
          'parameters': parameters ?? {},
        });
      } catch (e) {
        print('Error logging search: $e');
      }
    }
  }

  // Log custom event
  static Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('logCustomEvent', {
          'eventName': eventName,
          'parameters': parameters ?? {},
        });
      } catch (e) {
        print('Error logging custom event: $e');
      }
    }
  }

  // Log view content event
  static Future<void> logViewContent({
    required String contentType,
    required String contentId,
    Map<String, dynamic>? parameters,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('logViewContent', {
          'contentType': contentType,
          'contentId': contentId,
          'parameters': parameters ?? {},
        });
      } catch (e) {
        print('Error logging view content: $e');
      }
    }
  }
}

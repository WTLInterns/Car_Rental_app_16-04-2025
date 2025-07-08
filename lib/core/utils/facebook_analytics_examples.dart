// Facebook Analytics Usage Examples for WTL Car Rental App
// This file contains examples of how to integrate Facebook Analytics
// throughout your app for different user actions and events.

import 'facebook_analytics.dart';

class FacebookAnalyticsExamples {
  
  // Example 1: User Registration
  static Future<void> trackUserRegistration({
    required String registrationMethod,
    required String userType,
  }) async {
    await FacebookAnalytics.logRegistration(
      method: registrationMethod, // 'email', 'phone', 'google', 'facebook'
      parameters: {
        'user_type': userType, // 'customer', 'driver'
        'registration_source': 'mobile_app',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Example 2: Car Search
  static Future<void> trackCarSearch({
    required String searchQuery,
    required String location,
    required DateTime pickupDate,
    required DateTime dropoffDate,
    int? resultsCount,
  }) async {
    await FacebookAnalytics.logSearch(
      searchTerm: searchQuery,
      parameters: {
        'location': location,
        'pickup_date': pickupDate.toIso8601String(),
        'dropoff_date': dropoffDate.toIso8601String(),
        'rental_duration_days': dropoffDate.difference(pickupDate).inDays,
        'results_count': resultsCount ?? 0,
        'search_type': 'car_rental',
      },
    );
  }

  // Example 3: View Car Details
  static Future<void> trackViewCarDetails({
    required String carId,
    required String carModel,
    required String carType,
    required double pricePerDay,
    required String location,
  }) async {
    await FacebookAnalytics.logViewContent(
      contentType: 'car',
      contentId: carId,
      parameters: {
        'car_model': carModel,
        'car_type': carType, // 'economy', 'compact', 'suv', 'luxury'
        'price_per_day': pricePerDay,
        'location': location,
        'currency': 'USD',
        'availability': 'available',
      },
    );
  }

  // Example 4: Car Booking/Purchase
  static Future<void> trackCarBooking({
    required String bookingId,
    required String carId,
    required String carModel,
    required double totalAmount,
    required String currency,
    required int rentalDays,
    required String pickupLocation,
    required String dropoffLocation,
  }) async {
    await FacebookAnalytics.logBooking(
      amount: totalAmount,
      currency: currency,
      carType: carModel,
      parameters: {
        'booking_id': bookingId,
        'car_id': carId,
        'car_model': carModel,
        'rental_days': rentalDays,
        'pickup_location': pickupLocation,
        'dropoff_location': dropoffLocation,
        'booking_date': DateTime.now().toIso8601String(),
        'price_per_day': totalAmount / rentalDays,
      },
    );
  }

  // Example 5: Payment Processing
  static Future<void> trackPayment({
    required String bookingId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    await FacebookAnalytics.logPayment(
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod, // 'credit_card', 'debit_card', 'paypal', 'apple_pay'
      parameters: {
        'booking_id': bookingId,
        'payment_status': paymentStatus, // 'success', 'failed', 'pending'
        'payment_date': DateTime.now().toIso8601String(),
        'transaction_type': 'car_rental_payment',
      },
    );
  }

  // Example 6: User Login
  static Future<void> trackUserLogin({
    required String loginMethod,
    required String userType,
    required bool isReturningUser,
  }) async {
    await FacebookAnalytics.logCustomEvent(
      eventName: 'user_login',
      parameters: {
        'login_method': loginMethod, // 'email', 'phone', 'google', 'facebook'
        'user_type': userType, // 'customer', 'driver'
        'is_returning_user': isReturningUser,
        'login_date': DateTime.now().toIso8601String(),
      },
    );
  }

  // Example 7: Trip Start (for drivers)
  static Future<void> trackTripStart({
    required String tripId,
    required String driverId,
    required String customerId,
    required String carId,
    required String pickupLocation,
    required String dropoffLocation,
  }) async {
    await FacebookAnalytics.logCustomEvent(
      eventName: 'trip_started',
      parameters: {
        'trip_id': tripId,
        'driver_id': driverId,
        'customer_id': customerId,
        'car_id': carId,
        'pickup_location': pickupLocation,
        'dropoff_location': dropoffLocation,
        'trip_start_time': DateTime.now().toIso8601String(),
      },
    );
  }

  // Example 8: Trip Completion
  static Future<void> trackTripCompletion({
    required String tripId,
    required double tripDuration,
    required double distance,
    required double finalAmount,
    required String currency,
  }) async {
    await FacebookAnalytics.logCustomEvent(
      eventName: 'trip_completed',
      parameters: {
        'trip_id': tripId,
        'trip_duration_minutes': tripDuration,
        'distance_km': distance,
        'final_amount': finalAmount,
        'currency': currency,
        'trip_end_time': DateTime.now().toIso8601String(),
      },
    );
  }

  // Example 9: App Rating/Review
  static Future<void> trackAppRating({
    required int rating,
    String? reviewText,
  }) async {
    await FacebookAnalytics.logCustomEvent(
      eventName: 'app_rated',
      parameters: {
        'rating': rating,
        'has_review_text': reviewText != null && reviewText.isNotEmpty,
        'rating_date': DateTime.now().toIso8601String(),
      },
    );
  }

  // Example 10: Profile Update
  static Future<void> trackProfileUpdate({
    required String userId,
    required List<String> updatedFields,
  }) async {
    await FacebookAnalytics.logCustomEvent(
      eventName: 'profile_updated',
      parameters: {
        'user_id': userId,
        'updated_fields': updatedFields.join(','),
        'update_date': DateTime.now().toIso8601String(),
      },
    );
  }

  // Example 11: Push Notification Interaction
  static Future<void> trackNotificationInteraction({
    required String notificationType,
    required String action, // 'opened', 'dismissed', 'clicked'
  }) async {
    await FacebookAnalytics.logCustomEvent(
      eventName: 'notification_interaction',
      parameters: {
        'notification_type': notificationType,
        'action': action,
        'interaction_date': DateTime.now().toIso8601String(),
      },
    );
  }

  // Example 12: Feature Usage
  static Future<void> trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? additionalData,
  }) async {
    await FacebookAnalytics.logCustomEvent(
      eventName: 'feature_used',
      parameters: {
        'feature_name': featureName,
        'usage_date': DateTime.now().toIso8601String(),
        ...?additionalData,
      },
    );
  }
}

// Usage Examples in your screens:

/*
// In Registration Screen:
await FacebookAnalyticsExamples.trackUserRegistration(
  registrationMethod: 'email',
  userType: 'customer',
);

// In Search Screen:
await FacebookAnalyticsExamples.trackCarSearch(
  searchQuery: 'SUV cars',
  location: 'New York',
  pickupDate: DateTime.now().add(Duration(days: 1)),
  dropoffDate: DateTime.now().add(Duration(days: 5)),
  resultsCount: searchResults.length,
);

// In Car Details Screen:
await FacebookAnalyticsExamples.trackViewCarDetails(
  carId: car.id,
  carModel: car.model,
  carType: car.type,
  pricePerDay: car.pricePerDay,
  location: car.location,
);

// In Booking Confirmation:
await FacebookAnalyticsExamples.trackCarBooking(
  bookingId: booking.id,
  carId: booking.carId,
  carModel: booking.carModel,
  totalAmount: booking.totalAmount,
  currency: 'USD',
  rentalDays: booking.rentalDays,
  pickupLocation: booking.pickupLocation,
  dropoffLocation: booking.dropoffLocation,
);

// In Payment Screen:
await FacebookAnalyticsExamples.trackPayment(
  bookingId: booking.id,
  amount: payment.amount,
  currency: 'USD',
  paymentMethod: 'credit_card',
  paymentStatus: 'success',
);
*/

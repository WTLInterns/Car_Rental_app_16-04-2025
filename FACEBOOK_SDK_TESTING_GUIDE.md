# Facebook SDK Integration Testing Guide

## Overview
This guide provides comprehensive instructions for testing the Facebook SDK integration in your WTL Car Rental app.

## Prerequisites
1. Facebook App ID: 9822494027828805
2. Access to Facebook Events Manager
3. Android device or emulator for testing
4. Facebook Developer Account with access to the app

## Testing Setup

### 1. Facebook Events Manager Access
1. Go to [Facebook Events Manager](https://www.facebook.com/events_manager2)
2. Select your app (App ID: 9822494027828805)
3. Navigate to "Data Sources" > "App Events"
4. You should see your app listed

### 2. Enable Test Events
1. In Events Manager, go to "Test Events"
2. Add your test device:
   - For Android: Use your device's Advertising ID
   - You can find this in Settings > Google > Ads > Advertising ID
3. Enable "Test Events" mode for real-time event viewing

### 3. Build and Install the App
```bash
# Navigate to your project directory
cd "d:\_WTL Projects\_______WTL\final car rental app\Car_Rental_app_16-04-2025"

# Clean and build the project
flutter clean
flutter pub get

# Build and install on connected device
flutter run
```

## Event Testing Scenarios

### 1. App Open Event
**Test:** Launch the app
**Expected:** `fb_mobile_activate_app` event should appear in Events Manager
**Verification:** Check Events Manager within 5-10 minutes

### 2. Registration Event
**Test:** Complete user registration
**Implementation Example:**
```dart
// In your registration success handler
await FacebookAnalytics.logRegistration(
  method: 'email',
  parameters: {
    'user_type': 'customer',
    'registration_source': 'mobile_app'
  }
);
```
**Expected:** `fb_mobile_complete_registration` event

### 3. Search Event
**Test:** Search for cars
**Implementation Example:**
```dart
// In your search functionality
await FacebookAnalytics.logSearch(
  searchTerm: 'SUV cars',
  parameters: {
    'location': 'New York',
    'date_range': '2025-01-15 to 2025-01-20'
  }
);
```
**Expected:** `fb_mobile_search` event

### 4. View Content Event
**Test:** View car details
**Implementation Example:**
```dart
// When user views car details
await FacebookAnalytics.logViewContent(
  contentType: 'car',
  contentId: 'car_123',
  parameters: {
    'car_model': 'Toyota Camry',
    'price_per_day': 45.0,
    'location': 'New York'
  }
);
```
**Expected:** `fb_mobile_content_view` event

### 5. Booking/Purchase Event
**Test:** Complete a car booking
**Implementation Example:**
```dart
// When booking is confirmed
await FacebookAnalytics.logBooking(
  amount: 225.0,
  currency: 'USD',
  carType: 'SUV',
  parameters: {
    'booking_id': 'BK123456',
    'rental_days': 5,
    'pickup_location': 'Airport',
    'dropoff_location': 'Downtown'
  }
);
```
**Expected:** `fb_mobile_purchase` event with revenue data

### 6. Payment Event
**Test:** Process payment
**Implementation Example:**
```dart
// When payment is processed
await FacebookAnalytics.logPayment(
  amount: 225.0,
  currency: 'USD',
  paymentMethod: 'credit_card',
  parameters: {
    'payment_processor': 'stripe',
    'card_type': 'visa'
  }
);
```
**Expected:** `fb_mobile_add_payment_info` event

## Verification Steps

### 1. Real-time Testing
1. Enable Test Events in Events Manager
2. Perform actions in the app
3. Check Test Events tab for immediate feedback
4. Events should appear within 1-2 minutes

### 2. Production Verification
1. After 24-48 hours, check the main Events dashboard
2. Verify event counts and parameters
3. Check conversion tracking is working

### 3. Debug Mode
For detailed debugging, you can enable Facebook SDK debug mode:

```kotlin
// Add to MyApplication.kt onCreate method
FacebookSdk.setIsDebugEnabled(true)
FacebookSdk.addLoggingBehavior(LoggingBehavior.APP_EVENTS)
```

## Troubleshooting

### Common Issues

1. **Events not appearing:**
   - Check internet connection
   - Verify App ID is correct
   - Ensure Facebook SDK is properly initialized
   - Check Android logs for errors

2. **Wrong App ID error:**
   - Verify strings.xml has correct App ID: 9822494027828805
   - Check AndroidManifest.xml references @string/facebook_app_id

3. **Build errors:**
   - Run `flutter clean && flutter pub get`
   - Check all dependencies are properly added
   - Verify Android SDK and build tools are up to date

### Debug Commands
```bash
# Check Android logs for Facebook SDK
adb logcat | grep -i facebook

# Check for app events specifically
adb logcat | grep -i "AppEvents"
```

## Integration Examples

### Example: Login Screen Integration
```dart
// In your login success handler
await FacebookAnalytics.logCustomEvent(
  eventName: 'user_login',
  parameters: {
    'login_method': 'email',
    'user_type': 'returning_customer'
  }
);
```

### Example: Car Search Integration
```dart
// In your search results screen
await FacebookAnalytics.logSearch(
  searchTerm: searchQuery,
  parameters: {
    'results_count': searchResults.length,
    'filter_applied': hasFilters,
    'location': selectedLocation
  }
);
```

## Success Criteria
✅ App Open events are tracked automatically
✅ Custom events appear in Events Manager
✅ Revenue tracking works for bookings
✅ Event parameters are correctly passed
✅ No crashes or errors in app logs

## Next Steps
Once testing is complete and events are flowing correctly:
1. Set up Facebook Ad Campaigns
2. Configure conversion tracking
3. Create custom audiences based on app events
4. Monitor performance in Facebook Analytics

## Support
If you encounter issues:
1. Check Facebook Developer Documentation
2. Review Android logs for specific error messages
3. Verify all configuration steps were completed correctly
4. Test on multiple devices if possible

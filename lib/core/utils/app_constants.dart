class AppConstants {
  // Storage Keys
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUserId = 'userId';
  static const String keyUserRole = 'role';
  static const String keyUserData = 'userData';
  static const String keyLoginTimestamp = 'loginTimestamp';
  static const String keyRememberMe = 'rememberMe';
  static const String keySavedMobile = 'savedMobile';
  
  // User Roles
  static const String roleUser = 'USER';
  static const String roleDriver = 'DRIVER';
  static const String roleAdminDriver = 'ADMIN_DRIVER';
  
  // Routes
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeUserHome = '/user-home';
  static const String routeDriverTrips = '/driver-trips';
  static const String routeAdminDriverHome = '/admin-driver-home';
  static const String routeTracking = '/tracking';
  
  // Booking Types
  static const String bookingTypeOneWay = 'oneWay';
  static const String bookingTypeRoundTrip = 'roundTrip';
  
  // API Response Status
  static const String statusSuccess = 'success';
  
  // API URLs
  static const String apiBaseUrl = 'https://api.worldtriplink.com';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String bookingsEndpoint = '/bookings';
  static const String vehiclesEndpoint = '/vehicles';
  static const String paymentsEndpoint = '/payments';
  static const String tripsEndpoint = '/trips';
  static const String profileEndpoint = '/profile';
  
  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  
  // Other Constants
  static const int apiTimeoutDuration = 30; // seconds
  static const int splashScreenDuration = 3; // seconds
  static const String appVersion = '1.0.0';
} 
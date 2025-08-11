class AppConfig {
  // API Configuration
  static const String baseApiUrl = 'https://api.worldtriplink.com';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login1';
  
  // Map API Key - Should use environment variables in production
  static const String googleMapsApiKey = "AIzaSyAKjmBSUJ3XR8uD10vG2ptzqLJAZnOlzqI";
  
  // App Theme Colors
  static const primaryColorHex = 0xFF2E3192;
  static const secondaryColorHex = 0xFF4A90E2;
  static const accentColorHex = 0xFFFFCC00;
  static const backgroundColorHex = 0xFFF8F9FA;
  static const cardColorHex = 0xFFFFFFFF;
  static const surfaceColorHex = 0xFFF0F7FF;
  static const textColorHex = 0xFF333333;
  static const lightTextColorHex = 0xFF666666;
  static const mutedTextColorHex = 0xFFA0A0A0;
  
  // Authentication Settings
  static const int authTokenExpireDays = 20;
} 
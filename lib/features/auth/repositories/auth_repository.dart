import '../../../core/network/api_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/app_exception.dart';
import '../models/user_model.dart';
import '../../../core/config/app_config.dart';

class AuthRepository {
  final ApiService _apiService;
  
  AuthRepository({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  // Get current logged in user data
  Future<User?> getCurrentUser() async {
    final userData = StorageService.getObject(AppConstants.keyUserData);
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }
  
  // Check if user is logged in and token is valid
  Future<bool> isLoggedIn() async {
    final isLoggedIn = StorageService.getBool(AppConstants.keyIsLoggedIn);
    if (!isLoggedIn) return false;
    
    // Check if login session is still valid (token expiration)
    final loginTimestamp = StorageService.getInt(AppConstants.keyLoginTimestamp);
    final now = DateTime.now().millisecondsSinceEpoch;
    const expiryMillis = AppConfig.authTokenExpireDays * 24 * 60 * 60 * 1000;
    
    return (now - loginTimestamp) < expiryMillis;
  }
  
  // User login
  Future<User> login(String mobile, String password) async {
    try {
      final response = await _apiService.post(
        AppConfig.loginEndpoint,
        body: {
          'mobile': mobile,
          'password': password,
        },
      );
      
      if (response['status'] == AppConstants.statusSuccess) {
        final user = User.fromJson(response);
        
        // Save user data
        await StorageService.setBool(AppConstants.keyIsLoggedIn, true);
        await StorageService.setInt(AppConstants.keyUserId, user.id ?? 0);
        await StorageService.setString(AppConstants.keyUserRole, user.role ?? '');
        await StorageService.setInt(
          AppConstants.keyLoginTimestamp,
          DateTime.now().millisecondsSinceEpoch,
        );
        await StorageService.setObject(AppConstants.keyUserData, user.toJson());
        
        return user;
      } else {
        throw AuthException(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AuthException('Login failed: ${e.toString()}');
    }
  }
  
  // User registration
  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post(
        '/auth/register',
        body: userData,
      );
      
      if (response['id'] != null) {
        return true;
      } else {
        throw AuthException(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }
  
  // Request password reset (send OTP)
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await _apiService.post(
        '/carRental/request-reset',
        body: {'email': email},
      );
      
      return response != null;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AuthException('Failed to send OTP: ${e.toString()}');
    }
  }
  
  // Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final response = await _apiService.post(
        '/carRental/verify-otp',
        body: {
          'email': email,
          'otp': otp,
        },
      );
      
      return response == true;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AuthException('Failed to verify OTP: ${e.toString()}');
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final response = await _apiService.post(
        '/carRental/reset-password',
        body: {
          'email': email,
          'newPassword': newPassword,
        },
      );
      
      return response != null;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AuthException('Failed to reset password: ${e.toString()}');
    }
  }
  
  // Save remember me preference
  Future<void> saveRememberMe(bool remember, String mobile) async {
    await StorageService.setBool(AppConstants.keyRememberMe, remember);
    if (remember) {
      await StorageService.setString(AppConstants.keySavedMobile, mobile);
    } else {
      await StorageService.remove(AppConstants.keySavedMobile);
    }
  }
  
  // Get remember me preference
  bool getRememberMe() {
    return StorageService.getBool(AppConstants.keyRememberMe);
  }
  
  // Get saved mobile number
  String getSavedMobile() {
    return StorageService.getString(AppConstants.keySavedMobile);
  }
  
  // User logout
  Future<void> logout() async {
    final rememberMe = StorageService.getBool(AppConstants.keyRememberMe);
    final savedMobile = StorageService.getString(AppConstants.keySavedMobile);
    
    // Clear all stored data
    await StorageService.clear();
    
    // Restore remember me settings if needed
    if (rememberMe) {
      await StorageService.setBool(AppConstants.keyRememberMe, true);
      await StorageService.setString(AppConstants.keySavedMobile, savedMobile);
    }
  }
}

class AuthException extends AppException {
  AuthException(String message) : super(message, "Authentication Error");
} 
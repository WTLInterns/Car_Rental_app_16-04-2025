import 'package:flutter/foundation.dart';

import '../../../core/network/api_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/app_exception.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final ApiService _apiService;

  ProfileRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get user profile by user ID
  Future<Profile> getUserProfile(String userId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/profiles/$userId',
      );

      return Profile.fromJson(response['profile']);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user profile: $e');
      }
      throw AppException(
        'Failed to load profile information. Please try again.',
        e.toString(),
      );
    }
  }

  /// Update user profile
  Future<Profile> updateProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/profiles/$userId',
        body: profileData,
      );

      return Profile.fromJson(response['profile']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      throw AppException(
        'Failed to update profile. Please try again.',
        e.toString(),
      );
    }
  }

  /// Update profile picture
  Future<Profile> updateProfilePicture(String userId, String imageUrl) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/profiles/$userId/picture',
        body: {'profile_image': imageUrl},
      );

      return Profile.fromJson(response['profile']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile picture: $e');
      }
      throw AppException(
        'Failed to update profile picture. Please try again.',
        e.toString(),
      );
    }
  }

  /// Update driver duty status (for drivers only)
  Future<Profile> updateDriverDutyStatus(String userId, bool isOnDuty) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/profiles/$userId/duty-status',
        body: {'is_on_duty': isOnDuty},
      );

      return Profile.fromJson(response['profile']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating driver duty status: $e');
      }
      throw AppException(
        'Failed to update duty status. Please try again.',
        e.toString(),
      );
    }
  }

  /// Add emergency contact
  Future<Profile> addEmergencyContact(
    String userId,
    EmergencyContact contact,
  ) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.apiBaseUrl}/api/profiles/$userId/emergency-contacts',
        body: contact.toJson(),
      );

      return Profile.fromJson(response['profile']);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding emergency contact: $e');
      }
      throw AppException(
        'Failed to add emergency contact. Please try again.',
        e.toString(),
      );
    }
  }

  /// Update user preferences
  Future<Profile> updatePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/profiles/$userId/preferences',
        body: {'preferences': preferences},
      );

      return Profile.fromJson(response['profile']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating preferences: $e');
      }
      throw AppException(
        'Failed to update preferences. Please try again.',
        e.toString(),
      );
    }
  }
} 
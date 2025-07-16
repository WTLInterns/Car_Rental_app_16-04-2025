import 'package:flutter/foundation.dart';

import '../../../core/network/api_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/app_exception.dart';
import '../models/driver_model.dart';

class DriverRepository {
  final ApiService _apiService;

  DriverRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get driver by ID
  Future<Driver> getDriver(String driverId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/drivers/$driverId',
      );

      return Driver.fromJson(response['driver']);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching driver: $e');
      }
      throw AppException(
        'Failed to load driver information. Please try again.',
        e.toString(),
      );
    }
  }

  /// Update driver duty status
  Future<Driver> updateDutyStatus(String driverId, bool isOnDuty) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/drivers/$driverId/duty-status',
        body: {'is_on_duty': isOnDuty},
      );

      return Driver.fromJson(response['driver']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating duty status: $e');
      }
      throw AppException(
        'Failed to update duty status. Please try again.',
        e.toString(),
      );
    }
  }

  /// Update vehicle information
  Future<Driver> updateVehicleInfo(
    String driverId,
    Map<String, dynamic> vehicleInfo,
  ) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.apiBaseUrl}/api/drivers/$driverId/vehicle',
        body: vehicleInfo,
      );

      return Driver.fromJson(response['driver']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating vehicle info: $e');
      }
      throw AppException(
        'Failed to update vehicle information. Please try again.',
        e.toString(),
      );
    }
  }

  /// Get driver statistics
  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.apiBaseUrl}/api/drivers/$driverId/stats',
      );

      return response['stats'];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching driver stats: $e');
      }
      throw AppException(
        'Failed to load driver statistics. Please try again.',
        e.toString(),
      );
    }
  }
} 
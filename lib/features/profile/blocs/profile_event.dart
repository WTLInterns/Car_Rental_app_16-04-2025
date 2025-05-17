import 'package:equatable/equatable.dart';

import '../models/profile_model.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  final String userId;

  const LoadProfileEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UpdateProfileEvent extends ProfileEvent {
  final String userId;
  final Map<String, dynamic> profileData;

  const UpdateProfileEvent({
    required this.userId,
    required this.profileData,
  });

  @override
  List<Object> get props => [userId, profileData];
}

class UpdateProfilePictureEvent extends ProfileEvent {
  final String userId;
  final String imageUrl;

  const UpdateProfilePictureEvent({
    required this.userId,
    required this.imageUrl,
  });

  @override
  List<Object> get props => [userId, imageUrl];
}

class UpdateDriverDutyStatusEvent extends ProfileEvent {
  final String userId;
  final bool isOnDuty;

  const UpdateDriverDutyStatusEvent({
    required this.userId,
    required this.isOnDuty,
  });

  @override
  List<Object> get props => [userId, isOnDuty];
}

class AddEmergencyContactEvent extends ProfileEvent {
  final String userId;
  final EmergencyContact contact;

  const AddEmergencyContactEvent({
    required this.userId,
    required this.contact,
  });

  @override
  List<Object> get props => [userId, contact];
}

class UpdatePreferencesEvent extends ProfileEvent {
  final String userId;
  final Map<String, dynamic> preferences;

  const UpdatePreferencesEvent({
    required this.userId,
    required this.preferences,
  });

  @override
  List<Object> get props => [userId, preferences];
}

class ResetProfileEvent extends ProfileEvent {} 
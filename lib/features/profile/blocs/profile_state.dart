import 'package:equatable/equatable.dart';

import '../models/profile_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Profile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object> get props => [profile];
}

class ProfileUpdated extends ProfileState {
  final Profile profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object> get props => [profile];
}

class ProfilePictureUpdated extends ProfileState {
  final Profile profile;

  const ProfilePictureUpdated(this.profile);

  @override
  List<Object> get props => [profile];
}

class DriverDutyStatusUpdated extends ProfileState {
  final Profile profile;
  final bool isOnDuty;

  const DriverDutyStatusUpdated(this.profile, this.isOnDuty);

  @override
  List<Object> get props => [profile, isOnDuty];
}

class EmergencyContactAdded extends ProfileState {
  final Profile profile;

  const EmergencyContactAdded(this.profile);

  @override
  List<Object> get props => [profile];
}

class PreferencesUpdated extends ProfileState {
  final Profile profile;

  const PreferencesUpdated(this.profile);

  @override
  List<Object> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
} 
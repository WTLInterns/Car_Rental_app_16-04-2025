import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateProfilePictureEvent>(_onUpdateProfilePicture);
    on<UpdateDriverDutyStatusEvent>(_onUpdateDriverDutyStatus);
    on<AddEmergencyContactEvent>(_onAddEmergencyContact);
    on<UpdatePreferencesEvent>(_onUpdatePreferences);
    on<ResetProfileEvent>(_onResetProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      
      final profile = await _profileRepository.getUserProfile(event.userId);
      
      emit(ProfileLoaded(profile));
    } catch (error) {
      emit(ProfileError(error.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      
      final profile = await _profileRepository.updateProfile(
        event.userId,
        event.profileData,
      );
      
      emit(ProfileUpdated(profile));
    } catch (error) {
      emit(ProfileError(error.toString()));
    }
  }

  Future<void> _onUpdateProfilePicture(
    UpdateProfilePictureEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      
      final profile = await _profileRepository.updateProfilePicture(
        event.userId,
        event.imageUrl,
      );
      
      emit(ProfilePictureUpdated(profile));
    } catch (error) {
      emit(ProfileError(error.toString()));
    }
  }

  Future<void> _onUpdateDriverDutyStatus(
    UpdateDriverDutyStatusEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      
      final profile = await _profileRepository.updateDriverDutyStatus(
        event.userId,
        event.isOnDuty,
      );
      
      emit(DriverDutyStatusUpdated(profile, event.isOnDuty));
    } catch (error) {
      emit(ProfileError(error.toString()));
    }
  }

  Future<void> _onAddEmergencyContact(
    AddEmergencyContactEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      
      final profile = await _profileRepository.addEmergencyContact(
        event.userId,
        event.contact,
      );
      
      emit(EmergencyContactAdded(profile));
    } catch (error) {
      emit(ProfileError(error.toString()));
    }
  }

  Future<void> _onUpdatePreferences(
    UpdatePreferencesEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      
      final profile = await _profileRepository.updatePreferences(
        event.userId,
        event.preferences,
      );
      
      emit(PreferencesUpdated(profile));
    } catch (error) {
      emit(ProfileError(error.toString()));
    }
  }

  void _onResetProfile(
    ResetProfileEvent event,
    Emitter<ProfileState> emit,
  ) {
    emit(ProfileInitial());
  }
} 
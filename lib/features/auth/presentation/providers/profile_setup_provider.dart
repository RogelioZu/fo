import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// Estado acumulado durante los 6 pasos del profile setup.
class ProfileSetupState {
  final String? firstName;
  final String? lastName;
  final String? username;
  final DateTime? birthday;
  final String? city;
  final String? country;
  final double? lat;
  final double? lng;
  final List<String> interests;
  final String? avatarPath;

  const ProfileSetupState({
    this.firstName,
    this.lastName,
    this.username,
    this.birthday,
    this.city,
    this.country,
    this.lat,
    this.lng,
    this.interests = const [],
    this.avatarPath,
  });

  ProfileSetupState copyWith({
    String? firstName,
    String? lastName,
    String? username,
    DateTime? birthday,
    String? city,
    String? country,
    double? lat,
    double? lng,
    List<String>? interests,
    String? avatarPath,
  }) {
    return ProfileSetupState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      birthday: birthday ?? this.birthday,
      city: city ?? this.city,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      interests: interests ?? this.interests,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

/// Notifier que acumula datos del profile setup y los envía a Supabase.
class ProfileSetupNotifier extends StateNotifier<ProfileSetupState> {
  final AuthRepository _repository;

  ProfileSetupNotifier(this._repository) : super(const ProfileSetupState());

  void setName(String firstName, String lastName) {
    state = state.copyWith(firstName: firstName, lastName: lastName);
  }

  void setUsername(String username) {
    state = state.copyWith(username: username);
  }

  void setBirthday(DateTime birthday) {
    state = state.copyWith(birthday: birthday);
  }

  void setLocation({
    required String city,
    required String country,
    double? lat,
    double? lng,
  }) {
    state = state.copyWith(
      city: city,
      country: country,
      lat: lat,
      lng: lng,
    );
  }

  void setInterests(List<String> interests) {
    state = state.copyWith(interests: interests);
  }

  void setAvatarPath(String path) {
    state = state.copyWith(avatarPath: path);
  }

  /// Envía todos los datos acumulados a Supabase y marca el perfil como completo.
  Future<void> submitAll() async {
    try {
      // 1. Actualizar campos del perfil
      await _repository.updateProfile(
        firstName: state.firstName,
        lastName: state.lastName,
        username: state.username,
        birthday: state.birthday,
        city: state.city,
        country: state.country,
        lat: state.lat,
        lng: state.lng,
      );

      // 2. Guardar intereses
      if (state.interests.isNotEmpty) {
        await _repository.saveInterests(state.interests);
      }

      // 3. Subir avatar si existe
      if (state.avatarPath != null) {
        await _repository.uploadAvatar(state.avatarPath!);
      }

      // 4. Marcar perfil como completo
      await _repository.markProfileComplete();
    } catch (e) {
      debugPrint('Error en submitAll: $e');
      rethrow;
    }
  }
}

/// Provider del notifier de profile setup.
final profileSetupProvider =
    StateNotifierProvider<ProfileSetupNotifier, ProfileSetupState>((ref) {
  return ProfileSetupNotifier(ref.read(authRepositoryProvider));
});

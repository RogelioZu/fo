import 'package:equatable/equatable.dart';

/// Entidad principal de usuario de Finding Out.
class AppUser extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final DateTime? birthday;
  final String? city;
  final String? country;
  final double? lat;
  final double? lng;
  final List<String> interests;
  final bool profileComplete;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.birthday,
    this.city,
    this.country,
    this.lat,
    this.lng,
    this.interests = const [],
    this.profileComplete = false,
    required this.createdAt,
  });

  /// Crea una copia con campos modificados.
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    String? avatarUrl,
    DateTime? birthday,
    String? city,
    String? country,
    double? lat,
    double? lng,
    List<String>? interests,
    bool? profileComplete,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthday: birthday ?? this.birthday,
      city: city ?? this.city,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      interests: interests ?? this.interests,
      profileComplete: profileComplete ?? this.profileComplete,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        username,
        avatarUrl,
        birthday,
        city,
        country,
        lat,
        lng,
        interests,
        profileComplete,
        createdAt,
      ];
}

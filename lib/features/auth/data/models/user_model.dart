import '../../domain/entities/app_user.dart';

/// Modelo de datos que serializa/deserializa AppUser desde/hacia JSON de Supabase.
class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
    super.username,
    super.avatarUrl,
    super.birthday,
    super.city,
    super.country,
    super.lat,
    super.lng,
    super.bio,
    super.interests = const [],
    super.profileComplete = false,
    required super.createdAt,
  });

  /// Crea un UserModel desde un Map de Supabase (tabla profiles).
  factory UserModel.fromJson(Map<String, dynamic> json, {String? fallbackEmail}) {
    return UserModel(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? fallbackEmail ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'] as String)
          : null,
      city: json['city'] as String?,
      country: json['country'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      profileComplete: (json['profile_complete'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convierte a Map para enviar a Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'avatar_url': avatarUrl,
      'birthday': birthday?.toIso8601String().split('T').first,
      'city': city,
      'country': country,
      'lat': lat,
      'lng': lng,
      'bio': bio,
      'interests': interests,
      'profile_complete': profileComplete,
    };
  }
}

import 'package:equatable/equatable.dart';

/// Preferencias del usuario de Finding Out.
class UserPreferences extends Equatable {
  final String userId;
  final List<String> interests;
  final String? locale;
  final String? themeMode;

  const UserPreferences({
    required this.userId,
    this.interests = const [],
    this.locale,
    this.themeMode,
  });

  UserPreferences copyWith({
    String? userId,
    List<String>? interests,
    String? locale,
    String? themeMode,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      interests: interests ?? this.interests,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [userId, interests, locale, themeMode];
}

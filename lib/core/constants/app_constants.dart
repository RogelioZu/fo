/// Constantes globales de Finding Out.
class AppConstants {
  AppConstants._();

  /// Número mínimo de intereses que el usuario debe seleccionar.
  static const int minInterests = 3;

  /// Edad mínima permitida (años).
  static const int minAge = 13;

  /// Duración del debounce para validar username (ms).
  static const int usernameDebounceMs = 500;

  /// Duración del timer de reenvío de OTP (segundos).
  static const int otpResendTimerSec = 20;

  /// Número de dígitos del código OTP.
  static const int otpLength = 4;

  /// Categorías de intereses con su ícono Phosphor.
  static const List<Map<String, String>> interestCategories = [
    {'id': 'music', 'name': 'Music', 'icon': 'musicNote'},
    {'id': 'sports', 'name': 'Sports', 'icon': 'soccerBall'},
    {'id': 'art', 'name': 'Art', 'icon': 'paintBrush'},
    {'id': 'food_drinks', 'name': 'Food & Drinks', 'icon': 'forkKnife'},
    {'id': 'tech', 'name': 'Tech', 'icon': 'cpu'},
    {'id': 'teatro', 'name': 'Teatro', 'icon': 'maskHappy'},
    {'id': 'photo', 'name': 'Photo', 'icon': 'camera'},
    {'id': 'gaming', 'name': 'Gaming', 'icon': 'gameController'},
    {'id': 'wellness', 'name': 'Wellness', 'icon': 'tree'},
    {'id': 'travel', 'name': 'Travel', 'icon': 'airplaneTilt'},
    {'id': 'education', 'name': 'Education', 'icon': 'graduationCap'},
    {'id': 'nightlife', 'name': 'Nightlife', 'icon': 'martini'},
    {'id': 'literature', 'name': 'Literature', 'icon': 'bookOpen'},
    {'id': 'politics', 'name': 'Politics', 'icon': 'scales'},
    {'id': 'cinema', 'name': 'Cinema', 'icon': 'filmStrip'},
    {'id': 'fashion', 'name': 'Fashion', 'icon': 'tShirt'},
  ];

  /// Nombre del bucket de Supabase Storage para avatares.
  static const String avatarBucket = 'avatars';

  /// Key de SharedPreferences para onboarding.
  static const String hasSeenOnboardingKey = 'hasSeenOnboarding';
}

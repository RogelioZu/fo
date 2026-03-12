import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../entities/app_user.dart';

/// Contrato del repositorio de autenticación de Finding Out.
abstract class AuthRepository {
  // ─── Auth ───

  /// Stream de cambios de estado de autenticación.
  Stream<AuthState> get authStateChanges;

  /// Inicia sesión con email y contraseña.
  Future<AppUser> signInWithEmail(String email, String password);

  /// Registra un nuevo usuario con email y contraseña.
  Future<AppUser> signUpWithEmail(String email, String password);

  /// Cierra la sesión actual.
  Future<void> signOut();

  /// Inicia sesión con Google OAuth.
  Future<AppUser> signInWithGoogle();

  /// Inicia sesión con Apple Sign In.
  Future<AppUser> signInWithApple();

  /// Envía OTP por SMS al número proporcionado.
  Future<void> signInWithPhone(String phone);

  /// Verifica el código OTP (email o phone).
  Future<AppUser> verifyOtp(String email, String token);

  /// Envía un email para restablecer la contraseña.
  Future<void> sendPasswordReset(String email);

  /// Restablece la contraseña con una nueva.
  Future<void> resetPassword(String newPassword);

  // ─── Profile ───

  /// Obtiene el usuario actual con datos de perfil.
  Future<AppUser> getCurrentUser();

  /// Actualiza campos del perfil.
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    DateTime? birthday,
    String? city,
    String? country,
    double? lat,
    double? lng,
  });

  /// Verifica si un nombre de usuario está disponible.
  Future<bool> isUsernameAvailable(String username);

  /// Guarda las categorías de intereses seleccionadas.
  Future<void> saveInterests(List<String> categoryIds);

  /// Sube la foto de avatar y retorna la URL pública.
  Future<String> uploadAvatar(String filePath);

  /// Marca el perfil como completo.
  Future<void> markProfileComplete();
}

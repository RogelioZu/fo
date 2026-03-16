import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación concreta de AuthRepository.
/// Delega al datasource y propaga las excepciones tipadas.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Stream<AuthState> get authStateChanges => _datasource.authStateChanges;

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _datasource.signInWithEmail(email, password);

  @override
  Future<AppUser> signUpWithEmail(String email, String password) =>
      _datasource.signUpWithEmail(email, password);

  @override
  Future<void> signOut() => _datasource.signOut();

  @override
  Future<AppUser> signInWithGoogle() {
    // TODO: implementar Google Sign-In con google_sign_in package
    throw UnimplementedError('Google Sign-In aún no implementado');
  }

  @override
  Future<AppUser> signInWithApple() {
    // TODO: implementar Apple Sign-In con sign_in_with_apple package
    throw UnimplementedError('Apple Sign-In aún no implementado');
  }

  @override
  Future<void> signInWithPhone(String phone) {
    // TODO: implementar Phone Sign-In
    throw UnimplementedError('Phone Sign-In aún no implementado');
  }

  @override
  Future<AppUser> verifyOtp(String email, String token) =>
      _datasource.verifyOtp(email, token);

  @override
  Future<void> sendPasswordReset(String email) =>
      _datasource.sendPasswordReset(email);

  @override
  Future<void> resetPassword(String newPassword) =>
      _datasource.resetPassword(newPassword);

  @override
  Future<AppUser> getCurrentUser() => _datasource.getCurrentUser();

  @override
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    DateTime? birthday,
    String? city,
    String? country,
    double? lat,
    double? lng,
    String? bio,
  }) =>
      _datasource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        birthday: birthday,
        city: city,
        country: country,
        lat: lat,
        lng: lng,
        bio: bio,
      );

  @override
  Future<bool> isUsernameAvailable(String username) =>
      _datasource.isUsernameAvailable(username);

  @override
  Future<void> saveInterests(List<String> categoryIds) =>
      _datasource.saveInterests(categoryIds);

  @override
  Future<String> uploadAvatar(String filePath) =>
      _datasource.uploadAvatar(filePath);

  @override
  Future<void> markProfileComplete() => _datasource.markProfileComplete();
}

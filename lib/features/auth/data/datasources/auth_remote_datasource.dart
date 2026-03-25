import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../models/user_model.dart';

/// Web Client ID de Google Cloud (tipo "Web application").
/// Supabase lo usa para validar el ID token.
const _googleWebClientId =
    '510255339256-fb3ftcoqj4o18b0gu2sh62sf96l0qum6.apps.googleusercontent.com';

/// Android Client ID de Google Cloud.
const _googleAndroidClientId =
    '510255339256-lh4d958tsr5ue5e2rirancdapdchkv2i.apps.googleusercontent.com';

/// Datasource que interactúa directamente con Supabase Auth y DB.
class AuthRemoteDatasource {
  final SupabaseClient _client;

  AuthRemoteDatasource(this._client);

  // ─── Auth ───

  /// Stream de cambios de estado de autenticación.
  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /// Login con email y contraseña.
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const InvalidCredentialsException();
      }

      return _fetchProfile(response.user!.id, email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Registro con email y contraseña.
  Future<AppUser> signUpWithEmail(String email, String password) async {
    try {
      // Cerrar cualquier sesión previa para evitar conflictos de auth
      if (_client.auth.currentSession != null) {
        await _client.auth.signOut();
      }

      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const UnknownException('Error al crear la cuenta.');
      }

      // Supabase con email confirmation no lanza error si el email ya existe,
      // retorna un usuario sin identidades. Detectar ese caso.
      final identities = response.user!.identities;
      if (identities == null || identities.isEmpty) {
        throw const EmailAlreadyInUseException();
      }

      // El trigger handle_new_user() crea el perfil automáticamente
      return AppUser(
        id: response.user!.id,
        email: email,
        profileComplete: false,
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Login con Google OAuth.
  /// Flujo: GoogleSignIn → ID token → Supabase signInWithIdToken.
  Future<AppUser> signInWithGoogle() async {
    try {
      // 1. Configurar GoogleSignIn con el client ID correcto por plataforma
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? _googleWebClientId : null,
        serverClientId: _googleWebClientId,
        scopes: ['email', 'profile'],
      );

      // 2. Abrir el selector de cuenta de Google
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el login
        throw const UnknownException('Google Sign-In cancelado.');
      }

      // 3. Obtener tokens de autenticación
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const UnknownException('No se pudo obtener el token de Google.');
      }

      // 4. Pasarle el token a Supabase para crear/vincular la sesión
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        throw const UnknownException('Error al autenticar con Google.');
      }

      // 5. Obtener perfil (el trigger puede haberlo creado)
      return _fetchProfile(
        response.user!.id,
        response.user!.email ?? googleUser.email,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Login con Apple Sign-In.
  /// Flujo: SignInWithApple → nonce + ID token → Supabase signInWithIdToken.
  ///
  /// Requiere Apple Developer Account con Sign in with Apple configurado.
  /// Funciona en iOS 13+ y macOS 10.15+.
  Future<AppUser> signInWithApple() async {
    try {
      // 1. Generar nonce criptográfico (requerido por Apple + Supabase)
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // 2. Solicitar credenciales de Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw const UnknownException('No se pudo obtener el token de Apple.');
      }

      // 3. Autenticar con Supabase usando el token de Apple
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (response.user == null) {
        throw const UnknownException('Error al autenticar con Apple.');
      }

      return _fetchProfile(
        response.user!.id,
        response.user!.email ?? '',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const UnknownException('Apple Sign-In cancelado.');
      }
      throw UnknownException('Apple Sign-In error: ${e.message}');
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Genera un nonce criptográficamente seguro para Apple Sign-In.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Cerrar sesión.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Verificar OTP (signup confirmation).
  Future<AppUser> verifyOtp(String email, String token) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );

      if (response.user == null) {
        throw const InvalidOtpException();
      }

      return _fetchProfile(response.user!.id, email);
    } on AuthException catch (e) {
      if (e.message.contains('expired')) {
        throw const OtpExpiredException();
      }
      throw const InvalidOtpException();
    }
  }

  /// Enviar email para resetear contraseña.
  /// El redirectTo apunta al deep link de la app para que el magic link
  /// abra directamente la aplicación.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.example.fo://reset-callback',
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Resetear contraseña.
  Future<void> resetPassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  // ─── Profile ───

  /// Obtener el usuario actual con datos del perfil.
  Future<AppUser> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const InvalidCredentialsException();
    }
    return _fetchProfile(user.id, user.email ?? '');
  }

  /// Actualizar campos del perfil.
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
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const InvalidCredentialsException();

    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (username != null) updates['username'] = username;
    if (birthday != null) updates['birthday'] = birthday.toIso8601String().split('T').first;
    if (city != null) updates['city'] = city;
    if (country != null) updates['country'] = country;
    if (lat != null) updates['lat'] = lat;
    if (lng != null) updates['lng'] = lng;
    if (bio != null) updates['bio'] = bio;

    if (updates.isEmpty) return;

    try {
      await _client.from('profiles').update(updates).eq('id', userId);
    } on PostgrestException catch (e) {
      debugPrint('Error updating profile: ${e.message}');
      throw UnknownException(e.message);
    }
  }

  /// Verificar disponibilidad de username.
  Future<bool> isUsernameAvailable(String username) async {
    final result = await _client
        .from('profiles')
        .select('id')
        .eq('username', username.toLowerCase())
        .maybeSingle();
    return result == null;
  }

  /// Guardar intereses seleccionados.
  Future<void> saveInterests(List<String> categoryIds) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const InvalidCredentialsException();

    await _client
        .from('profiles')
        .update({'interests': categoryIds})
        .eq('id', userId);
  }

  static const _allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Subir avatar y retornar URL pública.
  Future<String> uploadAvatar(String filePath) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const InvalidCredentialsException();

    final fileExt = filePath.split('.').last.toLowerCase();
    if (!_allowedImageExtensions.contains(fileExt)) {
      throw const UnknownException('Formato de imagen no soportado. Usa JPG, PNG o WEBP.');
    }
    final path = '$userId/avatar.$fileExt';
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    final baseUrl = _client.storage.from('avatars').getPublicUrl(path);
    // Cache-buster para que CachedNetworkImage detecte el cambio
    final publicUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

    // Guardar URL en el perfil
    await _client
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', userId);

    return publicUrl;
  }

  /// Marcar perfil como completo.
  Future<void> markProfileComplete() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const InvalidCredentialsException();

    await _client
        .from('profiles')
        .update({'profile_complete': true})
        .eq('id', userId);
  }

  // ─── Helpers ───

  /// Obtiene el perfil del usuario desde la tabla profiles.
  Future<AppUser> _fetchProfile(String userId, String email) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        // Perfil aún no creado (el trigger puede tardar), retornar básico
        return AppUser(
          id: userId,
          email: email,
          profileComplete: false,
          createdAt: DateTime.now(),
        );
      }

      return UserModel.fromJson(data, fallbackEmail: email);
    } on PostgrestException catch (e) {
      debugPrint('Error fetching profile: ${e.message}');
      throw const ProfileNotFoundException();
    }
  }

  /// Mapea AuthException de Supabase a excepciones tipadas.
  AppException _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    debugPrint('AuthException: statusCode=${e.statusCode}');

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return const InvalidCredentialsException();
    }
    if (msg.contains('email not confirmed')) {
      return const EmailNotVerifiedException();
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return const EmailAlreadyInUseException();
    }
    if (msg.contains('weak password') || msg.contains('too short')) {
      return const WeakPasswordException();
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return const RateLimitException();
    }
    return UnknownException(e.message);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── Core Providers ───

/// Provider del cliente de Supabase.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider del datasource de autenticación.
final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.read(supabaseClientProvider));
});

/// Provider del repositorio de autenticación.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authDatasourceProvider));
});

// ─── Auth State ───

/// Stream de cambios de estado de autenticación.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

/// Provider del usuario actual (con datos de perfil).
/// Escucha authStateProvider para invalidarse automáticamente
/// cuando cambia la sesión (login, logout, signup, etc.).
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  // Watchear el estado de auth para re-evaluar cuando cambie la sesión
  ref.watch(authStateProvider);

  final client = ref.read(supabaseClientProvider);
  if (client.auth.currentUser == null) return null;
  return ref.read(authRepositoryProvider).getCurrentUser();
});

/// Provider para obtener el perfil público de un usuario por su ID.
final publicProfileProvider = FutureProvider.family<AppUser?, String>((ref, userId) async {
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();
  if (data == null) return null;
  return UserModel.fromJson(data);
});

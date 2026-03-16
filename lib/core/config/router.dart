import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/profile_setup/setup_name_screen.dart';
import '../../features/auth/presentation/screens/profile_setup/setup_username_screen.dart';
import '../../features/auth/presentation/screens/profile_setup/setup_birthday_screen.dart';
import '../../features/auth/presentation/screens/profile_setup/setup_location_screen.dart';
import '../../features/auth/presentation/screens/profile_setup/setup_interests_screen.dart';
import '../../features/auth/presentation/screens/profile_setup/setup_photo_screen.dart';
import '../../features/home/presentation/screens/main_shell.dart';
import '../../features/home/presentation/screens/edit_profile_screen.dart';

import '../constants/app_constants.dart';

/// Configuración del enrutador de Finding Out.
/// Contiene todas las rutas y la lógica de redirección según auth state.
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Cache del estado de profile_complete para evitar queries repetidas.
  static bool? _cachedProfileComplete;

  /// Crea el GoRouter con lógica de redirect.
  static GoRouter router(SharedPreferences prefs) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      routes: _routes,
      redirect: (context, state) => _redirect(state, prefs),
      errorBuilder: (context, state) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ruta no encontrada: ${state.uri.path}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/splash'),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Invalida el cache de profile_complete (llamar tras completar el setup).
  static void invalidateProfileCache() {
    _cachedProfileComplete = null;
  }

  // ─── Rutas ───

  static final List<RouteBase> _routes = [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'verify-email',
      builder: (context, state) => VerifyEmailScreen(
        email: state.uri.queryParameters['email'] ?? '',
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/setup/name',
      name: 'setup-name',
      builder: (context, state) => const SetupNameScreen(),
    ),
    GoRoute(
      path: '/setup/username',
      name: 'setup-username',
      builder: (context, state) => const SetupUsernameScreen(),
    ),
    GoRoute(
      path: '/setup/birthday',
      name: 'setup-birthday',
      builder: (context, state) => const SetupBirthdayScreen(),
    ),
    GoRoute(
      path: '/setup/location',
      name: 'setup-location',
      builder: (context, state) => const SetupLocationScreen(),
    ),
    GoRoute(
      path: '/setup/interests',
      name: 'setup-interests',
      builder: (context, state) => const SetupInterestsScreen(),
    ),
    GoRoute(
      path: '/setup/photo',
      name: 'setup-photo',
      builder: (context, state) => const SetupPhotoScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
  ];

  // ─── Redirect Logic ───

  static const _authRoutes = [
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/verify-email',
  ];

  static const _setupRoutes = [
    '/setup/name',
    '/setup/username',
    '/setup/birthday',
    '/setup/location',
    '/setup/interests',
    '/setup/photo',
  ];

  static Future<String?> _redirect(
      GoRouterState state, SharedPreferences prefs) async {
    final currentPath = state.uri.path;
    final session = Supabase.instance.client.auth.currentSession;
    final hasSeenOnboarding =
        prefs.getBool(AppConstants.hasSeenOnboardingKey) ?? false;

    final isOnSplash = currentPath == '/splash';
    final isOnOnboarding = currentPath == '/onboarding';
    final isOnAuthRoute = _authRoutes.contains(currentPath);
    final isOnSetupRoute = _setupRoutes.contains(currentPath);

    // 1. Si no ha visto onboarding Y no tiene sesión → mandarlo ahí
    //    (si ya tiene sesión, no necesita onboarding)
    if (!hasSeenOnboarding &&
        session == null &&
        !isOnOnboarding &&
        !isOnSplash &&
        !isOnAuthRoute) {
      return '/onboarding';
    }

    // 2. Si no hay sesión y está en ruta protegida → login
    if (session == null && !isOnAuthRoute && !isOnOnboarding && !isOnSplash) {
      return '/login';
    }

    // 3. Si hay sesión y está en ruta de auth, splash u onboarding → verificar perfil
    //    Excepción: /verify-email debe ser accesible con sesión (email aún no confirmado)
    if (session != null &&
        (isOnAuthRoute || isOnSplash || isOnOnboarding) &&
        currentPath != '/verify-email') {
      final profileComplete = await _isProfileComplete();
      if (profileComplete) {
        return '/home';
      } else {
        return '/setup/name';
      }
    }

    // 4. Si hay sesión, perfil no completo, y está en /home → mandarlo a setup
    if (session != null && !isOnSetupRoute && currentPath == '/home') {
      final profileComplete = await _isProfileComplete();
      if (!profileComplete) {
        return '/setup/name';
      }
    }

    return null; // Sin redirect
  }

  /// Verifica si el perfil del usuario actual está completo.
  static Future<bool> _isProfileComplete() async {
    // Usar cache si existe
    if (_cachedProfileComplete != null) return _cachedProfileComplete!;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('profile_complete')
          .eq('id', userId)
          .maybeSingle();

      _cachedProfileComplete = (data?['profile_complete'] as bool?) ?? false;
      return _cachedProfileComplete!;
    } catch (e) {
      debugPrint('Error checking profile_complete: $e');
      return false;
    }
  }
}

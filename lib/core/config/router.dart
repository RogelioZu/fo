import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
// TODO: importar pantallas conforme se vayan creando
// import '../../features/auth/presentation/screens/onboarding_screen.dart';
// import '../../features/auth/presentation/screens/login_screen.dart';
// import '../../features/auth/presentation/screens/register_screen.dart';
// import '../../features/auth/presentation/screens/verify_email_screen.dart';
// import '../../features/auth/presentation/screens/forgot_password_screen.dart';
// import '../../features/auth/presentation/screens/reset_password_screen.dart';
// import '../../features/auth/presentation/screens/profile_setup/setup_name_screen.dart';
// import '../../features/auth/presentation/screens/profile_setup/setup_username_screen.dart';
// import '../../features/auth/presentation/screens/profile_setup/setup_birthday_screen.dart';
// import '../../features/auth/presentation/screens/profile_setup/setup_location_screen.dart';
// import '../../features/auth/presentation/screens/profile_setup/setup_interests_screen.dart';
// import '../../features/auth/presentation/screens/profile_setup/setup_photo_screen.dart';

import '../constants/app_constants.dart';

/// Configuración del enrutador de Finding Out.
/// Contiene todas las rutas y la lógica de redirección según auth state.
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Crea el GoRouter con lógica de redirect.
  static GoRouter router(SharedPreferences prefs) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      routes: _routes,
      redirect: (context, state) => _redirect(state, prefs),
    );
  }

  // ─── Rutas ───

  static final List<RouteBase> _routes = [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    // TODO: descomentar rutas conforme se creen las pantallas
    /*
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
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Home — TODO')),
      ),
    ),
    */
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

  static String? _redirect(GoRouterState state, SharedPreferences prefs) {
    final currentPath = state.uri.path;
    final session = Supabase.instance.client.auth.currentSession;
    final hasSeenOnboarding =
        prefs.getBool(AppConstants.hasSeenOnboardingKey) ?? false;

    final isOnSplash = currentPath == '/splash';
    final isOnOnboarding = currentPath == '/onboarding';
    final isOnAuthRoute = _authRoutes.contains(currentPath);
    // ignore: unused_local_variable
    final isOnSetupRoute = _setupRoutes.contains(currentPath);

    // 1. Si no ha visto onboarding → mandarlo ahí
    if (!hasSeenOnboarding && !isOnOnboarding && !isOnSplash) {
      return '/onboarding';
    }

    // 2. Si no hay sesión y está en ruta protegida → login
    if (session == null && !isOnAuthRoute && !isOnOnboarding && !isOnSplash) {
      return '/login';
    }

    // 3. Si hay sesión y está en ruta de auth → verificar perfil
    if (session != null && (isOnAuthRoute || isOnSplash || isOnOnboarding)) {
      // TODO: verificar profile_complete desde Supabase
      // Por ahora redirige a /home
      return '/home';
    }

    return null; // Sin redirect
  }
}

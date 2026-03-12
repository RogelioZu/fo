# Finding Out — Plan de Implementación Completo

## Contexto

Reinicio del módulo Auth + Onboarding de Finding Out con Clean Architecture. La base de datos Supabase ya existe de una versión anterior. Las screens están diseñadas en `designs/pencil/login.pen` (15 pantallas).

**Stack**: Flutter + Supabase + Riverpod + GoRouter
**Diseño**: Minimalista B&W, Inter font, bordes redondeados (cornerRadius: 16-100), iconos Lucide/Phosphor

---

## Screens del Diseño (login.pen)

| # | Screen | ID | Elementos clave del diseño |
|---|--------|----|---------------------------|
| 1 | **Splash** | `IAMJa` | Ícono sparkles, "Explore the app", botones Sign in + Create account |
| 2 | **Onboarding 1** | `0GkQF` | "Discover Events Near You", PageView dots, Next + Skip |
| 3 | **Onboarding 2** | `SzFBb` | "Connect With People", PageView dots, Next + Skip |
| 4 | **Onboarding 3** | `FWio8` | "Personalize Your Experience", Get Started (sin Skip) |
| 5 | **Login** | `RT64G` | Email + Password (labeled inputs), Login btn negro, divider "Or Log in with", 3 social buttons (Google, Apple, Phone), footer "Sign up" |
| 6 | **Register** | `LxKqO` | Email + Create password + Confirm password, eye toggle, footer "Log in" |
| 7 | **Verify Email** | `0rGb3` | "Please check your email", 4-digit code boxes, Verify btn, "Send code again 00:20" timer |
| 8 | **Forgot Password** | `l1Nra` | Email input, "Send code" btn |
| 9 | **Reset Password** | `Rduuy` | New password + Confirm, eye toggles, "Reset Password" btn |
| 10 | **Setup Name** | `4unKf` | Step 1/6, progress bar, First + Last name inputs |
| 11 | **Setup Username** | `3hpye` | Step 2/6, @username input, real-time validation checkmark |
| 12 | **Setup Birthday** | `xzvWp` | Step 3/6, Month/Day/Year dropdowns |
| 13 | **Setup Location** | `z2qVf` | Step 4/6, GPS button + manual search input |
| 14 | **Setup Interests** | `eYJrO` | Step 5/6, 16 chip categories (Music, Sports, Art, Food & Drinks, Tech, Teatro, Photo, Gaming, Wellness, Travel, Education, Nightlife, Literature, Politics, Cinema, Fashion), counter "4 of 16 selected (minimum 3)" |
| 15 | **Setup Photo** | `j417q` | Step 6/6, avatar circle dashed, Camera + Gallery btns, "Complete Setup" + "Skip for now" |

---

## Decisiones de Arquitectura

| Tema | Decisión | Razón |
|------|----------|-------|
| Social Login | Google + Apple + Phone (Supabase Auth) | Cobertura completa iOS/Android |
| Verificación email | **OTP code de 4 dígitos** (según diseño) | El diseño muestra 4 cajas de código, no magic link |
| Phone auth | Botón en Login (social button #3) | Supabase Phone OTP |
| Onboarding storage | `SharedPreferences` flag `hasSeenOnboarding` | Persistir entre sesiones |
| Profile completeness | Campo `profile_complete` en tabla `profiles` | Router redirect check |
| Username uniqueness | RPC function o query `.eq('username', value)` con debounce 500ms | Validación real-time |
| Interests | Tabla `user_interests` (user_id, category_id) | Relación many-to-many |
| Photo upload | Supabase Storage bucket `avatars` | Ya existente de versión anterior |
| Location | `geolocator` GPS + texto manual como fallback | Según diseño |

---

## Fase 0: Setup del Proyecto (Foundation)

### 0.1 — Dependencias (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  # Navigation
  go_router: ^14.8.1
  # Backend
  supabase_flutter: ^2.8.4
  # Social Auth
  google_sign_in: ^6.2.2
  sign_in_with_apple: ^6.1.4
  crypto: ^3.0.6              # Para nonce de Apple Sign In
  # UI
  google_fonts: ^6.2.1
  phosphor_flutter: ^2.1.0
  flutter_animate: ^4.5.2
  cached_network_image: ^3.4.1
  # Utilities
  image_picker: ^1.1.2
  geolocator: ^13.0.2
  geocoding: ^3.0.0
  permission_handler: ^11.3.1
  equatable: ^2.0.7
  intl: ^0.19.0
  shared_preferences: ^2.3.5
  # Internationalization
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.14
  custom_lint: ^0.7.5
  riverpod_lint: ^2.6.3
```

### 0.2 — Estructura de Carpetas

```
lib/
├── main.dart                          # Entry point, ProviderScope, Supabase.init
├── app.dart                           # MaterialApp.router con tema + GoRouter
├── l10n/
│   ├── app_en.arb                     # English strings
│   └── app_es.arb                     # Spanish strings
├── core/
│   ├── config/
│   │   ├── env.dart                   # Supabase URL + anon key (from .env)
│   │   └── router.dart                # GoRouter config + auth redirect logic
│   ├── constants/
│   │   └── app_constants.dart         # Categories list, min interests, etc.
│   ├── errors/
│   │   ├── exceptions.dart            # Typed exceptions hierarchy
│   │   └── failures.dart              # Failure sealed class
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData light + dark
│   │   ├── app_colors.dart            # Color tokens
│   │   ├── app_text_styles.dart       # Typography scale (Inter)
│   │   ├── app_spacing.dart           # Spacing tokens
│   │   └── app_radius.dart            # Border radius tokens
│   ├── utils/
│   │   ├── validators.dart            # Email, password, username validators
│   │   └── extensions.dart            # Context extensions
│   └── widgets/
│       ├── fo_button.dart             # Primary button (black, cornerRadius: 100)
│       ├── fo_text_field.dart         # Labeled input (cornerRadius: 16, border #E5E7EB)
│       ├── fo_social_button.dart      # Social login button (outlined, icon + text)
│       ├── fo_icon_button.dart        # Square icon button (56x56)
│       ├── fo_loading.dart            # Loading indicator
│       └── fo_top_nav.dart            # Back arrow + sparkle top navigation
├── features/
│   └── auth/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── auth_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── user_model.dart
│       │   │   └── user_preferences_model.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── app_user.dart
│       │   │   └── user_preferences.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       ├── sign_in_usecase.dart
│       │       ├── sign_up_usecase.dart
│       │       ├── sign_out_usecase.dart
│       │       ├── social_sign_in_usecase.dart
│       │       ├── verify_otp_usecase.dart
│       │       ├── forgot_password_usecase.dart
│       │       ├── reset_password_usecase.dart
│       │       ├── update_profile_usecase.dart
│       │       ├── check_username_usecase.dart
│       │       └── save_preferences_usecase.dart
│       └── presentation/
│           ├── providers/
│           │   ├── auth_provider.dart          # Auth state + session
│           │   ├── onboarding_provider.dart    # Onboarding page state
│           │   └── profile_setup_provider.dart  # Setup wizard state
│           ├── screens/
│           │   ├── splash_screen.dart
│           │   ├── onboarding_screen.dart       # PageView con 3 pages
│           │   ├── login_screen.dart
│           │   ├── register_screen.dart
│           │   ├── verify_email_screen.dart
│           │   ├── forgot_password_screen.dart
│           │   ├── reset_password_screen.dart
│           │   └── profile_setup/
│           │       ├── setup_name_screen.dart
│           │       ├── setup_username_screen.dart
│           │       ├── setup_birthday_screen.dart
│           │       ├── setup_location_screen.dart
│           │       ├── setup_interests_screen.dart
│           │       └── setup_photo_screen.dart
│           └── widgets/
│               ├── social_login_row.dart        # 3 social buttons row
│               ├── onboarding_page.dart         # Single onboarding slide
│               ├── interest_chip.dart           # Category chip (selected/unselected)
│               ├── password_strength_indicator.dart
│               ├── otp_input.dart               # 4-digit code boxes
│               ├── progress_bar.dart            # Step X of 6 + bar
│               └── date_selector.dart           # Month/Day/Year dropdowns
```

### 0.3 — Variables de Entorno (`.env`)

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
```

> **PENDIENTE**: El usuario debe proporcionar estas credenciales.

---

## Fase 1: Core — Theme + Widgets Base

**Objetivo**: Tener el sistema de diseño en código, listo para construir screens.

### 1.1 — Theme System (extraído del diseño)

**Colores** (del login.pen):
```dart
// Primarios
static const black = Color(0xFF000000);       // Botones, texto principal
static const white = Color(0xFFFFFFFF);       // Fondos
// Grises
static const gray50 = Color(0xFFF9FAFB);     // Fondos sutiles
static const gray100 = Color(0xFFF3F4F6);    // Dividers, líneas
static const gray200 = Color(0xFFE5E7EB);    // Borders inputs (#E5E7EB)
static const gray400 = Color(0xFF9CA3AF);     // Placeholder icons (#9CA3AF)
static const gray500 = Color(0xFF6B7280);     // Texto secundario (#6B7280)
static const gray700 = Color(0xFF333333);     // Labels (#333333)
// Semánticos
static const success = Color(0xFF22C55E);     // Username available
static const error = Color(0xFFEF4444);       // Errores
// Accent (del location screen)
static const accent = Color(0xFFFF005D);      // GPS button, interests counter
static const accentBg = Color(0xFFFFF0F5);    // GPS button background
```

**Tipografía** (Inter via Google Fonts):
```
32px / 800 — Títulos de screen
28px / 900 — Títulos setup screens
24px / 800 — Subtítulos (splash)
16px / 600 — Botones, social text
16px / 400 — Descripciones
14px / 600 — Labels
14px / 500 — Links, steps, resend
14px / 400 — Subtextos
13px / 500 — Counter (interests)
```

**Spacing**:
```
24px — Padding horizontal de screens
60px — Padding top (safe area + espacio)
40px — Padding bottom / padding top setup body
24px — Gap entre elementos principales
16px — Gap entre inputs, gap social buttons
8px — Gap label-to-input, gap interno icon-text
```

**Radius**:
```
100px — Botones primarios (pill shape)
16px  — Inputs, social buttons, code boxes
80px  — Onboarding icon circles
90px  — Avatar circle (setup photo)
28px  — GPS button, interest chips (solo location/interests screen)
```

### 1.2 — Widgets Reutilizables (5 componentes del diseño)

| Widget | Diseño ref | Specs |
|--------|------------|-------|
| **FoButton** | `wOPxM` Button Primary | H:56, fill: black, text: white/16/600, radius: 100, full-width |
| **FoTextField** | `Ulhrf` Input Field | H:56, border: #E5E7EB/1px, radius: 16, icon left + placeholder, padding: 0,16 |
| **FoSocialButton** | `euTh9` Social Button | H:56, border: #E5E7EB/1px, radius: 16, icon + text centered |
| **FoIconButton** | `8Z95Z` Icon Button | 56x56, border: #E5E7EB/1px, radius: 16, icon centered |
| **FoLabeledInput** | `xwslb` Labeled Input | Label text (14/500/#333) + FoTextField, gap: 8 |

### 1.3 — Archivos a crear

```
core/theme/app_colors.dart          → Paleta completa
core/theme/app_text_styles.dart     → Escala tipográfica con Inter
core/theme/app_spacing.dart         → Tokens xs(4) sm(8) md(16) lg(24) xl(32) xxl(60)
core/theme/app_radius.dart          → Tokens pill(100) card(16) circle(80) avatar(90)
core/theme/app_theme.dart           → ThemeData light (dark preparado)
core/widgets/fo_button.dart         → Stateless, onPressed, text, loading state
core/widgets/fo_text_field.dart     → Stateless, icon, hint, obscure, suffix, controller
core/widgets/fo_social_button.dart  → Stateless, icon, label, onTap
core/widgets/fo_icon_button.dart    → Stateless, icon, onTap
core/widgets/fo_top_nav.dart        → Back chevron-left + sparkles icon right
core/widgets/fo_loading.dart        → CircularProgressIndicator themed
```

**Criterio de éxito**: Se puede renderizar cada widget aislado y coincide visualmente con el diseño.

---

## Fase 2: Core — Config + Errors + Utils

### 2.1 — Supabase Config

```dart
// core/config/env.dart
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  runApp(const ProviderScope(child: App()));
}
```

### 2.2 — Error System

```dart
// Sealed class approach
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class InvalidCredentialsException extends AppException { ... }
class EmailNotVerifiedException extends AppException { ... }
class EmailAlreadyInUseException extends AppException { ... }
class WeakPasswordException extends AppException { ... }
class UsernameAlreadyTakenException extends AppException { ... }
class NetworkException extends AppException { ... }
class RateLimitException extends AppException { ... }
// ... etc
```

### 2.3 — Validators

```dart
class Validators {
  static String? email(String? v) → RegExp + null check
  static String? password(String? v) → Min 8 chars, 1 upper, 1 number
  static String? confirmPassword(String? v, String password) → Match check
  static String? name(String? v) → Min 2 chars, letters only
  static String? username(String? v) → 3-20 chars, alphanumeric + underscore
}
```

### 2.4 — GoRouter Config

```dart
// core/config/router.dart
// Rutas:
/splash          → SplashScreen
/onboarding      → OnboardingScreen (PageView)
/login           → LoginScreen
/register        → RegisterScreen
/verify-email    → VerifyEmailScreen
/forgot-password → ForgotPasswordScreen
/reset-password  → ResetPasswordScreen
/setup/name      → SetupNameScreen
/setup/username  → SetupUsernameScreen
/setup/birthday  → SetupBirthdayScreen
/setup/location  → SetupLocationScreen
/setup/interests → SetupInterestsScreen
/setup/photo     → SetupPhotoScreen
/home            → HomeScreen (placeholder)

// Redirect logic:
redirect: (context, state) {
  final session = supabase.auth.currentSession;
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final isOnAuthRoute = ['/login', '/register', ...].contains(state.uri.path);

  if (!hasSeenOnboarding) return '/onboarding';
  if (session == null && !isOnAuthRoute) return '/login';
  if (session != null && isOnAuthRoute) → check profile_complete → '/home' or '/setup/name';
  return null;
}
```

---

## Fase 3: Domain Layer — Entities + Repository Contract

### 3.1 — Entities

```dart
// AppUser
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
  final List<String> interests;    // category IDs
  final bool profileComplete;
  final DateTime createdAt;
}

// UserPreferences
class UserPreferences extends Equatable {
  final String userId;
  final List<String> interests;
  final String? locale;
  final String? themeMode;
}
```

### 3.2 — Repository Contract

```dart
abstract class AuthRepository {
  // Auth
  Stream<AuthState> get authStateChanges;
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(String email, String password);
  Future<void> signOut();
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<void> signInWithPhone(String phone);
  Future<AppUser> verifyOtp(String email, String token);
  Future<void> sendPasswordReset(String email);
  Future<void> resetPassword(String newPassword);

  // Profile
  Future<AppUser> getCurrentUser();
  Future<void> updateProfile({String? firstName, String? lastName, String? username, DateTime? birthday, String? city, String? country, double? lat, double? lng});
  Future<bool> isUsernameAvailable(String username);
  Future<void> saveInterests(List<String> categoryIds);
  Future<String> uploadAvatar(String filePath);
  Future<void> markProfileComplete();
}
```

---

## Fase 4: Data Layer — Supabase Implementation

### 4.1 — Tablas Supabase esperadas (ya existen)

```sql
-- profiles (extends auth.users)
profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  email text,
  display_name text,
  username text UNIQUE,
  avatar_url text,
  birthday date,
  city text,
  country text,
  lat double precision,
  lng double precision,
  profile_complete boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
)

-- user_interests
user_interests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id),
  category_id text,              -- 'music', 'sports', etc.
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, category_id)
)

-- categories (seed data)
categories (
  id text PRIMARY KEY,           -- 'music', 'sports', etc.
  name text,
  icon text,                     -- phosphor icon name
  display_order int
)
```

> **NOTA**: Si las tablas no coinciden exactamente, se ajustarán los models. El usuario confirmará la estructura real.

### 4.2 — Auth Remote Datasource

```dart
class AuthRemoteDatasource {
  final SupabaseClient _client;

  // Auth methods → mapean a Supabase Auth API
  Future<AuthResponse> signInWithEmail(email, password);
  Future<AuthResponse> signUpWithEmail(email, password);
  Future<AuthResponse> signInWithGoogle();   // uses google_sign_in + supabase
  Future<AuthResponse> signInWithApple();    // uses sign_in_with_apple + supabase
  Future<void> signInWithPhone(phone);       // sends OTP via SMS
  Future<AuthResponse> verifyOtp(email, token, type);
  Future<void> sendPasswordReset(email);
  Future<UserResponse> resetPassword(newPassword);
  Future<void> signOut();

  // Profile methods → mapean a Supabase Database
  Future<Map<String, dynamic>> getProfile(userId);
  Future<void> updateProfile(userId, Map<String, dynamic> data);
  Future<bool> isUsernameAvailable(username);
  Future<void> saveInterests(userId, List<String> categoryIds);
  Future<String> uploadAvatar(userId, filePath);  // Storage
}
```

### 4.3 — Models (JSON serialization)

```dart
class UserModel extends AppUser {
  factory UserModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  AppUser toEntity();
}
```

---

## Fase 5: Presentation Layer — Providers (Riverpod)

### 5.1 — Auth Provider

```dart
// Estado
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
}

// Provider
@riverpod
class Auth extends _$Auth {
  // Escucha authStateChanges de Supabase
  // Expone: signIn, signUp, signOut, signInWithGoogle, signInWithApple
  // Maneja loading states y errores tipados
}
```

### 5.2 — Onboarding Provider

```dart
@riverpod
class Onboarding extends _$Onboarding {
  int currentPage = 0;   // 0, 1, 2
  bool hasSeenOnboarding; // SharedPreferences

  void nextPage();
  void skip();            // → marca como visto, navega a login
  void complete();        // → marca como visto, navega a login
}
```

### 5.3 — Profile Setup Provider

```dart
@riverpod
class ProfileSetup extends _$ProfileSetup {
  int currentStep = 1;   // 1-6

  // Step data
  String firstName, lastName;
  String username;
  DateTime? birthday;
  String? city, country;
  double? lat, lng;
  List<String> selectedInterests = [];
  String? avatarPath;

  // Validation
  bool get isUsernameValid;
  bool get hasMinInterests => selectedInterests.length >= 3;

  // Actions
  Future<void> saveName();
  Future<bool> checkUsername(String username);  // debounce 500ms
  Future<void> saveBirthday();
  Future<void> saveLocation();
  Future<void> saveInterests();
  Future<void> uploadPhoto();
  Future<void> skipPhoto();
  Future<void> completeSetup();  // marks profile_complete = true
}
```

---

## Fase 6: Screens — Implementación por pantalla

### 6.1 — Splash Screen (`splash_screen.dart`)

```
Diseño: IAMJa
- Ícono sparkles (lucide, 64px) centrado
- "Explore the app" (24/800)
- Subtexto 2 líneas (14/400, #6B7280)
- Spacer
- "Sign in" button (FoButton negro)
- "Create account" button (FoButton outlined, border #E5E7EB)

Lógica:
- Al iniciar: check SharedPreferences('hasSeenOnboarding')
- Si no ha visto → /onboarding
- Si ya vio → mostrar botones
- "Sign in" → /login
- "Create account" → /register
```

### 6.2 — Onboarding Screen (`onboarding_screen.dart`)

```
Diseño: 0GkQF + SzFBb + FWio8
- PageView con 3 páginas
- Cada página: Ilustración (160px circle, icon grande) + título + descripción
- Page indicators: 3 dots (activo = negro elongado, inactivo = gris)
- Páginas 1-2: "Next" + "Skip"
- Página 3: "Get Started" (sin Skip)

Widget: OnboardingPage(icon, title, description)

Lógica:
- PageController para animación
- Skip → guarda flag, navega a /login
- Get Started → guarda flag, navega a /login
```

### 6.3 — Login Screen (`login_screen.dart`)

```
Diseño: RT64G
Layout (vertical, gap: 24, padding: [60, 24, 40, 24]):
- FoTopNav (back ← + sparkles)
- "Log in" título (32/800)
- FoLabeledInput "Email address" (envelope icon)
- Password group:
  - Label "Password"
  - FoTextField con eye toggle suffix
  - "Forgot password?" link (14/500, alineado derecha)
- FoButton "Log in"
- Divider "Or Log in with"
- Row 3 social buttons: Google (social), Apple (social), Phone (icon 56x56)
- Spacer
- Footer: "Don't have an account?" + "Sign up" (bold)

Lógica:
- Form validation on submit
- Loading state en botón
- Error handling con SnackBar
- Social login: Google → signInWithGoogle, Apple → signInWithApple
- Phone → navega a phone input screen (o bottom sheet)
- "Forgot password?" → /forgot-password
- "Sign up" → /register
```

### 6.4 — Register Screen (`register_screen.dart`)

```
Diseño: LxKqO
Layout (vertical, gap: 24, padding: [60, 24, 40, 24]):
- FoTopNav
- "Sign up" título (32/800)
- FoLabeledInput "Email address"
- FoLabeledInput "Create a password" (eye toggle)
- FoLabeledInput "Confirm password" (eye toggle)
- FoButton "Log in" (texto del diseño, pero semántica = Sign up)
- Spacer
- Footer: "Already have an account?" + "Log in"

Lógica:
- Validación: email, password (min 8, upper, number), confirm match
- signUpWithEmail → on success → /verify-email
- Error: email ya en uso → mostrar error
```

### 6.5 — Verify Email Screen (`verify_email_screen.dart`)

```
Diseño: 0rGb3
Layout (vertical, gap: 24, padding: [60, 24, 40, 24]):
- FoTopNav
- "Please check your email" (32/800, 2 líneas, lineHeight: 1.1)
- "We've sent a code to {email}" (14/400, #6B7280)
- Row de 4 code boxes (64x64, radius: 16, border: #E5E7EB)
  - Cada box muestra 1 dígito, font 28/700
- FoButton "Verify"
- Spacer
- "Send code again 00:20" (timer countdown)

Widget: OtpInput (4 TextFields con FocusNode auto-advance)

Lógica:
- Auto-focus primer box
- Al llenar 4 dígitos → auto-verify
- Timer 20s para resend
- verifyOtp(email, code) → on success → check profile_complete
  - Si profile incompleto → /setup/name
  - Si completo → /home
- Resend → re-send OTP
```

### 6.6 — Forgot Password Screen (`forgot_password_screen.dart`)

```
Diseño: l1Nra
Layout (vertical, gap: 24, padding: [60, 24, 40, 24]):
- FoTopNav
- "Forgot password?" (32/800)
- Descripción 2 líneas (14/400)
- FoLabeledInput "Email address"
- Spacer
- FoButton "Send code"

Lógica:
- Validación email
- sendPasswordReset(email) → navega a /reset-password (o muestra confirmación)
- Manejo de error: email no encontrado
```

### 6.7 — Reset Password Screen (`reset_password_screen.dart`)

```
Diseño: Rduuy
Layout (vertical, gap: 24, padding: [60, 24, 40, 24]):
- FoTopNav
- "Reset password" (32/800)
- "Please type something you'll remember" (14/400)
- FoLabeledInput "New password" (eye toggle)
- FoLabeledInput "Confirm new password" (eye toggle)
- Spacer
- FoButton "Reset Password"

Lógica:
- Validación: password strength + confirm match
- resetPassword(newPassword) → on success → /login con SnackBar éxito
- Se accede via deep link de Supabase (detectado en GoRouter)
```

### 6.8 — Setup Name Screen (`setup_name_screen.dart`)

```
Diseño: 4unKf
Layout (vertical, gap: 0):
- ProgressBar: Step 1/6, barra 67/402px llenada
- Body (vertical, gap: 24, padding: [40, 24, 24, 24]):
  - "What's your name?" (28/900)
  - Descripción (16/400, #6B7280)
  - 2x FoTextField: First name (user icon) + Last name (user icon)
  - Spacer
  - FoButton "Continue"

Widget: ProgressBar(step: 1, total: 6)

Lógica:
- Validación: ambos campos min 2 chars
- Continue → guarda en provider → /setup/username
```

### 6.9 — Setup Username Screen (`setup_username_screen.dart`)

```
Diseño: 3hpye
Layout: igual estructura que Name pero Step 2/6, barra 134/402px
- FoTextField con @icon (phosphor "at")
- Validation row: ✓ icon verde + "Username is available!" (13/500, #22C55E)

Lógica:
- Debounce 500ms en onChange
- checkUsername(value) → query Supabase → mostrar ✓ o ✗
- Continue deshabilitado si username no disponible
- Continue → guarda → /setup/birthday
```

### 6.10 — Setup Birthday Screen (`setup_birthday_screen.dart`)

```
Diseño: xzvWp
Layout: Step 3/6, barra 201/402px
- 3 dropdowns en Row: Month | Day | Year
- Cada dropdown: H:56, border, radius:28, icon caret-down

Widget: DateSelector(onChanged: (DateTime))

Lógica:
- Month: Jan-Dec, Day: 1-31 (dinámico), Year: 1920-actualYear-13
- Validación: edad mínima 13 años
- Continue → guarda → /setup/location
```

### 6.11 — Setup Location Screen (`setup_location_screen.dart`)

```
Diseño: z2qVf
Layout: Step 4/6, barra 268/402px
- GPS button: rosa (#FFF0F5), borde accent (#FF005D), radius: 28, icon crosshair
- Divider "or search manually"
- FoTextField con magnifying-glass icon

Lógica:
- GPS button → pide permiso → geolocator.getCurrentPosition → geocoding reverse
- Search input → debounce → geocoding forward (ciudad/país)
- Continue → guarda lat/lng/city/country → /setup/interests
```

### 6.12 — Setup Interests Screen (`setup_interests_screen.dart`)

```
Diseño: eYJrO
Layout: Step 5/6, barra 335/402px, body gap: 20
- 16 chips en 6 rows (Wrap widget en Flutter)
- Chip seleccionado: fill negro, texto blanco
- Chip no seleccionado: fill blanco, borde negro
- Counter: "4 of 16 selected (minimum 3)" (13/500, #FF005D)

16 categorías con iconos phosphor:
  Music (music-note), Sports (soccer-ball), Art (paint-brush),
  Food & Drinks (fork-knife), Tech (cpu), Teatro (mask-happy),
  Photo (camera), Gaming (game-controller), Wellness (tree),
  Travel (airplane-tilt), Education (graduation-cap), Nightlife (martini),
  Literature (book-open), Politics (scales), Cinema (film-strip),
  Fashion (t-shirt)

Widget: InterestChip(label, icon, selected, onTap)

Lógica:
- Toggle selection on tap
- Continue deshabilitado si < 3 seleccionados
- Continue → saveInterests(selectedIds) → /setup/photo
```

### 6.13 — Setup Photo Screen (`setup_photo_screen.dart`)

```
Diseño: j417q
Layout: Step 6/6, barra 402/402px (completa)
- Avatar circle (180x180, dashed border, #F4F4F5 bg, camera icon)
- "Tap to upload" (14/500, #6B7280)
- Row: Camera btn + Gallery btn (outlined, 56h, radius: 28)
- Spacer
- FoButton "Complete Setup"
- "Skip for now" (14/500, #6B7280, center)

Lógica:
- Tap avatar / Camera → ImagePicker.camera
- Gallery → ImagePicker.gallery
- Preview: mostrar imagen seleccionada en el circle
- "Complete Setup" → uploadAvatar(path) → markProfileComplete() → /home
- "Skip for now" → markProfileComplete() → /home (sin avatar)
```

---

## Fase 7: Integración y Testing

### 7.1 — Auth Flow Completo

```
App Start
  → Splash (check session)
    → No session + no onboarding → Onboarding (3 slides) → Login
    → No session + onboarding seen → Login
    → Session + profile incomplete → Setup Name (resume from last step)
    → Session + profile complete → Home

Login → success → check profile_complete → Home or Setup
Register → Verify Email → OTP → check profile_complete → Home or Setup
Forgot Password → Send code → Reset Password → Login
Setup flow: Name → Username → Birthday → Location → Interests → Photo → Home
```

### 7.2 — Deep Link Handling

```dart
// GoRouter debe detectar:
// - supabase://auth/callback?type=recovery → /reset-password
// - supabase://auth/callback?type=signup → /verify-email (auto-verify)
```

### 7.3 — Checklist de Verificación

- [ ] `flutter analyze` — 0 errores
- [ ] `flutter run` — compila en iOS y Android
- [ ] Splash → Onboarding flow completo
- [ ] Login email/password funcional
- [ ] Login Google funcional
- [ ] Login Apple funcional
- [ ] Register → Verify OTP funcional
- [ ] Forgot → Reset Password funcional
- [ ] Setup wizard 6 pasos completo
- [ ] Username validation real-time
- [ ] GPS location funcional
- [ ] Interests selection (min 3) funcional
- [ ] Photo upload funcional
- [ ] Skip photo funcional
- [ ] Deep link recovery funcional
- [ ] Auth redirect guards correctos
- [ ] Error handling en todos los flows
- [ ] Loading states en todos los botones

---

## Orden de Implementación Recomendado

| Paso | Qué | Archivos | Dependencia |
|------|-----|----------|-------------|
| **1** | pubspec.yaml + flutter pub get | 1 archivo | Ninguna |
| **2** | Crear estructura de carpetas | Dirs vacíos | Paso 1 |
| **3** | .env + env.dart + main.dart + app.dart | 4 archivos | Paso 1 |
| **4** | Theme system completo | 5 archivos (colors, text, spacing, radius, theme) | Paso 2 |
| **5** | Widgets base (FoButton, FoTextField, etc.) | 6 archivos | Paso 4 |
| **6** | Errors + Validators | 3 archivos | Paso 2 |
| **7** | Entities (AppUser, UserPreferences) | 2 archivos | Paso 2 |
| **8** | Repository contract | 1 archivo | Paso 7 |
| **9** | GoRouter config (rutas + redirects) | 1 archivo | Paso 8 |
| **10** | Splash + Onboarding screens (UI only) | 3 archivos + widgets | Paso 5, 9 |
| **11** | Login + Register screens (UI only) | 2 archivos + widgets | Paso 5, 9 |
| **12** | Auth datasource + repository impl | 2 archivos | Paso 8 |
| **13** | Auth provider (Riverpod) | 1 archivo | Paso 12 |
| **14** | Conectar Login/Register con providers | Editar 2 archivos | Paso 11, 13 |
| **15** | Verify Email + Forgot + Reset screens | 3 archivos + OTP widget | Paso 14 |
| **16** | Setup Name + Username screens | 2 archivos + progress widget | Paso 14 |
| **17** | Setup Birthday + Location screens | 2 archivos + date widget | Paso 16 |
| **18** | Setup Interests + Photo screens | 2 archivos + chip widget | Paso 17 |
| **19** | Profile setup provider + conectar | 1 archivo + editar 6 | Paso 18 |
| **20** | Integration testing + polish | Tests | Paso 19 |

**Total estimado**: ~45 archivos nuevos

---

## Notas Importantes

1. **La DB ya existe**: No crear tablas nuevas sin confirmar estructura actual con el usuario
2. **Credenciales pendientes**: SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_WEB_CLIENT_ID
3. **El diseño usa OTP de 4 dígitos**, no magic links — configurar Supabase Auth accordingly
4. **El diseño es minimalista B&W** — no usar los colores neobrutalist de la versión anterior del .pen
5. **Phone auth** aparece como 3er social button — Supabase Phone OTP requiere config en dashboard
6. **Apple Sign In** requiere: Apple Developer account, Service ID, Key configurados en Supabase
7. **Google Sign In** requiere: OAuth consent screen, Web Client ID en Supabase + app config

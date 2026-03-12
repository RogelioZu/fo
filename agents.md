# Finding Out (fo) — Contexto del Proyecto

## Que es Finding Out

Plataforma social de descubrimiento de eventos en tiempo real. Conecta personas con lo que esta pasando a su alrededor — conciertos, exposiciones, meetups, fiestas, deportes, festivales, ferias gastronomicas. Es una red social construida alrededor de la experiencia compartida: sabes quien va, sigues organizadores, descubres eventos a traves de amigos, y construyes un historial de experiencias vividas.

### Propuesta de valor

| Para quien      | Que resuelve                                                  |
| --------------- | ------------------------------------------------------------- |
| Usuarios        | El FOMO real: "que esta pasando cerca de mi ahora mismo?"     |
| Organizadores   | Visibilidad organica sin campanas de marketing complejas      |
| Ciudades        | Activacion de la vida cultural, social y economica local      |

---

## Stack Tecnologico

| Capa             | Tecnologia                                        |
| ---------------- | ------------------------------------------------- |
| Framework        | Flutter (cross-platform: iOS, Android, Web)       |
| State Management | Riverpod (providers con autodispose)              |
| Navigation       | GoRouter (rutas declarativas con guards de auth)  |
| Backend          | Supabase (Auth, Database, Storage, Realtime)      |
| Maps             | Google Maps SDK + Google Places API               |
| Image Caching    | CachedNetworkImage                                |
| Icons            | Phosphor Flutter                                  |

---

## Arquitectura — Clean Architecture (3 capas)

```
Presentation Layer
  Screens -> Widgets -> Providers (Riverpod)

Domain Layer
  Entities -> Repositories (contracts) -> Use Cases

Data Layer
  Models -> Repository Implementations -> Data Sources (Supabase, APIs)
```

Cada feature module (auth, events, profile, social, location_search) sigue esta estructura de 3 capas.

---

## Estructura del Proyecto

```
lib/
├── main.dart                    # Entry point, Supabase init
├── core/
│   ├── config/
│   │   ├── app_config.dart          # App-level configuration
│   │   ├── router_config.dart       # GoRouter con 14 rutas + auth redirect
│   │   └── supabase_config.dart     # Supabase keys y URLs
│   ├── constants/
│   │   ├── api_constants.dart       # API endpoints
│   │   └── app_constants.dart       # App-level constants
│   ├── errors/
│   │   ├── exceptions.dart          # 15+ typed exceptions
│   │   └── failures.dart            # Failure classes
│   ├── providers/
│   │   ├── location_provider.dart   # GPS location state
│   │   └── storage_provider.dart    # Supabase Storage provider
│   ├── services/
│   │   ├── location/                # Location service abstraction
│   │   └── storage/                 # File upload service
│   ├── theme/
│   │   ├── app_colors.dart          # Color palette
│   │   ├── app_theme.dart           # Material theme config
│   │   └── text_styles.dart         # Typography
│   ├── utils/
│   │   ├── date_formatter.dart      # Date/time formatting
│   │   ├── distance_calculator.dart # Haversine distance calc
│   │   ├── location_helper.dart     # Location utilities
│   │   ├── string_utils.dart        # String helpers (initials, etc.)
│   │   └── validators.dart          # Form validators
│   └── widgets/
│       ├── main_shell.dart          # Tab shell con lazy Offstage loading
│       ├── floating_navbar.dart     # Navbar flotante glassmorphism
│       ├── custom_button.dart       # Boton reutilizable
│       ├── error_widget.dart        # Error state widget
│       └── loading_indicator.dart   # Loading state
├── features/
│   ├── auth/          (13 files)    # Autenticacion completa
│   ├── events/        (46 files)    # Motor principal de eventos
│   ├── home/          (1 file)      # Home screen (legacy/placeholder)
│   ├── location_search/ (8 files)   # Google Places autocomplete
│   ├── profile/       (17 files)    # Perfiles y busqueda de usuarios
│   └── social/        (7 files)     # Sistema de follows
```

---

## Sistema de Navegacion

14 rutas con auth redirect inteligente:
- Rutas protegidas redirigen a `/login` si no hay sesion
- Rutas de auth redirigen a `/home` si ya hay sesion
- Deep link de reset-password detectado y redirigido automaticamente

### Auth Flow
`not authenticated` -> `splash` -> `login/register/forgot-password/verify-email/reset-password`

### Main Shell (tabs)
`home` -> Tab 0: Events Home | Tab 1: Events Map | Tab 2: Create Event | Tab 3: Profile | Tab 4: User Search

### Detail Routes
`category/:id` | `events/:id` | `search-events` | `edit-profile` | `users/:id`

---

## Feature: Auth (13 archivos)

Flujo completo de autenticacion con Supabase Auth, 15+ excepciones tipadas y manejo de errores granular.

### Entidad
**AppUser** — id, email, displayName, avatarUrl, createdAt + copyWith

### Screens

| Screen                | Descripcion                                              |
| --------------------- | -------------------------------------------------------- |
| SplashScreen          | Verificacion de sesion al inicio. Logo con spinner       |
| LoginScreen           | Hero illustration, glassmorphism card, gradient button, social login (UI) |
| RegisterScreen        | Registro con validacion de campos                        |
| ForgotPasswordScreen  | Solicitud de reset via email                             |
| VerifyEmailScreen     | Instrucciones post-registro, resend verification button  |
| ResetPasswordScreen   | Nueva contrasena desde deep link, strength validation    |

### Error Handling tipado

```
AppException (base)
├── AuthException
│   ├── InvalidCredentialsException
│   ├── EmailNotVerifiedException
│   ├── EmailAlreadyInUseException
│   ├── WeakPasswordException
│   ├── InvalidEmailException
│   ├── RateLimitException
│   ├── EmailVerificationRequiredException
│   ├── PasswordResetException
│   ├── ProfileUpdateException
│   ├── UserNotFoundException
│   └── NetworkException
├── EventException (+ subclasses)
└── UnknownException
```

---

## Feature: Events (46 archivos) — Motor principal

Descubrimiento, visualizacion, creacion y busqueda de eventos.

### Entidades de dominio

| Entidad           | Campos clave                                                         |
| ----------------- | -------------------------------------------------------------------- |
| Event             | id, title, description, categoryId, imageUrl, locationLat/Lng, address, startDate, endDate, createdBy, createdAt |
| Category          | id, name, icon, color, displayOrder                                  |
| EventAttendance   | id, eventId, userId, status (going/interested), createdAt            |
| FeaturedEvent     | event, category, attendeeCount, distanceKm, score                    |

### Screens principales
1. **EventsHomeScreen** (525 lineas) — Tab principal, "Netflix meets Eventbrite": inmersivo, scrollable
2. **EventsMapScreen** (414 lineas) — Google Maps con marcadores por categoria
3. **CreateEventScreen** — Formulario con imagen, ubicacion (Google Places), categoria
4. **EventDetailScreen** (571 lineas) — Hero image parallax, asistencia, amigos, compartir
5. **CategoryEventsScreen** — Lista filtrada por categoria
6. **Top10EventsScreen** — Modal con ranking inteligente

### Algoritmo de ranking
Score = 0.6 x proximidad temporal + 0.4 x popularidad (asistentes)

### Providers (Riverpod)

| Provider                | Responsabilidad                                   |
| ----------------------- | ------------------------------------------------- |
| eventsProvider          | Estado principal: eventos por categoria, loading, error |
| eventByIdProvider(id)   | Detalle de un evento especifico                   |
| featuredEventsProvider  | Eventos destacados con score calculado            |
| eventFiltersProvider    | Filtros activos (categoria, radio, fecha)         |
| eventSearchProvider     | Estado de busqueda con debounce                   |

---

## Feature: Profile (17 archivos)

### Entidades
- **UserProfile** — Perfil propio completo (privado)
- **PublicProfile** — Perfil publico visible (id, displayName, avatarUrl, createdAt)

### Screens
- **ProfileScreen** (451 lineas) — Avatar, nombre, email, stats, eventos asistidos, logout
- **EditProfileScreen** (215 lineas) — Cambiar nombre, avatar (upload a Storage)
- **UserProfileScreen** (439 lineas) — Perfil publico, follow button, eventos del usuario
- **UserSearchScreen** (226 lineas) — Busqueda con debounce en ListView

---

## Feature: Social (7 archivos)

### Entidades
- **FollowRelation** — id, followerId, followingId, createdAt
- **FollowStats** — followersCount, followingCount

### Widget principal
- **FollowButton** — Boton follow/unfollow con estado reactivo (Riverpod)

---

## Feature: Location Search (8 archivos)

Integracion con Google Places API para autocompletado de direcciones y seleccion de ubicacion.

- **GooglePlacesDatasource** — Data source que consulta la API
- **PlaceSuggestion** — Entidad (nombre, direccion, lat/lng)
- **AddressAutocompleteField** — Widget de autocompletado
- **MapLocationPickerScreen** — Pantalla de seleccion con pin en mapa

---

## Core — Infraestructura compartida

### MainShell + FloatingNavbar
- Shell con 5 tabs: Home, Mapa, Crear, Perfil, Buscar
- Navbar flotante con efecto glassmorphism
- Lazy loading: tabs se construyen solo al visitarlos

### Services
- **LocationService**: GPS tracking, permisos, estado de ubicacion
- **StorageService**: Upload de archivos a Supabase Storage

### Utils
- **DateFormatter**: Formateo consistente de fechas y horas
- **DistanceCalculator**: Calculo de distancia Haversine entre coordenadas
- **Validators**: Validacion de email, password, display name, campos de evento

---

## Estado actual — Features implementados

- Auth completo (login, registro, verificacion email, reset password)
- Descubrimiento de eventos por categoria
- Mapa interactivo con marcadores por categoria
- Creacion de eventos con imagen, ubicacion, categoria
- Detalle de evento con hero image, info, compartir
- Asistencia a eventos (going/interested)
- Contadores de asistentes
- Amigos que asisten a un evento
- Sistema de follows
- Perfiles publicos y propios
- Busqueda de usuarios
- Edicion de perfil (nombre + avatar)
- Busqueda de eventos en tiempo real
- Eventos destacados con ranking inteligente
- Top 10 eventos
- Image caching (CachedNetworkImage)
- Lazy tab loading
- 15+ tipos de excepciones

---

## Proximo paso: Rehacer Auth (Login/Registro)

Empezar desde cero el modulo de autenticacion, usando el mismo stack (Flutter + Supabase + Riverpod + GoRouter) pero mejor estructurado.

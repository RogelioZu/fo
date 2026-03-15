import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/router.dart';
import 'core/theme/app_theme.dart';

/// Provider para SharedPreferences (inicializado en main.dart).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

/// Provider del GoRouter — se crea UNA sola vez (evita recrearlo en cada build).
final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return AppRouter.router(prefs);
});

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(routerProvider);

    return MaterialApp.router(
      title: 'Finding Out',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

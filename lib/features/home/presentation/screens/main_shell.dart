import 'package:flutter/material.dart';

import '../widgets/nav_pill.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Shell principal con navegación por tabs (Home, Search, Map, Profile).
///
/// Usa IndexedStack para preservar el estado de cada tab.
/// Los tabs se cargan lazy (solo al visitar) y se cachean para evitar
/// que se recreen en cada rebuild (lo cual destruye el estado del mapa).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  /// Tabs que ya fueron visitados.
  final Set<int> _loadedTabs = {0};

  /// Cache de widgets creados — NUNCA se recrean después de su primera
  /// construcción. Esto es crítico para GoogleMap: si el widget se recrea,
  /// el estado del mapa se pierde y se inicializa de nuevo, causando
  /// un crash por reinicialización nativa repetida.
  late final List<Widget> _cachedScreens = List.generate(4, (_) => const SizedBox.shrink());

  @override
  void initState() {
    super.initState();
    // Home siempre cargado
    _cachedScreens[0] = const HomeScreen();
  }

  void _onTabTap(int index) {
    if (!_loadedTabs.contains(index)) {
      _loadedTabs.add(index);
      // Crear el widget UNA vez y cachearlo
      switch (index) {
        case 1:
          _cachedScreens[1] = const SearchScreen();
          break;
        case 2:
          _cachedScreens[2] = const MapScreen();
          break;
        case 3:
          _cachedScreens[3] = const ProfileScreen();
          break;
      }
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _cachedScreens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavPill(
              currentIndex: _currentIndex,
              onTap: _onTabTap,
            ),
          ),
        ],
      ),
    );
  }
}

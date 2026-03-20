import 'package:flutter/material.dart';

import '../widgets/nav_pill.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

/// Shell principal con navegación por tabs (Home, Search, Map, Profile).
/// Usa IndexedStack para preservar el estado de cada tab.
///
/// Los tabs pesados (como Map) se cargan lazy: solo se construyen
/// cuando el usuario los visita por primera vez.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  /// Tabs que ya fueron visitados → se activan con lazy loading.
  final Set<int> _loadedTabs = {0}; // Home siempre cargado

  Widget _buildTab(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }

    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: Text('Search — TODO')),
        );
      case 2:
        return const MapScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTabTap(int index) {
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: List.generate(4, _buildTab),
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

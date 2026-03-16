import 'package:flutter/material.dart';

import '../widgets/nav_pill.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Shell principal con navegación por tabs (Home, Search, Profile).
/// Usa IndexedStack para preservar el estado de cada tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static final List<Widget> _screens = [
    const HomeScreen(),
    const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text('Search — TODO')),
    ),
    const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text('Map — TODO')),
    ),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavPill(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

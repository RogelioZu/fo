import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Barra de navegación flotante tipo pill con efecto glassmorphism.
/// Blur de fondo + tinte translúcido + borde sutil brillante.
class NavPill extends StatelessWidget {
  const NavPill({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    _NavTab(icon: LucideIcons.home, label: 'HOME'),
    _NavTab(icon: LucideIcons.search, label: 'SEARCH'),
    _NavTab(icon: LucideIcons.map, label: 'MAP'),
    _NavTab(icon: LucideIcons.user, label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(31),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              // Tinte muy sutil — deja que el blur sea protagonista
              color: AppColors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(31),
              // Borde glass — brillo fino apenas visible
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 8),
                  blurRadius: 32,
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.black.withValues(alpha: 0.75)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(27),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tab.icon,
                            size: 18,
                            color: isActive
                                ? AppColors.white
                                : AppColors.gray500,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: isActive
                                  ? AppColors.white
                                  : AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

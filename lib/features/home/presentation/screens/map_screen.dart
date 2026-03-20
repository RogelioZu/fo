import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Pantalla de mapa con marcadores, barra de búsqueda,
/// chips de filtro y bottom sheet arrastrable con eventos destacados.
/// De momento el mapa es un placeholder visual.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // ─── Map placeholder ───
          _MapPlaceholder(),

          // ─── Markers ───
          _MapMarkers(),

          // ─── Top search + chips ───
          _TopUI(),

          // ─── Draggable bottom sheet ───
          _EventsBottomSheet(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Map placeholder
// ─────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE8E4D8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.map,
              size: 48,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 8),
            Text(
              'Map',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Map markers (decorative)
// ─────────────────────────────────────────────

class _MapMarkers extends StatelessWidget {
  const _MapMarkers();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        // Marker 1 — Music (blue)
        Positioned(
          left: 120,
          top: 250,
          child: _MarkerPin(
            color: Color(0xFF3B82F6),
            icon: LucideIcons.music,
            size: 36,
            iconSize: 16,
            borderWidth: 3,
          ),
        ),
        // Marker 2 — Art (red)
        Positioned(
          left: 250,
          top: 380,
          child: _MarkerPin(
            color: Color(0xFFEF4444),
            icon: LucideIcons.palette,
            size: 36,
            iconSize: 16,
            borderWidth: 3,
          ),
        ),
        // Marker 3 — Ticket (green)
        Positioned(
          left: 180,
          top: 480,
          child: _MarkerPin(
            color: Color(0xFF10B981),
            icon: LucideIcons.ticket,
            size: 44,
            iconSize: 20,
            borderWidth: 4,
          ),
        ),
      ],
    );
  }
}

class _MarkerPin extends StatelessWidget {
  const _MarkerPin({
    required this.color,
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.borderWidth,
  });

  final Color color;
  final IconData icon;
  final double size;
  final double iconSize;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: iconSize, color: AppColors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top UI: search bar + filter chips
// ─────────────────────────────────────────────

class _TopUI extends StatelessWidget {
  const _TopUI();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Search bar ───
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20000000),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(LucideIcons.search, size: 20, color: AppColors.gray400),
                  const SizedBox(width: 12),
                  Text(
                    'Search events, venues...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ─── Filter chips ───
            Row(
              children: [
                _FilterChip(label: 'All', isSelected: true),
                const SizedBox(width: 8),
                _FilterChip(label: 'Music', isSelected: false),
                const SizedBox(width: 8),
                _FilterChip(label: 'Art', isSelected: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.black : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isSelected ? AppColors.white : AppColors.black,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Draggable bottom sheet with event cards
// ─────────────────────────────────────────────

class _EventsBottomSheet extends StatelessWidget {
  const _EventsBottomSheet();

  // Collapsed: ~294px of 874px total ≈ 0.336
  // Expanded: ~614px of 874px total ≈ 0.703
  static const double _minChildSize = 0.34;
  static const double _maxChildSize = 0.75;
  static const double _initialChildSize = 0.34;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _initialChildSize,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      snap: true,
      snapSizes: const [_minChildSize, _maxChildSize],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, -8),
                blurRadius: 24,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            children: [
              // ─── Handle ───
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Header ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Events',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const Icon(
                    LucideIcons.slidersHorizontal,
                    size: 20,
                    color: AppColors.black,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Event cards ───
              const _EventCard(
                title: 'Summer Music Fest',
                subtitle: 'WiZink Center \u2022 2.5km',
                imageColor: Color(0xFFE8A040),
              ),
              const SizedBox(height: 24),
              const _EventCard(
                title: 'Tech Conference 2026',
                subtitle: 'IFEMA \u2022 4.1km',
                imageColor: Color(0xFF7BA8C4),
              ),
              const SizedBox(height: 24),
              const _EventCard(
                title: 'Modern Art Exhibition',
                subtitle: 'Prado Museum \u2022 1.2km',
                imageColor: Color(0xFFC4A87B),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.subtitle,
    required this.imageColor,
  });

  final String title;
  final String subtitle;
  final Color imageColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Event image placeholder
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: imageColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              LucideIcons.image,
              size: 24,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Event info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

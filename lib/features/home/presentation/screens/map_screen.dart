import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────
// Data models (inline, event feature)
// ─────────────────────────────────────────────

/// Evento con ubicación para el mapa.
class MapEvent {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final String? imageUrl;
  final double? locationLat;
  final double? locationLng;
  final String? address;
  final DateTime startDate;

  const MapEvent({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    this.imageUrl,
    this.locationLat,
    this.locationLng,
    this.address,
    required this.startDate,
  });

  bool get hasLocation => locationLat != null && locationLng != null;

  factory MapEvent.fromJson(Map<String, dynamic> json) => MapEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        categoryId: json['category_id'] as String,
        imageUrl: json['image_url'] as String?,
        locationLat: (json['location_lat'] as num?)?.toDouble(),
        locationLng: (json['location_lng'] as num?)?.toDouble(),
        address: json['address'] as String?,
        startDate: DateTime.parse(json['start_date'] as String),
      );
}

/// Categoría de evento con ícono y color.
class MapCategory {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final IconData lucideIcon;

  const MapCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.lucideIcon,
  });
}

// ─────────────────────────────────────────────
// Category definitions (con fallback hardcoded)
// ─────────────────────────────────────────────

/// Categorías con sus colores e íconos para el mapa.
/// Se sincronizan con la DB cuando hay datos; estas son el fallback.
final _defaultCategories = <MapCategory>[
  MapCategory(id: 'music', name: 'Music', icon: 'musicNote', color: const Color(0xFF3B82F6), lucideIcon: LucideIcons.music),
  MapCategory(id: 'art', name: 'Art', icon: 'paintBrush', color: const Color(0xFFEF4444), lucideIcon: LucideIcons.palette),
  MapCategory(id: 'sports', name: 'Sports', icon: 'soccerBall', color: const Color(0xFF10B981), lucideIcon: LucideIcons.trophy),
  MapCategory(id: 'food_drinks', name: 'Food & Drinks', icon: 'forkKnife', color: const Color(0xFFF59E0B), lucideIcon: LucideIcons.utensils),
  MapCategory(id: 'tech', name: 'Tech', icon: 'cpu', color: const Color(0xFF8B5CF6), lucideIcon: LucideIcons.cpu),
  MapCategory(id: 'nightlife', name: 'Nightlife', icon: 'martini', color: const Color(0xFFEC4899), lucideIcon: LucideIcons.wine),
  MapCategory(id: 'teatro', name: 'Theater', icon: 'maskHappy', color: const Color(0xFF6366F1), lucideIcon: LucideIcons.smile),
  MapCategory(id: 'cinema', name: 'Cinema', icon: 'filmStrip', color: const Color(0xFFD97706), lucideIcon: LucideIcons.film),
];

// ─────────────────────────────────────────────
// Map Screen (StatefulWidget — functional)
// ─────────────────────────────────────────────

/// Pantalla del mapa con búsqueda funcional,
/// chips de filtro dinámicos y bottom sheet con eventos reales.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  String? _selectedCategoryId;
  List<MapEvent> _events = [];
  List<MapEvent> _filteredEvents = [];
  List<MapEvent> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─── Data Loading ───

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('events')
          .select()
          .not('location_lat', 'is', null)
          .not('location_lng', 'is', null)
          .order('start_date', ascending: true);

      if (!mounted) return;
      setState(() {
        _events = (data as List).map((e) => MapEvent.fromJson(e)).toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading map events: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      if (_selectedCategoryId == null) {
        _filteredEvents = List.from(_events);
      } else {
        _filteredEvents = _events
            .where((e) => e.categoryId == _selectedCategoryId)
            .toList();
      }
    });
  }

  // ─── Category Filter ───

  void _onCategoryTap(String? categoryId) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategoryId =
          (_selectedCategoryId == categoryId) ? null : categoryId;
      _applyFilters();
    });
  }

  // ─── Search ───

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchQuery = '';
      });
      return;
    }

    _searchQuery = query;
    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      try {
        final data = await Supabase.instance.client
            .from('events')
            .select()
            .ilike('title', '%${query.trim()}%')
            .order('start_date', ascending: true)
            .limit(10);

        if (!mounted || _searchQuery != query) return;

        setState(() {
          _searchResults =
              (data as List).map((e) => MapEvent.fromJson(e)).toList();
          _isSearching = false;
        });
      } catch (e) {
        debugPrint('Error searching events: $e');
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _onSearchClear() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _searchQuery = '';
    });
    _searchFocusNode.unfocus();
  }

  // ─── Helpers ───

  MapCategory? _getCategoryForEvent(MapEvent event) {
    try {
      return _defaultCategories.firstWhere((c) => c.id == event.categoryId);
    } catch (_) {
      return null;
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // ─── Map placeholder ───
          _buildMapPlaceholder(),

          // ─── Markers from real events ───
          ..._buildEventMarkers(),

          // ─── Top: search bar + chips ───
          _buildTopUI(),

          // ─── Draggable bottom sheet ───
          _buildBottomSheet(),
        ],
      ),
    );
  }

  // ─── Map Placeholder ───

  Widget _buildMapPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE8E4D8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.map, size: 48, color: AppColors.gray400),
            const SizedBox(height: 8),
            Text(
              'Map — Coming Soon',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_filteredEvents.length} events nearby',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Event Markers (positioned on placeholder) ───

  List<Widget> _buildEventMarkers() {
    // Show first 5 events as visual markers spread on the placeholder
    final visible = _filteredEvents.take(5).toList();
    if (visible.isEmpty) return [];

    // Spread markers visually across the screen
    final positions = [
      const Offset(0.25, 0.30),
      const Offset(0.65, 0.45),
      const Offset(0.40, 0.55),
      const Offset(0.75, 0.30),
      const Offset(0.15, 0.50),
    ];

    return List.generate(visible.length, (i) {
      final event = visible[i];
      final category = _getCategoryForEvent(event);
      final pos = positions[i];

      return Positioned(
        left: MediaQuery.of(context).size.width * pos.dx,
        top: MediaQuery.of(context).size.height * pos.dy,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showEventSnackbar(event);
          },
          child: _MarkerPin(
            color: category?.color ?? AppColors.accent,
            icon: category?.lucideIcon ?? LucideIcons.mapPin,
            size: 40,
            iconSize: 18,
            borderWidth: 3,
          ),
        ),
      );
    });
  }

  void _showEventSnackbar(MapEvent event) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.mapPin, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (event.address != null)
                    Text(event.address!,
                        style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.black,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Top UI ───

  Widget _buildTopUI() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Search bar ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
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
                  const Icon(LucideIcons.search,
                      size: 20, color: AppColors.gray400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search events, venues...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.gray400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _onSearchClear,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(LucideIcons.x,
                            size: 18, color: AppColors.gray400),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Search Results Dropdown ───
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray200),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gray400,
                            ),
                          ),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No events found',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.gray400,
                                ),
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 44,
                                color: AppColors.gray100,
                              ),
                              itemBuilder: (context, index) {
                                final event = _searchResults[index];
                                final cat = _getCategoryForEvent(event);
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    cat?.lucideIcon ?? LucideIcons.mapPin,
                                    size: 18,
                                    color: cat?.color ?? AppColors.accent,
                                  ),
                                  title: Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: event.address != null
                                      ? Text(
                                          event.address!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.gray500,
                                          ),
                                        )
                                      : null,
                                  onTap: () {
                                    _onSearchClear();
                                    _showEventSnackbar(event);
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ),

          const SizedBox(height: 12),

          // ─── Filter chips (scrollable) ───
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _defaultCategories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedCategoryId == null;
                  return GestureDetector(
                    onTap: () => _onCategoryTap(null),
                    child: _FilterChipWidget(
                      label: 'All',
                      isSelected: isSelected,
                      color: AppColors.black,
                    ),
                  );
                }
                final cat = _defaultCategories[index - 1];
                final isSelected = _selectedCategoryId == cat.id;
                return GestureDetector(
                  onTap: () => _onCategoryTap(cat.id),
                  child: _FilterChipWidget(
                    label: cat.name,
                    isSelected: isSelected,
                    color: cat.color,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Sheet ───

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.34,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.34, 0.75],
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
              // Handle
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

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategoryId != null
                        ? '${_getCategoryName(_selectedCategoryId!)} Events'
                        : 'Featured Events',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  Row(
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gray400,
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.slidersHorizontal,
                        size: 20,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Event list (real data or empty state)
              if (_filteredEvents.isEmpty && !_isLoading)
                _buildEmptyState()
              else
                ..._filteredEvents.take(10).map((event) {
                  final cat = _getCategoryForEvent(event);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _EventCardWidget(
                      title: event.title,
                      subtitle: event.address ?? 'No location',
                      imageColor: cat?.color ?? AppColors.gray400,
                      icon: cat?.lucideIcon ?? LucideIcons.calendar,
                      onTap: () => _showEventSnackbar(event),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(LucideIcons.mapPin, size: 36, color: AppColors.gray200),
          const SizedBox(height: 12),
          Text(
            'No events found',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedCategoryId != null
                ? 'Try a different category'
                : 'Events will appear here',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String id) {
    try {
      return _defaultCategories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return 'All';
    }
  }
}

// ─────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────

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

class _FilterChipWidget extends StatelessWidget {
  const _FilterChipWidget({
    required this.label,
    required this.isSelected,
    required this.color,
  });

  final String label;
  final bool isSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? color : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : AppColors.gray200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? color.withValues(alpha: 0.3)
                : const Color(0x0A000000),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.white : AppColors.black,
        ),
      ),
    );
  }
}

class _EventCardWidget extends StatelessWidget {
  const _EventCardWidget({
    required this.title,
    required this.subtitle,
    required this.imageColor,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color imageColor;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: imageColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, size: 24, color: imageColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

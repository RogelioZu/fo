import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────
// Cached text styles — avoids repeated GoogleFonts lookups per frame.
// ─────────────────────────────────────────────
final _tsSearchInput = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.black);
final _tsSearchHint = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.gray400);
final _tsChip = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600);
final _tsSheetTitle = GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black);
final _tsSheetCount = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray400);
final _tsCardTitle = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black);
final _tsCardSubtitle = GoogleFonts.inter(fontSize: 13, color: AppColors.gray500);
final _tsResultTitle = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);
final _tsResultSubtitle = GoogleFonts.inter(fontSize: 12, color: AppColors.gray500);
final _tsNoResults = GoogleFonts.inter(fontSize: 14, color: AppColors.gray400);
final _tsEmptyTitle = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray400);
final _tsEmptySubtitle = GoogleFonts.inter(fontSize: 13, color: AppColors.gray400);
final _tsCategoryBadge = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600);

// ─────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────

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

class MapCategory {
  final String id;
  final String name;
  final Color color;
  final IconData lucideIcon;
  final double markerHue;

  const MapCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.lucideIcon,
    required this.markerHue,
  });
}

// ─────────────────────────────────────────────
// Category definitions
// ─────────────────────────────────────────────

final _defaultCategories = <MapCategory>[
  MapCategory(id: 'music', name: 'Music', color: const Color(0xFF3B82F6), lucideIcon: LucideIcons.music, markerHue: BitmapDescriptor.hueAzure),
  MapCategory(id: 'art', name: 'Art', color: const Color(0xFFEF4444), lucideIcon: LucideIcons.palette, markerHue: BitmapDescriptor.hueRed),
  MapCategory(id: 'sports', name: 'Sports', color: const Color(0xFF10B981), lucideIcon: LucideIcons.trophy, markerHue: BitmapDescriptor.hueGreen),
  MapCategory(id: 'food_drinks', name: 'Food & Drinks', color: const Color(0xFFF59E0B), lucideIcon: LucideIcons.utensils, markerHue: BitmapDescriptor.hueOrange),
  MapCategory(id: 'tech', name: 'Tech', color: const Color(0xFF8B5CF6), lucideIcon: LucideIcons.cpu, markerHue: BitmapDescriptor.hueViolet),
  MapCategory(id: 'nightlife', name: 'Nightlife', color: const Color(0xFFEC4899), lucideIcon: LucideIcons.wine, markerHue: BitmapDescriptor.hueRose),
  MapCategory(id: 'teatro', name: 'Theater', color: const Color(0xFF6366F1), lucideIcon: LucideIcons.smile, markerHue: BitmapDescriptor.hueBlue),
  MapCategory(id: 'cinema', name: 'Cinema', color: const Color(0xFFD97706), lucideIcon: LucideIcons.film, markerHue: BitmapDescriptor.hueYellow),
];

/// O(1) category lookup map — built once from the list above.
final _categoryMap = {for (final c in _defaultCategories) c.id: c};

// ─────────────────────────────────────────────
// Map Screen
// ─────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with AutomaticKeepAliveClientMixin {
  // ─── Controllers ───
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  // ─── State ───
  String? _selectedCategoryId;
  List<MapEvent> _events = [];
  List<MapEvent> _filteredEvents = [];
  List<MapEvent> _searchResults = [];
  Set<Marker> _markers = {};
  MapEvent? _selectedEvent;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  // Default position (Monterrey, MX — se actualiza con GPS)
  static const _defaultPosition = LatLng(25.6866, -100.3161);
  LatLng _currentPosition = _defaultPosition;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
    _loadEvents();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    // No disponer _mapController — GoogleMap lo maneja internamente
    super.dispose();
  }

  // ─── Location ───

  Future<void> _initUserLocation() async {
    try {
      // Only need lat/lng — skip reverse geocoding (city/country).
      final position = await LocationService.getCurrentPosition();
      if (position != null && mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() => _currentPosition = latLng);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 13),
        );
      }
    } catch (e) {
      debugPrint('Error getting user location: $e');
    }
  }

  Future<void> _goToMyLocation() async {
    HapticFeedback.mediumImpact();
    try {
      // Only need lat/lng — skip reverse geocoding (city/country).
      final position = await LocationService.getCurrentPosition();
      if (position != null && mounted) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error centering on user: $e');
    }
  }

  // ─── Data ───

  Future<void> _loadEvents() async {
    try {
      final data = await Supabase.instance.client
          .from('events')
          .select()
          .not('location_lat', 'is', null)
          .not('location_lng', 'is', null)
          .order('start_date', ascending: true);

      if (!mounted) return;
      final events = (data as List).map((e) => MapEvent.fromJson(e)).toList();
      setState(() {
        _events = events;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading events: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final filtered = _selectedCategoryId == null
        ? List<MapEvent>.from(_events)
        : _events.where((e) => e.categoryId == _selectedCategoryId).toList();

    setState(() {
      _filteredEvents = filtered;
      _markers = _buildMarkers(filtered);
    });
  }

  // ─── Markers ───

  Set<Marker> _buildMarkers(List<MapEvent> events) {
    return events.where((e) => e.hasLocation).map((event) {
      final cat = _getCategoryForEvent(event);
      return Marker(
        markerId: MarkerId(event.id),
        position: LatLng(event.locationLat!, event.locationLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          cat?.markerHue ?? BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: event.title,
          snippet: event.address ?? '',
        ),
        onTap: () => _onMarkerTap(event),
      );
    }).toSet();
  }

  void _onMarkerTap(MapEvent event) {
    HapticFeedback.selectionClick();
    setState(() => _selectedEvent = event);

    if (event.hasLocation) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(event.locationLat!, event.locationLng!),
        ),
      );
    }
  }

  void _dismissSelectedEvent() {
    setState(() => _selectedEvent = null);
  }

  // ─── Category Filter ───

  void _onCategoryTap(String? categoryId) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategoryId =
          (_selectedCategoryId == categoryId) ? null : categoryId;
      _selectedEvent = null;
    });
    _applyFilters();
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

  void _onSearchResultTap(MapEvent event) {
    _onSearchClear();
    if (event.hasLocation) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(event.locationLat!, event.locationLng!),
          15,
        ),
      );
      setState(() => _selectedEvent = event);
    }
  }

  // ─── Helpers ───

  MapCategory? _getCategoryForEvent(MapEvent event) =>
      _categoryMap[event.categoryId];

  String _getCategoryName(String id) =>
      _categoryMap[id]?.name ?? 'All';

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // ═══ Google Map (full screen) ═══
          RepaintBoundary(child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 13,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Map ready
            },
            markers: _markers,
            onTap: (_) {
              _dismissSelectedEvent();
              _searchFocusNode.unfocus();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            // Estilo limpio: sin POIs ni transit
            style: _cleanMapStyle,
          )),

          // ═══ Top UI: search + chips ═══
          Positioned(
            top: topPadding + 8,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Search Bar ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSearchBar(),
                ),

                // ─── Search Results ───
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSearchResults(),
                  ),

                const SizedBox(height: 12),

                // ─── Category Chips ───
                _buildCategoryChips(),
              ],
            ),
          ),

          // ═══ My Location Button ═══
          Positioned(
            right: 16,
            bottom: _selectedEvent != null ? 290 : 120,
            child: _buildMyLocationButton(),
          ),

          // ═══ Bottom Sheet ═══
          _buildBottomSheet(),

          // ═══ Selected Event Overlay ═══
          if (_selectedEvent != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: _buildSelectedEventCard(),
            ),

          // ═══ Loading indicator ═══
          if (_isLoading)
            Positioned(
              top: topPadding + 140,
              left: 0,
              right: 0,
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Search Bar ───

  Widget _buildSearchBar() {
    return Container(
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
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: _tsSearchInput,
              decoration: InputDecoration(
                hintText: 'Search events, venues...',
                hintStyle: _tsSearchHint,
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
                child: Icon(LucideIcons.x, size: 18, color: AppColors.gray400),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Search Results Dropdown ───

  Widget _buildSearchResults() {
    return Container(
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
                      style: _tsNoResults,
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 44, color: AppColors.gray100),
                    itemBuilder: (context, i) {
                      final event = _searchResults[i];
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
                          style: _tsResultTitle,
                        ),
                        subtitle: event.address != null
                            ? Text(event.address!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _tsResultSubtitle)
                            : null,
                        onTap: () => _onSearchResultTap(event),
                      );
                    },
                  ),
                ),
    );
  }

  // ─── Category Chips ───

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _defaultCategories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: () => _onCategoryTap(null),
              child: _ChipWidget(
                label: 'All',
                isSelected: _selectedCategoryId == null,
                color: AppColors.black,
              ),
            );
          }
          final cat = _defaultCategories[index - 1];
          return GestureDetector(
            onTap: () => _onCategoryTap(cat.id),
            child: _ChipWidget(
              label: cat.name,
              isSelected: _selectedCategoryId == cat.id,
              color: cat.color,
            ),
          );
        },
      ),
    );
  }

  // ─── My Location FAB ───

  Widget _buildMyLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _goToMyLocation,
        icon: const Icon(LucideIcons.locate, color: AppColors.black, size: 22),
      ),
    );
  }

  // ─── Bottom Sheet ───

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.30,
      minChildSize: 0.12,
      maxChildSize: 0.70,
      snap: true,
      snapSizes: const [0.12, 0.30, 0.70],
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
                        : 'Nearby Events',
                    style: _tsSheetTitle,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Text(
                        '${_filteredEvents.length}',
                        style: _tsSheetCount,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Events list
              if (_filteredEvents.isEmpty && !_isLoading) _buildEmptyState(),

              ..._filteredEvents.take(15).map((event) {
                final cat = _getCategoryForEvent(event);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _EventCardWidget(
                    title: event.title,
                    subtitle: event.address ?? 'Location TBD',
                    color: cat?.color ?? AppColors.gray400,
                    icon: cat?.lucideIcon ?? LucideIcons.calendar,
                    onTap: () {
                      if (event.hasLocation) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(event.locationLat!, event.locationLng!),
                            15,
                          ),
                        );
                        setState(() => _selectedEvent = event);
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ─── Selected Event Card ───

  Widget _buildSelectedEventCard() {
    final event = _selectedEvent!;
    final cat = _getCategoryForEvent(event);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category colored icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (cat?.color ?? AppColors.gray400).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                cat?.lucideIcon ?? LucideIcons.calendar,
                size: 24,
                color: cat?.color ?? AppColors.gray400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cat != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cat.name,
                      style: _tsCategoryBadge.copyWith(color: cat.color),
                    ),
                  ),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _tsCardTitle,
                ),
                if (event.address != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin,
                          size: 13, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _tsCardSubtitle,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Close
          GestureDetector(
            onTap: _dismissSelectedEvent,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 18, color: AppColors.gray400),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ───

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(LucideIcons.mapPin, size: 36, color: AppColors.gray200),
          const SizedBox(height: 12),
          Text(
            'No events found',
            style: _tsEmptyTitle,
          ),
          const SizedBox(height: 4),
          Text(
            _selectedCategoryId != null
                ? 'Try a different category'
                : 'Events will appear here',
            style: _tsEmptySubtitle,
          ),
        ],
      ),
    );
  }

  // ─── Map Style ───
  static const String _cleanMapStyle = '''[
    {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","elementType":"labels","stylers":[{"visibility":"off"}]}
  ]''';
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _ChipWidget extends StatelessWidget {
  const _ChipWidget({
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
        style: _tsChip.copyWith(
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
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Icon(icon, size: 22, color: color)),
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
                  style: _tsCardTitle,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin,
                        size: 13, color: AppColors.gray400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _tsCardSubtitle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: AppColors.gray200),
        ],
      ),
    );
  }
}

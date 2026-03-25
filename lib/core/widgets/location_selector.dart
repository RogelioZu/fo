import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../features/auth/presentation/providers/places_provider.dart';
import '../services/location_service.dart';
import '../services/places/city_suggestion.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'fo_text_field.dart';

/// Datos de ubicación retornados por [LocationSelector].
class LocationData {
  final String city;
  final String country;
  final double? lat;
  final double? lng;

  const LocationData({
    required this.city,
    required this.country,
    this.lat,
    this.lng,
  });
}

/// Widget reutilizable de selección de ubicación.
///
/// Ofrece dos modos:
///   1. GPS automático (Geolocator + reverse geocoding)
///   2. Búsqueda manual con Google Places Autocomplete
///
/// Usado en el setup de perfil y en el bottom sheet de cambio de ubicación.
class LocationSelector extends ConsumerStatefulWidget {
  const LocationSelector({
    super.key,
    required this.onLocationSelected,
    this.showSelectedBadge = true,
  });

  /// Callback cuando el usuario selecciona una ubicación.
  final ValueChanged<LocationData> onLocationSelected;

  /// Si es true, muestra el badge de ubicación seleccionada.
  /// En el bottom sheet se pone en false porque cierra al seleccionar.
  final bool showSelectedBadge;

  @override
  ConsumerState<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends ConsumerState<LocationSelector> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _isLoadingGps = false;
  bool _isLoadingSuggestions = false;
  List<CitySuggestion> _suggestions = [];
  CitySuggestion? _selectedSuggestion;
  Timer? _debounceTimer;

  // GPS fallback data
  String? _gpsCity;
  String? _gpsCountry;

  /// Indica si hay una selección válida (GPS o autocomplete).
  bool get hasSelection => _selectedSuggestion != null || _gpsCity != null;

  /// Texto para mostrar la selección actual.
  String? get selectionDisplay {
    if (_selectedSuggestion != null) {
      return _selectedSuggestion!.fullDescription;
    }
    if (_gpsCity != null) {
      return '$_gpsCity, $_gpsCountry';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() => _suggestions = []);
    }
  }

  // ─── GPS ───

  Future<void> _onUseGps() async {
    setState(() => _isLoadingGps = true);

    try {
      final result = await LocationService.requestAndResolveLocation();

      if (!mounted) return;

      if (result == null) {
        setState(() => _isLoadingGps = false);
        _showPermissionDialog();
        return;
      }

      final data = LocationData(
        city: result.city ?? '',
        country: result.country ?? '',
        lat: result.lat,
        lng: result.lng,
      );

      setState(() {
        _gpsCity = data.city;
        _gpsCountry = data.country;
        _selectedSuggestion = null;
        _searchController.clear();
        _suggestions = [];
        _isLoadingGps = false;
      });

      widget.onLocationSelected(data);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: const Text('Location permission'),
        content: const Text(
          'We need location access to find your city. '
          'Would you like to open settings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ─── Search / Autocomplete ───

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      final placesService = ref.read(placesServiceProvider);
      final results = await placesService.searchCities(query.trim());

      if (!mounted) return;

      setState(() {
        _suggestions = results;
        _isLoadingSuggestions = false;
      });
    });
  }

  Future<void> _onSuggestionSelected(CitySuggestion suggestion) async {
    final placesService = ref.read(placesServiceProvider);
    final detailed = await placesService.getCityDetails(suggestion);

    if (!mounted) return;

    final data = LocationData(
      city: detailed.city,
      country: detailed.country,
      lat: detailed.lat,
      lng: detailed.lng,
    );

    setState(() {
      _selectedSuggestion = detailed;
      _gpsCity = null;
      _gpsCountry = null;
      _searchController.text = detailed.fullDescription;
      _suggestions = [];
    });

    _searchFocusNode.unfocus();
    placesService.startNewSession();

    widget.onLocationSelected(data);
  }

  void _clearSelection() {
    setState(() {
      _selectedSuggestion = null;
      _gpsCity = null;
      _gpsCountry = null;
      _searchController.clear();
    });
    ref.read(placesServiceProvider).startNewSession();
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── GPS Button ───
        _buildGpsButton(),
        const SizedBox(height: AppSpacing.lg),

        // ─── Divider ───
        _buildDivider(),
        const SizedBox(height: AppSpacing.lg),

        // ─── Search + Dropdown ───
        _buildSearchField(),
        if (_suggestions.isNotEmpty || _isLoadingSuggestions)
          _buildSuggestionsDropdown(),

        // ─── Selected Location Badge ───
        if (widget.showSelectedBadge &&
            hasSelection &&
            _suggestions.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildSelectedBadge(),
        ],
      ],
    );
  }

  // ─── Sub-widgets ───

  Widget _buildGpsButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoadingGps ? null : _onUseGps,
        icon: _isLoadingGps
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            : const Icon(
                PhosphorIconsRegular.crosshair,
                color: AppColors.accent,
                size: 20,
              ),
        label: Text(
          _gpsCity != null
              ? '$_gpsCity, $_gpsCountry'
              : 'Use my current location',
          style: AppTextStyles.buttonText.copyWith(
            color: AppColors.accent,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.accent),
          backgroundColor: AppColors.accentBg,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.chipRadius,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.gray200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or search your city', style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider(color: AppColors.gray200)),
      ],
    );
  }

  Widget _buildSearchField() {
    return FoTextField(
      hintText: 'Search city...',
      prefixIcon: PhosphorIconsRegular.magnifyingGlass,
      controller: _searchController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.search,
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildSuggestionsDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoadingSuggestions && _suggestions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gray400,
                  ),
                ),
              ),
            )
          : ClipRRect(
              borderRadius: AppRadius.cardRadius,
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 48,
                  color: AppColors.gray100,
                ),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return _buildSuggestionTile(suggestion);
                },
              ),
            ),
    );
  }

  Widget _buildSuggestionTile(CitySuggestion suggestion) {
    return InkWell(
      onTap: () => _onSuggestionSelected(suggestion),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            const Icon(
              PhosphorIconsRegular.mapPin,
              size: 18,
              color: AppColors.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.city,
                    style: AppTextStyles.label,
                  ),
                  if (suggestion.state != null ||
                      suggestion.country.isNotEmpty)
                    Text(
                      [suggestion.state, suggestion.country]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(', '),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentBg,
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.mapPin,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectionDisplay ?? '',
              style: AppTextStyles.body.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearSelection,
            child: const Icon(
              PhosphorIconsRegular.x,
              size: 16,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

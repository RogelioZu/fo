import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/places/city_suggestion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/fo_button.dart';
import '../../../../../core/widgets/fo_text_field.dart';
import '../../providers/places_provider.dart';
import '../../providers/profile_setup_provider.dart';
import '../../widgets/progress_bar.dart';

/// Pantalla de Setup Location — Step 4/6.
///
/// Dos modos de selección:
///   1. GPS automático (Geolocator + reverse geocoding)
///   2. Búsqueda manual con Google Places Autocomplete (session tokens)
///
/// El dropdown muestra ciudades con estado y país para desambiguar.
class SetupLocationScreen extends ConsumerStatefulWidget {
  const SetupLocationScreen({super.key});

  @override
  ConsumerState<SetupLocationScreen> createState() =>
      _SetupLocationScreenState();
}

class _SetupLocationScreenState extends ConsumerState<SetupLocationScreen> {
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
  double? _gpsLat;
  double? _gpsLng;

  /// Indica si hay una selección válida (GPS o autocomplete).
  bool get _hasSelection =>
      _selectedSuggestion != null || _gpsCity != null;

  /// Texto para mostrar la selección actual.
  String? get _selectionDisplay {
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
    // Si pierde el foco y no hay búsqueda activa, limpiar sugerencias
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

      setState(() {
        _gpsCity = result.city ?? '';
        _gpsCountry = result.country ?? '';
        _gpsLat = result.lat;
        _gpsLng = result.lng;
        _selectedSuggestion = null; // GPS takes priority over search
        _searchController.clear();
        _suggestions = [];
        _isLoadingGps = false;
      });
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
              // Geolocator.openAppSettings(); // Uncomment when needed
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

    // Debounce de 400ms para no disparar requests en cada keystroke
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
    // Obtener detalles (lat/lng) — consume el session token
    final placesService = ref.read(placesServiceProvider);
    final detailed = await placesService.getCityDetails(suggestion);

    if (!mounted) return;

    setState(() {
      _selectedSuggestion = detailed;
      _gpsCity = null;
      _gpsCountry = null;
      _gpsLat = null;
      _gpsLng = null;
      _searchController.text = detailed.fullDescription;
      _suggestions = [];
    });

    _searchFocusNode.unfocus();

    // Iniciar nueva sesión para la próxima búsqueda
    placesService.startNewSession();
  }

  // ─── Continue ───

  void _onContinue() {
    if (_selectedSuggestion != null) {
      ref.read(profileSetupProvider.notifier).setLocation(
            city: _selectedSuggestion!.city,
            country: _selectedSuggestion!.country,
            lat: _selectedSuggestion!.lat,
            lng: _selectedSuggestion!.lng,
          );
    } else if (_gpsCity != null) {
      ref.read(profileSetupProvider.notifier).setLocation(
            city: _gpsCity!,
            country: _gpsCountry ?? '',
            lat: _gpsLat,
            lng: _gpsLng,
          );
    }

    context.go('/setup/interests');
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ProgressBar(currentStep: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.screenHorizontal,
                  right: AppSpacing.screenHorizontal,
                  top: AppSpacing.xxl,
                  bottom: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Where are\nyou located?",
                        style: AppTextStyles.heading2),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'We use this to find events near you',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),

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
                    if (_hasSelection && _suggestions.isEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildSelectedBadge(),
                    ],

                    const Spacer(),

                    FoButton(
                      text: 'Continue',
                      onPressed: _onContinue,
                      enabled: _hasSelection,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                separatorBuilder: (_, __) => const Divider(
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
                  if (suggestion.state != null || suggestion.country.isNotEmpty)
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
              _selectionDisplay ?? '',
              style: AppTextStyles.body.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedSuggestion = null;
                _gpsCity = null;
                _gpsCountry = null;
                _gpsLat = null;
                _gpsLng = null;
                _searchController.clear();
              });
              ref.read(placesServiceProvider).startNewSession();
            },
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

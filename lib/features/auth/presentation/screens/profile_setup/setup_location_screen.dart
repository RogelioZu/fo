import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/fo_button.dart';
import '../../../../../core/widgets/fo_text_field.dart';
import '../../providers/profile_setup_provider.dart';
import '../../widgets/progress_bar.dart';

/// Pantalla de Setup Location — Step 4/6.
/// Usa Geolocator + Geocoding para obtener ubicación real.
class SetupLocationScreen extends ConsumerStatefulWidget {
  const SetupLocationScreen({super.key});

  @override
  ConsumerState<SetupLocationScreen> createState() =>
      _SetupLocationScreenState();
}

class _SetupLocationScreenState extends ConsumerState<SetupLocationScreen> {
  final _searchController = TextEditingController();
  bool _isLoadingGps = false;
  String? _selectedLocation;
  double? _lat;
  double? _lng;
  String? _city;
  String? _country;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onUseGps() async {
    setState(() => _isLoadingGps = true);
    try {
      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Permiso de ubicación denegado permanentemente. Habilítalo en Ajustes.');
      }

      // Obtener posición actual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Geocodificación inversa para obtener ciudad y país
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _city = place.locality ?? place.subAdministrativeArea ?? '';
          _country = place.country ?? '';
          _lat = position.latitude;
          _lng = position.longitude;
          _selectedLocation = '$_city, $_country';
          _isLoadingGps = false;
        });
      } else {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
          _selectedLocation = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
          _isLoadingGps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _onContinue() {
    // Usar GPS o texto manual
    final locationText = _selectedLocation ?? _searchController.text.trim();
    if (locationText.isEmpty) return;

    ref.read(profileSetupProvider.notifier).setLocation(
          city: _city ?? locationText,
          country: _country ?? '',
          lat: _lat,
          lng: _lng,
        );

    context.go('/setup/interests');
  }

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
                    SizedBox(
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
                          _selectedLocation ?? 'Use my current location',
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
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Divider "or search manually" ───
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppColors.gray200),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            'or search manually',
                            style: AppTextStyles.caption,
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppColors.gray200),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Search Input ───
                    FoTextField(
                      hintText: 'Search city or address',
                      prefixIcon: PhosphorIconsRegular.magnifyingGlass,
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                    ),

                    const Spacer(),

                    FoButton(
                      text: 'Continue',
                      onPressed: _onContinue,
                      enabled: _selectedLocation != null ||
                          _searchController.text.trim().isNotEmpty,
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
}

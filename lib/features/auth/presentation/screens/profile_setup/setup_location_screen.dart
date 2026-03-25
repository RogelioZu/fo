import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/fo_button.dart';
import '../../../../../core/widgets/location_selector.dart';
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
  LocationData? _selectedLocation;

  void _onLocationSelected(LocationData data) {
    setState(() => _selectedLocation = data);
  }

  void _onContinue() {
    if (_selectedLocation == null) return;

    ref.read(profileSetupProvider.notifier).setLocation(
          city: _selectedLocation!.city,
          country: _selectedLocation!.country,
          lat: _selectedLocation!.lat,
          lng: _selectedLocation!.lng,
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
                    Expanded(
                      child: SingleChildScrollView(
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

                            // ─── Location Selector ───
                            LocationSelector(
                              onLocationSelected: _onLocationSelected,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FoButton(
                      text: 'Continue',
                      onPressed: _onContinue,
                      enabled: _selectedLocation != null,
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

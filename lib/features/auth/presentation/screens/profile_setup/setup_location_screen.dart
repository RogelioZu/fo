import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/fo_button.dart';
import '../../../../../core/widgets/fo_text_field.dart';
import '../../widgets/progress_bar.dart';

/// Pantalla de Setup Location — Step 4/6.
/// Diseño: z2qVf — GPS button + manual search input.
class SetupLocationScreen extends StatefulWidget {
  const SetupLocationScreen({super.key});

  @override
  State<SetupLocationScreen> createState() => _SetupLocationScreenState();
}

class _SetupLocationScreenState extends State<SetupLocationScreen> {
  final _searchController = TextEditingController();
  bool _isLoadingGps = false;
  String? _selectedLocation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onUseGps() async {
    setState(() => _isLoadingGps = true);
    try {
      // TODO: conectar con geolocator + geocoding
      await Future.delayed(const Duration(seconds: 1)); // placeholder
      if (!mounted) return;
      setState(() {
        _selectedLocation = 'Monterrey, Mexico'; // placeholder
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

  void _onContinue() {
    if (_selectedLocation == null && _searchController.text.trim().isEmpty) {
      return;
    }
    // TODO: guardar en provider → navegar a /setup/interests
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

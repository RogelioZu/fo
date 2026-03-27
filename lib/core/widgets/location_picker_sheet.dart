import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/selected_location_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'location_selector.dart';

/// Bottom sheet para cambiar la ubicación activa.
/// Permite usar GPS o buscar una ciudad manualmente.
class LocationPickerSheet extends ConsumerWidget {
  const LocationPickerSheet({super.key});

  /// Muestra el bottom sheet y retorna true si se cambió la ubicación.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentLocation = ref.watch(selectedLocationProvider);

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: AppSpacing.lg),

              // ─── Title ───
              Text('Change location', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Events will update based on your location',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Current location badge ───
              if (currentLocation != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: AppRadius.chipRadius,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          currentLocation.country.isNotEmpty
                              ? '${currentLocation.city}, ${currentLocation.country}'
                              : currentLocation.city,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      Text(
                        'Current',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ─── Location Selector (shared widget) ───
              LocationSelector(
                showSelectedBadge: false,
                onLocationSelected: (data) {
                  ref.read(selectedLocationProvider.notifier).setLocation(
                        city: data.city,
                        country: data.country,
                        lat: data.lat,
                        lng: data.lng,
                      );
                  Navigator.pop(context, true);
                },
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

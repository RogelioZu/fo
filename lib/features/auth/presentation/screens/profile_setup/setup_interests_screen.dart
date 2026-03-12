import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/fo_button.dart';
import '../../widgets/interest_chip.dart';
import '../../widgets/progress_bar.dart';

/// Pantalla de Setup Interests — Step 5/6.
/// Diseño: eYJrO — 16 chips categorías, counter, minimum 3.
class SetupInterestsScreen extends StatefulWidget {
  const SetupInterestsScreen({super.key});

  @override
  State<SetupInterestsScreen> createState() => _SetupInterestsScreenState();
}

class _SetupInterestsScreenState extends State<SetupInterestsScreen> {
  final Set<String> _selectedIds = {};

  /// Mapeo de nombre de ícono (String) a IconData de Phosphor.
  static final Map<String, IconData> _iconMap = {
    'musicNote': PhosphorIconsRegular.musicNote,
    'soccerBall': PhosphorIconsRegular.soccerBall,
    'paintBrush': PhosphorIconsRegular.paintBrush,
    'forkKnife': PhosphorIconsRegular.forkKnife,
    'cpu': PhosphorIconsRegular.cpu,
    'maskHappy': PhosphorIconsRegular.maskHappy,
    'camera': PhosphorIconsRegular.camera,
    'gameController': PhosphorIconsRegular.gameController,
    'tree': PhosphorIconsRegular.tree,
    'airplaneTilt': PhosphorIconsRegular.airplaneTilt,
    'graduationCap': PhosphorIconsRegular.graduationCap,
    'martini': PhosphorIconsRegular.martini,
    'bookOpen': PhosphorIconsRegular.bookOpen,
    'scales': PhosphorIconsRegular.scales,
    'filmStrip': PhosphorIconsRegular.filmStrip,
    'tShirt': PhosphorIconsRegular.tShirt,
  };

  void _toggleInterest(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _onContinue() {
    if (_selectedIds.length < AppConstants.minInterests) return;
    // TODO: guardar en provider → navegar a /setup/photo
  }

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.interestCategories;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ProgressBar(currentStep: 5),
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
                    Text("What are you\ninterested in?",
                        style: AppTextStyles.heading2),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Pick at least ${AppConstants.minInterests} categories',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.lg20),

                    // ─── Chips ───
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: categories.map((cat) {
                            final id = cat['id']!;
                            final name = cat['name']!;
                            final iconName = cat['icon']!;
                            return InterestChip(
                              label: name,
                              icon: _iconMap[iconName] ??
                                  PhosphorIconsRegular.star,
                              isSelected: _selectedIds.contains(id),
                              onTap: () => _toggleInterest(id),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Counter ───
                    Center(
                      child: Text(
                        '${_selectedIds.length} of ${categories.length} selected (minimum ${AppConstants.minInterests})',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    FoButton(
                      text: 'Continue',
                      onPressed: _onContinue,
                      enabled:
                          _selectedIds.length >= AppConstants.minInterests,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/fo_button.dart';
import '../../providers/profile_setup_provider.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/date_selector.dart';

/// Pantalla de Setup Birthday — Step 3/6.
/// Guarda la fecha de nacimiento en ProfileSetupNotifier.
class SetupBirthdayScreen extends ConsumerStatefulWidget {
  const SetupBirthdayScreen({super.key});

  @override
  ConsumerState<SetupBirthdayScreen> createState() =>
      _SetupBirthdayScreenState();
}

class _SetupBirthdayScreenState extends ConsumerState<SetupBirthdayScreen> {
  DateTime? _selectedDate;

  void _onContinue() {
    if (_selectedDate == null) return;

    ref.read(profileSetupProvider.notifier).setBirthday(_selectedDate!);
    context.go('/setup/location');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ProgressBar(currentStep: 3),
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
                    Text("When's your\nbirthday?",
                        style: AppTextStyles.heading2),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This helps us personalize your experience',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Date selector
                    DateSelector(
                      onChanged: (date) {
                        setState(() => _selectedDate = date);
                      },
                    ),

                    const Spacer(),

                    FoButton(
                      text: 'Continue',
                      onPressed: _onContinue,
                      enabled: _selectedDate != null,
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

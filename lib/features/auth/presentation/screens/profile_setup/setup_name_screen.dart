import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/fo_button.dart';
import '../../../../../core/widgets/fo_text_field.dart';
import '../../providers/profile_setup_provider.dart';
import '../../widgets/progress_bar.dart';

/// Pantalla de Setup Nombre — Step 1/6.
/// Guarda firstName y lastName en el ProfileSetupNotifier.
class SetupNameScreen extends ConsumerStatefulWidget {
  const SetupNameScreen({super.key});

  @override
  ConsumerState<SetupNameScreen> createState() => _SetupNameScreenState();
}

class _SetupNameScreenState extends ConsumerState<SetupNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref.read(profileSetupProvider.notifier).setName(
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
        );

    context.go('/setup/username');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Progress Bar ───
            const ProgressBar(currentStep: 1),

            // ─── Body ───
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.only(
                            left: AppSpacing.screenHorizontal,
                            right: AppSpacing.screenHorizontal,
                            top: AppSpacing.xxl,
                            bottom: AppSpacing.screenHorizontal + bottomInset,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("What's your\nname?",
                                    style: AppTextStyles.heading2),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  "Let's get to know you better",
                                  style: AppTextStyles.body,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // First name
                                FoTextField(
                                  hintText: 'First name',
                                  prefixIcon: PhosphorIconsRegular.user,
                                  controller: _firstNameController,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.name,
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Last name
                                FoTextField(
                                  hintText: 'Last name',
                                  prefixIcon: PhosphorIconsRegular.user,
                                  controller: _lastNameController,
                                  textInputAction: TextInputAction.done,
                                  validator: Validators.name,
                                ),

                                const Spacer(),

                                FoButton(
                                  text: 'Continue',
                                  onPressed: _onContinue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

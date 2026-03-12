import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/fo_button.dart';
import '../../../../../core/widgets/fo_text_field.dart';
import '../../widgets/progress_bar.dart';

/// Pantalla de Setup Username — Step 2/6.
/// Diseño: 3hpye — @username input con validación real-time.
class SetupUsernameScreen extends StatefulWidget {
  const SetupUsernameScreen({super.key});

  @override
  State<SetupUsernameScreen> createState() => _SetupUsernameScreenState();
}

class _SetupUsernameScreenState extends State<SetupUsernameScreen> {
  final _usernameController = TextEditingController();
  Timer? _debounce;
  bool? _isAvailable;
  bool _isChecking = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    setState(() {
      _isAvailable = null;
      _isChecking = false;
    });

    if (Validators.username(value) != null) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsername(value);
    });
  }

  Future<void> _checkUsername(String username) async {
    setState(() => _isChecking = true);
    try {
      // TODO: conectar con provider → isUsernameAvailable
      await Future.delayed(const Duration(milliseconds: 500)); // placeholder
      if (!mounted) return;
      setState(() {
        _isAvailable = true; // placeholder
        _isChecking = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _isChecking = false;
        });
      }
    }
  }

  void _onContinue() {
    if (_isAvailable != true) return;
    // TODO: guardar en provider → navegar a /setup/birthday
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ProgressBar(currentStep: 2),
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
                    Text("Choose a\nusername",
                        style: AppTextStyles.heading2),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This is how others will find you',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Username input
                    FoTextField(
                      hintText: 'username',
                      prefixIcon: PhosphorIconsRegular.at,
                      controller: _usernameController,
                      onChanged: _onUsernameChanged,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Validation indicator
                    if (_isChecking)
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Checking availability...',
                            style: AppTextStyles.small,
                          ),
                        ],
                      )
                    else if (_isAvailable == true)
                      Row(
                        children: [
                          const Icon(
                            PhosphorIconsBold.checkCircle,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Username is available!',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      )
                    else if (_isAvailable == false)
                      Row(
                        children: [
                          const Icon(
                            PhosphorIconsBold.xCircle,
                            color: AppColors.error,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Username is already taken',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    FoButton(
                      text: 'Continue',
                      onPressed: _onContinue,
                      enabled: _isAvailable == true,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/fo_button.dart';
import '../../../../core/widgets/fo_text_field.dart';
import '../../../../core/widgets/fo_top_nav.dart';

/// Pantalla de olvidé contraseña de Finding Out.
/// Diseño: l1Nra — email input + send code button.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      // TODO: conectar con auth provider → sendPasswordReset
      await Future.delayed(const Duration(seconds: 1)); // placeholder
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se envió un enlace de recuperación a tu email'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.screenTop,
            bottom: AppSpacing.screenBottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Top Nav ───
                FoTopNav(
                  onBack: () => context.go('/login'),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Título ───
                Text('Forgot\npassword?', style: AppTextStyles.heading1),
                const SizedBox(height: AppSpacing.sm),

                // ─── Descripción ───
                Text(
                  "Don't worry! It happens. Please enter the\nemail associated with your account.",
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Email ───
                FoLabeledInput(
                  label: 'Email address',
                  hintText: 'hello@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                ),

                const Spacer(),

                // ─── Send Code Button ───
                FoButton(
                  text: 'Send code',
                  onPressed: _onSendCode,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

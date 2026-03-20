import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/fo_button.dart';
import '../../../../core/widgets/fo_text_field.dart';
import '../../../../core/widgets/fo_top_nav.dart';
import '../providers/auth_providers.dart';

/// Pantalla de restablecer contraseña de Finding Out.
/// Conecta con Supabase Auth vía authRepositoryProvider.resetPassword.
/// Después de un reset exitoso, cierra la sesión temporal de recuperación
/// para que el usuario inicie sesión con su nueva contraseña.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            _passwordController.text,
          );

      if (!mounted) return;

      // Cerrar la sesión temporal de recuperación
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña restablecida exitosamente')),
      );
      context.go('/login');
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error inesperado. Intenta de nuevo.')),
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
                Text('Reset\npassword', style: AppTextStyles.heading1),
                const SizedBox(height: AppSpacing.sm),

                // ─── Descripción ───
                Text(
                  "Please type something you'll remember",
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── New Password ───
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New password', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    FoTextField(
                      hintText: 'Must be 8+ characters',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(
                              () => _obscurePassword = !_obscurePassword);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            _obscurePassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: AppColors.placeholder,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ─── Confirm New Password ───
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirm new password', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    FoTextField(
                      hintText: 'Repeat your password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() => _obscureConfirmPassword =
                              !_obscureConfirmPassword);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            _obscureConfirmPassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: AppColors.placeholder,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // ─── Reset Button ───
                FoButton(
                  text: 'Reset Password',
                  onPressed: _onResetPassword,
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

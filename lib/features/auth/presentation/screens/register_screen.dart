import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/fo_button.dart';
import '../../../../core/widgets/fo_text_field.dart';
import '../../../../core/widgets/fo_top_nav.dart';
import '../../../../core/config/router.dart';
import '../providers/auth_providers.dart';

/// Pantalla de Registro de Finding Out.
/// Conecta con Supabase Auth vía authRepositoryProvider.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      // Invalidar cache de perfil para evitar que se use el de una sesión anterior
      AppRouter.invalidateProfileCache();

      await ref.read(authRepositoryProvider).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      // Navegar a verificación de email
      context.go('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}');
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
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
                    // ─── Top Navigation ───
                    FoTopNav(
                      onBack: () => context.go('/splash'),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Título ───
                    Text('Sign up', style: AppTextStyles.heading1),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Email ───
                    FoLabeledInput(
                      label: 'Email address',
                      hintText: 'hello@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Create Password ───
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create a password', style: AppTextStyles.label),
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

                    // ─── Confirm Password ───
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Confirm password', style: AppTextStyles.label),
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
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Register Button (fix: decía "Log in", ahora dice "Sign up") ───
                    FoButton(
                      text: 'Sign up',
                      onPressed: _onRegister,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 64),

                    // ─── Footer ───
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: AppTextStyles.caption,
                            children: [
                              TextSpan(
                                text: 'Log in',
                                style: AppTextStyles.link.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

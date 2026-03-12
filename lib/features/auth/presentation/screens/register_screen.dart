import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/fo_button.dart';
import '../../../../core/widgets/fo_text_field.dart';
import '../../../../core/widgets/fo_top_nav.dart';

/// Pantalla de Registro de Finding Out.
/// Diseño: LxKqO — email + create password + confirm password, eye toggles.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
      // TODO: conectar con auth provider en Paso 14
      await Future.delayed(const Duration(seconds: 1)); // placeholder
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

                    // ─── Email (sin prefix icon) ───
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

                    // ─── Register Button (text says "Log in" per design) ───
                    FoButton(
                      text: 'Log in',
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

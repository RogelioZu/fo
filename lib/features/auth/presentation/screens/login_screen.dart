import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/fo_button.dart';
import '../../../../core/widgets/fo_text_field.dart';
import '../../../../core/widgets/fo_top_nav.dart';
import '../widgets/social_login_row.dart';

/// Pantalla de Login de Finding Out.
/// Diseño: RT64G — email + password (sin prefix icons), social buttons, forgot password link.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
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
                    Text('Log in', style: AppTextStyles.heading1),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Email (sin prefix icon, como en el diseño) ───
                    FoLabeledInput(
                      label: 'Email address',
                      hintText: 'hello@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Password ───
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        FoTextField(
                          hintText: '••••••••',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() =>
                                  _obscurePassword = !_obscurePassword);
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => context.go('/forgot-password'),
                            child: Text(
                              'Forgot password?',
                              style: AppTextStyles.link,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Login Button ───
                    FoButton(
                      text: 'Log in',
                      onPressed: _onLogin,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Divider "Or Log in with" ───
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
                            'Or Log in with',
                            style: AppTextStyles.caption,
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppColors.gray200),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Social Buttons (Facebook, G, Apple) ───
                    SocialLoginRow(
                      onFacebook: () {
                        // TODO: Facebook login
                      },
                      onGoogle: () {
                        // TODO: Google login
                      },
                      onApple: () {
                        // TODO: Apple login
                      },
                    ),

                    const SizedBox(height: 64),

                    // ─── Footer ───
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/register'),
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: AppTextStyles.caption,
                            children: [
                              TextSpan(
                                text: 'Sign up',
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

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
import '../../../../core/services/location_service.dart';
import '../providers/auth_providers.dart';
import '../widgets/social_login_row.dart';

/// Pantalla de Login de Finding Out.
/// Conecta con Supabase Auth vía authRepositoryProvider.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateLocationInBackground() {
    LocationService.requestAndResolveLocation().then((loc) {
      if (loc != null) {
        ref.read(authRepositoryProvider).updateProfile(
              lat: loc.lat,
              lng: loc.lng,
              city: loc.city,
              country: loc.country,
            );
      }
    });
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authRepositoryProvider).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      // Si el perfil no está completo → ir a setup
      if (!user.profileComplete) {
        context.go('/setup/name');
      } else {
        // Request location and update profile in background
        _updateLocationInBackground();
        context.go('/home');
      }
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

  /// Handler genérico para login social (Google / Apple).
  Future<void> _onSocialLogin({
    required Future<dynamic> Function() signIn,
    required void Function(bool) setLoading,
  }) async {
    setLoading(true);
    try {
      final user = await signIn();

      if (!mounted) return;

      if (!user.profileComplete) {
        context.go('/setup/name');
      } else {
        _updateLocationInBackground();
        context.go('/home');
      }
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
      if (mounted) setLoading(false);
    }
  }

  void _onGoogleLogin() => _onSocialLogin(
        signIn: () => ref.read(authRepositoryProvider).signInWithGoogle(),
        setLoading: (v) => setState(() => _isGoogleLoading = v),
      );

  void _onAppleLogin() => _onSocialLogin(
        signIn: () => ref.read(authRepositoryProvider).signInWithApple(),
        setLoading: (v) => setState(() => _isAppleLoading = v),
      );

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

                    // ─── Social Buttons ───
                    SocialLoginRow(
                      onFacebook: () {
                        // TODO: Facebook login — requiere Facebook Developer App
                      },
                      onGoogle: _isGoogleLoading ? null : _onGoogleLogin,
                      onApple: _isAppleLoading ? null : _onAppleLogin,
                      isGoogleLoading: _isGoogleLoading,
                      isAppleLoading: _isAppleLoading,
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

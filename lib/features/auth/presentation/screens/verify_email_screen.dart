import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/fo_button.dart';
import '../../../../core/widgets/fo_top_nav.dart';
import '../../../../core/config/router.dart';
import '../providers/auth_providers.dart';
import '../widgets/otp_input.dart';

/// Pantalla de verificación de email de Finding Out.
/// Conecta con Supabase Auth vía authRepositoryProvider.verifyOtp.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  String _otpCode = '';
  bool _isLoading = false;
  int _resendTimer = AppConstants.otpResendTimerSec;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = AppConstants.otpResendTimerSec;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedTimer {
    final minutes = (_resendTimer ~/ 60).toString().padLeft(2, '0');
    final seconds = (_resendTimer % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _onVerify() async {
    if (_otpCode.length != AppConstants.otpLength) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
            widget.email,
            _otpCode,
          );

      if (!mounted) return;

      // Invalidar cache para que el router use el perfil del nuevo usuario
      AppRouter.invalidateProfileCache();

      // Email verificado → ir al setup de perfil
      context.go('/setup/name');
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

  Future<void> _onResend() async {
    if (_resendTimer > 0) return;
    try {
      // Reenvía el OTP de confirmación de signup
      final client = ref.read(supabaseClientProvider);
      await client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );

      _startResendTimer();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado a tu email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reenviar: $e')),
      );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top Nav ───
              FoTopNav(
                onBack: () => context.go('/register'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Título ───
              Text(
                'Please check\nyour email',
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ─── Subtítulo ───
              Text(
                "We've sent a code to ${widget.email}",
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── OTP Input ───
              OtpInput(
                onCompleted: (code) {
                  _otpCode = code;
                  _onVerify();
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Verify Button ───
              FoButton(
                text: 'Verify',
                onPressed: _onVerify,
                isLoading: _isLoading,
              ),

              const Spacer(),

              // ─── Resend Timer ───
              Center(
                child: GestureDetector(
                  onTap: _resendTimer == 0 ? _onResend : null,
                  child: Text(
                    _resendTimer > 0
                        ? 'Send code again $_formattedTimer'
                        : 'Send code again',
                    style: AppTextStyles.link.copyWith(
                      color: _resendTimer > 0
                          ? AppColors.secondaryText
                          : AppColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

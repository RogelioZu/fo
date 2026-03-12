import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/fo_button.dart';

/// Pantalla de bienvenida de Finding Out.
/// Diseño: IAMJa — ícono sparkles, botones Sign in + Create account.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ─── Ícono sparkles ───
              const Icon(
                PhosphorIconsBold.sparkle,
                size: 64,
                color: AppColors.black,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Título ───
              Text(
                'Explore the app',
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ─── Descripción ───
              Text(
                'Find events near you, connect with people\nand personalize your experience.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // ─── Botón Sign in ───
              FoButton(
                text: 'Sign in',
                onPressed: () {
                  // TODO: navegar a /login con GoRouter
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Botón Create account ───
              FoButton(
                text: 'Create account',
                isOutlined: true,
                onPressed: () {
                  // TODO: navegar a /register con GoRouter
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

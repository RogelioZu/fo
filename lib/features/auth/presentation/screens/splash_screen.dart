import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/fo_button.dart';

/// Pantalla de bienvenida de Finding Out.
/// Diseño: IAMJa — ícono sparkles, título "Finding Out", botones Sign in + Create account.
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

              // ─── Ícono sparkles (lucide) ───
              const Icon(
                LucideIcons.sparkles,
                size: 64,
                color: AppColors.black,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Título ───
              Text(
                'Finding Out',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ─── Descripción ───
              Text(
                'Now your events are in one place\nand always under control',
                style: AppTextStyles.caption.copyWith(
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // ─── Botón Sign in ───
              FoButton(
                text: 'Sign in',
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Botón Create account ───
              FoButton(
                text: 'Create account',
                isOutlined: true,
                onPressed: () => context.go('/register'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

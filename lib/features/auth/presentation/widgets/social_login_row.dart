import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Fila de 3 botones de login social (icon-only, same width).
/// Con splash ink effect y feedback háptico.
class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({
    super.key,
    this.onGoogle,
    this.onApple,
    this.onFacebook,
    this.onPhone,
    this.isGoogleLoading = false,
    this.isAppleLoading = false,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onFacebook;
  final VoidCallback? onPhone;
  final bool isGoogleLoading;
  final bool isAppleLoading;

  Widget _buildSocialButton({
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: AppColors.white,
        borderRadius: AppRadius.cardRadius,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          borderRadius: AppRadius.cardRadius,
          splashColor: AppColors.gray100,
          highlightColor: AppColors.gray50,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.inputBorder),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSocialButton(
          child: const Icon(LucideIcons.facebook,
              size: 24, color: AppColors.black),
          onTap: onFacebook,
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          child: Text(
            'G',
            style: AppTextStyles.heading3.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          onTap: onGoogle,
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          child:
              const Icon(LucideIcons.apple, size: 24, color: AppColors.black),
          onTap: onApple,
        ),
      ],
    );
  }
}

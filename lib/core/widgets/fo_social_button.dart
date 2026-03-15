import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Botón de login social de Finding Out.
/// H: 56, borde, radius 16, splash ink effect y feedback háptico.
class FoSocialButton extends StatelessWidget {
  const FoSocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: AppColors.white,
        borderRadius: AppRadius.cardRadius,
        child: InkWell(
          onTap: isLoading
              ? null
              : onPressed != null
                  ? () {
                      HapticFeedback.selectionClick();
                      onPressed!();
                    }
                  : null,
          borderRadius: AppRadius.cardRadius,
          splashColor: AppColors.gray100,
          highlightColor: AppColors.gray50,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.gray200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.black,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 24, height: 24, child: icon),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

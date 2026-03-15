import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Botón primario reutilizable de Finding Out.
/// Pill shape (radius 100), fondo negro, altura 56.
/// Animación de escala al presionar y feedback háptico.
class FoButton extends StatefulWidget {
  const FoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool enabled;

  @override
  State<FoButton> createState() => _FoButtonState();
}

class _FoButtonState extends State<FoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  bool get _active => widget.enabled && !widget.isLoading;

  void _handleTap() {
    if (!_active) return;
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _active ? (_) => _scaleCtrl.forward() : null,
      onTapUp: _active ? (_) => _scaleCtrl.reverse() : null,
      onTapCancel: _active ? () => _scaleCtrl.reverse() : null,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.isOutlined
                ? AppColors.white
                : (_active ? AppColors.black : AppColors.gray400),
            borderRadius: AppRadius.pillRadius,
            border: widget.isOutlined
                ? Border.all(color: AppColors.gray200)
                : null,
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: widget.isOutlined
                          ? AppColors.black
                          : AppColors.white,
                    ),
                  )
                : Text(
                    widget.text,
                    key: ValueKey(widget.text),
                    style: AppTextStyles.buttonText.copyWith(
                      color: widget.isOutlined
                          ? AppColors.black
                          : AppColors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Barra de búsqueda reutilizable de Finding Out.
/// Estilo: fondo blanco, pill shape, sombra suave.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Search events, venues...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onBack,
    this.showBackArrow = false,
    this.textInputAction,
  });

  /// Controlador del campo de texto.
  final TextEditingController controller;

  /// Nodo de foco para controlar el teclado.
  final FocusNode focusNode;

  /// Texto placeholder cuando el campo está vacío.
  final String hintText;

  /// Callback al cambiar el texto (cada carácter).
  final ValueChanged<String>? onChanged;

  /// Callback al enviar la búsqueda (tecla enter/search).
  final ValueChanged<String>? onSubmitted;

  /// Callback al presionar el botón de limpiar (X).
  final VoidCallback? onClear;

  /// Callback al presionar la flecha de regreso.
  final VoidCallback? onBack;

  /// Si es true, muestra una flecha de regreso en lugar del ícono de búsqueda.
  final bool showBackArrow;

  /// Acción del teclado (search, done, etc.).
  final TextInputAction? textInputAction;

  // ─── Estilos cacheados ───
  static final _inputStyle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  static final _hintStyle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.gray400,
  );

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 8),
                blurRadius: 32,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
        children: [
          // ─── Leading icon ───
          GestureDetector(
            onTap: showBackArrow ? onBack : null,
            child: Icon(
              showBackArrow ? LucideIcons.arrowLeft : LucideIcons.search,
              size: 20,
              color: showBackArrow ? AppColors.black : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 12),

          // ─── Input ───
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: textInputAction,
              style: _inputStyle,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: _hintStyle,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),

          // ─── Clear button ───
          if (hasText && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(LucideIcons.x, size: 18, color: AppColors.gray400),
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }
}

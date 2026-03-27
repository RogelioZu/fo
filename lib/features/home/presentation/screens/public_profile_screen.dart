import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Pantalla de perfil público de un usuario.
/// Muestra la información básica de cualquier usuario, sin botones de editar/logout.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(publicProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (_, __) => SafeArea(
          child: Column(
            children: [
              // Top bar con back
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('Error al cargar el perfil'),
                ),
              ),
            ],
          ),
        ),
        data: (user) {
          if (user == null) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: SizedBox(
                      height: 64,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.arrowLeft),
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Usuario no encontrado'),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              // ─── Top Bar con back ───
              SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            LucideIcons.arrowLeft,
                            color: AppColors.black,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        Text(
                          'Perfil',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // Balance visual
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Header: Avatar + Info ───
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    // Avatar
                    ClipOval(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: user.avatarUrl != null &&
                                user.avatarUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.gray100,
                                  child: const Icon(
                                    LucideIcons.user,
                                    size: 48,
                                    color: AppColors.gray400,
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.gray100,
                                  child: const Icon(
                                    LucideIcons.user,
                                    size: 48,
                                    color: AppColors.gray400,
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.gray100,
                                child: const Icon(
                                  LucideIcons.user,
                                  size: 48,
                                  color: AppColors.gray400,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.ms),

                    // Nombre
                    Text(
                      user.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Username + Ciudad
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (user.username != null)
                          Text(
                            '@${user.username}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppColors.gray500,
                            ),
                          ),
                        if (user.city != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 14,
                                  color: AppColors.gray500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.city!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Bio
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.ms),
                      SizedBox(
                        width: 300,
                        child: Text(
                          user.bio!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ─── Stats ───
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatCircle(
                      value: '0',
                      label: 'Attended',
                      color: Color(0xFF3B82F6),
                    ),
                    _StatCircle(
                      value: '0',
                      label: 'Created',
                      color: Color(0xFF10B981),
                    ),
                    _StatCircle(
                      value: '0',
                      label: 'Connections',
                      color: Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),

              // ─── Achievements ───
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        'Achievements',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        children: const [
                          _BadgeItem(
                            icon: LucideIcons.partyPopper,
                            label: 'First event',
                            bgColor: Color(0xFFF3F4F6),
                            iconColor: Color(0xFF9CA3AF),
                            locked: true,
                          ),
                          SizedBox(width: AppSpacing.md),
                          _BadgeItem(
                            icon: LucideIcons.flame,
                            label: '5x Streak',
                            bgColor: Color(0xFFF3F4F6),
                            iconColor: Color(0xFF9CA3AF),
                            locked: true,
                          ),
                          SizedBox(width: AppSpacing.md),
                          _BadgeItem(
                            icon: LucideIcons.lock,
                            label: 'Top Creator',
                            bgColor: Color(0xFFF3F4F6),
                            iconColor: Color(0xFF9CA3AF),
                            locked: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Interests ───
              if (user.interests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interests',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: user.interests.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              interest,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.black,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Widgets privados ───

class _StatCircle extends StatelessWidget {
  const _StatCircle({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 28, color: iconColor),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: 80,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: locked ? AppColors.gray400 : AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}

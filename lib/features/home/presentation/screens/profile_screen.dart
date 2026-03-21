import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/config/router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Pantalla de perfil del usuario.
/// Muestra la información del usuario autenticado y secciones de eventos vacías.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (_, __) => Center(
          child: Text('Error loading profile', style: AppTextStyles.body),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.black),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              // ─── Top Bar ───
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _IconBtn(
                          icon: LucideIcons.settings,
                          onTap: () {
                            // TODO: Settings screen
                          },
                        ),
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

                    // Name
                    Text(
                      user.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Username + Location
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
                    const SizedBox(height: AppSpacing.md),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PillButton(
                          label: 'Edit profile',
                          filled: true,
                          onTap: () {
                            context.push('/edit-profile');
                          },
                        ),
                        const SizedBox(width: AppSpacing.ms),
                        _PillButton(
                          label: 'Share',
                          filled: false,
                          onTap: () {
                            // TODO: Share profile
                          },
                        ),
                      ],
                    ),
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
                padding: const EdgeInsets.fromLTRB(
                  0,
                  0,
                  0,
                  AppSpacing.lg,
                ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Interests',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
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

              // ─── Upcoming events ───
              _EmptyEventSection(title: 'Upcoming events'),

              // ─── Past events ───
              _EmptyEventSection(title: 'Past events', showSeeAll: true),

              // ─── Created events ───
              _EmptyEventSection(title: 'Created events'),

              // ─── Footer ───
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                child: Column(
                  children: [
                    _LogOutButton(ref: ref),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'By Retas',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray400,
                      ),
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

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        customBorder: const CircleBorder(),
        splashColor: AppColors.gray100,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.black, size: 24),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: filled ? AppColors.black : AppColors.gray100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: filled ? AppColors.white : AppColors.black,
          ),
        ),
      ),
    );
  }
}

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
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
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

class _EmptyEventSection extends StatelessWidget {
  const _EmptyEventSection({
    required this.title,
    this.showSeeAll = false,
  });

  final String title;
  final bool showSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              if (showSeeAll)
                Text(
                  'See all',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 28,
                  color: AppColors.gray200,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No events yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogOutButton extends StatefulWidget {
  const _LogOutButton({required this.ref});

  final WidgetRef ref;

  @override
  State<_LogOutButton> createState() => _LogOutButtonState();
}

class _LogOutButtonState extends State<_LogOutButton> {
  bool _loading = false;

  Future<void> _handleLogOut() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Log out',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out?',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Log out',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);

    // Capture router before await — the widget will be unmounted
    // when signOut triggers the auth stream and ProfileScreen rebuilds.
    final router = GoRouter.of(context);

    try {
      await widget.ref.read(authRepositoryProvider).signOut();
      AppRouter.invalidateProfileCache();
      router.go('/splash');
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not log out. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _handleLogOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 24,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            : Text(
                'Log out',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
      ),
    );
  }
}


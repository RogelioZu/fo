import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Pantalla de edición de perfil.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  String? _originalUsername;
  String? _avatarUrl;
  File? _newAvatarFile;
  bool _saving = false;

  // Username validation
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final value = _usernameController.text.trim().toLowerCase();

    // If same as original, no need to check
    if (value == _originalUsername) {
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = null;
      });
      return;
    }

    if (value.length < 3) {
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = null;
      });
      return;
    }

    setState(() => _checkingUsername = true);

    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final repo = ref.read(authRepositoryProvider);
      final available = await repo.isUsernameAvailable(value);
      if (mounted && _usernameController.text.trim().toLowerCase() == value) {
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = available;
        });
      }
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: Text('Camera', style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: Text('Gallery', style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => _newAvatarFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim().toLowerCase();

    // Validate username uniqueness
    if (username != _originalUsername && username.length >= 3) {
      if (_checkingUsername) return;
      if (_usernameAvailable == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Username already taken'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(authRepositoryProvider);

      // Upload new avatar if selected
      if (_newAvatarFile != null) {
        await repo.uploadAvatar(_newAvatarFile!.path);
      }

      // Parse name into first/last
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : null;

      await repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username.isNotEmpty ? username : null,
        bio: _bioController.text.trim(),
      );

      // Refresh user data
      ref.invalidate(currentUserProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (_, __) => const Center(child: Text('Error loading profile')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          // Initialize controllers only once
          if (_originalUsername == null) {
            _nameController.text = user.displayName;
            _usernameController.text = user.username ?? '';
            _bioController.text = user.bio ?? '';
            _avatarUrl = user.avatarUrl;
            _originalUsername = user.username?.toLowerCase() ?? '';
          }

          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          return Column(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.pop();
                          },
                          child: const Icon(
                            LucideIcons.chevronLeft,
                            color: AppColors.black,
                            size: 24,
                          ),
                        ),
                        Text(
                          'Edit profile',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: _saving ? null : () {
                            HapticFeedback.selectionClick();
                            _save();
                          },
                          child: _saving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.black,
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.check,
                                  color: AppColors.black,
                                  size: 24,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Content ───
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(bottom: 120 + bottomInset),
                  children: [
                    // ─── Photo Section ───
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickAvatar,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipOval(
                                  child: SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: _newAvatarFile != null
                                        ? Image.file(
                                            _newAvatarFile!,
                                            fit: BoxFit.cover,
                                          )
                                        : (_avatarUrl != null &&
                                                _avatarUrl!.isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl: _avatarUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) =>
                                                    Container(
                                                  color: AppColors.gray100,
                                                  child: const Icon(
                                                    LucideIcons.user,
                                                    size: 40,
                                                    color: AppColors.gray400,
                                                  ),
                                                ),
                                                errorWidget: (_, __, ___) =>
                                                    Container(
                                                  color: AppColors.gray100,
                                                  child: const Icon(
                                                    LucideIcons.user,
                                                    size: 40,
                                                    color: AppColors.gray400,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: AppColors.gray100,
                                                child: const Icon(
                                                  LucideIcons.user,
                                                  size: 40,
                                                  color: AppColors.gray400,
                                                ),
                                              ),
                                  ),
                                ),
                                // Dark overlay
                                ClipOval(
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    color: const Color(0x80000000),
                                    child: const Icon(
                                      LucideIcons.camera,
                                      size: 32,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.ms),
                          GestureDetector(
                            onTap: _pickAvatar,
                            child: Text(
                              'Change photo',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Form Fields ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          _FormField(
                            label: 'Name',
                            controller: _nameController,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _FormField(
                            label: 'Username',
                            controller: _usernameController,
                            suffix: _buildUsernameSuffix(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _FormField(
                            label: 'Bio',
                            controller: _bioController,
                            maxLines: 4,
                            height: 100,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Bottom Bar ───
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: GestureDetector(
                    onTap: _saving ? null : () {
                      HapticFeedback.lightImpact();
                      _save();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(31),
                      ),
                      alignment: Alignment.center,
                      child: _saving
                          ? const CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            )
                          : Text(
                              'Save changes',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildUsernameSuffix() {
    final value = _usernameController.text.trim().toLowerCase();
    if (value == _originalUsername || value.length < 3) return null;

    if (_checkingUsername) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gray400),
      );
    }

    if (_usernameAvailable == true) {
      return const Icon(LucideIcons.checkCircle, size: 20, color: Color(0xFF10B981));
    }
    if (_usernameAvailable == false) {
      return const Icon(LucideIcons.xCircle, size: 20, color: Color(0xFFEF4444));
    }

    return null;
  }
}

// ─── Form Field Widget ───

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.height,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final double? height;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: InputBorder.none,
              suffixIcon: suffix != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: suffix,
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minHeight: 20,
                minWidth: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/config/router.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/fo_button.dart';
import '../../providers/profile_setup_provider.dart';
import '../../widgets/progress_bar.dart';

/// Pantalla de Setup Photo — Step 6/6.
/// Usa ImagePicker para seleccionar foto, sube a Supabase Storage y marca perfil como completo.
class SetupPhotoScreen extends ConsumerStatefulWidget {
  const SetupPhotoScreen({super.key});

  @override
  ConsumerState<SetupPhotoScreen> createState() => _SetupPhotoScreenState();
}

class _SetupPhotoScreenState extends ConsumerState<SetupPhotoScreen> {
  String? _selectedImagePath;
  bool _isLoading = false;
  final _picker = ImagePicker();

  Future<void> _onCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  Future<void> _onGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  Future<void> _onCompleteSetup() async {
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(profileSetupProvider.notifier);

      // Si hay avatar seleccionado, guardarlo en el estado
      if (_selectedImagePath != null) {
        notifier.setAvatarPath(_selectedImagePath!);
      }

      // Enviar todos los datos acumulados a Supabase
      await notifier.submitAll();

      // Invalidar cache del router para que reconozca profile_complete = true
      AppRouter.invalidateProfileCache();

      if (!mounted) return;
      context.go('/home');
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al completar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSkip() async {
    setState(() => _isLoading = true);
    try {
      // Enviar datos sin avatar
      await ref.read(profileSetupProvider.notifier).submitAll();

      AppRouter.invalidateProfileCache();

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ProgressBar(currentStep: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.screenHorizontal,
                  right: AppSpacing.screenHorizontal,
                  top: AppSpacing.xxl,
                  bottom: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Add a profile\nphoto",
                        style: AppTextStyles.heading2),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Help others recognize you',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ─── Avatar Circle ───
                    Center(
                      child: GestureDetector(
                        onTap: _onGallery,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: AppRadius.avatarRadius,
                            border: Border.all(
                              color: AppColors.gray200,
                              width: 2,
                            ),
                          ),
                          child: _selectedImagePath != null
                              ? ClipRRect(
                                  borderRadius: AppRadius.avatarRadius,
                                  child: Image.file(
                                    File(_selectedImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  PhosphorIconsRegular.camera,
                                  size: 48,
                                  color: AppColors.placeholder,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ─── Tap to upload ───
                    Center(
                      child: Text(
                        'Tap to upload',
                        style: AppTextStyles.link.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── Camera + Gallery Buttons ───
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _onCamera,
                              icon: const Icon(
                                PhosphorIconsRegular.camera,
                                size: 20,
                              ),
                              label: Text(
                                'Camera',
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.black,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.gray200,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.chipRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _onGallery,
                              icon: const Icon(
                                PhosphorIconsRegular.image,
                                size: 20,
                              ),
                              label: Text(
                                'Gallery',
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.black,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.gray200,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.chipRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ─── Complete Setup ───
                    FoButton(
                      text: 'Complete Setup',
                      onPressed: _onCompleteSetup,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Skip for now ───
                    Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _onSkip,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Skip for now',
                            style: AppTextStyles.link.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/fo_button.dart';
import '../widgets/onboarding_page.dart';

/// Pantalla de onboarding con PageView de 3 páginas.
/// Diseño: 0GkQF + SzFBb + FWio8.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    {
      'icon': PhosphorIconsRegular.mapPin,
      'title': 'Discover Events\nNear You',
      'description':
          'Find the best events happening around you.\nNever miss out on the fun.',
    },
    {
      'icon': PhosphorIconsRegular.usersThree,
      'title': 'Connect With\nPeople',
      'description':
          'Meet like-minded people who share\nyour interests and passions.',
    },
    {
      'icon': PhosphorIconsRegular.sparkle,
      'title': 'Personalize Your\nExperience',
      'description':
          'Get recommendations tailored to your\ntastes and preferences.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onComplete() async {
    await _markOnboardingSeen();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _onSkip() async {
    await _markOnboardingSeen();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── PageView ───
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return OnboardingPage(
                    icon: page['icon'] as IconData,
                    title: page['title'] as String,
                    description: page['description'] as String,
                  );
                },
              ),
            ),

            // ─── Page indicators ───
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.black : AppColors.gray200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ─── Botones ───
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                children: [
                  FoButton(
                    text: isLastPage ? 'Get Started' : 'Next',
                    onPressed: isLastPage ? _onComplete : _onNext,
                  ),
                  if (!isLastPage) ...[
                    const SizedBox(height: AppSpacing.md),
                    GestureDetector(
                      onTap: _onSkip,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Skip',
                          style: AppTextStyles.link.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

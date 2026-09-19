import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:omnibrain_ai/l10n/app_localizations.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/providers/shared_prefs_provider.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding(String purpose) async {
    setState(() => _isCompleting = true);
    
    // Save purpose to preferences if needed in the future
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('user_purpose', purpose);
    await prefs.setBool('has_seen_onboarding', true);

    // Simulate a loading effect for premium feel
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      context.go(RoutePaths.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const GradientBackground(child: SizedBox.expand()),
          
          SafeArea(
            child: Column(
              children: [
                // Top Progress Indicators
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.neonPurple : Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildPage1(l10n),
                      _buildPage2(l10n),
                      _buildPage3(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isCompleting)
            Container(
              color: AppColors.deepNightBlue.withValues(alpha: 0.8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.neonPurple),
                      const SizedBox(height: 24),
                      Text(
                        l10n.onboardingPreparing,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().fadeIn().shimmer(duration: const Duration(seconds: 2)),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildPage1(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.neonPurple, AppColors.iceBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonPurple.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 60, color: Colors.white),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 48),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n.appName,
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingBody1,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
          const Spacer(),
          _buildNextButton(l10n).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPage2(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureIcon(Icons.mic, AppColors.coralRed, delay: 0),
              const SizedBox(width: 16),
              _buildFeatureIcon(Icons.camera_alt, AppColors.amber, delay: 200),
              const SizedBox(width: 16),
              _buildFeatureIcon(Icons.edit_document, AppColors.softGreen, delay: 400),
            ],
          ),
          const SizedBox(height: 48),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n.onboardingTitle2,
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingBody2,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const Spacer(),
          _buildNextButton(l10n).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPage3(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            l10n.onboardingPurposeTitle,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingPurposeSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 48),
          
          _buildSelectionCard(
            title: l10n.onboardingPurposeWork,
            icon: Icons.work_rounded,
            color: AppColors.neonPurple,
            onTap: () => _completeOnboarding("İş"),
            delay: 400,
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: l10n.onboardingPurposeEducation,
            icon: Icons.school_rounded,
            color: AppColors.iceBlue,
            onTap: () => _completeOnboarding("Eğitim"),
            delay: 500,
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: l10n.onboardingPurposeDaily,
            icon: Icons.wallet_rounded,
            color: AppColors.softGreen,
            onTap: () => _completeOnboarding("Günlük"),
            delay: 600,
          ),
          const Spacer(),
          const SizedBox(height: 80), // Button spacing area
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, Color color, {required int delay}) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ]
      ),
      child: Icon(icon, color: color, size: 32),
    ).animate().scale(delay: delay.ms, duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0),
    );
  }

  Widget _buildNextButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.neonPurple, AppColors.iceBlue],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonPurple.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Text(
          l10n.onboardingNext,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

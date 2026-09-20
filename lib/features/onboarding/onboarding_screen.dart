import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:omnibrain_ai/l10n/app_localizations.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/providers/shared_prefs_provider.dart';
import 'package:omnibrain_ai/core/providers/locale_provider.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/core/widgets/language_selector_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;
  String _selectedPurpose = 'work';

  static const int _totalPages = 5;

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skipToLast() {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    setState(() => _isCompleting = true);

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('user_purpose', _selectedPurpose);
      await prefs.setBool('has_seen_onboarding_v2', true);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      context.go(RoutePaths.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = ref.watch(currentLanguageProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const GradientBackground(child: SizedBox.expand()),

          // Ambient Background Glows
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.iceBlue.withValues(alpha: 0.15),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar (Language Switcher + Indicators + Skip)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // Language Selector Chip
                      GestureDetector(
                        onTap: () => LanguageSelectorSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currentLang.flag, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                currentLang.code.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Segmented Indicators
                      Row(
                        children: List.generate(_totalPages, (index) {
                          final isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: isActive ? 22 : 6,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.neonPurple : Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      const Spacer(),

                      // Skip Button
                      if (_currentPage < _totalPages - 1)
                        TextButton(
                          onPressed: _skipToLast,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.onboardingSkip,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white60,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Main Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildShowcaseSlide(
                        badge: l10n.onboardingFeature1Badge,
                        badgeColor: AppColors.softGreen,
                        title: l10n.onboardingFeature1Title,
                        description: l10n.onboardingFeature1Desc,
                        mockup: _buildScannerMockup(),
                        l10n: l10n,
                      ),
                      _buildShowcaseSlide(
                        badge: l10n.onboardingFeature2Badge,
                        badgeColor: AppColors.iceBlue,
                        title: l10n.onboardingFeature2Title,
                        description: l10n.onboardingFeature2Desc,
                        mockup: _buildAiVoiceMockup(),
                        l10n: l10n,
                      ),
                      _buildShowcaseSlide(
                        badge: l10n.onboardingFeature3Badge,
                        badgeColor: AppColors.neonPurple,
                        title: l10n.onboardingFeature3Title,
                        description: l10n.onboardingFeature3Desc,
                        mockup: _buildDynamicIslandMockup(),
                        l10n: l10n,
                      ),
                      _buildShowcaseSlide(
                        badge: l10n.onboardingFeature4Badge,
                        badgeColor: AppColors.amber,
                        title: l10n.onboardingFeature4Title,
                        description: l10n.onboardingFeature4Desc,
                        mockup: _buildConverterMockup(),
                        l10n: l10n,
                      ),
                      _buildPersonalizationSlide(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay when preparing dashboard
          if (_isCompleting)
            Container(
              color: AppColors.deepNightBlue.withValues(alpha: 0.85),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.neonPurple,
                        strokeWidth: 3,
                      ),
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
            ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Showcase Slide Layout
  // --------------------------------------------------------------------------
  Widget _buildShowcaseSlide({
    required String badge,
    required Color badgeColor,
    required String title,
    required String description,
    required Widget mockup,
    required AppLocalizations l10n,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Mockup Card
          mockup.animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

          const Spacer(flex: 2),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor,
                letterSpacing: 1.1,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 12),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

          const Spacer(flex: 3),

          // Next Button
          _buildActionButton(
            label: l10n.onboardingNext,
            onTap: _nextPage,
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Mockup 1: Document Scanner & Expense Excel
  // --------------------------------------------------------------------------
  Widget _buildScannerMockup() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.softGreen.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.softGreen.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.softGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: AppColors.softGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Taranan Fiş #1084', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('OCR Tespiti Tamamlandı', style: GoogleFonts.inter(fontSize: 11, color: AppColors.softGreen)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('.XLSX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildExpenseRow('İş Toplantı Yemeği', '₺850.00'),
                    const SizedBox(height: 6),
                    _buildExpenseRow('Taksi & Ulaşım Fişi', '₺320.00'),
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Toplam Masraf:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                        Text('₺1,170.00', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.softGreen)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
        Text(price, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Mockup 2: AI Voice Assistant & Notes
  // --------------------------------------------------------------------------
  Widget _buildAiVoiceMockup() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.iceBlue.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded, color: AppColors.iceBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Haftalık Strateji Toplantısı', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('08:42 • Ses Kaydı', style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Waveform Bars Mock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [12, 28, 40, 20, 36, 16, 32, 24, 44, 20, 14].map((height) {
                  return Container(
                    width: 4,
                    height: height.toDouble(),
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.iceBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.iceBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI: 3 temel eylem maddesi ve bütçe onayı notlara eklendi.',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Mockup 3: Dynamic Island & Pomodoro
  // --------------------------------------------------------------------------
  Widget _buildDynamicIslandMockup() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonPurple.withValues(alpha: 0.25),
                blurRadius: 35,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              // Dynamic Island Pill Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.neonPurple, size: 18),
                    const SizedBox(width: 8),
                    Text('Odaklanma', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Spacer(),
                    Text('24:18', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.iceBlue)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildIslandTag('🌲 Orman Sesi', AppColors.softGreen),
                  _buildIslandTag('🔴 Canlı Ada', AppColors.neonPurple),
                  _buildIslandTag('🔔 Çan Uyarısı', AppColors.amber),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIslandTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // --------------------------------------------------------------------------
  // Mockup 4: Multi Converter & Calculator
  // --------------------------------------------------------------------------
  Widget _buildConverterMockup() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.amber.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Text('🇺🇸 100 USD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Spacer(),
                    const Icon(Icons.sync_alt_rounded, color: AppColors.amber, size: 20),
                    const Spacer(),
                    const Text('🇪🇺 92.40 EUR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.iceBlue)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.functions_rounded, color: AppColors.neonPurple, size: 18),
                        const SizedBox(width: 8),
                        Text('AI Denklem Çözücü', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                    const Text('Adım Adım', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neonPurple)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Slide 5: Personalization / Goals
  // --------------------------------------------------------------------------
  Widget _buildPersonalizationSlide(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          const Spacer(flex: 1),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonPurple.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 4,
                )
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: AppColors.neonPurple, size: 48),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 24),

          Text(
            l10n.onboardingPurposeTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          Text(
            l10n.onboardingPurposeSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

          const Spacer(flex: 1),

          _buildPurposeCard(
            id: 'work',
            title: l10n.onboardingPurposeWork,
            icon: Icons.business_center_rounded,
            color: AppColors.neonPurple,
            delay: 400,
          ),
          const SizedBox(height: 12),
          _buildPurposeCard(
            id: 'education',
            title: l10n.onboardingPurposeEducation,
            icon: Icons.school_rounded,
            color: AppColors.iceBlue,
            delay: 500,
          ),
          const SizedBox(height: 12),
          _buildPurposeCard(
            id: 'daily',
            title: l10n.onboardingPurposeDaily,
            icon: Icons.auto_graph_rounded,
            color: AppColors.softGreen,
            delay: 600,
          ),

          const Spacer(flex: 2),

          _buildActionButton(
            label: l10n.onboardingStartExploring,
            onTap: _completeOnboarding,
          ).animate().fadeIn(delay: 700.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPurposeCard({
    required String id,
    required String title,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    final isSelected = _selectedPurpose == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPurpose = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white60, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20)
            else
              const Icon(Icons.circle_outlined, color: Colors.white24, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }

  // --------------------------------------------------------------------------
  // Action Button
  // --------------------------------------------------------------------------
  Widget _buildActionButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [AppColors.neonPurple, AppColors.iceBlue],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonPurple.withValues(alpha: 0.4),
              blurRadius: 25,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

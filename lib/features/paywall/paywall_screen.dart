import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';
import 'package:omnibrain_ai/l10n/app_localizations.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Package? _selectedPackage;
  int _fallbackSelectedIndex = 1; // Used if RevenueCat isn't configured
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default selection is handled after build based on available packages.
  }

  Future<void> _handlePurchase() async {
    final revenueCatState = ref.read(revenueCatProvider);
    final l10n = AppLocalizations.of(context)!;
    
    if (revenueCatState.isInitialized && _selectedPackage != null) {
      setState(() => _isLoading = true);
      final success = await ref.read(revenueCatProvider.notifier).purchasePackage(_selectedPackage!);
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paywallSuccess)),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paywallFailure)),
        );
      }
    } else {
      // Dummy purchase logic if RC is not setup yet
      ref.read(revenueCatProvider.notifier).enableTestProMode();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('(Test Modu) ${l10n.paywallSuccess}')),
      );
      context.pop();
    }
  }

  Future<void> _handleRestore() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    final success = await ref.read(revenueCatProvider.notifier).restorePurchases();
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paywallRestoreSuccess)),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paywallRestoreFailure)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rcState = ref.watch(revenueCatProvider);
    final availablePackages = rcState.offerings?.current?.availablePackages ?? [];

    // Automatically select the first or yearly package if not selected
    if (availablePackages.isNotEmpty && _selectedPackage == null) {
      _selectedPackage = availablePackages.length > 1 ? availablePackages[1] : availablePackages.first;
    }

    return Scaffold(
      backgroundColor: AppColors.deepNightBlue,
      body: Stack(
        children: [
          // Animated Premium Background
          Positioned.fill(
            child: Stack(
              children: [
                Container(color: AppColors.deepNightBlue),
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.amber.withValues(alpha: 0.15),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).rotate(duration: 10.seconds),
                ),
                Positioned(
                  bottom: -150,
                  left: -50,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonPurple.withValues(alpha: 0.15),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(duration: 8.seconds),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Close button & Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => context.pop(),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _handleRestore,
                        child: Text(
                          l10n.paywallRestore,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Logo / Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.amber.withValues(alpha: 0.2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.amber.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: const Icon(Icons.workspace_premium, size: 64, color: AppColors.amber),
                        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                        
                        const SizedBox(height: 24),
                        Text(
                          "OmniBrain PRO",
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          l10n.slogan,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 40),
                        
                        // Features List
                        _buildFeatureItem(Icons.all_inclusive, "Sınırsız AI Sorgusu", "Kelime limitlerine takılmadan sohbet edin", 400),
                        _buildFeatureItem(Icons.document_scanner, "Gelişmiş OCR ve Tarama", "Belgelerden veri çekme ve analiz etme", 500),
                        _buildFeatureItem(Icons.memory, "Akıllı Hafıza (Mini RAG)", "Yapay zeka tüm notlarınızı hatırlasın", 600),
                        _buildFeatureItem(Icons.block, "Reklamsız Deneyim", "Kesintisiz odaklanma ve kullanım", 700),
                        
                        const SizedBox(height: 40),
                        
                        // Pricing Packages (Dynamic from RevenueCat or Fallback)
                        if (availablePackages.isNotEmpty) ...[
                          Column(
                            children: availablePackages.map((pkg) {
                              final isSelected = _selectedPackage == pkg;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildDynamicPackageCard(pkg, isSelected, 800),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          // Fallback mockups
                          Row(
                            children: [
                              Expanded(child: _buildFallbackPackageCard(0, "Aylık", "99.99 ₺", "", 800)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFallbackPackageCard(1, "Yıllık", "499.99 ₺", "%58 İndirim", 900)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildFallbackPackageCard(2, "Ömür Boyu (Lifetime)", "999.99 ₺", "Tek Seferlik Ödeme", 1000, isWide: true),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Purchase Button
                        GestureDetector(
                          onTap: _isLoading ? null : _handlePurchase,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [AppColors.amber, Color(0xFFFF8F00)], // Premium Gold
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.amber.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: _isLoading 
                              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.deepNightBlue)))
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    l10n.confirm,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.deepNightBlue,
                                    ),
                                  ),
                                ),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 2.seconds),
                        
                        const SizedBox(height: 20),
                        Text(
                          l10n.paywallDisclaimer,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ).animate().fadeIn(delay: 1200.ms),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showTermsOrPrivacyDialog(context, l10n.privacyPolicy, l10n.privacyPolicyContent);
                              },
                              child: Text(
                                l10n.privacyPolicy,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.iceBlue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text("|", style: TextStyle(color: Colors.white24, fontSize: 11)),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                _showTermsOrPrivacyDialog(context, l10n.termsOfUse, l10n.termsOfUseContent);
                              },
                              child: Text(
                                l10n.termsOfUse,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.iceBlue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 1300.ms),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, int delay) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildDynamicPackageCard(Package pkg, bool isSelected, int delay) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPackage = pkg);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg.storeProduct.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pkg.storeProduct.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
            Text(
              pkg.storeProduct.priceString,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildFallbackPackageCard(int index, String title, String price, String badge, int delay, {bool isWide = false}) {
    final isSelected = _fallbackSelectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() => _fallbackSelectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: Column(
          children: [
            if (badge.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber : Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.deepNightBlue : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: isWide ? 16 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: GoogleFonts.montserrat(
                fontSize: isWide ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  void _showTermsOrPrivacyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.deepNightBlue,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: AppColors.neonPurple)),
          )
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/auth_provider.dart';
import 'package:omnibrain_ai/core/providers/locale_provider.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/core/widgets/language_selector_sheet.dart';
import 'package:omnibrain_ai/core/widgets/animated_press.dart';
import 'package:omnibrain_ai/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final currentLang = ref.watch(currentLanguageProvider);
    final isLoggedIn = authState.isLoggedIn;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n.profileTitle,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ----------------------------------------------------------------
              // Avatar + User Info
              // ----------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isLoggedIn
                        ? [AppColors.neonPurple, AppColors.iceBlue]
                        : [Colors.white24, Colors.white10],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isLoggedIn ? AppColors.neonPurple : Colors.black)
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.deepNightBlue,
                  child: Icon(
                    isLoggedIn ? Icons.person : Icons.person_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 20),
              Text(
                isLoggedIn ? (authState.displayName ?? 'Kullanıcı') : 'Misafir Kullanıcı',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 4),
              Text(
                isLoggedIn ? (authState.email ?? '') : 'Oturum açılmadı',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // ----------------------------------------------------------------
              // Login / Provider Badge
              // ----------------------------------------------------------------
              if (!isLoggedIn) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialLoginButton(
                        icon: Icons.apple,
                        label: 'Apple ile Giriş',
                        iconSize: 22,
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final result =
                              await ref.read(authProvider.notifier).signInWithApple();
                          if (context.mounted) {
                            if (result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Apple ile Giriş Yapıldı!'),
                                  backgroundColor: AppColors.neonPurple,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (result.isCancelled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Giriş işlemi iptal edildi.'),
                                  backgroundColor: Colors.grey,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Giriş yapılamadı: ${result.errorMessage ?? "Bilinmeyen hata"}'),
                                  backgroundColor: AppColors.coralRed,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSocialLoginButton(
                        icon: Icons.g_mobiledata,
                        label: 'Google ile Giriş',
                        iconSize: 28,
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final result =
                              await ref.read(authProvider.notifier).signInWithGoogle();
                          if (context.mounted) {
                            if (result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Google ile Giriş Yapıldı!'),
                                  backgroundColor: AppColors.iceBlue,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (result.isCancelled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Giriş işlemi iptal edildi.'),
                                  backgroundColor: Colors.grey,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Giriş yapılamadı: ${result.errorMessage ?? "Bilinmeyen hata"}'),
                                  backgroundColor: AppColors.coralRed,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 350.ms),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${authState.provider ?? 'Sosyal'} Hesabı Bağlı',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ----------------------------------------------------------------
              // Premium Banner
              // ----------------------------------------------------------------
              GestureDetector(
                onTap: () => context.push(RoutePaths.paywall),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.amber.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppColors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium,
                                color: AppColors.amber, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OmniBrain PRO',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Yapay zeka sınırlarını kaldır.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              // ----------------------------------------------------------------
              // Settings Group: Language / Onboarding / Theme / Notifications
              // ----------------------------------------------------------------
              _buildSettingsGroup([
                _buildSettingsTile(
                  context,
                  l10n,
                  Icons.language_rounded,
                  l10n.language,
                  '${currentLang.flag} ${currentLang.nativeName}',
                  onTap: () => LanguageSelectorSheet.show(context),
                ),
                _buildSettingsTile(
                  context,
                  l10n,
                  Icons.slideshow_rounded,
                  l10n.onboardingReplay,
                  '',
                  onTap: () => context.push(RoutePaths.onboarding),
                ),
                _buildSettingsTile(context, l10n, Icons.dark_mode, 'Tema',
                    'Karanlık', onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Premium deneyim için sadece Karanlık Tema aktiftir.')));
                }),
                _buildSettingsTile(context, l10n, Icons.notifications,
                    'Bildirimler', 'Açık', onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Bildirim tercihleri sistem ayarlarından yönetilmektedir.')));
                }),
              ]).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // ----------------------------------------------------------------
              // Settings Group: Legal / Help
              // ----------------------------------------------------------------
              _buildSettingsGroup([
                _buildSettingsTile(
                  context,
                  l10n,
                  Icons.help_outline,
                  l10n.profileAbout,
                  'v1.0.0 (Build 14)',
                  onTap: () => _showAboutSheet(context),
                ),
                _buildSettingsTile(
                  context,
                  l10n,
                  Icons.privacy_tip_outlined,
                  l10n.privacyPolicy,
                  '',
                  onTap: () => _showPrivacyPolicySheet(context),
                ),
                _buildSettingsTile(
                  context,
                  l10n,
                  Icons.description_outlined,
                  l10n.termsOfUse,
                  '',
                  onTap: () => _showTermsSheet(context),
                ),
              ]).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),

              const SizedBox(height: 40),

              // ----------------------------------------------------------------
              // Logout / Delete Account (only shown when logged in)
              // ----------------------------------------------------------------
              if (isLoggedIn) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.profileLogout),
                              backgroundColor: AppColors.neonPurple,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Text(
                        l10n.profileLogout,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('|', style: TextStyle(color: Colors.white24)),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.deepNightBlue,
                            title: const Text('Hesabı Sil',
                                style: TextStyle(color: Colors.white)),
                            content: const Text(
                              'Hesabınızı ve tüm verilerinizi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context,
                                        rootNavigator: true)
                                    .pop(),
                                child: Text(l10n.cancel,
                                    style: const TextStyle(
                                        color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                  await ref
                                      .read(authProvider.notifier)
                                      .deleteAccount();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Hesabınız silindi ve oturum kapatıldı.'),
                                        backgroundColor: AppColors.coralRed,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Text(l10n.delete,
                                    style: const TextStyle(
                                        color: AppColors.coralRed)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'Hesabı Sil',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.coralRed,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),
              ],

              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    AppLocalizations l10n,
    IconData icon,
    String title,
    String trailingText, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        trailing: trailingText.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      trailingText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white38, size: 14),
                ],
              )
            : const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white38, size: 14),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title ${l10n.retry}'),
                  backgroundColor: AppColors.neonPurple,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
      ),
    );
  }

  // ─── Balanced Social Login Button ─────────────────────────────────
  Widget _buildSocialLoginButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double iconSize = 20,
  }) {
    return AnimatedPress(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderHighlight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: iconSize),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hakkında (About) Bottom Sheet ────────────────────────────────
  void _showAboutSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.90,
          minChildSize: 0.50,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.deepNightBlue.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(color: AppColors.borderHighlight, width: 1),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.neonPurple, AppColors.iceBlue],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonPurple.withValues(alpha: 0.5),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'OmniBrain AI',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neonPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'Sürüm 1.0.0 (Build 14)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.iceBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'OmniBrain AI, günlük hayatınızı ve üretkenliğinizi en üst düzeye çıkaran hepsi-bir-arada kişisel yapay zeka araç kitinizdir. Matematiksel hesaplama, sesli toplantı notları, belge tarama, çok dilli çeviri ve odaklanma araçlarını tek çatı altında sunar.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow(Icons.calculate_rounded, 'Akıllı Hesaplayıcı', 'Doğal dil ve formül hesaplamaları'),
                      _buildInfoRow(Icons.document_scanner_rounded, 'Belge Tarayıcı', 'OCR ile fiş ve döküman aktarımı'),
                      _buildInfoRow(Icons.timer_rounded, 'Odaklanma & Pomodoro', 'Ağaç büyütme & 5 atmosferik doğa sesi'),
                      _buildInfoRow(Icons.translate_rounded, 'Çeviri & Dönüştürücü', 'AI çevirmen ve 8 kategori birimler'),
                      _buildInfoRow(Icons.note_alt_rounded, 'Akıllı Notlar', 'Sesli toplantı özeti, Word/PDF dışa aktarma'),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('mailto:support@omnibrain.ai?subject=OmniBrain%20Destek');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            Clipboard.setData(const ClipboardData(text: 'support@omnibrain.ai'));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('E-posta adresi panoya kopyalandı: support@omnibrain.ai')),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.mail_outline_rounded, color: AppColors.iceBlue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Destek: support@omnibrain.ai',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '© 2026 OmniBrain AI. Tüm hakları saklıdır.',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Gizlilik Politikası (Privacy Policy) Bottom Sheet ────────────
  void _showPrivacyPolicySheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          maxChildSize: 0.95,
          minChildSize: 0.50,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.deepNightBlue.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(color: AppColors.borderHighlight, width: 1),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.iceBlue.withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.privacy_tip_rounded, color: AppColors.iceBlue, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gizlilik Politikası',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Son Güncelleme: Eylül 2026',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildLegalSection(
                        '1. Gizlilik İlkemiz',
                        'OmniBrain AI, kullanıcı gizliliğini temel bir insan hakkı olarak kabul eder. Kişisel verilerinizi asla üçüncü taraflara satmaz ve reklam hedeflemesi amacıyla paylaşmayız.',
                      ),
                      _buildLegalSection(
                        '2. Yerel Veri Depolama',
                        'Notlarınız, hatırlatıcılarınız, ses kayıtlarınız ve hesaplama geçmişiniz öncelikli olarak cihazınızın yerel depolama alanında şifrelenerek tutulur. Cihazınızdan bilginiz dışında hiçbir veri dışarı aktarılmaz.',
                      ),
                      _buildLegalSection(
                        '3. Yapay Zeka İstekleri & Güvenlik',
                        'Yapay zeka asistanı, metin özeti veya çeviri istekleri gerçekleştirilirken gönderilen metinler anonimleştirilerek Google Gemini API ve güvenli sunucular üzerinden şifreli (TLS/SSL) protokollerle işlenir. Sorgularınız model eğitimi için saklanmaz.',
                      ),
                      _buildLegalSection(
                        '4. Kamera ve Mikrofon İzinleri',
                        'Kamera izni yalnızca belge tarama ve kamera çevirisi sırasında yerel metin okuma (Apple Vision / ML Kit) için kullanılır. Mikrofon izni yalnızca sesli toplantı kaydı ve dikte komutları anında kullanılır; arka planda dinleme yapılmaz.',
                      ),
                      _buildLegalSection(
                        '5. Ödeme ve Abonelik Güvenliği',
                        'Tüm uygulama içi satın alımlar ve PRO abonelik işlemleri doğrudan Apple App Store altyapısı üzerinden gerçekleştirilir. Kredi kartı veya fatura bilgileriniz geliştirici tarafından görülemez.',
                      ),
                      _buildLegalSection(
                        '6. İletişim',
                        'Gizlilik politikası ile ilgili tüm soru ve hak talepleriniz için support@omnibrain.ai üzerinden bizimle iletişime geçebilirsiniz.',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Anladım',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Kullanım Koşulları (EULA) Bottom Sheet ───────────────────────
  void _showTermsSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          maxChildSize: 0.95,
          minChildSize: 0.50,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.deepNightBlue.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(color: AppColors.borderHighlight, width: 1),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.neonPurple.withValues(alpha: 0.2),
                            ),
                            child: const Icon(Icons.description_rounded, color: AppColors.neonPurple, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kullanım Koşulları (EULA)',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Apple Standart Lisans Sözleşmesi Uyumlu',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildLegalSection(
                        '1. Lisans Kabulü',
                        'OmniBrain AI uygulamasını yükleyerek veya kullanarak Apple Standart Son Kullanıcı Lisans Sözleşmesi (EULA) ve bu şartları kabul etmiş sayılırsınız.',
                      ),
                      _buildLegalSection(
                        '2. Hizmet Kapsamı & Yapay Zeka',
                        'Uygulama; akıllı hesaplama, belge tarama, çeviri ve sesli not araçları sunar. Yapay zeka modelleri tarafından sağlanan çıktılar bilgilendirme amaçlıdır; finansal, tıbbi veya hukuki kesin tavsiye niteliği taşımaz.',
                      ),
                      _buildLegalSection(
                        '3. PRO Abonelik ve Otomatik Yenileme',
                        'OmniBrain PRO aboneliği (Aylık veya Yıllık), mevcut dönemin bitiminden en az 24 saat önce iptal edilmediği takdirde otomatik yenilenir. Abonelik ücreti Apple ID hesabınızdan tahsil edilir. Aboneliğinizi dilediğiniz zaman Cihaz Ayarları > Apple ID > Abonelikler bölümünden yönetebilir veya iptal edebilirsiniz.',
                      ),
                      _buildLegalSection(
                        '4. Kullanıcı Yükümlülükleri',
                        'Kullanıcılar uygulamayı yasalara aykırı, telif haklarını ihlal eden veya zararlı amaçlarla kullanamaz. Hizmetin kötüye kullanımı durumunda erişim sonlandırılabilir.',
                      ),
                      _buildLegalSection(
                        '5. Sorumluluk Sınırı',
                        'OmniBrain AI, üçüncü taraf yapay zeka hizmet kesintilerinden veya kullanıcı kaynaklı veri kayıplarından dolayı doğrudan ya da dolaylı zararlardan sorumlu tutulamaz.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.iceBlue),
                        label: Text(
                          'Resmi Apple EULA Sözleşmesini Görüntüle',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.iceBlue),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.iceBlue.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Kapat',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.iceBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}


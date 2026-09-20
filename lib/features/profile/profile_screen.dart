import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/auth_provider.dart';
import 'package:omnibrain_ai/core/providers/locale_provider.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/core/widgets/language_selector_sheet.dart';
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
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
                      icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                      label: Text(
                        'Apple ile Giriş',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
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
                      icon: const Icon(Icons.g_mobiledata,
                          color: Colors.white, size: 22),
                      label: Text(
                        'Google',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
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
                _buildSettingsTile(context, l10n, Icons.help_outline,
                    l10n.profileAbout, '', onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.deepNightBlue,
                      title: const Text('Yardım & Destek',
                          style: TextStyle(color: Colors.white)),
                      content: const Text(
                          'Bize support@omnibrain.ai adresinden ulaşabilirsiniz.',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          child: Text(l10n.close,
                              style: const TextStyle(
                                  color: AppColors.neonPurple)),
                        )
                      ],
                    ),
                  );
                }),
                _buildSettingsTile(context, l10n, Icons.privacy_tip_outlined,
                    l10n.privacyPolicy, '', onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.deepNightBlue,
                      title: Text(l10n.privacyPolicy,
                          style: const TextStyle(color: Colors.white)),
                      content: Text(l10n.privacyPolicyContent,
                          style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          child: Text(l10n.close,
                              style: const TextStyle(
                                  color: AppColors.neonPurple)),
                        )
                      ],
                    ),
                  );
                }),
                _buildSettingsTile(context, l10n, Icons.description_outlined,
                    l10n.termsOfUse, '', onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.deepNightBlue,
                      title: Text(l10n.termsOfUse,
                          style: const TextStyle(color: Colors.white)),
                      content: Text(l10n.termsOfUseContent,
                          style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          child: Text(l10n.close,
                              style: const TextStyle(
                                  color: AppColors.neonPurple)),
                        )
                      ],
                    ),
                  );
                }),
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
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';

/// Pre-defined text styles for OmniBrain AI.
///
/// Heading styles use **Montserrat**; body / UI styles use **Inter**.
/// Every style ships in two colour variants — primary ([AppColors.textPrimary])
/// and secondary ([AppColors.textSecondary]).
abstract final class AppTextStyles {
  // ─── Large Title (32 px · Montserrat Bold) ────────────────────────
  static final TextStyle largeTitle = GoogleFonts.montserrat(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static final TextStyle largeTitleSecondary = largeTitle.copyWith(
    color: AppColors.textSecondary,
  );

  // ─── Page Title (24 px · Montserrat SemiBold) ─────────────────────
  static final TextStyle pageTitle = GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static final TextStyle pageTitleSecondary = pageTitle.copyWith(
    color: AppColors.textSecondary,
  );

  // ─── Section Title (20 px · Montserrat SemiBold) ──────────────────
  static final TextStyle sectionTitle = GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static final TextStyle sectionTitleSecondary = sectionTitle.copyWith(
    color: AppColors.textSecondary,
  );

  // ─── Card Title (17 px · Inter SemiBold) ──────────────────────────
  static final TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static final TextStyle cardTitleSecondary = cardTitle.copyWith(
    color: AppColors.textSecondary,
  );

  // ─── Body Text (15 px · Inter Regular) ────────────────────────────
  static final TextStyle bodyText = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static final TextStyle bodyTextSecondary = bodyText.copyWith(
    color: AppColors.textSecondary,
  );

  /// Bold variant for emphasis within body copy.
  static final TextStyle bodyTextBold = bodyText.copyWith(
    fontWeight: FontWeight.w600,
  );

  // ─── Caption (13 px · Inter Regular) ──────────────────────────────
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static final TextStyle captionSecondary = caption.copyWith(
    color: AppColors.textSecondary,
  );

  // ─── Micro Text (11 px · Inter Medium) ────────────────────────────
  static final TextStyle microText = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static final TextStyle microTextSecondary = microText.copyWith(
    color: AppColors.textSecondary,
  );

  // ─── Button Text (15 px · Inter SemiBold) ─────────────────────────
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.0,
    letterSpacing: 0.3,
  );

  // ─── Input / Placeholder (15 px · Inter Regular) ──────────────────
  static final TextStyle input = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static final TextStyle inputHint = input.copyWith(
    color: AppColors.textSecondary,
  );

  // ─── Premium Numeric Styles ───────────────────────────────────────
  /// Hero number – large balance / total display with tabular figures.
  static final TextStyle heroNumber = GoogleFonts.montserrat(
    fontSize: 42,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -1.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Timer display – large countdown with tabular figures.
  static final TextStyle timerDisplay = GoogleFonts.montserrat(
    fontSize: 56,
    fontWeight: FontWeight.w300,
    color: AppColors.textPrimary,
    height: 1.0,
    letterSpacing: -1.0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Numeric body – smaller tabular figure text for converters, stats.
  static final TextStyle numericBody = GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Badge text – small caps-like label for PRO badges, status pills.
  static final TextStyle badge = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.0,
    letterSpacing: 0.8,
  );
}

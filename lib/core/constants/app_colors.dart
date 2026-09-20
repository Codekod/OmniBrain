import 'package:flutter/material.dart';

/// OmniBrain AI color palette.
///
/// All colors are derived from the official OmniBrain design language.
/// Use these constants throughout the app to maintain visual consistency.
abstract final class AppColors {
  // ─── Primary Backgrounds ───────────────────────────────────────────
  /// Deep night blue – primary scaffold / page background.
  static const Color deepNightBlue = Color(0xFF0A0E17);

  /// Dark navy – secondary surfaces, cards, bottom sheets.
  static const Color darkNavy = Color(0xFF111827);

  // ─── Accent Colors ────────────────────────────────────────────────
  /// Neon purple – primary accent used for CTAs, active states, highlights.
  static const Color neonPurple = Color(0xFF8A2BE2);

  /// Ice blue – secondary accent for icons, links, subtle highlights.
  static const Color iceBlue = Color(0xFF7DF9FF);

  // ─── Semantic Colors ──────────────────────────────────────────────
  /// Soft green – success states, confirmations, positive feedback.
  static const Color softGreen = Color(0xFF4ADE80);

  /// Amber – warnings, in-progress indicators.
  static const Color amber = Color(0xFFFBBF24);

  /// Coral red – errors, destructive actions, alerts.
  static const Color coralRed = Color(0xFFFB7185);

  // ─── Text Colors ──────────────────────────────────────────────────
  /// Primary text – headings, body copy on dark backgrounds.
  static const Color textPrimary = Color(0xFFF8FAFC);

  /// Secondary text – captions, labels, placeholders.
  static const Color textSecondary = Color(0xFF94A3B8);

  // ─── Surface Colors ───────────────────────────────────────────────
  /// Glassmorphism card fill – white at 12 % opacity.
  static final Color cardBackground = Colors.white.withValues(alpha: 0.12);

  /// Glassmorphism card border – white at 12 % opacity.
  static final Color cardBorder = Colors.white.withValues(alpha: 0.12);

  /// Slightly elevated surface (e.g. input fields inside cards).
  static final Color elevatedSurface = Colors.white.withValues(alpha: 0.06);

  /// Divider / separator color.
  static final Color divider = Colors.white.withValues(alpha: 0.08);

  // ─── Premium Surface Elevation ─────────────────────────────────
  /// Primary card surface – slightly lifted from the base canvas.
  static const Color surfacePrimary = Color(0xFF16181D);

  /// Secondary surface – nested elements inside cards (inputs, chips).
  static const Color surfaceSecondary = Color(0xFF21242C);

  /// Tertiary surface – deeply nested / popover overlays.
  static const Color surfaceTertiary = Color(0xFF2A2D38);

  // ─── Premium Border Tokens ─────────────────────────────────────
  /// Specular highlight – top-left edge glow simulating light source.
  static final Color borderHighlight = Colors.white.withValues(alpha: 0.16);

  /// Razor-thin subtle perimeter outline.
  static final Color borderSubtle = Colors.white.withValues(alpha: 0.06);

  /// Inner inset glow – 1px top highlight inside glassmorphic cards.
  static final Color innerGlow = Colors.white.withValues(alpha: 0.12);

  // ─── Neon Glow Colors ─────────────────────────────────────────────
  /// Neon purple glow used for box-shadows / ambient light effects.
  static final Color neonPurpleGlow = neonPurple.withValues(alpha: 0.35);

  /// Ice blue glow.
  static final Color iceBlueGlow = iceBlue.withValues(alpha: 0.30);

  // ─── Gradients ────────────────────────────────────────────────────
  /// Primary background gradient – top-to-bottom dark sweep.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepNightBlue, darkNavy],
  );

  /// Neon purple gradient – used for buttons, highlighted cards.
  static const LinearGradient neonPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9B30FF), // lighter purple
      neonPurple,
      Color(0xFF6A1FB5), // deeper purple
    ],
  );

  /// Ice-blue to purple gradient – used for premium / AI elements.
  static const LinearGradient icePurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [iceBlue, neonPurple],
  );

  /// Accent shimmer gradient – subtle horizontal sweep for loaders.
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0x00FFFFFF),
      Color(0x33FFFFFF),
      Color(0x00FFFFFF),
    ],
  );

  /// Card highlight gradient – used for featured / hero cards.
  static const LinearGradient cardHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x288A2BE2), // neonPurple @ 16 %
      Color(0x007DF9FF), // iceBlue @ 0 %
    ],
  );

  /// Success gradient.
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF34D399),
      softGreen,
    ],
  );

  // ─── Premium Gradients ────────────────────────────────────────
  /// Aurora orb – purple radial glow for ambient background mesh.
  static const RadialGradient auroraOrb1 = RadialGradient(
    center: Alignment(-0.6, -0.5),
    radius: 0.7,
    colors: [
      Color(0x1F8A2BE2), // neonPurple @ ~12%
      Color(0x008A2BE2), // transparent
    ],
  );

  /// Aurora orb – cyan radial glow for ambient background mesh.
  static const RadialGradient auroraOrb2 = RadialGradient(
    center: Alignment(0.7, 0.6),
    radius: 0.6,
    colors: [
      Color(0x147DF9FF), // iceBlue @ ~8%
      Color(0x007DF9FF), // transparent
    ],
  );

  /// Glassmorphic card surface gradient – subtle top-left light.
  static const LinearGradient glassCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF), // white @ 10%
      Color(0x08FFFFFF), // white @ 3%
    ],
  );

  /// Specular border gradient – simulates directional light hitting glass.
  static const LinearGradient specularBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x2AFFFFFF), // white @ 16%
      Color(0x08FFFFFF), // white @ 3%
    ],
  );

  // ─── Helpers ──────────────────────────────────────────────────────
  /// Returns a [Color] for the given semantic [status].
  static Color statusColor(StatusType status) => switch (status) {
        StatusType.success => softGreen,
        StatusType.warning => amber,
        StatusType.error => coralRed,
        StatusType.info => iceBlue,
      };
}

/// Semantic status types used across the app.
enum StatusType { success, warning, error, info }

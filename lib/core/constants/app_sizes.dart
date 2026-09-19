import 'package:flutter/material.dart';

/// Centralised sizing and spacing tokens for OmniBrain AI.
///
/// All magic numbers live here so the entire layout system stays consistent
/// and can be tweaked from a single source of truth.
abstract final class AppSizes {
  // ─── Spacing ──────────────────────────────────────────────────────
  /// 4 px – micro spacing (e.g. between icon and label inside a chip).
  static const double spacingXs = 4;

  /// 8 px – small spacing.
  static const double spacingSm = 8;

  /// 12 px – medium-small spacing.
  static const double spacingMd12 = 12;

  /// 16 px – default spacing between sibling elements.
  static const double spacingMd = 16;

  /// 24 px – large spacing (section gaps).
  static const double spacingLg = 24;

  /// 32 px – extra-large spacing (page-level separation).
  static const double spacingXl = 32;

  /// 48 px – 2×large, used sparingly for hero padding.
  static const double spacingXxl = 48;

  // ─── Border Radius ────────────────────────────────────────────────
  /// 8 px – smallest radius (chips, tags).
  static const double radiusXs = 8;

  /// 12 px – small radius (buttons, input fields).
  static const double radiusSm = 12;

  /// 16 px – medium radius (cards, dialogs).
  static const double radiusMd = 16;

  /// 24 px – large radius (glassmorphism cards, bottom sheets).
  static const double radiusLg = 24;

  /// 32 px – pill-shaped elements.
  static const double radiusXl = 32;

  /// Full circle.
  static const double radiusFull = 999;

  // ─── Pre-built Border Radii ───────────────────────────────────────
  static final BorderRadius borderRadiusXs = BorderRadius.circular(radiusXs);
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);

  // ─── Page-level Layout ────────────────────────────────────────────
  /// Horizontal padding for page content.
  static const double pagePaddingH = 20;

  /// Vertical padding at the top of a page (below app bar).
  static const double pagePaddingTop = 24;

  /// Standard page padding (symmetric horizontal).
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: pagePaddingH);

  /// Page padding with top spacing.
  static const EdgeInsets pagePaddingWithTop = EdgeInsets.only(
    left: pagePaddingH,
    right: pagePaddingH,
    top: pagePaddingTop,
  );

  // ─── Card Layout ─────────────────────────────────────────────────
  /// Default inner padding for glass cards.
  static const double cardPadding = 18;

  /// Symmetric card padding as [EdgeInsets].
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);

  /// Gap between cards in a list / grid.
  static const double cardGap = 16;

  /// Gap between cards in a smaller / compact list.
  static const double cardGapSm = 12;

  // ─── Icon Sizes ───────────────────────────────────────────────────
  /// 18 px – micro icons (inline indicators).
  static const double iconXs = 18;

  /// 22 px – small icons (list tiles, chips).
  static const double iconSm = 22;

  /// 26 px – default icon size.
  static const double iconMd = 26;

  /// 32 px – large icons (tool grid).
  static const double iconLg = 32;

  /// 48 px – hero icons (empty states, onboarding).
  static const double iconXl = 48;

  // ─── Button Sizes ─────────────────────────────────────────────────
  /// Default button height.
  static const double buttonHeight = 52;

  /// Small button height.
  static const double buttonHeightSm = 40;

  /// Icon button diameter (circular).
  static const double iconButtonSize = 48;

  /// Small circular icon button.
  static const double iconButtonSizeSm = 36;

  // ─── Bottom Navigation ────────────────────────────────────────────
  /// Height of the custom bottom nav bar.
  static const double bottomNavHeight = 72;

  // ─── Misc ─────────────────────────────────────────────────────────
  /// Default animation duration (ms).
  static const int defaultAnimationMs = 250;

  /// Long animation duration (ms).
  static const int longAnimationMs = 400;

  /// Max content width (for wide screens / tablets).
  static const double maxContentWidth = 600;
}

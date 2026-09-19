import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final IconData iconData;
  final Color accentColor;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.iconData,
    required this.accentColor,
  });

  static const Color _neonPurple = Color(0xFF8A2BE2);
  static const Color _iceBlue = Color(0xFF7DF9FF);
  static const Color _softGreen = Color(0xFF4ADE80);

  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      title: 'OmniBrain AI',
      description: 'Telefonundaki ikinci beyin',
      iconData: Icons.psychology_rounded,
      accentColor: _neonPurple,
    ),
    OnboardingPageModel(
      title: 'Akıllı Araçlar',
      description:
          'Hesapla, Tara, Zamanla, Çevir, Not Al ve Hatırlat — tüm araçlar tek yerde.',
      iconData: Icons.auto_awesome_rounded,
      accentColor: _iceBlue,
    ),
    OnboardingPageModel(
      title: 'Başlayalım',
      description: 'Günlük işlerin artık daha kolay',
      iconData: Icons.rocket_launch_rounded,
      accentColor: _softGreen,
    ),
  ];
}

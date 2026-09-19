import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a single tool item for the dashboard grid.
class ToolItem {
  final String name;
  final IconData icon;
  final Color color;
  final String route;

  const ToolItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.route,
  });
}

/// Mock focus timer remaining display.
final focusTimerProvider = StateProvider<String>((ref) => '14:32');

/// The 6 smart tools shown on the dashboard grid.
final dashboardToolsProvider = Provider<List<ToolItem>>((ref) {
  return const [
    ToolItem(
      name: 'Hesapla',
      icon: Icons.calculate_rounded,
      color: Color(0xFF8A2BE2),
      route: '/calculator',
    ),
    ToolItem(
      name: 'Tara',
      icon: Icons.document_scanner_rounded,
      color: Color(0xFF7DF9FF),
      route: '/calculator',
    ),
    ToolItem(
      name: 'Zamanla',
      icon: Icons.timer_rounded,
      color: Color(0xFF4ADE80),
      route: '/pomodoro',
    ),
    ToolItem(
      name: 'Çevir',
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFFFBBF24),
      route: '/converter',
    ),
    ToolItem(
      name: 'Not Al',
      icon: Icons.edit_note_rounded,
      color: Color(0xFFFB7185),
      route: '/notes',
    ),
    ToolItem(
      name: 'Hatırlat',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFF7DF9FF),
      route: '',
    ),
  ];
});

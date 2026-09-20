import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omnibrain_ai/l10n/app_localizations.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/features/dashboard/widgets/tool_widget_card.dart';

/// 2×3 grid of smart tool cards for the dashboard.
class SmartToolGrid extends StatelessWidget {
  const SmartToolGrid({super.key});

  List<_ToolDef> _getTools(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _ToolDef(l10n.toolCalculate, Icons.calculate_rounded, AppColors.neonPurple,
          '/smart_calculator'),
      _ToolDef(l10n.toolScan, Icons.document_scanner_rounded, AppColors.iceBlue,
          '/document_scanner'),
      _ToolDef(
          l10n.toolPomodoro, Icons.timer_rounded, AppColors.softGreen, '/pomodoro'),
      _ToolDef(
          l10n.toolConvert, Icons.swap_horiz_rounded, AppColors.amber, '/converter'),
      _ToolDef(l10n.toolNote, Icons.edit_note_rounded, AppColors.coralRed, '/notes'),
      _ToolDef(l10n.toolReminder, Icons.notifications_active_rounded,
          AppColors.iceBlue, '/reminders'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tools = _getTools(context);

    return Column(
      children: [
        // Top row: 2 large hero cards
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 160,
                child: ToolWidgetCard(
                  iconData: tools[0].icon,
                  name: tools[0].name,
                  color: tools[0].color,
                  subtitle: 'Akıllı İşlemler',
                  isHero: true,
                  onTap: () => context.push(tools[0].route),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 160,
                child: ToolWidgetCard(
                  iconData: tools[1].icon,
                  name: tools[1].name,
                  color: tools[1].color,
                  subtitle: 'AI Destekli',
                  isHero: true,
                  onTap: () => context.push(tools[1].route),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Bottom row: 4 compact cards in 2x2 grid
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.0, // Or whatever fits
          children: tools.sublist(2).map((tool) {
            return ToolWidgetCard(
              iconData: tool.icon,
              name: tool.name,
              color: tool.color,
              onTap: () {
                if (tool.route.isNotEmpty) {
                  context.push(tool.route);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${tool.name} çok yakında eklenecek!'),
                      backgroundColor: AppColors.neonPurple,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ToolDef {
  final String name;
  final IconData icon;
  final Color color;
  final String route;
  const _ToolDef(this.name, this.icon, this.color, this.route);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnibrain_ai/features/dashboard/dashboard_screen.dart';
import 'package:omnibrain_ai/features/ai_command/ai_command_screen.dart';
import 'package:omnibrain_ai/features/notes/notes_screen.dart';
import 'package:omnibrain_ai/features/profile/profile_screen.dart';
import 'package:omnibrain_ai/presentation/widgets/bottom_nav_bar.dart';
import 'package:omnibrain_ai/presentation/providers/navigation_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    final screens = [
      const DashboardScreen(),
      const Scaffold(body: Center(child: Text("Araçlar Ekranı (Yapım Aşamasında)", style: TextStyle(color: Colors.white)))), // ToolsGrid placeholder
      const AiCommandScreen(),
      const NotesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: OmniBrainBottomNav(
        onTabChanged: (index) {
          ref.read(currentTabIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}

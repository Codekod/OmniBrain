import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:omnibrain_ai/features/dashboard/dashboard_screen.dart';
import 'package:omnibrain_ai/features/ai_command/ai_command_screen.dart';
import 'package:omnibrain_ai/features/notes/notes_screen.dart';
import 'package:omnibrain_ai/features/profile/profile_screen.dart';
import 'package:omnibrain_ai/features/onboarding/onboarding_screen.dart';
import 'package:omnibrain_ai/features/pomodoro/pomodoro_screen.dart';
import 'package:omnibrain_ai/features/converter/converter_screen.dart';
import 'package:omnibrain_ai/features/notes/note_detail_screen.dart';
import 'package:omnibrain_ai/features/smart_calculator/smart_calculator_screen.dart';
import 'package:omnibrain_ai/features/document_scanner/document_scanner_screen.dart';
import 'package:omnibrain_ai/features/paywall/paywall_screen.dart';
import 'package:omnibrain_ai/features/reminders/reminders_screen.dart';
import 'package:omnibrain_ai/presentation/widgets/bottom_nav_bar.dart';
import 'package:omnibrain_ai/core/providers/shared_prefs_provider.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/widgets/in_app_dynamic_island.dart';
import 'package:omnibrain_ai/features/dashboard/widgets/smart_tool_grid.dart';

// ─── Route Paths ────────────────────────────────────────────────────────────
abstract final class RoutePaths {
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String tools = '/tools';
  static const String aiCommand = '/ai-command';
  static const String notes = '/notes';
  static const String profile = '/profile';
  static const String paywall = '/paywall';

  static const String smartCalculator = '/smart_calculator';
  static const String documentScanner = '/document_scanner';
  static const String pomodoro = '/pomodoro';
  static const String converter = '/converter';
  static const String reminders = '/reminders';
  static const String noteDetail = '/note/:id';

  static String noteDetailPath(String id) => '/note/$id';
}

// ─── Navigator Keys ─────────────────────────────────────────────────────────
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// ─── Page Transition Builders ───────────────────────────────────────────────
CustomTransitionPage<T> _fadeSlideTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<T> _fadeTransition<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

// ─── Shell Scaffold ─────────────────────────────────────────────────────────
class _MainShellScaffold extends StatelessWidget {
  const _MainShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: InAppDynamicIsland(),
          ),
        ],
      ),
      bottomNavigationBar: OmniBrainBottomNav(
        onTabChanged: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class ToolsGridPlaceholder extends StatelessWidget {
  const ToolsGridPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Tüm Araçlar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aktif Araçlar',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const SmartToolGrid(),
              const SizedBox(height: 32),
              const Text(
                'Yakında Gelecekler',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.0,
                children: [
                  _buildUpcomingTool(context, 'PDF Chat', Icons.picture_as_pdf, AppColors.coralRed),
                  _buildUpcomingTool(context, 'Rüya Tabiri', Icons.nights_stay, AppColors.neonPurple),
                  _buildUpcomingTool(context, 'Kod Asistanı', Icons.code, AppColors.softGreen),
                ],
              ),
              const SizedBox(height: 100), // Bottom nav overlap
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTool(BuildContext context, String name, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name çok yakında eklenecek!'),
            backgroundColor: AppColors.neonPurple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: color.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'YENİ',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.amber),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Router Configuration ───────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: hasSeenOnboarding ? RoutePaths.dashboard : RoutePaths.onboarding,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.onboarding,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlideTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return _MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                pageBuilder: (context, state) => _fadeTransition(
                  state: state,
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.tools,
                pageBuilder: (context, state) => _fadeTransition(
                  state: state,
                  child: const ToolsGridPlaceholder(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.aiCommand,
                pageBuilder: (context, state) => _fadeTransition(
                  state: state,
                  child: const AiCommandScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.notes,
                pageBuilder: (context, state) => _fadeTransition(
                  state: state,
                  child: const NotesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                pageBuilder: (context, state) => _fadeTransition(
                  state: state,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.smartCalculator,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlideTransition(
          context: context,
          state: state,
          child: const SmartCalculatorScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.documentScanner,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlideTransition(
          context: context,
          state: state,
          child: const DocumentScannerScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.pomodoro,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlideTransition(
          context: context,
          state: state,
          child: const PomodoroScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.converter,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlideTransition(
          context: context,
          state: state,
          child: const ConverterScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.noteDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return _fadeSlideTransition(
            context: context,
            state: state,
            child: const NoteDetailScreen(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.reminders,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlideTransition(
          context: context,
          state: state,
          child: const RemindersScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.paywall,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlideTransition(
          context: context,
          state: state,
          child: const PaywallScreen(),
        ),
      ),
    ],
  );
});

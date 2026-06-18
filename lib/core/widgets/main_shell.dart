import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/color_scheme.dart';
import '../providers/app_mode_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context, AppMode mode) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (mode == AppMode.fan) {
      if (loc == '/' || loc == '/contests') return 0;
      if (loc.startsWith('/games')) return 1;
      if (loc.startsWith('/social') || loc.startsWith('/community')) return 2;
      if (loc.startsWith('/profile')) return 3;
      return 0;
    } else {
      if (loc.startsWith('/tournaments/dashboard')) return 0;
      if (loc.startsWith('/tournaments/standings')) return 2;
      if (loc.startsWith('/tournaments')) return 1;
      if (loc.startsWith('/profile')) return 3;
      return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeState = ref.watch(appModeProvider);
    final idx = _currentIndex(context, modeState.mode);

    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: idx,
        mode: modeState.mode,
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final int currentIndex;
  final AppMode mode;
  const _BottomNav({required this.currentIndex, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFan = mode == AppMode.fan;
    final activeColor = isFan ? SkorioColors.primary : SkorioColors.secondary;

    final fanItems = [
      _TabItem(Icons.emoji_events_outlined, Icons.emoji_events, 'Contests', () => context.go('/')),
      _TabItem(Icons.sports_soccer_outlined, Icons.sports_soccer, 'Games', () => context.go('/games')),
      _TabItem(Icons.groups_outlined, Icons.groups, 'Social', () => context.go('/social')),
      _TabItem(Icons.person_outline, Icons.person, 'Profile', () => context.go('/profile')),
    ];

    final tournamentItems = [
      _TabItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', () => context.go('/tournaments/dashboard')),
      _TabItem(Icons.emoji_events_outlined, Icons.emoji_events, 'Tournaments', () => context.go('/tournaments')),
      _TabItem(Icons.table_chart_outlined, Icons.table_chart, 'Standings', () => context.go('/tournaments/standings')),
      _TabItem(Icons.person_outline, Icons.person, 'Profile', () => context.go('/profile')),
    ];

    final items = isFan ? fanItems : tournamentItems;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131318).withValues(alpha: 0.85),
            border: const Border(
              top: BorderSide(color: Color(0x14FFFFFF)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isActive = currentIndex == i;
                  final color = isActive ? activeColor : SkorioColors.outline;
                  return Expanded(
                    child: GestureDetector(
                      onTap: item.onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isActive ? item.activeIcon : item.icon,
                              key: ValueKey(isActive),
                              color: color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              color: color,
                            ),
                            child: Text(item.label),
                          ),
                          if (isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: activeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  const _TabItem(this.icon, this.activeIcon, this.label, this.onTap);
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../theme/color_scheme.dart';
import '../theme/text_styles.dart';
import '../providers/app_mode_provider.dart';

class TopBar extends ConsumerWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String activeTab;

  const TopBar({
    super.key,
    required this.scaffoldKey,
    required this.activeTab,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  int min(int a, int b) => a < b ? a : b;

  Widget _buildModeToggle(BuildContext context, WidgetRef ref) {
    final modeState = ref.watch(appModeProvider);
    final isFan = modeState.mode == AppMode.fan;
    
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            label: 'Fan',
            isActive: isFan,
            activeColor: SkorioColors.primary,
            onTap: () {
              ref.read(appModeProvider.notifier).setMode(AppMode.fan);
              if (modeState.activeFanTab == 'games') {
                context.go('/games');
              } else {
                context.go('/');
              }
            },
          ),
          _buildToggleOption(
            label: 'Tournament',
            isActive: !isFan,
            activeColor: SkorioColors.secondary,
            onTap: () {
              ref.read(appModeProvider.notifier).setMode(AppMode.tournament);
              if (modeState.activeTournamentTab == 'tournaments') {
                context.go('/tournaments');
              } else {
                context.go('/tournaments/dashboard');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white38,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final modeState = ref.watch(appModeProvider);
    final isFan = modeState.mode == AppMode.fan;
    final activeColor = isFan ? SkorioColors.primary : SkorioColors.secondary;
    final screenWidth = MediaQuery.of(context).size.width;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          height: preferredSize.height + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 12,
            right: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F).withValues(alpha: 0.85),
            border: const Border(
              bottom: BorderSide(color: Colors.white12, width: 1.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & App Title
              GestureDetector(
                onTap: () => context.go('/'),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/skorio-logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.sports_soccer,
                                color: activeColor, size: 28),
                      ),
                    ),
                    if (screenWidth > 400) ...[
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'SKO',
                              style: SkorioTextStyles.labelMd.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: activeColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const TextSpan(
                              text: 'RIO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Middle Toggle Switcher
              _buildModeToggle(context, ref),

              // Right Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user != null && screenWidth > 360) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (screenWidth > 440)
                          Text(
                            user.name,
                            style: SkorioTextStyles.labelSm.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        Text(
                          '${user.points} PTS',
                          style: TextStyle(
                            color: activeColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),

                  if (user != null) ...[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isFan
                              ? [const Color(0xFFA855F7), const Color(0xFF6366F1)]
                              : [const Color(0xFF10B981), const Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(user.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  IconButton(
                    onPressed: () {
                      scaffoldKey.currentState?.openEndDrawer();
                    },
                    icon: const Icon(Icons.menu, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

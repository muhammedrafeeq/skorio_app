import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/color_scheme.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/nav_drawer.dart';
import '../../../core/widgets/pitch_background.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/animations.dart';
import '../providers/community_provider.dart';
import '../../auth/providers/auth_provider.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _showUnlockDialog(BuildContext context, FanClub club) {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.80),
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131318),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Text(
            "Unlock ${club.name}",
            style: SkorioTextStyles.labelMd.copyWith(color: Colors.white, fontSize: 16),
          ),
          content: Text(
            "Joining a second Fan Club costs 100 Points. You will be able to participate in their exclusive chats and fan wars. Would you like to proceed?",
            style: SkorioTextStyles.labelSm.copyWith(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: SkorioColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("UNLOCK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed == true) {
        final success = await ref.read(communityProvider.notifier).joinClub(club.id);
        if (!success && mounted) {
          final errorMsg = ref.read(communityProvider).error ?? "Failed to join club";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: SkorioColors.errorContainer,
            ),
          );
        } else if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Welcome to the ${club.name}!"),
              backgroundColor: SkorioColors.onSecondaryContainer,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    final user = ref.watch(authProvider).value;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: SkorioColors.baseBg,
      appBar: TopBar(scaffoldKey: _scaffoldKey, activeTab: 'community'),
      endDrawer: const NavDrawer(activeTab: 'community'),
      body: Stack(
        children: [
          const PitchBackground(child: SizedBox.expand()),

          // Ambient Background Glows
          Positioned(
            top: 60,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SkorioColors.primary.withValues(alpha: 0.03),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: SkorioColors.primary.withValues(alpha: 0.03)),
              ),
            ),
          ),

          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: SkorioColors.primary),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Global Chat Quick Entry Header
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 50),
                          child: InkWell(
                            onTap: () => context.push('/chat/global'),
                            borderRadius: BorderRadius.circular(16),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: SkorioColors.primary.withValues(alpha: 0.1),
                                      border: Border.all(color: SkorioColors.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: const Icon(Icons.public, color: SkorioColors.primary, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "GLOBAL CHATROOM",
                                          style: SkorioTextStyles.labelMd.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Chat live with football fans worldwide.",
                                          style: SkorioTextStyles.labelSm.copyWith(color: SkorioColors.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. Active Fan Wars
                        if (state.activeWars.isNotEmpty) ...[
                          StaggeredEntrance(
                            delay: const Duration(milliseconds: 100),
                            child: Text(
                              "ACTIVE FAN WARS ⚔️",
                              style: SkorioTextStyles.labelMd.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.activeWars.length,
                            itemBuilder: (context, idx) {
                              final war = state.activeWars[idx];
                              return StaggeredEntrance(
                                delay: Duration(milliseconds: 150 + (idx * 50)),
                                child: _buildFanWarCard(context, war, state.allClubs),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 3. My Fan Clubs
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            "MY FAN CLUBS 👥",
                            style: SkorioTextStyles.labelMd.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        state.joinedClubs.isEmpty
                            ? _buildEmptyJoinedState()
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.joinedClubs.length,
                                itemBuilder: (context, idx) {
                                  final club = state.joinedClubs[idx];
                                  return StaggeredEntrance(
                                    delay: Duration(milliseconds: 250 + (idx * 50)),
                                    child: _buildJoinedClubCard(context, club),
                                  );
                                },
                              ),
                        const SizedBox(height: 24),

                        // 4. Browse Fan Clubs
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 300),
                          child: Text(
                            "BROWSE FAN CLUBS 🌍",
                            style: SkorioTextStyles.labelMd.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBrowseClubsGrid(context, state),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyJoinedState() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.groups_outlined, color: Colors.white24, size: 40),
            const SizedBox(height: 12),
            Text(
              "You haven't joined any Fan Clubs yet",
              style: SkorioTextStyles.labelMd.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              "Join a club below to start chat in member-only rooms.",
              style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinedClubCard(BuildContext context, FanClub club) {
    final colorVal = int.tryParse(club.primaryColor) ?? 0xFF8B80FF;
    final primaryColor = Color(colorVal);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: primaryColor.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(club.logoUrl, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club.name,
                        style: SkorioTextStyles.labelMd.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.white54, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "${club.memberCount} members",
                            style: SkorioTextStyles.labelSm.copyWith(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/chat/${club.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    "CHAT",
                    style: SkorioTextStyles.labelSm.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildJoinedStatTile("ACCURACY", "${club.avgAccuracy}%", primaryColor),
                _buildJoinedStatTile("FAN WAR RECORD", club.winRecord, primaryColor),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.01),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: SkorioColors.gold, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "Weekly Captain:",
                    style: SkorioTextStyles.labelSm.copyWith(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    club.weeklyCaptain,
                    style: SkorioTextStyles.labelSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${club.weeklyCaptainScore} PTS",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinedStatTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30, fontSize: 9, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildFanWarCard(BuildContext context, FanWar war, List<FanClub> allClubs) {
    final clubA = allClubs.firstWhere((c) => c.id == war.clubAId);
    final clubB = allClubs.firstWhere((c) => c.id == war.clubBId);

    final colorValA = int.tryParse(clubA.primaryColor) ?? 0xFF8B80FF;
    final colorA = Color(colorValA);
    final colorValB = int.tryParse(clubB.primaryColor) ?? 0xFFFFB955;
    final colorB = Color(colorValB);

    final isAccuracyEqual = war.accuracyA == war.accuracyB;
    final isAWinning = war.accuracyA > war.accuracyB;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/chat/${war.matchId}'),
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          borderColor: SkorioColors.error.withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: SkorioColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: SkorioColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      "FAN WAR LIVE",
                      style: SkorioTextStyles.labelSm.copyWith(
                        color: SkorioColors.error,
                        fontWeight: FontWeight.w900,
                        fontSize: 8,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white30, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        "Closes soon",
                        style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(clubA.logoUrl, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          clubA.name.split(' ')[0],
                          style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    child: Text(
                      "VS",
                      style: SkorioTextStyles.labelSm.copyWith(
                        color: Colors.white30,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(clubB.logoUrl, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          clubB.name.split(' ')[0],
                          style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Side by side accuracy progress bar
              Row(
                children: [
                  Text(
                    "${war.accuracyA}%",
                    style: TextStyle(
                      color: colorA,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            Expanded(
                              flex: (war.accuracyA * 10).round(),
                              child: Container(color: colorA),
                            ),
                            Expanded(
                              flex: (war.accuracyB * 10).round(),
                              child: Container(color: colorB),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${war.accuracyB}%",
                    style: TextStyle(
                      color: colorB,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  isAccuracyEqual
                      ? "Score level!"
                      : "${isAWinning ? clubA.name.split(' ')[0] : clubB.name.split(' ')[0]} Fan Club leading",
                  style: SkorioTextStyles.labelSm.copyWith(
                    color: Colors.white54,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseClubsGrid(BuildContext context, CommunityState state) {
    // Exclude clubs that the user has already joined
    final unjoined = state.allClubs.where(
      (c) => !state.joinedClubs.any((jc) => jc.id == c.id),
    ).toList();

    if (unjoined.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            "You have joined all available Fan Clubs!",
            style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: unjoined.length,
      itemBuilder: (context, idx) {
        final club = unjoined[idx];
        final colorVal = int.tryParse(club.primaryColor) ?? 0xFF8B80FF;
        final primaryColor = Color(colorVal);

        return GestureDetector(
          onTap: () {
            // Unlocking additional clubs prompts point deduction
            _showUnlockDialog(context, club);
          },
          child: GlassCard(
            padding: const EdgeInsets.all(10),
            borderColor: primaryColor.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(club.logoUrl, style: const TextStyle(fontSize: 20)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "JOIN",
                        style: SkorioTextStyles.labelSm.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  club.name,
                  style: SkorioTextStyles.labelSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${club.memberCount} members",
                  style: SkorioTextStyles.labelSm.copyWith(
                    color: Colors.white24,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

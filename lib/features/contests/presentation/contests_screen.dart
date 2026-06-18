import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_scheme.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/nav_drawer.dart';
import '../../../core/widgets/pitch_background.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/animations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/contests_provider.dart';

class ContestsScreen extends ConsumerStatefulWidget {
  const ContestsScreen({super.key});

  @override
  ConsumerState<ContestsScreen> createState() => _ContestsScreenState();
}

class _ContestsScreenState extends ConsumerState<ContestsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _joinCodeController = TextEditingController();

  String _joinError = '';
  String _joinSuccess = '';
  bool _isJoining = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinCode(String code) async {
    if (code.trim().isEmpty) return;
    setState(() {
      _isJoining = true;
      _joinError = '';
      _joinSuccess = '';
    });

    final success = await ref.read(contestsProvider.notifier).joinContest(code.trim().toUpperCase());
    if (mounted) {
      setState(() {
        _isJoining = false;
        if (success) {
          _joinSuccess = "Successfully joined contest!";
          _joinCodeController.clear();
        } else {
          _joinError = ref.read(contestsProvider).error ?? "Failed to join contest";
        }
      });
      if (success) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _joinSuccess = '';
            });
          }
        });
      }
    }
  }

  void _showCreateContestModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) {
        return const CreateContestDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contestsProvider);
    final activeContests = state.activeContests;
    final globalContests = state.globalContests;

    final authState = ref.watch(authProvider);
    final user = authState.value;
    final canCreate = user != null;

    // Filter global contests that the user hasn't joined yet
    final unjoinedGlobal = globalContests.where(
      (gc) => !activeContests.any((ac) => ac.id == gc.id),
    ).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: SkorioColors.baseBg,
      appBar: TopBar(scaffoldKey: _scaffoldKey, activeTab: 'contests'),
      endDrawer: const NavDrawer(activeTab: 'contests'),
      body: Stack(
        children: [
          // Football Pitch Background Overlay
          const PitchBackground(child: SizedBox.expand()),

          // Ambient blobs
          Positioned(
            top: 50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SkorioColors.primary.withValues(alpha: 0.04),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: SkorioColors.primary.withValues(alpha: 0.04)),
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SkorioColors.secondary.withValues(alpha: 0.03),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: SkorioColors.secondary.withValues(alpha: 0.03)),
              ),
            ),
          ),

          // Scrollable layout body or Loading state
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(SkorioColors.primary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PulsingWidget(
                        child: Text(
                          'Loading Contests...',
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(contestsProvider.notifier).loadContests(),
                  color: SkorioColors.primary,
                  backgroundColor: SkorioColors.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 24.0,
                      bottom: 40.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header Section with staggered entrance
                        StaggeredEntrance(
                          delay: Duration.zero,
                          child: _WelcomeHeader(),
                        ),
                        const SizedBox(height: 24),

                        // Global Contests Banner Carousel/List with staggered entrance
                        if (unjoinedGlobal.isNotEmpty) ...[
                          ...unjoinedGlobal.map((gc) => StaggeredEntrance(
                                delay: const Duration(milliseconds: 120),
                                child: _GlobalContestBanner(
                                  contest: gc,
                                  onJoin: () => _handleJoinCode(gc.joinCode),
                                  isJoining: _isJoining,
                                ),
                              )),
                          const SizedBox(height: 24),
                        ],

                        // Action Panel with staggered entrance
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 180),
                          child: Column(
                            children: [
                              // Join Contest Box (Full-width)
                              _JoinContestCard(
                                controller: _joinCodeController,
                                onJoin: () => _handleJoinCode(_joinCodeController.text),
                                isJoining: _isJoining,
                                error: _joinError,
                                success: _joinSuccess,
                              ),
                              
                              if (canCreate) ...[
                                const SizedBox(height: 16),
                                // Create Contest Box (Full-width, Hoverable)
                                HoverableCard(
                                  onTap: _showCreateContestModal,
                                  glowColor: SkorioColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  child: GlassCard(
                                    borderRadius: 20,
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.add,
                                                color: SkorioColors.primary, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'CREATE CONTEST',
                                              style: SkorioTextStyles.labelMd.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Start custom predictor scores with friends playing any mode.',
                                          style: SkorioTextStyles.labelSm.copyWith(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  SkorioColors.primaryContainer,
                                                  SkorioColors.primary
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: ElevatedButton(
                                              onPressed: _showCreateContestModal,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                              ),
                                              child: Text(
                                                'START CONTEST',
                                                style: SkorioTextStyles.labelSm.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // My Active Contests Header with staggered entrance
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 240),
                          child: Text(
                            'MY ACTIVE CONTESTS (${activeContests.length})',
                            style: SkorioTextStyles.labelSm.copyWith(
                              color: Colors.white38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Active Contests List with staggered entrance and hover interactions
                        if (activeContests.isEmpty)
                          StaggeredEntrance(
                            delay: const Duration(milliseconds: 280),
                            child: GlassCard(
                              borderRadius: 20,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 36),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.emoji_events_outlined,
                                        size: 48, color: Colors.white24),
                                    const SizedBox(height: 12),
                                    Text(
                                      'You have not joined any contests yet.',
                                      style: SkorioTextStyles.labelMd.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Join via invite code above or start your own!',
                                      style: SkorioTextStyles.labelSm.copyWith(
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeContests.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final contest = activeContests[index];
                              
                              // Extract matching badge colors for hover glow mapping
                              Color glowColor;
                              switch (contest.gameType) {
                                case 'match_prediction':
                                  glowColor = Colors.indigo[300]!;
                                  break;
                                case 'first_goal':
                                  glowColor = Colors.amber[300]!;
                                  break;
                                case 'formation':
                                  glowColor = Colors.purple[300]!;
                                  break;
                                case 'bracket':
                                  glowColor = const Color(0xFF34D399);
                                  break;
                                default:
                                  glowColor = Colors.white24;
                              }

                              return StaggeredEntrance(
                                delay: Duration(milliseconds: 280 + index * 60),
                                child: HoverableCard(
                                  onTap: () {
                                    context.push('/contest/${contest.id}');
                                  },
                                  glowColor: glowColor,
                                  borderRadius: BorderRadius.circular(16),
                                  child: _ContestListItem(contest: contest),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}



class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: SkorioColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  color: SkorioColors.primary, size: 10),
              const SizedBox(width: 6),
              Text(
                'CONTESTS CENTER',
                style: SkorioTextStyles.labelSm.copyWith(
                  color: SkorioColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your Predictor Hub',
          style: SkorioTextStyles.headlineLg.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create or join contests, make predictions, and climb the scoreboard.',
          style: SkorioTextStyles.bodyMd.copyWith(
            color: Colors.white38,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _GlobalContestBanner extends StatelessWidget {
  final Contest contest;
  final VoidCallback onJoin;
  final bool isJoining;

  const _GlobalContestBanner({
    required this.contest,
    required this.onJoin,
    required this.isJoining,
  });

  @override
  Widget build(BuildContext context) {
    return HoverableCard(
      onTap: isJoining ? null : onJoin,
      glowColor: SkorioColors.primary,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E1B4B).withValues(alpha: 0.6),
              const Color(0xFF0F172A).withValues(alpha: 0.8),
              const Color(0xFF022C22).withValues(alpha: 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SkorioColors.primary.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            // Faded Soccer ball outline simulation in background
            Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  Icons.sports_soccer,
                  size: 160,
                  color: Colors.white,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SkorioColors.primary.withValues(alpha: 0.2),
                          border: Border.all(
                              color: SkorioColors.primary.withValues(alpha: 0.35)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'ðŸ”¥ Global Arena',
                          style: SkorioTextStyles.labelSm.copyWith(
                            color: SkorioColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 8.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.15),
                          border: Border.all(
                              color: Colors.indigo.withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Match Predictor',
                          style: SkorioTextStyles.labelSm.copyWith(
                            color: Colors.indigo[200],
                            fontWeight: FontWeight.bold,
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Contest details
                  Text(
                    contest.name,
                    style: SkorioTextStyles.headlineMd.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Join the official global tournament! Compete with everyone, predict matches, and climb to the top of the global leaderboard.',
                    style: SkorioTextStyles.bodyMd.copyWith(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meta details row
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          color: SkorioColors.secondary, size: 14),
                      const SizedBox(width: 6),
                      RichText(
                        text: TextSpan(
                          style: SkorioTextStyles.labelSm.copyWith(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                          children: [
                            TextSpan(
                              text: '${contest.memberCount} ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: 'competitors'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('â€¢', style: TextStyle(color: Colors.white24)),
                      const SizedBox(width: 12),
                      Text(
                        'Free Entry',
                        style: SkorioTextStyles.labelSm.copyWith(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isJoining ? null : onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SkorioColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isJoining
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'JOIN GLOBAL CONTEST',
                                  style: SkorioTextStyles.labelSm.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward,
                                    color: Colors.black87, size: 14),
                              ],
                            ),
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
}

class _ContestListItem extends StatelessWidget {
  final Contest contest;

  const _ContestListItem({required this.contest});

  @override
  Widget build(BuildContext context) {
    // Determine color schema based on gameType
    final Map<String, dynamic> gameModeCfg = {
          'match_prediction': {
            'label': 'Match Predictor',
            'textColor': Colors.indigo[300],
            'bgColor': Colors.indigo.withValues(alpha: 0.1),
            'borderColor': Colors.indigo.withValues(alpha: 0.2),
          },
          'first_goal': {
            'label': 'First Goal',
            'textColor': Colors.amber[300],
            'bgColor': Colors.amber.withValues(alpha: 0.1),
            'borderColor': Colors.amber.withValues(alpha: 0.2),
          },
          'formation': {
            'label': 'Formation',
            'textColor': Colors.purple[300],
            'bgColor': Colors.purple.withValues(alpha: 0.1),
            'borderColor': Colors.purple.withValues(alpha: 0.2),
          },
          'bracket': {
            'label': 'Bracket',
            'textColor': const Color(0xFF34D399),
            'bgColor': const Color(0xFF10B981).withValues(alpha: 0.1),
            'borderColor': const Color(0xFF10B981).withValues(alpha: 0.2),
          },
        }[contest.gameType] ??
        {
          'label': contest.gameType,
          'textColor': Colors.white70,
          'bgColor': Colors.white.withValues(alpha: 0.05),
          'borderColor': Colors.white.withValues(alpha: 0.1),
        };

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: gameModeCfg['bgColor'],
                        border: Border.all(color: gameModeCfg['borderColor']),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        gameModeCfg['label'],
                        style: SkorioTextStyles.labelSm.copyWith(
                          color: gameModeCfg['textColor'],
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    if (contest.isPublic) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Global',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Contest Name
                Text(
                  contest.name,
                  style: SkorioTextStyles.labelMd.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                // Meta details (members + creator)
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        color: SkorioColors.secondary, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${contest.memberCount} members',
                      style: SkorioTextStyles.labelSm.copyWith(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('â€¢',
                        style: TextStyle(color: Colors.white24, fontSize: 10)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'By ${contest.creatorName}',
                        style: SkorioTextStyles.labelSm.copyWith(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Go Arrow Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: SkorioColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class CreateContestDialog extends ConsumerStatefulWidget {
  const CreateContestDialog({super.key});

  @override
  ConsumerState<CreateContestDialog> createState() => _CreateContestDialogState();
}

class _CreateContestDialogState extends ConsumerState<CreateContestDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _selectedGameMode = 'match_prediction';
  bool _isPublic = false;
  int _maxParticipants = 20;
  bool _unlimitedParticipants = false;
  DateTime _joinDeadline = DateTime.now().add(const Duration(days: 7));
  bool _isCreating = false;
  String _error = '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _gameModes = [
    {
      'id': 'match_prediction',
      'title': 'Match Predictor',
      'desc': 'Predict winner, score, & first scorer.',
    },
    {
      'id': 'first_goal',
      'title': 'First Goal Timer',
      'desc': 'Guess the exact minute the first goal is scored.',
    },
    {
      'id': 'formation',
      'title': 'Formation Predictor',
      'desc': 'Predict standard lineups and setups.',
    },
    {
      'id': 'bracket',
      'title': 'Tournament Bracket',
      'desc': 'Build the complete knockout tournament path.',
    },
    {
      'id': 'flags',
      'title': 'Flag Quiz',
      'desc': 'Interactive flag guessing with speed scoring.',
    },
  ];

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _joinDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: SkorioColors.primary,
              onPrimary: Colors.black,
              surface: SkorioColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_joinDeadline),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: SkorioColors.primary,
                onPrimary: Colors.black,
                surface: SkorioColors.surface,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          _joinDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a contest name.');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = '';
    });

    final success = await ref.read(contestsProvider.notifier).createContest(
          name: name,
          gameType: _selectedGameMode,
          isPublic: _isPublic,
          maxParticipants: _unlimitedParticipants ? 5000 : _maxParticipants,
          joinDeadline: _joinDeadline,
        );

    if (mounted) {
      setState(() => _isCreating = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _error = ref.read(contestsProvider).error ?? "Failed to create contest";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDeadline = "${_joinDeadline.day}/${_joinDeadline.month}/${_joinDeadline.year} at ${_joinDeadline.hour.toString().padLeft(2, '0')}:${_joinDeadline.minute.toString().padLeft(2, '0')}";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        borderColor: Colors.white.withValues(alpha: 0.15),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Contest',
                style: SkorioTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start a custom predictor competition for your friends.',
                style: SkorioTextStyles.labelSm.copyWith(
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contest Name Input
                    Text(
                      'CONTEST NAME',
                      style: SkorioTextStyles.labelSm.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. Dream Team League',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Game Mode Grid Selection
                    Text(
                      'GAME MODE',
                      style: SkorioTextStyles.labelSm.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: _gameModes.length,
                      itemBuilder: (context, index) {
                        final mode = _gameModes[index];
                        final isSelected = _selectedGameMode == mode['id'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedGameMode = mode['id']!;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white54
                                    : Colors.white.withValues(alpha: 0.04),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.check_circle, color: SkorioColors.primary, size: 12),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        mode['title']!,
                                        style: SkorioTextStyles.labelSm.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        mode['desc']!,
                                        style: SkorioTextStyles.labelSm.copyWith(
                                          color: Colors.white30,
                                          fontSize: 8,
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Visibility (Public vs Private)
                    Text(
                      'CONTEST VISIBILITY',
                      style: SkorioTextStyles.labelSm.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPublic = false),
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: !_isPublic ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_isPublic ? Colors.white54 : Colors.white.withValues(alpha: 0.04),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'ðŸ”’ PRIVATE (INVITE ONLY)',
                                  style: SkorioTextStyles.labelSm.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPublic = true),
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: _isPublic ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isPublic ? Colors.white54 : Colors.white.withValues(alpha: 0.04),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'ðŸŒ PUBLIC (DISCOVERABLE)',
                                  style: SkorioTextStyles.labelSm.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Max Participants
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MAX PARTICIPANTS',
                          style: SkorioTextStyles.labelSm.copyWith(
                            color: Colors.white54,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _unlimitedParticipants,
                              activeColor: SkorioColors.primary,
                              onChanged: (v) {
                                setState(() {
                                  _unlimitedParticipants = v ?? false;
                                });
                              },
                            ),
                            Text(
                              'UNLIMITED',
                              style: SkorioTextStyles.labelSm.copyWith(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!_unlimitedParticipants) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: SkorioColors.primary,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
                                thumbColor: SkorioColors.primary,
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _maxParticipants.toDouble(),
                                min: 2,
                                max: 100,
                                onChanged: (v) => setState(() => _maxParticipants = v.round()),
                              ),
                            ),
                          ),
                          Container(
                            width: 38,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$_maxParticipants',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Join Deadline
                    Text(
                      'JOINING DEADLINE',
                      style: SkorioTextStyles.labelSm.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDeadline(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDeadline,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.calendar_month, color: SkorioColors.primary, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_error.isNotEmpty) ...[
                      Text(
                        _error,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.08)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'CANCEL',
                                style: SkorioTextStyles.labelSm.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: SkorioColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: _isCreating ? null : _handleCreate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isCreating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.black),
                                        ),
                                      )
                                    : Text(
                                        'START CONTEST',
                                        style: SkorioTextStyles.labelSm.copyWith(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinContestCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onJoin;
  final bool isJoining;
  final String error;
  final String success;

  const _JoinContestCard({
    required this.controller,
    required this.onJoin,
    required this.isJoining,
    required this.error,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                color: SkorioColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'JOIN CONTEST',
                style: SkorioTextStyles.labelMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enter a 6-character invite code to join a private contest.',
            style: SkorioTextStyles.labelSm.copyWith(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'JOIN CODE',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: 11,
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isJoining ? null : onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SkorioColors.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    elevation: 0,
                  ),
                  child: isJoining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'JOIN',
                              style: SkorioTextStyles.labelSm.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                              size: 14,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
              ),
            ),
          ],
          if (success.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              success,
              style: const TextStyle(
                color: SkorioColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


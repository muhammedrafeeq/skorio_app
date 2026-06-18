import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_scheme.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/pitch_background.dart';
import '../../../core/widgets/animations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/achievements_provider.dart';
import '../providers/predictions_provider.dart';
import 'share_card_sheet.dart';

class PredictCricketScreen extends ConsumerStatefulWidget {
  final String matchId;

  const PredictCricketScreen({
    super.key,
    required this.matchId,
  });

  @override
  ConsumerState<PredictCricketScreen> createState() => _PredictCricketScreenState();
}

class _PredictCricketScreenState extends ConsumerState<PredictCricketScreen>
    with TickerProviderStateMixin {
  // Cricket Predictors state
  String? _selectedTossWinner;
  String? _selectedMatchWinner;
  String? _selectedBatsman;
  String? _selectedBowler;
  String? _selectedScoreRange;

  // Search input queries for autocomplete lists
  final TextEditingController _batsmanSearchController = TextEditingController();
  final TextEditingController _bowlerSearchController = TextEditingController();

  // Timer countdown values (simulating 152:13:30)
  int _totalSecondsRemaining = 152 * 3600 + 13 * 60 + 30;
  Timer? _timer;

  // Match details mapping based on ID
  late String _homeTeam;
  late String _awayTeam;
  late String _homeFlag;
  late String _awayFlag;
  late String _matchDate;
  late List<String> _batsmenSquad;
  late List<String> _bowlersSquad;
  bool _isLoading = true;
  bool _initialized = false;
  bool _isSaving = false;
  bool _lifelineUsed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _simulateLoading();

    // Map Cricket match data
    if (widget.matchId == 'cricket_2') {
      _homeTeam = 'Chennai Super Kings';
      _awayTeam = 'Mumbai Indians';
      _homeFlag = 'https://flagcdn.com/w160/in.png';
      _awayFlag = 'https://flagcdn.com/w160/in.png';
      _matchDate = '19 Jun';
      _batsmenSquad = [
        'Ruturaj Gaikwad',
        'Shivam Dube',
        'MS Dhoni',
        'Daryl Mitchell',
        'Rohit Sharma',
        'Suryakumar Yadav',
        'Ishan Kishan',
        'Tilak Varma',
        'Tim David',
      ];
      _bowlersSquad = [
        'Ravindra Jadeja',
        'Matheesha Pathirana',
        'Tushar Deshpande',
        'Mitchell Santner',
        'Jasprit Bumrah',
        'Hardik Pandya',
        'Piyush Chawla',
        'Gerald Coetzee',
      ];
    } else {
      // Default to India vs Pakistan
      _homeTeam = 'India';
      _awayTeam = 'Pakistan';
      _homeFlag = 'https://flagcdn.com/w160/in.png';
      _awayFlag = 'https://flagcdn.com/w160/pk.png';
      _matchDate = '18 Jun';
      _batsmenSquad = [
        'Virat Kohli',
        'Rohit Sharma',
        'Yashasvi Jaiswal',
        'Rishabh Pant',
        'Suryakumar Yadav',
        'Hardik Pandya',
        'Babar Azam',
        'Mohammad Rizwan',
        'Fakhar Zaman',
        'Iftikhar Ahmed',
      ];
      _bowlersSquad = [
        'Jasprit Bumrah',
        'Ravindra Jadeja',
        'Arshdeep Singh',
        'Axar Patel',
        'Kuldeep Yadav',
        'Shaheen Afridi',
        'Haris Rauf',
        'Naseem Shah',
        'Shadab Khan',
      ];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _batsmanSearchController.dispose();
    _bowlerSearchController.dispose();
    super.dispose();
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

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalSecondsRemaining > 0) {
        setState(() {
          _totalSecondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatRemainingTime() {
    final hours = _totalSecondsRemaining ~/ 3600;
    final minutes = (_totalSecondsRemaining % 3600) ~/ 60;
    final seconds = _totalSecondsRemaining % 60;

    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr:$secondsStr';
  }

  void _toggleTossWinner(String team) {
    setState(() {
      if (_selectedTossWinner == team) {
        _selectedTossWinner = null;
      } else {
        _selectedTossWinner = team;
      }
    });
  }

  void _toggleMatchWinner(String team) {
    setState(() {
      if (_selectedMatchWinner == team) {
        _selectedMatchWinner = null;
      } else {
        _selectedMatchWinner = team;
      }
    });
  }

  void _selectBatsman(String name) {
    setState(() {
      if (_selectedBatsman == name) {
        _selectedBatsman = null;
      } else {
        _selectedBatsman = name;
      }
    });
  }

  void _selectBowler(String name) {
    setState(() {
      if (_selectedBowler == name) {
        _selectedBowler = null;
      } else {
        _selectedBowler = name;
      }
    });
  }

  void _selectScoreRange(String range) {
    setState(() {
      if (_selectedScoreRange == range) {
        _selectedScoreRange = null;
      } else {
        _selectedScoreRange = range;
      }
    });
  }

  Future<void> _handleLockIn() async {
    if (_selectedTossWinner == null ||
        _selectedMatchWinner == null ||
        _selectedScoreRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Toss Winner, Match Winner, and Score Range are required fields!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    final success = await ref.read(matchPredictionsProvider(widget.matchId).notifier).saveCricketPredictions(
      tossWinner: _selectedTossWinner!,
      matchWinner: _selectedMatchWinner!,
      topBatsman: _selectedBatsman ?? 'None',
      topBowler: _selectedBowler ?? 'None',
      scoreRange: _selectedScoreRange!,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ref.read(authProvider.notifier).awardXp(amount: 10, action: 'Submit Cricket Prediction');
        
        // Award early bird & night owl achievements just like match predictor screen
        final now = DateTime.now();
        ref.read(achievementsProvider.notifier).unlockAchievement('early_bird');
        if (now.hour >= 0 && now.hour < 5) {
          ref.read(achievementsProvider.notifier).unlockAchievement('night_owl');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.black),
                const SizedBox(width: 8),
                const Text(
                  'Cricket Predictions Saved! 🏏',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: SkorioColors.secondary,
            duration: const Duration(milliseconds: 1500),
          ),
        );

        final user = ref.read(authProvider).value;
        final homeEmoji = _flagUrlToEmoji(_homeFlag);
        final awayEmoji = _flagUrlToEmoji(_awayFlag);

        final shareData = PredictionShareData(
          homeTeam: _homeTeam,
          awayTeam: _awayTeam,
          homeFlag: homeEmoji,
          awayFlag: awayEmoji,
          winner: _selectedMatchWinner,
          matchDate: _matchDate,
          userName: user?.name ?? 'Fan',
          isCricket: true,
          tossWinner: _selectedTossWinner,
          topBatsman: _selectedBatsman,
          topBowler: _selectedBowler,
          scoreRange: _selectedScoreRange,
        );

        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        await showShareCardSheet(context, shareData);
        if (!mounted) return;
        context.pop();
      } else {
        final errorMsg = ref.read(matchPredictionsProvider(widget.matchId)).error ?? "Failed to save predictions";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
            backgroundColor: SkorioColors.errorContainer,
          ),
        );
      }
    }
  }

  String _flagUrlToEmoji(String flagUrl) {
    if (flagUrl.contains('pk')) return '🇵🇰';
    if (flagUrl.contains('in')) return '🇮🇳';
    return '🏳️';
  }

  @override
  Widget build(BuildContext context) {
    final predictionsState = ref.watch(matchPredictionsProvider(widget.matchId));
    final authState = ref.watch(authProvider);
    final user = authState.value;

    if (!_initialized && !predictionsState.isLoading) {
      for (final pred in predictionsState.userPredictions) {
        final question = predictionsState.questions.firstWhere(
          (q) => q.id == pred.questionId,
          orElse: () => MatchQuestion(id: '', matchId: '', type: '', label: '', points: 0),
        );

        if (question.type == 'toss_winner') {
          _selectedTossWinner = pred.answer;
        } else if (question.type == 'match_winner') {
          _selectedMatchWinner = pred.answer;
        } else if (question.type == 'top_batsman') {
          _selectedBatsman = pred.answer;
        } else if (question.type == 'top_bowler') {
          _selectedBowler = pred.answer;
        } else if (question.type == 'score_range') {
          _selectedScoreRange = pred.answer;
        }
      }
      _initialized = true;
      _isLoading = false;
    }

    final filteredBatsmen = _batsmenSquad
        .where((p) => p.toLowerCase().contains(_batsmanSearchController.text.toLowerCase()))
        .toList();
    final filteredBowlers = _bowlersSquad
        .where((p) => p.toLowerCase().contains(_bowlerSearchController.text.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: Stack(
        children: [
          // Background layout
          const PitchBackground(child: SizedBox.expand()),

          // Ambient blue-teal glow
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withOpacity(0.03),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.teal.withOpacity(0.03)),
              ),
            ),
          ),

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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PulsingWidget(
                        child: Text(
                          'Preparing Predictor...',
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
              : SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => context.pop(),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back, color: Colors.white70, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Back',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 64.0),
                                  child: Text(
                                    'Predict Cricket Match',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scrollable form body
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Cricket match details header
                              StaggeredEntrance(
                                delay: Duration.zero,
                                child: _buildMatchHeaderCard(),
                              ),
                              const SizedBox(height: 16),

                              // 2. Lifeline Card
                              if (user != null) ...[
                                _buildLifelineCard(user),
                                const SizedBox(height: 24),
                              ],

                              // 3. Toss Winner Selection
                              StaggeredEntrance(
                                delay: const Duration(milliseconds: 100),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('TOSS WINNER', isRequired: true),
                                    const SizedBox(height: 10),
                                    _buildTossWinnerRow(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 4. Match Winner Selection
                              StaggeredEntrance(
                                delay: const Duration(milliseconds: 150),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('MATCH WINNER', isRequired: true),
                                    const SizedBox(height: 10),
                                    _buildMatchWinnerRow(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 5. Top Batsman Searchable Autocomplete
                              StaggeredEntrance(
                                delay: const Duration(milliseconds: 200),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('TOP BATSMAN (OPTIONAL)'),
                                    const SizedBox(height: 10),
                                    _buildSquadSelectorCard(
                                      controller: _batsmanSearchController,
                                      selectedName: _selectedBatsman,
                                      playersList: filteredBatsmen,
                                      onSelect: _selectBatsman,
                                      hint: 'Type or select top batsman...',
                                      role: 'batsman',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 6. Top Bowler Searchable Autocomplete
                              StaggeredEntrance(
                                delay: const Duration(milliseconds: 250),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('TOP BOWLER (OPTIONAL)'),
                                    const SizedBox(height: 10),
                                    _buildSquadSelectorCard(
                                      controller: _bowlerSearchController,
                                      selectedName: _selectedBowler,
                                      playersList: filteredBowlers,
                                      onSelect: _selectBowler,
                                      hint: 'Type or select top bowler...',
                                      role: 'bowler',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 7. Score Range Selection
                              StaggeredEntrance(
                                delay: const Duration(milliseconds: 300),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('1ST INNINGS SCORE RANGE', isRequired: true),
                                    const SizedBox(height: 10),
                                    _buildScoreRangeSelector(),
                                    if (_lifelineUsed) ...[
                                      const SizedBox(height: 12),
                                      _buildScoreRangeTrends(),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),

                      // Sticky Lock In Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: HoverableCard(
                          onTap: _isSaving ? null : _handleLockIn,
                          glowColor: Colors.tealAccent,
                          borderRadius: BorderRadius.circular(100),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent[700],
                                disabledBackgroundColor: Colors.tealAccent[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'LOCK IN CRICKET PREDICTIONS',
                                          style: SkorioTextStyles.labelMd.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMatchHeaderCard() {
    const timerColor = Color(0xFFFF5A60);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111c18).withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.withOpacity(0.12), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        _homeFlag,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _homeTeam.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _matchDate,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        _awayFlag,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _awayTeam.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: timerColor.withOpacity(0.04),
              border: Border.all(color: timerColor.withOpacity(0.18), width: 1.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: timerColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LOCKS IN',
                      style: SkorioTextStyles.labelSm.copyWith(
                        color: timerColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatRemainingTime(),
                  style: const TextStyle(
                    color: timerColor,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifelineCard(User user) {
    return StaggeredEntrance(
      delay: const Duration(milliseconds: 50),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _lifelineUsed
              ? const Color(0xFF0F172A).withOpacity(0.4)
              : Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _lifelineUsed
                ? Colors.cyanAccent.withOpacity(0.35)
                : Colors.white.withOpacity(0.04),
            width: 1.2,
          ),
          boxShadow: _lifelineUsed
              ? [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.06),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _lifelineUsed
                    ? Colors.cyanAccent.withOpacity(0.08)
                    : Colors.white.withOpacity(0.03),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _lifelineUsed
                      ? Colors.cyanAccent.withOpacity(0.3)
                      : Colors.white10,
                ),
              ),
              child: Icon(
                _lifelineUsed ? Icons.lightbulb : Icons.lightbulb_outline,
                color: _lifelineUsed ? Colors.cyanAccent : Colors.white38,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lifelineUsed ? 'LIFELINE ACTIVE' : 'PREDICTION LIFELINE',
                    style: GoogleFonts.outfit(
                      color: _lifelineUsed ? Colors.cyanAccent : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _lifelineUsed
                        ? 'Community voting splits are now revealed below!'
                        : 'Peek at what other users are predicting for this match.',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _lifelineUsed
                ? const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 20)
                : ElevatedButton(
                    onPressed: user.lifelinesCount <= 0
                        ? () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No lifelines owned! Purchase them in the Points Shop."),
                                backgroundColor: SkorioColors.errorContainer,
                              ),
                            );
                          }
                        : _handleActivateLifeline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.lifelinesCount > 0 ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                      foregroundColor: user.lifelinesCount > 0 ? Colors.cyanAccent : Colors.white24,
                      side: BorderSide(
                        color: user.lifelinesCount > 0 ? Colors.cyanAccent.withOpacity(0.4) : Colors.white10,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                    child: Text(
                      'USE (${user.lifelinesCount})',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleActivateLifeline() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Text(
          "Use Prediction Lifeline",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          "This will consume 1 Prediction Lifeline to show what other users have predicted for this match.",
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Use Lifeline",
              style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref.read(authProvider.notifier).consumeLifeline();
    if (success && mounted) {
      setState(() {
        _lifelineUsed = true;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Prediction Lifeline active! Community trends revealed."),
          backgroundColor: Colors.cyan,
        ),
      );
    }
  }

  Widget _buildTossWinnerRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectionCard(
            label: _homeTeam,
            isSelected: _selectedTossWinner == 'home',
            onTap: () => _toggleTossWinner('home'),
            percent: _lifelineUsed ? 52 : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSelectionCard(
            label: _awayTeam,
            isSelected: _selectedTossWinner == 'away',
            onTap: () => _toggleTossWinner('away'),
            percent: _lifelineUsed ? 48 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchWinnerRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectionCard(
            label: _homeTeam,
            isSelected: _selectedMatchWinner == 'home',
            onTap: () => _toggleMatchWinner('home'),
            percent: _lifelineUsed ? 64 : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSelectionCard(
            label: _awayTeam,
            isSelected: _selectedMatchWinner == 'away',
            onTap: () => _toggleMatchWinner('away'),
            percent: _lifelineUsed ? 36 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? percent,
  }) {
    return HoverableCard(
      onTap: onTap,
      hoverScale: 1.04,
      pressScale: 0.96,
      borderRadius: BorderRadius.circular(16),
      glowColor: isSelected ? Colors.tealAccent : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? Colors.tealAccent[700]!.withOpacity(0.12) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.tealAccent : Colors.white.withOpacity(0.06),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.tealAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            if (percent != null) ...[
              const SizedBox(height: 2),
              Text(
                '$percent%',
                style: GoogleFonts.outfit(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSquadSelectorCard({
    required TextEditingController controller,
    required String? selectedName,
    required List<String> playersList,
    required Function(String) onSelect,
    required String hint,
    required String role,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: TextField(
              controller: controller,
              onChanged: (val) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                ),
                suffixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.35),
                  size: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: playersList.map((player) {
              final isSelected = selectedName == player;
              final percent = _lifelineUsed ? (role == 'batsman' ? 24 : 32) : 0; // Simple simulation for stats split

              return HoverableCard(
                onTap: () => onSelect(player),
                hoverScale: 1.06,
                pressScale: 0.94,
                borderRadius: BorderRadius.circular(100),
                glowColor: isSelected ? Colors.tealAccent : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.tealAccent.withOpacity(0.12) 
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.tealAccent 
                          : Colors.white.withOpacity(0.05),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player,
                        style: TextStyle(
                          color: isSelected ? Colors.tealAccent : Colors.white60,
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                        ),
                      ),
                      if (_lifelineUsed && percent > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($percent%)',
                          style: GoogleFonts.outfit(
                            color: Colors.cyanAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRangeSelector() {
    final ranges = ['< 140', '140-160', '160-180', '180-200', '200+'];
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: ranges.map((r) {
        final isSelected = _selectedScoreRange == r;
        return HoverableCard(
          onTap: () => _selectScoreRange(r),
          hoverScale: 1.06,
          pressScale: 0.94,
          borderRadius: BorderRadius.circular(100),
          glowColor: isSelected ? Colors.tealAccent : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.tealAccent.withOpacity(0.15) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? Colors.tealAccent : Colors.white.withOpacity(0.05),
                width: 1.0,
              ),
            ),
            child: Text(
              r,
              style: TextStyle(
                color: isSelected ? Colors.tealAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreRangeTrends() {
    final List<String> trends = ['160-180 (45%)', '180-200 (28%)', '140-160 (15%)'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: Colors.cyanAccent, size: 14),
          const SizedBox(width: 8),
          Text(
            'Community Picks: ',
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          ...trends.map((t) => Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t,
                style: GoogleFonts.outfit(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: RichText(
        text: TextSpan(
          style: SkorioTextStyles.labelSm.copyWith(
            color: Colors.white54,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
          children: [
            TextSpan(text: title),
            if (isRequired)
              TextSpan(
                text: ' *',
                style: const TextStyle(color: Colors.tealAccent),
              ),
          ],
        ),
      ),
    );
  }
}

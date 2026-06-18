import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_scheme.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/pitch_background.dart';
import '../../../core/widgets/animations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/achievements_provider.dart';
import '../providers/predictions_provider.dart';
import 'share_card_sheet.dart';

class PredictMatchScreen extends ConsumerStatefulWidget {
  final String matchId;

  const PredictMatchScreen({
    super.key,
    required this.matchId,
  });

  @override
  ConsumerState<PredictMatchScreen> createState() => _PredictMatchScreenState();
}

class _PredictMatchScreenState extends ConsumerState<PredictMatchScreen>
    with TickerProviderStateMixin {
  // Score predictors
  int _homeScore = 0;
  int _awayScore = 0;

  // Selected winner selection ('home', 'draw', 'away', or null)
  String? _selectedWinner;

  // Search input query
  final TextEditingController _searchController = TextEditingController();

  // Selected scorer
  String? _selectedScorer;

  // Timer countdown values (simulating 152:13:30)
  int _totalSecondsRemaining = 152 * 3600 + 13 * 60 + 30;
  Timer? _timer;

  // Match details mapping based on ID
  late String _homeTeamShort;
  late String _awayTeamShort;
  late String _homeFlag;
  late String _awayFlag;
  late String _matchDate;
  late List<String> _players;
  bool _isLoading = true;
  bool _initialized = false;
  bool _isSaving = false;
  bool _lifelineUsed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _simulateLoading();

    // Map match data
    if (widget.matchId == 'match_2') {
      _homeTeamShort = 'S. KOREA';
      _awayTeamShort = 'CZECH REP.';
      _homeFlag = 'https://flagcdn.com/w160/kr.png';
      _awayFlag = 'https://flagcdn.com/w160/cz.png';
      _matchDate = '6/12/2026';
      _players = [
        'Son Heung-min',
        'Hwang Hee-chan',
        'Cho Gue-sung',
        'Patrik Schick',
        'Tomas Soucek',
        'Adam Hlozek',
      ];
    } else {
      // Default to Mexico vs South Africa
      _homeTeamShort = 'MEXICO';
      _awayTeamShort = 'SOUTH AFRICA';
      _homeFlag = 'https://flagcdn.com/w160/mx.png';
      _awayFlag = 'https://flagcdn.com/w160/za.png';
      _matchDate = '6/12/2026';
      _players = [
        'Alexis Vega',
        'Álvaro Fidalgo',
        'Armando González',
        'Aubrey Modiba',
        'Santiago Giménez',
        'Percy Tau',
      ];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
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

  void _incrementHomeScore() {
    setState(() {
      _homeScore++;
    });
  }

  void _decrementHomeScore() {
    if (_homeScore > 0) {
      setState(() {
        _homeScore--;
      });
    }
  }

  void _incrementAwayScore() {
    setState(() {
      _awayScore++;
    });
  }

  void _decrementAwayScore() {
    if (_awayScore > 0) {
      setState(() {
        _awayScore--;
      });
    }
  }

  void _toggleWinner(String winner) {
    setState(() {
      if (_selectedWinner == winner) {
        _selectedWinner = null; // deselect
      } else {
        _selectedWinner = winner;
      }
    });
  }

  void _selectScorer(String player) {
    setState(() {
      if (_selectedScorer == player) {
        _selectedScorer = null; // deselect
      } else {
        _selectedScorer = player;
      }
    });
  }

  Future<void> _handleLockIn() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    final success = await ref.read(matchPredictionsProvider(widget.matchId).notifier).savePredictions(
      homeScore: _homeScore,
      awayScore: _awayScore,
      winner: _selectedWinner,
      firstScorer: _selectedScorer,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ref.read(authProvider.notifier).awardXp(amount: 10, action: 'Submit Prediction');
        
        // Achievement trigger checks
        final now = DateTime.now();
        bool isEarlyBird = false;
        try {
          final dateParts = _matchDate.split('/');
          if (dateParts.length == 3) {
            final month = int.parse(dateParts[0]);
            final day = int.parse(dateParts[1]);
            final year = int.parse(dateParts[2]);
            final matchDateTime = DateTime(year, month, day, 18, 0);
            if (matchDateTime.difference(now).inHours >= 24) {
              isEarlyBird = true;
            }
          }
        } catch (_) {}
        if (now.minute % 2 == 0) {
          isEarlyBird = true;
        }

        if (isEarlyBird) {
          ref.read(achievementsProvider.notifier).unlockAchievement('early_bird');
        }

        if ((now.hour >= 0 && now.hour < 5) || now.minute % 2 != 0) {
          ref.read(achievementsProvider.notifier).unlockAchievement('night_owl');
        }

        // Show success snack briefly then the share sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.black),
                const SizedBox(width: 8),
                const Text(
                  'Predictions Saved! 🎉',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: SkorioColors.secondary,
            duration: const Duration(milliseconds: 1500),
          ),
        );

        // Build share data — map URL flags to emoji
        final user = ref.read(authProvider).value;
        final homeEmoji = _flagUrlToEmoji(_homeFlag);
        final awayEmoji = _flagUrlToEmoji(_awayFlag);
        final shareData = PredictionShareData(
          homeTeam: _homeTeamShort,
          awayTeam: _awayTeamShort,
          homeFlag: homeEmoji,
          awayFlag: awayEmoji,
          homeScore: _homeScore,
          awayScore: _awayScore,
          firstScorer: _selectedScorer,
          winner: _selectedWinner,
          matchDate: _matchDate,
          userName: user?.name ?? 'Fan',
        );

        // Small delay to let snack appear, then show share sheet
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

  /// Maps flagcdn.com URLs like https://flagcdn.com/w160/br.png → 🇧🇷
  String _flagUrlToEmoji(String flagUrl) {
    final _ccToEmoji = {
      'br': '🇧🇷', 'ar': '🇦🇷', 'fr': '🇫🇷', 'gb-eng': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'es': '🇪🇸', 'de': '🇩🇪', 'pt': '🇵🇹', 'nl': '🇳🇱',
      'be': '🇧🇪', 'it': '🇮🇹', 'uy': '🇺🇾', 'hr': '🇭🇷',
      'mx': '🇲🇽', 'co': '🇨🇴', 'us': '🇺🇸', 'ca': '🇨🇦',
      'ma': '🇲🇦', 'sn': '🇸🇳', 'jp': '🇯🇵', 'kr': '🇰🇷',
      'au': '🇦🇺', 'ir': '🇮🇷', 'ch': '🇨🇭', 'dk': '🇩🇰',
      'ec': '🇪🇨', 'cl': '🇨🇱', 'rs': '🇷🇸', 'pl': '🇵🇱',
      'cm': '🇨🇲', 'gh': '🇬🇭', 'sa': '🇸🇦', 'qa': '🇶🇦',
      'za': '🇿🇦', 'cz': '🇨🇿', 'ng': '🇳🇬', 'eg': '🇪🇬',
    };
    // Extract country code from URL path
    final match = RegExp(r'/([a-z-]+)\.png').firstMatch(flagUrl);
    if (match == null) return '🏳';
    final cc = match.group(1) ?? '';
    return _ccToEmoji[cc] ?? '🏳';
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

        if (question.type == 'scoreline') {
          final parts = pred.answer.split('-');
          if (parts.length == 2) {
            _homeScore = int.tryParse(parts[0]) ?? 0;
            _awayScore = int.tryParse(parts[1]) ?? 0;
          }
        } else if (question.type == 'winner') {
          _selectedWinner = pred.answer;
        } else if (question.type == 'top_scorer') {
          _selectedScorer = pred.answer;
        }
      }
      _initialized = true;
      _isLoading = false;
    }
    final filteredPlayers = _players
        .where((player) =>
            player.toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: Stack(
        children: [
          // Background components
          const PitchBackground(child: SizedBox.expand()),

          // Ambient glowing backdrop blobs
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SkorioColors.primary.withOpacity(0.02),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: SkorioColors.primary.withOpacity(0.02)),
              ),
            ),
          ),

          // Main page contents or Loading indicator
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
                      // 1. App Header Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            // Back Button
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
                            
                            // Title Text
                            const Expanded(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 64.0), // center balancing spacer
                                  child: Text(
                                    'Predict Match',
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
      
                      // Scrollable Body
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 2. Teams & Timer summary Card (Staggered)
                              StaggeredEntrance(
                                delay: Duration.zero,
                                child: _buildMatchHeaderCard(),
                              ),
                              const SizedBox(height: 16),

                              // 2.5 Prediction Lifeline Activation Card
                              if (user != null) ...[
                                _buildLifelineCard(user),
                                const SizedBox(height: 24),
                              ],
      
                              // 3. Exact Scoreline Section (Staggered)
                              StaggeredEntrance(
                                delay: const Duration(milliseconds: 100),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('EXACT SCORELINE', isRequired: true),
                                    const SizedBox(height: 10),
                                    _buildScoreSelectorCard(),
                                    if (_lifelineUsed) ...[
                                      const SizedBox(height: 12),
                                      _buildScorelineTrends(),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
      
                              // 4. Winner Selection Section (Staggered)
                              StaggeredEntrance(
                                delay: const Duration(milliseconds: 180),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('WINNER (OPTIONAL)'),
                                    const SizedBox(height: 10),
                                    _buildWinnerRow(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
      
                              // 5. First Scorer Selection Section (Staggered)
                              StaggeredEntrance(
                                delay: const Duration(milliseconds: 250),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('FIRST SCORER (OPTIONAL)'),
                                    const SizedBox(height: 10),
                                    _buildFirstScorerCard(filteredPlayers),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
      
                      // 6. Lock In Predictions Button (Sticky Bottom)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: HoverableCard(
                          onTap: _isSaving ? null : _handleLockIn,
                          glowColor: SkorioColors.primary,
                          borderRadius: BorderRadius.circular(100),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: null, // Click managed by HoverableCard
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SkorioColors.primary,
                                disabledBackgroundColor: SkorioColors.primary,
                                foregroundColor: Colors.black,
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
                                        color: Colors.black,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'LOCK IN PREDICTIONS',
                                          style: SkorioTextStyles.labelMd.copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.send_rounded,
                                          color: Colors.black,
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

  // Header card: Mexican/South African Flag and Monospace Timer
  Widget _buildMatchHeaderCard() {
    const timerColor = Color(0xFFFF5A60);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF131318).withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Home Team
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
                      _homeTeamShort,
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

              // VS and Date
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: SkorioColors.primary,
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

              // Away Team
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
                      _awayTeamShort,
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

          // Monospace Timer pill outline red
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
                      'TIMER',
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

  // Exact Score Selector Card with + / - buttons
  Widget _buildScoreSelectorCard() {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Selector (Home Team Score)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScoreCircleButton(Icons.add, _incrementHomeScore),
                const SizedBox(height: 16),
                Text(
                  _homeScore.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.slashedZero()],
                  ),
                ),
                const SizedBox(height: 16),
                _buildScoreCircleButton(Icons.remove, _decrementHomeScore),
              ],
            ),
          ),

          // Dash
          Text(
            '-',
            style: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Right Selector (Away Team Score)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScoreCircleButton(Icons.add, _incrementAwayScore),
                const SizedBox(height: 16),
                Text(
                  _awayScore.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.slashedZero()],
                  ),
                ),
                const SizedBox(height: 16),
                _buildScoreCircleButton(Icons.remove, _decrementAwayScore),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rounded outline buttons inside score selector
  Widget _buildScoreCircleButton(IconData icon, VoidCallback onTap) {
    return HoverableCard(
      onTap: onTap,
      hoverScale: 1.15,
      pressScale: 0.9,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.03),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  // Winner selection row buttons (MEXICO, DRAW, SOUTH AF.)
  Widget _buildWinnerRow() {
    return Row(
      children: [
        _buildWinnerButton('home', _homeTeamShort),
        const SizedBox(width: 10),
        _buildWinnerButton('draw', 'DRAW'),
        const SizedBox(width: 10),
        _buildWinnerButton('away', _awayTeamShort),
      ],
    );
  }

  Widget _buildWinnerButton(String key, String label) {
    final isSelected = _selectedWinner == key;
    final percents = _getWinnerPercentages();
    final percentage = percents[key] ?? 0;

    return Expanded(
      child: HoverableCard(
        onTap: () => _toggleWinner(key),
        hoverScale: 1.05,
        pressScale: 0.95,
        borderRadius: BorderRadius.circular(100),
        glowColor: isSelected ? SkorioColors.secondary : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? SkorioColors.secondary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected 
                  ? SkorioColors.secondary 
                  : Colors.white.withOpacity(0.06),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? SkorioColors.secondary : Colors.white60,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              if (_lifelineUsed) ...[
                const SizedBox(height: 2),
                Text(
                  '$percentage%',
                  style: GoogleFonts.outfit(
                    color: isSelected ? SkorioColors.secondary : Colors.cyanAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // First scorer widget panel (Search box + Wrapping Chips)
  Widget _buildFirstScorerCard(List<String> playersList) {
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
          // Search box
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Type or select first scorer...',
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

          // Wrapping list of chips
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: playersList.map((player) {
              final isSelected = _selectedScorer == player;
              final scorerPercents = _getScorerPercentages();
              final percent = scorerPercents[player] ?? 0;

              return HoverableCard(
                onTap: () => _selectScorer(player),
                hoverScale: 1.06,
                pressScale: 0.94,
                borderRadius: BorderRadius.circular(100),
                glowColor: isSelected ? SkorioColors.primary : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? SkorioColors.primary.withOpacity(0.12) 
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected 
                          ? SkorioColors.primary 
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
                          color: isSelected ? SkorioColors.primary : Colors.white60,
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

  Map<String, int> _getWinnerPercentages() {
    if (widget.matchId == 'match_2') {
      return {'home': 55, 'draw': 25, 'away': 20};
    } else {
      return {'home': 48, 'draw': 32, 'away': 20};
    }
  }

  Map<String, int> _getScorerPercentages() {
    if (widget.matchId == 'match_2') {
      return {'Son Heung-min': 58, 'Hwang Hee-chan': 24, 'Cho Gue-sung': 18};
    } else {
      return {'Santiago Giménez': 46, 'Alexis Vega': 34, 'Percy Tau': 20};
    }
  }

  Widget _buildScorelineTrends() {
    final List<String> trends = widget.matchId == 'match_2'
        ? ['2-1 (45%)', '1-1 (28%)', '2-0 (15%)']
        : ['2-1 (42%)', '1-1 (30%)', '0-2 (12%)'];

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

  // Section title generator with asterisk support
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
                style: const TextStyle(color: SkorioColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

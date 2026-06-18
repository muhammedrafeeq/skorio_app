import 'dart:math' as math;
import 'dart:ui' show ImageFilter, FontFeature, lerpDouble;
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
import '../providers/games_provider.dart';

enum GameStage { selectMode, playing, gameOver }

class PenaltyShootoutScreen extends ConsumerStatefulWidget {
  const PenaltyShootoutScreen({super.key});

  @override
  ConsumerState<PenaltyShootoutScreen> createState() => _PenaltyShootoutScreenState();
}

class _PenaltyShootoutScreenState extends ConsumerState<PenaltyShootoutScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GameStage _stage = GameStage.selectMode;

  // Game Play States
  final List<bool?> _kicks = [null, null, null, null, null]; // null=unplayed, true=goal, false=saved
  int _currentKick = 0;
  int _goals = 0;

  // Animation Controllers
  late AnimationController _shotController;
  late AnimationController _netController;
  
  bool _isAnimating = false;
  String? _userDirection; // 'left', 'centre', 'right'
  String? _gkDirection;   // 'left', 'centre', 'right'
  String? _resultText;    // 'GOAL!', 'SAVED!'
  Color? _resultColor;
  Offset? _ballEntry;     // Coordinates where ball hits goal area

  @override
  void initState() {
    super.initState();
    _shotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _netController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shotController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _evaluateResult();
      }
    });
  }

  @override
  void dispose() {
    _shotController.dispose();
    _netController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _stage = GameStage.playing;
      _currentKick = 0;
      _goals = 0;
      for (int i = 0; i < 5; i++) {
        _kicks[i] = null;
      }
      _resetKickState();
    });
  }

  void _resetKickState() {
    _shotController.reset();
    _netController.reset();
    setState(() {
      _isAnimating = false;
      _userDirection = null;
      _gkDirection = null;
      _resultText = null;
      _resultColor = null;
      _ballEntry = null;
    });
  }

  void _onDirectionSelect(String direction) {
    if (_isAnimating || _stage != GameStage.playing) return;

    // AI goalkeeper randomly chooses left, centre, or right
    final options = ['left', 'centre', 'right'];
    final aiChoice = options[math.Random().nextInt(3)];

    setState(() {
      _isAnimating = true;
      _userDirection = direction;
      _gkDirection = aiChoice;
    });

    _shotController.forward();
  }

  void _evaluateResult() {
    final isGoal = _userDirection != _gkDirection;
    setState(() {
      _kicks[_currentKick] = isGoal;
      if (isGoal) {
        _goals++;
        _resultText = 'GOAL!';
        _resultColor = const Color(0xFF4ADE80);
        _netController.forward(from: 0.0);
      } else {
        _resultText = 'SAVED!';
        _resultColor = const Color(0xFFEF4444);
      }
    });

    // Wait and progress to next kick or game over
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      if (_currentKick < 4) {
        setState(() {
          _currentKick++;
          _resetKickState();
        });
      } else {
        // Game completed, add points to User Provider and persist session
        final pointsEarned = _goals * 4; // 4 points per goal
        ref.read(gamesProvider.notifier).recordPenaltySession(
          score: pointsEarned,
          goals: _goals,
        );

        setState(() {
          _stage = GameStage.gameOver;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF05050A),
      body: Stack(
        children: [
          // Theme Background Pitch
          const PitchBackground(child: SizedBox.expand()),

          // Ambient glowing back blobs
          Positioned(
            top: 100,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.04),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: const Color(0xFF10B981).withOpacity(0.04)),
              ),
            ),
          ),

          // Render Screen Stages
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _stage == GameStage.selectMode
                  ? _buildSelectModeView()
                  : _stage == GameStage.playing
                      ? _buildGameplayView()
                      : _buildGameOverView(),
            ),
          ),
        ],
      ),
    );
  }

  // Stage 1: Select Game Mode View
  Widget _buildSelectModeView() {
    final gamesState = ref.watch(gamesProvider);
    final penaltyCount = gamesState.dailyPlayCounts['penalty'] ?? 0;
    final penaltyLimit = gamesState.dailyLimits['penalty'] ?? 5;
    final remainingPenalty = penaltyLimit - penaltyCount;
    final isLimitReached = remainingPenalty <= 0;

    return SingleChildScrollView(
      key: const ValueKey('select_mode'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header / Back navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () {
                  context.go('/games');
                },
              ),
              Text(
                'Back',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Big 3D Vector Graphic Hero
          FloatingWidget(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ADE80).withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withOpacity(0.12),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(80, 80),
                painter: PenaltyBallPainter(),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Penalty Shootout',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Test your skills or battle against your friends.',
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // 7-DAY CAREER STATS Card
          _buildStatsCard(),
          const SizedBox(height: 24),

          // Solo Game Mode Button
          HoverableCard(
            onTap: isLimitReached ? null : _startGame,
            glowColor: isLimitReached ? Colors.transparent : const Color(0xFF4ADE80),
            borderRadius: BorderRadius.circular(20),
            child: Opacity(
              opacity: isLimitReached ? 0.5 : 1.0,
              child: GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Ball icon inside glow circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLimitReached
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFF4ADE80).withOpacity(0.1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isLimitReached ? '🔒' : '⚽',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Play Solo',
                                style: GoogleFonts.outfit(
                                  color: isLimitReached ? Colors.white30 : const Color(0xFF4ADE80),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                isLimitReached
                                    ? 'Limit Reached'
                                    : '$remainingPenalty / $penaltyLimit Left',
                                style: GoogleFonts.outfit(
                                  color: isLimitReached ? const Color(0xFFEF4444) : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Practice penalties against AI goalkeeper. Earn points for the global leaderboard.',
                            style: GoogleFonts.outfit(
                              color: isLimitReached ? Colors.white24 : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Challenge a Friend Mode (Disabled)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      alignment: Alignment.center,
                      child: const Text('⚔️', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge a Friend',
                            style: GoogleFonts.outfit(
                              color: Colors.white30,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Play a round and generate a battle link. Send it to a friend to see if they can beat your score.',
                            style: GoogleFonts.outfit(
                              color: Colors.white24,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA78BFA).withOpacity(0.1),
                      border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'COMING SOON',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFC4B5FD),
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
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

  Widget _buildStatsCard() {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Text(
            '7-DAY CAREER STATS',
            style: GoogleFonts.outfit(
              color: const Color(0xFF4ADE80),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCol(Icons.star_outline, '5', 'BEST PTS', Colors.greenAccent),
              _buildStatCol(Icons.gps_fixed, '2', 'GOALS', Colors.amberAccent),
              _buildStatCol(Icons.local_fire_department, '1', 'GAMES', Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(IconData icon, String val, String title, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          val,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Stage 2: Active Gameplay View
  Widget _buildGameplayView() {
    return Column(
      key: const ValueKey('playing'),
      children: [
        // App bar Row matching Image 2
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back to Select Mode
              GestureDetector(
                onTap: () {
                  setState(() {
                    _stage = GameStage.selectMode;
                  });
                },
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios, color: Colors.white60, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Title
              Text(
                'Penalty Shootout',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),

              // 5-kick progress circles
              Row(
                children: List.generate(5, (index) {
                  final isPlayed = _kicks[index] != null;
                  final isGoal = _kicks[index] == true;
                  final isActive = _currentKick == index;

                  Color borderClr = Colors.white24;
                  Color bgClr = Colors.transparent;
                  Color textClr = Colors.white38;

                  if (isActive) {
                    borderClr = const Color(0xFF4ADE80);
                    textClr = const Color(0xFF4ADE80);
                  } else if (isPlayed) {
                    borderClr = isGoal ? const Color(0xFF4ADE80) : Colors.white12;
                    bgClr = isGoal ? const Color(0xFF4ADE80) : Colors.white12;
                    textClr = isGoal ? Colors.black : Colors.white38;
                  }

                  return Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgClr,
                      border: Border.all(color: borderClr, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.outfit(
                        color: textClr,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Subtitle instructions
        Text(
          'KICK ${_currentKick + 1} OF 5',
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick your direction',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 24),

        // Responsive Pitch Area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AspectRatio(
            aspectRatio: 1.3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                // Define coordinates
                final ballStart = Offset(w / 2, h * 0.82);
                
                // Targets
                final leftTarget = Offset(w * 0.28, h * 0.42);
                final centerTarget = Offset(w / 2, h * 0.38);
                final rightTarget = Offset(w * 0.72, h * 0.42);

                Offset ballEnd = centerTarget;
                if (_userDirection == 'left') ballEnd = leftTarget;
                if (_userDirection == 'right') ballEnd = rightTarget;

                // Keepers starting and diving targets
                final gkStart = Offset(w / 2, h * 0.46);
                final gkLeftTarget = Offset(w * 0.35, h * 0.52);
                final gkCenterTarget = Offset(w / 2, h * 0.46);
                final gkRightTarget = Offset(w * 0.65, h * 0.52);

                Offset gkEnd = gkCenterTarget;
                double gkEndRotation = 0.0;
                if (_gkDirection == 'left') {
                  gkEnd = gkLeftTarget;
                  gkEndRotation = -0.55; // Radians (~32 deg)
                }
                if (_gkDirection == 'right') {
                  gkEnd = gkRightTarget;
                  gkEndRotation = 0.55;
                }

                // If user's direction matches keeper's direction, keeper intercepts the ball!
                final isSaved = _userDirection == _gkDirection && _userDirection != null;
                if (isSaved) {
                  // Ball stops at keeper's body/hands
                  if (_userDirection == 'left') {
                    ballEnd = Offset(w * 0.34, h * 0.56);
                  } else if (_userDirection == 'right') {
                    ballEnd = Offset(w * 0.66, h * 0.56);
                  } else {
                    ballEnd = Offset(w / 2, h * 0.5);
                  }
                }

                // Store ballEntry coordinates for Net Shaking
                if (_ballEntry == null && _userDirection != null) {
                  _ballEntry = ballEnd;
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Football Stadium pitch canvas
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _netController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: GoalPostPainter(
                                netShake: _netController.value,
                                ballEntry: _ballEntry,
                              ),
                            );
                          },
                        ),
                      ),

                      // Ambient glowing bokeh stadium lights
                      Positioned(
                        top: h * 0.1,
                        left: w * 0.1,
                        child: _buildBokehLight(Colors.blue, 32),
                      ),
                      Positioned(
                        top: h * 0.15,
                        left: w * 0.3,
                        child: _buildBokehLight(Colors.purple, 24),
                      ),
                      Positioned(
                        top: h * 0.12,
                        right: w * 0.25,
                        child: _buildBokehLight(Colors.amber, 28),
                      ),
                      Positioned(
                        top: h * 0.08,
                        right: w * 0.08,
                        child: _buildBokehLight(Colors.red, 30),
                      ),

                      // Goalkeeper Silhouette
                      AnimatedBuilder(
                        animation: _shotController,
                        builder: (context, child) {
                          final t = _shotController.value;
                          final pos = Offset.lerp(gkStart, gkEnd, t)!;
                          final rot = lerpDouble(0.0, gkEndRotation, t)!;
                          final gkWidth = w * 0.26;
                          final gkHeight = h * 0.28;

                          return Positioned(
                            left: pos.dx - gkWidth / 2,
                            top: pos.dy - gkHeight / 2,
                            width: gkWidth,
                            height: gkHeight,
                            child: Transform.rotate(
                              angle: rot,
                              child: CustomPaint(
                                painter: GoalkeeperPainter(
                                  primaryColor: const Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Soccer Ball physics
                      AnimatedBuilder(
                        animation: _shotController,
                        builder: (context, child) {
                          final t = _shotController.value;
                          final pos = Offset.lerp(ballStart, ballEnd, t)!;
                          final scale = 1.0 - (1.0 - 0.42) * t;
                          final rotate = t * 6 * math.pi;
                          final ballSize = w * 0.12;

                          return Positioned(
                            left: pos.dx - ballSize / 2,
                            top: pos.dy - ballSize / 2,
                            width: ballSize,
                            height: ballSize,
                            child: Transform.scale(
                              scale: scale,
                              child: Transform.rotate(
                                angle: rotate,
                                child: CustomPaint(
                                  painter: SoccerBallPainter(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Goal / Saved visual feedback flash overlay
                      if (_resultText != null)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.2),
                            alignment: Alignment.center,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 300),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value * 1.2,
                                  child: Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _resultColor!.withOpacity(0.5),
                                          width: 2.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _resultColor!.withOpacity(0.25),
                                            blurRadius: 24,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _resultText!,
                                        style: GoogleFonts.outfit(
                                          color: _resultColor,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const Spacer(),

        // Direction selector buttons (LEFT, CENTRE, RIGHT)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDirBtn('left', Icons.arrow_back, 'LEFT'),
              const SizedBox(width: 12),
              _buildDirBtn('centre', Icons.circle, 'CENTRE'),
              const SizedBox(width: 12),
              _buildDirBtn('right', Icons.arrow_forward, 'RIGHT'),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBokehLight(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
      ),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: color.withOpacity(0.12),
        ),
      ),
    );
  }

  Widget _buildDirBtn(String direction, IconData icon, String label) {
    final isSelected = _userDirection == direction;
    final isSelectDisabled = _isAnimating;

    Color borderClr = Colors.white.withOpacity(0.04);
    Color bgClr = Colors.white.withOpacity(0.02);
    Color contentClr = Colors.white60;

    if (isSelected) {
      borderClr = const Color(0xFF4ADE80);
      bgClr = const Color(0xFF4ADE80).withOpacity(0.08);
      contentClr = const Color(0xFF4ADE80);
    }

    return Expanded(
      child: HoverableCard(
        onTap: isSelectDisabled ? null : () => _onDirectionSelect(direction),
        glowColor: const Color(0xFF4ADE80),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: bgClr,
            border: Border.all(color: borderClr, width: 1.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: contentClr, size: 20),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: contentClr,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Stage 3: Game Over Score Summary Overlay
  Widget _buildGameOverView() {
    final pointsEarned = _goals * 4;

    return Center(
      key: const ValueKey('game_over'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ADE80).withOpacity(0.1),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Winner Star
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ADE80).withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.emoji_events, color: Color(0xFF4ADE80), size: 32),
            ),
            const SizedBox(height: 20),

            Text(
              'Solo Round Finished!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Practice makes perfect. Keep scoring!',
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Score Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGameOverStat('GOALS', '$_goals / 5', const Color(0xFF4ADE80)),
                Container(width: 1.2, height: 40, color: Colors.white10),
                _buildGameOverStat('PTS EARNED', '+$pointsEarned PTS', const Color(0xFF38BDF8)),
              ],
            ),
            const SizedBox(height: 32),

            // Play Again
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF15803D), Color(0xFF4ADE80)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    'PLAY AGAIN',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Exit back to Arena
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  context.go('/games');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  'EXIT TO ARENA',
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFeatures: [const FontFeature.slashedZero()],
          ),
        ),
      ],
    );
  }
}

// 3D-like custom paint ball hero for selecting stages (matches games_screen Penalty design but high res)
class PenaltyBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final scale = w / 80.0;
    
    // Shadow ellipse
    final shadowPaint = Paint()
      ..color = const Color(0xFF4ADE80).withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(40 * scale, 72 * scale),
        width: 32 * scale,
        height: 8 * scale,
      ),
      shadowPaint,
    );

    // Ball body circle
    final ballCenter = Offset(40 * scale, 36 * scale);
    final ballRadius = 26 * scale;
    final ballBodyPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF4ADE80), Color(0xFF15803D)],
        center: const Alignment(-0.15, -0.15),
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(ballCenter, ballRadius, ballBodyPaint);

    // Pentagon patches
    final patchPaint = Paint()
      ..color = const Color(0xFF166534).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    void drawScaledPath(List<Offset> pts, Paint paint) {
      final path = Path()..moveTo(pts[0].dx * scale, pts[0].dy * scale);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx * scale, pts[i].dy * scale);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    drawScaledPath(const [
      Offset(40, 14),
      Offset(45, 18),
      Offset(43, 24),
      Offset(37, 24),
      Offset(35, 18),
    ], patchPaint);

    drawScaledPath(const [
      Offset(56, 25),
      Offset(58, 31),
      Offset(53, 34),
      Offset(49, 30),
      Offset(51, 24),
    ], patchPaint);

    drawScaledPath(const [
      Offset(51, 47),
      Offset(48, 52),
      Offset(42, 51),
      Offset(41, 45),
      Offset(46, 42),
    ], patchPaint);

    drawScaledPath(const [
      Offset(29, 47),
      Offset(24, 44),
      Offset(23, 50),
      Offset(17, 51),
      Offset(14, 46),
    ], patchPaint);

    drawScaledPath(const [
      Offset(24, 25),
      Offset(22, 31),
      Offset(26, 35),
      Offset(21, 32),
    ], patchPaint);

    // Shine circle
    final shineCenter = Offset(32 * scale, 26 * scale);
    final shineRadius = 8 * scale;
    final shinePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: shineCenter, radius: shineRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(shineCenter, shineRadius, shinePaint);

    // Goal post tubes
    final postPaint = Paint()..style = PaintingStyle.fill;

    postPaint.color = const Color(0xFFD1D5DB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14 * scale, 60 * scale, 52 * scale, 4 * scale),
        Radius.circular(2 * scale),
      ),
      postPaint,
    );

    postPaint.color = const Color(0xFF9CA3AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14 * scale, 56 * scale, 4 * scale, 8 * scale),
        Radius.circular(1.5 * scale),
      ),
      postPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(62 * scale, 56 * scale, 4 * scale, 8 * scale),
        Radius.circular(1.5 * scale),
      ),
      postPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom paint goal post and dynamic net shaking mesh
class GoalPostPainter extends CustomPainter {
  final double netShake;
  final Offset? ballEntry;

  GoalPostPainter({required this.netShake, this.ballEntry});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grass turf (bottom 20%)
    final grassPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF064E3B), Color(0xFF065F46)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.78, w, h * 0.22))
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), grassPaint);

    // Grid details for grass field lines (micro details)
    final linesPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.88), width: w * 0.36, height: h * 0.08),
      linesPaint,
    );
    canvas.drawCircle(Offset(w / 2, h * 0.88), 1.5, Paint()..color = Colors.white.withOpacity(0.3));

    // Goal Post coordinates
    final leftPostX = w * 0.2;
    final rightPostX = w * 0.8;
    final crossbarY = h * 0.28;
    final bottomY = h * 0.78;

    // Net mesh painting
    final netPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const int verticalGridLines = 14;
    const int horizontalGridLines = 7;

    for (int i = 0; i <= verticalGridLines; i++) {
      final t = i / verticalGridLines;
      final x = leftPostX + (rightPostX - leftPostX) * t;

      final path = Path();
      path.moveTo(x, crossbarY);

      for (int j = 1; j <= horizontalGridLines; j++) {
        final u = j / horizontalGridLines;
        final y = crossbarY + (bottomY - crossbarY) * u;

        double dx = 0.0;
        double dy = 0.0;
        if (netShake > 0.0 && ballEntry != null) {
          final dist = (Offset(x, y) - ballEntry!).distance;
          final influence = math.max(0.0, 1.0 - dist / (w * 0.32));
          dx = math.sin(netShake * 4 * math.pi) * 8.0 * influence;
          dy = math.cos(netShake * 4 * math.pi) * 4.0 * influence;
        }

        path.lineTo(x + dx, y + dy);
      }
      canvas.drawPath(path, netPaint);
    }

    for (int j = 0; j <= horizontalGridLines; j++) {
      final u = j / horizontalGridLines;
      final y = crossbarY + (bottomY - crossbarY) * u;

      final path = Path();
      path.moveTo(leftPostX, y);

      for (int i = 1; i <= verticalGridLines; i++) {
        final t = i / verticalGridLines;
        final x = leftPostX + (rightPostX - leftPostX) * t;

        double dx = 0.0;
        double dy = 0.0;
        if (netShake > 0.0 && ballEntry != null) {
          final dist = (Offset(x, y) - ballEntry!).distance;
          final influence = math.max(0.0, 1.0 - dist / (w * 0.32));
          dx = math.sin(netShake * 4 * math.pi) * 8.0 * influence;
          dy = math.cos(netShake * 4 * math.pi) * 4.0 * influence;
        }

        path.lineTo(x + dx, y + dy);
      }
      canvas.drawPath(path, netPaint);
    }

    // Shadow of Goal Posts
    final postShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(leftPostX, bottomY), Offset(leftPostX + 4, bottomY + 2), postShadowPaint);
    canvas.drawLine(Offset(rightPostX, bottomY), Offset(rightPostX + 4, bottomY + 2), postShadowPaint);

    // Goal Post Tubes (white)
    final postPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final goalPath = Path()
      ..moveTo(leftPostX, bottomY)
      ..lineTo(leftPostX, crossbarY)
      ..lineTo(rightPostX, crossbarY)
      ..lineTo(rightPostX, bottomY);
    canvas.drawPath(goalPath, postPaint);

    // Highlight border / 3D depth
    final postHighlightPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(goalPath, postHighlightPaint);
  }

  @override
  bool shouldRepaint(covariant GoalPostPainter oldDelegate) =>
      oldDelegate.netShake != netShake || oldDelegate.ballEntry != ballEntry;
}

// Custom paint goalkeeper sprite representation
class GoalkeeperPainter extends CustomPainter {
  final Color primaryColor;

  GoalkeeperPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow under goalie
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.95), width: w * 0.54, height: h * 0.12),
      shadowPaint,
    );

    // Jersey / Body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, primaryColor.withBlue(90).withGreen(90)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.3, h * 0.35, w * 0.4, h * 0.45))
      ..style = PaintingStyle.fill;
    
    final bodyPath = Path()
      ..moveTo(w * 0.35, h * 0.35)
      ..lineTo(w * 0.65, h * 0.35)
      ..lineTo(w * 0.58, h * 0.72)
      ..lineTo(w * 0.42, h * 0.72)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Head
    final headPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h * 0.22), h * 0.09, headPaint);

    // Cap
    final capPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w / 2, h * 0.21), radius: h * 0.09),
      math.pi,
      math.pi,
      true,
      capPaint,
    );

    // Arms (Drawn extending outwards to block)
    final armPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.35, h * 0.4), Offset(w * 0.14, h * 0.26), armPaint);
    canvas.drawLine(Offset(w * 0.65, h * 0.4), Offset(w * 0.86, h * 0.26), armPaint);

    // Gloves (Neon Orange)
    final glovePaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.13, h * 0.25), h * 0.08, glovePaint);
    canvas.drawCircle(Offset(w * 0.87, h * 0.25), h * 0.08, glovePaint);

    // Shorts (Dark Purple)
    final shortsPaint = Paint()
      ..color = const Color(0xFF2E1065)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.39, h * 0.72, w * 0.22, h * 0.1), shortsPaint);

    // Legs / Boots
    final legPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(Offset(w * 0.43, h * 0.82), Offset(w * 0.43, h * 0.92), legPaint);
    canvas.drawLine(Offset(w * 0.57, h * 0.82), Offset(w * 0.57, h * 0.92), legPaint);

    final bootPaint = Paint()
      ..color = const Color(0xFF84CC16)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(w * 0.4, h * 0.9, w * 0.07, h * 0.05), bootPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.53, h * 0.9, w * 0.07, h * 0.05), bootPaint);
  }

  @override
  bool shouldRepaint(covariant GoalkeeperPainter oldDelegate) => false;
}

// 2D Vector style soccer ball painter
class SoccerBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    // Ball Base Body with a subtle greyish radial gradient
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Colors.white, Color(0xFFCBD5E1)],
        center: const Alignment(-0.18, -0.18),
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, bodyPaint);

    // Pentagons
    final pentagonPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    void drawPentagon(Offset pt, double sizeRad) {
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final angle = i * 72 * math.pi / 180 - math.pi / 2;
        final x = pt.dx + sizeRad * math.cos(angle);
        final y = pt.dy + sizeRad * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, pentagonPaint);
    }

    // Center pentagon
    drawPentagon(center, r * 0.28);

    // Outer connecting mesh lines
    final linePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 5; i++) {
      final angle = i * 72 * math.pi / 180 - math.pi / 2;
      final cornerX = center.dx + r * 0.28 * math.cos(angle);
      final cornerY = center.dy + r * 0.28 * math.sin(angle);

      final edgeX = center.dx + r * math.cos(angle);
      final edgeY = center.dy + r * math.sin(angle);

      canvas.drawLine(Offset(cornerX, cornerY), Offset(edgeX, edgeY), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SoccerBallPainter oldDelegate) => false;
}

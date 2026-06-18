import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_scheme.dart';
import '../../../core/widgets/nav_drawer.dart';
import '../../../core/widgets/pitch_background.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/animations.dart';
import '../../auth/providers/auth_provider.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _allGames = [
    {
      'id': 'penalty', 'title': 'Penalty Shootout', 'badge': 'DAILY', 'maxPts': '20',
      'accent': Color(0xFF4ADE80), 'bgColors': [Color(0xFF052E16), Color(0xFF15803D)],
    },
    {
      'id': 'trivia', 'title': 'Football Trivia', 'badge': 'DAILY', 'maxPts': '30',
      'accent': Color(0xFF38BDF8), 'bgColors': [Color(0xFF082F49), Color(0xFF0369A1)],
    },
    {
      'id': 'who_am_i', 'title': 'Who Am I?', 'badge': 'DAILY', 'maxPts': '15',
      'accent': Color(0xFF2DD4BF), 'bgColors': [Color(0xFF042F2E), Color(0xFF0F766E)],
    },
    {
      'id': 'flags', 'title': 'Flag Quiz', 'badge': 'DAILY', 'maxPts': '20',
      'accent': Color(0xFFEC4899), 'bgColors': [Color(0xFF2D0618), Color(0xFF9D174D)],
    },
    {
      'id': 'first_goal', 'title': 'First Goal Timer', 'badge': 'PER MATCH', 'maxPts': '20',
      'accent': Color(0xFFFBBF24), 'bgColors': [Color(0xFF1C1400), Color(0xFFB45309)],
    },
    {
      'id': 'formation', 'title': 'Formation Predictor', 'badge': 'PER MATCH', 'maxPts': '20',
      'accent': Color(0xFFA78BFA), 'bgColors': [Color(0xFF1E1035), Color(0xFF6D28D9)],
    },
    {
      'id': 'bracket', 'title': 'Tournament Bracket', 'badge': 'ONE-SHOT', 'maxPts': '100+',
      'accent': Color(0xFFFACC15), 'bgColors': [Color(0xFF1A1200), Color(0xFFA16207)],
    },
    {
      'id': 'spin', 'title': 'Daily Spin Wheel', 'badge': 'DAILY', 'maxPts': '50',
      'accent': Color(0xFF8B80FF), 'bgColors': [Color(0xFF1A0833), Color(0xFF4C1D95)],
    },
    {
      'id': 'sportle', 'title': 'Sportle', 'badge': 'DAILY', 'maxPts': '10',
      'accent': Color(0xFF43DF9E), 'bgColors': [Color(0xFF0C1A0C), Color(0xFF14532D)],
    },
    {
      'id': 'survivor', 'title': 'Last Team Standing', 'badge': 'SEASON', 'maxPts': '50',
      'accent': Color(0xFFFF6B6B), 'bgColors': [Color(0xFF2B0D0D), Color(0xFF7F1D1D)],
    },
  ];

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

  void _onGameTapUp(String id, String title) {
    const routes = {
      'penalty':    '/games/penalty',
      'trivia':     '/games/trivia',
      'first_goal': '/games/first-goal',
      'formation':  '/games/formation',
      'bracket':    '/games/bracket',
      'who_am_i':   '/games/who-am-i',
      'flags':      '/games/flags',
      'spin':       '/games/spin',
      'sportle':    '/games/sportle',
      'survivor':   '/games/survivor',
    };
    if (routes.containsKey(id)) {
      context.push(routes[id]!);
      return;
    }

    // Show Coming Soon SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sports_esports, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Coming Soon: Play $title to earn points!',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: SkorioColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final gamePoints = user?.points ?? 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: SkorioColors.baseBg,
      appBar: TopBar(scaffoldKey: _scaffoldKey, activeTab: 'games'),
      endDrawer: const NavDrawer(activeTab: 'games'),
      body: Stack(
        children: [
          // Background Pitch Layout
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
                color: const Color(0xFFA855F7).withOpacity(0.04),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: const Color(0xFFA855F7).withOpacity(0.04)),
              ),
            ),
          ),

          Positioned(
            bottom: 150,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.03),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 95, sigmaY: 95),
                child: Container(color: const Color(0xFF6366F1).withOpacity(0.03)),
              ),
            ),
          ),

          // Main Scroll View or Loading overlay spinner
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
                          'Loading Arena Setup...',
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
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 24.0,
                    bottom: 40.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hero / Header Area with staggered entrance
                      StaggeredEntrance(
                        delay: Duration.zero,
                        child: Center(
                          child: Column(
                            children: [
                              // Mini Games Arena Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA78BFA).withOpacity(0.1),
                                  border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.sports_esports_outlined, color: Color(0xFFA78BFA), size: 14),
                                    const SizedBox(width: 8),
                                    Text(
                                      'MINI GAMES ARENA',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFA78BFA),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Play & Earn Points',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Six games. One leaderboard. Compete daily.',
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Games Leaderboard Action Button
                              InkWell(
                                onTap: () => context.push('/games/leaderboard'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA78BFA).withOpacity(0.08),
                                    border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.emoji_events, color: Color(0xFFC4B5FD), size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Games Leaderboard',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFC4B5FD),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right, color: Color(0xFFC4B5FD), size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Two-Column Games Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: _allGames.length,
                        itemBuilder: (context, index) {
                          final game = _allGames[index];
                          final id = game['id'] as String;
                          final title = game['title'] as String;
                          final badge = game['badge'] as String;
                          final maxPts = game['maxPts'] as String;
                          final accent = game['accent'] as Color;
                          final bgColors = game['bgColors'] as List<Color>;

                          return StaggeredEntrance(
                            delay: Duration(milliseconds: 150 + index * 70),
                            child: Column(
                              children: [
                                // iOS-Style Game Tile
                                Expanded(
                                  child: HoverableCard(
                                    onTap: () => _onGameTapUp(id, title),
                                    glowColor: accent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: bgColors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.06),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Stack(
                                          children: [
                                            // iOS Gloss Highlight Top
                                            Positioned(
                                              top: 0,
                                              left: 0,
                                              right: 0,
                                              height: 60,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.only(
                                                    topLeft: Radius.circular(20),
                                                    topRight: Radius.circular(20),
                                                  ),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0.18),
                                                      Colors.white.withOpacity(0.0),
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // 3D Vector Graphic floating infinitely inside tile
                                            Positioned.fill(
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: FloatingWidget(
                                                  isAnimated: true,
                                                  child: _buildGameIcon(id),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Metadata label & title below
                                Text(
                                  title,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent.withOpacity(0.1),
                                        border: Border.all(color: accent.withOpacity(0.2)),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        badge,
                                        style: GoogleFonts.outfit(
                                          color: accent,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$maxPts pts',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white24,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // 3. User Points Summary Banner with staggered entrance
                      if (gamePoints > 0)
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 650),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFA855F7).withOpacity(0.08),
                                  const Color(0xFF6366F1).withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'YOUR GAMES SCORE',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFA78BFA).withOpacity(0.6),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$gamePoints PTS',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFA78BFA),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        fontFeatures: [const FontFeature.slashedZero()],
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.auto_awesome,
                                  color: const Color(0xFFA78BFA).withOpacity(0.3),
                                  size: 24,
                                ),
                              ],
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

  // Graphic Builder for each Game Tile
  Widget _buildGameIcon(String id) {
    switch (id) {
      case 'penalty':
        return CustomPaint(
          size: const Size(56, 56),
          painter: PenaltyPainter(),
        );
      case 'trivia':
        return CustomPaint(
          size: const Size(56, 56),
          painter: TriviaPainter(),
        );
      case 'who_am_i':
        return CustomPaint(
          size: const Size(56, 56),
          painter: WhoAmIPainter(),
        );
      case 'first_goal':
        return CustomPaint(
          size: const Size(56, 56),
          painter: ClockPainter(),
        );
      case 'formation':
        return CustomPaint(
          size: const Size(56, 56),
          painter: FormationPainter(),
        );
      case 'bracket':
        return CustomPaint(
          size: const Size(56, 56),
          painter: BracketPainter(),
        );
      default:
        return const Icon(Icons.sports_esports, color: Colors.white, size: 24);
    }
  }
}

// Custom Painter for Penalty Shootout goalpost & ball (replicates Icon3dPenalty SVG exactly)
class PenaltyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Scale everything relative to 80x80 canvas size
    final scale = w / 80.0;
    
    // 1. Shadow ellipse at (40, 72), rx=16, ry=4
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

    // 2. Ball body circle at (40, 36), r=26
    final ballCenter = Offset(40 * scale, 36 * scale);
    final ballRadius = 26 * scale;
    final ballBodyPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF4ADE80), Color(0xFF15803D)],
        center: const Alignment(-0.1, -0.1),
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius))
      ..style = PaintingStyle.fill;
    
    // Draw ball glow shadow
    canvas.drawCircle(ballCenter, ballRadius, ballBodyPaint);

    // 3. Pentagon patches (relative points converted to absolute, scaled)
    final patchPaint = Paint()
      ..color = const Color(0xFF166534).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    void drawScaledPath(List<Offset> pts, Paint paint) {
      final path = Path()..moveTo(pts[0].dx * scale, pts[0].dy * scale);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx * scale, pts[i].dy * scale);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Patch 1: M40 14 l5 4 -2 6 -6 0 -2-6z
    drawScaledPath(const [
      Offset(40, 14),
      Offset(45, 18),
      Offset(43, 24),
      Offset(37, 24),
      Offset(35, 18),
    ], patchPaint);

    // Patch 2: M56 25 l2 6 -5 3 -4-4 2-6z
    drawScaledPath(const [
      Offset(56, 25),
      Offset(58, 31),
      Offset(53, 34),
      Offset(49, 30),
      Offset(51, 24),
    ], patchPaint);

    // Patch 3: M51 47 l-3 5 -6-1 -1-6 5-3z
    drawScaledPath(const [
      Offset(51, 47),
      Offset(48, 52),
      Offset(42, 51),
      Offset(41, 45),
      Offset(46, 42),
    ], patchPaint);

    // Patch 4: M29 47 l-5-3 -1 6 -6 1 -3-5z
    drawScaledPath(const [
      Offset(29, 47),
      Offset(24, 44),
      Offset(23, 50),
      Offset(17, 51),
      Offset(14, 46),
    ], patchPaint);

    // Patch 5: M24 25 l-2 6 4 4 -5-3z (opacity 0.7)
    final patchPaint5 = Paint()
      ..color = const Color(0xFF166534).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    drawScaledPath(const [
      Offset(24, 25),
      Offset(22, 31),
      Offset(26, 35),
      Offset(21, 32),
    ], patchPaint5);

    // 4. Shine circle at (33, 27), r=7
    final shineCenter = Offset(33 * scale, 27 * scale);
    final shineRadius = 7 * scale;
    final shinePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: shineCenter, radius: shineRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(shineCenter, shineRadius, shinePaint);

    // 5. Goal post at bottom
    final postPaint = Paint()..style = PaintingStyle.fill;

    // rect x="14" y="60" width="52" height="4" rx="2" fill="#d1d5db"
    postPaint.color = const Color(0xFFD1D5DB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14 * scale, 60 * scale, 52 * scale, 4 * scale),
        Radius.circular(2 * scale),
      ),
      postPaint,
    );

    // rect x="14" y="56" width="4" height="8" rx="1.5" fill="#9ca3af"
    postPaint.color = const Color(0xFF9CA3AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14 * scale, 56 * scale, 4 * scale, 8 * scale),
        Radius.circular(1.5 * scale),
      ),
      postPaint,
    );

    // rect x="62" y="56" width="4" height="8" rx="1.5" fill="#9ca3af"
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(62 * scale, 56 * scale, 4 * scale, 8 * scale),
        Radius.circular(1.5 * scale),
      ),
      postPaint,
    );

    // rect x="14" y="56" width="52" height="2" rx="1" fill="#f9fafb" opacity="0.5"
    postPaint.color = const Color(0xFFF9FAFB).withOpacity(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14 * scale, 56 * scale, 52 * scale, 2 * scale),
        Radius.circular(1 * scale),
      ),
      postPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Football Trivia brain & badge (replicates Icon3dTrivia SVG exactly)
class TriviaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = w / 80.0;

    // 1. Shadow ellipse at (40, 73), rx=14, ry=3.5
    final shadowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(40 * scale, 73 * scale),
        width: 28 * scale,
        height: 7 * scale,
      ),
      shadowPaint,
    );

    // 2. Brain shape
    // Path: M40 15 C28 15 20 23 20 32 C20 37 22 41 24 44 C20 46 18 50 19 54 C20 59 25 62 30 62 L50 62 C55 62 60 59 61 54 C62 50 60 46 56 44 C58 41 60 37 60 32 C60 23 52 15 40 15Z
    final brainPath = Path()
      ..moveTo(40 * scale, 15 * scale)
      ..cubicTo(28 * scale, 15 * scale, 20 * scale, 23 * scale, 20 * scale, 32 * scale)
      ..cubicTo(20 * scale, 37 * scale, 22 * scale, 41 * scale, 24 * scale, 44 * scale)
      ..cubicTo(20 * scale, 46 * scale, 18 * scale, 50 * scale, 19 * scale, 54 * scale)
      ..cubicTo(20 * scale, 59 * scale, 25 * scale, 62 * scale, 30 * scale, 62 * scale)
      ..lineTo(50 * scale, 62 * scale)
      ..cubicTo(55 * scale, 62 * scale, 60 * scale, 59 * scale, 61 * scale, 54 * scale)
      ..cubicTo(62 * scale, 50 * scale, 60 * scale, 46 * scale, 56 * scale, 44 * scale)
      ..cubicTo(58 * scale, 41 * scale, 60 * scale, 37 * scale, 60 * scale, 32 * scale)
      ..cubicTo(60 * scale, 23 * scale, 52 * scale, 15 * scale, 40 * scale, 15 * scale)
      ..close();

    final brainPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF7DD3FC), Color(0xFF0369A1)],
        center: const Alignment(-0.2, -0.2),
      ).createShader(brainPath.getBounds())
      ..style = PaintingStyle.fill;
    
    // Draw brain body
    canvas.drawPath(brainPath, brainPaint);

    // 3. Brain split line: M40 18 Q38 32 40 46 Q42 32 40 18
    final linePaint = Paint()
      ..color = const Color(0xFF0284C7).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;

    final splitLine = Path()
      ..moveTo(40 * scale, 18 * scale)
      ..quadraticBezierTo(38 * scale, 32 * scale, 40 * scale, 46 * scale)
      ..quadraticBezierTo(42 * scale, 32 * scale, 40 * scale, 18 * scale);
    canvas.drawPath(splitLine, linePaint);

    // 4. Wrinkles paint
    final wrinklePaint = Paint()
      ..color = const Color(0xFF0284C7).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale
      ..strokeCap = StrokeCap.round;

    // Left lobe wrinkles
    canvas.drawPath(
        Path()
          ..moveTo(24 * scale, 30 * scale)
          ..quadraticBezierTo(27 * scale, 27 * scale, 30 * scale, 30 * scale),
        wrinklePaint);
    canvas.drawPath(
        Path()
          ..moveTo(22 * scale, 38 * scale)
          ..quadraticBezierTo(26 * scale, 35 * scale, 29 * scale, 38 * scale),
        wrinklePaint);
    canvas.drawPath(
        Path()
          ..moveTo(21 * scale, 47 * scale)
          ..quadraticBezierTo(25 * scale, 44 * scale, 28 * scale, 47 * scale),
        wrinklePaint);

    // Right lobe wrinkles
    canvas.drawPath(
        Path()
          ..moveTo(56 * scale, 30 * scale)
          ..quadraticBezierTo(53 * scale, 27 * scale, 50 * scale, 30 * scale),
        wrinklePaint);
    canvas.drawPath(
        Path()
          ..moveTo(58 * scale, 38 * scale)
          ..quadraticBezierTo(54 * scale, 35 * scale, 51 * scale, 38 * scale),
        wrinklePaint);
    canvas.drawPath(
        Path()
          ..moveTo(59 * scale, 47 * scale)
          ..quadraticBezierTo(55 * scale, 44 * scale, 52 * scale, 47 * scale),
        wrinklePaint);

    // 5. Shine ellipse at (31, 24), rx=6, ry=5
    final shineCenter = Offset(31 * scale, 24 * scale);
    final shinePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromCenter(center: shineCenter, width: 12 * scale, height: 10 * scale))
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(center: shineCenter, width: 12 * scale, height: 10 * scale), shinePaint);

    // 6. Question mark badge: circle cx="57" cy="20" r="10" fill="#0ea5e9"
    final badgeCenter = Offset(57 * scale, 20 * scale);
    final badgePaint = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, 10 * scale, badgePaint);

    // Draw "?" text
    const textSpan = TextSpan(
      text: '?',
      style: TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        height: 1.0,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(badgeCenter.dx - textPainter.width / 2, badgeCenter.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Who Am I? magnifying glass & silhouette (replicates Icon3dWhoAmI SVG exactly)
class WhoAmIPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = w / 80.0;

    // 1. Shadow ellipse at (40, 73), rx=13, ry=3
    final shadowPaint = Paint()
      ..color = const Color(0xFF2DD4BF).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(40 * scale, 73 * scale),
        width: 26 * scale,
        height: 6 * scale,
      ),
      shadowPaint,
    );

    // 2. Magnifying glass handle (underneath glass body)
    // rect x="47" y="47" width="16" height="6" rx="3" fill="#0f766e" transform="rotate(45 47 47)"
    final handlePaint1 = Paint()
      ..color = const Color(0xFF0F766E)
      ..style = PaintingStyle.fill;
    final handlePaint2 = Paint()
      ..color = const Color(0xFF5EEAD4).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(47 * scale, 47 * scale);
    canvas.rotate(45 * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -3 * scale, 16 * scale, 6 * scale),
        Radius.circular(3 * scale),
      ),
      handlePaint1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -2 * scale, 14 * scale, 4 * scale),
        Radius.circular(2 * scale),
      ),
      handlePaint2,
    );
    canvas.restore();

    // 3. Magnifying glass circle body at (33, 33), r=19
    final glassCenter = Offset(33 * scale, 33 * scale);
    final glassRadius = 19 * scale;
    final glassBodyPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF5EEAD4), Color(0xFF0D9488)],
        center: const Alignment(-0.2, -0.2),
      ).createShader(Rect.fromCircle(center: glassCenter, radius: glassRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(glassCenter, glassRadius, glassBodyPaint);

    // 4. Inside glass circle at (33, 33), r=13
    final innerGlassPaint = Paint()
      ..color = const Color(0xFF0D9488).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(glassCenter, 13 * scale, innerGlassPaint);

    final innerGlassStroke = Paint()
      ..color = const Color(0xFF5EEAD4).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawCircle(glassCenter, 13 * scale, innerGlassStroke);

    // 5. Silhouette inside glass
    // head: circle cx="33" cy="30" r="4" fill="#ccfbf1" opacity="0.7"
    final silPaintHead = Paint()
      ..color = const Color(0xFFCCFBF1).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(33 * scale, 30 * scale), 4 * scale, silPaintHead);

    // body: path d="M25 42 Q33 36 41 42" fill="#ccfbf1" opacity="0.5"
    final silPaintBody = Paint()
      ..color = const Color(0xFFCCFBF1).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final bodyPath = Path()
      ..moveTo(25 * scale, 42 * scale)
      ..quadraticBezierTo(33 * scale, 36 * scale, 41 * scale, 42 * scale)
      ..lineTo(41 * scale, 46 * scale) // close it to fill nicely
      ..lineTo(25 * scale, 46 * scale)
      ..close();
    canvas.drawPath(bodyPath, silPaintBody);

    // 6. Glass reflection: transform="rotate(-30 27 26)"
    canvas.save();
    canvas.translate(27 * scale, 26 * scale);
    canvas.rotate(-30 * math.pi / 180);
    final reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 10 * scale, height: 8 * scale),
      reflectionPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for First Goal stopwatch & lightning (replicates Icon3dClock SVG exactly)
class ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = w / 80.0;

    // 1. Shadow ellipse at (40, 73), rx=14, ry=3.5
    final shadowPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(40 * scale, 73 * scale),
        width: 28 * scale,
        height: 7 * scale,
      ),
      shadowPaint,
    );

    // 2. Crown / top knob
    // rect x="37" y="9" width="6" height="6" rx="2" fill="#d97706"
    final knobPaint = Paint()..style = PaintingStyle.fill;
    knobPaint.color = const Color(0xFFD97706);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(37 * scale, 9 * scale, 6 * scale, 6 * scale),
        Radius.circular(2 * scale),
      ),
      knobPaint,
    );
    // rect x="38" y="8" width="4" height="3" rx="1" fill="#fbbf24"
    knobPaint.color = const Color(0xFFFBBF24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(38 * scale, 8 * scale, 4 * scale, 3 * scale),
        Radius.circular(1 * scale),
      ),
      knobPaint,
    );

    // 3. Outer ring circle at (40, 38), r=27
    final clockCenter = Offset(40 * scale, 38 * scale);
    final outerRadius = 27 * scale;
    final outerRingPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFDE68A), Color(0xFFB45309)],
        center: const Alignment(-0.2, -0.2),
      ).createShader(Rect.fromCircle(center: clockCenter, radius: outerRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(clockCenter, outerRadius, outerRingPaint);

    // 4. Face circle at (40, 38), r=21
    final innerRadius = 21 * scale;
    final facePaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF1C1917), Color(0xFF0C0A09)],
      ).createShader(Rect.fromCircle(center: clockCenter, radius: innerRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(clockCenter, innerRadius, facePaint);

    // 5. Tick marks: [0, 30, 60, ..., 330] angles
    final tickPaint = Paint()..style = PaintingStyle.stroke;
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * math.pi / 180;
      final isMajor = i % 3 == 0;
      final r1 = (isMajor ? 16 : 18) * scale;
      final r2 = 20 * scale;
      
      tickPaint.color = isMajor ? const Color(0xFFFBBF24) : const Color(0xFF78716C);
      tickPaint.strokeWidth = (isMajor ? 2.0 : 1.0) * scale;
      
      canvas.drawLine(
        Offset(clockCenter.dx + r1 * math.cos(angle), clockCenter.dy + r1 * math.sin(angle)),
        Offset(clockCenter.dx + r2 * math.cos(angle), clockCenter.dy + r2 * math.sin(angle)),
        tickPaint,
      );
    }

    // 6. Hands
    // Minute hand pointing to 12
    final minPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(clockCenter, Offset(40 * scale, 22 * scale), minPaint);

    // Hour hand pointing to 4
    final hourPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(clockCenter, Offset(52 * scale, 47 * scale), hourPaint);

    // Center dots
    canvas.drawCircle(clockCenter, 3 * scale, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawCircle(clockCenter, 1.5 * scale, Paint()..color = Colors.white);

    // 7. Lightning Bolt badge: circle cx="60" cy="18" r="10" fill="#f59e0b"
    final badgeCenter = Offset(60 * scale, 18 * scale);
    final badgePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, 10 * scale, badgePaint);

    // bolt path inside: M63 12 l-5 8 h4 l-5 8
    final boltPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final boltPath = Path()
      ..moveTo(63 * scale, 12 * scale)
      ..lineTo(58 * scale, 20 * scale)
      ..lineTo(62 * scale, 20 * scale)
      ..lineTo(57 * scale, 28 * scale);
    canvas.drawPath(boltPath, boltPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Formation pitch & dots (replicates Icon3dFormation SVG exactly)
class FormationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = w / 80.0;

    // 1. Shadow ellipse at (40, 73), rx=16, ry=4
    final shadowPaint = Paint()
      ..color = const Color(0xFFA855F7).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(40 * scale, 73 * scale),
        width: 32 * scale,
        height: 8 * scale,
      ),
      shadowPaint,
    );

    // 2. Pitch board: rect x="10" y="12" width="60" height="58" rx="6" fill="url(#pitch-g)"
    final pitchRect = Rect.fromLTWH(10 * scale, 12 * scale, 60 * scale, 58 * scale);
    final pitchPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF7C3AED), Color(0xFF4C1D95)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(pitchRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(pitchRect, Radius.circular(6 * scale)),
      pitchPaint,
    );

    // 3. Pitch markings: rect x="16" y="18" width="48" height="46" rx="3" fill="none" stroke="#a78bfa" strokeWidth="1" opacity="0.4"
    final linePaint = Paint()
      ..color = const Color(0xFFA78BFA).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16 * scale, 18 * scale, 48 * scale, 46 * scale),
        Radius.circular(3 * scale),
      ),
      linePaint,
    );

    // line x1="40" y1="18" x2="40" y2="64" stroke="#a78bfa" strokeWidth="1" opacity="0.3"
    linePaint.color = const Color(0xFFA78BFA).withOpacity(0.3);
    canvas.drawLine(Offset(40 * scale, 18 * scale), Offset(40 * scale, 64 * scale), linePaint);

    // circle cx="40" cy="41" r="8" fill="none" stroke="#a78bfa" strokeWidth="1" opacity="0.3"
    canvas.drawCircle(Offset(40 * scale, 41 * scale), 8 * scale, linePaint);

    // GK box: rect x="28" y="58" width="24" height="8" rx="1" fill="none" stroke="#a78bfa" strokeWidth="1" opacity="0.3"
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(28 * scale, 58 * scale, 24 * scale, 8 * scale),
        Radius.circular(1 * scale),
      ),
      linePaint,
    );

    // 4. Players: 4-3-3 formation dots
    final playerPaint = Paint()..style = PaintingStyle.fill;

    // GK: cx="40" cy="61" r="3.5" fill="#c4b5fd"
    playerPaint.color = const Color(0xFFC4B5FD);
    canvas.drawCircle(Offset(40 * scale, 61 * scale), 3.5 * scale, playerPaint);

    // Defenders: cx="20" cy="52", cx="31" cy="52", cx="49" cy="52", cx="60" cy="52" fill="#ddd6fe"
    playerPaint.color = const Color(0xFFDDD6FE);
    canvas.drawCircle(Offset(20 * scale, 52 * scale), 3.5 * scale, playerPaint);
    canvas.drawCircle(Offset(31 * scale, 52 * scale), 3.5 * scale, playerPaint);
    canvas.drawCircle(Offset(49 * scale, 52 * scale), 3.5 * scale, playerPaint);
    canvas.drawCircle(Offset(60 * scale, 52 * scale), 3.5 * scale, playerPaint);

    // Midfielders: cx="26" cy="41", cx="40" cy="41", cx="54" cy="41" fill="#ede9fe"
    playerPaint.color = const Color(0xFFEDE9FE);
    canvas.drawCircle(Offset(26 * scale, 41 * scale), 3.5 * scale, playerPaint);
    canvas.drawCircle(Offset(40 * scale, 41 * scale), 3.5 * scale, playerPaint);
    canvas.drawCircle(Offset(54 * scale, 41 * scale), 3.5 * scale, playerPaint);

    // Forwards: cx="22" cy="28", cx="40" cy="25", cx="58" cy="28" fill="#f5f3ff"
    playerPaint.color = const Color(0xFFF5F3FF);
    canvas.drawCircle(Offset(22 * scale, 28 * scale), 3.5 * scale, playerPaint);
    canvas.drawCircle(Offset(40 * scale, 25 * scale), 3.5 * scale, playerPaint);
    canvas.drawCircle(Offset(58 * scale, 28 * scale), 3.5 * scale, playerPaint);

    // 5. Shine top: rect x="12" y="13" width="56" height="8" rx="4" fill="white" opacity="0.07"
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12 * scale, 13 * scale, 56 * scale, 8 * scale),
        Radius.circular(4 * scale),
      ),
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Bracket trophy & badges (replicates Icon3dBracket SVG exactly)
class BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = w / 80.0;

    // 1. Shadow ellipse at (40, 74), rx=15, ry=4
    final shadowPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(40 * scale, 74 * scale),
        width: 30 * scale,
        height: 8 * scale,
      ),
      shadowPaint,
    );

    // 2. Base: rect x="28" y="62" width="24" height="6" rx="3" fill="url(#trophy-g)"
    final baseRect = Rect.fromLTWH(28 * scale, 62 * scale, 24 * scale, 6 * scale);
    final trophyG = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFF92400E)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(baseRect)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, Radius.circular(3 * scale)),
      trophyG,
    );

    // Base shine: rect x="29" y="62" width="22" height="3" rx="2" fill="#fde68a" opacity="0.3"
    final baseShinePaint = Paint()
      ..color = const Color(0xFFFDE68A).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(29 * scale, 62 * scale, 22 * scale, 3 * scale),
        Radius.circular(2 * scale),
      ),
      baseShinePaint,
    );

    // 3. Stem: rect x="36" y="54" width="8" height="8" rx="1" fill="#b45309"
    final stemPaint = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(36 * scale, 54 * scale, 8 * scale, 8 * scale),
        Radius.circular(1 * scale),
      ),
      stemPaint,
    );

    // 4. Handles: d="M26 16 Q16 20 18 28 Q20 34 26 32"
    final handlePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round;

    final leftHandle = Path()
      ..moveTo(26 * scale, 16 * scale)
      ..quadraticBezierTo(16 * scale, 20 * scale, 18 * scale, 28 * scale)
      ..quadraticBezierTo(20 * scale, 34 * scale, 26 * scale, 32 * scale);
    canvas.drawPath(leftHandle, handlePaint);

    final rightHandle = Path()
      ..moveTo(54 * scale, 16 * scale)
      ..quadraticBezierTo(64 * scale, 20 * scale, 62 * scale, 28 * scale)
      ..quadraticBezierTo(60 * scale, 34 * scale, 54 * scale, 32 * scale);
    canvas.drawPath(rightHandle, handlePaint);

    // 5. Trophy cup body: path d="M26 10 h28 v22 c0 14 -8 20 -14 22 c-6-2-14-8-14-22 Z"
    final cupPath = Path()
      ..moveTo(26 * scale, 10 * scale)
      ..lineTo(54 * scale, 10 * scale)
      ..lineTo(54 * scale, 32 * scale)
      ..cubicTo(54 * scale, 46 * scale, 46 * scale, 52 * scale, 40 * scale, 54 * scale)
      ..cubicTo(34 * scale, 52 * scale, 26 * scale, 46 * scale, 26 * scale, 32 * scale)
      ..close();

    final cupG = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFF92400E)],
        stops: const [0.0, 0.5, 1.0],
        center: const Alignment(-0.1, -0.2),
      ).createShader(cupPath.getBounds())
      ..style = PaintingStyle.fill;
    canvas.drawPath(cupPath, cupG);

    // 6. Shine on cup: d="M30 12 Q34 16 32 26"
    final cupShinePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * scale
      ..strokeCap = StrokeCap.round;
    final shinePath = Path()
      ..moveTo(30 * scale, 12 * scale)
      ..quadraticBezierTo(34 * scale, 16 * scale, 32 * scale, 26 * scale);
    canvas.drawPath(shinePath, cupShinePaint);

    // 7. Star inside: M40 22 l2 5 5 0 -4 3 2 5 -5-3 -5 3 2-5 -4-3 5 0z
    final starInsidePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final starInside = Path()
      ..moveTo(40 * scale, 22 * scale)
      ..lineTo(42 * scale, 27 * scale)
      ..lineTo(47 * scale, 27 * scale)
      ..lineTo(43 * scale, 30 * scale)
      ..lineTo(45 * scale, 35 * scale)
      ..lineTo(40 * scale, 32 * scale)
      ..lineTo(35 * scale, 35 * scale)
      ..lineTo(37 * scale, 30 * scale)
      ..lineTo(33 * scale, 27 * scale)
      ..lineTo(38 * scale, 27 * scale)
      ..close();
    canvas.drawPath(starInside, starInsidePaint);

    // 8. Star badge: circle cx="60" cy="14" r="10" fill="#f59e0b"
    final badgeCenter = Offset(60 * scale, 14 * scale);
    final badgePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, 10 * scale, badgePaint);

    // Star inside badge
    final badgeStarPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final badgeStar = Path()
      ..moveTo(60 * scale, 8 * scale)
      ..lineTo(61.5 * scale, 12 * scale)
      ..lineTo(65.5 * scale, 12 * scale)
      ..lineTo(62.5 * scale, 14.5 * scale)
      ..lineTo(63.7 * scale, 18.5 * scale)
      ..lineTo(60 * scale, 16 * scale)
      ..lineTo(56.3 * scale, 18.5 * scale)
      ..lineTo(57.5 * scale, 14.5 * scale)
      ..lineTo(54.5 * scale, 12 * scale)
      ..lineTo(58.5 * scale, 12 * scale)
      ..close();
    canvas.drawPath(badgeStar, badgeStarPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Bottom Nav Item Widget helper duplicate to avoid circular reference dependencies

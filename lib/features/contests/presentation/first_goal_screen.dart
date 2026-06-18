import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/pitch_background.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum MatchState { predictable, locked, predicted, completed }

class FirstGoalMatch {
  final int id;
  final String teamHome;
  final String teamAway;
  final String matchTime;
  final String deadline;
  final MatchState state;
  final int? userPrediction;
  final int? actualMinute;
  final int? points;

  const FirstGoalMatch({
    required this.id,
    required this.teamHome,
    required this.teamAway,
    required this.matchTime,
    required this.deadline,
    required this.state,
    this.userPrediction,
    this.actualMinute,
    this.points,
  });
}

// ─── Mock data ────────────────────────────────────────────────────────────────

final List<FirstGoalMatch> _mockMatches = [
  const FirstGoalMatch(
    id: 1,
    teamHome: 'Mexico',
    teamAway: 'South Africa',
    matchTime: 'FRI 12 JUN, 00:30',
    deadline: 'THU 11 JUN, 23:30',
    state: MatchState.predictable,
  ),
  const FirstGoalMatch(
    id: 2,
    teamHome: 'South Korea',
    teamAway: 'Czech Republic',
    matchTime: 'FRI 12 JUN, 07:30',
    deadline: 'FRI 12 JUN, 06:30',
    state: MatchState.predictable,
  ),
  const FirstGoalMatch(
    id: 3,
    teamHome: 'Brazil',
    teamAway: 'Argentina',
    matchTime: 'SAT 13 JUN, 15:00',
    deadline: 'SAT 13 JUN, 14:00',
    state: MatchState.locked,
  ),
  const FirstGoalMatch(
    id: 4,
    teamHome: 'England',
    teamAway: 'France',
    matchTime: 'THU 11 JUN, 18:00',
    deadline: 'THU 11 JUN, 17:00',
    state: MatchState.predicted,
    userPrediction: 38,
  ),
  const FirstGoalMatch(
    id: 5,
    teamHome: 'Spain',
    teamAway: 'Germany',
    matchTime: 'WED 10 JUN, 20:00',
    deadline: 'WED 10 JUN, 19:00',
    state: MatchState.completed,
    userPrediction: 22,
    actualMinute: 24,
    points: 15,
  ),
];

// ─── Points tier helper ───────────────────────────────────────────────────────

class _PointsTier {
  final String label;
  final String pts;
  final Color color;
  final Color borderColor;
  final Color bgColor;

  const _PointsTier({
    required this.label,
    required this.pts,
    required this.color,
    required this.borderColor,
    required this.bgColor,
  });
}

const List<_PointsTier> _tiers = [
  _PointsTier(
    label: 'Exact',
    pts: '20 pts',
    color: Color(0xFFFBBF24),
    borderColor: Color(0x40FBBF24),
    bgColor: Color(0x0DFBBF24),
  ),
  _PointsTier(
    label: '±2 min',
    pts: '15 pts',
    color: Color(0xFF4ADE80),
    borderColor: Color(0x404ADE80),
    bgColor: Color(0x0D4ADE80),
  ),
  _PointsTier(
    label: '±5 min',
    pts: '10 pts',
    color: Color(0xFF38BDF8),
    borderColor: Color(0x4038BDF8),
    bgColor: Color(0x0D38BDF8),
  ),
  _PointsTier(
    label: '±10 min',
    pts: '5 pts',
    color: Color(0xFFA78BFA),
    borderColor: Color(0x40A78BFA),
    bgColor: Color(0x0DA78BFA),
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class FirstGoalScreen extends ConsumerStatefulWidget {
  const FirstGoalScreen({super.key});

  @override
  ConsumerState<FirstGoalScreen> createState() => _FirstGoalScreenState();
}

class _FirstGoalScreenState extends ConsumerState<FirstGoalScreen>
    with TickerProviderStateMixin {
  late List<FirstGoalMatch> _matches;
  final Map<int, double> _minuteValues = {};
  final Map<int, bool> _submitting = {};
  final Map<int, bool> _submitted = {};

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _matches = List.from(_mockMatches);
    for (final m in _matches) {
      if (m.state == MatchState.predictable) {
        _minuteValues[m.id] = 45;
      }
    }

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Load persisted predictions asynchronously
    Future.microtask(() => _loadPredictions());
  }

  Future<void> _loadPredictions() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final questionIds = _matches.map((m) => 'q_first_goal_${m.id}').toList();
      final predictionsData = await client
          .from('predictions')
          .select()
          .eq('user_id', currentUser.id)
          .inFilter('question_id', questionIds);

      final predictionsMap = {
        for (var p in (predictionsData as List))
          p['question_id'].toString(): p['answer'].toString()
      };

      if (mounted) {
        setState(() {
          _matches = _matches.map((m) {
            final qId = 'q_first_goal_${m.id}';
            if (predictionsMap.containsKey(qId)) {
              final val = int.tryParse(predictionsMap[qId]!) ?? 45;
              _minuteValues[m.id] = val.toDouble();
              _submitted[m.id] = true;
              return FirstGoalMatch(
                id: m.id,
                teamHome: m.teamHome,
                teamAway: m.teamAway,
                matchTime: m.matchTime,
                deadline: m.deadline,
                state: m.state == MatchState.predictable ? MatchState.predicted : m.state,
                userPrediction: val,
                actualMinute: m.actualMinute,
                points: m.points,
              );
            }
            return m;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Failed to load first goal predictions from Supabase: $e");
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _lockIn(int matchId) {
    final minute = _minuteValues[matchId]?.round() ?? 45;
    setState(() {
      _submitting[matchId] = true;
    });

    Future<void> saveToSupabase() async {
      try {
        final client = Supabase.instance.client;
        final currentUser = client.auth.currentUser;
        if (currentUser != null) {
          await client.from('predictions').upsert({
            'user_id': currentUser.id,
            'match_id': matchId.toString(),
            'question_id': 'q_first_goal_$matchId',
            'answer': minute.toString(),
            'submitted_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,question_id');
        }
      } catch (e) {
        debugPrint("Failed to save first goal prediction: $e");
      }
    }

    saveToSupabase().then((_) {
      if (!mounted) return;
      setState(() {
        _submitting[matchId] = false;
        _submitted[matchId] = true;
        _matches = _matches.map((m) {
          if (m.id == matchId) {
            return FirstGoalMatch(
              id: m.id,
              teamHome: m.teamHome,
              teamAway: m.teamAway,
              matchTime: m.matchTime,
              deadline: m.deadline,
              state: MatchState.predicted,
              userPrediction: minute,
            );
          }
          return m;
        }).toList();
      });
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final predictable = _matches.where((m) => m.state == MatchState.predictable && !(_submitted[m.id] ?? false)).toList();
    final locked = _matches.where((m) => m.state == MatchState.locked).toList();
    final predicted = _matches.where((m) => m.state == MatchState.predicted || (_submitted[m.id] ?? false)).toList();
    final completed = _matches.where((m) => m.state == MatchState.completed).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF05050A),
      body: Stack(
        children: [
          const PitchBackground(child: SizedBox.expand()),
          // Ambient blobs
          Positioned(
            top: 60,
            right: -80,
            child: _ambientBlob(const Color(0xFFF59E0B), 260),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: _ambientBlob(const Color(0xFF6366F1), 220),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildHero()),
                  if (predictable.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _sectionLabel('PREDICT NOW', const Color(0xFFFBBF24), dot: true)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _buildPredictCard(predictable[i]),
                        ),
                        childCount: predictable.length,
                      ),
                    ),
                  ],
                  if (locked.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _sectionLabel('UNLOCKS 24H BEFORE KICK-OFF', Colors.white38, icon: Icons.lock_outline_rounded)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _buildLockedCard(locked[i]),
                        ),
                        childCount: locked.length,
                      ),
                    ),
                  ],
                  if (predicted.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _sectionLabel('AWAITING RESULT', const Color(0xFF4ADE80), dot: true)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _buildPredictedCard(predicted[i]),
                        ),
                        childCount: predicted.length,
                      ),
                    ),
                  ],
                  if (completed.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _sectionLabel('RESULTS', const Color(0xFF38BDF8), dot: true)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _buildCompletedCard(completed[i]),
                        ),
                        childCount: completed.length,
                      ),
                    ),
                  ],
                  if (predictable.isEmpty && predicted.isEmpty && completed.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.04),
      ),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: color.withOpacity(0.04)),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF05050A).withOpacity(0.9),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/games'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text('Back', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFFFBBF24), size: 16),
              const SizedBox(width: 6),
              Text(
                'First Goal Timer',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 60), // balance
        ],
      ),
    );
  }

  // ─── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.06),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.my_location_rounded, color: Color(0xFFFBBF24), size: 13),
                const SizedBox(width: 6),
                Text(
                  'PER-MATCH GAME',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFBBF24),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'First Goal Timer',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Predict the minute the first goal is scored.\nThe closer you are, the more points you earn.',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Points tiers grid
          Row(
            children: _tiers.map((t) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: t == _tiers.last ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: t.bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      t.pts,
                      style: GoogleFonts.outfit(color: t.color, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.label,
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Section label ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, Color color, {bool dot = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          if (dot)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(icon, color: color, size: 12),
            ),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Predict card ──────────────────────────────────────────────────────────

  Widget _buildPredictCard(FirstGoalMatch match) {
    final minute = _minuteValues[match.id] ?? 45;
    final isSubmitting = _submitting[match.id] ?? false;

    return StaggeredEntrance(
      delay: Duration(milliseconds: 80 * (_matches.indexOf(match) + 1)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.15)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top amber accent line
            Container(
              height: 1.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFFF59E0B), Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date / deadline row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        match.matchTime,
                        style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                      Text(
                        'DEADLINE: ${match.deadline}',
                        style: GoogleFonts.outfit(color: const Color(0xFFFBBF24).withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Teams row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.teamHome,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                        ),
                        child: Text(
                          'VS',
                          style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          match.teamAway,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Minute picker label
                  Text(
                    'Select the minute of the first goal:',
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Minute picker
                  _buildMinutePicker(match.id, minute),
                  const SizedBox(height: 16),

                  // Lock in button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isSubmitting
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: isSubmitting ? const Color(0xFFF59E0B).withOpacity(0.15) : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSubmitting
                            ? null
                            : [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () => _lockIn(match.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: const Color(0xFFF59E0B).withOpacity(0.6),
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Colors.black, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lock in Minute ${minute.round()}',
                                    style: GoogleFonts.outfit(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildMinutePicker(int matchId, double minute) {
    return Row(
      children: [
        // Minus button
        GestureDetector(
          onTap: () => setState(() => _minuteValues[matchId] = (minute - 1).clamp(1, 90)),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text('−', style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 20, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 10),

        // Slider
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: const Color(0xFFF59E0B),
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: const Color(0xFFF59E0B),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              overlayColor: const Color(0xFFF59E0B).withOpacity(0.12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: minute,
              min: 1,
              max: 90,
              onChanged: (v) => setState(() => _minuteValues[matchId] = v),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Plus button
        GestureDetector(
          onTap: () => setState(() => _minuteValues[matchId] = (minute + 1).clamp(1, 90)),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text('+', style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 20, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 10),

        // Minute display
        Container(
          width: 54,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
          ),
          alignment: Alignment.center,
          child: Text(
            "${minute.round()}'",
            style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  // ─── Locked card ───────────────────────────────────────────────────────────

  Widget _buildLockedCard(FirstGoalMatch match) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Opacity(
        opacity: 0.45,
        child: Row(
          children: [
            Expanded(
              child: Text(
                match.teamHome,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
            Column(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white38, size: 16),
                const SizedBox(height: 3),
                Text(
                  match.matchTime,
                  style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Expanded(
              child: Text(
                match.teamAway,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Predicted / awaiting card ─────────────────────────────────────────────

  Widget _buildPredictedCard(FirstGoalMatch match) {
    final prediction = match.userPrediction ?? (_minuteValues[match.id]?.round() ?? 45);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withOpacity(0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${match.teamHome} vs ${match.teamAway}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 16),
              const SizedBox(width: 4),
              Text('Locked', style: GoogleFonts.outfit(color: const Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
                ),
                child: Text(
                  "$prediction' predicted",
                  style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                match.matchTime,
                style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Completed / result card ───────────────────────────────────────────────

  Widget _buildCompletedCard(FirstGoalMatch match) {
    final diff = match.actualMinute != null && match.userPrediction != null
        ? (match.userPrediction! - match.actualMinute!).abs()
        : null;

    Color badgeColor = Colors.white30;
    String badgeText = 'Miss +0';
    if (diff != null) {
      if (diff == 0) { badgeColor = const Color(0xFFFBBF24); badgeText = 'EXACT +20'; }
      else if (diff <= 2) { badgeColor = const Color(0xFF4ADE80); badgeText = '±2 min +15'; }
      else if (diff <= 5) { badgeColor = const Color(0xFF38BDF8); badgeText = '±5 min +10'; }
      else if (diff <= 10) { badgeColor = const Color(0xFFA78BFA); badgeText = '±10 min +5'; }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${match.teamHome} vs ${match.teamAway}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: badgeColor.withOpacity(0.25)),
                ),
                child: Text(badgeText, style: GoogleFonts.outfit(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  "Your guess: ${match.userPrediction}'",
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
                ),
                child: Text(
                  "Actual: ${match.actualMinute}'",
                  style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 15),
              const SizedBox(width: 4),
              Text(
                '${match.points ?? 0} pts',
                style: GoogleFonts.outfit(color: const Color(0xFFFBBF24), fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.access_time_rounded, color: Colors.white10, size: 52),
          const SizedBox(height: 14),
          Text(
            'No upcoming matches available right now.',
            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back when matches are scheduled.',
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.2), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

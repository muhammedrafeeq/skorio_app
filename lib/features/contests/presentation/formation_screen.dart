import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/pitch_background.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const List<String> _formations = [
  '4-3-3', '4-4-2', '4-2-3-1', '3-5-2',
  '5-3-2', '3-4-3', '4-5-1', '4-1-4-1',
];

const Color _violet = Color(0xFFA78BFA);
const Color _violetDark = Color(0xFF7C3AED);
const Color _amber = Color(0xFFFBBF24);

// ─── Models ───────────────────────────────────────────────────────────────────

enum FormMatchState { predictable, locked, predicted, completed }

class FormationMatch {
  final int id;
  final String teamHome;
  final String teamAway;
  final String matchTime;
  final String deadline;
  final FormMatchState state;
  final String? predictedHome;
  final String? predictedAway;
  final String? actualHome;
  final String? actualAway;
  final int? points;

  const FormationMatch({
    required this.id,
    required this.teamHome,
    required this.teamAway,
    required this.matchTime,
    required this.deadline,
    required this.state,
    this.predictedHome,
    this.predictedAway,
    this.actualHome,
    this.actualAway,
    this.points,
  });
}

// ─── Mock data ────────────────────────────────────────────────────────────────

final List<FormationMatch> _mockMatches = [
  const FormationMatch(
    id: 1,
    teamHome: 'Mexico',
    teamAway: 'South Africa',
    matchTime: 'FRI 12 JUN, 00:30',
    deadline: 'THU 11 JUN, 23:30',
    state: FormMatchState.predictable,
  ),
  const FormationMatch(
    id: 2,
    teamHome: 'South Korea',
    teamAway: 'Czech Republic',
    matchTime: 'FRI 12 JUN, 07:30',
    deadline: 'FRI 12 JUN, 06:30',
    state: FormMatchState.predictable,
  ),
  const FormationMatch(
    id: 3,
    teamHome: 'Brazil',
    teamAway: 'Argentina',
    matchTime: 'SAT 13 JUN, 15:00',
    deadline: 'SAT 13 JUN, 14:00',
    state: FormMatchState.locked,
  ),
  const FormationMatch(
    id: 4,
    teamHome: 'England',
    teamAway: 'France',
    matchTime: 'THU 11 JUN, 18:00',
    deadline: 'THU 11 JUN, 17:00',
    state: FormMatchState.predicted,
    predictedHome: '4-3-3',
    predictedAway: '4-4-2',
  ),
  const FormationMatch(
    id: 5,
    teamHome: 'Spain',
    teamAway: 'Germany',
    matchTime: 'WED 10 JUN, 20:00',
    deadline: 'WED 10 JUN, 19:00',
    state: FormMatchState.completed,
    predictedHome: '4-3-3',
    predictedAway: '4-2-3-1',
    actualHome: '4-3-3',
    actualAway: '4-4-2',
    points: 10,
  ),
];

// ─── Formation diagram widget ─────────────────────────────────────────────────

class _FormationDiagram extends StatelessWidget {
  final String formation;

  const _FormationDiagram({required this.formation});

  @override
  Widget build(BuildContext context) {
    final rows = <int>[1, ...formation.split('-').map(int.parse)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.reversed.map((count) {
        return Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (_) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _violet.withOpacity(0.15),
                border: Border.all(color: _violet.withOpacity(0.5), width: 1),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _violet,
                ),
              ),
            )),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class FormationScreen extends ConsumerStatefulWidget {
  const FormationScreen({super.key});

  @override
  ConsumerState<FormationScreen> createState() => _FormationScreenState();
}

class _FormationScreenState extends ConsumerState<FormationScreen>
    with SingleTickerProviderStateMixin {
  late List<FormationMatch> _matches;
  // matchId → { home: formation?, away: formation? }
  final Map<int, Map<String, String?>> _selections = {};
  final Map<int, bool> _submitting = {};
  final Map<int, bool> _submitted = {};
  final Map<int, String> _errors = {};

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _matches = List.from(_mockMatches);

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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

      final List<String> questionIds = [];
      for (final m in _matches) {
        questionIds.add('q_formation_home_${m.id}');
        questionIds.add('q_formation_away_${m.id}');
      }

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
            final homeQId = 'q_formation_home_${m.id}';
            final awayQId = 'q_formation_away_${m.id}';
            final homeAns = predictionsMap[homeQId];
            final awayAns = predictionsMap[awayQId];

            if (homeAns != null || awayAns != null) {
              _selections[m.id] = {
                'home': homeAns,
                'away': awayAns,
              };
              _submitted[m.id] = true;
              return FormationMatch(
                id: m.id,
                teamHome: m.teamHome,
                teamAway: m.teamAway,
                matchTime: m.matchTime,
                deadline: m.deadline,
                state: m.state == FormMatchState.predictable ? FormMatchState.predicted : m.state,
                predictedHome: homeAns,
                predictedAway: awayAns,
                actualHome: m.actualHome,
                actualAway: m.actualAway,
                points: m.points,
              );
            }
            return m;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Failed to load formation predictions from Supabase: $e");
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectHome(int matchId, String formation) {
    setState(() {
      final cur = _selections[matchId] ?? {};
      _selections[matchId] = {
        'home': cur['home'] == formation ? null : formation,
        'away': cur['away'],
      };
    });
  }

  void _selectAway(int matchId, String formation) {
    setState(() {
      final cur = _selections[matchId] ?? {};
      _selections[matchId] = {
        'home': cur['home'],
        'away': cur['away'] == formation ? null : formation,
      };
    });
  }

  void _lockIn(int matchId) {
    final sel = _selections[matchId];
    if (sel == null || (sel['home'] == null && sel['away'] == null)) {
      setState(() => _errors[matchId] = 'Select at least one formation to predict.');
      return;
    }
    setState(() {
      _submitting[matchId] = true;
      _errors.remove(matchId);
    });

    Future<void> saveToSupabase() async {
      try {
        final client = Supabase.instance.client;
        final currentUser = client.auth.currentUser;
        if (currentUser != null) {
          if (sel['home'] != null) {
            await client.from('predictions').upsert({
              'user_id': currentUser.id,
              'match_id': matchId.toString(),
              'question_id': 'q_formation_home_$matchId',
              'answer': sel['home'],
              'submitted_at': DateTime.now().toUtc().toIso8601String(),
            }, onConflict: 'user_id,question_id');
          }
          if (sel['away'] != null) {
            await client.from('predictions').upsert({
              'user_id': currentUser.id,
              'match_id': matchId.toString(),
              'question_id': 'q_formation_away_$matchId',
              'answer': sel['away'],
              'submitted_at': DateTime.now().toUtc().toIso8601String(),
            }, onConflict: 'user_id,question_id');
          }
        }
      } catch (e) {
        debugPrint("Failed to save formation prediction: $e");
      }
    }

    saveToSupabase().then((_) {
      if (!mounted) return;
      setState(() {
        _submitting[matchId] = false;
        _submitted[matchId] = true;
        _matches = _matches.map((m) {
          if (m.id == matchId) {
            return FormationMatch(
              id: m.id,
              teamHome: m.teamHome,
              teamAway: m.teamAway,
              matchTime: m.matchTime,
              deadline: m.deadline,
              state: FormMatchState.predicted,
              predictedHome: sel['home'],
              predictedAway: sel['away'],
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
    final predictable = _matches.where((m) => m.state == FormMatchState.predictable && !(_submitted[m.id] ?? false)).toList();
    final locked = _matches.where((m) => m.state == FormMatchState.locked).toList();
    final predicted = _matches.where((m) => m.state == FormMatchState.predicted).toList();
    final completed = _matches.where((m) => m.state == FormMatchState.completed).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF05050A),
      body: Stack(
        children: [
          const PitchBackground(child: SizedBox.expand()),
          Positioned(
            top: 60,
            left: -80,
            child: _blob(_violet, 260),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: _blob(_violetDark, 220),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildHero()),
                  if (predictable.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _sectionLabel('PREDICT NOW', _violet, dot: true)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
                        (_, i) => Padding(
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
                        (_, i) => Padding(
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
                        (_, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _buildResultCard(completed[i]),
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

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.05),
      ),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: color.withOpacity(0.05)),
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
              const Icon(Icons.people_alt_rounded, color: _violet, size: 16),
              const SizedBox(width: 6),
              Text(
                'Formation Predictor',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 60),
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
              color: _violet.withOpacity(0.06),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _violet.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt_rounded, color: _violet, size: 13),
                const SizedBox(width: 6),
                Text(
                  'PER-MATCH GAME',
                  style: GoogleFonts.outfit(
                    color: _violet,
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
            'Formation Predictor',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Predict the starting formation for home and/or away team. Earn 10 pts for each correct formation.',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Points tiers
          Row(
            children: [
              _tierCard('+10 pts', 'Home correct', _violet),
              const SizedBox(width: 8),
              _tierCard('+10 pts', 'Away correct', _violet),
              const SizedBox(width: 8),
              _tierCard('+20 pts', 'Both correct', _amber),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tierCard(String pts, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(color == _amber ? 0.35 : 0.22)),
        ),
        child: Column(
          children: [
            Text(pts, style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
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
              width: 6, height: 6,
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

  Widget _buildPredictCard(FormationMatch match) {
    final sel = _selections[match.id] ?? {};
    final homeF = sel['home'];
    final awayF = sel['away'];
    final isSubmitting = _submitting[match.id] ?? false;
    final error = _errors[match.id];

    String buttonLabel = 'Lock in Formation';
    if (homeF != null && awayF == null) buttonLabel = 'Lock in Formation (Home only)';
    if (homeF == null && awayF != null) buttonLabel = 'Lock in Formation (Away only)';
    if (homeF != null && awayF != null) buttonLabel = 'Lock in Formation (Both teams)';

    return StaggeredEntrance(
      delay: Duration(milliseconds: 80 * (_matches.indexOf(match) + 1)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _violet.withOpacity(0.15)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // Violet accent line
            Container(
              height: 1.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, _violet, Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date / deadline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(match.matchTime, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      Text('DEADLINE: ${match.deadline}', style: GoogleFonts.outfit(color: _violet.withOpacity(0.55), fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Teams row
                  Row(
                    children: [
                      Expanded(child: Text(match.teamHome, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _violet.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: _violet.withOpacity(0.3)),
                        ),
                        child: Text('VS', style: GoogleFonts.outfit(color: _violet, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      Expanded(child: Text(match.teamAway, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900), textAlign: TextAlign.right)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Home formation selector
                  _buildFormationSelector(
                    teamName: match.teamHome,
                    label: 'HOME FORMATION',
                    selected: homeF,
                    onSelect: (f) => _selectHome(match.id, f),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.06), height: 1),
                  const SizedBox(height: 16),

                  // Away formation selector
                  _buildFormationSelector(
                    teamName: match.teamAway,
                    label: 'AWAY FORMATION',
                    selected: awayF,
                    onSelect: (f) => _selectAway(match.id, f),
                  ),

                  // Error
                  if (error != null && error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF87171).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF87171).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 15),
                          const SizedBox(width: 8),
                          Expanded(child: Text(error, style: GoogleFonts.outfit(color: const Color(0xFFF87171), fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // Lock in button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isSubmitting
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: isSubmitting ? _violet.withOpacity(0.15) : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSubmitting
                            ? null
                            : [BoxShadow(color: _violet.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () => _lockIn(match.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: _violet.withOpacity(0.6), strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_alt_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      buttonLabel,
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                                      overflow: TextOverflow.ellipsis,
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

  Widget _buildFormationSelector({
    required String teamName,
    required String label,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(teamName, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w900)),
            Text(label, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.1,
          ),
          itemCount: _formations.length,
          itemBuilder: (_, i) {
            final f = _formations[i];
            final isSelected = selected == f;
            return GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? _violet.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _violet.withOpacity(0.6) : Colors.white.withOpacity(0.08),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: _violet.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      f,
                      style: GoogleFonts.outfit(
                        color: isSelected ? const Color(0xFFC4B5FD) : Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      _FormationDiagram(formation: f),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Locked card ───────────────────────────────────────────────────────────

  Widget _buildLockedCard(FormationMatch match) {
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
            Expanded(child: Text(match.teamHome, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))),
            Column(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white38, size: 16),
                const SizedBox(height: 3),
                Text(match.matchTime, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
            Expanded(child: Text(match.teamAway, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900), textAlign: TextAlign.right)),
          ],
        ),
      ),
    );
  }

  // ─── Predicted / awaiting card ─────────────────────────────────────────────

  Widget _buildPredictedCard(FormationMatch match) {
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
          if (match.predictedHome != null)
            _predRow('Home', match.predictedHome!),
          if (match.predictedAway != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _predRow('Away', match.predictedAway!),
            ),
        ],
      ),
    );
  }

  Widget _predRow(String side, String formation) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(side, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _violet.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _violet.withOpacity(0.2)),
          ),
          child: Text(
            formation,
            style: GoogleFonts.outfit(color: const Color(0xFFC4B5FD), fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  // ─── Result card ───────────────────────────────────────────────────────────

  Widget _buildResultCard(FormationMatch match) {
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
              Expanded(child: Text('${match.teamHome} vs ${match.teamAway}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
              const Icon(Icons.emoji_events_rounded, color: _violet, size: 15),
              const SizedBox(width: 4),
              Text('${match.points ?? 0} pts', style: GoogleFonts.outfit(color: _violet, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          _resultRow('HOME', match.predictedHome, match.actualHome),
          const SizedBox(height: 8),
          _resultRow('AWAY', match.predictedAway, match.actualAway),
        ],
      ),
    );
  }

  Widget _resultRow(String side, String? predicted, String? actual) {
    if (predicted == null) {
      return Row(
        children: [
          SizedBox(width: 40, child: Text(side, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w700))),
          Text('Not predicted', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.2), fontSize: 11)),
        ],
      );
    }

    final correct = actual != null && predicted == actual;

    return Row(
      children: [
        SizedBox(width: 40, child: Text(side, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w700))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: correct ? const Color(0xFF4ADE80).withOpacity(0.1) : const Color(0xFFF87171).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: correct ? const Color(0xFF4ADE80).withOpacity(0.25) : const Color(0xFFF87171).withOpacity(0.2),
            ),
          ),
          child: Text(
            predicted,
            style: GoogleFonts.outfit(
              color: correct ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actual != null) ...[
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 14),
          const SizedBox(width: 4),
          Text(actual, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)),
          if (correct) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 14),
          ],
        ],
      ],
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.people_alt_rounded, color: Colors.white10, size: 52),
          const SizedBox(height: 14),
          Text('No upcoming matches available right now.', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Check back when matches are scheduled.', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.2), fontSize: 11)),
        ],
      ),
    );
  }
}

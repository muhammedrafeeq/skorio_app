import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/theme/color_scheme.dart';
import '../../../core/utils/iterable_extensions.dart';
import '../../auth/providers/auth_provider.dart';

// ─── World Cup 2026 Teams ──────────────────────────────────────────────────────
const List<Map<String, String>> _wcTeams = [
  {'name': 'Brazil',       'flag': '🇧🇷', 'group': 'A'},
  {'name': 'Argentina',    'flag': '🇦🇷', 'group': 'A'},
  {'name': 'France',       'flag': '🇫🇷', 'group': 'B'},
  {'name': 'England',      'flag': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'group': 'B'},
  {'name': 'Spain',        'flag': '🇪🇸', 'group': 'C'},
  {'name': 'Germany',      'flag': '🇩🇪', 'group': 'C'},
  {'name': 'Portugal',     'flag': '🇵🇹', 'group': 'D'},
  {'name': 'Netherlands',  'flag': '🇳🇱', 'group': 'D'},
  {'name': 'Belgium',      'flag': '🇧🇪', 'group': 'E'},
  {'name': 'Italy',        'flag': '🇮🇹', 'group': 'E'},
  {'name': 'Uruguay',      'flag': '🇺🇾', 'group': 'F'},
  {'name': 'Croatia',      'flag': '🇭🇷', 'group': 'F'},
  {'name': 'Mexico',       'flag': '🇲🇽', 'group': 'G'},
  {'name': 'Colombia',     'flag': '🇨🇴', 'group': 'G'},
  {'name': 'USA',          'flag': '🇺🇸', 'group': 'H'},
  {'name': 'Canada',       'flag': '🇨🇦', 'group': 'H'},
  {'name': 'Morocco',      'flag': '🇲🇦', 'group': 'A'},
  {'name': 'Senegal',      'flag': '🇸🇳', 'group': 'B'},
  {'name': 'Japan',        'flag': '🇯🇵', 'group': 'C'},
  {'name': 'South Korea',  'flag': '🇰🇷', 'group': 'D'},
  {'name': 'Australia',    'flag': '🇦🇺', 'group': 'E'},
  {'name': 'Iran',         'flag': '🇮🇷', 'group': 'F'},
  {'name': 'Switzerland',  'flag': '🇨🇭', 'group': 'G'},
  {'name': 'Denmark',      'flag': '🇩🇰', 'group': 'H'},
  {'name': 'Ecuador',      'flag': '🇪🇨', 'group': 'A'},
  {'name': 'Chile',        'flag': '🇨🇱', 'group': 'B'},
  {'name': 'Serbia',       'flag': '🇷🇸', 'group': 'C'},
  {'name': 'Poland',       'flag': '🇵🇱', 'group': 'D'},
  {'name': 'Cameroon',     'flag': '🇨🇲', 'group': 'E'},
  {'name': 'Ghana',        'flag': '🇬🇭', 'group': 'F'},
  {'name': 'Saudi Arabia', 'flag': '🇸🇦', 'group': 'G'},
  {'name': 'Qatar',        'flag': '🇶🇦', 'group': 'H'},
  {'name': 'Algeria',      'flag': '🇩🇿', 'group': 'A'},
  {'name': 'Nigeria',      'flag': '🇳🇬', 'group': 'B'},
  {'name': 'Ivory Coast',  'flag': '🇨🇮', 'group': 'C'},
  {'name': 'Tunisia',      'flag': '🇹🇳', 'group': 'D'},
  {'name': 'Egypt',        'flag': '🇪🇬', 'group': 'E'},
  {'name': 'Cameroon',     'flag': '🇨🇲', 'group': 'F'},
  {'name': 'Panama',       'flag': '🇵🇦', 'group': 'G'},
  {'name': 'Costa Rica',   'flag': '🇨🇷', 'group': 'H'},
  {'name': 'Wales',        'flag': '🏴󠁧󠁢󠁷󠁬󠁳󠁿', 'group': 'A'},
  {'name': 'Scotland',     'flag': '🏴󠁧󠁢󠁳󠁣󠁴󠁿', 'group': 'B'},
  {'name': 'Austria',      'flag': '🇦🇹', 'group': 'C'},
  {'name': 'Turkey',       'flag': '🇹🇷', 'group': 'D'},
  {'name': 'Ukraine',      'flag': '🇺🇦', 'group': 'E'},
  {'name': 'Hungary',      'flag': '🇭🇺', 'group': 'F'},
  {'name': 'Slovakia',     'flag': '🇸🇰', 'group': 'G'},
  {'name': 'Slovenia',     'flag': '🇸🇮', 'group': 'H'},
];

// ─── State model ───────────────────────────────────────────────────────────────
class SurvivorState {
  final bool isEliminated;
  final bool hasWon;
  final int currentDay;
  final List<String> pickHistory;   // team names picked per day
  final List<bool> resultHistory;   // was pick correct?
  final String? todayPick;          // null if not yet picked today

  const SurvivorState({
    this.isEliminated = false,
    this.hasWon = false,
    this.currentDay = 1,
    this.pickHistory = const [],
    this.resultHistory = const [],
    this.todayPick,
  });

  bool get hasPickedToday => todayPick != null;

  String? get lastPick => pickHistory.isNotEmpty ? pickHistory.last : null;

  SurvivorState copyWith({
    bool? isEliminated,
    bool? hasWon,
    int? currentDay,
    List<String>? pickHistory,
    List<bool>? resultHistory,
    String? todayPick,
    bool clearTodayPick = false,
  }) {
    return SurvivorState(
      isEliminated: isEliminated ?? this.isEliminated,
      hasWon: hasWon ?? this.hasWon,
      currentDay: currentDay ?? this.currentDay,
      pickHistory: pickHistory ?? this.pickHistory,
      resultHistory: resultHistory ?? this.resultHistory,
      todayPick: clearTodayPick ? null : (todayPick ?? this.todayPick),
    );
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────────
class SurvivorNotifier extends Notifier<AsyncValue<SurvivorState>> {
  @override
  AsyncValue<SurvivorState> build() {
    Future.microtask(_load);
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    try {
      final client = sb.Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        state = const AsyncValue.data(SurvivorState());
        return;
      }

      final rows = await client
          .from('survivor_picks')
          .select()
          .eq('user_id', userId)
          .order('match_day', ascending: true);

      final picks = List<Map<String, dynamic>>.from(rows as List);
      final pickNames = picks.map((r) => r['team_name'].toString()).toList();
      final results   = picks.map((r) => r['is_correct'] as bool? ?? false).toList();
      final isEliminated = picks.any((r) => r['is_eliminated'] == true);
      final today     = _todayStr();
      final todayRow  = picks.where((r) => r['pick_date']?.toString() == today).firstOrNull;

      state = AsyncValue.data(SurvivorState(
        isEliminated: isEliminated,
        currentDay: picks.length + 1,
        pickHistory: pickNames,
        resultHistory: results,
        todayPick: todayRow?['team_name']?.toString(),
      ));
    } catch (e) {
      // Offline / development mode
      state = const AsyncValue.data(SurvivorState());
    }
  }

  Future<void> submitPick(String teamName, String userId) async {
    final current = state.value;
    if (current == null || current.hasPickedToday || current.isEliminated) return;

    // Cannot pick same consecutive team
    if (current.lastPick == teamName) return;

    // Optimistic update
    state = AsyncValue.data(current.copyWith(todayPick: teamName));

    try {
      final client = sb.Supabase.instance.client;
      await client.from('survivor_picks').insert({
        'user_id': userId,
        'team_name': teamName,
        'match_day': current.currentDay,
        'pick_date': _todayStr(),
        'is_correct': false,     // admin sets this after match
        'is_eliminated': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Survivor pick failed: $e');
    }
  }

  String _todayStr() => DateTime.now().toIso8601String().split('T').first;
}

final survivorProvider =
    NotifierProvider<SurvivorNotifier, AsyncValue<SurvivorState>>(
  SurvivorNotifier.new,
);

// ─── Screen ────────────────────────────────────────────────────────────────────
class SurvivorScreen extends ConsumerStatefulWidget {
  const SurvivorScreen({super.key});

  @override
  ConsumerState<SurvivorScreen> createState() => _SurvivorScreenState();
}

class _SurvivorScreenState extends ConsumerState<SurvivorScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _pendingPick;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final survivorAsync = ref.watch(survivorProvider);

    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: Stack(
        children: [
          // BG gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.1,
                colors: [Color(0xFF0A1F0A), Color(0xFF0A0A0F)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: survivorAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (state) => _buildBody(state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(25)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last Team Standing',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Survivor Mode',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF14532D), Color(0xFF15803D)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 4),
                Text('50 pts', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SurvivorState survivorSt) {
    if (survivorSt.isEliminated) return _buildEliminated(survivorSt);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildStatusCard(survivorSt),
          const SizedBox(height: 20),
          if (survivorSt.hasPickedToday)
            _buildPickedCard(survivorSt)
          else ...[
            _buildPickInstruction(survivorSt),
            const SizedBox(height: 16),
            _buildTeamGrid(survivorSt),
            if (_pendingPick != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final user = ref.read(authProvider).value;
                  if (user == null || _pendingPick == null) return;
                  final team = _pendingPick!;
                  await ref.read(survivorProvider.notifier).submitPick(team, user.id);
                  setState(() => _pendingPick = null);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF0F2A0F),
                      content: Row(children: [
                        const Icon(Icons.check_circle, color: Color(0xFF43DF9E)),
                        const SizedBox(width: 10),
                        Text('Pick submitted: $team — Good luck! 🏆',
                            style: const TextStyle(color: Colors.white)),
                      ]),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43DF9E), Color(0xFF00C082)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF43DF9E).withAlpha(80), blurRadius: 16),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '✅ Confirm Pick: $_pendingPick',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (survivorSt.pickHistory.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildHistory(survivorSt),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusCard(SurvivorState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2B0D), Color(0xFF14532D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF43DF9E).withAlpha(60)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Day ${state.currentDay}',
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF43DF9E))),
              Text('Survival streak',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${state.pickHistory.length} picks made',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
              Text('${state.resultHistory.where((r) => r).length} correct',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickInstruction(SurvivorState state) {
    final lastPick = state.lastPick;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pick your team for today',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text(
          lastPick != null
              ? 'Cannot pick $lastPick again (consecutive rule)'
              : 'Choose one team to survive — wrong pick means elimination!',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildTeamGrid(SurvivorState state) {
    final lastPick = state.lastPick;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _wcTeams.length,
      itemBuilder: (context, i) {
        final team = _wcTeams[i];
        final teamName = team['name']!;
        final isDisabled = teamName == lastPick;
        final isSelected = _pendingPick == teamName;

        return GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() => _pendingPick = isSelected ? null : teamName);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.white.withAlpha(5)
                  : isSelected
                      ? const Color(0xFF43DF9E).withAlpha(40)
                      : Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDisabled
                    ? Colors.white.withAlpha(10)
                    : isSelected
                        ? const Color(0xFF43DF9E)
                        : Colors.white.withAlpha(25),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(team['flag']!, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  teamName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDisabled ? Colors.white24 : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickedCard(SurvivorState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2B1A), Color(0xFF14532D)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF43DF9E).withAlpha(80)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF43DF9E), size: 48),
          const SizedBox(height: 12),
          Text('Pick Submitted!',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Text('You picked: ${state.todayPick}',
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF43DF9E))),
          const SizedBox(height: 8),
          Text('Results will be updated after the match.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildEliminated(SurvivorState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💀', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            Text('Eliminated!',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFFFF6B6B))),
            const SizedBox(height: 12),
            Text('You survived ${state.pickHistory.length} days',
                style: GoogleFonts.inter(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Better luck next time. The survivor wins 50 pts!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(SurvivorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pick History',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70)),
        const SizedBox(height: 10),
        ...List.generate(state.pickHistory.length, (i) {
          final team  = state.pickHistory[i];
          final correct = i < state.resultHistory.length ? state.resultHistory[i] : null;
          final teamData = _wcTeams.where((t) => t['name'] == team).firstOrNull;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: correct == null
                  ? Colors.white.withAlpha(8)
                  : correct
                      ? const Color(0xFF43DF9E).withAlpha(20)
                      : const Color(0xFFFF6B6B).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: correct == null
                    ? Colors.white.withAlpha(15)
                    : correct
                        ? const Color(0xFF43DF9E).withAlpha(60)
                        : const Color(0xFFFF6B6B).withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                Text('Day ${i + 1}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                const SizedBox(width: 12),
                Text(teamData?['flag'] ?? '🏳', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(team,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const Spacer(),
                if (correct == null)
                  Text('Pending', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38))
                else
                  Icon(correct ? Icons.check_circle : Icons.cancel,
                      color: correct ? const Color(0xFF43DF9E) : const Color(0xFFFF6B6B),
                      size: 20),
              ],
            ),
          );
        }),
      ],
    );
  }
}



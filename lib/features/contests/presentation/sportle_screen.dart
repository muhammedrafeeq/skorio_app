import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/theme/color_scheme.dart';
import '../../../core/utils/iterable_extensions.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Player pool (World Cup stars) ─────────────────────────────────────────────
class _Player {
  final String name;
  final int age;
  final String nationality;
  final String position; // GK DEF MID FWD
  final String club;
  final int rating;     // 1–99

  const _Player({
    required this.name,
    required this.age,
    required this.nationality,
    required this.position,
    required this.club,
    required this.rating,
  });
}

const List<_Player> _players = [
  _Player(name: 'Lionel Messi',     age: 36, nationality: 'Argentina', position: 'FWD', club: 'Inter Miami', rating: 91),
  _Player(name: 'Cristiano Ronaldo',age: 39, nationality: 'Portugal',  position: 'FWD', club: 'Al Nassr',    rating: 88),
  _Player(name: 'Kylian Mbappé',    age: 25, nationality: 'France',    position: 'FWD', club: 'Real Madrid', rating: 91),
  _Player(name: 'Erling Haaland',   age: 23, nationality: 'Norway',    position: 'FWD', club: 'Man City',    rating: 91),
  _Player(name: 'Vinicius Jr',      age: 23, nationality: 'Brazil',    position: 'FWD', club: 'Real Madrid', rating: 90),
  _Player(name: 'Rodri',            age: 27, nationality: 'Spain',     position: 'MID', club: 'Man City',    rating: 91),
  _Player(name: 'Jude Bellingham',  age: 20, nationality: 'England',   position: 'MID', club: 'Real Madrid', rating: 88),
  _Player(name: 'Kevin De Bruyne',  age: 32, nationality: 'Belgium',   position: 'MID', club: 'Man City',    rating: 91),
  _Player(name: 'Lamine Yamal',     age: 17, nationality: 'Spain',     position: 'FWD', club: 'Barcelona',   rating: 84),
  _Player(name: 'Pedri',            age: 22, nationality: 'Spain',     position: 'MID', club: 'Barcelona',   rating: 87),
  _Player(name: 'Toni Kroos',       age: 34, nationality: 'Germany',   position: 'MID', club: 'Real Madrid', rating: 88),
  _Player(name: 'Virgil van Dijk',  age: 32, nationality: 'Netherlands',position: 'DEF',club: 'Liverpool',   rating: 90),
  _Player(name: 'Rúben Dias',       age: 27, nationality: 'Portugal',  position: 'DEF', club: 'Man City',    rating: 89),
  _Player(name: 'Ter Stegen',       age: 32, nationality: 'Germany',   position: 'GK',  club: 'Barcelona',   rating: 89),
  _Player(name: 'Alisson Becker',   age: 31, nationality: 'Brazil',    position: 'GK',  club: 'Liverpool',   rating: 90),
  _Player(name: 'Harry Kane',       age: 30, nationality: 'England',   position: 'FWD', club: 'Bayern Munich',rating: 90),
  _Player(name: 'Bruno Fernandes',  age: 29, nationality: 'Portugal',  position: 'MID', club: 'Man United',  rating: 87),
  _Player(name: 'Bernardo Silva',   age: 29, nationality: 'Portugal',  position: 'MID', club: 'Man City',    rating: 88),
  _Player(name: 'Phil Foden',       age: 24, nationality: 'England',   position: 'MID', club: 'Man City',    rating: 88),
  _Player(name: 'Federico Valverde',age: 25, nationality: 'Uruguay',   position: 'MID', club: 'Real Madrid', rating: 88),
  _Player(name: 'Neymar Jr',        age: 32, nationality: 'Brazil',    position: 'FWD', club: 'Al Hilal',    rating: 87),
  _Player(name: 'Marcus Rashford',  age: 26, nationality: 'England',   position: 'FWD', club: 'Man United',  rating: 83),
  _Player(name: 'Antoine Griezmann',age: 32, nationality: 'France',    position: 'FWD', club: 'Atletico',    rating: 87),
  _Player(name: 'Lautaro Martínez', age: 26, nationality: 'Argentina', position: 'FWD', club: 'Inter Milan', rating: 87),
  _Player(name: 'Leroy Sane',       age: 28, nationality: 'Germany',   position: 'FWD', club: 'Bayern Munich',rating: 86),
  _Player(name: 'Joshua Kimmich',   age: 29, nationality: 'Germany',   position: 'MID', club: 'Bayern Munich',rating: 88),
  _Player(name: 'Casemiro',         age: 32, nationality: 'Brazil',    position: 'MID', club: 'Man United',  rating: 87),
  _Player(name: 'Marquinhos',       age: 29, nationality: 'Brazil',    position: 'DEF', club: 'PSG',         rating: 87),
  _Player(name: 'Gavi',             age: 19, nationality: 'Spain',     position: 'MID', club: 'Barcelona',   rating: 85),
  _Player(name: 'Ansu Fati',        age: 21, nationality: 'Spain',     position: 'FWD', club: 'Barcelona',   rating: 79),
  _Player(name: 'Raheem Sterling',  age: 29, nationality: 'England',   position: 'FWD', club: 'Chelsea',     rating: 84),
  _Player(name: 'Jack Grealish',    age: 28, nationality: 'England',   position: 'MID', club: 'Man City',    rating: 83),
  _Player(name: 'Cody Gakpo',       age: 24, nationality: 'Netherlands',position: 'FWD',club: 'Liverpool',   rating: 82),
  _Player(name: 'Denzel Dumfries',  age: 28, nationality: 'Netherlands',position: 'DEF',club: 'Inter Milan', rating: 83),
  _Player(name: 'Achraf Hakimi',    age: 25, nationality: 'Morocco',   position: 'DEF', club: 'PSG',         rating: 85),
  _Player(name: 'Yassine Bounou',   age: 32, nationality: 'Morocco',   position: 'GK',  club: 'Al-Hilal',   rating: 85),
  _Player(name: 'Sadio Mané',       age: 31, nationality: 'Senegal',   position: 'FWD', club: 'Al Nassr',    rating: 85),
  _Player(name: 'Son Heung-min',    age: 31, nationality: 'South Korea',position: 'FWD',club: 'Tottenham',   rating: 87),
  _Player(name: 'Paulo Dybala',     age: 30, nationality: 'Argentina', position: 'FWD', club: 'AS Roma',     rating: 84),
  _Player(name: 'Theo Hernández',   age: 26, nationality: 'France',    position: 'DEF', club: 'AC Milan',    rating: 85),
  _Player(name: 'Dayot Upamecano', age: 25, nationality: 'France',    position: 'DEF', club: 'Bayern Munich',rating: 85),
  _Player(name: 'Édouard Mendy',    age: 32, nationality: 'Senegal',   position: 'GK',  club: 'Al-Ahli',    rating: 83),
  _Player(name: 'Takehiro Tomiyasu',age: 25, nationality: 'Japan',     position: 'DEF', club: 'Arsenal',     rating: 80),
  _Player(name: 'Wataru Endo',      age: 30, nationality: 'Japan',     position: 'MID', club: 'Liverpool',   rating: 81),
  _Player(name: 'Ivan Perišić',     age: 35, nationality: 'Croatia',   position: 'MID', club: 'Hajduk Split',rating: 82),
  _Player(name: 'Luka Modrić',      age: 38, nationality: 'Croatia',   position: 'MID', club: 'Real Madrid', rating: 87),
  _Player(name: 'Mateo Kovačić',    age: 30, nationality: 'Croatia',   position: 'MID', club: 'Man City',    rating: 84),
  _Player(name: 'Granit Xhaka',     age: 31, nationality: 'Switzerland',position: 'MID',club: 'Leverkusen',  rating: 83),
  _Player(name: 'Xherdan Shaqiri',  age: 32, nationality: 'Switzerland',position: 'MID',club: 'Chicago Fire',rating: 79),
  _Player(name: 'Robert Lewandowski',age:35, nationality: 'Poland',    position: 'FWD', club: 'Barcelona',   rating: 89),
];

// ─── Clue result types ─────────────────────────────────────────────────────────
enum _Hint { correct, close, wrong }

class _GuessResult {
  final String playerName;
  final _Hint age;         // within 2 = close, exact = correct
  final _Hint nationality;
  final _Hint position;
  final _Hint club;
  final _Hint rating;      // within 5 = close, exact = correct

  const _GuessResult({
    required this.playerName,
    required this.age,
    required this.nationality,
    required this.position,
    required this.club,
    required this.rating,
  });
}

// ─── Provider ──────────────────────────────────────────────────────────────────
// ignore: library_private_types_in_public_api
class SportleState {
  // ignore: library_private_types_in_public_api
  final _Player target;
  // ignore: library_private_types_in_public_api
  final List<_GuessResult> guesses;
  final bool solved;
  final bool failed;
  final int ptsEarned;

  const SportleState({
    // ignore: library_private_types_in_public_api
    required this.target,
    this.guesses = const [],
    this.solved = false,
    this.failed = false,
    this.ptsEarned = 0,
  });

  int get attemptsLeft => 6 - guesses.length;
  bool get isOver => solved || failed || guesses.length >= 6;
}

class SportleNotifier extends Notifier<SportleState> {
  @override
  SportleState build() {
    Future.microtask(_loadTodayResult);
    return SportleState(target: _dailyPlayer());
  }

  static _Player _dailyPlayer() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _players[dayOfYear % _players.length];
  }

  Future<void> _loadTodayResult() async {
    try {
      final client = sb.Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      final today = DateTime.now().toIso8601String().split('T').first;
      final row = await client
          .from('sportle_results')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .maybeSingle();

      if (row != null) {
        final attempts = row['attempts'] as int? ?? 0;
        final solved = row['solved'] as bool? ?? false;
        if (solved || attempts >= 6) {
          state = SportleState(
            target: state.target,
            solved: solved,
            failed: !solved && attempts >= 6,
            ptsEarned: row['pts_earned'] as int? ?? 0,
            guesses: List.generate(attempts, (_) => _GuessResult(
              playerName: '---',
              age: _Hint.wrong, nationality: _Hint.wrong,
              position: _Hint.wrong, club: _Hint.wrong, rating: _Hint.wrong,
            )),
          );
        }
      }
    } catch (e) {
      debugPrint('Sportle load: $e');
    }
  }

  void guess(String playerName) {
    if (state.isOver) return;
    final target = state.target;

    final guessed = _players.where((p) => p.name.toLowerCase() == playerName.toLowerCase()).firstOrNull;
    if (guessed == null) return;

    final ageDiff  = (guessed.age - target.age).abs();
    final rateDiff = (guessed.rating - target.rating).abs();

    final result = _GuessResult(
      playerName: guessed.name,
      age:         ageDiff == 0  ? _Hint.correct : ageDiff <= 3  ? _Hint.close : _Hint.wrong,
      nationality: guessed.nationality == target.nationality ? _Hint.correct : _Hint.wrong,
      position:    guessed.position    == target.position    ? _Hint.correct : _Hint.wrong,
      club:        guessed.club        == target.club        ? _Hint.correct : _Hint.wrong,
      rating:      rateDiff == 0 ? _Hint.correct : rateDiff <= 5 ? _Hint.close : _Hint.wrong,
    );

    final newGuesses = [...state.guesses, result];
    final solved = guessed.name.toLowerCase() == target.name.toLowerCase();
    final failed = !solved && newGuesses.length >= 6;

    int pts = 0;
    if (solved) {
      pts = 11 - newGuesses.length; // attempt 1 → 10pts, attempt 6 → 5pts
      if (pts < 5) pts = 5;
      ref.read(authProvider.notifier).addPoints(pts);
      ref.read(authProvider.notifier).awardXp(amount: pts * 2, action: 'Sportle');
    }

    state = SportleState(
      target: target,
      guesses: newGuesses,
      solved: solved,
      failed: failed,
      ptsEarned: pts,
    );

    _persistResult(newGuesses.length, solved, pts);
  }

  Future<void> _persistResult(int attempts, bool solved, int pts) async {
    try {
      final client = sb.Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      final today = DateTime.now().toIso8601String().split('T').first;
      await client.from('sportle_results').upsert({
        'user_id': userId,
        'date': today,
        'attempts': attempts,
        'solved': solved,
        'pts_earned': pts,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');
    } catch (e) {
      debugPrint('Sportle persist: $e');
    }
  }

  String buildShareText() {
    final s = state;
    final lines = s.guesses.map((g) {
      final a = _hintEmoji(g.age);
      final n = _hintEmoji(g.nationality);
      final p = _hintEmoji(g.position);
      final c = _hintEmoji(g.club);
      final r = _hintEmoji(g.rating);
      return '$a$n$p$c$r';
    });
    final status = s.solved ? '${s.guesses.length}/6' : 'X/6';
    return '⚽ Sportle $status\n${lines.join('\n')}\nskorio.in';
  }

  String _hintEmoji(_Hint h) {
    switch (h) {
      case _Hint.correct: return '🟩';
      case _Hint.close:   return '🟨';
      case _Hint.wrong:   return '⬛';
    }
  }
}

final sportleProvider =
    NotifierProvider<SportleNotifier, SportleState>(
  SportleNotifier.new,
);



// ─── Screen ────────────────────────────────────────────────────────────────────
class SportleScreen extends ConsumerStatefulWidget {
  const SportleScreen({super.key});

  @override
  ConsumerState<SportleScreen> createState() => _SportleScreenState();
}

class _SportleScreenState extends ConsumerState<SportleScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  String? _inputError;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query) {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _suggestions = _players
          .where((p) => p.name.toLowerCase().contains(q))
          .map((p) => p.name)
          .take(6)
          .toList();
    });
  }

  void _submitGuess(String name) {
    if (name.trim().isEmpty) return;
    final exists = _players.any((p) => p.name.toLowerCase() == name.toLowerCase());
    if (!exists) {
      setState(() => _inputError = 'Player not found in the pool');
      _shakeCtrl.forward(from: 0);
      return;
    }
    setState(() { _inputError = null; _suggestions = []; });
    ref.read(sportleProvider.notifier).guess(name);
    _inputCtrl.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sportleProvider);

    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.0,
                colors: [Color(0xFF0C1A0C), Color(0xFF0A0A0F)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildHowToPlay(),
                        const SizedBox(height: 16),
                        _buildColumnHeaders(),
                        const SizedBox(height: 8),
                        _buildGuessGrid(state),
                        _buildEmptyRows(state),
                        const SizedBox(height: 20),
                        if (!state.isOver)
                          _buildInputArea(state)
                        else
                          _buildResultBanner(state),
                        const SizedBox(height: 40),
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

  Widget _buildTopBar(BuildContext context, SportleState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
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
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF43DF9E), Color(0xFF8B80FF)],
                ).createShader(b),
                child: Text('Sportle',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              Text('Daily Football Puzzle',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
            ],
          ),
          const Spacer(),
          // Attempts badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Text('${state.attemptsLeft} left',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF43DF9E).withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF43DF9E).withAlpha(40)),
      ),
      child: Text(
        '🟩 Correct  🟨 Close (age ±3, rating ±5)  ⬛ Wrong\nGuess the mystery World Cup player in 6 attempts!',
        style: GoogleFonts.inter(fontSize: 12, color: Colors.white60, height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildColumnHeaders() {
    const cols = ['Player', 'Age', 'Nation', 'Pos', 'Club', 'Rating'];
    return Row(
      children: cols.map((c) => Expanded(
        flex: c == 'Player' ? 3 : 2,
        child: Text(c,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white38)),
      )).toList(),
    );
  }

  Widget _buildGuessGrid(SportleState state) {
    return Column(
      children: state.guesses.map((g) => _GuessRow(
        guess: g,
        target: state.target,
      )).toList(),
    );
  }

  Widget _buildEmptyRows(SportleState state) {
    final remaining = 6 - state.guesses.length;
    if (remaining <= 0) return const SizedBox.shrink();
    return Column(
      children: List.generate(remaining, (_) => const _EmptyRow()),
    );
  }

  Widget _buildInputArea(SportleState state) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(math.sin(_shakeAnim.value * math.pi * 4) * 8, 0),
        child: child,
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _inputError != null
                    ? const Color(0xFFFF6B6B).withAlpha(120)
                    : const Color(0xFF43DF9E).withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    focusNode: _focusNode,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type a player name...',
                      hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: _updateSuggestions,
                    onSubmitted: _submitGuess,
                  ),
                ),
                GestureDetector(
                  onTap: () => _submitGuess(_inputCtrl.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF43DF9E), Color(0xFF00C082)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.send, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),

          if (_inputError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_inputError!,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFF6B6B))),
            ),

          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Column(
                children: _suggestions.map((s) => ListTile(
                  dense: true,
                  title: Text(s, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
                  leading: const Icon(Icons.sports_soccer, color: Colors.white38, size: 18),
                  onTap: () {
                    _inputCtrl.text = s;
                    setState(() => _suggestions = []);
                    _submitGuess(s);
                  },
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultBanner(SportleState state) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: state.solved
              ? const LinearGradient(colors: [Color(0xFF0D2B1A), Color(0xFF14532D)])
              : const LinearGradient(colors: [Color(0xFF2B0D0D), Color(0xFF7F1D1D)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: state.solved
                ? const Color(0xFF43DF9E).withAlpha(80)
                : const Color(0xFFFF6B6B).withAlpha(80),
          ),
        ),
        child: Column(
          children: [
            Text(state.solved ? '⚽ Correct!' : '💀 Game Over',
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              state.solved
                  ? 'The answer was ${state.target.name}\n+${state.ptsEarned} points earned!'
                  : 'The answer was ${state.target.name}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                final text = ref.read(sportleProvider.notifier).buildShareText();
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Result copied to clipboard!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B80FF), Color(0xFF4C1D95)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.share, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Share Result',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// ─── Guess row widget ──────────────────────────────────────────────────────────
class _GuessRow extends StatefulWidget {
  final _GuessResult guess;
  final _Player target;
  const _GuessRow({required this.guess, required this.target, super.key});

  @override
  State<_GuessRow> createState() => _GuessRowState();
}

class _GuessRowState extends State<_GuessRow> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final g = widget.guess;
    final guessed = _players.where((p) => p.name == g.playerName).firstOrNull;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _ctrl.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _ctrl.value) * 20),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            // Player name
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(15)),
                ),
                child: Text(
                  g.playerName,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Age
            _HintCell(hint: g.age,  label: '${guessed?.age ?? '?'}'),
            const SizedBox(width: 4),
            // Nationality
            _HintCell(hint: g.nationality, label: guessed?.nationality.split(' ').first ?? '?'),
            const SizedBox(width: 4),
            // Position
            _HintCell(hint: g.position,    label: guessed?.position ?? '?'),
            const SizedBox(width: 4),
            // Club
            _HintCell(hint: g.club,        label: guessed?.club.split(' ').first ?? '?'),
            const SizedBox(width: 4),
            // Rating
            _HintCell(hint: g.rating,      label: '${guessed?.rating ?? '?'}'),
          ],
        ),
      ),
    );
  }
}

class _HintCell extends StatelessWidget {
  final _Hint hint;
  final String label;
  const _HintCell({required this.hint, required this.label});

  Color get _color {
    switch (hint) {
      case _Hint.correct: return const Color(0xFF43DF9E);
      case _Hint.close:   return const Color(0xFFFFD700);
      case _Hint.wrong:   return const Color(0xFF374151);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _color.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _color.withAlpha(120), width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
    );
  }
}

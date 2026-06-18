import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/games_provider.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _WhoAmIPlayer {
  final String name;
  final List<String> clues;
  const _WhoAmIPlayer({required this.name, required this.clues});
}

const _kTeal = Color(0xFF2DD4BF);
const _kTealDark = Color(0xFF0F766E);
const _kBg = Color(0xFF080E0E);

const _cluePoints = [15, 12, 9, 6, 3, 1];

final _players = [
  _WhoAmIPlayer(
    name: 'Gianluigi Buffon',
    clues: [
      'I was born in Carrara, Italy, in 1978.',
      'I won the FIFA World Cup with Italy in 2006 as their first-choice goalkeeper.',
      'I spent the majority of my club career at Juventus, winning multiple Serie A titles.',
      'I hold the record for the most appearances in Serie A history.',
      'I wore the number 1 jersey and was known for my commanding presence and reflexes.',
      'My surname is also a type of cabinet used to store items.',
    ],
  ),
  _WhoAmIPlayer(
    name: 'Ronaldinho',
    clues: [
      'I was born in Porto Alegre, Brazil, in 1980.',
      'I won the FIFA World Cup with Brazil in 2002.',
      'I won the Ballon d\'Or in 2005 while playing for FC Barcelona.',
      'I was renowned for my dribbling, tricks, and joyful style of play.',
      'I played for clubs including PSG, Barça, AC Milan, and Flamengo.',
      'My nickname means "Little Ronaldo" in Portuguese.',
    ],
  ),
  _WhoAmIPlayer(
    name: 'Thierry Henry',
    clues: [
      'I was born in Les Ulis, France, in 1977.',
      'I won the FIFA World Cup with France in 1998.',
      'I became Arsenal\'s all-time top scorer with 228 goals.',
      'I was part of the legendary "Invincibles" Arsenal squad in 2003–04.',
      'I briefly played for FC Barcelona and the New York Red Bulls.',
      'A famous handball incident involving me decided a World Cup play-off.',
    ],
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class WhoAmIScreen extends ConsumerStatefulWidget {
  const WhoAmIScreen({super.key});
  @override
  ConsumerState<WhoAmIScreen> createState() => _WhoAmIScreenState();
}

enum _GameStage { playing, correct, wrong, finished }

class _WhoAmIScreenState extends ConsumerState<WhoAmIScreen>
    with TickerProviderStateMixin {
  late _WhoAmIPlayer _player;
  int _revealedClues = 1;
  int _currentPlayerIndex = 0;

  _GameStage _stage = _GameStage.playing;
  int _score = 0;

  // auto-reveal countdown
  Timer? _autoRevealTimer;
  int _countdown = 5;
  bool _autoRevealing = false;

  final _guessController = TextEditingController();
  final _scrollController = ScrollController();

  late AnimationController _fadeCtrl;
  late AnimationController _revealCtrl;
  late AnimationController _resultCtrl;

  @override
  void initState() {
    super.initState();
    _player = _players[_currentPlayerIndex];

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _autoRevealTimer?.cancel();
    _guessController.dispose();
    _scrollController.dispose();
    _fadeCtrl.dispose();
    _revealCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  // ── auto-reveal next clue ──
  void _startAutoReveal() {
    if (_revealedClues >= _player.clues.length) return;
    setState(() {
      _autoRevealing = true;
      _countdown = 5;
    });
    _autoRevealTimer?.cancel();
    _autoRevealTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _revealNextClue();
      }
    });
  }

  void _cancelAutoReveal() {
    _autoRevealTimer?.cancel();
    setState(() => _autoRevealing = false);
  }

  void _revealNextClue() {
    if (_revealedClues >= _player.clues.length) return;
    setState(() {
      _revealedClues++;
      _autoRevealing = false;
    });
    _revealCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── guess logic ──
  void _submitGuess() {
    final raw = _guessController.text.trim();
    if (raw.isEmpty) return;
    final guess = raw.toLowerCase();
    final answer = _player.name.toLowerCase();
    final isCorrect = guess == answer ||
        answer.contains(guess) ||
        guess.contains(answer.split(' ').last.toLowerCase());

    HapticFeedback.mediumImpact();

    if (isCorrect) {
      final pts = _cluePoints[_revealedClues - 1];
      setState(() {
        _score += pts;
        _stage = _GameStage.correct;
      });
      _resultCtrl.forward(from: 0);
    } else {
      setState(() {
        _stage = _GameStage.wrong;
      });
      _resultCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        _resultCtrl.reverse();
        setState(() {
          _stage = _GameStage.playing;
          _guessController.clear();
        });
        // auto-reveal next clue after wrong guess
        if (_revealedClues < _player.clues.length) {
          _startAutoReveal();
        }
      });
    }
  }

  void _nextPlayer() {
    _autoRevealTimer?.cancel();
    final next = _currentPlayerIndex + 1;
    if (next >= _players.length) {
      setState(() => _stage = _GameStage.finished);
      ref.read(gamesProvider.notifier).recordWhoAmISession(score: _score);
      return;
    }
    setState(() {
      _currentPlayerIndex = next;
      _player = _players[next];
      _revealedClues = 1;
      _stage = _GameStage.playing;
      _autoRevealing = false;
    });
    _guessController.clear();
    _fadeCtrl.forward(from: 0);
    _resultCtrl.reset();
  }

  Widget _buildLimitReached() {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          _buildAmbientBlobs(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.red, width: 2.5),
                    ),
                    child: const Icon(Icons.lock_clock_rounded, color: Colors.red, size: 52),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Daily Limit Reached',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have already played Who Am I? 5 times today. Please come back tomorrow for more puzzles!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kTeal, _kTealDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Back to Games',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gamesState = ref.watch(gamesProvider);
    final count = gamesState.dailyPlayCounts['who_am_i'] ?? 0;
    final limit = gamesState.dailyLimits['who_am_i'] ?? 5;
    final isLimitReached = count >= limit;

    if (isLimitReached && _stage != _GameStage.finished) {
      return _buildLimitReached();
    }

    if (_stage == _GameStage.finished) return _buildFinished();
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          _buildAmbientBlobs(),
          SafeArea(child: _buildBody()),
          if (_stage == _GameStage.correct) _buildCorrectOverlay(),
        ],
      ),
    );
  }

  // ── ambient blobs ──
  Widget _buildAmbientBlobs() {
    return Stack(children: [
      Positioned(
        top: -80, left: -60,
        child: Container(
          width: 260, height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kTeal.withValues(alpha: 0.06),
          ),
        ),
      ),
      Positioned(
        bottom: 100, right: -80,
        child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kTealDark.withValues(alpha: 0.08),
          ),
        ),
      ),
    ]);
  }

  // ── main body ──
  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeCtrl,
      child: Column(
        children: [
          _buildHeader(),
          _buildPlayerAvatar(),
          _buildClueBar(),
          const SizedBox(height: 12),
          Expanded(child: _buildClueList()),
          _buildBottomSection(),
        ],
      ),
    );
  }

  // ── header ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(children: [
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text('Back', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15)),
            ]),
          ),
          Expanded(
            child: Text(
              'Who Am I?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'Clue $_revealedClues/${_player.clues.length}',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── avatar ──
  Widget _buildPlayerAvatar() {
    return Column(children: [
      const SizedBox(height: 8),
      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _kTeal, width: 2.5),
          color: _kTeal.withValues(alpha: 0.1),
        ),
        child: const Icon(Icons.person_rounded, color: _kTeal, size: 44),
      ),
      const SizedBox(height: 8),
      Text(
        _stage == _GameStage.correct ? _player.name.toUpperCase() : 'MYSTERY PLAYER',
        style: GoogleFonts.outfit(
          color: _stage == _GameStage.correct ? _kTeal : Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }

  // ── clue bar ──
  Widget _buildClueBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_player.clues.length, (i) {
          final isActive = i == _revealedClues - 1;
          final isRevealed = i < _revealedClues;
          return Column(children: [
            Text(
              'C${i + 1}',
              style: GoogleFonts.outfit(
                color: isActive ? _kTeal : isRevealed ? Colors.white54 : Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? _kTeal.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? _kTeal : Colors.transparent,
                  width: isActive ? 1.5 : 0,
                ),
              ),
              child: Text(
                '${_cluePoints[i]}pt',
                style: GoogleFonts.outfit(
                  color: isActive ? _kTeal : isRevealed ? Colors.white54 : Colors.white24,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  // ── clue list ──
  Widget _buildClueList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _player.clues.length,
      itemBuilder: (ctx, i) {
        final isRevealed = i < _revealedClues;
        final isLatest = i == _revealedClues - 1;

        if (!isRevealed) {
          return _buildLockedClue(i + 1);
        }
        return _buildRevealedClue(i + 1, _player.clues[i], isLatest);
      },
    );
  }

  Widget _buildRevealedClue(int num, String text, bool isLatest) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLatest ? _kTeal.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLatest ? _kTeal.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
          width: isLatest ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLatest ? _kTeal : Colors.white24,
            ),
            child: Center(
              child: Text(
                '$num',
                style: GoogleFonts.outfit(
                  color: isLatest ? Colors.black : Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: isLatest ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: isLatest ? FontWeight.w600 : FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedClue(int num) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
          child: Center(
            child: Text('$num', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Text('???', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 15, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── bottom section ──
  Widget _buildBottomSection() {
    if (_stage == _GameStage.correct) {
      return _buildCorrectBottomBar();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGuessInput(),
        _buildRevealOrCountdown(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildGuessInput() {
    final isWrong = _stage == _GameStage.wrong;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isWrong ? Colors.red.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isWrong ? Colors.red.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: TextField(
              controller: _guessController,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: isWrong ? 'Wrong! Try again…' : 'Type a player name...',
                hintStyle: GoogleFonts.outfit(
                  color: isWrong ? Colors.red.withValues(alpha: 0.6) : Colors.white38,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onSubmitted: (_) => _submitGuess(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _submitGuess,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kTeal, _kTealDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('Guess', style: GoogleFonts.outfit(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  Widget _buildRevealOrCountdown() {
    if (_revealedClues >= _player.clues.length) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          'All clues revealed — make your guess!',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    if (_autoRevealing) {
      return GestureDetector(
        onTap: _cancelAutoReveal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
              children: [
                TextSpan(
                  text: '${_countdown}s',
                  style: GoogleFonts.outfit(color: _kTeal, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const TextSpan(text: ' before next clue…'),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _revealNextClue,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text(
              'Reveal next clue  (−${_cluePoints[_revealedClues]} pts max)',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectBottomBar() {
    final pts = _cluePoints[_revealedClues - 1];
    final isLast = _currentPlayerIndex >= _players.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kTeal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kTeal.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: _kTeal, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Correct!', style: GoogleFonts.outfit(color: _kTeal, fontSize: 16, fontWeight: FontWeight.w800)),
                Text('You earned $pts points this round', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _kTeal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('+$pts', style: GoogleFonts.outfit(color: _kTeal, fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _nextPlayer,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kTeal, _kTealDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              isLast ? 'See Final Score' : 'Next Player →',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ]),
    );
  }

  // ── correct overlay ──
  Widget _buildCorrectOverlay() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kTeal.withValues(alpha: 0.15), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── finished screen ──
  Widget _buildFinished() {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        _buildAmbientBlobs(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kTeal.withValues(alpha: 0.15),
                    border: Border.all(color: _kTeal, width: 2.5),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: _kTeal, size: 52),
                ),
                const SizedBox(height: 24),
                Text('Game Complete!', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'You identified all the mystery players',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 15),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                  decoration: BoxDecoration(
                    color: _kTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kTeal.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    Text('Total Score', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(
                      '$_score',
                      style: GoogleFonts.outfit(color: _kTeal, fontSize: 56, fontWeight: FontWeight.w900, height: 1),
                    ),
                    Text('pts', style: GoogleFonts.outfit(color: _kTeal.withValues(alpha: 0.7), fontSize: 18)),
                  ]),
                ),
                const SizedBox(height: 32),
                _buildScoreBadge(),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kTeal, _kTealDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text('Back to Games', textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildScoreBadge() {
    final maxPossible = _players.length * _cluePoints[0];
    final pct = (_score / maxPossible * 100).round();
    final label = pct >= 80 ? '🏆 Expert' : pct >= 50 ? '⭐ Good' : '📚 Keep Practising';
    final color = pct >= 80 ? _kTeal : pct >= 50 ? Colors.amber : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: GoogleFonts.outfit(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}

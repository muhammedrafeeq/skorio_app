import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/pitch_background.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/games_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum TriviaStage { select, loading, playing, answered, complete }

enum TriviaDifficulty { easy, medium, hard }

class TriviaQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const TriviaQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class QuestionResult {
  final bool correct;
  final int correctIndex;
  final int points;
  final String explanation;

  const QuestionResult({
    required this.correct,
    required this.correctIndex,
    required this.points,
    required this.explanation,
  });
}

// ─── Difficulty config ────────────────────────────────────────────────────────

class _DifficultyConfig {
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final int seconds;
  final String mult;

  const _DifficultyConfig({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.seconds,
    required this.mult,
  });
}

const Map<TriviaDifficulty, _DifficultyConfig> _diffConfig = {
  TriviaDifficulty.easy: _DifficultyConfig(
    label: 'Easy',
    color: Color(0xFF4ADE80),
    bgColor: Color(0x144ADE80),
    borderColor: Color(0x404ADE80),
    seconds: 30,
    mult: '×1',
  ),
  TriviaDifficulty.medium: _DifficultyConfig(
    label: 'Medium',
    color: Color(0xFFF59E0B),
    bgColor: Color(0x14F59E0B),
    borderColor: Color(0x40F59E0B),
    seconds: 25,
    mult: '×2',
  ),
  TriviaDifficulty.hard: _DifficultyConfig(
    label: 'Hard',
    color: Color(0xFFF87171),
    bgColor: Color(0x14F87171),
    borderColor: Color(0x40F87171),
    seconds: 20,
    mult: '×3',
  ),
};

// ─── Mock question bank ───────────────────────────────────────────────────────

const List<TriviaQuestion> _mockQuestions = [
  TriviaQuestion(
    id: 1,
    question: "Which club has won the most FA Cup titles?",
    options: ["Tottenham", "Chelsea", "Arsenal", "Manchester United"],
    correctIndex: 2,
    explanation: "Arsenal have won the FA Cup a record 14 times, most recently in 2020.",
  ),
  TriviaQuestion(
    id: 2,
    question: "Which country hosted the 2019 Women's World Cup?",
    options: ["Germany", "USA", "England", "France"],
    correctIndex: 3,
    explanation: "France hosted the 2019 FIFA Women's World Cup. USA won the tournament.",
  ),
  TriviaQuestion(
    id: 3,
    question: "Who won the Golden Boot at Euro 2024?",
    options: ["Kylian Mbappé", "Harry Kane", "Dani Olmo", "Cristiano Ronaldo"],
    correctIndex: 2,
    explanation: "Dani Olmo won the Golden Boot at Euro 2024 as part of Spain's title-winning campaign.",
  ),
  TriviaQuestion(
    id: 4,
    question: "How many Premier League goals did Erling Haaland score in 2022-23?",
    options: ["28", "32", "36", "40"],
    correctIndex: 2,
    explanation: "Erling Haaland scored 36 Premier League goals in 2022-23, breaking the all-time single-season record.",
  ),
  TriviaQuestion(
    id: 5,
    question: "Who scored both goals in Brazil's 2-0 win over Germany in the 2002 World Cup final?",
    options: ["Rivaldo", "Ronaldo Nazário", "Ronaldinho", "Roberto Carlos"],
    correctIndex: 1,
    explanation: "Brazil beat Germany 2-0 in the 2002 World Cup final, with both goals from Ronaldo Nazário.",
  ),
  TriviaQuestion(
    id: 6,
    question: "England's Lionesses won Women's Euro 2022 on home soil, beating which team in the final?",
    options: ["Sweden", "France", "Germany", "Spain"],
    correctIndex: 2,
    explanation: "England's Lionesses won Women's Euro 2022 on home soil, beating Germany 2-1 in extra time at Wembley.",
  ),
  TriviaQuestion(
    id: 7,
    question: "In which city was UEFA founded in 1954?",
    options: ["Paris", "Vienna", "Basel", "Zurich"],
    correctIndex: 2,
    explanation: "UEFA was founded in 1954 in Basel, Switzerland.",
  ),
  TriviaQuestion(
    id: 8,
    question: "Which club did Lionel Messi join after leaving Barcelona in 2021?",
    options: ["Manchester City", "Chelsea", "Paris Saint-Germain", "Inter Miami"],
    correctIndex: 2,
    explanation: "Messi joined Paris Saint-Germain on a free transfer after Barcelona's financial difficulties forced his exit.",
  ),
  TriviaQuestion(
    id: 9,
    question: "Which nation has won the most FIFA World Cup titles?",
    options: ["Germany", "Brazil", "Italy", "Argentina"],
    correctIndex: 1,
    explanation: "Brazil has won the FIFA World Cup a record 5 times (1958, 1962, 1970, 1994, 2002).",
  ),
  TriviaQuestion(
    id: 10,
    question: "Who is the all-time top scorer in UEFA Champions League history?",
    options: ["Lionel Messi", "Cristiano Ronaldo", "Robert Lewandowski", "Raúl"],
    correctIndex: 1,
    explanation: "Cristiano Ronaldo is the all-time top scorer in the UEFA Champions League with over 140 goals.",
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class TriviaScreen extends ConsumerStatefulWidget {
  const TriviaScreen({super.key});

  @override
  ConsumerState<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends ConsumerState<TriviaScreen>
    with TickerProviderStateMixin {
  TriviaStage _stage = TriviaStage.select;
  TriviaDifficulty _difficulty = TriviaDifficulty.medium;

  List<TriviaQuestion> _questions = [];
  int _currentIdx = 0;
  int _selectedOption = -1;
  int _timeLeft = 25;
  int _currentStreak = 0;
  int _totalPoints = 0;
  int _streakBonus = 0;
  final List<Map<String, dynamic>> _answers = [];
  final List<QuestionResult> _results = [];

  Timer? _timer;
  DateTime? _questionStart;
  bool _answered = false;

  // Animations
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _optionCtrl;
  late Animation<double> _optionAnim;
  late AnimationController _streakCtrl;
  late Animation<double> _streakAnim;
  late AnimationController _resultCtrl;
  late Animation<double> _resultAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _optionCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _optionAnim = CurvedAnimation(parent: _optionCtrl, curve: Curves.easeOut);

    _streakCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _streakAnim = CurvedAnimation(parent: _streakCtrl, curve: Curves.elasticOut);

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _resultAnim = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    _optionCtrl.dispose();
    _streakCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  _DifficultyConfig get _cfg => _diffConfig[_difficulty]!;

  void _startGame() {
    final rng = math.Random();
    final shuffled = List<TriviaQuestion>.from(_mockQuestions)..shuffle(rng);
    final questions = shuffled.take(10).toList();

    setState(() {
      _stage = TriviaStage.playing;
      _questions = questions;
      _currentIdx = 0;
      _selectedOption = -1;
      _currentStreak = 0;
      _totalPoints = 0;
      _streakBonus = 0;
      _answers.clear();
      _results.clear();
      _answered = false;
    });

    _fadeCtrl.forward(from: 0);
    _optionCtrl.forward(from: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _questionStart = DateTime.now();
    _answered = false;
    setState(() => _timeLeft = _cfg.seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        if (!_answered) _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _answered = true;
    final spent = _cfg.seconds;
    final q = _questions[_currentIdx];
    _answers.add({'questionId': q.id, 'answerIndex': -1, 'timeSpent': spent});
    setState(() {
      _selectedOption = -1;
      _currentStreak = 0;
      _stage = TriviaStage.answered;
    });
    _resultCtrl.forward(from: 0);
    _scheduleNext();
  }

  void _handleAnswer(int optionIdx) {
    if (_answered || _stage != TriviaStage.playing) return;
    _answered = true;
    _timer?.cancel();

    final q = _questions[_currentIdx];
    final spent = DateTime.now().difference(_questionStart!).inSeconds;
    _answers.add({'questionId': q.id, 'answerIndex': optionIdx, 'timeSpent': spent});

    final isCorrect = optionIdx == q.correctIndex;
    if (isCorrect) {
      _currentStreak++;
      if (_currentStreak >= 3) _streakCtrl.forward(from: 0);
    } else {
      _currentStreak = 0;
    }

    setState(() {
      _selectedOption = optionIdx;
      _stage = TriviaStage.answered;
    });
    _resultCtrl.forward(from: 0);
    _scheduleNext();
  }

  void _scheduleNext() {
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      if (_currentIdx + 1 >= _questions.length) {
        _calculateResults();
      } else {
        setState(() {
          _currentIdx++;
          _selectedOption = -1;
          _stage = TriviaStage.playing;
          _answered = false;
        });
        _optionCtrl.forward(from: 0);
        _fadeCtrl.forward(from: 0);
        _startTimer();
      }
    });
  }

  void _calculateResults() {
    int total = 0;
    int bonus = 0;
    final results = <QuestionResult>[];
    int streak = 0;

    for (int i = 0; i < _answers.length; i++) {
      final a = _answers[i];
      final q = _questions[i];
      final isCorrect = a['answerIndex'] == q.correctIndex;
      final timeSpent = a['timeSpent'] as int;

      int pts = 0;
      if (isCorrect) {
        final speedMult = timeSpent < 10 ? 3 : timeSpent < 20 ? 2 : 1;
        final diffMult = _difficulty == TriviaDifficulty.easy ? 1 : _difficulty == TriviaDifficulty.medium ? 2 : 3;
        pts = speedMult * diffMult;
        streak++;
        if (streak >= 3) { bonus++; pts++; }
      } else {
        streak = 0;
      }

      total += pts;
      results.add(QuestionResult(
        correct: isCorrect,
        correctIndex: q.correctIndex,
        points: pts,
        explanation: q.explanation,
      ));
    }

    final correctCount = results.where((r) => r.correct).length;
    ref.read(gamesProvider.notifier).recordTriviaSession(
      score: total,
      correctCount: correctCount,
      difficulty: _difficulty.name,
    );
    if (correctCount > 0) {
      ref.read(authProvider.notifier).awardXp(
        amount: correctCount * 20,
        action: 'Trivia Correct Answers',
      );
    }

    setState(() {
      _results.addAll(results);
      _totalPoints = total;
      _streakBonus = bonus;
      _stage = TriviaStage.complete;
    });
    _resultCtrl.forward(from: 0);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050A),
      body: Stack(
        children: [
          const PitchBackground(child: SizedBox.expand()),
          // Ambient blob top-left
          Positioned(
            top: 80,
            left: -100,
            child: _ambientBlob(const Color(0xFF38BDF8), 280),
          ),
          // Ambient blob bottom-right
          Positioned(
            bottom: 120,
            right: -100,
            child: _ambientBlob(const Color(0xFF6366F1), 240),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: _buildStage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case TriviaStage.select:
        return _buildSelectView();
      case TriviaStage.loading:
        return _buildLoadingView();
      case TriviaStage.playing:
      case TriviaStage.answered:
        return _buildPlayingView();
      case TriviaStage.complete:
        return _buildCompleteView();
    }
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

  // ─── Stage 1: Select Difficulty ────────────────────────────────────────────

  Widget _buildSelectView() {
    final gamesState = ref.watch(gamesProvider);
    final triviaCount = gamesState.dailyPlayCounts['trivia'] ?? 0;
    final triviaLimit = gamesState.dailyLimits['trivia'] ?? 5;
    final remainingTrivia = triviaLimit - triviaCount;
    final isLimitReached = remainingTrivia <= 0;

    return SingleChildScrollView(
      key: const ValueKey('select'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            children: [
              _backButton(() => context.go('/games')),
              const Spacer(),
              Text(
                'Football Trivia',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _langBadge(),
            ],
          ),
          const SizedBox(height: 36),

          // Brain emoji hero
          FloatingWidget(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.14),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('🧠', style: TextStyle(fontSize: 52)),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Choose Difficulty',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Harder = higher point multiplier',
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),

          // Difficulty cards
          ...TriviaDifficulty.values.map((d) => _buildDiffCard(d)),
          const SizedBox(height: 20),

          // Streak bonus banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFBBF24).withOpacity(0.18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  '3+ correct in a row = streak bonus (+1 pt each)',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFBBF24),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Remaining daily plays
          Text(
            'Remaining daily plays: $remainingTrivia / $triviaLimit',
            style: GoogleFonts.outfit(
              color: isLimitReached ? const Color(0xFFF87171) : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLimitReached
                      ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                      : [
                          _cfg.color.withOpacity(0.9),
                          _cfg.color.withOpacity(0.6),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: isLimitReached
                    ? []
                    : [
                        BoxShadow(
                          color: _cfg.color.withOpacity(0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: isLimitReached ? null : _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  isLimitReached ? 'Daily Limit Reached' : 'Start ${_cfg.label}',
                  style: GoogleFonts.outfit(
                    color: isLimitReached ? Colors.white30 : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDiffCard(TriviaDifficulty d) {
    final cfg = _diffConfig[d]!;
    final selected = _difficulty == d;

    return GestureDetector(
      onTap: () => setState(() => _difficulty = d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? cfg.bgColor : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? cfg.borderColor : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: cfg.color.withOpacity(0.12), blurRadius: 18, spreadRadius: 2)]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cfg.label,
                    style: GoogleFonts.outfit(
                      color: selected ? cfg.color : Colors.white60,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cfg.seconds}s per question',
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              cfg.mult,
              style: GoogleFonts.outfit(
                color: cfg.color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stage 2: Loading ──────────────────────────────────────────────────────

  Widget _buildLoadingView() {
    return Center(
      key: const ValueKey('loading'),
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          color: _cfg.color,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  // ─── Stage 3: Playing ──────────────────────────────────────────────────────

  Widget _buildPlayingView() {
    if (_questions.isEmpty) return const SizedBox();
    final q = _questions[_currentIdx];
    final isAnswered = _stage == TriviaStage.answered;
    final timerPct = _timeLeft / _cfg.seconds;
    final timerColor = _timeLeft <= 8 ? const Color(0xFFF87171) : _cfg.color;

    return Column(
      key: const ValueKey('playing'),
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _backButton(() => setState(() => _stage = TriviaStage.select)),
              const Spacer(),
              // Difficulty pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _cfg.bgColor,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _cfg.borderColor),
                ),
                child: Text(
                  _cfg.label,
                  style: GoogleFonts.outfit(
                    color: _cfg.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Q counter
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700),
                  children: [
                    const TextSpan(text: 'Q '),
                    TextSpan(
                      text: '${_currentIdx + 1}',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    TextSpan(text: ' / ${_questions.length}'),
                  ],
                ),
              ),
              const Spacer(),
              // Streak badge
              if (_currentStreak >= 3) ...[
                ScaleTransition(
                  scale: _streakAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 2),
                        Text(
                          '$_currentStreak',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              // Timer
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 15, color: timerColor),
                  const SizedBox(width: 4),
                  Text(
                    '${_timeLeft}s',
                    style: GoogleFonts.outfit(
                      color: timerColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress dots
                Row(
                  children: List.generate(_questions.length, (i) {
                    Color dotColor;
                    if (i < _currentIdx) {
                      dotColor = _cfg.color;
                    } else if (i == _currentIdx) {
                      dotColor = _cfg.color.withOpacity(0.4);
                    } else {
                      dotColor = Colors.white.withOpacity(0.1);
                    }
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        margin: EdgeInsets.only(right: i < _questions.length - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Timer bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    height: 5,
                    color: Colors.white.withOpacity(0.08),
                    child: LayoutBuilder(builder: (ctx, cns) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.linear,
                        width: cns.maxWidth * timerPct.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          color: timerColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 18),

                // Question card
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(_fadeAnim),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUESTION ${_currentIdx + 1}',
                            style: GoogleFonts.outfit(
                              color: _cfg.color.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            q.question,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Options
                ...List.generate(q.options.length, (i) => _buildOption(q, i, isAnswered)),
                const SizedBox(height: 12),

                // Bottom hint
                AnimatedOpacity(
                  opacity: isAnswered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: Text(
                      _currentIdx + 1 < _questions.length
                          ? 'Next question loading...'
                          : 'Submitting your answers...',
                      style: GoogleFonts.outfit(
                        color: Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(TriviaQuestion q, int i, bool isAnswered) {
    final labels = ['A', 'B', 'C', 'D'];
    Color borderColor = Colors.white.withOpacity(0.1);
    Color bgColor = Colors.white.withOpacity(0.04);
    Color textColor = Colors.white.withOpacity(0.8);
    Color labelBg = Colors.white.withOpacity(0.08);
    Color labelText = Colors.white54;

    if (isAnswered) {
      if (i == q.correctIndex) {
        // Always highlight correct answer
        borderColor = const Color(0xFF4ADE80).withOpacity(0.6);
        bgColor = const Color(0xFF4ADE80).withOpacity(0.08);
        textColor = Colors.white;
        labelBg = const Color(0xFF4ADE80).withOpacity(0.2);
        labelText = const Color(0xFF4ADE80);
      } else if (i == _selectedOption && _selectedOption != q.correctIndex) {
        // Wrong selected
        borderColor = const Color(0xFFF87171).withOpacity(0.6);
        bgColor = const Color(0xFFF87171).withOpacity(0.08);
        textColor = Colors.white60;
        labelBg = const Color(0xFFF87171).withOpacity(0.2);
        labelText = const Color(0xFFF87171);
      } else {
        borderColor = Colors.white.withOpacity(0.04);
        bgColor = Colors.white.withOpacity(0.02);
        textColor = Colors.white.withOpacity(0.3);
        labelBg = Colors.white.withOpacity(0.04);
        labelText = Colors.white24;
      }
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(-0.06 - i * 0.01, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _optionCtrl,
        curve: Interval(i * 0.08, 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _optionCtrl,
            curve: Interval(i * 0.08, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: GestureDetector(
          onTap: isAnswered ? null : () => _handleAnswer(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.4),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: labelBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: GoogleFonts.outfit(
                      color: labelText,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    q.options[i],
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                // Correct/wrong icon
                if (isAnswered && i == q.correctIndex)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
                if (isAnswered && i == _selectedOption && _selectedOption != q.correctIndex)
                  const Icon(Icons.cancel_rounded, color: Color(0xFFF87171), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Stage 4: Complete ─────────────────────────────────────────────────────

  Widget _buildCompleteView() {
    final correctCount = _results.where((r) => r.correct).length;
    final trophy = _totalPoints >= 60 ? '🏆' : _totalPoints >= 30 ? '🧠' : '📚';

    return SingleChildScrollView(
      key: const ValueKey('complete'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Back
          Align(
            alignment: Alignment.centerLeft,
            child: _backButton(() => context.go('/games')),
          ),
          const SizedBox(height: 28),

          // Trophy emoji
          FadeTransition(
            opacity: _resultAnim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                  .animate(_resultAnim),
              child: Column(
                children: [
                  Text(trophy, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 14),
                  Text(
                    'Quiz Complete!',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                      children: [
                        TextSpan(text: '$correctCount/${_questions.length} correct · '),
                        TextSpan(
                          text: _cfg.label,
                          style: TextStyle(color: _cfg.color, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Points card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Color(0xFF38BDF8), size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '$_totalPoints pts',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF38BDF8),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Streak bonus
                  if (_streakBonus > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            '+$_streakBonus streak bonus included!',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFBBF24),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Q breakdown
          ..._results.asMap().entries.map((e) => _buildResultRow(e.key, e.value)),
          const SizedBox(height: 16),

          // Speed bonus info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Speed bonus: <10s = ×3 · 10-20s = ×2 · >20s = ×1',
                  style: GoogleFonts.outfit(
                    color: Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Play Again
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => setState(() {
                _stage = TriviaStage.select;
                _results.clear();
                _answers.clear();
              }),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Play Again',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Back to Games
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => context.go('/games'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.07)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Back to Games Hub',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildResultRow(int index, QuestionResult r) {
    final streakPts = r.points > (_difficulty == TriviaDifficulty.easy ? 3 : _difficulty == TriviaDifficulty.medium ? 6 : 9);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: r.correct
            ? const Color(0xFF4ADE80).withOpacity(0.05)
            : const Color(0xFFF87171).withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: r.correct
              ? const Color(0xFF4ADE80).withOpacity(0.18)
              : const Color(0xFFF87171).withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                r.correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: r.correct ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Q${index + 1}',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (r.correct && streakPts)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 14),
                ),
              Text(
                r.correct ? '+${r.points} pts' : '0 pts',
                style: GoogleFonts.outfit(
                  color: r.correct ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.explanation,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared widgets ────────────────────────────────────────────────────────

  Widget _backButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 14),
          const SizedBox(width: 4),
          Text(
            'Back',
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _langBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFA78BFA).withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.25)),
      ),
      child: Text(
        'മല',
        style: GoogleFonts.outfit(
          color: const Color(0xFFC4B5FD),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

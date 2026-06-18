import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/games_provider.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _FlagQuizCountry {
  final String name;
  final String code; // ISO 2-letter lowercase code
  const _FlagQuizCountry({required this.name, required this.code});
}

const List<_FlagQuizCountry> _kCountries = [
  _FlagQuizCountry(name: 'Brazil', code: 'br'),
  _FlagQuizCountry(name: 'Argentina', code: 'ar'),
  _FlagQuizCountry(name: 'France', code: 'fr'),
  _FlagQuizCountry(name: 'Germany', code: 'de'),
  _FlagQuizCountry(name: 'Spain', code: 'es'),
  _FlagQuizCountry(name: 'Portugal', code: 'pt'),
  _FlagQuizCountry(name: 'Italy', code: 'it'),
  _FlagQuizCountry(name: 'Netherlands', code: 'nl'),
  _FlagQuizCountry(name: 'Belgium', code: 'be'),
  _FlagQuizCountry(name: 'Croatia', code: 'hr'),
  _FlagQuizCountry(name: 'Uruguay', code: 'uy'),
  _FlagQuizCountry(name: 'Colombia', code: 'co'),
  _FlagQuizCountry(name: 'Senegal', code: 'sn'),
  _FlagQuizCountry(name: 'Morocco', code: 'ma'),
  _FlagQuizCountry(name: 'Japan', code: 'jp'),
  _FlagQuizCountry(name: 'South Korea', code: 'kr'),
  _FlagQuizCountry(name: 'Saudi Arabia', code: 'sa'),
  _FlagQuizCountry(name: 'Qatar', code: 'qa'),
  _FlagQuizCountry(name: 'USA', code: 'us'),
  _FlagQuizCountry(name: 'Mexico', code: 'mx'),
  _FlagQuizCountry(name: 'Canada', code: 'ca'),
  _FlagQuizCountry(name: 'Jamaica', code: 'jm'),
  _FlagQuizCountry(name: 'Chile', code: 'cl'),
  _FlagQuizCountry(name: 'Peru', code: 'pe'),
  _FlagQuizCountry(name: 'Ecuador', code: 'ec'),
  _FlagQuizCountry(name: 'Venezuela', code: 've'),
  _FlagQuizCountry(name: 'Paraguay', code: 'py'),
  _FlagQuizCountry(name: 'Panama', code: 'pa'),
  _FlagQuizCountry(name: 'Costa Rica', code: 'cr'),
  _FlagQuizCountry(name: 'Switzerland', code: 'ch'),
  _FlagQuizCountry(name: 'Denmark', code: 'dk'),
  _FlagQuizCountry(name: 'Sweden', code: 'se'),
  _FlagQuizCountry(name: 'Norway', code: 'no'),
  _FlagQuizCountry(name: 'Poland', code: 'pl'),
  _FlagQuizCountry(name: 'Austria', code: 'at'),
  _FlagQuizCountry(name: 'Egypt', code: 'eg'),
  _FlagQuizCountry(name: 'Nigeria', code: 'ng'),
  _FlagQuizCountry(name: 'Cameroon', code: 'cm'),
  _FlagQuizCountry(name: 'Tunisia', code: 'tn'),
  _FlagQuizCountry(name: 'Ghana', code: 'gh'),
  _FlagQuizCountry(name: 'Ivory Coast', code: 'ci'),
  _FlagQuizCountry(name: 'Australia', code: 'au'),
  _FlagQuizCountry(name: 'Iran', code: 'ir'),
  _FlagQuizCountry(name: 'UAE', code: 'ae'),
  _FlagQuizCountry(name: 'South Africa', code: 'za'),
  _FlagQuizCountry(name: 'Turkey', code: 'tr'),
  _FlagQuizCountry(name: 'New Zealand', code: 'nz'),
  _FlagQuizCountry(name: 'Ukraine', code: 'ua'),
];

// Aesthetic Colors
const Color _kPink = Color(0xFFEC4899);
const Color _kPinkDark = Color(0xFF9D174D);
const Color _kBg = Color(0xFF0C0407);

enum _FlagQuizStage { playing, answered, finished }

class FlagQuizScreen extends ConsumerStatefulWidget {
  const FlagQuizScreen({super.key});

  @override
  ConsumerState<FlagQuizScreen> createState() => _FlagQuizScreenState();
}

class _FlagQuizScreenState extends ConsumerState<FlagQuizScreen>
    with TickerProviderStateMixin {
  
  // Game state
  final List<_FlagQuizCountry> _sessionCountries = [];
  int _roundIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  _FlagQuizStage _stage = _FlagQuizStage.playing;

  // Active round state
  late _FlagQuizCountry _correctCountry;
  late List<_FlagQuizCountry> _options;
  _FlagQuizCountry? _selectedCountry;
  
  // Timer state
  Timer? _timer;
  int _secondsRemaining = 10;
  late DateTime _roundStartTime;
  int _pointsEarnedThisRound = 0;
  bool _gotCardDrop = false;
  String? _cardDropName;

  // Animation controllers
  late AnimationController _fadeCtrl;
  late AnimationController _progressCtrl;

  // Mock players for card drops
  final List<String> _mockPlayers = [
    'Lionel Messi', 'Cristiano Ronaldo', 'Kylian Mbappé', 
    'Erling Haaland', 'Neymar Jr', 'Kevin De Bruyne', 
    'Mohamed Salah', 'Harry Kane', 'Robert Lewandowski'
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10));

    // Choose 5 random unique countries for the session
    final rand = math.Random();
    final allCountries = List<_FlagQuizCountry>.from(_kCountries)..shuffle(rand);
    _sessionCountries.addAll(allCountries.take(5));

    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _startRound() {
    _correctCountry = _sessionCountries[_roundIndex];
    
    // Choose 3 random wrong options
    final rand = math.Random();
    final wrongPool = _kCountries.where((c) => c.code != _correctCountry.code).toList()..shuffle(rand);
    
    _options = [
      _correctCountry,
      wrongPool[0],
      wrongPool[1],
      wrongPool[2],
    ]..shuffle(rand);

    _selectedCountry = null;
    _secondsRemaining = 10;
    _pointsEarnedThisRound = 0;
    _gotCardDrop = false;
    _cardDropName = null;
    _stage = _FlagQuizStage.playing;
    
    _roundStartTime = DateTime.now();

    _fadeCtrl.forward(from: 0);
    _progressCtrl.forward(from: 0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          _timer?.cancel();
          _submitTimeOut();
        }
      });
    });
  }

  void _submitTimeOut() {
    HapticFeedback.heavyImpact();
    setState(() {
      _stage = _FlagQuizStage.answered;
    });
  }

  void _chooseOption(_FlagQuizCountry country) {
    if (_stage != _FlagQuizStage.playing) return;
    _timer?.cancel();
    _progressCtrl.stop();

    final isCorrect = country.code == _correctCountry.code;
    final elapsed = DateTime.now().difference(_roundStartTime).inMilliseconds / 1000.0;
    
    int pts = 0;
    bool cardDrop = false;
    String? droppedPlayer;

    if (isCorrect) {
      _correctCount++;
      HapticFeedback.lightImpact();
      
      // Speed points
      if (elapsed <= 3.0) {
        pts = 3;
      } else if (elapsed <= 6.0) {
        pts = 2;
      } else {
        pts = 1;
      }

      // Card drop probability based on speed
      final chance = elapsed <= 3.0 ? 0.70 : elapsed <= 6.0 ? 0.55 : 0.40;
      if (math.Random().nextDouble() <= chance) {
        cardDrop = true;
        droppedPlayer = _mockPlayers[math.Random().nextInt(_mockPlayers.length)];
      }
    } else {
      HapticFeedback.vibrate();
    }

    setState(() {
      _selectedCountry = country;
      _pointsEarnedThisRound = pts;
      _score += pts;
      _gotCardDrop = cardDrop;
      _cardDropName = droppedPlayer;
      _stage = _FlagQuizStage.answered;
    });
  }

  void _nextRound() {
    if (_roundIndex < 4) {
      setState(() {
        _roundIndex++;
      });
      _startRound();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    
    // Add perfect round bonus
    if (_correctCount == 5) {
      _score += 5;
    }

    setState(() {
      _stage = _FlagQuizStage.finished;
    });

    ref.read(gamesProvider.notifier).recordFlagsSession(score: _score);
    if (_correctCount > 0) {
      ref.read(authProvider.notifier).awardXp(
        amount: _correctCount * 5,
        action: 'Flag Quiz Correct Flags',
      );
    }
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
                      color: Colors.red.withOpacity(0.15),
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
                    'You have already played Flag Quiz 5 times today. Please come back tomorrow for more challenges!',
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
                          colors: [_kPink, _kPinkDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Back to Games',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
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
    final count = gamesState.dailyPlayCounts['flags'] ?? 0;
    final limit = gamesState.dailyLimits['flags'] ?? 5;
    final isLimitReached = count >= limit;

    if (isLimitReached && _stage != _FlagQuizStage.finished) {
      return _buildLimitReached();
    }

    if (_stage == _FlagQuizStage.finished) return _buildFinished();

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          _buildAmbientBlobs(),
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildAmbientBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPink.withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPinkDark.withOpacity(0.08),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeCtrl,
      child: Column(
        children: [
          _buildHeader(),
          _buildProgressBar(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildFlagCard(),
                  const SizedBox(height: 28),
                  _buildTimerText(),
                  const SizedBox(height: 16),
                  _buildOptionsList(),
                  const SizedBox(height: 20),
                  if (_stage == _FlagQuizStage.answered) _buildRoundResultPanel(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text('Back', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15)),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'Flag Quiz',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'Round ${_roundIndex + 1}/5',
            style: GoogleFonts.outfit(color: _kPink, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_roundIndex) / 5;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress == 0 ? 0.02 : progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kPink, _kPinkDark]),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildFlagCard() {
    final flagUrl = 'https://flagcdn.com/w320/${_correctCountry.code}.png';
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _kPink.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                flagUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) {
                  return Container(
                    color: Colors.white.withOpacity(0.04),
                    child: const Icon(Icons.flag_rounded, color: Colors.white24, size: 50),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerText() {
    final timerColor = _secondsRemaining <= 3 ? Colors.red : _secondsRemaining <= 6 ? Colors.orange : _kPink;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TIMER',
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
            ),
            Text(
              '${_secondsRemaining}s',
              style: GoogleFonts.outfit(color: timerColor, fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _progressCtrl,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 1 - _progressCtrl.value,
                minHeight: 5,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptionsList() {
    return Column(
      children: _options.map((opt) {
        final isSelected = _selectedCountry?.code == opt.code;
        final isCorrect = opt.code == _correctCountry.code;
        final showResults = _stage == _FlagQuizStage.answered;

        Color borderColor = Colors.white.withOpacity(0.1);
        Color bgColor = Colors.white.withOpacity(0.03);
        Color textColor = Colors.white70;
        Widget? trailing;

        if (showResults) {
          if (isCorrect) {
            borderColor = const Color(0xFF10B981).withOpacity(0.8);
            bgColor = const Color(0xFF10B981).withOpacity(0.12);
            textColor = const Color(0xFF34D399);
            trailing = const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20);
          } else if (isSelected) {
            borderColor = const Color(0xFFEF4444).withOpacity(0.8);
            bgColor = const Color(0xFFEF4444).withOpacity(0.12);
            textColor = const Color(0xFFF87171);
            trailing = const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20);
          } else {
            textColor = Colors.white24;
          }
        } else if (isSelected) {
          borderColor = _kPink;
          bgColor = _kPink.withOpacity(0.1);
          textColor = Colors.white;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: _stage == _FlagQuizStage.playing ? () => _chooseOption(opt) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    opt.name,
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: isSelected || (showResults && isCorrect) ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoundResultPanel() {
    final isCorrect = _selectedCountry?.code == _correctCountry.code;
    final isLast = _roundIndex >= 4;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF10B981).withOpacity(0.08) : const Color(0xFFEF4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCorrect ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? 'Correct!' : _selectedCountry == null ? 'Time\'s Up!' : 'Incorrect!',
                      style: GoogleFonts.outfit(
                        color: isCorrect ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCorrect
                          ? 'You earned $_pointsEarnedThisRound points'
                          : 'The correct country is ${_correctCountry.name}',
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isCorrect)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$_pointsEarnedThisRound',
                    style: GoogleFonts.outfit(color: const Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          if (_gotCardDrop && _cardDropName != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.style_rounded, color: _kPink, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Card Drop: $_cardDropName (Common)',
                    style: GoogleFonts.outfit(color: _kPink, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kPink.withOpacity(0.3)),
                  ),
                  child: Text(
                    'VAULTED',
                    style: GoogleFonts.outfit(color: _kPink, fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _nextRound,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPink, _kPinkDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isLast ? 'See Final Score' : 'Next Flag →',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished() {
    final isPerfect = _correctCount == 5;
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
                      color: _kPink.withOpacity(0.15),
                      border: Border.all(color: _kPink, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: _kPink.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
                      ],
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: _kPink, size: 52),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quiz Complete!',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPerfect 
                        ? 'Perfect round! +5 pts bonus added!'
                        : 'You identified $_correctCount/5 flags correctly.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    decoration: BoxDecoration(
                      color: _kPink.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _kPink.withOpacity(0.25)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TOTAL POINTS',
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_score',
                          style: GoogleFonts.outfit(color: _kPink, fontSize: 60, fontWeight: FontWeight.w900, height: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'pts',
                          style: GoogleFonts.outfit(color: _kPink.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildFinalBadge(),
                  const SizedBox(height: 36),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPink, _kPinkDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Back to Games',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
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

  Widget _buildFinalBadge() {
    String label = '🥉 Flag Rookie';
    Color badgeColor = Colors.white54;
    if (_score >= 20) {
      label = '🏆 Flag Legend';
      badgeColor = _kPink;
    } else if (_score >= 15) {
      label = '🥇 Flag Master';
      badgeColor = Colors.amber;
    } else if (_score >= 10) {
      label = '🥈 Flag Specialist';
      badgeColor = Colors.blueAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(color: badgeColor, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

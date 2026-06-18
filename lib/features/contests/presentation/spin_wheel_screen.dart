import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_scheme.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Prize segments ────────────────────────────────────────────────────────────
class _Prize {
  final String id;
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _Prize({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

const List<_Prize> _prizes = [
  _Prize(id: '+25pts',    label: '+25',       subtitle: 'Points',      color: Color(0xFF8B80FF), icon: Icons.stars),
  _Prize(id: 'lifeline',  label: 'Lifeline',  subtitle: 'Power-Up',   color: Color(0xFF43DF9E), icon: Icons.auto_awesome),
  _Prize(id: '+10pts',    label: '+10',       subtitle: 'Points',      color: Color(0xFF38BDF8), icon: Icons.add_circle),
  _Prize(id: 'try_again', label: 'Try',       subtitle: 'Again',       color: Color(0xFF475569), icon: Icons.refresh),
  _Prize(id: '+50pts',    label: '+50',       subtitle: 'Points',      color: Color(0xFFFFD700), icon: Icons.emoji_events),
  _Prize(id: 'extra_spin',label: 'Extra',     subtitle: 'Spin',        color: Color(0xFFEC4899), icon: Icons.rotate_right),
  _Prize(id: '+5pts',     label: '+5',        subtitle: 'Points',      color: Color(0xFF94A3B8), icon: Icons.add),
  _Prize(id: 'card_pack', label: 'Card',      subtitle: 'Pack',        color: Color(0xFFFFB955), icon: Icons.style),
];

// ─── Wheel painter ─────────────────────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final double rotationAngle;
  const _WheelPainter(this.rotationAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / _prizes.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    for (int i = 0; i < _prizes.length; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      final prize = _prizes[i];

      // Segment fill
      final paint = Paint()..color = prize.color.withAlpha(220);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Segment border
      final borderPaint = Paint()
        ..color = Colors.black.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Label
      final midAngle = startAngle + segmentAngle / 2;
      final labelRadius = radius * 0.65;
      final labelX = labelRadius * math.cos(midAngle);
      final labelY = labelRadius * math.sin(midAngle);

      canvas.save();
      canvas.translate(labelX, labelY);
      canvas.rotate(midAngle + math.pi / 2);

      final tp = TextPainter(
        text: TextSpan(
          text: prize.label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              const Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      final subTp = TextPainter(
        text: TextSpan(
          text: prize.subtitle,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      subTp.paint(canvas, Offset(-subTp.width / 2, tp.height / 2 - 2));

      canvas.restore();
    }

    // Center cap
    final capPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF8B80FF), Color(0xFF4C1D95)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius * 0.12));
    canvas.drawCircle(Offset.zero, radius * 0.12, capPaint);
    canvas.drawCircle(Offset.zero, radius * 0.12,
        Paint()..color = Colors.white.withAlpha(40)..style = PaintingStyle.stroke..strokeWidth = 2);

    canvas.restore();

    // Outer ring
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8B80FF), Color(0xFF43DF9E), Color(0xFFFFD700), Color(0xFF8B80FF)],
        stops: [0, 0.33, 0.66, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, ringPaint);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.rotationAngle != rotationAngle;
}

// ─── Screen ────────────────────────────────────────────────────────────────────
class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  bool _isSpinning = false;
  int? _landedIndex;
  bool _showResult = false;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutExpo,
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  // Returns remaining seconds until next free spin, 0 if available
  int _secondsUntilNextSpin(User? user) {
    if (user?.lastSpinAt == null) return 0;
    final elapsed = DateTime.now().difference(user!.lastSpinAt!).inSeconds;
    final remaining = (24 * 3600) - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  String _formatCountdown(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _spin({bool useExtraTicket = false}) async {
    if (_isSpinning) return;
    final user = ref.read(authProvider).value;
    if (user == null) return;

    // Check eligibility
    final secondsLeft = _secondsUntilNextSpin(user);
    if (!useExtraTicket && secondsLeft > 0) {
      _showCooldownSnack(secondsLeft);
      return;
    }
    if (useExtraTicket && user.extraTickets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No extra spins available!')),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _landedIndex = null;
    });

    // Pick random prize (weighted: +5pts and try_again more likely)
    final rng = math.Random();
    final weights = [20, 10, 20, 15, 5, 8, 25, 7]; // corresponds to _prizes
    int total = weights.fold(0, (a, b) => a + b);
    int roll = rng.nextInt(total);
    int picked = 0;
    for (int i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll < 0) { picked = i; break; }
    }

    // Calculate final angle
    final segmentAngle = (2 * math.pi) / _prizes.length;
    // Spin at least 5 full rotations + land on the chosen segment
    final extraSpins = 5 + rng.nextInt(3); // 5–7 full rotations
    final targetAngle = extraSpins * 2 * math.pi +
        ((_prizes.length - picked) * segmentAngle) - segmentAngle / 2;

    _spinAnimation = Tween<double>(
      begin: 0,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.easeOutExpo));

    _spinController.reset();
    await _spinController.forward();

    // Apply prize
    final prize = _prizes[picked];
    await ref.read(authProvider.notifier)
        .awardSpinPrize(prize.id, useExtraTicket: useExtraTicket);

    if (!mounted) return;

    String msg;
    switch (prize.id) {
      case '+5pts':   msg = 'You won +5 Points! 🎉'; break;
      case '+10pts':  msg = 'You won +10 Points! 🎉'; break;
      case '+25pts':  msg = 'You won +25 Points! 🌟'; break;
      case '+50pts':  msg = 'Jackpot! +50 Points! 🏆'; break;
      case 'lifeline': msg = 'You won a Lifeline! 🔮'; break;
      case 'extra_spin': msg = 'You won an Extra Spin! 🎡'; break;
      case 'card_pack': msg = 'You won a Card Pack! 🃏'; break;
      default:        msg = 'Better luck next time! Try Again 🔄'; break;
    }

    setState(() {
      _isSpinning = false;
      _landedIndex = picked;
      _showResult = true;
      _resultMessage = msg;
    });
  }

  void _showCooldownSnack(int secondsLeft) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1B2E),
        content: Row(children: [
          const Icon(Icons.timer, color: Color(0xFF8B80FF)),
          const SizedBox(width: 12),
          Text('Next free spin in ${_formatCountdown(secondsLeft)}',
              style: const TextStyle(color: Colors.white)),
        ]),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    final user = userAsync.value;
    final secondsLeft = _secondsUntilNextSpin(user);
    final canFreeSpin = secondsLeft == 0;
    final hasExtraTicket = (user?.extraTickets ?? 0) > 0;

    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1A0833), Color(0xFF0A0A0F)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(context),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildWheel(),
                        const SizedBox(height: 24),
                        if (_showResult && _landedIndex != null)
                          _buildResult(_prizes[_landedIndex!]),
                        const SizedBox(height: 20),
                        _buildSpinButtons(canFreeSpin, hasExtraTicket, secondsLeft),
                        const SizedBox(height: 20),
                        _buildPrizeList(),
                        const SizedBox(height: 32),
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
          Text('Daily Spin Wheel',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const Spacer(),
          // Ticket counter
          Consumer(builder: (context, ref, _) {
            final tickets = ref.watch(authProvider).value?.extraTickets ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text('$tickets Extra', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF8B80FF), Color(0xFFFFD700)],
          ).createShader(bounds),
          child: Text('🎡 Spin to Win!',
              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        const SizedBox(height: 6),
        Text('One free spin every 24 hours',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
      ],
    );
  }

  Widget _buildWheel() {
    return AnimatedBuilder(
      animation: _spinAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow behind wheel
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B80FF).withAlpha(60),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),

            SizedBox(
              width: 290,
              height: 290,
              child: CustomPaint(
                painter: _WheelPainter(_spinAnimation.value),
              ),
            ),

            // Pointer / arrow at top
            Positioned(
              top: -2,
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: const Icon(Icons.arrow_downward, color: Colors.black, size: 18),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResult(_Prize prize) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(
        scale: v,
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              prize.color.withAlpha(50),
              prize.color.withAlpha(20),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: prize.color.withAlpha(120), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(prize.icon, color: prize.color, size: 40),
            const SizedBox(height: 8),
            Text(_resultMessage ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinButtons(bool canFreeSpin, bool hasExtraTicket, int secondsLeft) {
    return Column(
      children: [
        // Free spin button
        GestureDetector(
          onTap: canFreeSpin && !_isSpinning ? () => _spin() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: canFreeSpin && !_isSpinning
                  ? const LinearGradient(
                      colors: [Color(0xFF8B80FF), Color(0xFF4C1D95)],
                    )
                  : null,
              color: canFreeSpin && !_isSpinning ? null : Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: canFreeSpin ? const Color(0xFF8B80FF) : Colors.white.withAlpha(20),
              ),
              boxShadow: canFreeSpin && !_isSpinning
                  ? [BoxShadow(color: const Color(0xFF8B80FF).withAlpha(80), blurRadius: 20)]
                  : null,
            ),
            child: Center(
              child: _isSpinning
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      const SizedBox(width: 12),
                      Text('Spinning...', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ])
                  : canFreeSpin
                      ? Text('🎡 Spin Now — FREE!',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))
                      : _buildCountdownText(secondsLeft),
            ),
          ),
        ),

        if (hasExtraTicket) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: !_isSpinning ? () => _spin(useExtraTicket: true) : null,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text('🎟 Use Extra Ticket',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCountdownText(int seconds) {
    return _CountdownWidget(seconds: seconds);
  }

  Widget _buildPrizeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Possible Prizes',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _prizes.map((p) => _PrizeChip(prize: p)).toList(),
        ),
      ],
    );
  }
}

// Countdown rebuilds every second via a StatefulWidget
class _CountdownWidget extends StatefulWidget {
  final int seconds;
  const _CountdownWidget({required this.seconds});

  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget> {
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_remaining > 0) {
        setState(() => _remaining--);
        _tick();
      }
    });
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.timer_outlined, color: Colors.white54, size: 18),
      const SizedBox(width: 8),
      Text(
        'Next spin in ${_fmt(_remaining)}',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white54),
      ),
    ]);
  }
}

class _PrizeChip extends StatelessWidget {
  final _Prize prize;
  const _PrizeChip({required this.prize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: prize.color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: prize.color.withAlpha(80)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(prize.icon, color: prize.color, size: 14),
        const SizedBox(width: 6),
        Text('${prize.label} ${prize.subtitle}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }
}

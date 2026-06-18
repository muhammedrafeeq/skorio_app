import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

// ─── Data model passed from predict screen ─────────────────────────────────────
class PredictionShareData {
  final String homeTeam;
  final String awayTeam;
  final String homeFlag;   // emoji flag (e.g. '🇧🇷')
  final String awayFlag;
  final int homeScore;
  final int awayScore;
  final String? firstScorer;
  final String? winner;    // 'home', 'draw', 'away' or null
  final String matchDate;
  final String userName;
  final bool isCricket;
  final String? tossWinner;
  final String? topBatsman;
  final String? topBowler;
  final String? scoreRange;

  const PredictionShareData({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeFlag,
    required this.awayFlag,
    this.homeScore = 0,
    this.awayScore = 0,
    this.firstScorer,
    this.winner,
    required this.matchDate,
    required this.userName,
    this.isCricket = false,
    this.tossWinner,
    this.topBatsman,
    this.topBowler,
    this.scoreRange,
  });

  String get winnerLabel {
    if (winner == 'home') return homeTeam;
    if (winner == 'away') return awayTeam;
    if (winner == 'draw') return 'Draw';
    return '?';
  }

  String buildShareText() {
    final sb = StringBuffer();
    if (isCricket) {
      sb.writeln('🏏 My Cricket Prediction on Skorio');
      sb.writeln('');
      sb.writeln('$homeFlag $homeTeam vs $awayTeam $awayFlag');
      if (tossWinner != null) sb.writeln('🪙 Toss Winner: $tossWinner');
      if (winner != null) sb.writeln('🏆 Match Winner: $winnerLabel');
      if (topBatsman != null) sb.writeln('🏏 Top Batsman: $topBatsman');
      if (topBowler != null) sb.writeln('🎯 Top Bowler: $topBowler');
      if (scoreRange != null) sb.writeln('📊 Score Range: $scoreRange');
    } else {
      sb.writeln('⚽ My Prediction on Skorio');
      sb.writeln('');
      sb.writeln('$homeFlag $homeTeam  $homeScore – $awayScore  $awayTeam $awayFlag');
      if (winner != null) sb.writeln('🏆 Winner: $winnerLabel');
      if (firstScorer != null) sb.writeln('🥅 First Scorer: $firstScorer');
    }
    sb.writeln('');
    sb.writeln('📅 Match: $matchDate');
    sb.writeln('');
    sb.writeln('👤 $userName  •  skorio.app');
    sb.writeln('');
    sb.writeln('Can you beat my prediction? Download Skorio! 🔥');
    return sb.toString().trim();
  }
}

// ─── Entry point ───────────────────────────────────────────────────────────────
Future<void> showShareCardSheet(BuildContext context, PredictionShareData data) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareCardSheet(data: data),
  );
}

// ─── Bottom sheet ──────────────────────────────────────────────────────────────
class _ShareCardSheet extends StatefulWidget {
  final PredictionShareData data;
  const _ShareCardSheet({required this.data});

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _shareText() async {
    final text = widget.data.buildShareText();
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: widget.data.isCricket ? 'My Skorio Cricket Prediction 🏏' : 'My Skorio Prediction ⚽',
      ),
    );
  }

  Future<void> _copyText() async {
    final text = widget.data.buildShareText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _entryAnim,
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text('Share Your Prediction',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            Text('Let your friends know what you predicted!',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
            const SizedBox(height: 24),

            // Preview card
            RepaintBoundary(
              child: _PredictionCard(data: widget.data),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Share',
                    icon: Icons.share_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43DF9E), Color(0xFF00C082)],
                    ),
                    onTap: _shareText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: _copied ? 'Copied!' : 'Copy Text',
                    icon: _copied ? Icons.check_circle : Icons.copy_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B80FF), Color(0xFF4C1D95)],
                    ),
                    onTap: _copyText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // WhatsApp / Telegram shortcuts
            Row(
              children: [
                Expanded(
                  child: _AppShareButton(
                    label: 'WhatsApp',
                    emoji: '💬',
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      // share_plus handles native share; WA is one of the options
                      await _shareText();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AppShareButton(
                    label: 'Telegram',
                    emoji: '✈️',
                    color: const Color(0xFF0088CC),
                    onTap: _shareText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AppShareButton(
                    label: 'Close',
                    emoji: '✖️',
                    color: const Color(0xFF374151),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── The card itself ──────────────────────────────────────────────────────────
class _PredictionCard extends StatelessWidget {
  final PredictionShareData data;
  const _PredictionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isCricket) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF022C22), Color(0xFF0F172A), Color(0xFF1E293B)],
            stops: [0, 0.5, 1],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyanAccent.withAlpha(60),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withAlpha(30),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.cyanAccent, Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('SKORIO',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black,
                          letterSpacing: 1.5)),
                ),
                const SizedBox(width: 10),
                Text('Cricket Prediction',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                const Spacer(),
                Text(data.matchDate,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 20),

            // Teams row
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data.homeFlag, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 8),
                  Text(
                    '${data.homeTeam}  vs  ${data.awayTeam}',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(data.awayFlag, style: const TextStyle(fontSize: 32)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Container(height: 1, color: Colors.white.withAlpha(15)),
            const SizedBox(height: 16),

            // Grid of Cricket predictions
            Column(
              children: [
                Row(
                  children: [
                    if (data.tossWinner != null)
                      _InfoChip(
                        icon: Icons.monetization_on_outlined,
                        label: 'Toss Winner',
                        value: data.tossWinner!,
                        color: Colors.amber,
                      ),
                    const SizedBox(width: 10),
                    if (data.winner != null)
                      _InfoChip(
                        icon: Icons.emoji_events_rounded,
                        label: 'Match Winner',
                        value: data.winnerLabel,
                        color: Colors.cyanAccent,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (data.topBatsman != null)
                      _InfoChip(
                        icon: Icons.sports_cricket,
                        label: 'Top Batsman',
                        value: data.topBatsman!.split(' ').last,
                        color: const Color(0xFF34D399),
                      ),
                    const SizedBox(width: 10),
                    if (data.topBowler != null)
                      _InfoChip(
                        icon: Icons.adjust_rounded,
                        label: 'Top Bowler',
                        value: data.topBowler!.split(' ').last,
                        color: const Color(0xFFF87171),
                      ),
                  ],
                ),
                if (data.scoreRange != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.bar_chart_rounded,
                        label: '1st Inn Score Range',
                        value: data.scoreRange!,
                        color: const Color(0xFFA78BFA),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Footer
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('👤 ${data.userName}',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
                ),
                const Spacer(),
                Text('skorio.app',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.cyanAccent,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2B1A), Color(0xFF1A1A3E), Color(0xFF0D1B3E)],
          stops: [0, 0.5, 1],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF43DF9E).withAlpha(60),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43DF9E).withAlpha(30),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43DF9E), Color(0xFF00C082)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('SKORIO',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black,
                        letterSpacing: 1.5)),
              ),
              const SizedBox(width: 10),
              Text('My Prediction',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
              const Spacer(),
              Text(data.matchDate,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 20),

          // Teams + score
          Row(
            children: [
              // Home team
              Expanded(
                child: Column(
                  children: [
                    Text(data.homeFlag, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 6),
                    Text(data.homeTeam,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),

              // Score display
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(80),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Row(
                      children: [
                        Text('${data.homeScore}',
                            style: GoogleFonts.inter(
                                fontSize: 32, fontWeight: FontWeight.w900,
                                color: const Color(0xFF43DF9E))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('–',
                              style: GoogleFonts.inter(
                                  fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white54)),
                        ),
                        Text('${data.awayScore}',
                            style: GoogleFonts.inter(
                                fontSize: 32, fontWeight: FontWeight.w900,
                                color: const Color(0xFF8B80FF))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('FINAL SCORE PICK',
                      style: GoogleFonts.inter(
                          fontSize: 9, letterSpacing: 1.2, color: Colors.white38)),
                ],
              ),

              // Away team
              Expanded(
                child: Column(
                  children: [
                    Text(data.awayFlag, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 6),
                    Text(data.awayTeam,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Divider
          Container(height: 1, color: Colors.white.withAlpha(15)),
          const SizedBox(height: 16),

          // Extra picks row
          Row(
            children: [
              if (data.winner != null)
                _InfoChip(
                  icon: Icons.emoji_events_rounded,
                  label: 'Winner',
                  value: data.winnerLabel,
                  color: const Color(0xFFFFD700),
                ),
              if (data.winner != null && data.firstScorer != null)
                const SizedBox(width: 10),
              if (data.firstScorer != null)
                _InfoChip(
                  icon: Icons.sports_soccer,
                  label: '1st Scorer',
                  value: data.firstScorer!.split(' ').last, // last name only
                  color: const Color(0xFF43DF9E),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Footer
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('👤 ${data.userName}',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
              ),
              const Spacer(),
              Text('skorio.app',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF43DF9E),
                      fontWeight: FontWeight.w600)),
            ],
          ),

          // Decorative dots (bottom right)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _DecorativeDots(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Text(label,
                    style: GoogleFonts.inter(fontSize: 9, color: color.withAlpha(180))),
              ],
            ),
            const SizedBox(height: 2),
            Text(value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _DecorativeDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 16),
      painter: _DotsPainter(),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF43DF9E).withAlpha(60);
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(i * 10.0, size.height / 2),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => false;
}

// ─── Action button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ─── App shortcut button ───────────────────────────────────────────────────────
class _AppShareButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  const _AppShareButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

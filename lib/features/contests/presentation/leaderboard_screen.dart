import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

// ─── Mock data ────────────────────────────────────────────────────────────────

class _LeaderEntry {
  final String name;
  final String initials;
  final int points;
  final int games;
  final bool isCurrentUser;
  const _LeaderEntry({
    required this.name,
    required this.initials,
    required this.points,
    required this.games,
    this.isCurrentUser = false,
  });
}

const _kPurple = Color(0xFF7C3AED);
const _kPurpleLight = Color(0xFFA78BFA);
const _kGold = Color(0xFFF59E0B);
const _kGoldLight = Color(0xFFFBBF24);
const _kBg = Color(0xFF07070F);

const _filters = ['All Games', 'Penalty', 'Trivia', 'Who Am I', 'First Goal', 'Formation', 'Bracket'];

final _allData = <_LeaderEntry>[
  _LeaderEntry(name: 'Rafeeq', initials: 'RA', points: 41, games: 4, isCurrentUser: true),
  _LeaderEntry(name: 'Arjun', initials: 'AR', points: 38, games: 5),
  _LeaderEntry(name: 'Carlos', initials: 'CA', points: 35, games: 4),
  _LeaderEntry(name: 'Meera', initials: 'ME', points: 30, games: 3),
  _LeaderEntry(name: 'Diego', initials: 'DI', points: 27, games: 4),
  _LeaderEntry(name: 'Fatima', initials: 'FA', points: 24, games: 3),
  _LeaderEntry(name: 'Luca', initials: 'LU', points: 18, games: 2),
  _LeaderEntry(name: 'Sofia', initials: 'SO', points: 12, games: 2),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  int _activeFilter = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectFilter(int i) {
    setState(() => _activeFilter = i);
    _fadeCtrl.forward(from: 0.4);
  }

  List<_LeaderEntry> get _entries => _allData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        _buildBlobs(),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [
              _buildHeader(context),
              _buildTitleSection(),
              _buildFilterChips(),
              const SizedBox(height: 8),
              _buildPodiumSection(),
              const SizedBox(height: 8),
              _buildTableHeader(),
              Expanded(child: _buildList()),
            ]),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildBottomNav(context),
        ),
      ]),
    );
  }

  // ── ambient blobs ──
  Widget _buildBlobs() {
    return Stack(children: [
      Positioned(
        top: -100, left: -80,
        child: Container(
          width: 300, height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kPurple.withValues(alpha: 0.07),
          ),
        ),
      ),
      Positioned(
        top: 200, right: -100,
        child: Container(
          width: 240, height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kGold.withValues(alpha: 0.05),
          ),
        ),
      ),
    ]);
  }

  // ── header ──
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.sports_esports_rounded, color: _kPurpleLight, size: 20),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'GAMES ',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              TextSpan(
                text: 'BOARD',
                style: GoogleFonts.outfit(color: _kPurpleLight, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: _kPurple),
          child: Center(
            child: Text('R', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  // ── hero section ──
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(children: [
        Text('GAMES ARENA', style: GoogleFonts.outfit(color: _kPurpleLight, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 6),
        Text('Games Leaderboard', style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
          'Points earned across all mini-games. Separate\nfrom match predictions.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
      ]),
    );
  }

  Widget _buildPodiumSection() {
    final top = _entries.first;
    return _buildPodiumCard(top);
  }

  Widget _buildPodiumCard(_LeaderEntry e) {
    return Column(children: [
      // crown
      const Icon(Icons.emoji_events_rounded, color: _kGold, size: 32),
      const SizedBox(height: 8),
      // avatar circle
      Stack(alignment: Alignment.bottomRight, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF5A2D00), Color(0xFF2A1500)],
            ),
            border: Border.all(color: _kGold, width: 2.5),
          ),
          child: Center(
            child: Text(e.initials, style: GoogleFonts.outfit(color: _kGold, fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ),
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kGold,
            border: Border.all(color: _kBg, width: 2),
          ),
          child: Center(
            child: Text('1', style: GoogleFonts.outfit(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      // card
      Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D1E00), Color(0xFF1A0D00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGold.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Column(children: [
          Text(
            e.name + (e.isCurrentUser ? '' : ''),
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${e.points}',
            style: GoogleFonts.outfit(color: _kGoldLight, fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGold.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${e.games} GAMES',
              style: GoogleFonts.outfit(color: _kGold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── filter chips ──
  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (ctx, i) {
          final active = i == _activeFilter;
          return GestureDetector(
            onTap: () => _selectFilter(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _kPurple : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? _kPurple : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                _filters[i],
                style: GoogleFonts.outfit(
                  color: active ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── table header ──
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        SizedBox(
          width: 48,
          child: Text('POS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ),
        Expanded(
          child: Text('PLAYER', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ),
        Text('POINTS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      ]),
    );
  }

  // ── list ──
  Widget _buildList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 80 + MediaQuery.of(context).padding.bottom),
      itemCount: _entries.length,
      itemBuilder: (ctx, i) => _buildRow(_entries[i], i + 1),
    );
  }

  Widget _buildRow(_LeaderEntry e, int pos) {
    final isMe = e.isCurrentUser;
    final isTop3 = pos <= 3;
    final posColor = pos == 1 ? _kGold : pos == 2 ? const Color(0xFFD1D5DB) : pos == 3 ? const Color(0xFFCD7F32) : Colors.white38;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? _kPurple.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? _kPurple.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(children: [
        // position / trophy
        SizedBox(
          width: 36,
          child: isMe && pos == 1
              ? const Icon(Icons.emoji_events_rounded, color: _kGold, size: 22)
              : Text(
                  '$pos',
                  style: GoogleFonts.outfit(color: posColor, fontSize: 15, fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w600),
                ),
        ),
        // avatar
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMe ? _kPurple.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: isMe ? _kPurpleLight.withValues(alpha: 0.5) : Colors.transparent),
          ),
          child: Center(
            child: Text(e.initials, style: GoogleFonts.outfit(color: isMe ? _kPurpleLight : Colors.white70, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 12),
        // name + games
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                e.name,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              if (e.isCurrentUser) ...[
                const SizedBox(width: 6),
                Text('(You)', style: GoogleFonts.outfit(color: _kPurpleLight, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ]),
            Text(
              '${e.games} GAMES',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
          ]),
        ),
        // points
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${e.points}',
                style: GoogleFonts.outfit(color: isMe ? _kPurpleLight : Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: ' pts',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── bottom nav ──
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: const Color(0xFF05050A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.grid_view_rounded, label: 'My Contests', isActive: false, onTap: () => context.go('/')),
          _NavItem(icon: Icons.sports_esports_outlined, label: 'Games', isActive: true, onTap: () => context.pop()),
          _NavItem(icon: Icons.history_rounded, label: 'History', isActive: false, onTap: () {}),
        ],
      ),
    );
  }
}

// ─── Bottom nav item ──────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _kPurpleLight : Colors.white38;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 90,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }
}

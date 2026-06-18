import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/pitch_background.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

const Map<String, List<String>> _groups = {
  'A': ['USA', 'Canada', 'Mexico', 'Jamaica'],
  'B': ['Argentina', 'Chile', 'Peru', 'Bolivia'],
  'C': ['Brazil', 'Colombia', 'Ecuador', 'Venezuela'],
  'D': ['Uruguay', 'Paraguay', 'Panama', 'Costa Rica'],
  'E': ['England', 'Germany', 'Netherlands', 'Belgium'],
  'F': ['France', 'Spain', 'Portugal', 'Italy'],
  'G': ['Switzerland', 'Denmark', 'Sweden', 'Norway'],
  'H': ['Croatia', 'Poland', 'Czech Republic', 'Austria'],
  'I': ['Morocco', 'Senegal', 'Egypt', 'Nigeria'],
  'J': ['Cameroon', 'Tunisia', 'Ghana', 'Ivory Coast'],
  'K': ['Japan', 'South Korea', 'Australia', 'Iran'],
  'L': ['Saudi Arabia', 'Qatar', 'UAE', 'Bahrain'],
};

const Map<String, Color> _groupColors = {
  'A': Color(0xFF22D3EE),
  'B': Color(0xFF60A5FA),
  'C': Color(0xFF4ADE80),
  'D': Color(0xFFFACC15),
  'E': Color(0xFFFB7185),
  'F': Color(0xFFC084FC),
  'G': Color(0xFFFB923C),
  'H': Color(0xFFF472B6),
  'I': Color(0xFF2DD4BF),
  'J': Color(0xFFA3E635),
  'K': Color(0xFFA78BFA),
  'L': Color(0xFFFBBF24),
};

const Color _amber = Color(0xFFFACC15);
const Color _amberDark = Color(0xFFD97706);

// ─── R16 seeding ──────────────────────────────────────────────────────────────

List<Map<String, String>> _buildR16Slots(Map<String, Map<String, String>> groups) {
  String get(String letter, String slot) => groups[letter]?[slot] ?? '';
  return [
    {'home': get('A', 'first'),  'away': get('B', 'second')},
    {'home': get('B', 'first'),  'away': get('A', 'second')},
    {'home': get('C', 'first'),  'away': get('D', 'second')},
    {'home': get('D', 'first'),  'away': get('C', 'second')},
    {'home': get('E', 'first'),  'away': get('F', 'second')},
    {'home': get('F', 'first'),  'away': get('E', 'second')},
    {'home': get('G', 'first'),  'away': get('H', 'second')},
    {'home': get('H', 'first'),  'away': get('G', 'second')},
    {'home': get('I', 'first'),  'away': get('J', 'second')},
    {'home': get('J', 'first'),  'away': get('I', 'second')},
    {'home': get('K', 'first'),  'away': get('L', 'second')},
    {'home': get('L', 'first'),  'away': get('K', 'second')},
    {'home': 'Best 3rd (A-D)',   'away': 'Best 3rd (E-H)'},
    {'home': 'Best 3rd (I-L)',   'away': 'Best 3rd (A-D)'},
    {'home': 'Best 3rd (E-H)',   'away': 'Best 3rd (I-L)'},
    {'home': 'Best 3rd (A-L)',   'away': 'Best 3rd (A-L)'},
  ];
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BracketScreen extends ConsumerStatefulWidget {
  const BracketScreen({super.key});

  @override
  ConsumerState<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends ConsumerState<BracketScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0; // 0=groups, 1=knockout, 2=submit
  bool _submitted = false;
  bool _showConfirm = false;

  // Group picks: letter → {first, second}
  final Map<String, Map<String, String>> _groupPicks = {};

  // Knockout picks
  List<String> _r16 = List.filled(16, '');
  List<String> _qf  = List.filled(8, '');
  List<String> _sf  = List.filled(4, '');
  List<String> _fin = List.filled(2, '');
  String _champion = '';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Computed ──────────────────────────────────────────────────────────────

  bool get _groupsComplete =>
      _groups.keys.every((l) => (_groupPicks[l]?['first'] ?? '').isNotEmpty && (_groupPicks[l]?['second'] ?? '').isNotEmpty);

  int get _groupsDone =>
      _groups.keys.where((l) => (_groupPicks[l]?['first'] ?? '').isNotEmpty && (_groupPicks[l]?['second'] ?? '').isNotEmpty).length;

  List<Map<String, String>> get _r16Slots => _buildR16Slots(_groupPicks);

  List<Map<String, String>> get _qfSlots => List.generate(8, (i) => {
    'home': _r16[i * 2],
    'away': _r16[i * 2 + 1],
  });

  List<Map<String, String>> get _sfSlots => List.generate(4, (i) => {
    'home': _qf[i * 2],
    'away': _qf[i * 2 + 1],
  });

  List<Map<String, String>> get _finalSlots => [
    {'home': _sf[0], 'away': _sf[1]},
    {'home': _sf[2], 'away': _sf[3]},
  ];

  bool get _knockoutComplete =>
      _r16.every((t) => t.isNotEmpty) &&
      _qf.every((t) => t.isNotEmpty) &&
      _sf.every((t) => t.isNotEmpty) &&
      _fin.every((t) => t.isNotEmpty) &&
      _champion.isNotEmpty;

  bool get _bracketComplete => _groupsComplete && _knockoutComplete;

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _handleGroupPick(String letter, String team) {
    setState(() {
      final g = Map<String, String>.from(_groupPicks[letter] ?? {'first': '', 'second': ''});
      if (g['first'] == team) {
        g['first'] = '';
      } else if (g['second'] == team) {
        g['second'] = '';
      } else if ((g['first'] ?? '').isEmpty) {
        g['first'] = team;
      } else if ((g['second'] ?? '').isEmpty) {
        g['second'] = team;
      } else {
        g['second'] = team;
      }
      _groupPicks[letter] = g;
      // Invalidate knockout
      _r16 = List.filled(16, '');
      _qf  = List.filled(8, '');
      _sf  = List.filled(4, '');
      _fin = List.filled(2, '');
      _champion = '';
    });
  }

  void _pickR16(int idx, String team) => setState(() {
    _r16 = List.from(_r16)..[idx] = team;
    _qf  = List.filled(8, '');
    _sf  = List.filled(4, '');
    _fin = List.filled(2, '');
    _champion = '';
  });

  void _pickQf(int idx, String team) => setState(() {
    _qf = List.from(_qf)..[idx] = team;
    _sf  = List.filled(4, '');
    _fin = List.filled(2, '');
    _champion = '';
  });

  void _pickSf(int idx, String team) => setState(() {
    _sf = List.from(_sf)..[idx] = team;
    _fin = List.filled(2, '');
    _champion = '';
  });

  void _pickFin(int idx, String team) => setState(() {
    _fin = List.from(_fin)..[idx] = team;
    _champion = '';
  });

  void _submitBracket() {
    final pts = 50; // mock points
    ref.read(authProvider.notifier).addPoints(pts);
    setState(() {
      _submitted = true;
      _showConfirm = false;
    });
  }

  void _switchTab(int tab) {
    setState(() => _tab = tab);
    _fadeCtrl.forward(from: 0);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050A),
      body: Stack(
        children: [
          const PitchBackground(child: SizedBox.expand()),
          Positioned(top: 80, right: -80, child: _blob(_amber, 240)),
          Positioned(bottom: 100, left: -80, child: _blob(const Color(0xFF6366F1), 200)),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _submitted ? _buildSubmittedView() : _buildTabContent(),
                  ),
                ),
              ],
            ),
          ),
          if (_showConfirm) _buildConfirmDialog(),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.04)),
    child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: color.withOpacity(0.04))),
  );

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF05050A).withOpacity(0.9),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/games'),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white38, size: 18),
          ),
          const Spacer(),
          Text('WC 2026 Bracket',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
          const Spacer(),
          if (_bracketComplete && !_submitted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _amber.withOpacity(0.25)),
              ),
              child: Text('READY', style: GoogleFonts.outfit(color: _amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            )
          else
            const SizedBox(width: 50),
        ],
      ),
    );
  }

  // ─── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final tabs = [
      ('GROUPS', _groupsComplete),
      ('KNOCKOUT', _knockoutComplete),
      ('SUBMIT', false),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF05050A).withOpacity(0.9),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value.$1;
          final done = e.value.$2;
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? _amber : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (done) Container(
                      width: 5, height: 5,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: active ? _amber : Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 0: return _buildGroupsTab();
      case 1: return _buildKnockoutTab();
      case 2: return _buildSubmitTab();
      default: return const SizedBox();
    }
  }

  // ─── Groups tab ────────────────────────────────────────────────────────────

  Widget _buildGroupsTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Group Stage Picks', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  'For each group, tap the 1st-place finisher first, then tap a different team for 2nd place. Tap again to deselect.',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 12,
              mainAxisExtent: 240,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final letter = _groups.keys.elementAt(i);
                return _buildGroupCard(letter);
              },
              childCount: _groups.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverToBoxAdapter(child: _buildGroupProgress()),
        ),
      ],
    );
  }

  Widget _buildGroupCard(String letter) {
    final color = _groupColors[letter]!;
    final teams = _groups[letter]!;
    final picks = _groupPicks[letter] ?? {'first': '', 'second': ''};
    final first = picks['first'] ?? '';
    final second = picks['second'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(letter, style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 8),
              Text('Group $letter', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              const Spacer(),
              if (first.isNotEmpty)
                Text('1st: $first', style: GoogleFonts.outfit(color: _amber, fontSize: 9, fontWeight: FontWeight.w900)),
              if (first.isNotEmpty && second.isNotEmpty)
                const SizedBox(width: 6),
              if (second.isNotEmpty)
                Text('2nd: $second', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          // Teams
          ...teams.map((team) {
            final slot = first == team ? 'first' : second == team ? 'second' : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _buildTeamPill(team, slot, () => _handleGroupPick(letter, team)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeamPill(String team, String? slot, VoidCallback onTap) {
    Color bg, border, textColor;
    if (slot == 'first') {
      bg = _amber.withOpacity(0.15);
      border = _amber.withOpacity(0.5);
      textColor = const Color(0xFFFDE047);
    } else if (slot == 'second') {
      bg = Colors.white.withOpacity(0.12);
      border = Colors.white.withOpacity(0.25);
      textColor = Colors.white;
    } else {
      bg = Colors.white.withOpacity(0.04);
      border = Colors.white.withOpacity(0.08);
      textColor = Colors.white.withOpacity(0.65);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(team, style: GoogleFonts.outfit(color: textColor, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            if (slot == 'first')
              Text('1ST', style: GoogleFonts.outfit(color: _amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
            if (slot == 'second')
              Text('2ND', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupProgress() {
    final pct = _groupsDone / _groups.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Groups completed', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$_groupsDone / ${_groups.length}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 6,
              color: Colors.white.withOpacity(0.08),
              child: LayoutBuilder(builder: (ctx, cns) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: cns.maxWidth * pct,
                  color: _amber,
                );
              }),
            ),
          ),
          if (_groupsComplete) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _switchTab(1),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _amber.withOpacity(0.3)),
                  backgroundColor: _amber.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text('Continue to Knockout →', style: GoogleFonts.outfit(color: _amber, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Knockout tab ──────────────────────────────────────────────────────────

  Widget _buildKnockoutTab() {
    final r16slots = _r16Slots;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Knockout Stage', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Click a team in each match to advance them. Your group picks seed the bracket.',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, height: 1.5)),
          const SizedBox(height: 14),

          if (!_groupsComplete)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _amber.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _amber.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Complete all group stage picks first.',
                      style: GoogleFonts.outfit(color: _amber, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: () => _switchTab(0),
                    child: Text('Go →', style: GoogleFonts.outfit(color: _amber, fontSize: 12, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),

          // Horizontal bracket scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // R16
                  _bracketColumn('R16', const Color(0xFF38BDF8), List.generate(16, (i) =>
                    _matchBox(
                      label: 'M${i + 1}',
                      home: r16slots[i]['home'] ?? '',
                      away: r16slots[i]['away'] ?? '',
                      winner: _r16[i],
                      onPick: _groupsComplete && !(r16slots[i]['home']!.startsWith('Best')) ? (t) => _pickR16(i, t) : null,
                    ),
                  )),
                  const SizedBox(width: 10),

                  // QF
                  _bracketColumn('QF', const Color(0xFF60A5FA), List.generate(8, (i) =>
                    _matchBox(
                      label: 'QF${i + 1}',
                      home: _qfSlots[i]['home'] ?? '',
                      away: _qfSlots[i]['away'] ?? '',
                      winner: _qf[i],
                      onPick: (_r16[i * 2].isNotEmpty && _r16[i * 2 + 1].isNotEmpty) ? (t) => _pickQf(i, t) : null,
                    ),
                  )),
                  const SizedBox(width: 10),

                  // SF
                  _bracketColumn('SF', const Color(0xFFA78BFA), List.generate(4, (i) =>
                    _matchBox(
                      label: 'SF${i + 1}',
                      home: _sfSlots[i]['home'] ?? '',
                      away: _sfSlots[i]['away'] ?? '',
                      winner: _sf[i],
                      onPick: (_qf[i * 2].isNotEmpty && _qf[i * 2 + 1].isNotEmpty) ? (t) => _pickSf(i, t) : null,
                    ),
                  )),
                  const SizedBox(width: 10),

                  // Final
                  _bracketColumn('FINAL', const Color(0xFFFBBF24), List.generate(2, (i) =>
                    _matchBox(
                      label: 'F${i + 1}',
                      home: _finalSlots[i]['home'] ?? '',
                      away: _finalSlots[i]['away'] ?? '',
                      winner: _fin[i],
                      onPick: (_sf[i * 2].isNotEmpty && _sf[i * 2 + 1].isNotEmpty) ? (t) => _pickFin(i, t) : null,
                    ),
                  )),
                  const SizedBox(width: 10),

                  // Champion
                  _buildChampionBox(),
                ],
              ),
            ),
          ),

          if (_knockoutComplete) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _switchTab(2),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _amber.withOpacity(0.3)),
                  backgroundColor: _amber.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Review & Submit →', style: GoogleFonts.outfit(color: _amber, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bracketColumn(String label, Color color, List<Widget> boxes) {
    return SizedBox(
      width: 118,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.outfit(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          ...boxes.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b)),
        ],
      ),
    );
  }

  Widget _matchBox({
    required String label,
    required String home,
    required String away,
    required String winner,
    void Function(String)? onPick,
  }) {
    final isPlaceholder = home.startsWith('Best') || away.startsWith('Best') || home.isEmpty || away.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: Colors.white.withOpacity(0.04),
            child: Text(label, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          _matchTeamRow(home.isEmpty ? 'TBD' : home, winner == home && !isPlaceholder, isPlaceholder, onPick),
          Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          _matchTeamRow(away.isEmpty ? 'TBD' : away, winner == away && !isPlaceholder, isPlaceholder, onPick),
        ],
      ),
    );
  }

  Widget _matchTeamRow(String team, bool isWinner, bool disabled, void Function(String)? onPick) {
    return GestureDetector(
      onTap: disabled || onPick == null ? null : () => onPick(team),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        color: isWinner ? _amber.withOpacity(0.18) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                team,
                style: GoogleFonts.outfit(
                  color: isWinner ? const Color(0xFFFDE047) : disabled ? Colors.white24 : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWinner) const Icon(Icons.chevron_right_rounded, color: Color(0xFFFDE047), size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildChampionBox() {
    final finalists = _fin.where((t) => t.isNotEmpty).toList();
    return SizedBox(
      width: 118,
      child: Column(
        children: [
          Text('CHAMPION', style: GoogleFonts.outfit(color: _amber.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _amber.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _amber.withOpacity(0.3)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: _amber.withOpacity(0.08),
                  child: Text('Winner', style: GoogleFonts.outfit(color: _amber.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                if (finalists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text('Pending…', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
                  )
                else
                  ...finalists.map((team) => GestureDetector(
                    onTap: () => setState(() => _champion = _champion == team ? '' : team),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      color: _champion == team ? _amber.withOpacity(0.2) : Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(team, style: GoogleFonts.outfit(
                              color: _champion == team ? const Color(0xFFFDE047) : Colors.white54,
                              fontSize: 11, fontWeight: FontWeight.w700,
                            ), overflow: TextOverflow.ellipsis),
                          ),
                          if (_champion == team) const Icon(Icons.emoji_events_rounded, color: Color(0xFFFACC15), size: 13),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Submit tab ────────────────────────────────────────────────────────────

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & Lock In', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Once submitted your bracket is permanent — you cannot edit it.',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, height: 1.5)),
          const SizedBox(height: 20),

          // Group Stage section
          _reviewSectionLabel('GROUP STAGE'),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 80,
            ),
            itemCount: _groups.length,
            itemBuilder: (_, i) {
              final letter = _groups.keys.elementAt(i);
              final color = _groupColors[letter]!;
              final picks = _groupPicks[letter] ?? {};
              return Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.22)),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GROUP $letter', style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Text('🥇 ', style: TextStyle(fontSize: 12)),
                      Expanded(child: Text(picks['first'] ?? '—', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Text('🥈 ', style: TextStyle(fontSize: 12)),
                      Expanded(child: Text(picks['second'] ?? '—', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Knockout Stage section
          _reviewSectionLabel('KNOCKOUT STAGE'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _knockoutReviewRow('ROUND OF 16', const Color(0xFF38BDF8), _r16),
                const SizedBox(height: 12),
                _knockoutReviewRow('QUARTER-FINALS', const Color(0xFF60A5FA), _qf),
                const SizedBox(height: 12),
                _knockoutReviewRow('SEMI-FINALS', const Color(0xFFA78BFA), _sf),
                const SizedBox(height: 12),
                _knockoutReviewRow('FINALISTS', _amber, _fin),
                Divider(color: Colors.white.withOpacity(0.07), height: 20),
                Text('CHAMPION', style: GoogleFonts.outfit(color: _amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                _champion.isNotEmpty
                    ? Text('🏆 $_champion', style: GoogleFonts.outfit(color: _amber, fontSize: 16, fontWeight: FontWeight.w900))
                    : Text('Not yet picked', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.2), fontSize: 13, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Incomplete warning
          if (!_bracketComplete) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _amber.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _amber.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 8),
                    Text('Bracket incomplete', style: GoogleFonts.outfit(color: _amber, fontSize: 13, fontWeight: FontWeight.w900)),
                  ]),
                  if (!_groupsComplete) ...[
                    const SizedBox(height: 8),
                    _incompleteRow('Fill in all 12 group stage picks', () => _switchTab(0)),
                  ],
                  if (_groupsComplete && !_knockoutComplete) ...[
                    const SizedBox(height: 8),
                    _incompleteRow('Complete knockout bracket picks', () => _switchTab(1)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lock in button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _bracketComplete
                    ? const LinearGradient(colors: [Color(0xFFFACC15), Color(0xFFD97706)])
                    : null,
                color: _bracketComplete ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                boxShadow: _bracketComplete
                    ? [BoxShadow(color: _amber.withOpacity(0.35), blurRadius: 24, spreadRadius: 2)]
                    : null,
                border: _bracketComplete ? null : Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ElevatedButton(
                onPressed: _bracketComplete ? () => setState(() => _showConfirm = true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: _bracketComplete ? Colors.black : Colors.white24, size: 18),
                    const SizedBox(width: 8),
                    Text('Lock In Bracket', style: GoogleFonts.outfit(
                      color: _bracketComplete ? Colors.black : Colors.white24,
                      fontSize: 16, fontWeight: FontWeight.w900,
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('This action is irreversible.',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _reviewSectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
    );
  }

  Widget _knockoutReviewRow(String label, Color color, List<String> teams) {
    final filled = teams.where((t) => t.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        filled.isEmpty
            ? Text('Not yet picked', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.2), fontSize: 12, fontStyle: FontStyle.italic))
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                children: filled.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(t, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w700)),
                )).toList(),
              ),
      ],
    );
  }

  Widget _incompleteRow(String text, VoidCallback onFix) {
    return Row(
      children: [
        Text('• $text', style: GoogleFonts.outfit(color: _amber.withOpacity(0.8), fontSize: 12)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onFix,
          child: Text('Fix →', style: GoogleFonts.outfit(color: _amber, fontSize: 12, decoration: TextDecoration.underline, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ─── Submitted view ────────────────────────────────────────────────────────

  Widget _buildSubmittedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white30, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text('Your bracket is locked. Results update automatically as the tournament progresses.',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Champion banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_amber.withOpacity(0.08), _amberDark.withOpacity(0.04)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _amber.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('YOUR CHAMPION PICK', style: GoogleFonts.outfit(color: _amber.withOpacity(0.6), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('🏆 ${_champion.isEmpty ? "—" : _champion}', style: GoogleFonts.outfit(color: _amber, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Result pending', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Group Stage Picks', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, mainAxisExtent: 80,
            ),
            itemCount: _groups.length,
            itemBuilder: (_, i) {
              final letter = _groups.keys.elementAt(i);
              final color = _groupColors[letter]!;
              final picks = _groupPicks[letter] ?? {};
              return Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.22)),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('GROUP $letter', style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Text('🥇 ', style: TextStyle(fontSize: 12)),
                    Expanded(child: Text(picks['first'] ?? '—', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Text('🥈 ', style: TextStyle(fontSize: 12)),
                    Expanded(child: Text(picks['second'] ?? '—', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ]),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Confirm dialog ────────────────────────────────────────────────────────

  Widget _buildConfirmDialog() {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _amber.withOpacity(0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _amber.withOpacity(0.12),
                    border: Border.all(color: _amber.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.lock_rounded, color: Color(0xFFFACC15), size: 28),
                ),
                const SizedBox(height: 18),
                Text('Lock In Your Bracket?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Your predictions will be saved permanently. You cannot edit your bracket after this.',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showConfirm = false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.15)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitBracket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amber,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, color: Colors.black, size: 16),
                            const SizedBox(width: 6),
                            Text('Confirm', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

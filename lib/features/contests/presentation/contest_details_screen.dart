import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_scheme.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/pitch_background.dart';
import '../../../core/widgets/animations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/contests_provider.dart';

class ContestDetailsScreen extends ConsumerStatefulWidget {
  final String contestId;

  const ContestDetailsScreen({
    super.key,
    required this.contestId,
  });

  @override
  ConsumerState<ContestDetailsScreen> createState() => _ContestDetailsScreenState();
}

class _ContestDetailsScreenState extends ConsumerState<ContestDetailsScreen> {
  int _activeTabIndex = 0; // 0 = PLAY GAME, 1 = STANDINGS, 2 = MEMBERS
  String _selectedSport = 'football';
  
  // Custom members list state to allow interactive removal
  List<Map<String, dynamic>> _members = [];
  bool _initializedMembers = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  final List<Map<String, dynamic>> _matches = [
    {
      'id': 'match_1',
      'homeTeam': 'Mexico',
      'awayTeam': 'South Africa',
      'homeFlag': 'https://flagcdn.com/w160/mx.png',
      'awayFlag': 'https://flagcdn.com/w160/za.png',
      'homeAccent': const Color(0xFF22c55e),
      'awayAccent': const Color(0xFF22c55e),
      'date': '12 Jun',
      'time': '12 Jun, 12:30 am IST',
      'status': 'OPEN',
      'sport': 'football',
    },
    {
      'id': 'match_2',
      'homeTeam': 'South Korea',
      'awayTeam': 'Czech Republic',
      'homeFlag': 'https://flagcdn.com/w160/kr.png',
      'awayFlag': 'https://flagcdn.com/w160/cz.png',
      'homeAccent': const Color(0xFFef4444),
      'awayAccent': const Color(0xFF3b82f6),
      'date': '12 Jun',
      'time': '12 Jun, 07:30 am IST',
      'status': 'OPEN',
      'sport': 'football',
    },
    {
      'id': 'match_3',
      'homeTeam': 'Uruguay',
      'awayTeam': 'France',
      'homeFlag': 'https://flagcdn.com/w160/uy.png',
      'awayFlag': 'https://flagcdn.com/w160/fr.png',
      'homeAccent': const Color(0xFF38bdf8),
      'awayAccent': const Color(0xFF3b82f6),
      'date': '13 Jun',
      'time': '13 Jun, 08:30 pm IST',
      'status': 'LOCKED',
      'sport': 'football',
    },
    {
      'id': 'cricket_1',
      'homeTeam': 'India',
      'awayTeam': 'Pakistan',
      'homeFlag': 'https://flagcdn.com/w160/in.png',
      'awayFlag': 'https://flagcdn.com/w160/pk.png',
      'homeAccent': const Color(0xFF1e40af),
      'awayAccent': const Color(0xFF166534),
      'date': '18 Jun',
      'time': '18 Jun, 03:00 pm IST',
      'status': 'OPEN',
      'sport': 'cricket',
    },
    {
      'id': 'cricket_2',
      'homeTeam': 'CSK',
      'awayTeam': 'Mumbai Indians',
      'homeFlag': 'https://flagcdn.com/w160/in.png',
      'awayFlag': 'https://flagcdn.com/w160/in.png',
      'homeAccent': const Color(0xFFeab308),
      'awayAccent': const Color(0xFF2563eb),
      'date': '19 Jun',
      'time': '19 Jun, 07:30 pm IST',
      'status': 'OPEN',
      'sport': 'cricket',
    },
  ];

  final List<Map<String, dynamic>> _standings = [
    {
      'position': 1,
      'name': 'Ansil',
      'initials': 'AN',
      'points': 0,
      'color': Colors.amber,
    },
    {
      'position': 2,
      'name': 'Fasil',
      'initials': 'FA',
      'points': 0,
      'color': Colors.blue,
    },
    {
      'position': 3,
      'name': 'Favas',
      'initials': 'FA',
      'points': 0,
      'color': Colors.deepOrangeAccent,
    },
    {
      'position': 4,
      'name': 'Rafeeq',
      'initials': 'RA',
      'points': 0,
      'color': Colors.indigo,
    },
    {
      'position': 5,
      'name': 'Rafeeq',
      'initials': 'RA',
      'points': 0,
      'color': Colors.purple,
    },
  ];

  void _initializeMembersList() {
    if (_initializedMembers) return;
    _members = [
      {'userId': 'user_1', 'name': 'Ansil', 'joined': '6/4/2026', 'isCreator': false, 'initials': 'A', 'color': Colors.blue},
      {'userId': 'user_2', 'name': 'Favas', 'joined': '6/4/2026', 'isCreator': false, 'initials': 'F', 'color': Colors.indigo},
      {'userId': 'user_3', 'name': 'Fasil', 'joined': '6/4/2026', 'isCreator': false, 'initials': 'F', 'color': Colors.purple},
      {'userId': 'user_4', 'name': 'Rafeeq', 'joined': '6/4/2026', 'isCreator': false, 'initials': 'R', 'color': Colors.teal},
      {'userId': 'user_creator', 'name': 'Rafeeq', 'joined': '6/5/2026', 'isCreator': true, 'initials': 'R', 'color': Colors.amber},
    ];
    _initializedMembers = true;
  }

  void _handleRemoveMember(int index, int contestId, String userId) {
    setState(() {
      _members.removeAt(index);
    });
    ref.read(contestsProvider.notifier).removeParticipant(contestId: contestId, userId: userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Member removed successfully'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handlePredict(String matchId, String home, String away, String sport) {
    if (sport == 'cricket') {
      context.push('/predict/cricket/$matchId');
    } else {
      context.push('/predict/$matchId');
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeMembersList();

    // Query parent contests state
    final contestsState = ref.watch(contestsProvider);
    
    // Find the current contest by ID
    final parsedId = int.tryParse(widget.contestId);
    Contest? currentContest;
    
    if (parsedId != null) {
      currentContest = contestsState.activeContests.firstWhere(
        (c) => c.id == parsedId,
        orElse: () => contestsState.globalContests.firstWhere(
          (c) => c.id == parsedId,
          orElse: () => Contest(
            id: parsedId,
            name: 'World Cup 2026',
            gameType: 'match_prediction',
            joinCode: 'L4FWNL',
            createdAt: '2026-06-01',
            tournamentName: 'World Cup 2026',
            memberCount: _members.length,
            creatorName: 'Rafeeq',
            creatorId: 'user_creator',
            isPublic: true,
            maxParticipants: 100,
            joinDeadline: '',
          ),
        ),
      );
    } else {
      currentContest = Contest(
        id: 0,
        name: 'World Cup 2026',
        gameType: 'match_prediction',
        joinCode: 'L4FWNL',
        createdAt: '2026-06-01',
        tournamentName: 'World Cup 2026',
        memberCount: _members.length,
        creatorName: 'Rafeeq',
        creatorId: 'user_creator',
        isPublic: true,
        maxParticipants: 100,
        joinDeadline: '',
      );
    }

    final authState = ref.watch(authProvider);
    final currentUser = authState.value;
    final bool isUserCreatorOfContest = currentUser != null &&
        (currentUser.id == currentContest.creatorId || currentUser.name == currentContest.creatorName);

    // Colors mapping
    final Map<String, dynamic> gameModeCfg = {
          'match_prediction': {
            'label': 'MATCH PREDICTOR',
            'textColor': const Color(0xFFC6C0FF),
            'bgColor': const Color(0xFF1E1B4B),
          },
          'first_goal': {
            'label': 'FIRST GOAL',
            'textColor': const Color(0xFFFFB955),
            'bgColor': const Color(0xFF452B00),
          },
          'formation': {
            'label': 'FORMATION',
            'textColor': const Color(0xFFE4E1E9),
            'bgColor': const Color(0xFF131318),
          },
          'bracket': {
            'label': 'BRACKET',
            'textColor': const Color(0xFF43DF9E),
            'bgColor': const Color(0xFF003823),
          },
          'flags': {
            'label': 'FLAG QUIZ',
            'textColor': const Color(0xFF38BDF8),
            'bgColor': const Color(0xFF0C4A6E),
          },
        }[currentContest.gameType] ??
        {
          'label': currentContest.gameType.toUpperCase(),
          'textColor': Colors.white70,
          'bgColor': Colors.white.withOpacity(0.05),
        };

    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: Stack(
        children: [
          // Background components
          const PitchBackground(child: SizedBox.expand()),

          // Ambient glowing backdrop blobs
          Positioned(
            top: 60,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SkorioColors.primary.withOpacity(0.03),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: SkorioColors.primary.withOpacity(0.03)),
              ),
            ),
          ),

          // Scrollable Page Content or Loading State
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(SkorioColors.primary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PulsingWidget(
                        child: Text(
                          'Loading Contest Details...',
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Custom Page Header (AppBar)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
                            InkWell(
                              onTap: () => context.pop(),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back, color: Colors.white70, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Back',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
      
                            // Center Title
                            Expanded(
                              child: Center(
                                child: Text(
                                  currentContest.name.toUpperCase(),
                                  style: SkorioTextStyles.labelMd.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
      
                            // Invite Code Pill button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currentContest.joinCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.person_add_alt_1_outlined,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      
                      // 2. Contest Meta Info Block
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row of badges (Predictor Mode, Global/Private type)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: gameModeCfg['bgColor'],
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    gameModeCfg['label'],
                                    style: SkorioTextStyles.labelSm.copyWith(
                                      color: gameModeCfg['textColor'],
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.calendar_today_outlined, color: Colors.white30, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  currentContest.isPublic ? 'Global Tournament' : 'Private Contest',
                                  style: SkorioTextStyles.labelSm.copyWith(
                                    color: Colors.white38,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
      
                            // Large Title
                            Text(
                              currentContest.name,
                              style: SkorioTextStyles.headlineLg.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
      
                            // Subtitle
                            RichText(
                              text: TextSpan(
                                style: SkorioTextStyles.bodyMd.copyWith(
                                  color: Colors.white38,
                                  fontSize: 12.5,
                                ),
                                children: [
                                  const TextSpan(text: 'Share the code '),
                                  TextSpan(
                                    text: currentContest.joinCode,
                                    style: const TextStyle(
                                      color: SkorioColors.tertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: ' to invite other members to this contest.'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      
                      // 3. Tab Buttons Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Bottom divider line
                            Container(
                              height: 1.0,
                              color: Colors.white.withOpacity(0.04),
                            ),
                            Row(
                              children: [
                                _buildTabButton(0, 'PLAY GAME'),
                                _buildTabButton(1, 'STANDINGS'),
                                _buildTabButton(2, 'MEMBERS (${_members.length})'),
                              ],
                            ),
                          ],
                        ),
                      ),
      
                      // 4. Tab Body Content (Expanded to scroll)
                      Expanded(
                        child: IndexedStack(
                          index: _activeTabIndex,
                          children: [
                            _buildPlayGameTab(),
                            _buildStandingsTab(),
                            _buildMembersTab(currentContest, isUserCreatorOfContest),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // Helper widget to construct custom aligned tab buttons
  Widget _buildTabButton(int index, String label) {
    final isActive = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? SkorioColors.primary : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- PLAY GAME TAB ---
  Widget _buildPlayGameTab() {
    final filteredMatches = _matches.where((m) => (m['sport'] ?? 'football') == _selectedSport).toList();
    final openMatchesCount = filteredMatches.where((m) => m['status'] == 'OPEN').length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sport Switcher capsules
          Row(
            children: [
              _buildSportCapsule('football', '⚽ FOOTBALL'),
              const SizedBox(width: 12),
              _buildSportCapsule('cricket', '🏏 CRICKET'),
            ],
          ),
          const SizedBox(height: 20),

          // Subheader label
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '$openMatchesCount matches open ',
                    style: const TextStyle(color: SkorioColors.secondary),
                  ),
                  const TextSpan(text: '- to predict dynamically'),
                ],
              ),
            ),
          ),

          // Matches list builder
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredMatches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final match = filteredMatches[index];
              final isOpen = match['status'] == 'OPEN';

              final homeAccent = (match['homeAccent'] as Color?) ?? const Color(0xFFa855f7);
              final awayAccent = (match['awayAccent'] as Color?) ?? const Color(0xFFa855f7);

              return StaggeredEntrance(
                delay: Duration(milliseconds: 100 + index * 70),
                child: GestureDetector(
                  onTap: isOpen
                      ? () => _handlePredict(
                            match['id'],
                            match['homeTeam'],
                            match['awayTeam'],
                            match['sport'] ?? 'football',
                          )
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Team-color glow overlay (web: linear-gradient(135deg, homeAccent44, transparent 50%, awayAccent44))
                        if (isOpen)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    homeAccent.withValues(alpha: 0.27),
                                    Colors.transparent,
                                    awayAccent.withValues(alpha: 0.27),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        // Glass card layer
                        Container(
                          decoration: BoxDecoration(
                            gradient: isOpen
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
                                      Color(0x05FFFFFF), // rgba(255,255,255,0.02)
                                    ],
                                  )
                                : null,
                            color: isOpen ? null : const Color(0x03FFFFFF),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isOpen
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                      children: [
                        // Card Top (Badge + Date)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Status badge (OPEN / LOCKED)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOpen 
                                    ? const Color(0xFF022C22) 
                                    : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isOpen 
                                      ? const Color(0xFF065F46).withOpacity(0.2) 
                                      : Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isOpen ? const Color(0xFF34D399) : Colors.white24,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    match['status'],
                                    style: TextStyle(
                                      color: isOpen ? const Color(0xFF34D399) : Colors.white38,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 8.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Date label
                            Text(
                              match['date'],
                              style: const TextStyle(
                                color: Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
      
                        // Teams comparison row
                        Opacity(
                          opacity: isOpen ? 1.0 : 0.4,
                          child: Row(
                            children: [
                              // Left Team (Home)
                              Expanded(
                                child: Column(
                                  children: [
                                    // Flag image
                                    Container(
                                      width: 60,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          match['homeFlag'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.white10,
                                            child: const Icon(Icons.flag, color: Colors.white24),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      match['homeTeam'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
      
                              // VS center indicator
                              Column(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.04),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'vs',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    match['time'].toString().split(', ').last,
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
      
                              // Right Team (Away)
                              Expanded(
                                child: Column(
                                  children: [
                                    // Flag image
                                    Container(
                                      width: 60,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          match['awayFlag'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.white10,
                                            child: const Icon(Icons.flag, color: Colors.white24),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      match['awayTeam'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
      
                        // Card Bottom button
                        Center(
                          child: isOpen
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8B80FF), Color(0xFFC6C0FF)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.flash_on, color: Colors.black87, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'PREDICT NOW',
                                        style: SkorioTextStyles.labelSm.copyWith(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right, color: Colors.black87, size: 12),
                                    ],
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock_outline, color: Colors.white12, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'UNLOCKS 12 JUN',
                                      style: SkorioTextStyles.labelSm.copyWith(
                                        color: Colors.white12,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),           // Container
                ],             // Stack children
              ),               // Stack
            ),                 // ClipRRect
          ),                   // GestureDetector
        );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSportCapsule(String sport, String label) {
    final isSelected = _selectedSport == sport;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSport = sport;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? SkorioColors.primary.withOpacity(0.15)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? SkorioColors.primary
                : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SkorioColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // --- STANDINGS TAB ---
  Widget _buildStandingsTab() {
    return Column(
      children: [
        // 1. Leaderboard Podium Graphical Representation
        Container(
          padding: const EdgeInsets.only(top: 24, bottom: 20),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Position 2 (Left)
              StaggeredEntrance(
                delay: const Duration(milliseconds: 150),
                child: _buildPodiumColumn(
                  standing: _standings[1],
                  podiumHeight: 90.0,
                  podiumColor: const Color(0xFF1E293B).withOpacity(0.4),
                  avatarBorderColor: const Color(0xFF94A3B8),
                  badgeColor: Colors.blue[800]!,
                  badgeIndex: 2,
                  topIcon: const Icon(Icons.star, color: Color(0xFFCBD5E1), size: 14),
                ),
              ),
              const SizedBox(width: 8),
      
              // Position 1 (Center)
              StaggeredEntrance(
                delay: const Duration(milliseconds: 50),
                child: _buildPodiumColumn(
                  standing: _standings[0],
                  podiumHeight: 120.0,
                  podiumColor: const Color(0xFF78350F).withOpacity(0.3),
                  avatarBorderColor: const Color(0xFFF59E0B),
                  badgeColor: Colors.amber[600]!,
                  badgeIndex: 1,
                  topIcon: const Icon(Icons.emoji_events, color: Color(0xFFFBBF24), size: 16),
                  isTallest: true,
                ),
              ),
              const SizedBox(width: 8),
      
              // Position 3 (Right)
              StaggeredEntrance(
                delay: const Duration(milliseconds: 250),
                child: _buildPodiumColumn(
                  standing: _standings[2],
                  podiumHeight: 70.0,
                  podiumColor: const Color(0xFF431407).withOpacity(0.3),
                  avatarBorderColor: const Color(0xFFD97706),
                  badgeColor: Colors.orange[800]!,
                  badgeIndex: 3,
                  topIcon: const Icon(Icons.military_tech, color: Color(0xFFF97316), size: 14),
                ),
              ),
            ],
          ),
        ),
      
        // 2. Standings Table Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 30,
                    child: Text(
                      'POS',
                      style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PLAYER',
                    style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Text(
                'POINTS',
                style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      
        // 3. Standings Table List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
            itemCount: _standings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final standing = _standings[index];
              final pos = standing['position'];
      
              // Pos styling helper
              Widget posWidget;
              if (pos == 1) {
                posWidget = Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                    color: Colors.amber.withOpacity(0.05),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.amber, size: 13),
                );
              } else if (pos == 2) {
                posWidget = Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    color: Colors.blue.withOpacity(0.05),
                  ),
                  child: const Icon(Icons.star, color: Colors.blue, size: 13),
                );
              } else if (pos == 3) {
                posWidget = Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    color: Colors.orange.withOpacity(0.05),
                  ),
                  child: const Icon(Icons.military_tech, color: Colors.orange, size: 13),
                );
              } else {
                posWidget = SizedBox(
                  width: 26,
                  height: 26,
                  child: Center(
                    child: Text(
                      pos.toString(),
                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
      
              return StaggeredEntrance(
                delay: Duration(milliseconds: 320 + index * 50),
                child: HoverableCard(
                  hoverScale: 1.02,
                  pressScale: 0.98,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Position badge
                            SizedBox(
                              width: 30,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: posWidget,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Avatar
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.04),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Center(
                                child: Text(
                                  standing['initials'],
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Player Name
                            Text(
                              standing['name'],
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        // Points
                        Text(
                          '${standing['points']} pts',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Helper widget to construct columns inside the podium
  Widget _buildPodiumColumn({
    required Map<String, dynamic> standing,
    required double podiumHeight,
    required Color podiumColor,
    required Color avatarBorderColor,
    required Color badgeColor,
    required int badgeIndex,
    required Widget topIcon,
    bool isTallest = false,
  }) {
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top floating crown / star icon
          FloatingWidget(
            child: topIcon,
          ),
          const SizedBox(height: 6),
      
          // 2. Avatar with outline border and index badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: isTallest ? 72 : 60,
                height: isTallest ? 72 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarBorderColor, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: avatarBorderColor.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.03),
                  child: Text(
                    standing['initials'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isTallest ? 16 : 14,
                    ),
                  ),
                ),
              ),
              // Position Index badge at bottom-right
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                ),
                child: Center(
                  child: Text(
                    badgeIndex.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Vertical podium block shape
          Container(
            height: podiumHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: podiumColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border.all(
                color: avatarBorderColor.withOpacity(0.12),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  standing['name'],
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  standing['points'].toString(),
                  style: TextStyle(
                    color: isTallest ? Colors.amber[300] : Colors.white60,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MEMBERS TAB ---
  Widget _buildMembersTab(Contest currentContest, bool isUserCreatorOfContest) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: _members.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = _members[index];
        final isCreator = member['isCreator'] ?? false;

        return StaggeredEntrance(
          delay: Duration(milliseconds: 100 + index * 60),
          child: HoverableCard(
            hoverScale: 1.02,
            pressScale: 0.98,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Circular initials avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: member['color'].withOpacity(0.12),
                          border: Border.all(color: member['color'].withOpacity(0.24)),
                        ),
                        child: Center(
                          child: Text(
                            member['initials'],
                            style: TextStyle(
                              color: member['color'],
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name and joined date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Joined ${member['joined']}',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
    
                  // Creator label OR remove action
                  isCreator
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF452B00),
                            border: Border.all(color: SkorioColors.tertiary.withOpacity(0.35)),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_outlined, color: SkorioColors.tertiary, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                'CREATOR',
                                style: SkorioTextStyles.labelSm.copyWith(
                                  color: SkorioColors.tertiary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 8,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'MEMBER',
                              style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            if (isUserCreatorOfContest) ...[
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 28,
                                child: OutlinedButton(
                                  onPressed: () => _handleRemoveMember(index, currentContest.id, member['userId']?.toString() ?? ''),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.redAccent, width: 1.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  child: const Text(
                                    'REMOVE',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/color_scheme.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/pitch_background.dart';
import '../providers/tournaments_provider.dart';
import '../../auth/providers/auth_provider.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _ensureTabController(bool hasBracket) {
    final expectedLength = hasBracket ? 5 : 4;
    if (_tabController.length != expectedLength) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: expectedLength,
        vsync: this,
        initialIndex: oldIndex < expectedLength ? oldIndex : 0,
      );
    }
  }

  void _showResultEntryDialog(BuildContext context, TournamentMatch match, Tournament tournament) {
    final homeController = TextEditingController(text: match.homeScore.toString());
    final awayController = TextEditingController(text: match.awayScore.toString());
    final scorersController = TextEditingController(text: match.scorers.join(', '));
    final cardsController = TextEditingController(text: match.cards.join(', '));
    final motmController = TextEditingController(text: match.motm ?? '');

    final homeTeam = tournament.teams.firstWhere((t) => t.id == match.homeTeamId);
    final awayTeam = tournament.teams.firstWhere((t) => t.id == match.awayTeamId);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131318),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Text(
            "Enter Result",
            style: SkorioTextStyles.labelMd.copyWith(color: Colors.white, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(homeTeam.logoUrl, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(homeTeam.name, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          _buildNumberField(homeController),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("VS", style: TextStyle(color: Colors.white30, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(awayTeam.logoUrl, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(awayTeam.name, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          _buildNumberField(awayController),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel("Scorers (comma separated player names)"),
                _buildTextField(scorersController, "e.g., Alex Thorne, Chris Evans"),
                const SizedBox(height: 12),
                _buildLabel("Cards (comma separated name:Yellow/Red)"),
                _buildTextField(cardsController, "e.g., Marcus Fox:Yellow, Tom Hardy:Red"),
                const SizedBox(height: 12),
                _buildLabel("Man of the Match"),
                _buildTextField(motmController, "e.g., Alex Thorne"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                final hScore = int.tryParse(homeController.text.trim()) ?? 0;
                final aScore = int.tryParse(awayController.text.trim()) ?? 0;
                final scorers = scorersController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final cards = cardsController.text.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
                final motm = motmController.text.trim().isEmpty ? null : motmController.text.trim();

                await ref.read(tournamentsProvider.notifier).updateMatchResult(
                      tournament.id,
                      match.id,
                      hScore,
                      aScore,
                      scorers: scorers,
                      cards: cards,
                      motm: motm,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Match results updated and standings recalculated!"),
                      backgroundColor: SkorioColors.onSecondaryContainer,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SkorioColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("SAVE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddFixtureDialog(BuildContext context, Tournament tournament) {
    String? homeTeamId;
    String? awayTeamId;
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 1));
    String phase = '';
    final venueCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131318),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white12),
              ),
              title: Text(
                "Add Fixture",
                style: SkorioTextStyles.labelMd.copyWith(color: Colors.white, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Home Team"),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButton<String?>(
                        value: homeTeamId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF131318),
                        hint: const Text("Select home team", style: TextStyle(color: Colors.white38, fontSize: 13)),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        underline: Container(height: 1, color: Colors.white12),
                        onChanged: (v) => setDialogState(() => homeTeamId = v),
                        items: tournament.teams.map((team) => DropdownMenuItem<String?>(
                          value: team.id,
                          child: Text('${team.logoUrl} ${team.name}'),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel("Away Team"),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButton<String?>(
                        value: awayTeamId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF131318),
                        hint: const Text("Select away team", style: TextStyle(color: Colors.white38, fontSize: 13)),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        underline: Container(height: 1, color: Colors.white12),
                        onChanged: (v) => setDialogState(() => awayTeamId = v),
                        items: tournament.teams.map((team) => DropdownMenuItem<String?>(
                          value: team.id,
                          child: Text('${team.logoUrl} ${team.name}'),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel("Venue"),
                    TextField(
                      controller: venueCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "e.g. Main Ground - Pitch A",
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel("Match Date"),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: scheduledDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date == null) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(scheduledDate),
                        );
                        setDialogState(() {
                          scheduledDate = DateTime(
                            date.year, date.month, date.day,
                            time?.hour ?? scheduledDate.hour,
                            time?.minute ?? scheduledDate.minute,
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event, color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}  ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel("Phase"),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButton<String>(
                        value: phase,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF131318),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        underline: Container(height: 1, color: Colors.white12),
                        onChanged: (v) => setDialogState(() => phase = v ?? ''),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('League')),
                          DropdownMenuItem(value: 'r16', child: Text('Round of 16')),
                          DropdownMenuItem(value: 'qf', child: Text('Quarter Final')),
                          DropdownMenuItem(value: 'sf', child: Text('Semifinal')),
                          DropdownMenuItem(value: 'final', child: Text('Final')),
                          DropdownMenuItem(value: 'third', child: Text('3rd Place')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (homeTeamId == null || awayTeamId == null || homeTeamId == awayTeamId) return;
                    final newMatch = TournamentMatch(
                      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
                      homeTeamId: homeTeamId!,
                      awayTeamId: awayTeamId!,
                      date: scheduledDate,
                      status: 'scheduled',
                      venue: venueCtrl.text.trim().isEmpty ? 'TBD' : venueCtrl.text.trim(),
                      phase: phase,
                      groupId: '',
                    );
                    ref.read(tournamentsProvider.notifier).addMatchToTournament(tournament.id, newMatch);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SkorioColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("ADD FIXTURE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNumberField(TextEditingController controller) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: SkorioTextStyles.labelSm.copyWith(color: Colors.white54, fontSize: 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentsProvider);
    final tIdx = state.tournaments.indexWhere((t) => t.id == widget.tournamentId);

    if (tIdx == -1) {
      return Scaffold(
        backgroundColor: SkorioColors.baseBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Tournament not found", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.pop(), child: const Text("Go Back")),
            ],
          ),
        ),
      );
    }

    final tournament = state.tournaments[tIdx];
    final currentUser = ref.watch(authProvider).value;
    final isCreator = currentUser != null && tournament.creatorId == currentUser.id;
    final hasBracket = tournament.format == 'knockout' || tournament.format == 'group_knockout';
    _ensureTabController(hasBracket);

    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: Stack(
        children: [
          const PitchBackground(child: SizedBox.expand()),

          // Ambient Background Glows
          Positioned(
            top: 40,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SkorioColors.secondary.withValues(alpha: 0.03),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: SkorioColors.secondary.withValues(alpha: 0.03)),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildHeader(context, tournament),

                // Sub-tabs Selector
                _buildSubTabs(hasBracket),

                // Sub-tabs Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStandingsTab(tournament),
                      _buildFixturesTab(tournament, isCreator: isCreator),
                      _buildTeamsTab(tournament),
                      _buildStatsTab(tournament),
                      if (hasBracket) _buildBracketTab(tournament, isCreator: isCreator),
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

  Widget _buildHeader(BuildContext context, Tournament tournament) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name.toUpperCase(),
                  style: SkorioTextStyles.labelMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  "${tournament.sport.toUpperCase()} · ${tournament.location}",
                  style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white54, size: 20),
            onPressed: () {
              final text = '🏆 ${tournament.name}\n'
                  '${tournament.sport.toUpperCase()} · ${tournament.location}\n'
                  '${tournament.teams.length} teams · ${tournament.format.toUpperCase()} format\n\n'
                  'Follow on Skorio 📲';
              SharePlus.instance.share(ShareParams(text: text));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabs(bool hasBracket) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: SkorioColors.secondary,
        labelColor: SkorioColors.secondary,
        unselectedLabelColor: Colors.white30,
        labelStyle: SkorioTextStyles.labelSm.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
        indicatorSize: TabBarIndicatorSize.tab,
        isScrollable: hasBracket,
        tabs: [
          const Tab(text: "STANDINGS"),
          const Tab(text: "FIXTURES"),
          const Tab(text: "TEAMS"),
          const Tab(text: "LEADERS"),
          if (hasBracket) const Tab(text: "BRACKET"),
        ],
      ),
    );
  }

  // ─── 1. Standings Tab ────────────────────────────────────────────────────────

  Widget _buildStandingsTab(Tournament tournament) {
    if (tournament.format == 'group_knockout') {
      final groupStandings = ref.watch(tournamentsProvider.notifier).getGroupStandings(tournament.id);
      if (groupStandings.isEmpty) {
        return Center(
          child: Text("No group stage data yet", style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24)),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupStandings.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "GROUP ${entry.key}",
                    style: SkorioTextStyles.labelMd.copyWith(color: SkorioColors.secondary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                  ),
                ),
                _buildStandingsTable(entry.value),
                const SizedBox(height: 20),
              ],
            );
          }).toList(),
        ),
      );
    }

    final standings = ref.watch(tournamentsProvider.notifier).getStandings(tournament.id);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildStandingsTable(standings),
    );
  }

  Widget _buildStandingsTable(List<StandingsRecord> standings) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderColor: SkorioColors.secondary.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_list_numbered, color: SkorioColors.secondary, size: 16),
              const SizedBox(width: 8),
              Text(
                "POINTS TABLE",
                style: SkorioTextStyles.labelMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Standings Table Header
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Text("#   TEAM", style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              _buildTableCellHeader("P", 1),
              _buildTableCellHeader("W", 1),
              _buildTableCellHeader("D", 1),
              _buildTableCellHeader("L", 1),
              _buildTableCellHeader("GD", 1.2),
              _buildTableCellHeader("PTS", 1.5, align: Alignment.centerRight),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          // Standings Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: standings.length,
            itemBuilder: (context, idx) {
              final rec = standings[idx];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Team Name & Rank
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            child: Text(
                              "${idx + 1}",
                              style: TextStyle(
                                color: idx < 3 ? SkorioColors.secondary : Colors.white24,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(rec.team.logoUrl, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec.team.name,
                              style: SkorioTextStyles.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stats Columns
                    _buildTableCell("${rec.played}", 1),
                    _buildTableCell("${rec.won}", 1),
                    _buildTableCell("${rec.drawn}", 1),
                    _buildTableCell("${rec.lost}", 1),
                    _buildTableCell("${rec.gd > 0 ? "+" : ""}${rec.gd}", 1.2),
                    _buildTableCell(
                      "${rec.points}",
                      1.5,
                      align: Alignment.centerRight,
                      style: const TextStyle(color: SkorioColors.secondary, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableCellHeader(String text, double flex, {Alignment align = Alignment.center}) {
    return Expanded(
      flex: (flex * 10).round(),
      child: Container(
        alignment: align,
        child: Text(
          text,
          style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24, fontSize: 9.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, double flex, {Alignment align = Alignment.center, TextStyle? style}) {
    return Expanded(
      flex: (flex * 10).round(),
      child: Container(
        alignment: align,
        child: Text(
          text,
          style: style ?? SkorioTextStyles.labelSm.copyWith(color: Colors.white70, fontSize: 11.5, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  // ─── 2. Fixtures Tab ────────────────────────────────────────────────────────

  Widget _buildFixturesTab(Tournament tournament, {required bool isCreator}) {
    return Stack(
      children: [
        if (tournament.matches.isEmpty)
          Center(
            child: Text("No fixtures yet. Tap + to add.", style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24)),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournament.matches.length,
            itemBuilder: (context, idx) {
        final match = tournament.matches[idx];
        final homeTeam = tournament.teams.firstWhere((t) => t.id == match.homeTeamId);
        final awayTeam = tournament.teams.firstWhere((t) => t.id == match.awayTeamId);

        final homeColor = Color(int.tryParse(homeTeam.primaryColor) ?? 0xFFEF4444);
        final awayColor = Color(int.tryParse(awayTeam.primaryColor) ?? 0xFF3B82F6);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: match.status == 'live' ? SkorioColors.secondary.withValues(alpha: 0.2) : Colors.white12,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match.venue,
                      style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30, fontSize: 9),
                    ),
                    _buildStatusBadge(match.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Home
                    Expanded(
                      child: Column(
                        children: [
                          Text(homeTeam.logoUrl, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            homeTeam.name,
                            style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Score Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        match.status == 'completed' ? "${match.homeScore} - ${match.awayScore}" : "VS",
                        style: TextStyle(
                          color: match.status == 'completed' ? SkorioColors.secondary : Colors.white30,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Away
                    Expanded(
                      child: Column(
                        children: [
                          Text(awayTeam.logoUrl, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            awayTeam.name,
                            style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Scorers
                if (match.status == 'completed' && match.scorers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_soccer, color: Colors.white24, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            match.scorers.join(', '),
                            style: SkorioTextStyles.labelSm.copyWith(color: Colors.white54, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Admin Edit Button
                if (isCreator && match.status != 'completed') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: SkorioColors.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _showResultEntryDialog(context, match, tournament),
                      child: Text(
                        "RECORD RESULT",
                        style: SkorioTextStyles.labelSm.copyWith(
                          color: SkorioColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
            },
          ),
        if (isCreator)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'add_fixture',
              backgroundColor: SkorioColors.secondary,
              onPressed: () => _showAddFixtureDialog(context, tournament),
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.white24;
    String text = status.toUpperCase();

    if (status == 'live') {
      color = SkorioColors.secondary;
    } else if (status == 'completed') {
      color = Colors.white54;
    } else {
      text = "SCHEDULED";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: SkorioTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 8),
      ),
    );
  }

  // ─── 3. Teams Tab ──────────────────────────────────────────────────────────

  Widget _buildTeamsTab(Tournament tournament) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: tournament.teams.length,
      itemBuilder: (context, idx) {
        final team = tournament.teams[idx];
        final colorVal = int.tryParse(team.primaryColor) ?? 0xFF43DF9E;
        final primaryColor = Color(colorVal);

        return GestureDetector(
          onTap: () => _showRosterSheet(context, team),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            borderColor: primaryColor.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(team.logoUrl, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  team.name,
                  style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${team.players.length} registered squad",
                  style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRosterSheet(BuildContext context, TournamentTeam team) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131318),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(team.logoUrl, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    "${team.name} Squad Roster",
                    style: SkorioTextStyles.labelMd.copyWith(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: team.players.isEmpty
                    ? Center(
                        child: Text("No roster uploaded", style: TextStyle(color: Colors.white24)),
                      )
                    : ListView.builder(
                        itemCount: team.players.length,
                        itemBuilder: (context, idx) {
                          final player = team.players[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white10,
                                  child: Text(
                                    "${player.jerseyNumber}",
                                    style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.name,
                                        style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        player.position,
                                        style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${player.goals} Goals",
                                  style: TextStyle(color: SkorioColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── 4. Leaders Tab ─────────────────────────────────────────────────────────

  Widget _buildStatsTab(Tournament tournament) {
    // Extract all players and sort
    final List<TournamentPlayer> allPlayers = [];
    for (var team in tournament.teams) {
      allPlayers.addAll(team.players);
    }

    if (allPlayers.isEmpty) {
      return Center(
        child: Text("No statistics compiled yet", style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24)),
      );
    }

    final topScorers = (List<TournamentPlayer>.from(allPlayers)..sort((x, y) => y.goals.compareTo(x.goals)))
        .where((p) => p.goals > 0).take(5).toList();
    final topMotm = (List<TournamentPlayer>.from(allPlayers)..sort((x, y) => y.motm.compareTo(x.motm)))
        .where((p) => p.motm > 0).take(5).toList();
    final mostCards = (List<TournamentPlayer>.from(allPlayers)..sort((x, y) => y.cards.compareTo(x.cards)))
        .where((p) => p.cards > 0).take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeaderSection("TOP GOAL SCORERS ⚽", topScorers, (p) => "${p.goals} Goals"),
          const SizedBox(height: 20),
          _buildLeaderSection("MAN OF THE MATCH 👑", topMotm, (p) => "${p.motm} Awards"),
          const SizedBox(height: 20),
          _buildLeaderSection("DISCIPLINARY 🟨", mostCards, (p) => "${p.cards} Cards"),
        ],
      ),
    );
  }

  Widget _buildLeaderSection(
    String title,
    List<TournamentPlayer> sortedList,
    String Function(TournamentPlayer) metricExtractor,
  ) {
    final top3 = sortedList;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: SkorioColors.secondary.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SkorioTextStyles.labelMd.copyWith(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 12),
          top3.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text("No records recorded", style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top3.length,
                  itemBuilder: (context, idx) {
                    final player = top3[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            idx == 0
                                ? Icons.workspace_premium
                                : idx == 1
                                    ? Icons.stars
                                    : Icons.star_border,
                            color: idx == 0
                                ? SkorioColors.gold
                                : idx == 1
                                    ? SkorioColors.silver
                                    : SkorioColors.bronze,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              player.name,
                              style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            metricExtractor(player),
                            style: const TextStyle(color: SkorioColors.secondary, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ─── 5. Bracket Tab ──────────────────────────────────────────────────────────

  Widget _buildBracketTab(Tournament tournament, {required bool isCreator}) {
    final rounds = ref.watch(tournamentsProvider.notifier).getKnockoutRounds(tournament.id);

    if (rounds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_tree_outlined, color: Colors.white24, size: 40),
            const SizedBox(height: 12),
            Text(
              "No knockout matches yet",
              style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24),
            ),
            const SizedBox(height: 6),
            Text(
              "Add matches with phase r16/qf/sf/final",
              style: SkorioTextStyles.labelSm.copyWith(color: Colors.white12, fontSize: 10),
            ),
          ],
        ),
      );
    }

    const phaseLabels = {'r16': 'R16', 'qf': 'QF', 'sf': 'SEMI', 'final': 'FINAL'};
    const phaseColors = {
      'r16': Color(0xFF38BDF8),
      'qf': Color(0xFF60A5FA),
      'sf': Color(0xFFA78BFA),
      'final': Color(0xFFFBBF24),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rounds.entries.map((entry) {
            final phase = entry.key;
            final matches = entry.value;
            final color = phaseColors[phase] ?? SkorioColors.secondary;
            final label = phaseLabels[phase] ?? phase.toUpperCase();

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 140,
                child: Column(
                  children: [
                    Text(
                      label,
                      style: SkorioTextStyles.labelSm.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...matches.map((match) {
                      final homeTeam = tournament.teams.where((t) => t.id == match.homeTeamId).firstOrNull;
                      final awayTeam = tournament.teams.where((t) => t.id == match.awayTeamId).firstOrNull;
                      final homeName = homeTeam?.name ?? 'TBD';
                      final awayName = awayTeam?.name ?? 'TBD';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: match.status == 'completed'
                                ? color.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          children: [
                            _bracketTeamRow(homeName, match.homeScore,
                                match.status == 'completed' && match.homeScore > match.awayScore, color),
                            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                            _bracketTeamRow(awayName, match.awayScore,
                                match.status == 'completed' && match.awayScore > match.homeScore, color),
                            if (match.status != 'completed' && isCreator)
                              GestureDetector(
                                onTap: () => _showResultEntryDialog(context, match, tournament),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  color: color.withValues(alpha: 0.08),
                                  child: Text(
                                    '+ RESULT',
                                    textAlign: TextAlign.center,
                                    style: SkorioTextStyles.labelSm.copyWith(
                                      color: color,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _bracketTeamRow(String name, int score, bool isWinner, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      color: isWinner ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: SkorioTextStyles.labelSm.copyWith(
                color: isWinner ? Colors.white : Colors.white54,
                fontWeight: isWinner ? FontWeight.w900 : FontWeight.w600,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: isWinner ? accentColor : Colors.white30,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// ─── Models ──────────────────────────────────────────────────────────────────

class TournamentPlayer {
  final String id;
  final String name;
  final int jerseyNumber;
  final String position;
  final int goals;
  final int assists;
  final int cards; // total yellow/red cards
  final int motm;  // Man of the Match awards

  const TournamentPlayer({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.position,
    this.goals = 0,
    this.assists = 0,
    this.cards = 0,
    this.motm = 0,
  });

  TournamentPlayer copyWith({
    String? id,
    String? name,
    int? jerseyNumber,
    String? position,
    int? goals,
    int? assists,
    int? cards,
    int? motm,
  }) {
    return TournamentPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      position: position ?? this.position,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      cards: cards ?? this.cards,
      motm: motm ?? this.motm,
    );
  }

  factory TournamentPlayer.fromJson(Map<String, dynamic> json) {
    return TournamentPlayer(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      jerseyNumber: json['jersey_number'] ?? json['jerseyNumber'] ?? 0,
      position: json['position'] ?? 'MID',
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      cards: json['cards'] ?? 0,
      motm: json['motm'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'jersey_number': jerseyNumber,
      'position': position,
      'goals': goals,
      'assists': assists,
      'cards': cards,
      'motm': motm,
    };
  }
}

class TournamentTeam {
  final String id;
  final String name;
  final String logoUrl; // Emoji badge
  final String primaryColor;
  final String secondaryColor;
  final List<TournamentPlayer> players;

  const TournamentTeam({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.players,
  });

  TournamentTeam copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    List<TournamentPlayer>? players,
  }) {
    return TournamentTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      players: players ?? this.players,
    );
  }

  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    return TournamentTeam(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logo_url'] ?? '⚽',
      primaryColor: json['primary_color'] ?? '0xFF43DF9E',
      secondaryColor: json['secondary_color'] ?? '0xFF131318',
      players: (json['players'] as List?)
              ?.map((p) => TournamentPlayer.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'players': players.map((p) => p.toJson()).toList(),
    };
  }
}

class TournamentMatch {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int homeScore;
  final int awayScore;
  final DateTime date;
  final String status; // 'scheduled', 'live', 'completed'
  final String venue;
  final List<String> scorers; // list of player names/ids
  final List<String> cards;   // e.g. ["Marcus_F:Yellow", "NeyMagic:Yellow"]
  final String? motm;         // Player Name/Id
  final String phase;         // 'group', 'r16', 'qf', 'sf', 'final', '' (league)
  final String groupId;       // 'A', 'B', etc. for group stage, empty otherwise

  const TournamentMatch({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore = 0,
    this.awayScore = 0,
    required this.date,
    required this.status,
    required this.venue,
    this.scorers = const [],
    this.cards = const [],
    this.motm,
    this.phase = '',
    this.groupId = '',
  });

  TournamentMatch copyWith({
    String? id,
    String? homeTeamId,
    String? awayTeamId,
    int? homeScore,
    int? awayScore,
    DateTime? date,
    String? status,
    String? venue,
    List<String>? scorers,
    List<String>? cards,
    String? motm,
    String? phase,
    String? groupId,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      date: date ?? this.date,
      status: status ?? this.status,
      venue: venue ?? this.venue,
      scorers: scorers ?? this.scorers,
      cards: cards ?? this.cards,
      motm: motm ?? this.motm,
      phase: phase ?? this.phase,
      groupId: groupId ?? this.groupId,
    );
  }

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id']?.toString() ?? '',
      homeTeamId: json['home_team_id']?.toString() ?? json['homeTeamId']?.toString() ?? '',
      awayTeamId: json['away_team_id']?.toString() ?? json['awayTeamId']?.toString() ?? '',
      homeScore: json['home_score'] ?? 0,
      awayScore: json['away_score'] ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      status: json['status'] ?? 'scheduled',
      venue: json['venue'] ?? 'Pitch A',
      scorers: (json['scorers'] as List?)?.map((s) => s.toString()).toList() ?? [],
      cards: (json['cards'] as List?)?.map((c) => c.toString()).toList() ?? [],
      motm: json['motm']?.toString(),
      phase: json['phase'] ?? '',
      groupId: json['group_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'home_score': homeScore,
      'away_score': awayScore,
      'date': date.toIso8601String(),
      'status': status,
      'venue': venue,
      'scorers': scorers,
      'cards': cards,
      'motm': motm,
      'phase': phase,
      'group_id': groupId,
    };
  }
}

class Tournament {
  final String id;
  final String name;
  final String sport;       // 'football', 'cricket', 'custom'
  final String format;      // 'league', 'knockout', 'group_knockout'
  final String description;
  final String location;
  final String bannerUrl;
  final int winPts;
  final int drawPts;
  final int lossPts;
  final List<TournamentTeam> teams;
  final List<TournamentMatch> matches;
  final String prizes;
  final String creatorId;
  final bool isPublished;

  const Tournament({
    required this.id,
    required this.name,
    required this.sport,
    required this.format,
    required this.description,
    required this.location,
    required this.bannerUrl,
    required this.winPts,
    required this.drawPts,
    required this.lossPts,
    required this.teams,
    required this.matches,
    required this.prizes,
    required this.creatorId,
    this.isPublished = true,
  });

  Tournament copyWith({
    String? id,
    String? name,
    String? sport,
    String? format,
    String? description,
    String? location,
    String? bannerUrl,
    int? winPts,
    int? drawPts,
    int? lossPts,
    List<TournamentTeam>? teams,
    List<TournamentMatch>? matches,
    String? prizes,
    String? creatorId,
    bool? isPublished,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      format: format ?? this.format,
      description: description ?? this.description,
      location: location ?? this.location,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      winPts: winPts ?? this.winPts,
      drawPts: drawPts ?? this.drawPts,
      lossPts: lossPts ?? this.lossPts,
      teams: teams ?? this.teams,
      matches: matches ?? this.matches,
      prizes: prizes ?? this.prizes,
      creatorId: creatorId ?? this.creatorId,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      sport: json['sport'] ?? 'football',
      format: json['format'] ?? 'league',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      bannerUrl: json['banner_url'] ?? '',
      winPts: json['win_pts'] ?? 3,
      drawPts: json['draw_pts'] ?? 1,
      lossPts: json['loss_pts'] ?? 0,
      teams: (json['teams'] as List?)?.map((t) => TournamentTeam.fromJson(t)).toList() ?? [],
      matches: (json['matches'] as List?)?.map((m) => TournamentMatch.fromJson(m)).toList() ?? [],
      prizes: json['prizes'] ?? '',
      creatorId: json['creator_id'] ?? '',
      isPublished: json['is_published'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'format': format,
      'description': description,
      'location': location,
      'banner_url': bannerUrl,
      'win_pts': winPts,
      'draw_pts': drawPts,
      'loss_pts': lossPts,
      'teams': teams.map((t) => t.toJson()).toList(),
      'matches': matches.map((m) => m.toJson()).toList(),
      'prizes': prizes,
      'creator_id': creatorId,
      'is_published': isPublished,
    };
  }
}

class StandingsRecord {
  final TournamentTeam team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int gf; // Goals For / Runs For
  final int ga; // Goals Against / Runs Against
  final int gd; // Goal Difference / NRR
  final int points;
  final List<String> form; // Last 5 results, e.g. ['W', 'D', 'W']

  const StandingsRecord({
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.gf,
    required this.ga,
    required this.gd,
    required this.points,
    required this.form,
  });
}

// ─── State ───────────────────────────────────────────────────────────────────

class TournamentsState {
  final List<Tournament> tournaments;
  final bool isLoading;
  final String? error;

  const TournamentsState({
    required this.tournaments,
    this.isLoading = false,
    this.error,
  });

  TournamentsState copyWith({
    List<Tournament>? tournaments,
    bool? isLoading,
    String? error,
  }) {
    return TournamentsState(
      tournaments: tournaments ?? this.tournaments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class TournamentsNotifier extends Notifier<TournamentsState> {
  @override
  TournamentsState build() {
    Future.microtask(() => loadTournaments());
    return const TournamentsState(tournaments: [], isLoading: false);
  }

  Future<void> loadTournaments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = sb.Supabase.instance.client;
      final response = await client.from('tournaments').select();

      final list = (response as List).map((t) => Tournament.fromJson(t)).toList();
      state = TournamentsState(tournaments: list, isLoading: false);
    } catch (e) {
      debugPrint("Failed to load tournaments from Supabase, loading mock: $e");
      state = TournamentsState(
        tournaments: _getMockTournaments(),
        isLoading: false,
      );
    }
  }

  /// Creates a new tournament and generates matches if round-robin format
  Future<bool> createTournament(Tournament tournament) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Automatically generate fixtures for League format
    var processedTournament = tournament;
    if (tournament.format == 'league' && tournament.teams.length >= 2) {
      final generatedMatches = _generateRoundRobinFixtures(tournament.teams);
      processedTournament = tournament.copyWith(matches: generatedMatches);
    }

    try {
      final client = sb.Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      final userId = currentUser?.id ?? 'mock-user-id';

      final finalTournament = processedTournament.copyWith(creatorId: userId);

      await client.from('tournaments').insert(finalTournament.toJson());
      await loadTournaments();
      return true;
    } catch (e) {
      debugPrint("Failed to save tournament to database, running locally: $e");
      // Local fallback
      final updatedList = [processedTournament, ...state.tournaments];
      state = TournamentsState(tournaments: updatedList, isLoading: false);
      return true;
    }
  }

  /// Updates a match score and recalculates the team standings and player statistics
  Future<bool> updateMatchResult(
    String tournamentId,
    String matchId,
    int homeScore,
    int awayScore, {
    List<String> scorers = const [],
    List<String> cards = const [],
    String? motm,
  }) async {
    final tIdx = state.tournaments.indexWhere((t) => t.id == tournamentId);
    if (tIdx == -1) return false;

    final tournament = state.tournaments[tIdx];
    final updatedMatches = tournament.matches.map((m) {
      if (m.id == matchId) {
        return m.copyWith(
          homeScore: homeScore,
          awayScore: awayScore,
          status: 'completed',
          scorers: scorers,
          cards: cards,
          motm: motm,
        );
      }
      return m;
    }).toList();

    // Recalculate Player stats dynamically on completion
    final updatedTeams = _recalculatePlayerStats(tournament.teams, updatedMatches);

    final updatedTournament = tournament.copyWith(
      matches: updatedMatches,
      teams: updatedTeams,
    );

    // Save to database
    try {
      final client = sb.Supabase.instance.client;
      await client
          .from('tournaments')
          .update(updatedTournament.toJson())
          .eq('id', tournamentId);
    } catch (e) {
      debugPrint("Failed to update tournament in database, applying locally: $e");
    }

    final newList = List<Tournament>.from(state.tournaments);
    newList[tIdx] = updatedTournament;
    state = state.copyWith(tournaments: newList);

    return true;
  }

  // Standings Calculation Helper
  List<StandingsRecord> getStandings(String tournamentId) {
    final tIdx = state.tournaments.indexWhere((t) => t.id == tournamentId);
    if (tIdx == -1) return [];

    final tournament = state.tournaments[tIdx];
    final Map<String, _TeamAccumulator> acc = {};

    // Init accumulators
    for (var team in tournament.teams) {
      acc[team.id] = _TeamAccumulator(team: team);
    }

    // Accumulate finished matches
    for (var match in tournament.matches) {
      if (match.status == 'completed') {
        final home = acc[match.homeTeamId];
        final away = acc[match.awayTeamId];

        if (home != null && away != null) {
          home.played++;
          away.played++;

          home.gf += match.homeScore;
          home.ga += match.awayScore;
          away.gf += match.awayScore;
          away.ga += match.homeScore;

          if (match.homeScore > match.awayScore) {
            home.won++;
            home.points += tournament.winPts;
            home.form.add('W');

            away.lost++;
            away.points += tournament.lossPts;
            away.form.add('L');
          } else if (match.awayScore > match.homeScore) {
            away.won++;
            away.points += tournament.winPts;
            away.form.add('W');

            home.lost++;
            home.points += tournament.lossPts;
            home.form.add('L');
          } else {
            home.drawn++;
            home.points += tournament.drawPts;
            home.form.add('D');

            away.drawn++;
            away.points += tournament.drawPts;
            away.form.add('D');
          }
        }
      }
    }

    // Convert to records and sort
    final records = acc.values.map((a) {
      // Keep only last 5 form elements
      final formList = a.form.length > 5 ? a.form.sublist(a.form.length - 5) : a.form;
      return StandingsRecord(
        team: a.team,
        played: a.played,
        won: a.won,
        drawn: a.drawn,
        lost: a.lost,
        gf: a.gf,
        ga: a.ga,
        gd: a.gf - a.ga,
        points: a.points,
        form: formList,
      );
    }).toList();

    // Sorting: Points desc, GD desc, GF desc, Name asc
    records.sort((x, y) {
      if (x.points != y.points) return y.points.compareTo(x.points);
      if (x.gd != y.gd) return y.gd.compareTo(x.gd);
      if (x.gf != y.gf) return y.gf.compareTo(x.gf);
      return x.team.name.compareTo(y.team.name);
    });

    return records;
  }

  /// Returns standings keyed by groupId for group_knockout format tournaments
  Map<String, List<StandingsRecord>> getGroupStandings(String tournamentId) {
    final tIdx = state.tournaments.indexWhere((t) => t.id == tournamentId);
    if (tIdx == -1) return {};
    final tournament = state.tournaments[tIdx];

    // Collect unique group IDs from matches
    final groupIds = tournament.matches
        .where((m) => m.groupId.isNotEmpty)
        .map((m) => m.groupId)
        .toSet()
        .toList()
      ..sort();

    if (groupIds.isEmpty) return {};

    final Map<String, List<StandingsRecord>> result = {};
    for (final groupId in groupIds) {
      final groupMatches = tournament.matches.where((m) => m.groupId == groupId).toList();
      final groupTeamIds = <String>{};
      for (final m in groupMatches) {
        groupTeamIds.add(m.homeTeamId);
        groupTeamIds.add(m.awayTeamId);
      }
      final groupTeams = tournament.teams.where((t) => groupTeamIds.contains(t.id)).toList();

      final Map<String, _TeamAccumulator> acc = {};
      for (var team in groupTeams) {
        acc[team.id] = _TeamAccumulator(team: team);
      }
      for (var match in groupMatches) {
        if (match.status == 'completed') {
          final home = acc[match.homeTeamId];
          final away = acc[match.awayTeamId];
          if (home != null && away != null) {
            home.played++; away.played++;
            home.gf += match.homeScore; home.ga += match.awayScore;
            away.gf += match.awayScore; away.ga += match.homeScore;
            if (match.homeScore > match.awayScore) {
              home.won++; home.points += tournament.winPts; home.form.add('W');
              away.lost++; away.points += tournament.lossPts; away.form.add('L');
            } else if (match.awayScore > match.homeScore) {
              away.won++; away.points += tournament.winPts; away.form.add('W');
              home.lost++; home.points += tournament.lossPts; home.form.add('L');
            } else {
              home.drawn++; home.points += tournament.drawPts; home.form.add('D');
              away.drawn++; away.points += tournament.drawPts; away.form.add('D');
            }
          }
        }
      }
      final records = acc.values.map((a) {
        final formList = a.form.length > 5 ? a.form.sublist(a.form.length - 5) : a.form;
        return StandingsRecord(
          team: a.team, played: a.played, won: a.won, drawn: a.drawn, lost: a.lost,
          gf: a.gf, ga: a.ga, gd: a.gf - a.ga, points: a.points, form: formList,
        );
      }).toList();
      records.sort((x, y) {
        if (x.points != y.points) return y.points.compareTo(x.points);
        if (x.gd != y.gd) return y.gd.compareTo(x.gd);
        if (x.gf != y.gf) return y.gf.compareTo(x.gf);
        return x.team.name.compareTo(y.team.name);
      });
      result[groupId] = records;
    }
    return result;
  }

  /// Returns knockout matches grouped by phase for bracket display
  Map<String, List<TournamentMatch>> getKnockoutRounds(String tournamentId) {
    final tIdx = state.tournaments.indexWhere((t) => t.id == tournamentId);
    if (tIdx == -1) return {};
    final tournament = state.tournaments[tIdx];

    const phases = ['r16', 'qf', 'sf', 'final'];
    final Map<String, List<TournamentMatch>> result = {};
    for (final phase in phases) {
      final matches = tournament.matches.where((m) => m.phase == phase).toList();
      if (matches.isNotEmpty) result[phase] = matches;
    }
    return result;
  }

  // Recalculates stats like goals, cards, and MOTMs per player based on match results
  List<TournamentTeam> _recalculatePlayerStats(
    List<TournamentTeam> teams,
    List<TournamentMatch> matches,
  ) {
    final Map<String, int> playerGoals = {};
    final Map<String, int> playerCards = {};
    final Map<String, int> playerMotm = {};

    for (var m in matches) {
      if (m.status == 'completed') {
        // Goals
        for (var scorer in m.scorers) {
          playerGoals[scorer] = (playerGoals[scorer] ?? 0) + 1;
        }
        // Cards
        for (var cardRecord in m.cards) {
          final pName = cardRecord.split(':')[0];
          playerHighlighter(playerCards, pName);
        }
        // MOTM
        if (m.motm != null) {
          playerMotm[m.motm!] = (playerMotm[m.motm!] ?? 0) + 1;
        }
      }
    }

    return teams.map((team) {
      final updatedPlayers = team.players.map((p) {
        return p.copyWith(
          goals: playerGoals[p.name] ?? 0,
          cards: playerCards[p.name] ?? 0,
          motm: playerMotm[p.name] ?? 0,
        );
      }).toList();

      return team.copyWith(players: updatedPlayers);
    }).toList();
  }

  void playerHighlighter(Map<String, int> map, String name) {
    map[name] = (map[name] ?? 0) + 1;
  }

  // Round-Robin fixtures generator
  List<TournamentMatch> _generateRoundRobinFixtures(List<TournamentTeam> teams) {
    final List<TournamentMatch> matches = [];
    final int teamCount = teams.length;
    int matchCounter = 1;

    // Standard round robin pairing algorithm (Berger tables)
    for (int i = 0; i < teamCount; i++) {
      for (int j = i + 1; j < teamCount; j++) {
        matches.add(
          TournamentMatch(
            id: 'match_auto_${matchCounter++}',
            homeTeamId: teams[i].id,
            awayTeamId: teams[j].id,
            date: DateTime.now().add(Duration(days: matchCounter)),
            status: 'scheduled',
            venue: 'Main Stadium Pitch ${matchCounter % 2 == 0 ? "A" : "B"}',
          ),
        );
      }
    }
    return matches;
  }

  // ─── Mock Data ─────────────────────────────────────────────────────────────

  List<Tournament> _getMockTournaments() {
    // Mock Teams
    final t1Players = const [
      TournamentPlayer(id: 'p1_1', name: 'Alex Thorne', jerseyNumber: 10, position: 'FWD'),
      TournamentPlayer(id: 'p1_2', name: 'Liam Vance', jerseyNumber: 8, position: 'MID'),
      TournamentPlayer(id: 'p1_3', name: 'Marcus Fox', jerseyNumber: 4, position: 'DEF'),
      TournamentPlayer(id: 'p1_4', name: 'Sam Taylor', jerseyNumber: 1, position: 'GK'),
    ];
    final t2Players = const [
      TournamentPlayer(id: 'p2_1', name: 'David Miller', jerseyNumber: 9, position: 'FWD'),
      TournamentPlayer(id: 'p2_2', name: 'Chris Evans', jerseyNumber: 7, position: 'MID'),
      TournamentPlayer(id: 'p2_3', name: 'Tom Hardy', jerseyNumber: 5, position: 'DEF'),
      TournamentPlayer(id: 'p2_4', name: 'John Doe', jerseyNumber: 12, position: 'GK'),
    ];
    final t3Players = const [
      TournamentPlayer(id: 'p3_1', name: 'Kylian C', jerseyNumber: 10, position: 'FWD'),
      TournamentPlayer(id: 'p3_2', name: 'Paul P', jerseyNumber: 6, position: 'MID'),
      TournamentPlayer(id: 'p3_3', name: 'Raphael V', jerseyNumber: 4, position: 'DEF'),
      TournamentPlayer(id: 'p3_4', name: 'Hugo L', jerseyNumber: 1, position: 'GK'),
    ];
    final t4Players = const [
      TournamentPlayer(id: 'p4_1', name: 'Harry K', jerseyNumber: 9, position: 'FWD'),
      TournamentPlayer(id: 'p4_2', name: 'Jude B', jerseyNumber: 10, position: 'MID'),
      TournamentPlayer(id: 'p4_3', name: 'John S', jerseyNumber: 5, position: 'DEF'),
      TournamentPlayer(id: 'p4_4', name: 'Jordan P', jerseyNumber: 1, position: 'GK'),
    ];

    final team1 = TournamentTeam(id: 'team_red', name: 'Red Panthers', logoUrl: '🐆', primaryColor: '0xFFEF4444', secondaryColor: '0xFF131318', players: t1Players);
    final team2 = TournamentTeam(id: 'team_blue', name: 'Blue Falcons', logoUrl: '🦅', primaryColor: '0xFF3B82F6', secondaryColor: '0xFF131318', players: t2Players);
    final team3 = TournamentTeam(id: 'team_green', name: 'Green Vipers', logoUrl: '🐍', primaryColor: '0xFF10B981', secondaryColor: '0xFF131318', players: t3Players);
    final team4 = TournamentTeam(id: 'team_gold', name: 'Golden Eagles', logoUrl: '🦅', primaryColor: '0xFFFFD700', secondaryColor: '0xFF131318', players: t4Players);

    final mockMatches = [
      TournamentMatch(
        id: 'm_1',
        homeTeamId: 'team_red',
        awayTeamId: 'team_blue',
        homeScore: 2,
        awayScore: 1,
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'completed',
        venue: 'Stadium Pitch A',
        scorers: ['Alex Thorne', 'Liam Vance', 'David Miller'],
        cards: ['Marcus Fox:Yellow'],
        motm: 'Alex Thorne',
      ),
      TournamentMatch(
        id: 'm_2',
        homeTeamId: 'team_green',
        awayTeamId: 'team_gold',
        homeScore: 0,
        awayScore: 0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'completed',
        venue: 'Stadium Pitch B',
        scorers: [],
        cards: [],
        motm: 'Hugo L',
      ),
      TournamentMatch(
        id: 'm_3',
        homeTeamId: 'team_red',
        awayTeamId: 'team_green',
        date: DateTime.now().add(const Duration(hours: 3)),
        status: 'scheduled',
        venue: 'Stadium Pitch A',
      ),
      TournamentMatch(
        id: 'm_4',
        homeTeamId: 'team_blue',
        awayTeamId: 'team_gold',
        date: DateTime.now().add(const Duration(days: 2)),
        status: 'scheduled',
        venue: 'Stadium Pitch B',
      ),
    ];

    // Build complete redone teams with calculated stats
    final initTeams = [team1, team2, team3, team4];
    final processedTeams = _recalculatePlayerStats(initTeams, mockMatches);

    return [
      Tournament(
        id: 'tour_1',
        name: 'PES Super League 2026',
        sport: 'football',
        format: 'league',
        description: 'Elite local PES mobile league with top local squad players competing for the annual shield.',
        location: 'Kochi Arena (Offline)',
        bannerUrl: 'assets/images/tournament-banner-1.png',
        winPts: 3,
        drawPts: 1,
        lossPts: 0,
        teams: processedTeams,
        matches: mockMatches,
        prizes: '🏆 Trophy + ₹5000 Shop Voucher',
        creatorId: 'mock-user-id',
      ),
      Tournament(
        id: 'tour_2',
        name: 'Mumbai Cup 2026',
        sport: 'football',
        format: 'knockout',
        description: 'Knockout cup championship for college teams in Mumbai district.',
        location: 'Cooperage Ground',
        bannerUrl: 'assets/images/tournament-banner-2.png',
        winPts: 3,
        drawPts: 0,
        lossPts: 0,
        teams: processedTeams.sublist(0, 2),
        matches: [
          TournamentMatch(
            id: 'm_cup_1',
            homeTeamId: 'team_red',
            awayTeamId: 'team_blue',
            date: DateTime.now().add(const Duration(days: 4)),
            status: 'scheduled',
            venue: 'Cooperage Ground',
          )
        ],
        prizes: '🎖️ Winner Gold Medals + Kit sponsor',
        creatorId: 'another-creator',
      ),
    ];
  }
}

class _TeamAccumulator {
  final TournamentTeam team;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int gf = 0;
  int ga = 0;
  int points = 0;
  List<String> form = [];

  _TeamAccumulator({required this.team});
}

final tournamentsProvider = NotifierProvider<TournamentsNotifier, TournamentsState>(() {
  return TournamentsNotifier();
});

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class Contest {
  final int id;
  final String name;
  final String gameType; // 'match_prediction', 'first_goal', 'formation', 'bracket', 'flags'
  final String joinCode;
  final String createdAt;
  final String tournamentName;
  final int memberCount;
  final String creatorName;
  final String creatorId;
  final bool isPublic;
  final int maxParticipants;
  final String joinDeadline;

  Contest({
    required this.id,
    required this.name,
    required this.gameType,
    required this.joinCode,
    required this.createdAt,
    required this.tournamentName,
    required this.memberCount,
    required this.creatorName,
    required this.creatorId,
    this.isPublic = false,
    required this.maxParticipants,
    required this.joinDeadline,
  });

  Contest copyWith({
    int? id,
    String? name,
    String? gameType,
    String? joinCode,
    String? createdAt,
    String? tournamentName,
    int? memberCount,
    String? creatorName,
    String? creatorId,
    bool? isPublic,
    int? maxParticipants,
    String? joinDeadline,
  }) {
    return Contest(
      id: id ?? this.id,
      name: name ?? this.name,
      gameType: gameType ?? this.gameType,
      joinCode: joinCode ?? this.joinCode,
      createdAt: createdAt ?? this.createdAt,
      tournamentName: tournamentName ?? this.tournamentName,
      memberCount: memberCount ?? this.memberCount,
      creatorName: creatorName ?? this.creatorName,
      creatorId: creatorId ?? this.creatorId,
      isPublic: isPublic ?? this.isPublic,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      joinDeadline: joinDeadline ?? this.joinDeadline,
    );
  }

  factory Contest.fromJson(Map<String, dynamic> json) {
    // Check if visibility string is 'public'
    final isPublicVal = json['isPublic'] ?? (json['visibility'] == 'public');
    
    return Contest(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      gameType: json['game_type'] ?? json['gameType'] ?? 'match_prediction',
      joinCode: json['join_code'] ?? json['joinCode'] ?? '',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      tournamentName: json['tournamentName'] ?? 'World Cup 2026',
      memberCount: json['memberCount'] ?? json['member_count'] ?? 1,
      creatorName: json['creator_name'] ?? json['creatorName'] ?? 'System',
      creatorId: json['creator_id'] ?? json['creatorId'] ?? '',
      isPublic: isPublicVal,
      maxParticipants: json['max_participants'] ?? json['maxParticipants'] ?? 100,
      joinDeadline: json['join_deadline'] ?? json['joinDeadline'] ?? '',
    );
  }
}

class ContestsState {
  final List<Contest> activeContests;
  final List<Contest> globalContests;
  final bool isLoading;
  final String? error;

  ContestsState({
    required this.activeContests,
    required this.globalContests,
    this.isLoading = false,
    this.error,
  });

  ContestsState copyWith({
    List<Contest>? activeContests,
    List<Contest>? globalContests,
    bool? isLoading,
    String? error,
  }) {
    return ContestsState(
      activeContests: activeContests ?? this.activeContests,
      globalContests: globalContests ?? this.globalContests,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ContestsNotifier extends Notifier<ContestsState> {
  @override
  ContestsState build() {
    Future.microtask(() => loadContests());
    return ContestsState(activeContests: [], globalContests: [], isLoading: false);
  }

  List<Contest> _getMockActiveContests() {
    return [
      Contest(
        id: 2,
        name: "Friends & Family League",
        gameType: "match_prediction",
        joinCode: "FFL202",
        createdAt: "2026-06-01T10:00:00Z",
        tournamentName: "World Cup 2026",
        memberCount: 8,
        creatorName: "Alex Thorne",
        creatorId: "mock-creator-id-2",
        isPublic: false,
        maxParticipants: 20,
        joinDeadline: "2026-06-25T18:00:00Z",
      ),
      Contest(
        id: 3,
        name: "Tactical Geniuses",
        gameType: "formation",
        joinCode: "TACTIC",
        createdAt: "2026-06-02T12:00:00Z",
        tournamentName: "World Cup 2026",
        memberCount: 12,
        creatorName: "Liam Vance",
        creatorId: "mock-creator-id-3",
        isPublic: false,
        maxParticipants: 15,
        joinDeadline: "2026-06-24T12:00:00Z",
      ),
      Contest(
        id: 4,
        name: "Minute of Madness",
        gameType: "first_goal",
        joinCode: "MADMIN",
        createdAt: "2026-06-03T15:30:00Z",
        tournamentName: "World Cup 2026",
        memberCount: 15,
        creatorName: "Sophia Chen",
        creatorId: "mock-creator-id-4",
        isPublic: false,
        maxParticipants: 50,
        joinDeadline: "2026-06-29T20:00:00Z",
      ),
    ];
  }

  List<Contest> _getMockGlobalContests() {
    return [
      Contest(
        id: 1,
        name: "World Cup 2026 Ultimate Arena",
        gameType: "match_prediction",
        joinCode: "GLOB26",
        createdAt: "2026-05-15T09:00:00Z",
        tournamentName: "World Cup 2026",
        memberCount: 1254,
        creatorName: "System",
        creatorId: "system-id",
        isPublic: true,
        maxParticipants: 5000,
        joinDeadline: "2026-07-10T23:59:59Z",
      ),
    ];
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = math.Random();
    return List.generate(6, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> loadContests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = sb.Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        state = ContestsState(
          activeContests: _getMockActiveContests(),
          globalContests: _getMockGlobalContests(),
          isLoading: false,
        );
        return;
      }

      // Fetch joined contests via user_contest_participants relation
      // user_contest_participants table: user_id, contest_id, joined_at, total_pts, rank
      final participantsData = await client
          .from('user_contest_participants')
          .select('*, user_contests(*)')
          .eq('user_id', currentUser.id);

      final List<Contest> activeList = [];
      for (var row in (participantsData as List)) {
        if (row['user_contests'] != null) {
          final contestData = Map<String, dynamic>.from(row['user_contests']);
          
          // Get member count separately
          final membersCountRes = await client
              .from('user_contest_participants')
              .select('id')
              .eq('contest_id', contestData['id']);
          
          contestData['member_count'] = (membersCountRes as List).length;
          
          activeList.add(Contest.fromJson(contestData));
        }
      }

      // Fetch all public discoverable contests
      final publicContestsData = await client
          .from('user_contests')
          .select()
          .eq('visibility', 'public');

      final List<Contest> globalList = [];
      for (var row in (publicContestsData as List)) {
        final contestData = Map<String, dynamic>.from(row);
        
        final membersCountRes = await client
            .from('user_contest_participants')
            .select('id')
            .eq('contest_id', contestData['id']);
        contestData['member_count'] = (membersCountRes as List).length;

        globalList.add(Contest.fromJson(contestData));
      }

      state = ContestsState(
        activeContests: activeList,
        globalContests: globalList,
        isLoading: false,
      );
    } catch (e) {
      debugPrint("Load Contests failed, fallback to mock: $e");
      state = ContestsState(
        activeContests: _getMockActiveContests(),
        globalContests: _getMockGlobalContests(),
        isLoading: false,
      );
    }
  }

  Future<bool> joinContest(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = sb.Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      // 1. Fetch contest by join code
      final contestRes = await client
          .from('user_contests')
          .select()
          .eq('join_code', code)
          .maybeSingle();

      if (contestRes == null) {
        state = state.copyWith(isLoading: false, error: "Contest not found with code $code");
        return false;
      }

      final contest = Contest.fromJson(contestRes);

      // 2. Check if already joined
      final checkJoined = await client
          .from('user_contest_participants')
          .select()
          .eq('contest_id', contest.id)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (checkJoined != null) {
        state = state.copyWith(isLoading: false, error: "You are already a member of this contest.");
        return false;
      }

      // 3. Check member count limit
      final membersCountRes = await client
          .from('user_contest_participants')
          .select('id')
          .eq('contest_id', contest.id);
      
      final currentMembers = (membersCountRes as List).length;
      if (currentMembers >= contest.maxParticipants) {
        state = state.copyWith(isLoading: false, error: "This contest has reached its participant limit.");
        return false;
      }

      // 4. Check join deadline
      if (contest.joinDeadline.isNotEmpty) {
        final deadline = DateTime.tryParse(contest.joinDeadline);
        if (deadline != null && deadline.isBefore(DateTime.now())) {
          state = state.copyWith(isLoading: false, error: "The join deadline for this contest has passed.");
          return false;
        }
      }

      // 5. Insert participant record
      await client.from('user_contest_participants').insert({
        'contest_id': contest.id,
        'user_id': currentUser.id,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
        'total_pts': 0,
        'rank': currentMembers + 1,
        'status': 'active',
      });

      await loadContests();
      return true;
    } catch (e) {
      debugPrint("Join Contest Supabase failed, simulating offline fallback: $e");
      await Future.delayed(const Duration(milliseconds: 800));

      final allGlobal = [...state.globalContests];
      Contest matchedGlobal;
      try {
        matchedGlobal = allGlobal.firstWhere((gc) => gc.joinCode == code);
      } catch (_) {
        matchedGlobal = Contest(
          id: DateTime.now().millisecondsSinceEpoch,
          name: "Private Contest ($code)",
          gameType: "match_prediction",
          joinCode: code,
          createdAt: DateTime.now().toIso8601String(),
          tournamentName: "World Cup 2026",
          memberCount: 2,
          creatorName: "Inviter",
          creatorId: "some-creator-id",
          isPublic: false,
          maxParticipants: 10,
          joinDeadline: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        );
      }

      if (state.activeContests.any((c) => c.joinCode == code)) {
        state = state.copyWith(isLoading: false, error: "You are already in this contest.");
        return false;
      }

      state = ContestsState(
        activeContests: [matchedGlobal.copyWith(memberCount: matchedGlobal.memberCount + 1), ...state.activeContests],
        globalContests: state.globalContests,
        isLoading: false,
      );
      return true;
    }
  }

  Future<bool> createContest({
    required String name,
    required String gameType,
    required bool isPublic,
    required int maxParticipants,
    required DateTime joinDeadline,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final joinCode = _generateJoinCode();

    try {
      final client = sb.Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      // Fetch creator name from profile
      final profile = await client.from('profiles').select('name').eq('id', currentUser.id).maybeSingle();
      final creatorName = profile?['name'] ?? 'Guest Predictor';

      // 1. Insert into user_contests
      final inserted = await client.from('user_contests').insert({
        'name': name,
        'game_type': gameType,
        'visibility': isPublic ? 'public' : 'private',
        'max_participants': maxParticipants,
        'join_deadline': joinDeadline.toUtc().toIso8601String(),
        'join_code': joinCode,
        'creator_id': currentUser.id,
        'creator_name': creatorName,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      final contestId = inserted['id'];

      // 2. Add creator as first participant
      await client.from('user_contest_participants').insert({
        'contest_id': contestId,
        'user_id': currentUser.id,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
        'total_pts': 0,
        'rank': 1,
        'status': 'creator',
      });

      await loadContests();
      return true;
    } catch (e) {
      debugPrint("Create Contest Supabase failed, simulating offline fallback: $e");
      await Future.delayed(const Duration(milliseconds: 800));

      final newContest = Contest(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        gameType: gameType,
        joinCode: joinCode,
        createdAt: DateTime.now().toIso8601String(),
        tournamentName: "World Cup 2026",
        memberCount: 1,
        creatorName: "Alex Thorne", // Mock creator
        creatorId: "mock-user-id",
        isPublic: isPublic,
        maxParticipants: maxParticipants,
        joinDeadline: joinDeadline.toIso8601String(),
      );

      state = ContestsState(
        activeContests: [newContest, ...state.activeContests],
        globalContests: isPublic ? [newContest, ...state.globalContests] : state.globalContests,
        isLoading: false,
      );
      return true;
    }
  }

  Future<void> removeParticipant({required int contestId, required String userId}) async {
    try {
      final client = sb.Supabase.instance.client;
      await client
          .from('user_contest_participants')
          .delete()
          .eq('contest_id', contestId)
          .eq('user_id', userId);
      
      await loadContests();
    } catch (e) {
      debugPrint("Remove Participant Supabase failed, simulating locally: $e");
      // Fallback local memory state
      final updatedActive = state.activeContests.map((c) {
        if (c.id == contestId) {
          return c.copyWith(memberCount: math.max(1, c.memberCount - 1));
        }
        return c;
      }).toList();
      state = state.copyWith(activeContests: updatedActive);
    }
  }
}

final contestsProvider = NotifierProvider<ContestsNotifier, ContestsState>(() {
  return ContestsNotifier();
});

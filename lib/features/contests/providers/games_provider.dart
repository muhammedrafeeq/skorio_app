import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

class GamesState {
  final Map<String, int> dailyPlayCounts;
  final Map<String, int> dailyLimits;
  final bool isLoading;
  final String? error;

  GamesState({
    required this.dailyPlayCounts,
    required this.dailyLimits,
    required this.isLoading,
    this.error,
  });

  GamesState copyWith({
    Map<String, int>? dailyPlayCounts,
    Map<String, int>? dailyLimits,
    bool? isLoading,
    String? error,
  }) {
    return GamesState(
      dailyPlayCounts: dailyPlayCounts ?? this.dailyPlayCounts,
      dailyLimits: dailyLimits ?? this.dailyLimits,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class GamesNotifier extends Notifier<GamesState> {
  @override
  GamesState build() {
    // Proactively load on initialization
    Future.microtask(() => loadDailyPlayCounts());
    return GamesState(
      dailyPlayCounts: {'trivia': 0, 'penalty': 0, 'who_am_i': 0, 'flags': 0},
      dailyLimits: {'trivia': 5, 'penalty': 5, 'who_am_i': 5, 'flags': 5},
      isLoading: true,
    );
  }

  Future<void> loadDailyPlayCounts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final now = DateTime.now();
      // Use local timezone start of day converted to UTC
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

      // Fetch Trivia sessions count
      final triviaRes = await client
          .from('quiz_sessions')
          .select('id')
          .eq('user_id', currentUser.id)
          .gte('played_at', startOfDay);

      // Fetch Penalty sessions count
      final penaltyRes = await client
          .from('game_scores')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('game_id', 'penalty')
          .gte('played_at', startOfDay);

      // Fetch Who Am I sessions count
      final whoAmIRes = await client
          .from('game_scores')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('game_id', 'who_am_i')
          .gte('played_at', startOfDay);

      // Fetch Flags sessions count
      final flagsRes = await client
          .from('game_scores')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('game_id', 'flags')
          .gte('played_at', startOfDay);

      final triviaCount = (triviaRes as List).length;
      final penaltyCount = (penaltyRes as List).length;
      final whoAmICount = (whoAmIRes as List).length;
      final flagsCount = (flagsRes as List).length;

      state = GamesState(
        dailyPlayCounts: {
          'trivia': triviaCount,
          'penalty': penaltyCount,
          'who_am_i': whoAmICount,
          'flags': flagsCount,
        },
        dailyLimits: {'trivia': 5, 'penalty': 5, 'who_am_i': 5, 'flags': 5},
        isLoading: false,
      );
    } catch (e) {
      debugPrint("Failed to fetch daily play counts from Supabase: $e");
      // Fallback: Keep local counts as is (for offline/local dev support)
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> recordTriviaSession({
    required int score,
    required int correctCount,
    required String difficulty,
  }) async {
    try {
      // 1. Save to local/remote profile points
      ref.read(authProvider.notifier).addPoints(score);

      // 2. Increment local daily counter
      final currentCounts = Map<String, int>.from(state.dailyPlayCounts);
      currentCounts['trivia'] = (currentCounts['trivia'] ?? 0) + 1;
      state = state.copyWith(dailyPlayCounts: currentCounts);

      // 3. Persist session in Supabase
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        await client.from('quiz_sessions').insert({
          'user_id': currentUser.id,
          'score': score,
          'correct_count': correctCount,
          'difficulty': difficulty,
          'played_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      return true;
    } catch (e) {
      debugPrint("Failed to record trivia session in Supabase: $e");
      // Returns true to proceed with local mock success experience
      return true;
    }
  }

  Future<bool> recordPenaltySession({
    required int score,
    required int goals,
  }) async {
    try {
      // 1. Save to local/remote profile points
      ref.read(authProvider.notifier).addPoints(score);
      ref.read(authProvider.notifier).awardXp(amount: 10, action: 'Penalty Shootout Game Played');

      // 2. Increment local daily counter
      final currentCounts = Map<String, int>.from(state.dailyPlayCounts);
      currentCounts['penalty'] = (currentCounts['penalty'] ?? 0) + 1;
      state = state.copyWith(dailyPlayCounts: currentCounts);

      // 3. Persist session in Supabase
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        await client.from('game_scores').insert({
          'user_id': currentUser.id,
          'game_id': 'penalty',
          'score': score,
          'goals_count': goals,
          'played_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      return true;
    } catch (e) {
      debugPrint("Failed to record penalty session in Supabase: $e");
      // Returns true to proceed with local mock success experience
      return true;
    }
  }

  Future<bool> recordWhoAmISession({
    required int score,
  }) async {
    try {
      // 1. Save to local/remote profile points
      ref.read(authProvider.notifier).addPoints(score);
      ref.read(authProvider.notifier).awardXp(amount: 10, action: 'Who Am I Game Played');

      // 2. Increment local daily counter
      final currentCounts = Map<String, int>.from(state.dailyPlayCounts);
      currentCounts['who_am_i'] = (currentCounts['who_am_i'] ?? 0) + 1;
      state = state.copyWith(dailyPlayCounts: currentCounts);

      // 3. Persist session in Supabase
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        await client.from('game_scores').insert({
          'user_id': currentUser.id,
          'game_id': 'who_am_i',
          'score': score,
          'played_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      return true;
    } catch (e) {
      debugPrint("Failed to record who_am_i session in Supabase: $e");
      // Returns true to proceed with local mock success experience
      return true;
    }
  }

  Future<bool> recordFlagsSession({
    required int score,
  }) async {
    try {
      // 1. Save to local/remote profile points
      ref.read(authProvider.notifier).addPoints(score);

      // 2. Increment local daily counter
      final currentCounts = Map<String, int>.from(state.dailyPlayCounts);
      currentCounts['flags'] = (currentCounts['flags'] ?? 0) + 1;
      state = state.copyWith(dailyPlayCounts: currentCounts);

      // 3. Persist session in Supabase
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        await client.from('game_scores').insert({
          'user_id': currentUser.id,
          'game_id': 'flags',
          'score': score,
          'played_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      return true;
    } catch (e) {
      debugPrint("Failed to record flags session in Supabase: $e");
      // Returns true to proceed with local mock success experience
      return true;
    }
  }
}

final gamesProvider = NotifierProvider<GamesNotifier, GamesState>(() {
  return GamesNotifier();
});

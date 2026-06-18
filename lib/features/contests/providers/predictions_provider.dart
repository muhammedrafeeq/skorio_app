import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchQuestion {
  final String id;
  final String matchId;
  final String type; // 'scoreline', 'winner', 'top_scorer'
  final String label;
  final int points;

  MatchQuestion({
    required this.id,
    required this.matchId,
    required this.type,
    required this.label,
    required this.points,
  });

  factory MatchQuestion.fromJson(Map<String, dynamic> json) {
    return MatchQuestion(
      id: json['id']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? '',
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      points: json['points'] ?? 2,
    );
  }
}

class MatchPrediction {
  final String id;
  final String questionId;
  final String answer;

  MatchPrediction({
    required this.id,
    required this.questionId,
    required this.answer,
  });

  factory MatchPrediction.fromJson(Map<String, dynamic> json) {
    return MatchPrediction(
      id: json['id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

class MatchPredictionsState {
  final bool isLoading;
  final String? error;
  final List<MatchQuestion> questions;
  final List<MatchPrediction> userPredictions;

  MatchPredictionsState({
    required this.isLoading,
    this.error,
    required this.questions,
    required this.userPredictions,
  });

  MatchPredictionsState copyWith({
    bool? isLoading,
    String? error,
    List<MatchQuestion>? questions,
    List<MatchPrediction>? userPredictions,
  }) {
    return MatchPredictionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      questions: questions ?? this.questions,
      userPredictions: userPredictions ?? this.userPredictions,
    );
  }
}

class MatchPredictionsNotifier extends Notifier<MatchPredictionsState> {
  final String matchId;
  MatchPredictionsNotifier(this.matchId);

  @override
  MatchPredictionsState build() {
    Future.microtask(() => loadPredictionsAndQuestions());
    return MatchPredictionsState(
      isLoading: true,
      questions: [],
      userPredictions: [],
    );
  }

  Future<void> loadPredictionsAndQuestions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      
      // 1. Fetch questions for this match
      final questionsData = await client
          .from('questions')
          .select()
          .eq('match_id', matchId);
      final listQuestions = (questionsData as List)
          .map((q) => MatchQuestion.fromJson(q))
          .toList();

      if (listQuestions.isEmpty) {
        if (matchId.startsWith('cricket')) {
          listQuestions.addAll([
            MatchQuestion(id: 'q_toss_$matchId', matchId: matchId, type: 'toss_winner', label: 'Toss Winner', points: 2),
            MatchQuestion(id: 'q_winner_$matchId', matchId: matchId, type: 'match_winner', label: 'Match Winner', points: 2),
            MatchQuestion(id: 'q_batsman_$matchId', matchId: matchId, type: 'top_batsman', label: 'Top Batsman', points: 3),
            MatchQuestion(id: 'q_bowler_$matchId', matchId: matchId, type: 'top_bowler', label: 'Top Bowler', points: 3),
            MatchQuestion(id: 'q_range_$matchId', matchId: matchId, type: 'score_range', label: '1st Innings Score Range', points: 4),
          ]);
        } else {
          listQuestions.addAll([
            MatchQuestion(id: 'q_score_$matchId', matchId: matchId, type: 'scoreline', label: 'Exact Scoreline', points: 4),
            MatchQuestion(id: 'q_winner_$matchId', matchId: matchId, type: 'winner', label: 'Winner', points: 2),
            MatchQuestion(id: 'q_scorer_$matchId', matchId: matchId, type: 'top_scorer', label: 'First Scorer', points: 2),
          ]);
        }
      }

      List<MatchPrediction> listPredictions = [];
      if (currentUser != null && listQuestions.isNotEmpty) {
        // 2. Fetch user's predictions for these questions
        final questionIds = listQuestions.map((q) => q.id).toList();
        final predictionsData = await client
            .from('predictions')
            .select()
            .eq('user_id', currentUser.id)
            .inFilter('question_id', questionIds);
        
        listPredictions = (predictionsData as List)
            .map((p) => MatchPrediction.fromJson(p))
            .toList();
      }

      state = MatchPredictionsState(
        isLoading: false,
        questions: listQuestions,
        userPredictions: listPredictions,
      );
    } catch (e) {
      debugPrint("Failed to load predictions from Supabase: $e");
      // Fallback: default questions if database is not fully set up
      final List<MatchQuestion> fallbackQuestions;
      if (matchId.startsWith('cricket')) {
        fallbackQuestions = [
          MatchQuestion(id: 'q_toss_$matchId', matchId: matchId, type: 'toss_winner', label: 'Toss Winner', points: 2),
          MatchQuestion(id: 'q_winner_$matchId', matchId: matchId, type: 'match_winner', label: 'Match Winner', points: 2),
          MatchQuestion(id: 'q_batsman_$matchId', matchId: matchId, type: 'top_batsman', label: 'Top Batsman', points: 3),
          MatchQuestion(id: 'q_bowler_$matchId', matchId: matchId, type: 'top_bowler', label: 'Top Bowler', points: 3),
          MatchQuestion(id: 'q_range_$matchId', matchId: matchId, type: 'score_range', label: '1st Innings Score Range', points: 4),
        ];
      } else {
        fallbackQuestions = [
          MatchQuestion(id: 'q_score_$matchId', matchId: matchId, type: 'scoreline', label: 'Exact Scoreline', points: 4),
          MatchQuestion(id: 'q_winner_$matchId', matchId: matchId, type: 'winner', label: 'Winner', points: 2),
          MatchQuestion(id: 'q_scorer_$matchId', matchId: matchId, type: 'top_scorer', label: 'First Scorer', points: 2),
        ];
      }
      state = MatchPredictionsState(
        isLoading: false,
        questions: fallbackQuestions,
        userPredictions: [],
      );
    }
  }

  Future<bool> savePredictions({
    required int homeScore,
    required int awayScore,
    String? winner,
    String? firstScorer,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) throw Exception("User must be logged in to predict");

      // Scoreline answer format: "2-1"
      final scorelineAnswer = "$homeScore-$awayScore";
      
      // Get respective question IDs
      final scorelineQ = state.questions.firstWhere((q) => q.type == 'scoreline');
      final winnerQ = state.questions.firstWhere((q) => q.type == 'winner');
      final scorerQ = state.questions.firstWhere((q) => q.type == 'top_scorer');

      final List<Map<String, dynamic>> upserts = [
        {
          'user_id': currentUser.id,
          'match_id': matchId,
          'question_id': scorelineQ.id,
          'answer': scorelineAnswer,
        }
      ];

      if (winner != null) {
        upserts.add({
          'user_id': currentUser.id,
          'match_id': matchId,
          'question_id': winnerQ.id,
          'answer': winner,
        });
      }

      if (firstScorer != null) {
        upserts.add({
          'user_id': currentUser.id,
          'match_id': matchId,
          'question_id': scorerQ.id,
          'answer': firstScorer,
        });
      }

      // Perform upserts on predictions table
      for (final data in upserts) {
        await client.from('predictions').upsert(data, onConflict: 'user_id,question_id');
      }

      // Reload
      await loadPredictionsAndQuestions();
      return true;
    } catch (e) {
      debugPrint("Failed to save predictions: $e");
      state = state.copyWith(isLoading: false, error: "Failed to save: $e");
      return false;
    }
  }

  Future<bool> saveCricketPredictions({
    required String tossWinner,
    required String matchWinner,
    required String topBatsman,
    required String topBowler,
    required String scoreRange,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) throw Exception("User must be logged in to predict");

      final tossQ = state.questions.firstWhere((q) => q.type == 'toss_winner');
      final winnerQ = state.questions.firstWhere((q) => q.type == 'match_winner');
      final batsmanQ = state.questions.firstWhere((q) => q.type == 'top_batsman');
      final bowlerQ = state.questions.firstWhere((q) => q.type == 'top_bowler');
      final rangeQ = state.questions.firstWhere((q) => q.type == 'score_range');

      final List<Map<String, dynamic>> upserts = [
        {
          'user_id': currentUser.id,
          'match_id': matchId,
          'question_id': tossQ.id,
          'answer': tossWinner,
        },
        {
          'user_id': currentUser.id,
          'match_id': matchId,
          'question_id': winnerQ.id,
          'answer': matchWinner,
        },
        {
          'user_id': currentUser.id,
          'match_id': matchId,
          'question_id': batsmanQ.id,
          'answer': topBatsman,
        },
        {
          'user_id': currentUser.id,
          'match_id': matchId,
          'question_id': bowlerQ.id,
          'answer': topBowler,
        },
        {
          'user_id': currentUser.id,
          'match_id': matchId,
          'question_id': rangeQ.id,
          'answer': scoreRange,
        },
      ];

      for (final data in upserts) {
        await client.from('predictions').upsert(data, onConflict: 'user_id,question_id');
      }

      await loadPredictionsAndQuestions();
      return true;
    } catch (e) {
      debugPrint("Failed to save cricket predictions: $e");
      state = state.copyWith(isLoading: false, error: "Failed to save cricket predictions: $e");
      return false;
    }
  }
}

final matchPredictionsProvider = NotifierProvider.family<
    MatchPredictionsNotifier, MatchPredictionsState, String>((matchId) {
  return MatchPredictionsNotifier(matchId);
});

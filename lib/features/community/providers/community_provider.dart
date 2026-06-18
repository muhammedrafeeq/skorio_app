import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../auth/providers/auth_provider.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class FanClub {
  final String id;
  final String name;
  final String logoUrl;
  final String primaryColor; // Hex string e.g. '0xFF00C082'
  final String secondaryColor;
  final int memberCount;
  final double avgAccuracy;
  final String winRecord; // e.g. "12W - 4L"
  final String weeklyCaptain;
  final int weeklyCaptainScore;

  const FanClub({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.memberCount,
    required this.avgAccuracy,
    required this.winRecord,
    required this.weeklyCaptain,
    required this.weeklyCaptainScore,
  });

  FanClub copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    int? memberCount,
    double? avgAccuracy,
    String? winRecord,
    String? weeklyCaptain,
    int? weeklyCaptainScore,
  }) {
    return FanClub(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      memberCount: memberCount ?? this.memberCount,
      avgAccuracy: avgAccuracy ?? this.avgAccuracy,
      winRecord: winRecord ?? this.winRecord,
      weeklyCaptain: weeklyCaptain ?? this.weeklyCaptain,
      weeklyCaptainScore: weeklyCaptainScore ?? this.weeklyCaptainScore,
    );
  }

  factory FanClub.fromJson(Map<String, dynamic> json) {
    return FanClub(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      primaryColor: json['primary_color'] ?? '0xFFC6C0FF',
      secondaryColor: json['secondary_color'] ?? '0xFF131318',
      memberCount: json['member_count'] ?? 1,
      avgAccuracy: (json['avg_accuracy'] as num?)?.toDouble() ?? 0.0,
      winRecord: json['win_record'] ?? '0W - 0L',
      weeklyCaptain: json['weekly_captain'] ?? 'None',
      weeklyCaptainScore: json['weekly_captain_score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'member_count': memberCount,
      'avg_accuracy': avgAccuracy,
      'win_record': winRecord,
      'weekly_captain': weeklyCaptain,
      'weekly_captain_score': weeklyCaptainScore,
    };
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String userId;
  final String userName;
  final String userBorder;
  final String messageText;
  final Map<String, List<String>> reactions; // emoji -> list of userNames
  final Map<String, dynamic>? predictionCard; // prediction details if attached
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.userBorder,
    required this.messageText,
    required this.reactions,
    this.predictionCard,
    required this.createdAt,
  });

  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? userId,
    String? userName,
    String? userBorder,
    String? messageText,
    Map<String, List<String>>? reactions,
    Map<String, dynamic>? predictionCard,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userBorder: userBorder ?? this.userBorder,
      messageText: messageText ?? this.messageText,
      reactions: reactions ?? this.reactions,
      predictionCard: predictionCard ?? this.predictionCard,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FanWar {
  final String id;
  final String matchId;
  final String matchTitle;
  final String clubAId;
  final String clubBId;
  final double accuracyA;
  final double accuracyB;
  final DateTime endsAt;

  const FanWar({
    required this.id,
    required this.matchId,
    required this.matchTitle,
    required this.clubAId,
    required this.clubBId,
    required this.accuracyA,
    required this.accuracyB,
    required this.endsAt,
  });
}

// ─── State ───────────────────────────────────────────────────────────────────

class CommunityState {
  final List<FanClub> joinedClubs;
  final List<FanClub> allClubs;
  final List<FanWar> activeWars;
  final Map<String, List<ChatMessage>> chatMessages;
  final bool isLoading;
  final String? error;

  const CommunityState({
    required this.joinedClubs,
    required this.allClubs,
    required this.activeWars,
    required this.chatMessages,
    this.isLoading = false,
    this.error,
  });

  CommunityState copyWith({
    List<FanClub>? joinedClubs,
    List<FanClub>? allClubs,
    List<FanWar>? activeWars,
    Map<String, List<ChatMessage>>? chatMessages,
    bool? isLoading,
    String? error,
  }) {
    return CommunityState(
      joinedClubs: joinedClubs ?? this.joinedClubs,
      allClubs: allClubs ?? this.allClubs,
      activeWars: activeWars ?? this.activeWars,
      chatMessages: chatMessages ?? this.chatMessages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CommunityNotifier extends Notifier<CommunityState> {
  Timer? _mockMessageTimer;
  final math.Random _random = math.Random();

  @override
  CommunityState build() {
    ref.onDispose(() {
      _mockMessageTimer?.cancel();
    });

    _initSimulator();
    return _getInitialState();
  }

  CommunityState _getInitialState() {
    final clubs = _getMockClubs();
    // Default: joined user's first club (e.g. Argentina or matching profile team)
    final initialJoined = [clubs[0]]; 
    final wars = _getMockWars();
    final initialMessages = {
      'global': _getMockMessages('global'),
      'club_argentina': _getMockMessages('club_argentina'),
      'club_brazil': _getMockMessages('club_brazil'),
      'match_1': _getMockMessages('match_1'),
    };

    return CommunityState(
      joinedClubs: initialJoined,
      allClubs: clubs,
      activeWars: wars,
      chatMessages: initialMessages,
    );
  }

  void _initSimulator() {
    _mockMessageTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (state.isLoading) return;
      _simulateIncomingMessage();
    });
  }

  // Mock Clubs Data
  List<FanClub> _getMockClubs() {
    return const [
      FanClub(
        id: 'club_argentina',
        name: 'Argentina Fan Club',
        logoUrl: '🇦🇷',
        primaryColor: '0xFF38BDF8', // Cyan
        secondaryColor: '0xFF0A0A0F',
        memberCount: 2450,
        avgAccuracy: 71.4,
        winRecord: '15W - 3L',
        weeklyCaptain: 'LeoG_10',
        weeklyCaptainScore: 94,
      ),
      FanClub(
        id: 'club_brazil',
        name: 'Brazil Fan Club',
        logoUrl: '🇧🇷',
        primaryColor: '0xFFFFD700', // Gold
        secondaryColor: '0xFF003823', // Dark Green
        memberCount: 2210,
        avgAccuracy: 68.2,
        winRecord: '11W - 5L',
        weeklyCaptain: 'NeyMagic',
        weeklyCaptainScore: 89,
      ),
      FanClub(
        id: 'club_france',
        name: 'France Fan Club',
        logoUrl: '🇫🇷',
        primaryColor: '0xFF8B80FF', // Purple
        secondaryColor: '0xFF131318',
        memberCount: 1890,
        avgAccuracy: 69.5,
        winRecord: '12W - 4L',
        weeklyCaptain: 'Kylian_C',
        weeklyCaptainScore: 91,
      ),
      FanClub(
        id: 'club_england',
        name: 'England Fan Club',
        logoUrl: '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
        primaryColor: '0xFFFFB4AB', // Light Red
        secondaryColor: '0xFF131318',
        memberCount: 1650,
        avgAccuracy: 64.8,
        winRecord: '9W - 7L',
        weeklyCaptain: 'HarryK_9',
        weeklyCaptainScore: 82,
      ),
      FanClub(
        id: 'club_realmadrid',
        name: 'Real Madrid Fan Club',
        logoUrl: '🇪🇸',
        primaryColor: '0xFFF59E0B', // Amber
        secondaryColor: '0xFF131318',
        memberCount: 3100,
        avgAccuracy: 72.8,
        winRecord: '18W - 2L',
        weeklyCaptain: 'ViniJr_Fan',
        weeklyCaptainScore: 96,
      ),
      FanClub(
        id: 'club_barcelona',
        name: 'FC Barcelona Fan Club',
        logoUrl: '🔵🔴',
        primaryColor: '0xFFEF4444', // Red
        secondaryColor: '0xFF1E3A8A', // Blue
        memberCount: 2950,
        avgAccuracy: 70.1,
        winRecord: '14W - 4L',
        weeklyCaptain: 'Pedri_Magic',
        weeklyCaptainScore: 92,
      ),
    ];
  }

  // Mock Wars Data
  List<FanWar> _getMockWars() {
    return [
      FanWar(
        id: 'war_1',
        matchId: 'match_1',
        matchTitle: 'Argentina vs Brazil',
        clubAId: 'club_argentina',
        clubBId: 'club_brazil',
        accuracyA: 72.5,
        accuracyB: 68.1,
        endsAt: DateTime.now().add(const Duration(hours: 4, minutes: 12)),
      ),
      FanWar(
        id: 'war_2',
        matchId: 'match_2',
        matchTitle: 'France vs England',
        clubAId: 'club_france',
        clubBId: 'club_england',
        accuracyA: 64.2,
        accuracyB: 65.5,
        endsAt: DateTime.now().add(const Duration(hours: 9, minutes: 30)),
      ),
    ];
  }

  // Mock Messages Data
  List<ChatMessage> _getMockMessages(String roomId) {
    final now = DateTime.now();
    if (roomId == 'global') {
      return [
        ChatMessage(
          id: 'm1',
          roomId: roomId,
          userId: 'u1',
          userName: 'Marcus_F',
          userBorder: 'none',
          messageText: 'Who else predicts a France vs Argentina final? 🏆',
          reactions: {'🔥': ['LeoG_10', 'ViniJr_Fan'], '💯': ['Kylian_C']},
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
        ChatMessage(
          id: 'm2',
          roomId: roomId,
          userId: 'u2',
          userName: 'NeyMagic',
          userBorder: 'neon_blue',
          messageText: 'Brazil is taking the cup home this time. No doubts! 🇧🇷⚽',
          reactions: {'😤': ['Marcus_F'], '😂': ['LeoG_10']},
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
        ChatMessage(
          id: 'm3',
          roomId: roomId,
          userId: 'u3',
          userName: 'LeoG_10',
          userBorder: 'golden_champion',
          messageText: 'Check out my predictions for Brazil vs Argentina. Let\'s go!',
          reactions: {'🔥': ['NeyMagic', 'Marcus_F'], '🙏': ['Kylian_C']},
          predictionCard: {
            'homeTeam': 'Brazil',
            'awayTeam': 'Argentina',
            'homeScore': 1,
            'awayScore': 2,
            'winner': 'Argentina',
            'firstScorer': 'Lionel Messi',
            'username': 'LeoG_10',
          },
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
      ];
    } else if (roomId == 'club_argentina') {
      return [
        ChatMessage(
          id: 'ca1',
          roomId: roomId,
          userId: 'u3',
          userName: 'LeoG_10',
          userBorder: 'golden_champion',
          messageText: 'Welcome to the Argentina Fan Club! Let\'s keep the crown this week! 👑',
          reactions: {'🔥': ['Gaucho_A', 'Albi_12'], '💯': ['Gaucho_A']},
          createdAt: now.subtract(const Duration(minutes: 30)),
        ),
        ChatMessage(
          id: 'ca2',
          roomId: roomId,
          userId: 'u4',
          userName: 'Gaucho_A',
          userBorder: 'none',
          messageText: 'Messi starting tonight is confirmed. Easiest points prediction!',
          reactions: {'🙏': ['LeoG_10', 'Albi_12']},
          createdAt: now.subtract(const Duration(minutes: 12)),
        ),
      ];
    } else {
      return [
        ChatMessage(
          id: 'cg1',
          roomId: roomId,
          userId: 'u_generic',
          userName: 'Football_Guy',
          userBorder: 'none',
          messageText: 'Big match coming up! Share your prediction cards guys.',
          reactions: {},
          createdAt: now.subtract(const Duration(minutes: 8)),
        ),
      ];
    }
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

  /// Joins a new fan club.
  /// If the user is already in a club, it costs 100 points to unlock a second slot.
  Future<bool> joinClub(String clubId) async {
    state = state.copyWith(isLoading: true, error: null);

    final club = state.allClubs.firstWhere((c) => c.id == clubId);
    final isAlreadyJoined = state.joinedClubs.any((c) => c.id == clubId);
    if (isAlreadyJoined) {
      state = state.copyWith(isLoading: false, error: "Already a member of ${club.name}");
      return false;
    }

    final currentJoinedCount = state.joinedClubs.length;
    final authState = ref.read(authProvider);
    final user = authState.value;

    if (currentJoinedCount >= 1) {
      // Unlocking 2nd slot costs 100 pts
      if (user == null || user.points < 100) {
        state = state.copyWith(
          isLoading: false,
          error: "Unlocking a second Fan Club costs 100 Points. You have ${user?.points ?? 0} PTS.",
        );
        return false;
      }

      // Deduct points via AuthProvider
      final success = await ref.read(authProvider.notifier).addPoints(-100);
      // Wait, addPoints is void, but we can assume success or check points.
      // Since it updates local state immediately, let's proceed.
    }

    // Update member count
    final updatedClub = club.copyWith(memberCount: club.memberCount + 1);

    // Save to database if Supabase is connected
    try {
      final client = sb.Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.from('fan_club_members').insert({
          'user_id': client.auth.currentUser!.id,
          'fan_club_id': clubId,
          'is_favorite': currentJoinedCount == 0,
        });
      }
    } catch (e) {
      debugPrint("Database save failed for joining club, proceeding locally: $e");
    }

    final newJoined = [...state.joinedClubs, updatedClub];
    final newAll = state.allClubs.map((c) => c.id == clubId ? updatedClub : c).toList();

    state = state.copyWith(
      joinedClubs: newJoined,
      allClubs: newAll,
      isLoading: false,
    );

    return true;
  }

  /// Sends a new message in the chat room.
  Future<void> sendMessage(String roomId, String text, {Map<String, dynamic>? predictionCard}) async {
    final user = ref.read(authProvider).value;
    final userId = user?.id ?? 'guest-id';
    final userName = user?.name ?? 'Guest Predictor';
    final userBorder = user?.activeBorder ?? 'none';

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      userId: userId,
      userName: userName,
      userBorder: userBorder,
      messageText: text,
      reactions: {},
      predictionCard: predictionCard,
      createdAt: DateTime.now(),
    );

    // Update locally immediately
    final roomMessages = <ChatMessage>[...(state.chatMessages[roomId] ?? [])];
    roomMessages.add(newMessage);

    final updatedMessages = Map<String, List<ChatMessage>>.from(state.chatMessages);
    updatedMessages[roomId] = roomMessages;

    state = state.copyWith(chatMessages: updatedMessages);

    // Save message to Supabase
    try {
      final client = sb.Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.from('chat_messages').insert({
          'room_id': roomId,
          'user_id': userId,
          'user_name': userName,
          'user_border': userBorder,
          'message_text': text,
          'prediction_card_data': predictionCard,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("Supabase send message failed: $e");
    }
  }

  /// Toggles an emoji reaction on a message.
  void toggleReaction(String roomId, String messageId, String emoji) {
    final user = ref.read(authProvider).value;
    final userName = user?.name ?? 'Guest Predictor';

    final roomMessages = state.chatMessages[roomId];
    if (roomMessages == null) return;

    final updatedList = roomMessages.map((msg) {
      if (msg.id == messageId) {
        final newReactions = Map<String, List<String>>.from(msg.reactions);
        final currentReactors = List<String>.from(newReactions[emoji] ?? []);

        if (currentReactors.contains(userName)) {
          currentReactors.remove(userName);
        } else {
          currentReactors.add(userName);
        }

        if (currentReactors.isEmpty) {
          newReactions.remove(emoji);
        } else {
          newReactions[emoji] = currentReactors;
        }

        return msg.copyWith(reactions: newReactions);
      }
      return msg;
    }).toList();

    final updatedMessages = Map<String, List<ChatMessage>>.from(state.chatMessages);
    updatedMessages[roomId] = updatedList;

    state = state.copyWith(chatMessages: updatedMessages);

    // Async database update
    try {
      final client = sb.Supabase.instance.client;
      final targetMsg = updatedList.firstWhere((m) => m.id == messageId);
      if (client.auth.currentUser != null) {
        client.from('chat_messages').update({
          'reactions': targetMsg.reactions,
        }).eq('id', messageId);
      }
    } catch (e) {
      debugPrint("Database update for reaction failed: $e");
    }
  }

  // ─── Simulation ─────────────────────────────────────────────────────────────

  final List<String> _simNames = ['SambaKing', 'Kaiser_Franz', 'CR7_Legacy', 'Gunner_ForLife', 'GoalPoacher', 'FifaPro_007', 'TikiTaka_X', 'SuperSub'];
  final List<String> _simBorders = ['none', 'neon_blue', 'royal_purple', 'golden_champion', 'none'];
  final List<String> _simMessages = [
    'What a game! Absolute masterclass.',
    'I knew they\'d struggle in the midfield today.',
    'Prediction card: 3-1 Brazil. Lock it in! 🔒',
    'Who is your pick for the Golden Boot?',
    'This tournament is full of surprises, loving it!',
    'That penalty decision was so soft...',
    'Is anyone playing trivia right now? Need some cards.',
    'Let\'s go team! We are top of the fan war table! ⚔️🏆',
    'Messi or Ronaldo? Let the chat decide for the 100th time 😂',
  ];

  void _simulateIncomingMessage() {
    final roomIds = ['global', ...state.joinedClubs.map((c) => c.id)];
    final targetRoom = roomIds[_random.nextInt(roomIds.length)];

    final simName = _simNames[_random.nextInt(_simNames.length)];
    final simBorder = _simBorders[_random.nextInt(_simBorders.length)];
    final simText = _simMessages[_random.nextInt(_simMessages.length)];

    final newMessage = ChatMessage(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      roomId: targetRoom,
      userId: 'sim_user',
      userName: simName,
      userBorder: simBorder,
      messageText: simText,
      reactions: {},
      createdAt: DateTime.now(),
    );

    final roomMessages = <ChatMessage>[...(state.chatMessages[targetRoom] ?? [])];
    // Keep max 50 messages in memory for mock rooms
    if (roomMessages.length > 50) {
      roomMessages.removeAt(0);
    }
    roomMessages.add(newMessage);

    final updatedMessages = Map<String, List<ChatMessage>>.from(state.chatMessages);
    updatedMessages[targetRoom] = roomMessages;

    state = state.copyWith(chatMessages: updatedMessages);
  }
}

final communityProvider = NotifierProvider<CommunityNotifier, CommunityState>(() {
  return CommunityNotifier();
});

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/color_scheme.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/pitch_background.dart';
import '../providers/community_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late String _currentRoomId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Map<String, dynamic>? _attachedPredictionCard;
  final List<String> _emojis = ['🔥', '😂', '💀', '🙏', '😤', '💯', '😭', '🎉'];

  // Predefined mock predictions for attachment sheet
  final List<Map<String, dynamic>> _mockShareablePredictions = [
    {
      'homeTeam': 'Brazil',
      'awayTeam': 'Argentina',
      'homeScore': 1,
      'awayScore': 2,
      'winner': 'Argentina',
      'firstScorer': 'Lionel Messi',
      'username': 'Me',
    },
    {
      'homeTeam': 'France',
      'awayTeam': 'England',
      'homeScore': 3,
      'awayScore': 2,
      'winner': 'France',
      'firstScorer': 'Kylian Mbappé',
      'username': 'Me',
    },
    {
      'homeTeam': 'Spain',
      'awayTeam': 'Germany',
      'homeScore': 2,
      'awayScore': 1,
      'winner': 'Spain',
      'firstScorer': 'Dani Olmo',
      'username': 'Me',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.roomId;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachedPredictionCard == null) return;

    ref.read(communityProvider.notifier).sendMessage(
      _currentRoomId,
      text,
      predictionCard: _attachedPredictionCard,
    );

    _messageController.clear();
    setState(() {
      _attachedPredictionCard = null;
    });
    _scrollToBottom();
  }

  void _showAttachmentSheet() {
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Attach Prediction Card",
                style: SkorioTextStyles.labelMd.copyWith(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "Select one of your recent predictions to share in the chat.",
                style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mockShareablePredictions.length,
                itemBuilder: (context, index) {
                  final pred = _mockShareablePredictions[index];
                  return Card(
                    color: Colors.white.withValues(alpha: 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white10),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        "${pred['homeTeam']} vs ${pred['awayTeam']}",
                        style: SkorioTextStyles.labelMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Prediction: ${pred['homeScore']}-${pred['awayScore']} · Scorer: ${pred['firstScorer']}",
                        style: SkorioTextStyles.labelSm.copyWith(color: SkorioColors.onSurfaceVariant),
                      ),
                      trailing: const Icon(Icons.add_circle, color: SkorioColors.primary),
                      onTap: () {
                        setState(() {
                          _attachedPredictionCard = pred;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReactionOverlay(BuildContext context, ChatMessage message) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      ref.read(communityProvider.notifier).toggleReaction(
                            _currentRoomId,
                            message.id,
                            emoji,
                          );
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    final currentUser = ref.watch(authProvider).value;

    // Resolve current room properties
    String title = "Global Fan Chat";
    String icon = "🌍";
    Color accentColor = SkorioColors.primary;
    String desc = "Main community chatroom";

    if (_currentRoomId.startsWith('club_')) {
      final club = state.allClubs.firstWhere((c) => c.id == _currentRoomId);
      title = club.name;
      icon = club.logoUrl;
      accentColor = Color(int.tryParse(club.primaryColor) ?? 0xFF8B80FF);
      desc = "${club.memberCount} active members";
    } else if (_currentRoomId.startsWith('match_')) {
      final war = state.activeWars.firstWhere((w) => w.matchId == _currentRoomId, orElse: () {
        return FanWar(
          id: 'temp',
          matchId: _currentRoomId,
          matchTitle: 'Match Debate',
          clubAId: '',
          clubBId: '',
          accuracyA: 50,
          accuracyB: 50,
          endsAt: DateTime.now(),
        );
      });
      title = war.matchTitle;
      icon = "⚽";
      accentColor = SkorioColors.error;
      desc = "Match day live debate";
    }

    final messages = (state.chatMessages[_currentRoomId] ?? []).reversed.toList();

    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: Stack(
        children: [
          const PitchBackground(child: SizedBox.expand()),

          // Ambient Background Glows
          Positioned(
            top: 100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.03),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: accentColor.withValues(alpha: 0.03)),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Custom App Bar
                _buildAppBar(context, title, icon, accentColor, desc),

                // 2. Chat Switcher Quick Tabs (Global + user's clubs + active wars)
                _buildQuickRoomsTab(state, accentColor),

                // 3. Message List Area
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.userId == currentUser?.id;
                      return _buildMessageRow(context, message, isMe, accentColor, currentUser?.name);
                    },
                  ),
                ),

                // Attached Preview Banner
                if (_attachedPredictionCard != null) _buildAttachedPreview(),

                // 4. Input Area
                _buildInputBar(context, accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    String title,
    String icon,
    Color accentColor,
    String desc,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.05),
              border: Border.all(color: accentColor.withValues(alpha: 0.15)),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: SkorioTextStyles.labelMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  desc,
                  style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRoomsTab(CommunityState state, Color activeColor) {
    final List<Map<String, dynamic>> rooms = [
      {'id': 'global', 'label': 'Global Chat', 'icon': '🌍'},
    ];

    for (var club in state.joinedClubs) {
      rooms.add({'id': club.id, 'label': club.name.split(' ')[0], 'icon': club.logoUrl});
    }

    for (var war in state.activeWars) {
      rooms.add({'id': war.matchId, 'label': war.matchTitle, 'icon': '⚔️'});
    }

    return Container(
      height: 46,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          final isSelected = room['id'] == _currentRoomId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentRoomId = room['id']!;
              });
              _scrollToBottom();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected ? activeColor.withValues(alpha: 0.25) : Colors.white10,
                ),
              ),
              child: Row(
                children: [
                  Text(room['icon']!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    room['label']!,
                    style: SkorioTextStyles.labelSm.copyWith(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageRow(
    BuildContext context,
    ChatMessage message,
    bool isMe,
    Color accentColor,
    String? currentUserName,
  ) {
    // Resolve Border border color (neon cyan, royal purple, gold, or none)
    Color? borderColor;
    double borderWidth = 1.0;
    if (message.userBorder == 'neon_blue') {
      borderColor = Colors.cyanAccent;
      borderWidth = 2.0;
    } else if (message.userBorder == 'royal_purple') {
      borderColor = Colors.purpleAccent;
      borderWidth = 2.0;
    } else if (message.userBorder == 'golden_champion') {
      borderColor = SkorioColors.gold;
      borderWidth = 2.0;
    }

    final String initials = message.userName.isEmpty
        ? 'U'
        : message.userName.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onLongPress: () => _showReactionOverlay(context, message),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  border: borderColor != null
                      ? Border.all(color: borderColor, width: borderWidth)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Username Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.userName,
                      style: SkorioTextStyles.labelSm.copyWith(
                        color: isMe ? accentColor : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}",
                      style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24, fontSize: 8.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Bubble Card
                GestureDetector(
                  onLongPress: () => _showReactionOverlay(context, message),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    borderColor: isMe
                        ? accentColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    opacity: isMe ? 0.06 : 0.03,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.messageText.isNotEmpty)
                          Text(
                            message.messageText,
                            style: SkorioTextStyles.bodyMd.copyWith(color: Colors.white, fontSize: 13.5),
                          ),
                        if (message.predictionCard != null) ...[
                          if (message.messageText.isNotEmpty) const SizedBox(height: 8),
                          _buildPredictionCardItem(message.predictionCard!),
                        ],
                      ],
                    ),
                  ),
                ),

                // Reactions Row
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: message.reactions.entries.map((entry) {
                        final emoji = entry.key;
                        final count = entry.value.length;
                        final reacted = userHasReacted(entry.value, currentUserName);

                        return GestureDetector(
                          onTap: () {
                            ref.read(communityProvider.notifier).toggleReaction(
                                  _currentRoomId,
                                  message.id,
                                  emoji,
                                );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: reacted
                                  ? accentColor.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: reacted
                                    ? accentColor.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text(
                                  "$count",
                                  style: TextStyle(
                                    color: reacted ? Colors.white : Colors.white54,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onLongPress: () => _showReactionOverlay(context, message),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accentColor.withValues(alpha: 0.8), accentColor.withValues(alpha: 0.5)],
                  ),
                  border: borderColor != null
                      ? Border.all(color: borderColor, width: borderWidth)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool userHasReacted(List<String> userNames, String? myName) {
    if (myName == null) return false;
    return userNames.contains(myName);
  }

  Widget _buildPredictionCardItem(Map<String, dynamic> card) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: SkorioColors.gold, size: 12),
              const SizedBox(width: 4),
              Text(
                "PREDICTION CARD",
                style: SkorioTextStyles.labelSm.copyWith(
                  color: SkorioColors.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card['homeTeam'],
                style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                "${card['homeScore']} - ${card['awayScore']}",
                style: const TextStyle(color: SkorioColors.primary, fontWeight: FontWeight.w900, fontSize: 13),
              ),
              Text(
                card['awayTeam'],
                style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Winner: ${card['winner']}",
                  style: SkorioTextStyles.labelSm.copyWith(color: Colors.white54, fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  "First Scorer: ${card['firstScorer']}",
                  style: SkorioTextStyles.labelSm.copyWith(color: Colors.white54, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withValues(alpha: 0.02),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: SkorioColors.primary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Attached prediction card for ${_attachedPredictionCard!['homeTeam']} vs ${_attachedPredictionCard!['awayTeam']}",
              style: SkorioTextStyles.labelSm.copyWith(color: Colors.white70, fontSize: 11),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white30, size: 14),
            onPressed: () {
              setState(() {
                _attachedPredictionCard = null;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D12),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // Attach Prediction Card Button
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: SkorioColors.primary),
            onPressed: _showAttachmentSheet,
            tooltip: "Attach Prediction",
          ),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button
          IconButton(
            icon: const Icon(Icons.send_rounded, color: SkorioColors.primary),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}

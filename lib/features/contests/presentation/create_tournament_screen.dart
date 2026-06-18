import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/color_scheme.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/pitch_background.dart';
import '../providers/tournaments_provider.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends ConsumerState<CreateTournamentScreen> {
  int _currentStep = 1;
  final int _totalSteps = 5;

  // Step 1 Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  String _selectedSport = 'football'; // 'football', 'cricket', 'custom'

  // Step 2 Format
  String _selectedFormat = 'league'; // 'league', 'knockout'

  // Step 3 Rules
  int _winPts = 3;
  int _drawPts = 1;
  int _lossPts = 0;
  final TextEditingController _prizesController = TextEditingController();

  // Step 4 Teams List (Pre-loaded with 4 mock teams to make demo incredibly easy)
  final List<TournamentTeam> _teams = [
    const TournamentTeam(id: 't_mock_1', name: 'Red Panthers', logoUrl: '🐆', primaryColor: '0xFFEF4444', secondaryColor: '0xFF131318', players: []),
    const TournamentTeam(id: 't_mock_2', name: 'Blue Falcons', logoUrl: '🦅', primaryColor: '0xFF3B82F6', secondaryColor: '0xFF131318', players: []),
    const TournamentTeam(id: 't_mock_3', name: 'Green Vipers', logoUrl: '🐍', primaryColor: '0xFF10B981', secondaryColor: '0xFF131318', players: []),
    const TournamentTeam(id: 't_mock_4', name: 'Golden Eagles', logoUrl: '🦅', primaryColor: '0xFFFFD700', secondaryColor: '0xFF131318', players: []),
  ];

  final TextEditingController _teamNameController = TextEditingController();
  String _teamLogoEmoji = '⚽';
  Color _teamPrimaryColor = SkorioColors.secondary;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locController.dispose();
    _prizesController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tournament Name is required"),
          backgroundColor: SkorioColors.errorContainer,
        ),
      );
      return;
    }
    if (_currentStep == 4 && _teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least 2 teams"),
          backgroundColor: SkorioColors.errorContainer,
        ),
      );
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  void _addTeam() {
    final name = _teamNameController.text.trim();
    if (name.isEmpty) return;

    // Convert color to hex string
    final hexColor = '0xFF${_teamPrimaryColor.value.toRadixString(16).substring(2).toUpperCase()}';

    // Mock roster
    final mockPlayers = [
      TournamentPlayer(id: 'p_${name}_1', name: 'Player A', jerseyNumber: 10, position: 'FWD'),
      TournamentPlayer(id: 'p_${name}_2', name: 'Player B', jerseyNumber: 8, position: 'MID'),
      TournamentPlayer(id: 'p_${name}_3', name: 'Player C', jerseyNumber: 4, position: 'DEF'),
      TournamentPlayer(id: 'p_${name}_4', name: 'Player D', jerseyNumber: 1, position: 'GK'),
    ];

    setState(() {
      _teams.add(
        TournamentTeam(
          id: 'team_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          logoUrl: _teamLogoEmoji,
          primaryColor: hexColor,
          secondaryColor: '0xFF131318',
          players: mockPlayers,
        ),
      );
      _teamNameController.clear();
      _teamLogoEmoji = '⚽';
    });
  }

  void _removeTeam(int index) {
    setState(() {
      _teams.removeAt(index);
    });
  }

  Future<void> _handlePublish() async {
    final tournament = Tournament(
      id: 'tour_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      sport: _selectedSport,
      format: _selectedFormat,
      description: _descController.text.trim(),
      location: _locController.text.trim(),
      bannerUrl: '',
      winPts: _winPts,
      drawPts: _drawPts,
      lossPts: _lossPts,
      teams: _teams,
      matches: const [], // Will be auto-generated for League format!
      prizes: _prizesController.text.trim(),
      creatorId: '',
    );

    final success = await ref.read(tournamentsProvider.notifier).createTournament(tournament);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tournament published successfully!"),
          backgroundColor: SkorioColors.onSecondaryContainer,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkorioColors.baseBg,
      body: Stack(
        children: [
          const PitchBackground(child: SizedBox.expand()),

          // Ambient Background Glows
          Positioned(
            top: 40,
            left: -80,
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
                // Header Row
                _buildHeader(context),

                // Step Progress Bar
                _buildProgressBar(),

                // Step Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderColor: SkorioColors.secondary.withValues(alpha: 0.1),
                      child: _buildStepContent(),
                    ),
                  ),
                ),

                // Navigation Row at Bottom
                _buildBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            "CREATE TOURNAMENT",
            style: SkorioTextStyles.labelMd.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Step $_currentStep of $_totalSteps",
                style: SkorioTextStyles.labelSm.copyWith(color: SkorioColors.secondary, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(_currentStep / _totalSteps * 100).round()}% Completed",
                style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: _currentStep / _totalSteps,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(SkorioColors.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Info();
      case 2:
        return _buildStep2Format();
      case 3:
        return _buildStep3Rules();
      case 4:
        return _buildStep4Teams();
      case 5:
        return _buildStep5Confirm();
      default:
        return Container();
    }
  }

  // Step 1: Info Screen
  Widget _buildStep1Info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("BASIC INFO", "Enter the naming and location details."),
        const SizedBox(height: 18),
        _buildLabel("Tournament Name"),
        _buildTextField(_nameController, "e.g., Sunday Champions League"),
        const SizedBox(height: 16),
        _buildLabel("Description"),
        _buildTextField(_descController, "e.g., Local tournament for sector 5 clubs.", maxLines: 2),
        const SizedBox(height: 16),
        _buildLabel("Location / Venue"),
        _buildTextField(_locController, "e.g., Sector 5 Ground, Mumbai"),
        const SizedBox(height: 16),
        _buildLabel("Sport Type"),
        Row(
          children: [
            _buildChoiceChip("⚽ FOOTBALL", _selectedSport == 'football', () {
              setState(() => _selectedSport = 'football');
            }),
            const SizedBox(width: 8),
            _buildChoiceChip("🏏 CRICKET", _selectedSport == 'cricket', () {
              setState(() => _selectedSport = 'cricket');
            }),
          ],
        ),
      ],
    );
  }

  // Step 2: Format
  Widget _buildStep2Format() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("TOURNAMENT FORMAT", "Choose how teams compete."),
        const SizedBox(height: 18),
        _buildFormatOption(
          'league',
          'Round Robin League',
          'Everyone plays everyone. Auto-generates fixtures. Best for local seasonal clubs.',
          Icons.grid_view_outlined,
        ),
        const SizedBox(height: 6),
        _buildFormatOption(
          'knockout',
          'Knockout / Single Elimination',
          'Lose once and you are out. Ideal for weekend cups or esports brackets.',
          Icons.account_tree_outlined,
        ),
      ],
    );
  }

  // Step 3: Scoring Rules
  Widget _buildStep3Rules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("SCORING CONFIG", "Determine points awarded per match outcome."),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPointsConfigTile("WIN POINTS", _winPts, (val) => setState(() => _winPts = val)),
            _buildPointsConfigTile("DRAW POINTS", _drawPts, (val) => setState(() => _drawPts = val)),
            _buildPointsConfigTile("LOSS POINTS", _lossPts, (val) => setState(() => _lossPts = val)),
          ],
        ),
        const SizedBox(height: 20),
        _buildLabel("Prizes Description"),
        _buildTextField(_prizesController, "e.g., Trophy + ₹10,000 Shop Voucher"),
      ],
    );
  }

  // Step 4: Add Teams
  Widget _buildStep4Teams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("PARTICIPATING TEAMS", "Add teams to compete (min 2)."),
        const SizedBox(height: 14),
        Row(
          children: [
            DropdownButton<String>(
              value: _teamLogoEmoji,
              dropdownColor: const Color(0xFF131318),
              underline: Container(),
              onChanged: (val) {
                if (val != null) setState(() => _teamLogoEmoji = val);
              },
              items: ['⚽', '🐆', '🦅', '🐍', '🦁', '🛡️', '⚔️']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 20))))
                  .toList(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(_teamNameController, "Team Name", height: 42),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: SkorioColors.secondary, size: 28),
              onPressed: _addTeam,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 12),
        _teams.isEmpty
            ? Center(
                child: Text(
                  "No teams added yet",
                  style: SkorioTextStyles.labelSm.copyWith(color: Colors.white24),
                ),
              )
            : SizedBox(
                height: 240,
                child: ListView.builder(
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: Row(
                        children: [
                          Text(team.logoUrl, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              team.name,
                              style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                            onPressed: () => _removeTeam(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  // Step 5: Confirm Page
  Widget _buildStep5Confirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("PUBLISH TOURNAMENT", "Review details before going live."),
        const SizedBox(height: 18),
        _buildSummaryRow("Name", _nameController.text),
        _buildSummaryRow("Sport", _selectedSport.toUpperCase()),
        _buildSummaryRow("Format", _selectedFormat == 'league' ? 'Round Robin League' : 'Single Elimination Cup'),
        _buildSummaryRow("Rules", "Win: $_winPts PTS · Draw: $_drawPts PTS · Loss: $_lossPts PTS"),
        _buildSummaryRow("Total Teams", "${_teams.length} Teams"),
        if (_locController.text.isNotEmpty) _buildSummaryRow("Venue", _locController.text),
        if (_prizesController.text.isNotEmpty) _buildSummaryRow("Prizes", _prizesController.text),
      ],
    );
  }

  // Helpers
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SkorioTextStyles.labelMd.copyWith(color: SkorioColors.secondary, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: SkorioTextStyles.labelSm.copyWith(color: Colors.white54, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SkorioColors.secondary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? SkorioColors.secondary : Colors.white12,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: SkorioTextStyles.labelSm.copyWith(
            color: isSelected ? SkorioColors.secondary : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildFormatOption(String value, String title, String desc, IconData icon) {
    final isSelected = _selectedFormat == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SkorioColors.secondary.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? SkorioColors.secondary.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? SkorioColors.secondary : Colors.white24, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: SkorioTextStyles.labelSm.copyWith(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: SkorioColors.secondary, size: 13),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsConfigTile(String label, int value, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30, fontSize: 8.5, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white54, size: 14),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Text(
                "$value",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white54, size: 14),
                onPressed: () => onChanged(value + 1),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: SkorioTextStyles.labelSm.copyWith(color: Colors.white30, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: SkorioTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 1)
            OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("BACK", style: SkorioTextStyles.labelSm.copyWith(color: Colors.white70)),
            )
          else
            const SizedBox(),
          ElevatedButton(
            onPressed: _currentStep == _totalSteps ? _handlePublish : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: SkorioColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              _currentStep == _totalSteps ? "PUBLISH" : "CONTINUE",
              style: SkorioTextStyles.labelSm.copyWith(color: Colors.black, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

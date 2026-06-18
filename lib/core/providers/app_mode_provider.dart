import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/color_scheme.dart';

enum AppMode { fan, tournament }

class AppModeState {
  final AppMode mode;
  final String activeFanTab;
  final String activeTournamentTab;

  AppModeState({
    required this.mode,
    required this.activeFanTab,
    required this.activeTournamentTab,
  });

  AppModeState copyWith({
    AppMode? mode,
    String? activeFanTab,
    String? activeTournamentTab,
  }) {
    return AppModeState(
      mode: mode ?? this.mode,
      activeFanTab: activeFanTab ?? this.activeFanTab,
      activeTournamentTab: activeTournamentTab ?? this.activeTournamentTab,
    );
  }
}

class AppModeNotifier extends Notifier<AppModeState> {
  @override
  AppModeState build() {
    return AppModeState(
      mode: AppMode.fan,
      activeFanTab: 'contests',
      activeTournamentTab: 'dashboard',
    );
  }

  void setMode(AppMode newMode) {
    state = state.copyWith(mode: newMode);
  }

  void setFanTab(String tab) {
    state = state.copyWith(activeFanTab: tab);
  }

  void setTournamentTab(String tab) {
    state = state.copyWith(activeTournamentTab: tab);
  }

  Color get accentColor {
    return state.mode == AppMode.fan
        ? SkorioColors.primary
        : SkorioColors.secondary;
  }
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppModeState>(() {
  return AppModeNotifier();
});

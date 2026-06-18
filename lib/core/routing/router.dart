import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/points_shop_screen.dart';
import '../../features/auth/presentation/notification_settings_screen.dart';
import '../../features/contests/presentation/contests_screen.dart';
import '../../features/contests/presentation/contest_details_screen.dart';
import '../../features/contests/presentation/predict_match_screen.dart';
import '../../features/contests/presentation/games_screen.dart';
import '../../features/contests/presentation/penalty_shootout_screen.dart';
import '../../features/contests/presentation/trivia_screen.dart';
import '../../features/contests/presentation/first_goal_screen.dart';
import '../../features/contests/presentation/formation_screen.dart';
import '../../features/contests/presentation/bracket_screen.dart';
import '../../features/contests/presentation/who_am_i_screen.dart';
import '../../features/contests/presentation/flag_quiz_screen.dart';
import '../../features/contests/presentation/leaderboard_screen.dart';
import '../../features/contests/presentation/spin_wheel_screen.dart';
import '../../features/contests/presentation/survivor_screen.dart';
import '../../features/contests/presentation/sportle_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/contests/presentation/tournament_dashboard_screen.dart';
import '../../features/contests/presentation/tournaments_list_screen.dart';
import '../widgets/main_shell.dart';
import '../../features/contests/presentation/create_tournament_screen.dart';
import '../../features/contests/presentation/tournament_detail_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/community/presentation/chat_screen.dart';
import '../../features/contests/presentation/predict_cricket_screen.dart';

CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      final reverseTween = Tween(
        begin: Offset.zero,
        end: const Offset(-0.25, 0.0),
      ).chain(CurveTween(curve: Curves.easeInCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: SlideTransition(
          position: secondaryAnimation.drive(reverseTween),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.value != null;
      final goingToLogin = state.matchedLocation == '/login';
      if (!isLoggedIn && !goingToLogin) return '/login';
      if (isLoggedIn && goingToLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, s) => _slidePage(s, const LoginScreen()),
      ),

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/',                      pageBuilder: (ctx, s) => _slidePage(s, const ContestsScreen())),
          GoRoute(path: '/contests',              pageBuilder: (ctx, s) => _slidePage(s, const ContestsScreen())),
          GoRoute(path: '/games',                 pageBuilder: (ctx, s) => _slidePage(s, const GamesScreen())),
          GoRoute(path: '/social',                pageBuilder: (ctx, s) => _slidePage(s, const CommunityScreen())),
          GoRoute(path: '/profile',               pageBuilder: (ctx, s) => _slidePage(s, const ProfileScreen())),
          GoRoute(path: '/tournaments/dashboard', pageBuilder: (ctx, s) => _slidePage(s, const TournamentDashboardScreen())),
          GoRoute(path: '/tournaments',           pageBuilder: (ctx, s) => _slidePage(s, const TournamentsListScreen())),
          GoRoute(path: '/tournaments/standings', pageBuilder: (ctx, s) => _slidePage(s, const TournamentsListScreen())),
          GoRoute(path: '/tournaments/teams',    pageBuilder: (ctx, s) => _slidePage(s, const TournamentsListScreen())),
        ],
      ),

      // Contest routes
      GoRoute(
        path: '/contest/:id',
        pageBuilder: (ctx, s) => _slidePage(s, ContestDetailsScreen(contestId: s.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path: '/predict/:matchId',
        pageBuilder: (ctx, s) => _slidePage(s, PredictMatchScreen(matchId: s.pathParameters['matchId'] ?? '')),
      ),
      GoRoute(
        path: '/predict/cricket/:matchId',
        pageBuilder: (ctx, s) => _slidePage(s, PredictCricketScreen(matchId: s.pathParameters['matchId'] ?? '')),
      ),

      // Game routes
      GoRoute(path: '/games/penalty',     pageBuilder: (ctx, s) => _slidePage(s, const PenaltyShootoutScreen())),
      GoRoute(path: '/games/trivia',      pageBuilder: (ctx, s) => _slidePage(s, const TriviaScreen())),
      GoRoute(path: '/games/first-goal',  pageBuilder: (ctx, s) => _slidePage(s, const FirstGoalScreen())),
      GoRoute(path: '/games/formation',   pageBuilder: (ctx, s) => _slidePage(s, const FormationScreen())),
      GoRoute(path: '/games/bracket',     pageBuilder: (ctx, s) => _slidePage(s, const BracketScreen())),
      GoRoute(path: '/games/who-am-i',    pageBuilder: (ctx, s) => _slidePage(s, const WhoAmIScreen())),
      GoRoute(path: '/games/flags',       pageBuilder: (ctx, s) => _slidePage(s, const FlagQuizScreen())),
      GoRoute(path: '/games/leaderboard', pageBuilder: (ctx, s) => _slidePage(s, const LeaderboardScreen())),
      GoRoute(path: '/games/spin',        pageBuilder: (ctx, s) => _slidePage(s, const SpinWheelScreen())),
      GoRoute(path: '/games/survivor',    pageBuilder: (ctx, s) => _slidePage(s, const SurvivorScreen())),
      GoRoute(path: '/games/sportle',     pageBuilder: (ctx, s) => _slidePage(s, const SportleScreen())),
      GoRoute(path: '/points-shop',       pageBuilder: (ctx, s) => _slidePage(s, const PointsShopScreen())),
      GoRoute(path: '/notifications',     pageBuilder: (ctx, s) => _slidePage(s, const NotificationSettingsScreen())),
      GoRoute(path: '/community',         pageBuilder: (ctx, s) => _slidePage(s, const CommunityScreen())),
      GoRoute(
        path: '/chat/:roomId',
        pageBuilder: (ctx, s) => _slidePage(s, ChatScreen(roomId: s.pathParameters['roomId'] ?? 'global')),
      ),
      GoRoute(path: '/tournaments/create', pageBuilder: (ctx, s) => _slidePage(s, const CreateTournamentScreen())),
      GoRoute(
        path: '/tournaments/:id',
        pageBuilder: (ctx, s) => _slidePage(s, TournamentDetailScreen(tournamentId: s.pathParameters['id'] ?? '')),
      ),
    ],
  );
});

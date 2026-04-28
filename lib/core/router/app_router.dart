import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/trips/trips_screen.dart';
import '../../presentation/screens/trips/create_trip_screen.dart';
import '../../presentation/screens/trips/trip_detail_screen.dart';
import '../../presentation/screens/packing/packing_screen.dart';
import '../../presentation/screens/todo/todo_screen.dart';
import '../../presentation/screens/containers/containers_screen.dart';
import '../../presentation/screens/group/group_screen.dart';
import '../../presentation/screens/group/join_group_screen.dart';
import '../../presentation/screens/group/group_todo_screen.dart';
import '../../presentation/screens/group/group_containers_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/widgets/common/main_scaffold.dart';

GoRouter buildRouter(WidgetRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = authState.value;
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (user == null && !isAuthRoute) return '/login';
      if (user != null && isAuthRoute) return '/';
      return null;
    },
    refreshListenable: _AuthChangeNotifier(ref),
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/login',
        builder: (c, s) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (c, s) => const SignupScreen(),
      ),
      // Main app shell
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/trips', builder: (c, s) => const TripsScreen()),
          GoRoute(path: '/todo', builder: (c, s) => const TodoScreen()),
          GoRoute(
              path: '/containers',
              builder: (c, s) => const ContainersScreen()),
          GoRoute(path: '/chat', builder: (c, s) => const ChatScreen()),
        ],
      ),
      GoRoute(
        path: '/trips/create',
        builder: (c, s) => const CreateTripScreen(),
      ),
      GoRoute(
        path: '/trips/:id',
        builder: (c, s) => TripDetailScreen(tripId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/trips/:id/packing',
        builder: (c, s) => PackingScreen(tripId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/trips/:id/todo',
        builder: (c, s) => TodoScreen(tripId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/trips/:id/containers',
        builder: (c, s) => ContainersScreen(tripId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/group',
        builder: (c, s) => const GroupScreen(),
      ),
      GoRoute(
        path: '/group/join',
        builder: (c, s) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/group/:groupId/todos',
        builder: (c, s) =>
            GroupTodoScreen(groupId: s.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/group/:groupId/containers',
        builder: (c, s) =>
            GroupContainersScreen(groupId: s.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (c, s) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (c, s) => const ProfileScreen(),
      ),
    ],
  );
}

/// Notifies GoRouter to re-evaluate redirect when auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      notifyListeners();
    });
  }
}

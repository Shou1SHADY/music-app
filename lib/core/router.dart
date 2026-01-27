import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../features/auth/auth_service.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/chat/chat_detail_screen.dart';
import '../features/studios/studio_detail_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../models/user_model.dart';
import '../models/studio_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (context, state) {
      final user = authService.currentUser;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/onboarding';

      // 1. If user is NOT logged in, they must be on login/signup/onboarding pages
      if (user == null) {
        return isLoggingIn ? null : '/onboarding';
      }

      // 2. If user IS logged in and trying to go to login/signup, send them home
      if (isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/chat-detail/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final extra = state.extra;
          final otherUser = extra is UserModel ? extra : null;

          if (otherUser == null) {
            return const Scaffold(
              body: Center(
                child: Text('Missing chat participant (navigation data).'),
              ),
            );
          }

          return ChatDetailScreen(chatId: chatId, otherUser: otherUser);
        },
      ),
      GoRoute(
        path: '/studio-detail',
        builder: (context, state) {
          final extra = state.extra;
          final studio = extra is StudioModel ? extra : null;

          if (studio == null) {
            return const Scaffold(
              body: Center(
                child: Text('Missing studio (navigation data).'),
              ),
            );
          }

          return StudioDetailScreen(studio: studio);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../musicians/musician_list_screen.dart';
import '../studios/studio_list_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/user_profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MusicianListScreen(),
    const StudioListScreen(),
    const ChatListScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.04))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold);
              }
              return const TextStyle(color: AppColors.textMuted, fontSize: 12);
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const IconThemeData(color: AppColors.primary);
              }
              return const IconThemeData(color: AppColors.textMuted);
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            backgroundColor: AppColors.background,
            indicatorColor: AppColors.primary.withOpacity(0.08),
            height: 75,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined,
                    size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.explore_rounded,
                    size: 24, color: AppColors.primary),
                label: 'Community',
              ),
              NavigationDestination(
                icon: Icon(Icons.music_note_outlined,
                    size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.music_note_rounded,
                    size: 24, color: AppColors.primary),
                label: 'Studios',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline,
                    size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.chat_bubble_rounded,
                    size: 24, color: AppColors.primary),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline,
                    size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.person_rounded,
                    size: 24, color: AppColors.primary),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

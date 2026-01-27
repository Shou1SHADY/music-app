import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../auth/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import '../bookings/booking_service.dart';

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).getUserProfileStream(user.uid);
});

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        data: (user) {
          if (user == null) return _buildNoProfile(context);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, ref, user),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(user),
                      const SizedBox(height: 32),
                      const SizedBox(height: 32),
                      _buildBookingsSection(ref, user.id),
                      const SizedBox(height: 40),
                      _buildSectionHeader('Biography'),
                      const SizedBox(height: 12),
                      Text(
                        user.bio ??
                            "Every artist has a story. Tell yours to the community.",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color:
                              Colors.white.withOpacity(0.85), // High contrast
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Musical Identity'),
                      const SizedBox(height: 16),
                      _buildInstruments(user.instruments),
                      const SizedBox(height: 24),
                      _buildInfoTile(
                          'Level', user.skillLevel, Icons.bolt_rounded),
                      _buildInfoTile('Base', user.city ?? 'Egypt',
                          Icons.location_on_outlined),
                      const SizedBox(height: 40),
                      _buildActionButtons(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
            child: Text('Connection error: $e',
                style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, UserModel user) {
    return SliverAppBar(
      expandedHeight: 0,
      backgroundColor: AppColors.background,
      pinned: true,
      elevation: 0,
      title: Text('MY PROFILE',
          style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppColors.primary)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded,
              color: AppColors.error, size: 22),
          onPressed: () => ref.read(authServiceProvider).signOut(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader(UserModel user) {
    return Row(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2),
            ],
          ),
          child: ClipOval(
            child: user.photoUrl != null
                ? Image.network(
                    user.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        user.displayName[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      user.displayName[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: GoogleFonts.outfit(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MEMBER SINCE 2026',
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                      letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
          letterSpacing: 1.5),
    );
  }

  Widget _buildBookingsSection(WidgetRef ref, String userId) {
    final bookingsStream =
        ref.watch(bookingServiceProvider).getUserBookings(userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Upcoming Bookings'),
        const SizedBox(height: 16),
        StreamBuilder<List<BookingModel>>(
          stream: bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Text('Error loading bookings',
                  style: GoogleFonts.outfit(color: AppColors.error));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final bookings = snapshot.data!;
            if (bookings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: AppColors.textMuted, size: 32),
                    const SizedBox(height: 12),
                    Text('No upcoming sessions',
                        style:
                            GoogleFonts.outfit(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            return Column(
              children: bookings
                  .map((booking) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      DateFormat('d').format(booking.startTime),
                                      style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text(
                                      DateFormat('MMM')
                                          .format(booking.startTime)
                                          .toUpperCase(),
                                      style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(booking.studioName,
                                      style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${DateFormat('h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}',
                                      style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                booking.status.name.toUpperCase(),
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInstruments(List<String> instruments) {
    if (instruments.isEmpty) {
      return Text('No instruments added yet',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: instruments
          .map((i) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Text(i,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 16),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 15, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.push('/profile-setup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Edit Profile'),
          ),
        ),
      ],
    );
  }

  Widget _buildNoProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.surface, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline_rounded,
                  size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            Text('Complete Your Profile',
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(
                'Unlock the full community experience by sharing your musical journey.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.push('/profile-setup'),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_service.dart';
import '../auth/auth_service.dart';
import '../../core/constants.dart';

final musiciansProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getMusicians();
});

class MusicianListScreen extends ConsumerStatefulWidget {
  const MusicianListScreen({super.key});

  @override
  ConsumerState<MusicianListScreen> createState() => _MusicianListScreenState();
}

class _MusicianListScreenState extends ConsumerState<MusicianListScreen> {
  String _selectedInstrument = 'All';
  String _selectedCity = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showInstruments = false;
  bool _showLocation = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterMusicians(List<UserModel> musicians) {
    return musicians.where((m) {
      // Filter by instrument
      if (_selectedInstrument != 'All' &&
          !m.instruments.contains(_selectedInstrument)) {
        return false;
      }
      // Filter by city
      if (_selectedCity != 'All' && m.city != _selectedCity) {
        return false;
      }
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = m.displayName.toLowerCase().contains(query);
        final bioMatch = m.bio?.toLowerCase().contains(query) ?? false;
        final instrumentMatch =
            m.instruments.any((i) => i.toLowerCase().contains(query));
        if (!nameMatch && !bioMatch && !instrumentMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final musiciansAsync = ref.watch(musiciansProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Find Musicians'),
            Text('Connect & Jam in Egypt',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.primary, fontSize: 10)),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          Expanded(
            child: musiciansAsync.when(
              data: (musicians) {
                final filtered = _filterMusicians(musicians);

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) {
                    final musician = filtered[index];
                    return _buildMusicianCard(context, musician);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search musicians, instruments...',
          hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.textMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.03)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _buildCategoryToggle(
                  label: 'Instruments',
                  isSelected: _showInstruments,
                  activeValue:
                      _selectedInstrument != 'All' ? _selectedInstrument : null,
                  icon: Icons.music_note_rounded,
                  onTap: () => setState(() {
                    _showInstruments = !_showInstruments;
                  }),
                ),
                const SizedBox(width: 12),
                _buildCategoryToggle(
                  label: 'Location',
                  isSelected: _showLocation,
                  activeValue: _selectedCity != 'All' ? _selectedCity : null,
                  icon: Icons.location_on_rounded,
                  onTap: () => setState(() {
                    _showLocation = !_showLocation;
                  }),
                ),
              ],
            ),
          ),
          if (_showInstruments)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildFilterSection(
                '',
                AppConstants.instruments,
                _selectedInstrument,
                (val) => setState(() => _selectedInstrument = val),
              ),
            ),
          if (_showLocation)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildFilterSection(
                '',
                AppConstants.egyptCities,
                _selectedCity,
                (val) => setState(() => _selectedCity = val),
                icon: Icons.location_on_rounded,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryToggle({
    required String label,
    required bool isSelected,
    required String? activeValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasActiveValue = activeValue != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : hasActiveValue
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected || hasActiveValue
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              hasActiveValue ? activeValue : label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected || hasActiveValue
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isSelected || hasActiveValue
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isSelected || hasActiveValue
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> items,
      String selectedValue, Function(String) onSelected,
      {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary.withOpacity(0.6),
                letterSpacing: 1.2,
              ),
            ),
          ),
        SizedBox(
          height: 48, // Increased height to accommodate text
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              final label = index == 0 ? 'All' : items[index - 1];
              final isSelected = selectedValue == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildPremiumChip(
                  label: label,
                  isSelected: isSelected,
                  icon: (index > 0) ? icon : null,
                  onTap: () => onSelected(label),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected ? AppColors.onPrimary : AppColors.primary,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11, // Smaller font to prevent overflow
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicianCard(BuildContext context, UserModel musician) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => _showMusicianDetail(context, musician),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildAvatar(musician),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            musician.displayName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14,
                                  color: AppColors.primary.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text(
                                musician.city ?? 'Cairo',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildSkillBadge(musician.skillLevel),
                  ],
                ),
              ),
              if (musician.bio != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    musician.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: musician.instruments
                      .map((i) => _buildInstrumentTag(i))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showMusicianDetail(context, musician),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final currentUser =
                              ref.read(authServiceProvider).currentUser;
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please login to chat')),
                            );
                            return;
                          }

                          try {
                            // Optimistic UI / Loading state could be added here
                            final chatId = await ref
                                .read(chatServiceProvider)
                                .createOrGetChat(currentUser.uid, musician.id);

                            if (context.mounted) {
                              context.push('/chat-detail/$chatId',
                                  extra: musician);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Could not open chat. Please try again. ($e)'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Let\'s Jam',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMusicianDetail(BuildContext context, UserModel musician) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MusicianDetailSheet(musician: musician),
    );
  }

  Widget _buildAvatar(UserModel musician) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: musician.photoUrl != null
            ? Image.network(
                musician.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 28),
              )
            : const Icon(Icons.person, color: AppColors.primary, size: 28),
      ),
    );
  }

  Widget _buildSkillBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        level.toUpperCase(),
        style: GoogleFonts.outfit(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInstrumentTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_off_outlined,
                size: 48, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Text(
            'No Musicians Found',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedInstrument = 'All';
                _selectedCity = 'All';
                _searchQuery = '';
                _searchController.clear();
                _showInstruments = false;
                _showLocation = false;
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}

// Musician Detail Bottom Sheet
class MusicianDetailSheet extends ConsumerWidget {
  final UserModel musician;

  const MusicianDetailSheet({super.key, required this.musician});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header with Avatar
                    Row(
                      children: [
                        Hero(
                          tag: 'musician_${musician.id}',
                          child: Container(
                            width: 80,
                            height: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: musician.photoUrl != null
                                  ? Image.network(
                                      musician.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.person,
                                                  color: AppColors.primary,
                                                  size: 40),
                                    )
                                  : const Icon(Icons.person,
                                      color: AppColors.primary, size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                musician.displayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 16,
                                      color:
                                          AppColors.primary.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    musician.city ?? 'Egypt',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      musician.skillLevel,
                                      style: GoogleFonts.outfit(
                                        color: AppColors.accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Bio
                    if (musician.bio != null) ...[
                      _buildSectionTitle('About'),
                      const SizedBox(height: 8),
                      Text(
                        musician.bio!,
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Instruments
                    _buildSectionTitle('Instruments'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: musician.instruments
                          .map((instrument) => Chip(
                                avatar: const Icon(Icons.music_note,
                                    size: 16, color: AppColors.primary),
                                label: Text(instrument,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white)),
                                backgroundColor: AppColors.surface,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Genres
                    if (musician.genres.isNotEmpty) ...[
                      _buildSectionTitle('Genres'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: musician.genres
                            .map((genre) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(genre,
                                      style: GoogleFonts.outfit(
                                          color: AppColors.textSecondary,
                                          fontSize: 13)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Contact Button
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        final currentUser =
                            ref.read(authServiceProvider).currentUser;
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please login to chat')),
                          );
                          return;
                        }

                        try {
                          final chatId = await ref
                              .read(chatServiceProvider)
                              .createOrGetChat(currentUser.uid, musician.id);

                          if (context.mounted) {
                            Navigator.pop(context); // Close bottom sheet
                            router.push('/chat-detail/$chatId', extra: musician);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Could not open chat. Please try again. ($e)'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.bolt_rounded),
                      label: Text("Let's Jam Together",
                          style:
                              GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

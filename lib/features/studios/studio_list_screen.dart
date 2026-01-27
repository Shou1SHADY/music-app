import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/studio_model.dart';
import '../../services/firestore_service.dart';
import '../../core/constants.dart';
import 'studio_detail_screen.dart';

final studiosProvider = StreamProvider<List<StudioModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getStudios();
});

class StudioListScreen extends ConsumerStatefulWidget {
  const StudioListScreen({super.key});

  @override
  ConsumerState<StudioListScreen> createState() => _StudioListScreenState();
}

class _StudioListScreenState extends ConsumerState<StudioListScreen> {
  String _selectedCity = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showLocation = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudioModel> _filterStudios(List<StudioModel> studios) {
    return studios.where((s) {
      // Filter by city
      if (_selectedCity != 'All' && s.city != _selectedCity) {
        return false;
      }
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = s.name.toLowerCase().contains(query);
        final descMatch = s.description.toLowerCase().contains(query);
        final equipmentMatch =
            s.equipment.any((e) => e.toLowerCase().contains(query));
        if (!nameMatch && !descMatch && !equipmentMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final studiosAsync = ref.watch(studiosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Music Studios'),
            Text('Book rehearsal space in Egypt',
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
          _buildCityFilter(),
          Expanded(
            child: studiosAsync.when(
              data: (studios) {
                final filtered = _filterStudios(studios);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final studio = filtered[index];
                    return _buildStudioCard(context, studio);
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
          hintText: 'Search studios, equipment...',
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

  Widget _buildCityFilter() {
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
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              final label = index == 0 ? 'All' : items[index - 1];
              final isSelected = selectedValue == label;
              return _buildPremiumChip(
                label: label,
                isSelected: isSelected,
                icon: (index > 0) ? icon : null,
                onTap: () => onSelected(label),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? AppColors.onPrimary : AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
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
            child: const Icon(Icons.house_siding_rounded,
                size: 48, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Text(
            'No Studios Found',
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
                _selectedCity = 'All';
                _searchQuery = '';
                _searchController.clear();
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

  Widget _buildStudioCard(BuildContext context, StudioModel studio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: () {
            context.push('/studio-detail', extra: studio);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                    ),
                    child: studio.images.isNotEmpty
                        ? Image.network(
                            studio.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.piano,
                                  size: 80, color: Colors.white24),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.music_video,
                                size: 48, color: Colors.white12)),
                  ),
                  _buildPriceTag(studio.pricePerHour),
                  _buildRatingBadge(studio.rating),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studio.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14,
                            color: AppColors.primary.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${studio.city} • ${studio.address}',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      studio.description,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    _buildEquipmentList(studio.equipment),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudioDetailScreen(studio: studio),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Book Session'),
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

  Widget _buildPriceTag(double price) {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          '${price.toStringAsFixed(0)} EGP/hr',
          style: GoogleFonts.outfit(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
            const SizedBox(width: 4),
            Text(
              rating.toString(),
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentList(List<String> equipment) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: equipment
          .take(3)
          .map((e) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  e,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ))
          .toList(),
    );
  }
}

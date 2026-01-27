import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../models/studio_model.dart';
import '../bookings/booking_sheet.dart';
import '../reviews/review_widgets.dart';

class StudioDetailScreen extends StatefulWidget {
  final StudioModel studio;

  const StudioDetailScreen({super.key, required this.studio});

  @override
  State<StudioDetailScreen> createState() => _StudioDetailScreenState();
}

class _StudioDetailScreenState extends State<StudioDetailScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _openInMaps() async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.studio.latitude},${widget.studio.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.studio.images.isNotEmpty
                      ? Image.network(
                          widget.studio.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.piano,
                                size: 80, color: Colors.white24),
                          ),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.piano,
                              size: 80, color: Colors.white24)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.9),
                          AppColors.background,
                        ],
                        stops: const [0.6, 0.9, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Share functionality coming soon!')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.studio.name,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.accent, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              widget.studio.rating.toString(),
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              ' (${widget.studio.reviewCount})',
                              style: GoogleFonts.outfit(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _openInMaps,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.textSecondary, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.studio.city} • ${widget.studio.address}',
                            style: GoogleFonts.outfit(
                                color: AppColors.primary, fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.open_in_new_rounded,
                            color: AppColors.primary, size: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Stats
                  _buildQuickStats(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('About'),
                  const SizedBox(height: 8),
                  Text(
                    widget.studio.description,
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        height: 1.6,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Equipment'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.studio.equipment
                        .map((e) => Chip(
                              avatar: const Icon(Icons.check_circle_rounded,
                                  size: 16, color: AppColors.success),
                              label: Text(e,
                                  style: GoogleFonts.outfit(
                                      color: AppColors.textPrimary,
                                      fontSize: 13)),
                              backgroundColor: AppColors.surface,
                              padding: const EdgeInsets.all(8),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 32),

                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Reviews'),
                      TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                WriteReviewSheet(studioId: widget.studio.id),
                          );
                        },
                        icon: const Icon(Icons.rate_review_rounded, size: 16),
                        label: const Text('Write Review'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ReviewList(studioId: widget.studio.id),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Location'),
                  const SizedBox(height: 12),
                  _buildMapSection(),
                  const SizedBox(height: 100), // Space for fab
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price',
                      style: GoogleFonts.outfit(
                          color: AppColors.textMuted, fontSize: 12)),
                  Text(
                    '${widget.studio.pricePerHour.toStringAsFixed(0)} EGP',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text('/ hour',
                      style: GoogleFonts.outfit(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BookingSheet(studio: widget.studio),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Book Now',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.star_rounded,
            value: widget.studio.rating.toString(),
            label: 'Rating',
            color: AppColors.accent,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.reviews_rounded,
            value: widget.studio.reviewCount.toString(),
            label: 'Reviews',
            color: AppColors.secondary,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.build_rounded,
            value: widget.studio.equipment.length.toString(),
            label: 'Equipment',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildMapSection() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 40, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  "Location Preview",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.studio.address,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openInMaps,
          icon: const Icon(Icons.directions_rounded),
          label: const Text('Get Directions'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }
}

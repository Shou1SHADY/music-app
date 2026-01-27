import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/studio_model.dart';
import 'booking_service.dart';

class BookingSheet extends ConsumerStatefulWidget {
  final StudioModel studio;

  const BookingSheet({super.key, required this.studio});

  @override
  ConsumerState<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<BookingSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 0);
  int _durationHours = 2;
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = startDateTime.add(Duration(hours: _durationHours));

    try {
      await ref.read(bookingServiceProvider).createBooking(
            widget.studio.id,
            widget.studio.name,
            startDateTime,
            endDateTime,
            widget.studio.pricePerHour,
          );

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request sent!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.studio.pricePerHour * _durationHours;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Book Session',
            style: GoogleFonts.outfit(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),

          // Date Selection
          _buildSelector(
            label: 'Date',
            value: DateFormat('MMM dd, yyyy').format(_selectedDate),
            icon: Icons.calendar_today_rounded,
            onTap: _selectDate,
          ),
          const SizedBox(height: 16),

          // Time Selection
          _buildSelector(
            label: 'Start Time',
            value: _startTime.format(context),
            icon: Icons.access_time_rounded,
            onTap: _selectTime,
          ),
          const SizedBox(height: 16),

          // Duration Selection
          Row(
            children: [
              Text('Duration',
                  style: GoogleFonts.outfit(
                      fontSize: 16, color: AppColors.textSecondary)),
              const Spacer(),
              _buildDurationControl(Icons.remove, () {
                if (_durationHours > 1) setState(() => _durationHours--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_durationHours hrs',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              _buildDurationControl(Icons.add, () {
                if (_durationHours < 8) setState(() => _durationHours++);
              }),
            ],
          ),

          const SizedBox(height: 32),
          Divider(color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.outfit(
                      fontSize: 18, color: AppColors.textSecondary)),
              Text(
                '${totalPrice.toStringAsFixed(0)} EGP',
                style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ],
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: AppColors.background)
                : Text('Confirm Booking',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSelector(
      {required String label,
      required String value,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            const Spacer(),
            Text(value,
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.grey, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationControl(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

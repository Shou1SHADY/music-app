import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/studio_model.dart';
import '../../widgets/ui_widgets.dart';
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
  bool _isCheckingAvailability = false;
  bool _isAvailable = true;

  // Generate time slots from 8 AM to 10 PM
  List<TimeOfDay> get _timeSlots {
    final slots = <TimeOfDay>[];
    for (int hour = 8; hour <= 22; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
    }
    return slots;
  }

  void _selectTimeSlot(TimeOfDay timeSlot) {
    setState(() {
      _startTime = timeSlot;
    });
    _checkAvailability();
  }

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
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkAvailability();
    }
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
    if (picked != null) {
      setState(() => _startTime = picked);
      _checkAvailability();
    }
  }

  Future<void> _checkAvailability() async {
    setState(() => _isCheckingAvailability = true);
    
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = startDateTime.add(Duration(hours: _durationHours));

    try {
      final isAvailable = await ref.read(bookingServiceProvider).checkAvailability(
            widget.studio.id,
            startDateTime,
            endDateTime,
          );
      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
          _isCheckingAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingAvailability = false);
      }
    }
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
      // Check availability first
      final isAvailable = await ref.read(bookingServiceProvider).checkAvailability(
            widget.studio.id,
            startDateTime,
            endDateTime,
          );

      if (!isAvailable) {
        if (mounted) {
          ErrorSnackBar.show(
            context,
            'This time slot is not available. Please choose another time.',
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await ref.read(bookingServiceProvider).createBooking(
            widget.studio.id,
            widget.studio.name,
            startDateTime,
            endDateTime,
            widget.studio.pricePerHour,
          );

      if (mounted) {
        Navigator.pop(context); // Close sheet
        SuccessSnackBar.show(
          context,
          'Booking request sent successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(
          context,
          'Failed to create booking: ${e.toString()}',
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

          // Time Selection - Visual Time Slot Picker
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start Time',
                  style: GoogleFonts.outfit(
                      fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _timeSlots.length,
                  itemBuilder: (context, index) {
                    final timeSlot = _timeSlots[index];
                    final isSelected = _startTime.hour == timeSlot.hour;
                    
                    return GestureDetector(
                      onTap: () => _selectTimeSlot(timeSlot),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primary 
                              : AppColors.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected 
                                ? AppColors.primary 
                                : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            timeSlot.format(context),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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

          const SizedBox(height: 24),

          // Availability Status
          _buildAvailabilityStatus(),

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

  Widget _buildDurationControl(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary, size: 20),
        onPressed: () {
          onPressed();
          _checkAvailability();
        },
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildAvailabilityStatus() {
    if (_isCheckingAvailability) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Checking availability...',
              style: GoogleFonts.outfit(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (_isAvailable ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_isAvailable ? Colors.green : Colors.red).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isAvailable ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            _isAvailable ? 'Available for booking' : 'Time slot not available',
            style: GoogleFonts.outfit(
              color: _isAvailable ? Colors.green : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

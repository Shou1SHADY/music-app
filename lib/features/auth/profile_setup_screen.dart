import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import 'auth_service.dart';
import '../../services/firestore_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _selectedCity;
  String? _skillLevel = 'Beginner';
  List<String> _selectedInstruments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final profile =
          await ref.read(firestoreServiceProvider).getUserProfile(user.uid);
      if (profile != null) {
        _nameController.text = profile.displayName;
        _bioController.text = profile.bio ?? '';
        setState(() {
          _selectedCity = profile.city;
          _skillLevel = profile.skillLevel;
          _selectedInstruments = List.from(profile.instruments);
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleInstrument(String instrument) {
    setState(() {
      if (_selectedInstruments.contains(instrument)) {
        _selectedInstruments.remove(instrument);
      } else {
        _selectedInstruments.add(instrument);
      }
    });
  }

  Future<void> _completeSetup() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      debugPrint("CompleteSetup: No user logged in");
      return;
    }

    if (_nameController.text.trim().isEmpty || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint("CompleteSetup: Starting profile creation for ${user.uid}");

    final newUser = UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: _nameController.text.trim(),
      city: _selectedCity,
      instruments: _selectedInstruments,
      skillLevel: _skillLevel ?? 'Beginner',
      bio: _bioController.text.trim(),
      latitude: 30.0444,
      longitude: 31.2357,
    );

    try {
      debugPrint("CompleteSetup: Sending to Firestore...");

      // Start the save operation
      final saveFuture =
          ref.read(firestoreServiceProvider).createUserProfile(newUser);

      // Wait briefly for server confirmation (2 seconds), but don't block the user
      // if it takes longer. Firestore will continue to sync in the background.
      await saveFuture.timeout(const Duration(seconds: 2), onTimeout: () {
        debugPrint(
            "CompleteSetup: Save initiated. Will sync with cloud in background.");
        return;
      });

      debugPrint("CompleteSetup: Success! Navigating to home.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated! Syncing with community...'),
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      debugPrint("CompleteSetup Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Setup Profile',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.primary, size: 40),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: AppColors.onPrimary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('IDENTIFICATION'),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Display Name',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    items: AppConstants.egyptCities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCity = v),
                    decoration: const InputDecoration(
                      hintText: 'Your City',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                    dropdownColor: AppColors.surface,
                    style: GoogleFonts.outfit(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionTitle('MUSICALITY'),
                  DropdownButtonFormField<String>(
                    value: _skillLevel,
                    items: ['Beginner', 'Intermediate', 'Professional']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _skillLevel = v),
                    decoration: const InputDecoration(
                      hintText: 'Skill Level',
                      prefixIcon: Icon(Icons.bolt_rounded, size: 20),
                    ),
                    dropdownColor: AppColors.surface,
                    style: GoogleFonts.outfit(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  Text('What do you play?',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.instruments.take(12).map((inst) {
                      final isSelected = _selectedInstruments.contains(inst);
                      return FilterChip(
                        label: Text(inst,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.onPrimary
                                    : AppColors.textSecondary)),
                        selected: isSelected,
                        onSelected: (_) => _toggleInstrument(inst),
                        showCheckmark: false,
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.05)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionTitle('BIOGRAPHY'),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                        hintText: 'Tell us about your musical journey...'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _completeSetup,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.onPrimary))
                        : const Text('Start Sharing Music'),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

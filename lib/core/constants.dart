import 'package:flutter/material.dart';

class AppColors {
  // Premium Palette
  static const Color primary = Color(0xFFC5A059); // Harvest Gold
  static const Color primaryVariant = Color(0xFFB38D45);
  static const Color accent = Color(0xFFE8C382);
  static const Color secondary = Color(0xFF4A90E2); // Modern Blue

  static const Color background = Color(0xFF0F0F12); // Deep Space Black
  static const Color surface = Color(0xFF1A1A1E); // Off Black Surface
  static const Color cardBackground = Color(0xFF242429);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B5C1); // Brighter than 9EA3AE
  static const Color textMuted = Color(0xFF7D8392); // Brighter than 636773

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);

  static const Color onPrimary = Color(0xFF0F0F12);
  static const Color onSecondary = Colors.white;
}

class AppConstants {
  static const String appName = 'Egypt Music Community';
  static const List<String> egyptCities = [
    'Cairo',
    'Giza',
    'Alexandria',
    'Dahab',
    'El Gouna',
    'Hurghada',
    'Mansoura',
    'Luxor',
    'Aswan'
  ];

  static const List<String> instruments = [
    'Electric Guitar',
    'Acoustic Guitar',
    'Bass Guitar',
    'Piano/Keyboard',
    'Drums',
    'Percussion/Tabla',
    'Oud',
    'Violin',
    'Cello',
    'Saxophone',
    'Trumpet',
    'Flute/Nay',
    'Synthesizer',
    'Vocals (Male)',
    'Vocals (Female)',
    'DJ/Electronic Production',
  ];

  static const List<String> genres = [
    'Rock',
    'Alternative',
    'Jazz',
    'Blues',
    'Pop',
    'Hip Hop/Rap',
    'Mahraganat',
    'Oriental/Shaabi',
    'Classical Arabic',
    'Electronic/Techno',
    'House',
    'Metal',
    'Reggae',
    'Indie',
    'Funk',
  ];
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/studio_model.dart';

class SeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> seedIfNeeded() async {
    print('SeedingService: Checking if database initialization is needed...');
    await _seedMusiciansIfNeeded();
    await _seedStudiosIfNeeded();
    await _fixBrokenExistingImages();
    print('SeedingService: Initial check complete.');
  }

  Future<void> _fixBrokenExistingImages() async {
    final brokenIds = [
      'photo-1514702361016',
      'photo-1549412121',
      'photo-152081379',
      'photo-1506794778',
      'photo-1544005313'
    ];
    const workingStudioUrl =
        'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800';
    const workingUserUrl =
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400';

    try {
      print('SeedingService: Scanning for broken images...');
      int fixedStudios = 0;
      int fixedUsers = 0;

      // Fix studios
      final studioSnapshot = await _firestore.collection('studios').get();
      for (var doc in studioSnapshot.docs) {
        final images = List<String>.from(doc.data()['images'] ?? []);
        bool changed = false;
        final updatedImages = images.map((img) {
          if (brokenIds.any((id) => img.contains(id))) {
            changed = true;
            return workingStudioUrl;
          }
          return img;
        }).toList();

        if (changed) {
          await doc.reference.update({'images': updatedImages});
          fixedStudios++;
        }
      }

      // Fix users
      final userSnapshot = await _firestore.collection('users').get();
      for (var doc in userSnapshot.docs) {
        final photoUrl = doc.data()['photoUrl'] as String?;
        if (photoUrl != null && brokenIds.any((id) => photoUrl.contains(id))) {
          await doc.reference.update({'photoUrl': workingUserUrl});
          fixedUsers++;
        }
      }

      print(
          'SeedingService: Cleanup complete. Fixed $fixedStudios studios and $fixedUsers users.');
    } catch (e) {
      print('SeedingService: Error during image cleanup: $e');
    }
  }

  Future<void> _seedMusiciansIfNeeded() async {
    final musiciansSnapshot = await _firestore
        .collection('users')
        .where('isStudioOwner', isEqualTo: false)
        .limit(1)
        .get();

    if (musiciansSnapshot.docs.isEmpty) {
      print(
          'SeedingService: No musicians found, seeding 4 default accounts...');
      await _generateMusicians();
      print('SeedingService: Musicians created successfully.');
    } else {
      print('SeedingService: Musicians collection already exists.');
    }
  }

  Future<void> _seedStudiosIfNeeded() async {
    final studiosSnapshot =
        await _firestore.collection('studios').limit(1).get();

    if (studiosSnapshot.docs.isEmpty) {
      print('SeedingService: No studios found, seeding 3 default studios...');
      await _generateStudios();
      print('SeedingService: Studios created successfully.');
    } else {
      print('SeedingService: Studios collection already exists.');
    }
  }

  Future<void> _generateMusicians() async {
    final musicians = [
      UserModel(
        id: _uuid.v4(),
        email: 'omar@example.com',
        displayName: 'Omar El Arabi',
        city: 'Cairo',
        instruments: ['Electric Guitar', 'Vocals (Male)'],
        skillLevel: 'Professional',
        bio:
            'Session guitarist for major artists. Love funk and fusion. Let\'s create something unique!',
        photoUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        latitude: 30.0444,
        longitude: 31.2357,
      ),
      UserModel(
        id: _uuid.v4(),
        email: 'layla@example.com',
        displayName: 'Layla Mansour',
        city: 'Dahab',
        instruments: ['Piano/Keyboard', 'Vocals (Female)'],
        skillLevel: 'Intermediate',
        bio:
            'Songwriter based in Dahab. Looking for chill collaboration and acoustic vibes.',
        photoUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
        latitude: 28.5097,
        longitude: 34.5126,
      ),
      UserModel(
        id: _uuid.v4(),
        email: 'hassan@example.com',
        displayName: 'Hassan Tabla',
        city: 'Giza',
        instruments: ['Percussion/Tabla', 'Nay'],
        skillLevel: 'Professional',
        bio:
            'Classical oriental percussionist. Dedicated to tradition and exploring new rhythms.',
        photoUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
        latitude: 30.0131,
        longitude: 31.2089,
      ),
      UserModel(
        id: _uuid.v4(),
        email: 'dana@example.com',
        displayName: 'Dana Electronic',
        city: 'Alexandria',
        instruments: ['DJ/Electronic Production', 'Synthesizer'],
        skillLevel: 'Intermediate',
        bio:
            'Exploring the intersection of Nile beats and deep house. Analog gear enthusiast.',
        photoUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        latitude: 31.2001,
        longitude: 29.9187,
      ),
    ];

    for (var m in musicians) {
      await _firestore.collection('users').doc(m.id).set(m.toJson());
    }
  }

  Future<void> _generateStudios() async {
    final studios = [
      StudioModel(
        id: _uuid.v4(),
        ownerId: 'mock_owner_1',
        name: 'The Sonic Pyramid',
        description:
            'Elite recording facility with views of the Giza plateau. Top-tier acoustics and world-class equipment.',
        address: 'Pyramid St, Giza',
        city: 'Giza',
        pricePerHour: 450,
        equipment: ['Neve Console', 'Steinway Grand', 'Acoustic Treatment'],
        rating: 5.0,
        reviewCount: 24,
        latitude: 29.9851,
        longitude: 31.1342,
        images: [
          'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=800'
        ],
      ),
      StudioModel(
        id: _uuid.v4(),
        ownerId: 'mock_owner_2',
        name: 'Retro Beat Lab',
        description:
            'Vintage gear and analog tape recording. Perfect for that authentic 70s sound and warmth.',
        address: 'Talaat Harb, Downtown Cairo',
        city: 'Cairo',
        pricePerHour: 250,
        equipment: ['Analog Tape', 'Vintage Mics', 'Old Hammond'],
        rating: 4.7,
        reviewCount: 18,
        latitude: 30.0444,
        longitude: 31.2357,
        images: [
          'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800'
        ],
      ),
      StudioModel(
        id: _uuid.v4(),
        ownerId: 'mock_owner_3',
        name: 'Dahab Sound Nest',
        description:
            'Open-air studio vibes by the Red Sea. Experience unique acoustics in a natural setting.',
        address: 'Lighthouse Area, Dahab',
        city: 'Dahab',
        pricePerHour: 180,
        equipment: ['Focusrite System', 'Solar Powered', 'Beach Vibes'],
        rating: 4.9,
        reviewCount: 12,
        latitude: 28.5137,
        longitude: 34.5186,
        images: [
          'https://images.unsplash.com/photo-1525362081669-2b476bb628c3?w=800'
        ],
      ),
    ];

    for (var s in studios) {
      await _firestore.collection('studios').doc(s.id).set(s.toJson());
    }
  }
}

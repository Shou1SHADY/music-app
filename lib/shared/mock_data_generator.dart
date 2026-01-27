import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/studio_model.dart';

class MockDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> generateMusicians() async {
    final musicians = [
      UserModel(
        id: _uuid.v4(),
        email: 'omar@example.com',
        displayName: 'Omar El Arabi',
        city: 'Cairo',
        instruments: ['Electric Guitar', 'Vocals (Male)'],
        skillLevel: 'Professional',
        bio: 'Session guitarist for major artists. Love funk and fusion.',
        photoUrl:
            'https://images.unsplash.com/photo-1511367461989-f85a21fda142?w=400',
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
        bio: 'Songwriter based in Dahab. Looking for chill collaboration.',
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
        bio: 'Classical oriental percussionist. Dedicated to tradition.',
        photoUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
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
        bio: 'Exploring the intersection of Nile beats and deep house.',
        photoUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
        latitude: 31.2001,
        longitude: 29.9187,
      ),
    ];

    for (var m in musicians) {
      await _firestore.collection('users').doc(m.id).set(m.toJson());
    }
  }

  Future<void> generateStudios() async {
    final studios = [
      StudioModel(
        id: _uuid.v4(),
        ownerId: 'mock_owner_1',
        name: 'The Sonic Pyramid',
        description:
            'Elite recording facility with views of the Giza plateau. Top-tier acoustics.',
        address: 'Pyramid St, Giza',
        city: 'Giza',
        pricePerHour: 450,
        equipment: ['Neve Console', 'Steinway Grand', 'Acoustic Treatment'],
        rating: 5.0,
        reviewCount: 24,
        latitude: 29.9851,
        longitude: 31.1342,
        images: [
          'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800'
        ],
      ),
      StudioModel(
        id: _uuid.v4(),
        ownerId: 'mock_owner_2',
        name: 'Retro Beat Lab',
        description:
            'Vintage gear and analog tape recording. Perfect for that 70s sound.',
        address: 'Talaat Harb, Downtown Cairo',
        city: 'Cairo',
        pricePerHour: 250,
        equipment: ['Analog Tape', 'Vintage Mics', 'Old Hammond'],
        rating: 4.7,
        reviewCount: 18,
        latitude: 30.0444,
        longitude: 31.2357,
        images: [
          'https://images.unsplash.com/photo-1520529618774-88f17a86e969?w=800'
        ],
      ),
      StudioModel(
        id: _uuid.v4(),
        ownerId: 'mock_owner_3',
        name: 'Dahab Sound Nest',
        description:
            'Open-air studio vibes by the Red Sea. Experience unique acoustics.',
        address: 'Lighthouse Area, Dahab',
        city: 'Dahab',
        pricePerHour: 180,
        equipment: ['Focusrite System', 'Solar Powered', 'Beach Vibes'],
        rating: 4.9,
        reviewCount: 12,
        latitude: 28.5137,
        longitude: 34.5186,
        images: [
          'https://images.unsplash.com/photo-1514525253344-f814d0743b1a?w=800'
        ],
      ),
    ];

    for (var s in studios) {
      await _firestore.collection('studios').doc(s.id).set(s.toJson());
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/studio_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  Future<void> createUserProfile(UserModel user) async {
    try {
      print("FirestoreService: Setting profile for user ${user.id}...");
      await _firestore.collection('users').doc(user.id).set(user.toJson());
      print("FirestoreService: Profile set successfully.");
    } catch (e) {
      print("FirestoreService: Error creating user profile: $e");
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null);
  }

  Stream<List<UserModel>> getMusicians() {
    return _firestore
        .collection('users')
        .where('isStudioOwner', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<StudioModel>> getStudios() {
    return _firestore.collection('studios').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => StudioModel.fromJson(doc.data())).toList());
  }
}

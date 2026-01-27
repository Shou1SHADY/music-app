import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? city; // Cairo, Giza, etc.
  final List<String> instruments;
  final List<String> genres;
  final String skillLevel; // Beginner, Intermediate, Professional
  final bool isStudioOwner;
  final String? bio;
  final Map<String, String>? socialLinks;

  // Custom converter for GeoPoint if needed, or just store lat/lng
  final double? latitude;
  final double? longitude;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.city,
    this.instruments = const [],
    this.genres = const [],
    this.skillLevel = 'Beginner',
    this.isStudioOwner = false,
    this.bio,
    this.socialLinks,
    this.latitude,
    this.longitude,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

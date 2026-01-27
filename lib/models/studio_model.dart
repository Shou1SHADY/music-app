import 'package:json_annotation/json_annotation.dart';

part 'studio_model.g.dart';

@JsonSerializable()
class StudioModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final String city;
  final double pricePerHour;
  final List<String> equipment;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;

  StudioModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.pricePerHour,
    required this.equipment,
    this.images = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.latitude,
    required this.longitude,
  });

  factory StudioModel.fromJson(Map<String, dynamic> json) => _$StudioModelFromJson(json);
  Map<String, dynamic> toJson() => _$StudioModelToJson(this);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'studio_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudioModel _$StudioModelFromJson(Map<String, dynamic> json) => StudioModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      equipment:
          (json['equipment'] as List<dynamic>).map((e) => e as String).toList(),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$StudioModelToJson(StudioModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'name': instance.name,
      'description': instance.description,
      'address': instance.address,
      'city': instance.city,
      'pricePerHour': instance.pricePerHour,
      'equipment': instance.equipment,
      'images': instance.images,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

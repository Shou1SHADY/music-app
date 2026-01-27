// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      city: json['city'] as String?,
      instruments: (json['instruments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      skillLevel: json['skillLevel'] as String? ?? 'Beginner',
      isStudioOwner: json['isStudioOwner'] as bool? ?? false,
      bio: json['bio'] as String?,
      socialLinks: (json['socialLinks'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'city': instance.city,
      'instruments': instance.instruments,
      'genres': instance.genres,
      'skillLevel': instance.skillLevel,
      'isStudioOwner': instance.isStudioOwner,
      'bio': instance.bio,
      'socialLinks': instance.socialLinks,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

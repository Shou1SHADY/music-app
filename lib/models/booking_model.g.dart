// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) => BookingModel(
      id: json['id'] as String,
      studioId: json['studioId'] as String,
      userId: json['userId'] as String,
      studioName: json['studioName'] as String,
      userName: json['userName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: $enumDecodeNullable(_$BookingStatusEnumMap, json['status']) ??
          BookingStatus.pending,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studioId': instance.studioId,
      'userId': instance.userId,
      'studioName': instance.studioName,
      'userName': instance.userName,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'totalPrice': instance.totalPrice,
      'status': _$BookingStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'pending',
  BookingStatus.approved: 'approved',
  BookingStatus.rejected: 'rejected',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.completed: 'completed',
};

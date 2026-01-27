import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'booking_model.g.dart';

enum BookingStatus { pending, approved, rejected, cancelled, completed }

@JsonSerializable()
class BookingModel {
  final String id;
  final String studioId;
  final String userId;
  final String studioName;
  final String userName;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final BookingStatus status;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.studioId,
    required this.userId,
    required this.studioName,
    required this.userName,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.status = BookingStatus.pending,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String? ?? '',
      studioId: json['studioId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      studioName: json['studioName'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic ts) {
    if (ts == null) return DateTime.now();
    if (ts is Timestamp) return ts.toDate();
    if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
    return DateTime.now();
  }

  static BookingStatus _parseStatus(dynamic status) {
    if (status == null) return BookingStatus.pending;
    if (status is String) {
      return BookingStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => BookingStatus.pending,
      );
    }
    return BookingStatus.pending;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studioId': studioId,
        'userId': userId,
        'studioName': studioName,
        'userName': userName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'totalPrice': totalPrice,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };
}

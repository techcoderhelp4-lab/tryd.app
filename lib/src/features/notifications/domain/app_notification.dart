import 'package:json_annotation/json_annotation.dart';

part 'app_notification.g.dart';

@JsonSerializable()
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'challenge_invite', 'challenge_update', 'friend_request', 'system', etc.
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isRead: json['isRead'] ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}

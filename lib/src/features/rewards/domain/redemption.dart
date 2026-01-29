import 'reward.dart';

class Redemption {
  final String id;
  final Reward reward;
  final int pointsDeducted;
  final String status;
  final String? couponCode;
  final DateTime createdAt;

  Redemption({
    required this.id,
    required this.reward,
    required this.pointsDeducted,
    required this.status,
    this.couponCode,
    required this.createdAt,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    return Redemption(
      id: json['_id'] ?? json['id'] ?? '',
      reward: Reward.fromJson(json['rewardId'] ?? {}),
      pointsDeducted: json['pointsDeducted'] ?? 0,
      status: json['status'] ?? 'pending',
      couponCode: json['couponCode'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'rewardId': reward.toJson(),
      'pointsDeducted': pointsDeducted,
      'status': status,
      'couponCode': couponCode,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

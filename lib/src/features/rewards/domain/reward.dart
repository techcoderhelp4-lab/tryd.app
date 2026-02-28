class Reward {
  final String id;
  final String title;
  final String description;
  final int requiredPoints;
  final String imageUrl;
  final String partner;
  final String category;
  final bool requiresApproval;
  final int? maxPerUser;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.imageUrl,
    required this.partner,
    required this.category,
    this.requiresApproval = false,
    this.maxPerUser,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requiredPoints: json['requiredPoints'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      partner: json['partner'] ?? '',
      category: json['category'] ?? '',
      requiresApproval: json['requiresApproval'] ?? false,
      maxPerUser: json['maxPerUser'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'requiredPoints': requiredPoints,
      'imageUrl': imageUrl,
      'partner': partner,
      'category': category,
      'requiresApproval': requiresApproval,
      'maxPerUser': maxPerUser,
    };
  }
}

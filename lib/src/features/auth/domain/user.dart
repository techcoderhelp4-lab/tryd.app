import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

Object? _readId(Map map, String key) {
  if (key == 'id') {
    return map['id'] ?? map['_id'];
  }
  return map[key];
}

@JsonSerializable()
class User {
  @JsonKey(readValue: _readId)
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? phoneNumber;
  final String? gender;
  final int? points;
  final String? referralCode;
  final String? role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.phoneNumber,
    this.gender,
    this.points,
    this.referralCode,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}


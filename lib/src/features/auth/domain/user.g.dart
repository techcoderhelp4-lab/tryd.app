// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: _readId(json, 'id') as String,
  name: json['name'] as String,
  email: json['email'] as String,
  profilePicture: json['profilePicture'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  gender: json['gender'] as String?,
  points: (json['points'] as num?)?.toInt(),
  referralCode: json['referralCode'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'profilePicture': instance.profilePicture,
  'phoneNumber': instance.phoneNumber,
  'gender': instance.gender,
  'points': instance.points,
  'referralCode': instance.referralCode,
};


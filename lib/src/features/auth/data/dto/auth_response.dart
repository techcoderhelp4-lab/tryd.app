import 'package:json_annotation/json_annotation.dart';
import '../../domain/user.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final bool success;
  final String? message;
  final String? accessToken;
  final User? user;

  AuthResponse({
    this.success = false,
    this.message,
    this.accessToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

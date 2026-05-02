import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dto/auth_response.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_database.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    String? referralCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          if (referralCode != null && referralCode.isNotEmpty)
            'referralCode': referralCode.trim().toUpperCase(),
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      if (authResponse.accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', authResponse.accessToken!);
        if (authResponse.refreshToken != null) {
          await prefs.setString('refresh_token', authResponse.refreshToken!);
        }
      }
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      if (authResponse.accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', authResponse.accessToken!);
        if (authResponse.refreshToken != null) {
          await prefs.setString('refresh_token', authResponse.refreshToken!);
        }
      }
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout(Ref ref) async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (e) {
      // Ignore
    } finally {
      // 1. Clear Local SQLite Database (Profile, Challenges, Activity, Sync Queue)
      try {
        await ref.read(localDatabaseProvider).clearAllData();
      } catch (e) {
        // Ignore DB clear errors during logout
      }

      // 2. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('workoutHistory');
      await prefs.remove('activityHistory');
      await prefs.remove('selected_language_code');
      await prefs.remove('cached_user_profile');
      
      // 3. Invalidate all cached providers
      ref.invalidate(apiClientProvider);
    }
  }
  Future<bool> checkUserExists({String? phoneNumber, String? email}) async {
    try {
      final response = await _dio.post(
        ApiConstants.checkUserExists,
        data: {
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (email != null) 'email': email,
        },
      );
      return response.data['exists'] == true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      await _dio.post(
        ApiConstants.sendOtp,
        data: {'email': email},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: {'email': email, 'otp': otp},
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token
      if (authResponse.accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', authResponse.accessToken!);
        if (authResponse.refreshToken != null) {
          await prefs.setString('refresh_token', authResponse.refreshToken!);
        }
      }

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyReferralCode(String code) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyReferralCode,
        data: {'code': code.trim().toUpperCase()},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> verifyOtpLogin(String email, String otp) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtpLogin,
        data: {'email': email, 'otp': otp},
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token
      if (authResponse.accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', authResponse.accessToken!);
        if (authResponse.refreshToken != null) {
          await prefs.setString('refresh_token', authResponse.refreshToken!);
        }
      }

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  final dio = ref.watch(apiClientProvider);
  return AuthRepository(dio);
}

